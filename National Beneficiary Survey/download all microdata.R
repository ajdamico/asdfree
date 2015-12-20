# analyze survey data for free (http://asdfree.com) with the r language
# national beneficiary survey
# all available years

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NBS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Beneficiary%20Survey/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


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

