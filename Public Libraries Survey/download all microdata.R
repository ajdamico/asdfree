# analyze survey data for free (http://asdfree.com) with the r language
# public libraries survey
# all available years

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/PLS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Public%20Libraries%20Survey/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


################################################################
# download every available year of the public libraries survey #
# with R, then save every file as an R data frame (.rda)       #
################################################################


# set your working directory.
# all pls files will be stored here
# after downloading and importing it.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PLS/" )
# ..in order to set your current working directory



############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #

# initiate a temporary file and a temporary directory
tf <- tempfile() ; td <- tempdir()

# read the `data_files` page contents to a local character vector
pls.page <- readLines( "https://www.imls.gov/research-evaluation/data-collection/public-libraries-united-states-survey/public-libraries-united" )

# restrict this page to only the records that contain `_csv` links
pls.links <- pls.page[ grep( '_csv' , pls.page ) ]

# re-name these zipped-file-links to only the pre-csv filepath
pls.files <- gsub( "(.*)files/(.*)_csv\\.zip(.*)" , "\\2" , pls.links )

# loop through each of the pls files
for ( this.file in pls.files ){

	# extract all numeric characters from the filename prefix
	this.year <- as.numeric( gsub( "[^0-9]" , "" , this.file ) )
	
	# since only the last two digits are available,
	# add 1900 or 2000 if it's after the 90's
	if ( this.year < 90 ) this.year <- this.year + 2000 else this.year <- this.year + 1900
	
	# construct the full http location
	this.location <- paste0( "https://www.imls.gov/sites/default/files/" , this.file , "_csv.zip" )
	
	# download the zipped file to the local disk
	download.file( this.location , tf , mode = 'wb' )
	
	# unzip the zipped file to the local temporary directory
	z <- unzip( tf , exdir = td )
	
	# loop through each of the files extracted to the temporary directory..
	for ( this.csv in z ){
	
		# figure out the name of the object to be saved,
		# by removing all text after the dot
		this.tablename <- gsub( "\\.(.*)" , "" , basename( this.csv ) )
	
		# remove all numeric characters, and also conver the entire string to lowercase
		this.tablename <- tolower( gsub( "[0-9]" , "" , this.tablename ) )
	
		# read the csv file into an R data.frame
		x <- read.csv( this.csv , stringsAsFactors = FALSE )
		
		# convert all column names to lowercase
		names( x ) <- tolower( names( x ) )
	
		# figure out which columns are integer typed
		int.cols <- sapply( x , class ) == 'integer'
		
		# for all integer columns, replace negative ones with NAs
		x[ , int.cols ] <- 
			sapply( 
				x[ , int.cols ] , 
				function( z ){ z[ z == -1 ] <- NA ; z } 
			)
		
		# save the data.frame `x` over to the cleaned-up filename
		assign( this.tablename , x )
			
		# save this table to a year x tablename path in the current working directory
		save( list = this.tablename , file = paste0( "./" , this.year , " - " , this.tablename , ".rda" ) )

		# clear these objects from RAM
		rm( list = c( "x" , this.tablename ) )
		
		# tell your computer it can re-claim that memory space, if needed
		gc()
		
	}

}

# delete all files and folders in the temporary directory
unlink( td , recursive = TRUE )


# print a reminder: set the directory you just saved everything to as read-only!
message( paste( "all done.  you should set" , getwd() , "read-only so you don't accidentally alter these files." ) )

# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/

# dear everyone: please contribute your script.
# have you written syntax that precisely matches an official publication?
message( "if others might benefit, send your code to ajdamico@gmail.com" )
# http://asdfree.com needs more user contributions

# let's play the which one of these things doesn't belong game:
# "only you can prevent forest fires" -smokey bear
# "take a bite out of crime" -mcgruff the crime pooch
# "plz gimme your statistical programming" -anthony damico
