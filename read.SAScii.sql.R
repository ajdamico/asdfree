# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# warnings:
# experimental!
# decimal division isn't flexible
# must read in the entire table
# BUT multiple tables can contribute to a single final db-table
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

read.SAScii.sql <-
	function( 
		fn , 			# either a string pointing to an ASCII file or a character vector containing multiple!
		sas_ri , 
		beginline = 1 , 
		zipped = F , 
		# n = -1 , 		# no n parameter available for this - you must read in the entire table!
		lrecl = NULL , 
		# skip.decimal.division = NULL , skipping decimal division not an option
		tl = F ,		# convert all column names to lowercase?
		tablename ,
		dbname 
	) {

	# read.SAScii.sql depends on two packages:
	require(SAScii)
	require(RSQLite)
	
	x <- parse.SAScii( sas_ri , beginline , lrecl )
	
	if( tl ) x$varname <- tolower( x$varname )
	
	#only the width field should include negatives
	y <- x[ !is.na( x[ , 'varname' ] ) , ]
	
	
	#if the ASCII file is stored in an archive, unpack it to a temporary file and run that through read.fwf instead.
	if ( zipped ){
		#create a temporary file and a temporary directory..
		tf <- tempfile() ; td <- tempdir()
		#download the CPS repwgts zipped file
		download.file( fn , tf , mode = "wb" )
		#unzip the file's contents and store the file name within the temporary directory
		fn <- unzip( tf , exdir = td , overwrite = T )
	}

	# this next block of code thanks to Seth Falcon!
	# largely pulled from--
	# http://r.789695.n4.nabble.com/How-to-Read-a-Large-CSV-into-a-Database-with-R-td3043209.html
	
	# input actual SAS data text-delimited file to read in
	
	file_list <- fn
	
	input <- file( file_list[1] , "r" )
	
	db <- dbConnect( SQLite(), dbname = dbname)

	fields <- y$varname

	colTypes <- rep( "TEXT" , length( fields ) )

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

	dbGetQuery( db , sql )

	colClasses <- ifelse( !y[ , 'char' ] , 'numeric' , 'character' )
	
	sql.in <- 
		sprintf( 
			paste( 
				"INSERT INTO" ,
				tablename , 
				"VALUES (%s)"
			) ,
			paste(
				rep(
					"?" , 
					length( fields ) 
				) ,
				collapse = ","
			)
		)
			
	# read in 1000 records at a time!
	chunk_size <- 1000
	# increasing this doesn't noticeably improve speed..
	# at least not 1,000 vs. 25,000

	current.position <- 0

	dbBeginTransaction(db)

	tryCatch(
		{
			while (TRUE) {
		
				part <- 
					read.fwf(
						input , 
						n = chunk_size , 
						widths = x$width ,
						colClasses = colClasses ,
						comment.char = ""
					)
						
				dbGetPreparedQuery( 
					db , 
					sql.in , 
					bind.data = part
				)
			
				current.position <- current.position + nrow( part )

				rm( part )
				
				gc()
				
				cat( 
					"  current progress: read.SAScii.sql has read in" , 
					prettyNum( 
						current.position , 
						big.mark = "," 
					) , 
					"records                    " , 
					"\r" 
				)

			}
		} , 
		error = 
			function(e) {
				if (grepl("no lines available", conditionMessage(e)))
					TRUE
				else
					stop(conditionMessage(e))
			}
	)
	
	dbCommit(db)
	
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
				
			dbSendQuery( db , sql )
			
		}
			
		cat( "  current progress: " , l , "of" , nrow( y ) , "columns processed.                    " , "\r" )
	
	}
	
	dbDisconnect(db)

}
	

