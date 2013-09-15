

clear.goofy.characters <-
	function( fn ){
	
		tf <- tempfile()
		
		# initiate a read-only connection to the input file
		incon <- file( fn , "r")

		outcon <- file( tf , "w" )

		# loop through every row of data in the original input file
		while( length( line <- readLines( incon , 1 ) ) > 0 ){

			# remove goofy special characters (that will break monetdb)
			line <- iconv( line , "" , "ASCII" , " " )
		
			writeLines( line , outcon )
		}
		
		# close all file connections
		close( outcon )
		close( incon )
		
		tf
	}


import.nchs <-
	function(
		files.to.import ,
		sas.scripts ,
		db
	){

		# figure out tablename from the files.to.import
		tablenames <-
			gsub( "./" , "" , files.to.import , fixed = TRUE )
		
		tablenames <-
			gsub( ".dat" , "" , tablenames , fixed = TRUE )

		tablenames <-
			gsub( "/x" , "/" , tablenames , fixed = TRUE )

		tablenames <-
			gsub( "/" , "_" , tablenames , fixed = TRUE )
			
	
		for ( i in seq( length( tablenames ) ) ){
	
			cat( 'currently working on' , tablenames[ i ] , '\r' )
			
			fti <- clear.goofy.characters( files.to.import[ i ] )
			
			on.exit( file.remove( fti ) )
			
			read.SAScii.monetdb( 
				fn = fti ,
				sas_ri = remove.overlap( sas.scripts[ i ] ) , 
				beginline = 1 , 
				zipped = FALSE , 
				tl = TRUE ,						# convert all column names to lowercase?
				tablename = tablenames[ i ] ,
				overwrite = FALSE ,				# overwrite existing table?
				connection = db
			)
			
			file.remove( fti )
			
		}
		
		TRUE
	}




extract.files <-
	function( y , name ){
	
		y <- y[ grep( name , y ) ]
	
		y <- tolower( y )

		pdfs <- y[ grep( "(ftp://ftp.cdc.gov/.*\\.pdf)" , y ) ]

		pdf.files <- gsub( "(.*a href=\\\")(ftp://ftp.cdc.gov/.*\\.pdf)(.*)$" , "\\2" , pdfs )

		zips <- y[ grep( "(ftp://ftp.cdc.gov/.*\\.zip)" , y ) ]

		ps <- zips[ grep( 'ps.zip' , zips ) ]
		us <- zips[ !grepl( 'ps.zip' , zips ) ]

		ps.files <- gsub( "(.*a href=\\\")(ftp://ftp.cdc.gov/.*\\.zip)(.*)$" , "\\2" , ps )
		us.files <- gsub( "(.*a href=\\\")(ftp://ftp.cdc.gov/.*\\.zip)(.*)$" , "\\2" , us )

		list( name = name , pdfs = pdf.files , ps = ps.files , us = us.files )
	}
	

##############################################################################
# add starting blanks
add.blanks <-
	function( sasfile ){
		sas_lines <- tolower( readLines( sasfile ) )

		if( any( grepl( "@19   rectype        1." , sas_lines ) ) ){
		
			sas_lines <- gsub( "@19   rectype        1." , "@1 blank $ 18 @19   rectype        1." , sas_lines )
		
		} else if ( any( grepl( "@20   restatus       1." , sas_lines ) ) ) {
		
			sas_lines <- gsub( "@20   restatus       1." , "@1 blank $ 19 @20   restatus       1." , sas_lines )
		
		}
		
		
		# the column name `year` is illegal.
		sas_lines <- gsub( " year " , " yearz " , sas_lines )
		
		
		# create a temporary file
		tf <- tempfile()

		# write the updated sas input file to the temporary file
		writeLines( sas_lines , tf )

		# return the filepath to the temporary file containing the updated sas input script
		tf
	}
##############################################################################

##############################################################################
# order fields
order.at.signs <-
	function( sasfile , add.blank = FALSE ){
		sas_lines <- tolower( readLines( sasfile ) )

		ats <- sas_lines[ substr( sas_lines , 1 , 1 ) == "@" ]

		positions <- as.numeric( substr( ats , 2 , 5 ) )

		sas_lines <- ats[ order( positions ) ]

		# if the first position is missing..
		if ( ( sort( positions )[ 1 ] != 1 ) & add.blank ){
		
			# ..add a blank column
			new.line <- paste( "@1 blank" , sort( positions )[ 1 ] - 1 )
			
			sas_lines <- c( new.line , sas_lines )
		}
				
		sas_lines <- c( "INPUT" , sas_lines , ";" )
		
		# create a temporary file
		tf <- tempfile()

		# write the updated sas input file to the temporary file
		writeLines( sas_lines , tf )

		# return the filepath to the temporary file containing the updated sas input script
		tf
	}
##############################################################################



