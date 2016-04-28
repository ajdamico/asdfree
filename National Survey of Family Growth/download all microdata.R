
mvrf <-
	function( x , sf ){
	
		mvr <- grep( "^if(.*)\\.;$" , tolower( str_trim( sf ) ) , value = TRUE )
		
		for( this_mv in mvr ){
			ifs <- gsub( "if(.*)then(.*)=(.*)" , "\\1" , mvr )
			thens <- gsub( "if(.*)then(.*)=(.*)" , "\\2" , mvr )
			ifs <- gsub( "=" , "%in%" , ifs )
			ifs <- gsub( "or" , "|" , ifs )
			ifs <- gsub( "and" , "&" , ifs )

			x[ with( x , ifs[ 1 ] ) , thens[ 1 ] ] <- NA
		}
		
		x
	}
	
# you need to deal with hidden missingness like this..
# ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NSFG/sas/1976FemRespSetup.sas
# * USER-DEFINED MISSING VALUES RECODE TO SAS SYSMIS;
   # IF (A1 = 99) THEN A1 = .;
   # IF (A3 = 8 OR A3 = 9) THEN A3 = .;
   # IF (A4 = 8 OR A4 = 9) THEN A4 = .;
   # IF (A5 = 8 OR A5 = 9) THEN A5 = .;
   # IF (A6 = 8 OR A6 = 9) THEN A6 = .;
   # IF (A8 = 98 OR A8 = 99) THEN A8 = .;
   # IF (A9_CM = 0) THEN A9_CM = .;
   # IF (A10 = 9) THEN A10 = .;
   # IF (A11 = 9) THEN A11 = .;
   # IF (A12A13_MNTH = 0) THEN A12A13_MNTH = .;
   # IF (A12A13_INFUN = 9) THEN A12A13_INFUN = .;
   # IF (A14_MOSTREC = 9) THEN A14_MOSTREC = .;
   # IF (A15A16_MOSTREC = 0) THEN A15A16_MOSTREC = .;
   # IF (A17_MOSTREC = 0) THEN A17_MOSTREC = .;
   # IF (A13MON_1ST = 0) THEN A13MON_1ST = .;
   # IF (A13INF_1ST3 = 9) THEN A13INF_1ST3 = .;



setwd( "R:/National Survey of Family Growth" )
# setwd( "C:/My Directory/NSFG" )

setInternet2( FALSE )

library(stringr)
library(readr)
library(SAScii)
library(RCurl)

tf <- tempfile()

sas_dir <- "ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NSFG/sas/"
sas_ftp <- readLines( textConnection( getURL( sas_dir ) ) )
all_files <- gsub( "(.*) (.*)" , "\\2" , sas_ftp )
sas_files <- all_files[ grep( "\\.sas$" , tolower( all_files ) ) ]

dat_dir <- "ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NSFG/"
dat_ftp <- readLines( textConnection( getURL( dat_dir ) ) )
all_files <- gsub( "(.*) (.*)" , "\\2" , dat_ftp )
dat_files <- all_files[ grep( "\\.dat$" , tolower( all_files ) ) ]

# remove ValueLabel and VarLabel scripts
sas_files <- sas_files[ !grepl( "ValueLabel|VarLabel" , sas_files ) ]

# identify starting years
sy <- unique( substr( sas_files , 1 , 4 ) )

# remove dat files without a starting year
dat_files <- dat_files[ substr( dat_files , 1 , 4 ) %in% sy ]

# remove this one too
dat_files <- dat_files[ dat_files != "2002curr_ins.dat" ]



# for ( s in rev( sas_files ) ){
	# if ( s == '1982PregSetup.sas' ) beginline <- 1567 else
	# if( s == '1976FemRespSetup.sas' ) beginline <- 7515 else
	# if( s == '1976PregSetup.sas' ) beginline <- 194 else
	# beginline <- 1
	
	# if ( s == '1982FemRespSetup.sas' ){
	
		# download.file( paste0( sas_dir , s ) , tf , mode = 'wb' )
		
		# a <- readLines( tf )[ 4322:4583 ]
		# a <- paste( gsub( "\t" , " " , a ) , collapse = " " )
		# while( grepl( "  " , a ) ) a <- gsub( "  " , " " , a )
		# a <- data.frame( t( matrix( strsplit( a , " " )[[ 1 ]] , 2 ) ) )
		# a[ , ] <- sapply( a[ , ] , as.character )
		# a$sortnum <- gsub( "-(.*)" , "" , a$X2 )
		# a <- a[ order( as.numeric( a$sortnum ) ) , ]
		# a$sortnum <- NULL
		# writeLines( paste( 'input\n ' , paste( apply( a , 1 , paste , collapse = ' ' ) , collapse = ' ' ) , ';' ) , tf )
		# this_file <- tf
		
	# } else this_file <- paste0( sas_dir , s )
	
	# print( parse.SAScii( this_file , beginline = beginline ) )
	
# }



