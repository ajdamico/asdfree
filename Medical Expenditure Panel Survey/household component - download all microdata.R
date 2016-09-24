# analyze survey data for free (http://asdfree.com) with the r language
# medical expenditure panel survey
# 1996 through 2014
# full-year consolidated, medical conditions, jobs, person round plan, longitudinal weight, and event files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/MEPS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Medical%20Expenditure%20Panel%20Survey/household%20component%20-%20download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


##################################################################################################
# download all Medical Expenditure Panel Survey microdata files, codebooks, documentation with R #
##################################################################################################


# set your working directory.
# all MEPS data files will be stored here
# after downloading.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/MEPS/" )
# ..in order to set your current working directory


# remove the # in order to run this install.packages line only once
# install.packages( c( "RCurl" , "downloader" , "digest" ) )


library(RCurl)				# load RCurl package (downloads files from the web)
library(foreign) 			# load foreign package (converts data files into R)
library(downloader)			# downloads and then runs the source() function on scripts from github

# load the download_cached and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url( 
	"https://raw.githubusercontent.com/ajdamico/asdfree/master/Download%20Cache/download%20cache.R" , 
	prompt = FALSE , 
	echo = FALSE 
)

# all available meps years
year <- 1996:2014


# specify the file numbers of all MEPS public use files
# (these were acquired from browsing around https://meps.ahrq.gov/mepsweb/data_stats/download_data_files.jsp)
# notes:
# 1996 files are buggy.
# 2000, 2001, 2002, and 2003 jobs files need a workaround.
# 2001 and 2002 medical conditions files need a workaround.
# 2000, 2001, and 2002 events files need a workaround.
consolidated <- c( 12 , 20 , 28 , 38 , 50 , 60 , 70 , 79 , 89 , 97 , 105 , 113 , 121 , 129 , 138 , 147 , 155 , 163 , 171 )
popchar <- c( NA , NA , NA , NA , NA , NA , NA , NA , NA , NA , NA , NA , 115 , 123 , 132 , 141 , 149 , 157 , 165 )
conditions <- c( "06r" , 18 , 27 , 37 , 52 , NA , NA , 78 , 87 , 96 , 104 , 112 , 120 , 128 , 137 , 146 , 154 , 162 , 170 )
jobs <- c( "07" , 19 , 25 , 32 , NA , NA , NA , NA , 83 , 91 , 100 , 108 , 116 , 124 , 133 , 142 , 150 , 158 , 166 )
prpf <- c( 24 , 47 , 47 , 47 , 47 , 57 , 66 , 76 , 88 , 95 , 103 , 111 , 119 , 127 , 136 , 145 , 153 , 161 , 169 )
longitudinal <- c( 23 , 35 , 48 , 58 , 65 , 71 , 80 , 86 , 98 , 106 , 114 , 122 , 130 , 139 , 148 , 156 , 164 , NA , NA )
events <- c( 10 , 16 , NA , 33 , NA , NA , NA , 77 , 85 , 94 , 102 , 110 , 118 , 126 , 135 , 144 , 152 , 160 , 168 )

# condition-event link file currently only available until 2013
cond_event <- paste0( ifelse( events < 168 , events , NA ) , "i" )


# specify the most current brr / link file locations
lf <- "https://meps.ahrq.gov/mepsweb/data_files/pufs/h36brr13ssp.zip"
lf.cb <- "https://meps.ahrq.gov/mepsweb/data_stats/download_data/pufs/h36brr/h36brr13cb.pdf"
lf.doc <- "https://meps.ahrq.gov/mepsweb/data_stats/download_data/pufs/h36brr/h36brr13doc.pdf"


# create a big table containing the file number of each meps data file available
# mm stands for meps matrix - a data table pointing to each data file
mm <- 
	data.frame(
		year , 
		consolidated , 
		popchar ,
		conditions , 
		jobs , 
		prpf , 
		longitudinal , 
		events ,
		cond_event
	)

	

