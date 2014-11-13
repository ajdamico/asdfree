# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# differences from the SAScii package's read.SAScii() --
# 	4x faster
# 	no RAM issues
# 	decimal division isn't flexible
# 	must read in the entire table
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

read.SAScii.sqlite <-
	function( 
		fn ,
		sas_ri , 
		beginline = 1 , 
		zipped = F , 
		# n = -1 , 			# no n parameter available for this - you must read in the entire table!
		lrecl = NULL , 
		skip.decimal.division = FALSE , # skipping decimal division is a modified option
		tl = F ,			# convert all column names to lowercase?
		tablename ,
		overwrite = FALSE ,	# overwrite existing table?
		conn				# database connection object -- read.SAScii.sql requires that dbConnect()
							# already be run before this function begins.
	) {

	# scientific notation contains a decimal point when converted to a character string..
	# so store the user's current value and get rid of it.
	user.defined.scipen <- getOption( 'scipen' )
	
	# set scientific notation to something impossibly high.  Inf doesn't work.
	options( scipen = 1000000 )
	
	# read.SAScii.sqlite depends on three packages
	# to install these packages, use the line:
	# install.packages( c( 'SAScii' , 'descr' , 'RSQLite' , 'downloader' ) )
	library(SAScii)
	library(descr)
	library(RSQLite)
	library(downloader)
	
	
	if ( !exists( "download.cache" ) ){
		# load the download.cache and related functions
		# to prevent re-downloading of files once they've been downloaded.
		source_url( 
			"https://raw.github.com/ajdamico/usgsd/master/Download%20Cache/download%20cache.R" , 
			prompt = FALSE , 
			echo = FALSE 
		)
	}


	
	x <- parse.SAScii( sas_ri , beginline , lrecl )
	
	if( tl ) x$varname <- tolower( x$varname )
	
	#only the width field should include negatives
	y <- x[ !is.na( x[ , 'varname' ] ) , ]
	
	
	# deal with gaps in the data frame #
	num.gaps <- nrow( x ) - nrow( y )
	
	# if there are any gaps..
	if ( num.gaps > 0 ){
	
		# read them in as simple character strings
		x[ is.na( x[ , 'varname' ] ) , 'char' ] <- TRUE
		x[ is.na( x[ , 'varname' ] ) , 'divisor' ] <- 1
		
		# invert their widths
		x[ is.na( x[ , 'varname' ] ) , 'width' ] <- abs( x[ is.na( x[ , 'varname' ] ) , 'width' ] )
		
		# name them toss_1 thru toss_###
		x[ is.na( x[ , 'varname' ] ) , 'varname' ] <- paste( 'toss' , 1:num.gaps , sep = "_" )
		
		# and re-create y
		y <- x
	}
		
	#if the ASCII file is stored in an archive, unpack it to a temporary file and run that through read.fwf instead.
	if ( zipped ){
		#create a temporary file and a temporary directory..
		tf <- tempfile() ; td <- tempdir()
		#download the CPS repwgts zipped file
		download.cache( fn , tf , mode = "wb" )
		#unzip the file's contents and store the file name within the temporary directory
		fn <- unzip( tf , exdir = td , overwrite = T )
	}

	
	# if the overwrite flag is TRUE, then check if the table is in the database..
	if ( overwrite ){
		# and if it is, remove it.
		if ( tablename %in% dbListTables( conn ) ) dbRemoveTable( conn , tablename )
		
		# if the overwrite flag is false
		# but the table exists in the database..
	} else {
		if ( tablename %in% dbListTables( conn ) ) stop( "table with this name already in database" )
	}
	
	# if ( sum( grepl( 'sample' , tolower( y$varname ) ) ) > 0 ){
		# print( 'warning: variable named sample not allowed in monetdb' )
		# print( 'changing column name to sample_' )
		# y$varname <- gsub( 'sample' , 'sample_' , y$varname )
	# }
	
	# fields <- y$varname

	# colTypes <- ifelse( !y[ , 'char' ] , 'DOUBLE PRECISION' , 'VARCHAR(255)' )
	

	# colDecl <- paste( fields , colTypes )

	# sql <-
		# sprintf(
			# paste(
				# "CREATE TABLE" ,
				# tablename ,
				# "(%s)"
			# ) ,
			# paste(
				# colDecl ,
				# collapse = ", "
			# )
		# )
	
	# dbSendQuery( conn , sql )

	# create a second temporary file
	tf2 <- tempfile()
	
	# create a third temporary file
	tf3 <- tempfile()
	
	# starts and ends
	w <- abs ( x$width )
	s <- 1
	e <- w[ 1 ]
	for ( i in 2:length( w ) ) {
		s[ i ] <- s[ i - 1 ] + w[ i - 1 ]
		e[ i ] <- e[ i - 1 ] + w[ i ]
	}
		
	# convert the fwf to a csv
	fwf2csv( fn , tf2 , names = x$varname , begin = s , end = e , verbose = FALSE )

	# pull the csv file into the database
	dbWriteTable( conn , tablename , tf2 , sep = "\t" , header = TRUE )
	
	# delete the temporary file from the hard disk
	file.remove( tf2 )
		

	if( skip.decimal.division ) y[ , 'divisor' ] <- 1
		
	# construct the sql string used to multiply by all divisors at once
	sql.divisor <- 
		paste( 
			"create table" ,
			tablename , 
			"as select" , 
			paste( 
				ifelse( 
					y[ , "char" ] , 
					y[ , "varname" ] , 
					paste( "(" , y[ , "varname" ] , "*" , y[ , "divisor" ] , ")" ) 
				) , 
				"as" ,
				y[ , 'varname' ] ,
				collapse = ", " 
			) , 
			"from temp_backup"
		)

	# rename the current table to a backup table..
	dbSendQuery( conn , paste0( "ALTER TABLE " , tablename , " RENAME TO temp_backup" ) )

	# run the divisor query
	dbSendQuery( conn , sql.divisor )
	
	# remove the backup table
	dbRemoveTable( conn , "temp_backup" )

	
	# eliminate gap variables.. loop through every gap
	if ( num.gaps > 0 ){

		# store all columns
		All.Cols <- dbListFields( conn , tablename )

		# throw out toss_### columns
		Keep.Cols <- All.Cols[ !( All.Cols %in% paste0( 'toss_' , 1:num.gaps ) ) ]
				
		# rename the current table to a backup table..
		dbSendQuery( conn , paste0( "ALTER TABLE " , tablename , " RENAME TO temp_backup" ) )
		
		# select only the non-toss columns from that backup table into the original tablename
		sql <- paste0( "create table " , tablename , " as select " , paste( Keep.Cols , collapse = ", " ) , " from temp_backup" )
		dbSendQuery( conn , sql )
		
		# throw out the backup table
		dbRemoveTable( conn , "temp_backup" )

	}
	
	# reset scientific notation length
	options( scipen = user.defined.scipen )
	
	TRUE
}
	

