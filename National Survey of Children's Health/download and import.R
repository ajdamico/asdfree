# analyze survey data for free (http://asdfree.com) with the r language
# national survey of children's health
# 2003, 2007, 2012
# main files and imputed poverty categories

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# years.to.download <- c( 2003 , 2007 , 2012 )
# setwd( "C:/My Directory/NSCH/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/National%20Survey%20of%20Children%27s%20Health/download%20and%20import.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# http://www.screenr.com/Zpd8

# emily rowe
# eprowe@gmail.com

# anthony joseph damico
# ajdamico@gmail.com

# if you use this script for a project, please send me a note
# it's always nice to hear about how people are using this stuff

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf


##########################################################################################
# download every file from every year of the National Survey of Children's Health with R #
# then save every file as an R data frame (.rda) so future analyses can be rapid-fire.   #
##########################################################################################


# define which years to download #

# uncomment this line to download all available data sets
# uncomment this line by removing the `#` at the front
# years.to.download <- c( 2003 , 2007 , 2012 )

# uncomment this line to only download the most current year
# years.to.download <- 2012

# uncomment this line to download, for example, 2003 and 2012
# years.to.download <- c( 2003 , 2012 )


# set your working directory.
# all NSCH data files will be stored here
# after downloading.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NSCH/" )
# ..in order to set your current working directory


# remove the # in order to run this install.packages line only once
# install.packages( 'sas7bdat' )


# no need to edit anything below this line #


# # # # # # # # #
# program start #
# # # # # # # # #

require(foreign) 	# load foreign package (converts data files into R)
require(sas7bdat)	# loads files ending in .sas7bdat directly into r as data.frame objects


# create a temporary file and a temporary directory
tf <- tempfile() ; td <- tempdir()

# loop through each year of data specified by the user to download
for ( year in years.to.download ){

	# confirm it actually exists
	if ( !( year %in% c( 2003 , 2007 , 2012 ) ) ) stop( "oh so sorry, but that year is not available" )

	# for the 2011-2012 survey, use these filepaths
	if ( year == 2012 ){
		puf.fp <- "ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/slaits/nsch_2011_2012/03_Dataset/nsch_2011_2012_puf.zip"
		mi.fp <- "ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/slaits/nsch_2011_2012/03_Dataset/nsch1112mimp.zip"
	}

	# for the 2007 survey, use these filepaths
	if ( year == 2007 ){
		puf.fp <- "ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/slaits/nsch07/3_Dataset/nsch_2007_puf.zip"
		mi.fp <- "ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/slaits/nsch07/3_Dataset/nsch07mimp.zip"
	}

	# for the 2003 survey, use these filepaths
	if ( year == 2003 ){
		puf.fp <- "ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/slaits/nsch/data/nschpuf3.zip"
		mi.fp <- "ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/slaits/nsch/data/NSCH03 Multiple Imputation.zip"
	}
		
	# download the main file
	download.file( puf.fp , tf , mode = 'wb' )

	# unzip the main file to the temporary directory
	z <- unzip( tf , exdir = td )

	# isolate all of the downloaded files
	# to only the file containing the text `sas7bdat`
	y <- z[ grep( 'sas7bdat' , z ) ]
	
	# read the native sas file directly into R
	x <- read.sas7bdat( y )

	# convert all column names to lowercase
	names( x ) <- tolower( names( x ) )

	# since the sas version of nsch contains multiple types of missings
	# (that, really, you probably don't care about)
	# convert them all into a standard missing `NA` value in the R language.
	# loop through every column and replace all NaN values with NA values
	x[ , ] <- sapply( x[ , ] , function( z ){ z[ is.nan( z ) ] <- NA ; gc() ; z } )

	# clear up RAM
	gc()

	# add a column of all ones
	x$one <- 1

	# download the multiply-imputed poverty data.frame
	download.file( mi.fp , tf , mode = 'wb' )

	# unzip yet another file
	z <- unzip( tf , exdir = td )

	# and yet again, isolate the file to only `sas7bdat`
	y <- z[ grep( 'sas7bdat' , z ) ]
	
	# load the native sas file directly into R
	mimp <- read.sas7bdat( y )

	# convert all column names to lowercase
	names( mimp ) <- tolower( names( mimp ) )

	# delete the temporary file that you just downloaded
	file.remove( tf )

	# double-check that there's only the numbers 1 - 5
	# in the imputation column
	stopifnot( identical( as.numeric( 1:5 ) , sort( unique( mimp$imputation ) ) ) )

	# double-check that there are five times as many records
	# in the `mimp` data.frame as in `x`
	stopifnot( nrow( x ) == ( nrow( mimp ) / 5 ) )
	
	# clear up RAM
	gc()

	# loop through each unique level of the `imputation` field
	for ( i in 1:5 ){

		# print current progress to the screen
		print( i )

		# keep the records for the current level,
		# and throw out that column simultaneously
		cur.imp <- 
			mimp[ 
				mimp$imputation %in% i ,
				!( names( mimp ) %in% 'imputation' ) 
			]
		
		# tack the imputed poverty values onto the main data.frame
		y <- merge( x , cur.imp )
		
		# triple-check that the number of records isn't changed
		stopifnot( nrow( x ) == nrow( y ) )
		
		# save the data.frame as `imp1` - `imp5`
		assign( paste0( 'imp' , i ) , y )
		
		# remove unnecessary data.frame objects from working memory
		rm( y , cur.imp )
		
		# clear up RAM
		gc()
	}

	# remove unnecessary data.frame objects from working memory
	rm( x , mimp )

	# clear up RAM
	gc()

	# save implicates 1 - 5 to the local working directory for faster loading later
	save( list = paste0( 'imp' , 1:5 ) , file = paste0( "nsch " , year , ".rda" ) )

	# remove `imp1` - `imp5` from working memory
	rm( list = paste0( 'imp' , 1:5 ) )

	# you guessed it, clear up RAM
	gc()

}

# delete the temporary directory and all subfolders too
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
