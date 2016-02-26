
# this function reads through every line in a .dat file
# and converts unknown character types to ASCII,
# so monetdb will not break during data importation
clear.goofy.characters <-
	function( fn , fl ){
	
		tf <- tempfile()
		
		# initiate a read-only connection to the input file
		incon <- file( fn , "r")

		outcon <- file( tf , "w" )

		# loop through every row of data in the original input file
		while( length( line <- readLines( incon , 1 ) ) > 0 ){

			# remove goofy special characters (that will break monetdb)
			line <- iconv( line , "" , "ASCII" , " " )
		
			# if there's an enforced line length..
			if( fl ){
				# ..then confirm the current line matches that length before writing
				if( nchar( line ) == fl ) writeLines( line , outcon )
				
			} else {
				# otherwise just write it.
				writeLines( line , outcon )
			}
		}
		
		# close all file connections
		close( outcon )
		close( incon )
		
		tf
	}


# this function prepares and then executes a read.SAScii.monetdb call
import.nchs <-
	function(
		files.to.import ,
		sas.scripts ,
		db ,
		force.length = FALSE
	){

		gc()
	
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
			
			fti <- clear.goofy.characters( files.to.import[ i ] , fl = force.length )
			
			on.exit( suppressWarnings( while( any( unlink( fti ) ) ) Sys.sleep( 1 ) ) )
			
			read.SAScii.monetdb( 
				fn = fti ,
				sas_ri = remove.overlap( sas.scripts[ i ] ) , 
				beginline = 1 , 
				zipped = FALSE , 
				tl = TRUE ,						# convert all column names to lowercase?
				tablename = tablenames[ i ] ,
				overwrite = FALSE ,				# overwrite existing table?
				connection = db ,
				try_best_effort = TRUE
			)
			
			suppressWarnings( while( unlink( fti ) ) Sys.sleep( 1 ) )
			
		}
		
		gc()
		
		TRUE
	}


# this function figures out the filepaths of all zipped and pdf files
# from the cdc's website that store mortality, cohort-linked, period-linked, natality, and fetal death files
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
	

# this function adds starting blanks to sas importation scripts
# that are not already available
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


# this function extend missing blank field positions after frace
extend.frace <-
	function( sasfile ){
		sas_lines <- tolower( readLines( sasfile ) )

		
		sas_lines <- gsub( "@1443 frace8e       $3. " , "@1443 frace8e       $3. @1446 endblank $ 55." , sas_lines , fixed = TRUE )
				
		# create a temporary file
		tf <- tempfile()

		# write the updated sas input file to the temporary file
		writeLines( sas_lines , tf )

		# return the filepath to the temporary file containing the updated sas input script
		tf
	}

	
# this function re-orders lines in sas importion
# scripts, based on the @ sign positions
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

	
# this function to removes hard-coded overlapping columns
remove.overlap <-
	function( sasfile ){
		sas_lines <- tolower( readLines( sasfile ) )

		sas_lines <- sas_lines[ sas_lines != "@119  fipssto           $2. " ]
		sas_lines <- sas_lines[ sas_lines != "@124  fipsstr           $2. " ]
		
		sas_lines <- gsub( "@214 ucr130 3." , "@214 ucr130 $ 3." , sas_lines )
		
		sas_lines <- gsub( "@107  mrace6             2" , "@107  mrace6             1" , sas_lines )
		sas_lines <- gsub( "@9    dob_yy             4" , "@1 BLANK $8  @9    dob_yy             4" , sas_lines )
		sas_lines <- gsub( "@7    revision" , "@1    BLANK $6 @7    revision" , sas_lines )
		sas_lines <- gsub( "@4    reparea        1." , "@4    reparea        $1" , sas_lines )
		
		
		if ( sas_lines[ 25 ] == "                    @19 cntyocb 3." & sas_lines[ 26 ] == "                    @17 stateocb 2." ){
			sas_lines[ 25 ] <- "                    @17 stateocb 2."
			sas_lines[ 26 ] <- "                    @19 cntyocb 3."
		}
		
		overlap.fields <- 
			c( 'rdscresb' , 'regnresb' , 'divresb' , 'estatrsb' , 'cntyresb' , 'statersb' , 'rdsscocd' , 'regnoccd' , "regnocc" , "regnres" ,
				'divoccd' , 'estatocd' , 'cntyocd' , 'stateocd' , 'rdscresd' , 'regnresd' , 'divresd' , 'estatrsd' , 
				'cntyresd' , 'statersd' , 'cityresd' , 'cityresb' , 'rdsscocb' , 'regnoccb' , 'divoccb' , 'estatocb' , 'cntyocb' , 
				'stateocb' , 'stateoc' , 'staters' , paste0( "rnifla_" , 1:14 ) , paste0( 'entity' , 1:14 ) , 'divocc' , 
				'statenat' , 'stoccfip' , 'divres' , 'stateres' , 'stresfip' , 'feduc6' ,
				'stocfipb' , 'strefipb' , 'delmeth' , 'medrisk' , 'otherrsk' , 'obstetrc' , 'labor' , 'newborn' , 'congenit' , 'flres' , 
				paste0( 'rnifla_' , 1:9 ) , paste0( 'rnifl_' , 10:20 ) , paste0( 'entity_' , 1:9 ) , paste0( 'entit_' , 10:20 ) , 
				paste0( 'enifla_' , 1:9 ) , paste0( 'enifl_' , 10:20 ) , 'stocfipd' , 'strefipd'
			)
		
		sas_lines <- sas_lines[ !grepl( paste( overlap.fields , collapse = "|" ) , sas_lines ) ]

		
		# the column name `year` is illegal.
		sas_lines <- gsub( " year " , " yearz " , sas_lines )
		
		
		# create a temporary file
		tf <- tempfile()

		# write the updated sas input file to the temporary file
		writeLines( sas_lines , tf )

		# return the filepath to the temporary file containing the updated sas input script
		tf
	}
	