#assign all events files (a through h)
mm$rx <- paste0( mm$events , "a" )
mm$dental <- paste0( mm$events , "b" )
mm$other <- paste0( mm$events , "c" )
mm$inpatient <- paste0( mm$events , "d" )
mm$er <- paste0( mm$events , "e" )
mm$outpatient <- paste0( mm$events , "f" )
mm$office <- paste0( mm$events , "g" )
mm$hh <- paste0( mm$events , "h" )

# anything containing the character string 'NA' should be replaced with NA
for ( i in seq( ncol( mm ) ) ) mm[ grepl( "NA" , mm[ , i ] ) , i ] <- NA

# now that each event type-specific column has been created, 
# the 'events' column is no longer necessary
mm$events <- NULL


# if you only want to download certain years of data,
# subset the mm object here.  some examples:

# only download MEPS years 2006 - 2010
# mm <- subset( mm , year %in% 2006:2010 )

# only download MEPS 1997
# mm <- subset( mm , year %in% 1997 )

# only download MEPS 2000, 2004, and 2009
# mm <- subset( mm , year %in% c( 2000 , 2004 , 2009 ) )

# highly recommended: MEPS 1996 has lots of oddities compared to other years
# this file should be skipped unless you spend lots of time reading the documentation
# to figure out what changed where.
# comment this line by adding a `#` at the front
mm <- subset( mm , year %in% 1997:2014 )



# conversion options #

# it's recommended you keep a version of the .rda files,
# since they work with all subsequent scripts

# do you want to store the sas transport (.ssp) file in the working directory?
ssp <- FALSE

# do you want to save an R data file (.rda) to the working directory?
rda <- TRUE

# do you want to save a stata-readable file (.dta) to the working directory?
dta <- FALSE

# do you want to save a comma-separated values file (.csv) to the working directory?
csv <- FALSE

# end of conversion options #




# create a temporary file and a temporary directory
tf <- tempfile(); td <- tempdir()


# download brr / linkage files
download_cached( lf , tf , mode = 'wb' )
zc <- unzip( tf , exdir = td )

# read the file in as an R data frame
brr <- read.xport( zc )

# save the data frame according to the conversion options specified
if ( ssp ) file.copy( zc , "linkage - brr.ssp" )
if ( rda ) save( brr , file = "linkage - brr.rda" )
if ( dta ) write.dta( brr , file = "linkage - brr.dta" )
if ( csv ) write.csv( brr , file = "linkage - brr.csv" )

# immediately delete the brr data frame from memory and clear up ram
rm( brr ) ; gc()


# download the documentation and codebook as well
download_cached( lf.cb , "linkage - brr cb.pdf" , mode = "wb" )
download_cached( lf.doc  , "linkage - brr doc.pdf" , mode = "wb" )



