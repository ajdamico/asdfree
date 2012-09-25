# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# differences from the SAScii package's read.SAScii() --
# 	3.5x faster
# 	no RAM issues
# 	decimal division isn't flexible
# 	must read in the entire table
#	no gaps allows between columns
#	requires RMonetDB and a few other packages
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

read.SAScii.sql <-
	function( 
		fn ,
		sas_ri , 
		beginline = 1 , 
		zipped = F , 
		# n = -1 , 			# no n parameter available for this - you must read in the entire table!
		lrecl = NULL , 
		# skip.decimal.division = NULL , skipping decimal division not an option
		tl = F ,			# convert all column names to lowercase?
		tablename ,
		overwrite = FALSE ,	# overwrite existing table?
		monetdriver			# path to the "monetdb-jdbc-#.#.jar" file on your local computer
		
	) {
		
	# to install MonetDB, use the line:
	# install.packages( "RMonetDB" , repos = c( "http://cran.r-project.org" , "http://R-Forge.R-project.org" ) , dep=TRUE )
	require(RMonetDB)
	drv <- MonetDB( classPath = monetdriver )

	
	# scientific notation contains a decimal point when converted to a character string..
	# so store the user's current value and get rid of it.
	user.defined.scipen <- getOption( 'scipen' )
	
	# set scientific notation to something impossibly high.  Inf doesn't work.
	options( scipen = 1000000 )
	
	
	# read.SAScii.sql depends on the SAScii package and the descr package
	# to install these packages, use the line:
	# install.packages( c( 'SAScii' , 'descr' ) )
	require(SAScii)
	require(descr)
	
	
	x <- parse.SAScii( sas_ri , beginline , lrecl )
	
	if( tl ) x$varname <- tolower( x$varname )
	
	#only the width field should include negatives
	y <- x[ !is.na( x[ , 'varname' ] ) , ]
	
	
	# if there are any gaps between columns, this version of read.SAScii.sql will not work
	# because of the fwf2csv() function -- look at old versions of read.SAScii.sql() (prior to september 19th, 2012)
	# for a read.SAScii.sql() version that used read.SAScii() instead of just parse.SAScii()
	if ( nrow( y ) != nrow( x ) ) stop( "gaps not allowed in this version of read.SAScii.sql()" )
	
	#if the ASCII file is stored in an archive, unpack it to a temporary file and run that through read.fwf instead.
	if ( zipped ){
		#create a temporary file and a temporary directory..
		tf <- tempfile() ; td <- tempdir()
		#download the CPS repwgts zipped file
		download.file( fn , tf , mode = "wb" )
		#unzip the file's contents and store the file name within the temporary directory
		fn <- unzip( tf , exdir = td , overwrite = T )
	}

	
	# connect to the database
	db <- dbConnect( drv , "jdbc:monetdb://localhost/demo" , user = "monetdb" , password = "monetdb" )
	
	
	
	# if the overwrite flag is TRUE, then check if the table is in the database..
	if ( overwrite ){
		# and if it is, remove it.
		if ( tablename %in% dbListTables( db ) ) dbRemoveTable( db , tablename )
		
		# if the overwrite flag is false
		# but the table exists in the database..
	} else {
		if ( tablename %in% dbListTables( db ) ) stop( "table with this name already in database" )
	}
	
	if ( sum( grepl( 'sample' , tolower( y$varname ) ) ) > 0 ){
		print( 'warning: variable named sample not allowed in monetdb' )
		print( 'changing column name to sample_' )
		y$varname <- gsub( 'sample' , 'sample_' , y$varname )
	}
	
	fields <- y$varname

	colTypes <- ifelse( !y[ , 'char' ] , 'DOUBLE PRECISION' , 'VARCHAR(255)' )
	

	colDecl <- paste( fields , colTypes )

	sql <-
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
	
	dbSendUpdate( db , sql )

	# create a second temporary file
	tf2 <- tempfile()

	# starts and ends
	w <- abs ( x$width )
	s <- 1
	e <- w[ 1 ]
	for ( i in 2:length( w ) ) {
		s[ i ] <- s[ i - 1 ] + w[ i - 1 ]
		e[ i ] <- e[ i - 1 ] + w[ i ]
	}
	
	# convert the fwf to a csv
	fwf2csv( fn , tf2 , names = x$varname , begin = s , end = e )

	# quickly figure out the number of lines in the data file
	# code thanks to 
	# http://costaleconomist.blogspot.com/2010/02/easy-way-of-determining-number-of.html

	# in speed tests, increasing this chunk_size does nothing
	chunk_size <- 1000
	testcon <- file( tf2 ,open = "r" )
	nooflines <- 0
	( while( ( linesread <- length( readLines( testcon , chunk_size ) ) ) > 0 )
	nooflines <- nooflines + linesread )
	close( testcon )
	
	# in speed tests, adding the exact number of lines in the file was much faster
	# than setting a very high number and letting it finish..
	
	# pull the csv file into the database
	dbSendUpdate( db , paste0( "copy " , nooflines , " offset 2 records into " , tablename , " from '" , tf2 , "' using delimiters '\t' NULL AS ''" ) )
	
	# delete the temporary file from the hard disk
	file.remove( tf2 )
		
	# loop through all columns to:
		# convert to numeric where necessary
		# divide by the divisor whenever necessary
	for ( l in 1:nrow(y) ){
	
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
				
			dbSendUpdate( db , sql )
			
		}
			
		cat( "  current progress: " , l , "of" , nrow( y ) , "columns processed.                    " , "\r" )
	
	}
	
	# close the database connection
	dbDisconnect(db)
	
	# reset scientific notation length
	options( scipen = user.defined.scipen )
		
	NULL
}