# this function downloads a specified zipped file to the local disk
# and unzips everything according to a straightforward pattern
download.nchs <-
	function( y ){
		
		tf <- tempfile() ; td <- tempdir()
		
		winrar.dir <- normalizePath( paste( td , "winrar" , sep = "/" ) )
		
		dir.create( winrar.dir )
		
		on.exit( unlink( winrar.dir , recursive = TRUE ) )
		
		on.exit( unlink( tf ) )
		
		dir.create( y$name )
		
		dir.create( paste( y$name , "us" , sep = "/" ) )
		
		dir.create( paste( y$name , "ps" , sep = "/" ) )
		
		for ( i in c( y$us , y$ps ) ){
			
			curYear <- as.numeric( gsub( "\\D" , "" , i ) )
			if ( curYear < 50 ) curYear <- curYear + 2000
			if ( curYear > 50 & curYear < 100 ) curYear <- curYear + 1900
			
			download_cached( i , tf , mode = 'wb' )
			
			# actually run winrar on the downloaded file,
			# extracting the results to the temporary directory
			
			# extract the file, platform-specific
			
			if ( .Platform$OS.type == 'windows' ){
				dos.command <- paste0( '"' , path.to.winrar , '" x ' , tf , ' ' , winrar.dir )
				shell( dos.command ) 
			} else {
				sys.command <- paste( "unzip" , tf , "-d" , winrar.dir )
				system( sys.command )
			}

			suppressWarnings( while( any( file.remove( tf ) ) ) Sys.sleep( 1 ) )
			
			z <- list.files( winrar.dir , full.names = TRUE )
			
			if ( y$name %in% c( 'mortality' , 'natality' , 'fetaldeath' ) ){
				
				if ( y$name == 'mortality' & curYear == 1994 ){
				
					# add the puerto rico file to the guam file
					file.append( z[ 1 ] , z[ 2 ] )
					# add the virgin islands file to the puerto rico + guam file
					file.append( z[ 1 ] , z[ 3 ] )
					
					# remove those two files from the disk
					suppressWarnings( while( any( file.remove( z[ 2 ] , z[ 3 ] ) ) ) Sys.sleep( 1 ) )
					
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
				
				stopifnot( any( num <- grepl( 'num' , tolower( z ) ) ) )
				
				stopifnot( any( den <- grepl( 'den' , tolower( z ) ) ) )
			
				if ( any( un <- grepl( 'un' , tolower( z ) ) ) ){
				
					file.copy( z[ un ] , paste( "." , y$name , ifelse( i %in% y$us , "us" , "ps" ) , paste0( "unl" , curYear , ".dat" ) , sep = "/" ) )
				
				}
				
				file.copy( z[ num ] , paste( "." , y$name , ifelse( i %in% y$us , "us" , "ps" ) , paste0( "num" , curYear , ".dat" ) , sep = "/" ) )
				
				file.copy( z[ den ] , paste( "." , y$name , ifelse( i %in% y$us , "us" , "ps" ) , paste0( "den" , curYear , ".dat" ) , sep = "/" ) )
				
			}
			
			suppressWarnings( while( unlink( z ) ) Sys.sleep( 1 ) )
			
		}	
		
		
		for ( i in y$pdfs ){
		
			# wait one minute before each download
			Sys.sleep( 60 )
				
			attempt.one <- try( download_cached( i , paste( "." , y$name , basename( i ) , sep = "/" ) , mode = 'wb' ) , silent = TRUE )
			
			if ( class( attempt.one ) == 'try-error' ) {
				Sys.sleep( 60 )
				
				download_cached( i , paste( "." , y$name , basename( i ) , sep = "/" ) , mode = 'wb' )
			}
		}
			
		TRUE
	}
