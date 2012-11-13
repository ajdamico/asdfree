# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# differences from the SAScii package's read.SAScii() --
# 	4x faster
# 	no RAM issues
# 	decimal division isn't flexible
# 	must read in the entire table
#	requires RMonetDB and a few other packages
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

read.SAScii.monetdb <-
	function( 
		fn ,
		sas_ri , 
		beginline = 1 , 
		zipped = F , 
		# n = -1 , 				# no n parameter available for this - you must read in the entire table!
		lrecl = NULL , 
		# skip.decimal.division = NULL , skipping decimal division not an option
		tl = F ,				# convert all column names to lowercase?
		tablename ,
		overwrite = FALSE ,		# overwrite existing table?
		monet.drv ,
		monet.url ,
		tf.path = NULL ,		# do temporary files need to be stored in a specific folder?
								# this option is useful for keeping protected data off of random temporary folders on your computer--
								# specifying this option creates the temporary file inside the folder specified
		delimiters = "'\t'" , 	# delimiters for the monetdb COPY INTO command
		shell.refresh = NULL	# if the database connection isn't alive, run this command to refresh it			
		
	) {

	# connect to the database
	connection <- dbConnect( monet.drv , monet.url , user = "monetdb" , password = "monetdb" )
	
	# check that autocommit mode isn't on
	ac <- .jcall(connection@jc, "Z", "getAutoCommit")
	if ( !ac ) stop( "read.SAScii.monetdb() only works in autocommit mode")

	# before anything else, create the temporary files needed for this function to run
	# if the user doesn't specify that the temporary files get stored in a temporary directory
	# just put them anywhere..
	if ( is.null( tf.path ) ){
		tf <- tempfile()
		td <- tempdir()
		tf2 <- tempfile() 
		tf3 <- tempfile()
	} else {
		# otherwise, put them in the protected folder
		tf.path <- normalizePath( tf.path )
		td <- tf.path
		tf <- normalizePath( paste0( tf.path , tablename , "1" ) )
		tf2 <- normalizePath( paste0( tf.path , tablename , "2" ) )
		tf3 <- normalizePath( paste0( tf.path , tablename , "3" ) )
	}

	# scientific notation contains a decimal point when converted to a character string..
	# so store the user's current value and get rid of it.
	user.defined.scipen <- getOption( 'scipen' )
	
	# set scientific notation to something impossibly high.  Inf doesn't work.
	options( scipen = 1000000 )
	
	
	# read.SAScii.monetdb depends on the SAScii package and the descr package
	# to install these packages, use the line:
	# install.packages( c( 'SAScii' , 'descr' ) )
	require(SAScii)
	require(descr)
	
	
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
		download.file( fn , tf , mode = "wb" )
		#unzip the file's contents and store the file name within the temporary directory
		fn <- unzip( tf , exdir = td , overwrite = T )
		
		on.exit( file.remove( tf ) )
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

	colTypes <- ifelse( !y[ , 'char' ] , 'DOUBLE PRECISION' , 'VARCHAR(255)' )
	

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
	zz <- file( tf3 , open = 'wt' )
	sink( zz , type = 'message' )
	
	# convert the fwf to a csv
	# verbose = TRUE prints a message, which has to be captured.
	fwf2csv( fn , tf2 , names = x$varname , begin = s , end = e , verbose = TRUE )
	on.exit( { file.remove( tf ) ; file.remove( tf2 ) } )
	
	# stop storing the output
	sink( type = "message" )
	unlink( tf3 )
	on.exit( { file.remove( tf ) ; file.remove( tf2 ) ; file.remove( tf3 ) } )
	
	# read the contents of that message into a character string
	zzz <- readLines( tf3 )
	
	# read it up to the first space..
	last.char <- which( strsplit( zzz , '')[[1]]==' ')
	
	# ..and that's the number of lines in the file
	num.lines <- substr( zzz , 1 , last.char - 1 )
	
	# in speed tests, adding the exact number of lines in the file was much faster
	# than setting a very high number and letting it finish..

	# if the shell.refresh parameter isn't missing
	if ( !is.null( shell.refresh ) & class( try( dbListTables( connection ) , silent = TRUE ) ) == 'try-error' ){
		eval( shell.refresh )
		connection <- dbConnect( monet.drv , monet.url , user = "monetdb" , password = "monetdb" )
	}
	
	# create the table in the database
	dbSendUpdate( connection , sql.create )
	
	# import the data into the database
	sql.update <- paste0( "copy " , num.lines , " offset 2 records into " , tablename , " from '" , tf2 , "' using delimiters " , delimiters  , " NULL AS '' ' '" ) 
	# capture an error (without breaking)
	te <- try( dbSendUpdate( connection , sql.update ) , silent = TRUE )

	# and try another delimiter statement
	if ( class( te ) == "try-error" ){
		
		# print the error and indicate moving forward..
		print( te )
		print( 'attempt #1 broke, trying method #2' )

		# if the shell.refresh parameter isn't missing
		if ( !is.null( shell.refresh ) & class( try( dbListTables( connection ) , silent = TRUE ) ) == 'try-error' ){
			eval( shell.refresh )
			connection <- dbConnect( monet.drv , monet.url , user = "monetdb" , password = "monetdb" )
		}
		
		sql.update <- paste0( "copy " , num.lines , " offset 2 records into " , tablename , " from '" , tf2 , "' using delimiters " , delimiters ) 
		te <- try( dbSendUpdate( connection , sql.update ) , silent = TRUE )
	}

	if ( class( te ) == "try-error" ){
	
		print( te )
		print( 'attempt #2 broke, trying method #3' )
		
		# if the shell.refresh parameter isn't missing
		if ( !is.null( shell.refresh ) & class( try( dbListTables( connection ) , silent = TRUE ) ) == 'try-error' ){
			eval( shell.refresh )
			connection <- dbConnect( monet.drv , monet.url , user = "monetdb" , password = "monetdb" )
		}
		
		sql.update <- paste0( "copy " , num.lines , " offset 2 records into " , tablename , " from '" , tf2 , "' using delimiters " , delimiters , " NULL AS '" , '""' , "'" ) 
		te <- try( dbSendUpdate( connection , sql.update ) , silent = TRUE )
	}

	if ( class( te ) == "try-error" ){

		print( te )
		print( 'attempt #3 broke, trying method #4' )

		# if the shell.refresh parameter isn't missing
		if ( !is.null( shell.refresh ) & class( try( dbListTables( connection ) , silent = TRUE ) ) == 'try-error' ){
			eval( shell.refresh )
			connection <- dbConnect( monet.drv , monet.url , user = "monetdb" , password = "monetdb" )
		}
		
		sql.update <- paste0( "copy " , num.lines , " offset 2 records into " , tablename , " from '" , tf2 , "' using delimiters " , delimiters , " NULL AS ''" ) 
		te <- try( dbSendUpdate( connection , sql.update ) , silent = TRUE )
	}
	
	if ( class( te ) == "try-error" ){
		
		print( te )
		print( 'attempt #4 broke, trying method #5' )
	
		# if the shell.refresh parameter isn't missing
		if ( !is.null( shell.refresh ) & class( try( dbListTables( connection ) , silent = TRUE ) ) == 'try-error' ){
			eval( shell.refresh )
			connection <- dbConnect( monet.drv , monet.url , user = "monetdb" , password = "monetdb" )
		}
		
		sql.update <- paste0( "copy " , num.lines , " offset 2 records into " , tablename , " from '" , tf2 , "' using delimiters " , delimiters , " NULL AS ' '" ) 
		
		# this one no longer includes a try() - because it's the final attempt
		dbSendUpdate( connection , sql.update )
	}

		
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
				
			dbSendUpdate( connection , sql )
			
		}
			
		cat( "  current progress: " , l , "of" , nrow( y ) , "columns processed.                    " , "\r" )
	
	}
	
	# eliminate gap variables.. loop through every gap
	if ( num.gaps > 0 ){
		for ( i in seq( num.gaps ) ) {
		
			# create a SQL query to drop these columns
			sql.drop <- paste0( "ALTER TABLE " , tablename , " DROP toss_" , i )
			
			# and drop them!
			dbSendUpdate( connection , sql.drop )
		}
	}
	
	# reset scientific notation length
	options( scipen = user.defined.scipen )

	# disconnect from the database
	dbDisconnect( connection )
	
	TRUE
}
