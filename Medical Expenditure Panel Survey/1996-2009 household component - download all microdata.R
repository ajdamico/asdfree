# analyze us government survey data with the r language
# medical expenditure panel survey
# 1996 through 2009
# full-year consolidated, medical conditions, jobs, person round plan, longitudinal weight, and event files

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# http://www.screenr.com/Zpd8

# anthony joseph damico
# ajdamico@gmail.com

# if you use this script for a project, please send me a note
# it's always nice to hear about how people are using this stuff

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf


##################################################################################################
# download all Medical Expenditure Panel Survey microdata files, codebooks, documentation with R #
##################################################################################################


# set your working directory.
# all MEPS data files will be stored here
# after downloading.
# use forward slashes instead of back slashes

setwd( "C:/My Directory/MEPS/" )


# remove the # in order to run this install.packages line only once
# install.packages( "RCurl" )


library(RCurl)		# load RCurl package (downloads files from the web)


# specify the MEPS years currently available
year <- 1996:2009


# specify the file numbers of all MEPS public use files
# (these were acquired from browsing around http://meps.ahrq.gov/mepsweb/data_stats/download_data_files.jsp)
consolidated <- c( 12 , 20 , 28 , 38 , 50 , 60 , 70 , 79 , 89 , 97 , 105 , 113 , 121 , 129 )
conditions <- c( "06r" , 18 , 27 , 37 , 52 , 61 , 69 , 78 , 87 , 96 , 104 , 112 , 120 , 128 )
jobs <- c( "07" , 19 , 25 , 32 , 40 , 56 , 63 , 74 , 83 , 91 , 100 , 108 , 116 , 124 )
prpf <- c( 24 , 47 , 47 , 47 , 47 , 57 , 66 , 76 , 88 , 95 , 103 , 111 , 119 , 127 )
longitudinal <- c( 23 , 35 , 48 , 58 , 65 , 71 , 80 , 86 , 98 , 106 , 114 , 122 , 130 , NA )
events <- c( 10 , 16 , 26 , 33 , 51 , 59 , 67 , 77 , 85 , 94 , 102 , 110 , 118 , 126 )


# specify the most current brr / link file locations
lf <- "http://meps.ahrq.gov/mepsweb/data_files/pufs/h36b09ssp.zip"
lf.cb <- "http://meps.ahrq.gov/mepsweb/data_stats/download_data/pufs/h36brr/h36b09cb.pdf"
lf.doc <- "http://meps.ahrq.gov/mepsweb/data_stats/download_data/pufs/h36brr/h36b09doc.pdf"


