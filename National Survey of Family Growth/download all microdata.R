# analyze survey data for free (http://asdfree.com) with the r language
# national survey of family growth
# latest editions of all available survey years

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NSFG/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Survey%20of%20Family%20Growth/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


#######################################################
# analyze the National Survey of Family Growth with R #
#######################################################


# set your working directory.
# the NSFG data files will be stored here
# after downloading and importing them.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NSFG/" )
# ..in order to set your current working directory


# windows machines might need to change their internet settings
if ( .Platform$OS.type == 'windows' ) setInternet2( FALSE )


# remove the # in order to run this install.packages line only once
# install.packages( c( "stringr" , "readr" , "RCurl" , "SAScii" ) )


############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #


# define the missing value recode function
mvrf <-
	function( x , sf ){
	
		# search within a `sas` import script for all `if` blocks ending with a .;
		mvr <- grep( "^if(.*)\\.;$" , tolower( str_trim( sf ) ) , value = TRUE )
		
		# loop through each one..
		for( this_mv in mvr ){
		
			# figure out the if block of the sas line
			ifs <- gsub( "if(.*)then(.*)=(.*)" , "\\1" , this_mv )
			# figure out the `then` bloc,
			thens <- str_trim( gsub( "if(.*)then(.*)=(.*)" , "\\2" , this_mv ) )
			
			# replace equalses, ors, and ands with their R representations
			ifs <- gsub( "=" , "%in%" , ifs )
			ifs <- gsub( " or " , "|" , ifs )
			ifs <- gsub( " and " , "&" , ifs )

			# overwrite records where the if statement is true with missing
			x[ with( x , which( eval( parse( text = ifs ) ) ) ) , thens ] <- NA
			
		}
		
		# return the missings-blanked-out data.frame object
		x
	}
	

library(readr)		# load the readr package (reads fixed-width files a little easier)
library(SAScii) 	# load the SAScii package (imports ascii data with a SAS script)
library(RCurl)		# load RCurl package (downloads https files)
library(stringr) 	# load stringr package (manipulates character strings easily)


# initiate a temporary file
tf <- tempfile()

# figure out all `.sas` files on the cdc's nsfg ftp site
sas_dir <- "ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NSFG/sas/"
sas_ftp <- readLines( textConnection( getURL( sas_dir ) ) )
all_files <- gsub( "(.*) (.*)" , "\\2" , sas_ftp )
sas_files <- all_files[ grep( "\\.sas$" , tolower( all_files ) ) ]

# but remove ValueLabel and VarLabel scripts
sas_files <- sas_files[ !grepl( "ValueLabel|VarLabel" , sas_files ) ]


# figure out all `.dat` files on the cdc's nsfg ftp site
dat_dir <- "ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NSFG/"
dat_ftp <- readLines( textConnection( getURL( dat_dir ) ) )
all_files <- gsub( "(.*) (.*)" , "\\2" , dat_ftp )
dat_files <- all_files[ grep( "\\.dat$" , tolower( all_files ) ) ]


# identify starting years
sy <- unique( substr( sas_files , 1 , 4 ) )

# remove dat files without a starting year
dat_files <- dat_files[ substr( dat_files , 1 , 4 ) %in% sy ]

# remove this one too
dat_files <- dat_files[ dat_files != "2002curr_ins.dat" ]