##############################################################################
# function to remove overlapping columns
remove.overlap <-
	function( sasfile ){
		sas_lines <- tolower( readLines( sasfile ) )

		sas_lines <- gsub( "@214 ucr130 3." , "@214 ucr130 $ 3." )
		
		sas_lines <- gsub( "@7    revision" , "@1    BLANK $6 @7    revision" , sas_lines )
		sas_lines <- gsub( "@4    reparea        1." , "@4    reparea        $1" , sas_lines )
		
		
		if ( sas_lines[ 25 ] == "                    @19 cntyocb 3." & sas_lines[ 26 ] == "                    @17 stateocb 2." ){
			sas_lines[ 25 ] <- "                    @17 stateocb 2."
			sas_lines[ 26 ] <- "                    @19 cntyocb 3."
		}
		
		overlap.fields <- 
			c( 'rdscresb' , 'regnresb' , 'divresb' , 'estatrsb' , 'cntyresb' , 'statersb' , 'rdsscocd' , 'regnoccd' , 
				'divoccd' , 'estatocd' , 'cntyocd' , 'stateocd' , 'rdscresd' , 'regnresd' , 'divresd' , 'estatrsd' , 
				'cntyresd' , 'statersd' , 'cityresd' , 'cityresb' , 'rdsscocb' , 'regnoccb' , 'divoccb' , 'estatocb' , 'cntyocb' , 
				'stateocb' , 'stateoc' , 'staters' , paste0( "rnifla_" , 1:14 ) , paste0( 'entity' , 1:14 ) , 'divocc' , 
				'statenat' , 'stoccfip' , 'divres' , 'stateres' , 'stresfip' , 'feduc6' ,
				'stocfipb' , 'strefipb' , 'delmeth' , 'medrisk' , 'otherrsk' , 'obstetrc' , 'labor' , 'newborn' , 'congenit' , 'flres' , 
				paste0( 'rnifla_' , 1:9 ) , paste0( 'rnifl_' , 10:20 ) , paste0( 'entity_' , 1:9 ) , paste0( 'entit_' , 10:20 ) , 
				paste0( 'enifla_' , 1:9 ) , paste0( 'enifl_' , 10:20 ) , 'stocfipd' , 'strefipd'
			)
		
		sas_lines <- sas_lines[ !grepl( paste( overlap.fields , collapse = "|" ) , sas_lines ) ]

		# create a temporary file
		tf <- tempfile()

		# write the updated sas input file to the temporary file
		writeLines( sas_lines , tf )

		# return the filepath to the temporary file containing the updated sas input script
		tf
	}
##############################################################################


download.nchs <-
	function( y ){
		
		tf <- tempfile() ; td <- tempdir()
		
		on.exit( file.remove( tf ) )
		
		on.exit( unlink( td ) )
		
		dir.create( y$name )
		
		dir.create( paste( y$name , "us" , sep = "/" ) )
		
		dir.create( paste( y$name , "ps" , sep = "/" ) )
		
		for ( i in c( y$us , y$ps ) ){
			
			curYear <- as.numeric( gsub( "\\D" , "" , i ) )
			if ( curYear < 50 ) curYear <- curYear + 2000
			if ( curYear > 50 & curYear < 100 ) curYear <- curYear + 1900
			
			download.file( i , tf , mode = 'wb' )
			
			z <- tolower( unzip( tf , exdir = td ) )
			
			file.remove( tf )
			
			if ( y$name %in% c( 'mortality' , 'natality' , 'fetaldeath' ) ){
				
				if ( y$name == 'mortality' & curYear == 1994 ){
				
					# add the puerto rico file to the guam file
					file.append( z[ 1 ] , z[ 2 ] )
					# add the virgin islands file to the puerto rico + guam file
					file.append( z[ 1 ] , z[ 3 ] )
					
					# remove those two files from the disk
					file.remove( z[ 2 ] , z[ 3 ] )
					
					# remove those two files from the vector
					z <- z[ -2:-3 ]
				
				}
				
				file.copy( 
					z , 
					paste( 
						"." , 
						y$name , 
						ifelse( i %in% y$us , "us" , "ps" ) , 
						paste0( "x" , curYear , ".dat" ) , 
						sep = "/" 
					) 
				)
				
			} else {
			
				# confirm it's got at least two files..
				stopifnot( length( z ) > 1 )
				# some years don't have unlinked, so this test is not necessary
				# stopifnot( any( un <- grepl( 'un' , z ) ) )
				
				stopifnot( any( num <- grepl( 'num' , z ) ) )
				
				stopifnot( any( den <- grepl( 'den' , z ) ) )
			
				if ( any( un <- grepl( 'un' , z ) ) ){
				
					file.copy( z[ un ] , paste( "." , y$name , ifelse( i %in% y$us , "us" , "ps" ) , paste0( "unl" , curYear , ".dat" ) , sep = "/" ) )
				
				}
				
				file.copy( z[ num ] , paste( "." , y$name , ifelse( i %in% y$us , "us" , "ps" ) , paste0( "num" , curYear , ".dat" ) , sep = "/" ) )
				
				file.copy( z[ den ] , paste( "." , y$name , ifelse( i %in% y$us , "us" , "ps" ) , paste0( "den" , curYear , ".dat" ) , sep = "/" ) )
				
			}
			
			file.remove( z )
			
		}	
		
		dir.create( paste( y$name , "docs" , sep = "/" ) )
		
		for ( i in y$pdfs ){
			attempt.one <- try( download.file( i , paste( "." , y$name , "docs" , basename( i ) , sep = "/" ) , mode = 'wb' ) , silent = TRUE )
			
			if ( class( attempt.one ) == 'try-error' ) {
				Sys.sleep( 60 )
				
				download.file( i , paste( "." , y$name , "docs" , basename( i ) , sep = "/" ) , mode = 'wb' )
			}
		}
			
		TRUE
	}
	
	
	
	