# create a big table containing the file number of each meps data file available
# mm stands for meps matrix - a data table pointing to each data file
mm <- 
	data.frame(
		year , 
		consolidated , 
		conditions , 
		jobs , 
		prpf , 
		longitudinal , 
		events
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


# now that each event type-specific column has been created, 
# the 'events' column is no longer necessary
mm$events <- NULL


# if you only want to download certain years of data,
# subset the mm object here.  some examples:

# only download MEPS years 2006 - 2009
# mm <- subset( mm , year %in% 2006:2009 )

# only download MEPS 1997
# mm <- subset( mm , year %in% 1997 )

# only download MEPS 2000, 2004, and 2009
# mm <- subset( mm , year %in% c( 2000 , 2004 , 2009 ) )

# but really, why not download them all!?  ;)


# create a temporary file and a temporary directory
tf <- tempfile(); td <- tempdir()


# download brr / linkage files, and rename them to 'linkage - brr...' so analysis code does not need to be altered
download.file( lf , tf )
zc <- unzip( tf , exdir = td )
file.rename( zc , "linkage - brr.ssp" )
download.file( lf.cb , "linkage - brr cb.pdf" , mode="wb" , cacheOK=F , method="internal" )
download.file( lf.doc  , "linkage - brr doc.pdf" , mode="wb" , cacheOK=F , method="internal" )


# begin downloading all files for all years specified in the mm (meps matrix) table
for ( i in 1:nrow( mm ) ) {

	# year is the first column, so cycle through all the others..
	for ( j in 2:ncol( mm ) ) {
	
		# if the current table position has something in it..
		if ( !is.na( mm[ i , j ] ) ) {
		
			# create a character string containing the name of the .zip file
			fn <- paste0( "h" , mm[ i , j ] , "ssp.zip" )
			
			# create the full url path to the zipped file on the web
			u <- paste0( "http://meps.ahrq.gov/mepsweb/data_files/pufs/h" , mm[ i , j ] , "ssp.zip" )
			
			# figure out if the file exists
			err <- try( getURLContent( u ) , silent = T )
						
			# if the file doesn't exist on its own..
			if( class( err ) == "try-error" ){
				
				# then there should be an f1 and an f2 file (sometimes more)
				
				# download the ..f1ssp.zip file to the temporary file on your local computer
				download.file( sub( "ssp.zip" , "f1ssp.zip" , u ) , tf ) 
				
				# unzip the ..f1ssp.zip to the temporary directory
				zc <- unzip( tf , exdir = td )
				
				# determine what this datafile should be called when saved
				# in the working directory [[the setwd() command above]]
				# so it fits a pattern, instead of an arbitrary file number
				fn <- paste0( mm[ i , 1 ] , " - " , names( mm )[ j ] , " f1.ssp" )
				
				# finally, rename/move the unzipped ___.ssp file to the new name
				file.rename( zc , fn )

				# download the ..f2ssp.zip file to the temporary file on your local computer
				download.file( sub( "ssp.zip" , "f2ssp.zip" , u ) , tf ) 
				
				# unzip the ..f2ssp.zip to the temporary directory
				zc <- unzip( tf , exdir = td )
				
				# determine what this datafile should be called when saved
				# in the working directory [[the setwd() command above]]
				# so it fits a pattern, instead of an arbitrary file number
				fn <- paste0( mm[ i , 1 ] , " - " , names( mm )[ j ] , " f2.ssp" )
				
				# finally, rename/move the unzipped ___.ssp file to the new name
				file.rename( zc , fn )
							
			} else {
				
				# download the ..ssp.zip file to the temporary file on your local computer
				download.file( u , tf )
			
				# unzip the ..ssp.zip to the temporary directory
				zc <- unzip( tf , exdir = td )
			
				# determine what this datafile should be called when saved
				# in the working directory [[the setwd() command above]]
				# so it fits a pattern, instead of an arbitrary file number
				fn <- paste0( mm[ i , 1 ] , " - " , names( mm )[ j ] , ".ssp" )
				
				# finally, rename/move the unzipped ___.ssp file to the new name
				file.rename( zc , fn )
				
			}
			
			# reset the error object (this object stores whether or not the download attempt failed)
			err <- NULL
			
			###################################
			# download the codebook if possible
			
			# specify what the codebook should be named (as opposed to a number)
			cbname <- paste0( mm[ i , 1 ] , " - " , names( mm )[ j ] , " cb.pdf" )
			
			# specify the url where the codebook should be
			cbsite <- paste0( "http://meps.ahrq.gov/mepsweb/data_stats/download_data/pufs/h" , mm[ i , j ] , "/h" , mm[ i , j ] , "cb.pdf" )
			
			# determine whether the codebooks exists
			# (note: many early codebooks do not exist, because they are included in the documentation file)
			err <- try( getURLContent( cbsite ) , silent = T )
			
			# if it does, download it
			if (! class(err) == "try-error" ) download.file(  cbsite , cbname , mode="wb" , cacheOK=F , method="internal" )
			
			# reset the error object (this object stores whether or not the download attempt failed)
			err <- NULL
			
			########################################
			# download the documentation if possible
			
			# specify what the documentation should be named (as opposed to a number)
			docname <- paste0( mm[i,1] , " - " , names(mm)[j] , " doc.pdf" )
			
			# specify the url where the documentation should be
			docsite <- paste0( "http://meps.ahrq.gov/mepsweb/data_stats/download_data/pufs/h" , mm[ i , j ] , "/h" , mm[ i , j ] , "doc.pdf" )
			
			# determine whether the documentation exists
			err <- try( getURLContent( docsite ) , silent = T )
			
			# if it does, download it
			if (! class(err) == "try-error" ) download.file(  docsite , docname , mode="wb" , cacheOK=F , method="internal" )
			
			# reset the error object (this object stores whether or not the download attempt failed)
			err <- NULL
		
		}
	}
}

# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/