# loop through all `.dat` files to be downloaded to the local disk
for ( s in dat_files ){

	# print which download currently being downloaded
	print( s )
	
	# find appropriate sas file for this dat_file
	tsf <- gsub( "Setup|File" , "Data" , gsub( "\\.sas|\\.SAS|Input" , "" , sas_files ) )

	# sometimes sas files and dat files do not have the exact same names..
	
	# if they do, use it
	match_attempt <- which( gsub( "\\.dat" , "" , s ) == tsf )
	
	# however, here are three hardcodes of sas import script to dat file relationships
	if( s == "1973NSFGData.dat" ) match_attempt <- which( sas_files == "1973FemRespSetup.sas" )
	if( length( match_attempt ) == 0 ) match_attempt <- which( gsub( "\\.dat" , "" , s ) == gsub( "Data" , "" , tsf ) )
	if( length( match_attempt ) == 0 ) match_attempt <- which( gsub( "\\.dat" , "" , s ) == gsub( "FemPreg" , "Preg" , tsf ) )
	
	# if the match attempt failed..
	if( length( match_attempt ) == 0 ){
		
		# hopefully it's one of these two .dat files
		if( s %in% c( "1982NSFGData.dat" , "1976NSFGData.dat" ) ){
		
			# if it's 1976..
			if( s == "1976NSFGData.dat" ){
				
				# read the file in with the PregSetup.sas file
				x <- read.SAScii( paste0( dat_dir , s ) , paste0( sas_dir , "1976PregSetup.sas" ) , beginline = 194 )
				
				# convert all column names to lowercase
				names( x ) <- tolower( names( x ) )
				
				# overwrite the `rectype` field
				names( x )[ names( x ) == 'rectype' ] <- 'rec_type'
				
				# remove records with `rec_type` higher than 4
				x <- subset( x , rec_type >= 5 )
				
				# blank out missing values
				x <- mvrf( x , readLines( paste0( sas_dir , "1976PregSetup.sas" ) ) )
				
				# save this data.frame object to the local disk
				save( x , file = "1976FemPreg.rda" )
				
				# remove the object and clear up RAM
				rm( x ) ; gc()
				
				# read the same file in with the FemRespSetup.sas file
				x <- read.SAScii( paste0( dat_dir , s ) , paste0( sas_dir , "1976FemRespSetup.sas" ) , beginline = 7515 )
				
				# convert all column names to lowercase
				names( x ) <- tolower( names( x ) )
				
				# remove records with `marstat` higher than 4
				x <- subset( x , marstat <= 4 )

				# blank out missing values
				x <- mvrf( x , readLines( paste0( sas_dir , "1976FemRespSetup.sas" ) ) )

				# save this data.frame object to the local disk
				save( x , file = "1976FemResp.rda" )
				
				# remove the object and clear up RAM
				rm( x ) ; gc()
						
			} else {
		
				# download the 1982 pregnancy setup sas script
				download.file( paste0( sas_dir , "1982PregSetup.sas" ) , tf , mode = 'wb' )
				
				# load this file into working memory
				a <- readLines( tf )
				
				# substitute some variable names
				a <- gsub( "CASEID \t\t1494-1498" , "CASEID \t\t1494-1498 		REC_TYPE 1499-1500" , a )
				
				# save it back onto the disk
				writeLines( a , tf )
			
				# read the 1982NSFGData.dat fixed-width file into a data.frame object
				x <- read.SAScii( paste0( dat_dir , s ) , tf , beginline = 1567 )
				
				# convert all column names to lowercase
				names( x ) <- tolower( names( x ) )
				
				# keep only records where `rec_type` is nonzero
				x <- subset( x , rec_type > 0 )
				
				# blank out missing values
				x <- mvrf( x , a )
				
				# save this data.frame object to the local disk
				save( x , file = "1982FemPreg.rda" )
				
				# remove the object and clear up RAM
				rm( x ) ; gc()
				
				# download the 1982 female respondent setup sas script
				download.file( paste0( sas_dir , "1982FemRespSetup.sas" ) , tf , mode = 'wb' )
				
				# read a slice of this sas import script into RAM
				a <- readLines( tf )[ 4322:4583 ]
				
				# get rid of the tab separators and collapse all strings together into one
				a <- paste( gsub( "\t" , " " , a ) , collapse = " " )
				
				# remove double and triple spaces
				while( grepl( "  " , a ) ) a <- gsub( "  " , " " , a )
				
				# coerce this messy thing into a data.frame of values
				a <- data.frame( t( matrix( strsplit( a , " " )[[ 1 ]] , 2 ) ) )
				
				# coerce every column to character
				a[ , ] <- sapply( a[ , ] , as.character )
				
				# construct an ordered column from `X2`
				a$sortnum <- gsub( "-(.*)" , "" , a$X2 )
				
				# sort the data.frame
				a <- a[ order( as.numeric( a$sortnum ) ) , ]
				
				# remove the column you've just made
				a$sortnum <- NULL
				
				# add `rec_type` at the bottom of the data.frame
				a <- rbind( a , data.frame( X1 = "REC_TYPE" , X2 = "1499-1500" ) )
				
				# write this big string back onto the local disk as if it were a sas import script
				writeLines( paste( 'input\n ' , paste( apply( a , 1 , paste , collapse = ' ' ) , collapse = ' ' ) , ';' ) , tf )
				
				# save the temporary filepath to a separate `this_file` object
				this_file <- tf
				
				# read in the same fixed-width file as before, this time with a different sas import script
				x <- read.SAScii( paste0( dat_dir , s ) , tf )
				
				# convert all column names to lowercase
				names( x ) <- tolower( names( x ) )

				# keep only records with `rec_type` zeroes
				x <- subset( x , rec_type == 0 )
				
				# recode all missing values
				x <- mvrf( x , a )
				
				# save this data.frame object to the local disk
				save( x , file = "1982FemResp.rda" )
				
				# remove the object and clear up RAM
				rm( x ) ; gc()
				
			}
		
		} else stop( "no sas script found for this data file" )
		
	} else {

		# specify the full ascii file's path on the cdc's nsfg website
		dat_path <- paste0( dat_dir , s )
		
		# specify the sas import script's path on the cdc's nsfg website
		sas_path <- paste0( sas_dir , sas_files[ match_attempt ] )
		
		# figure out the column positions
		sasc <- parse.SAScii( sas_path )

		# this particular file has no line endings
		if( s == "1988PregData.dat" ){

			# download the file onto the local disk
			download.file( dat_path , tf , mode = 'wb' )
			
			# start an empty object
			fwf88 <- NULL
			
			# initiate a file-read connection to the downloaded file
			conn <- file( tf , 'r' )
			
			# read 3553 characters at a time (the actual line length of this file)
			# until you are out of lines
			while( length( data88 <- readChar( conn, 3553 ) ) ){

				# stack the lines on top of one another
				fwf88 <- c( fwf88 , data88 )

			}
			
			# terminate the file-read connection
			close( conn )
			
			# write the full ascii file back to the temporary file
			writeLines( fwf88 , tf )

			# overwrite the full dat_path with the locally-stored file
			dat_path <- tf
			
		}
		
		# read in the fixed-width file..
		x <- 
			read_fwf(
				# using the ftp filepath
				dat_path ,
				# using the parsed sas widths
				fwf_widths( abs( sasc$width ) , col_names = sasc[ , 'varname' ] ) ,
				# using the parsed sas column types
				col_types = paste0( ifelse( is.na( sasc$varname ) , "_" , ifelse( sasc$char , "c" , "d" ) ) , collapse = "" )
			)
			
		# convert all column names to lowercase
		names( x ) <- tolower( names( x ) )
		
		# recode all missing values
		x <- mvrf( x , readLines( sas_path ) )
		
		# figure out the save file name by replacing the `.dat` extension with `.rda`
		sfn <- gsub( "\\.dat" , ".rda" , tolower( s ) )
		
		
		# save this data.frame object to the local disk
		save( x , file = sfn )
		
		# remove the object and clear up RAM
		rm( x ) ; gc()
								
	}
	
}


