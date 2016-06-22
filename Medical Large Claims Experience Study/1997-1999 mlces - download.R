# analyze survey data for free (http://asdfree.com) with the r language
# medical large claims experience study
# 1997-1999

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/MLCES/" )
# years.to.download <- 1997:1999
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Medical%20Large%20Claims%20Experience%20Study/1997-1999%20mlces%20-%20download.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


#########################################################################
# download the three years of the medical large claims experience study #
# with R, then save every file as an R data frame (.rda)                #
#########################################################################


# set your working directory.
# all mlces files will be stored here
# after downloading and importing it.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/MLCES/" )
# ..in order to set your current working directory


# remove the # in order to run this install.packages line only once
# install.packages( "downloader" , "digest" )


# uncomment this line to download all available data sets
# uncomment this line by removing the `#` at the front
# years.to.download <- 1997:1999


############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #


library(downloader)	# downloads files easily from https sites


# create a temporary file and temporary directory
tf <- tempfile() ; td <- tempdir()

# loop through each of the years to download and..
for ( year in years.to.download ){

	# determine the filepath on the society of actuaries' website to the file
	fp <- paste0( "https://www.soa.org/Files/Research/" , year , ".zip" )
		
	# download the current MLCES file
	# and save it as the temporary file
	download( fp , tf , mode = 'wb' )


	# unzip all of the files in the downloaded .zip file into the current working directory
	# then save all of their unzipped locations into a character vector called 'z'
	z <- unzip( tf , exdir = getwd() )

	# read the current file into RAM
	x <- read.csv( z )

	# convert fields to all lowercase
	names( x ) <- tolower( names( x ) )
	
	# save the mcles data table as an R data file (.rda)
	# (for quick loading later)
	save( x , file = paste0( "mcles" , year , ".rda" ) )
	
	# delete the temporary file..
	file.remove( tf )
	# ..and the unzipped file
	file.remove( z )
	
	# remove `x` from memory and clear up RAM
	rm( x )

	# clear up RAM
	gc()
	
}

# print a reminder: set the directory you just saved everything to as read-only!
message( paste( "all done.  you should set" , getwd() , "read-only so you don't accidentally alter these files." ) )
