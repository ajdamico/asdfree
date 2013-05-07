# analyze us government survey data with the r language
# medical large claims experience study
# 1997-1999

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



############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #


# create a temporary file and temporary directory
tf <- tempfile() ; td <- tempdir()

# uncomment this line to download all available data sets
# uncomment this line by removing the `#` at the front
# years.to.download <- 1997:1999

# loop through each of the years to download and..
for ( year in years.to.download ){

	# determine the filepath on the society of actuaries' website to the file
	fp <- paste0( "http://www.soa.org/Files/Research/" , year , ".zip" )
		
	# download the current MLCES file
	# and save it as the temporary file
	download.file( fp , tf , mode = 'wb' )


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

# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