for ( s in sample( dat_files , length( dat_files ) ) ){
# for ( s in dat_files ){

	print( s )
	
	# find appropriate sas file for this dat_file
	tsf <- gsub( "Setup|File" , "Data" , gsub( "\\.sas|\\.SAS|Input" , "" , sas_files ) )

	match_attempt <- which( gsub( "\\.dat" , "" , s ) == tsf )
	if( s == "1973NSFGData.dat" ) match_attempt <- which( sas_files == "1973FemRespSetup.sas" )
	if( length( match_attempt ) == 0 ) match_attempt <- which( gsub( "\\.dat" , "" , s ) == gsub( "Data" , "" , tsf ) )
	if( length( match_attempt ) == 0 ) match_attempt <- which( gsub( "\\.dat" , "" , s ) == gsub( "FemPreg" , "Preg" , tsf ) )
	
	
	if( length( match_attempt ) == 0 ){
		
		if( s %in% c( "1982NSFGData.dat" , "1976NSFGData.dat" ) ){
		
			if( s == "1976NSFGData.dat" ){
				
				x <- read.SAScii( paste0( dat_dir , s ) , paste0( sas_dir , "1976PregSetup.sas" ) , beginline = 194 )
				names( x ) <- tolower( names( x ) )
				names( x )[ names( x ) == 'rectype' ] <- 'rec_type'
				x <- subset( x , rec_type >= 5 )
				
				x <- mvrf( x , readLines( paste0( sas_dir , "1976PregSetup.sas" ) ) )
				
				save( x , file = "1976FemPreg.rda" )
				rm( x )
				
				x <- read.SAScii( paste0( dat_dir , s ) , paste0( sas_dir , "1976FemRespSetup.sas" ) , beginline = 7515 )
				names( x ) <- tolower( names( x ) )
				x <- subset( x , marstat <= 4 )

				x <- mvrf( x , readLines( paste0( sas_dir , "1976FemRespSetup.sas" ) ) )

				save( x , file = "1976FemResp.rda" )
				rm( x )
						
			} else {
			
				download.file( paste0( sas_dir , "1982PregSetup.sas" ) , tf , mode = 'wb' )
				a <- readLines( tf )
				a <- gsub( "CASEID \t\t1494-1498" , "CASEID \t\t1494-1498 		REC_TYPE 1499-1500" , a )
				writeLines( a , tf )
			
				x <- read.SAScii( paste0( dat_dir , s ) , tf , beginline = 1567 )
				names( x ) <- tolower( names( x ) )
				x <- subset( x , rec_type > 0 )
				
				x <- mvrf( x , a )
				
				save( x , file = "1982FemPreg.rda" )
				rm( x )

				
				download.file( paste0( sas_dir , "1982FemRespSetup.sas" ) , tf , mode = 'wb' )
				a <- readLines( tf )[ 4322:4583 ]
				a <- paste( gsub( "\t" , " " , a ) , collapse = " " )
				
				while( grepl( "  " , a ) ) a <- gsub( "  " , " " , a )
				a <- data.frame( t( matrix( strsplit( a , " " )[[ 1 ]] , 2 ) ) )
				a[ , ] <- sapply( a[ , ] , as.character )
				a$sortnum <- gsub( "-(.*)" , "" , a$X2 )
				a <- a[ order( as.numeric( a$sortnum ) ) , ]
				a$sortnum <- NULL
				a <- rbind( a , data.frame( X1 = "REC_TYPE" , X2 = "1499-1500" ) )
				writeLines( paste( 'input\n ' , paste( apply( a , 1 , paste , collapse = ' ' ) , collapse = ' ' ) , ';' ) , tf )
				this_file <- tf
				x <- read.SAScii( paste0( dat_dir , s ) , tf )
				names( x ) <- tolower( names( x ) )
				x <- subset( x , rec_type == 0 )
				
				x <- mvrf( x , a )
				
				save( x , file = "1982FemResp.rda" )
				rm( x )
			
			}
		
		} else stop( "no sas script found for this data file" )
		
	} else {

		dat_path <- paste0( dat_dir , s )
		sas_path <- paste0( sas_dir , sas_files[ match_attempt ] )
		
		sasc <- parse.SAScii( sas_path )
		
		x <- 
			read_fwf(
				dat_path ,
				fwf_widths( abs( sasc$width ) , col_names = sasc[ , 'varname' ] ) ,
				col_types = paste0( ifelse( is.na( sasc$varname ) , "_" , ifelse( sasc$char , "c" , "d" ) ) , collapse = "" )
			)
			
		
		# x <- 
			# read.SAScii( 
				# paste0( dat_dir , s ) ,
				# paste0( sas_dir , sas_files[ match_attempt ] )
			# )
			
		
			
		names( x ) <- tolower( names( x ) )
		
		x <- mvrf( x , readLines( sas_path ) )
		
		sfn <- gsub( "\\.dat" , ".rda" , tolower( s ) )
		
		save( x , file = sfn )
		
		rm( x )
				
	}
	
}


