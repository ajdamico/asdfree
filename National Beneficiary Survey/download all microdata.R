# analyze survey data for free (http://asdfree.com) with the r language
# national beneficiary survey
# all available years

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NBS/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/National%20Beneficiary%20Survey/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

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


# set your working directory.
# the NBS data files will be stored here
# after downloading and importing them.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NBS/" )
# ..in order to set your current working directory

# remove the # in order to run this install.packages line only once
# install.packages( "stringr" )


############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #

library(stringr) # load stringr package (manipulates character strings easily)


# create a character vector pointing to each of the csv files
rounds <-
	c( 
		# round one
		"http://www.ssa.gov/disabilityresearch/documents/r1puf093009.CSV" ,
		
		# round two
		"http://www.ssa.gov/disabilityresearch/documents/r2puf102609.CSV" ,
		
		# round three
		"http://www.ssa.gov/disabilityresearch/documents/NBSr3puf121509.CSV" ,
		
		# round four
		"http://www.ssa.gov/disabilityresearch/documents/NBSR4PUF.csv"
	)


# loop through each of the available nbs rounds
for ( i in seq_along( rounds ) ){

	# download and read the current round directly into an R data.frame object
	x <- read.csv( rounds[ i ] , stringsAsFactors = FALSE )
	
	# convert all column names to lowercase
	names( x ) <- tolower( names( x ) )
	
	# remove those rounds at the front of the column names
	names( x ) <- gsub( paste0( "^r" , i , "_" ) , "" , names( x ) )
	# that `^` symbol instructs r to only match a pattern at the start of the string.
	
	# add a column of nuthin' but ones.
	x$one <- 1
	
	# store the current data.frame object as a `.rda` file within the current working directory
	save( x , file = paste0( "round " , str_pad( i , 2 , pad = "0" ) , ".rda" ) )
	
	# remove the `x` object from current working memory
	rm( x )
	
	# clear up RAM
	gc()

}


# print a reminder: set the directory you just saved everything to as read-only!
message( paste0( "all done.  you should set the file " , file.path( getwd() ) , " read-only so you don't accidentally alter these tables." ) )


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
