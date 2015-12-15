
# read.SAScii.monetdb depends on the SAScii package and the descr package
# to install these packages, use the line:
# install.packages( c( 'SAScii' , 'descr' , 'downloader' , 'digest' , 'R.utils' , 'ff' ) )
library(SAScii)
library(descr)
library(downloader)
library(R.utils)
library(ff)


# create importation function
# to use different 'NULL AS <something>' options for the actual command that imports
# lines into monetdb: COPY <stuff> INTO <tablename> ...
sql.copy.into <-
	function( nullas , num.lines , tablename , tf2 , connection , delimiters ){
		
		# import the data into the database
		sql.update <- paste0( "copy " , num.lines , " offset 2 records into " , tablename , " from '" , tf2 , "' using delimiters " , delimiters  , nullas ) 
		dbSendQuery( connection , sql.update )
		
		# return true when it's completed
		TRUE
	}
	

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# differences from the SAScii package's read.SAScii() --
# 	um well a whole lot faster
# 	no RAM issues
# 	decimal division must be TRUE/FALSE (as opposed to NULL - the user must decide)
# 	can read in only part of the table with `n_max=`
#	requires MonetDB.R and a few other packages
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

read.SAScii.monetdb <-
	function( 
		# differences between parameters for read.SAScii() (from the R SAScii package)
		# and read.SAScii.monetdb() documented here --
		fn ,
		sas_ri , 
		beginline = 1 , 
		zipped = F , 
		lrecl = NULL , 
		skip.decimal.division = FALSE , # skipping decimal division defaults to FALSE for this function!
		tl = F ,						# convert all column names to lowercase?
		tablename ,
		overwrite = FALSE ,				# overwrite existing table?
		connection ,
		tf.path = NULL ,				# do temporary files need to be stored in a specific folder?
										# this option is useful for keeping protected data off of random temporary folders on your computer--
										# specifying this option creates the temporary file inside the folder specified
		delimiters = "'\t'" ,			# delimiters for the monetdb COPY INTO command
		sleep.between.col.updates = 0 ,
		varchar = TRUE ,				# import character strings as type VARCHAR(255)?  use FALSE to import them as clob
		n_max = -1 ,
		try_best_effort = FALSE
		
	) {

	# before anything else, create the temporary files needed for this function to run
	# if the user doesn't specify that the temporary files get stored in a temporary directory
	# just put them anywhere..
	if ( is.null( tf.path ) ){
		tf <- tempfile()
		td <- tempdir()
		tf2 <- tempfile() 
	} else {
		# otherwise, put them in the protected folder
		tf.path <- normalizePath( tf.path )
		td <- tf.path
		tf <- paste0( tf.path , "/" , tablename , "1" )
		tf2 <- paste0( tf.path , "/" , tablename , "2" )
	}
	
	file.create( tf , tf2 )
	
	
	# scientific notation contains a decimal point when converted to a character string..
	# so store the user's current value and get rid of it.
	user.defined.scipen <- getOption( 'scipen' )
	
	# set scientific notation to something impossibly high.  Inf doesn't work.
	options( scipen = 1000000 )
	
	
	if ( !exists( "download_cached" ) ){
		# load the download_cached and related functions
		# to prevent re-downloading of files once they've been downloaded.
		source_url( 
			"https://raw.github.com/ajdamico/asdfree/master/Download%20Cache/download%20cache.R" , 
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
		#download the CPS repwgts zipped file
		download_cached( fn , tf , mode = "wb" )
		#unzip the file's contents and store the file name within the temporary directory
		fn <- unzip( tf , exdir = td , overwrite = T )
		
		on.exit( file.remove( tf ) )
	}

	# improve speed of `n_max` by limiting the file
	if( n_max != -1 ) {
	
		infile <- read.table.ffdf( file = fn , nrows = n_max , header = FALSE , sep = "\n" , colClasses = "factor" , row.names = NULL , quote = '' , na.strings = NULL , comment.char = "" )
	
		file.remove( fn )
		
		write.table.ffdf( infile , file = fn , col.names = FALSE , row.names = FALSE , quote = FALSE , sep = "" , na = "" )
		
		rm( infile )
	
	}
	
	
	# if the overwrite flag is TRUE, then check if the table is in the database..
	if ( overwrite ){
		# and if it is, remove it.
		if ( tablename %in% dbListTables( connection ) ) dbRemoveTable( connection , tablename )
		
		# if the overwrite flag is false
		# but the table exists in the database..
	} else {
		if ( tablename %in% dbListTables( connection ) ) stop( "table with this name already in database" )
	}
	
	if ( sum( grepl( 'sample' , tolower( y$varname ) ) ) > 0 ){
		print( 'warning: variable named sample not allowed in monetdb' )
		print( 'changing column name to sample_' )
		y$varname <- gsub( 'sample' , 'sample_' , y$varname )
	}
	
	fields <- y$varname

	if( varchar ){
		colTypes <- ifelse( !y[ , 'char' ] , 'DOUBLE PRECISION' , 'VARCHAR(255)' )
	} else {
		colTypes <- ifelse( !y[ , 'char' ] , 'DOUBLE PRECISION' , 'clob' )
	}
	

	colDecl <- paste( fields , colTypes )

	sql.create <-
		sprintf(
			paste(
				"CREATE TABLE" ,
				tablename ,
				"(%s)"
			) ,
			paste(
				colDecl ,
				collapse = ", "
			)
		)
	
	# starts and ends
	w <- abs ( x$width )
	s <- 1
	e <- w[ 1 ]
	for ( i in 2:length( w ) ) {
		s[ i ] <- s[ i - 1 ] + w[ i - 1 ]
		e[ i ] <- e[ i - 1 ] + w[ i ]
	}
	
	# create another file connection to the temporary file to store the fwf2csv output..
	
	# convert the fwf to a csv
	# verbose = TRUE prints a message, which has to be captured.
	fwf2csv( fn , tf2 , names = x$varname , begin = s , end = e , verbose = F )
	on.exit( { file.remove( tf2 ) } )
	
	# ..and that's the number of lines in the file
	if( n_max == -1 ) num.lines <- countLines( tf2 ) else num.lines <- n_max
	
	# in speed tests, adding the exact number of lines in the file was much faster
	# than setting a very high number and letting it finish..

	# create the table in the database
	dbSendQuery( connection , sql.create )
	
	##############################
	# begin importation attempts #

	# notice the differences in the NULL AS <stuff> for the five different attempts.
	# monetdb importation is finnicky, so attempt a bunch of different COPY INTO tries
	# using the sql.copy.into() function defined above
	
	# capture an error (without breaking)
	te <- try( sql.copy.into( " NULL AS ''" , num.lines , tablename , tf2  , connection , delimiters )  , silent = TRUE )

	# try another delimiter statement
	if ( class( te ) == "try-error" ){
		cat( 'attempt #1 broke, trying method #2' , "\r" )
		print( te )
		te <- try( sql.copy.into( " NULL AS ' '" , num.lines , tablename , tf2  , connection , delimiters )  , silent = TRUE )
	}

	# try another delimiter statement
	if ( class( te ) == "try-error" ){
		cat( 'attempt #2 broke, trying method #3' , "\r"  )
		print( te )
		te <- try( sql.copy.into( "" , num.lines , tablename , tf2  , connection , delimiters )  , silent = TRUE )
	}
	
	# try another delimiter statement
	if ( class( te ) == "try-error" ){
		cat( 'attempt #3 broke, trying method #4' , "\r"  )
		print( te )
		te <- try( sql.copy.into( paste0( " NULL AS '" , '""' , "'" ) , num.lines , tablename , tf2  , connection , delimiters )  , silent = TRUE )
	}

	if ( class( te ) == "try-error" ){
		cat( 'attempt #4 broke, trying method #5' , "\r" )
		print( te )
		# this time without error-handling.
		# do you want to try the BEST EFFORT flag for COPY INTO?
		te <- try( sql.copy.into( " NULL AS '' ' '" , num.lines , tablename , tf2  , connection , delimiters ) , silent = TRUE )
	}
	
	
	if( class( te ) == 'try-error' ){
	
		if( !try_best_effort ) stop( "ran out if import ideas" ) else{
		
			sql.update <- paste0( "copy " , num.lines , " offset 2 records into " , tablename , " from '" , tf2 , "' using delimiters " , delimiters , " BEST EFFORT" ) 
			dbSendQuery( connection , sql.update )
		
		}
		
	}
	
	# end importation attempts #
	############################	
	
	
	# loop through all columns to:
		# convert to numeric where necessary
		# divide by the divisor whenever necessary
	for ( l in seq( nrow(y) ) ){
	
		if ( 
			( y[ l , "divisor" ] != 1 ) & 
			!( y[ l , "char" ] )
		) {
			
			sql <- 
				paste( 
					"UPDATE" , 
					tablename , 
					"SET" , 
					y[ l , 'varname' ] , 
					"=" ,
					y[ l , 'varname' ] , 
					"*" ,
					y[ l , "divisor" ]
				)
				
			if ( !skip.decimal.division ){
				dbSendQuery( connection , sql )
			
				# give the MonetDB mserver.exe a certain number of seconds to process each column
				Sys.sleep( sleep.between.col.updates )
			}
		
		}
			
		cat( "  current progress: " , l , "of" , nrow( y ) , "columns processed.                    " , "\r" )
	

	}
	
	# eliminate gap variables.. loop through every gap
	if ( num.gaps > 0 ){
		for ( i in seq( num.gaps ) ) {
		
			# create a SQL query to drop these columns
			sql.drop <- paste0( "ALTER TABLE " , tablename , " DROP toss_" , i )
			
			# and drop them!
			dbSendQuery( connection , sql.drop )
		}
	}
	
	# reset scientific notation length
	options( scipen = user.defined.scipen )

	TRUE
}