# begin downloading all files for all years specified in the mm (meps matrix) table
# start downloading the most current year first..
for ( i in nrow( mm ):1 ) {

	# year is the first column, so cycle through all the others..
	for ( j in 2:ncol( mm ) ) {
	
		# if the current table position has something in it..
		if ( !is.na( mm[ i , j ] ) ) {
		
			# wait 60 seconds before each new download..
			# Sys.sleep( 60 )
			
			# create a character string containing the name of the .zip file
			fn <- paste0( "h" , mm[ i , j ] , "ssp.zip" )
			
			# create the full url path to the zipped file on the web
			u <- paste0( "https://meps.ahrq.gov/mepsweb/data_files/pufs/h" , mm[ i , j ] , "ssp.zip" )
			
			# figure out if the file exists
			err <- try( getURLContent( u , ssl.verifypeer = FALSE ) , silent = T )

			# if it can't be found once, try a second time
			if( class( err ) == "try-error" ){
				
				# wait 5 more seconds
				Sys.sleep( 5 )
				
				# try once more
				err <- try( getURLContent( u , ssl.verifypeer = FALSE ) , silent = T )
			}
			
			# if the file doesn't exist on its own..
			if( class( err ) == "try-error" ){
				
				# then there should be an f1 and an f2 file (sometimes more)
				
				# download the ..f1ssp.zip file to the temporary file on your local computer
				download_cached( sub( "ssp.zip" , "f1ssp.zip" , u ) , tf , mode = 'wb' ) 
				
				# unzip the ..f1ssp.zip to the temporary directory
				zc <- unzip( tf , exdir = td )
				
				# determine what this datafile should be called when saved
				# in the working directory [[the setwd() command above]]
				# so it fits a pattern, instead of an arbitrary file number
				fn <- paste0( mm[ i , 1 ] , " - " , names( mm )[ j ] , " f1.ssp" )
				
				# choose a data frame name for this file
				# files will be named type.year,
				# so the 2005 jobs file will be accessible as a data.frame called jobs.2005.f1
				df.name <- paste( names( mm )[ j ] , mm[ i , 1 ] , 'f1' , sep = "." )
							
				# read this file into RAM
				assign( df.name , read.xport( zc ) )
				
				# save the file into the formats specified during the 'conversion options' section above
				if ( ssp ) file.copy( zc , fn )
				if ( rda ) save( list = df.name , file = gsub( 'ssp' , 'rda' , fn ) )
				if ( dta ) write.dta( get( df.name ) , file = gsub( 'ssp' , 'dta' , fn ) )
				if ( csv ) write.csv( get( df.name ) , file = gsub( 'ssp' , 'csv' , fn ) )
			
				# immediately delete the brr data frame from memory and clear up ram
				rm( list = df.name ) ; gc()
				
				# download the ..f2ssp.zip file to the temporary file on your local computer
				download_cached( sub( "ssp.zip" , "f2ssp.zip" , u ) , tf , mode = 'wb' )
				
				# unzip the ..f2ssp.zip to the temporary directory
				zc <- unzip( tf , exdir = td )
				
				# determine what this datafile should be called when saved
				# in the working directory [[the setwd() command above]]
				# so it fits a pattern, instead of an arbitrary file number
				fn <- paste0( mm[ i , 1 ] , " - " , names( mm )[ j ] , " f2.ssp" )
				
				# choose a data frame name for this file
				# files will be named type.year,
				# so the 2005 jobs file will be accessible as a data.frame called jobs.2005.f2
				df.name <- paste( names( mm )[ j ] , mm[ i , 1 ] , 'f2' , sep = "." )
							
				# read this file into RAM
				assign( df.name , read.xport( zc ) )
				
				# save the file into the formats specified during the 'conversion options' section above
				if ( ssp ) file.copy( zc , fn )				
				if ( rda ) save( list = df.name , file = gsub( 'ssp' , 'rda' , fn ) )
				if ( dta ) write.dta( get( df.name ) , file = gsub( 'ssp' , 'dta' , fn ) )
				if ( csv ) write.csv( get( df.name ) , file = gsub( 'ssp' , 'csv' , fn ) )
			
				# immediately delete the brr data frame from memory and clear up ram
				rm( list = df.name ) ; gc()
					
			} else {
				
				# determine what this datafile should be called when saved
				# in the working directory [[the setwd() command above]]
				# so it fits a pattern, instead of an arbitrary file number
				fn <- paste0( mm[ i , 1 ] , " - " , names( mm )[ j ] , ".ssp" )
								
				# choose a data frame name for this file
				# files will be named type.year,
				# so the 2005 jobs file will be accessible as a data.frame called jobs.2005
				df.name <- paste( names( mm )[ j ] , mm[ i , 1 ] , sep = "." )

				# try the download, unzip, read-in twice before breaking
				attempt.one <-
					try({
						# download the ..ssp.zip file to the temporary file on your local computer
						download_cached( u , tf , mode = 'wb' )
					
						# unzip the ..ssp.zip to the temporary directory
						zc <- unzip( tf , exdir = td )
					
						# read this file into RAM
						assign( df.name , read.xport( zc ) )
					} , silent = TRUE )
					
				# if the first time broke..
				if ( class( attempt.one ) == 'try-error' ){
					attempt.two <-
						try({
			
							# ..wait 5 seconds and try again
							Sys.sleep( 5 )
							
							# download the ..ssp.zip file to the temporary file on your local computer
							download_cached( u , tf , mode = 'wb' )
						
							# unzip the ..ssp.zip to the temporary directory
							zc <- unzip( tf , exdir = td )
						
							# read this file into RAM
							assign( df.name , read.xport( zc ) )
						} , silent = TRUE )
						
				} else attempt.two <- NA
				
				
				if ( class( attempt.two ) == 'try-error' ) {
				
					warning( u , ' did not download properly!' )
				
				} else{

					
					# save the file into the formats specified during the 'conversion options' section above
					if ( ssp ) file.copy( zc , fn )
					if ( rda ) save( list = df.name , file = gsub( 'ssp' , 'rda' , fn ) )
					if ( dta ) write.dta( get( df.name ) , file = gsub( 'ssp' , 'dta' , fn ) )
					if ( csv ) write.csv( get( df.name ) , file = gsub( 'ssp' , 'csv' , fn ) )
				
					# immediately delete the brr data frame from memory and clear up ram
					rm( list = df.name ) ; gc()

				}
				
				# erase the try-error objects
				attempt.one <- attempt.two <- NULL
				
			}
			
			# reset the error object (this object stores whether or not the download attempt failed)
			err <- NULL
			
			###################################
			# download the codebook if possible
			
			# specify what the codebook should be named (as opposed to a number)
			cbname <- paste0( mm[ i , 1 ] , " - " , names( mm )[ j ] , " cb.pdf" )
			
			# specify the url where the codebook should be
			cbsite <- paste0( "https://meps.ahrq.gov/mepsweb/data_stats/download_data/pufs/h" , mm[ i , j ] , "/h" , mm[ i , j ] , "cb.pdf" )
			
			# determine whether the codebooks exists
			# (note: many early codebooks do not exist, because they are included in the documentation file)
			err <- try( getURLContent( cbsite , ssl.verifypeer = FALSE ) , silent = TRUE )
			
			# give the ahrq website five seconds before the actual download
			Sys.sleep( 5 )
			
			attempt1 <- NULL
			
			# if it does, download it
			if (! class(err) == "try-error" ) attempt1 <- try( download_cached( cbsite , cbname , mode = "wb" ) , silent = TRUE )
			
			# if the first documentation download broke, wait 5 seconds and try again
			if ( class( attempt1 ) == 'try-error' ){
				Sys.sleep( 5 )
				try( download_cached(  cbsite , cbname , mode = "wb" ) , silent = TRUE )
			}
			
			# reset the error object (this object stores whether or not the download attempt failed)
			err <- NULL
			
			########################################
			# download the documentation if possible
			
			# specify what the documentation should be named (as opposed to a number)
			docname <- paste0( mm[i,1] , " - " , names(mm)[j] , " doc.pdf" )
			
			# specify the url where the documentation should be
			docsite <- paste0( "https://meps.ahrq.gov/mepsweb/data_stats/download_data/pufs/h" , mm[ i , j ] , "/h" , mm[ i , j ] , "doc.pdf" )
			
			# determine whether the documentation exists
			err <- try( getURLContent( docsite , ssl.verifypeer = FALSE ) , silent = T )
			
			# give the ahrq website five seconds before the actual download
			Sys.sleep( 5 )
			
			attempt1 <- NULL
			
			# if it does, download it
			if (! class(err) == "try-error" ){
				attempt1 <- try( download_cached( docsite , docname , mode = "wb" ) , silent = TRUE )
			}
			
			# if the first documentation download broke, wait 5 seconds and try again
			if ( class( attempt1 ) == 'try-error' ){
				Sys.sleep( 5 )
				try( download_cached(  docsite , docname , mode = "wb" ) , silent = TRUE )
			}
			
			# reset the error object (this object stores whether or not the download attempt failed)
			err <- NULL
		
		}
	}
}

# print a reminder: set the directory you just saved everything to as read-only!
message( paste( "all done.  you should set" , getwd() , "read-only so you don't accidentally alter these files." ) )

