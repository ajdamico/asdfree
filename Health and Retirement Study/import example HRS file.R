# analyze survey data for free (http://asdfree.com) with the r language
# health and retirement study
# import a single HRS file
# originally constructed by the University of Michigan

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/HRS/" )
# source_url( "https://raw.github.com/ajdamico/asdfree/master/Health%20and%20Retirement%20Study/import%20example%20HRS%20file.R" , prompt = FALSE , echo = TRUE )
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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#############################################################################################################################
# prior to running this analysis script, the 1992 Core Distribution HRS files must be downloaded and unzipped on the        #
# local machine. running the 1992 - 2010 download HRS microdata.R script download all of the necessary files automatically  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/asdfree/master/Health%20and%20Retirement%20Study/1992-2010%20download%20HRS%20microdata.R   #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will place the HRS file "HOUSEHLD.DA" and many others in the "C:/My Directory/HRS/download/" folder           #
#############################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# remove the # in order to run this install.packages line only once
# install.packages( "SAScii" )


##########################################################################################################
# import a single HRS file into R, then save that file as an R data file (.rda) for faster loading later #
##########################################################################################################

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/HRS/" )
# ..in order to set your current working directory

# filepath to a fixed-width file produced by the university of michigan
fn <- "./download/1992/h92core/h92da/HOUSEHLD.DA"

# filepath to the SAS importation instructions for that fixed-width file
sas.input <- "./download/1992/h92core/h92sas/HOUSEHLD.SAS"



library(SAScii) 	# load the SAScii package (imports ascii data with a SAS script)


# load the ascii file directly into R using only a SAS script
x <- read.SAScii( fn , sas.input )

# in some cases, the above command is all that's necessary. #




# note that the SAS script included a number of IF statements
# that are not appropriately handled by the R SAScii package
# in every case, these IF statements specify certain cases where
# values should be overwritten with missing values instead.

# load the SAS input script into memory as a big character string
saslines <- readLines( sas.input )

# keep only lines beginning with IF
saslines <- saslines[ substr( saslines , 1 , 2 ) == "IF" ]

# split them up by spaces
sas.split <- strsplit( saslines , " " )

# find the second element of the list, which contains the variable to overwrite
overwrites <- sapply( sas.split , `[[` , 2 )

# find the third element of the list, which contains equal or GE (>=)
eoge <- sapply( sas.split , `[[` , 3 )

# find the fourth element of the list, which contains the values to overwrite
val <- sapply( sas.split , `[[` , 4 )

# define a function that simply replaces missings with FALSE values
no.na <-
	function( x , value = FALSE ){
		x[ is.na( x ) ] <- value
		x
	}


# loop through every 'overwrite' column instructed by the SAS script..
for ( i in seq( length( overwrites ) ) ){

	# if the line is 'greater than or equal to'..
	if ( eoge[ i ] == 'GE' ){

		# overwrite all records with values >= than the stated value with NA
		x[ no.na( x[ , overwrites[ i ] ] >= val[ i ] ) , overwrites[ i ] ] <- NA

	} else {

		# if the line is just 'equal to'..
		if ( eoge[ i ] == '=' ){

			# overwrite all records with values == to the stated value with NA
			x[ no.na( x[ , overwrites[ i ] ] == val[ i ] ) , overwrites[ i ] ] <- NA
			
		# otherwise..
		} else {
			# there's something else going on in the script that needs to be human-viewed
			stop( "eoge isn't GE or =" )
		}
	}
}

# just to check..

# count the number of records in x
nrow( x )

# look at the first six..
head( x )

# ..and last six records of x
tail( x )

# finally, save the data frame as a '.rda' file for ultra-fast loading in the future.
save( x , file = 'household.rda' )


######################################################
# close and re-open R to see how much faster this is #
######################################################


load( 'household.rda' )

# count the number of records in x
nrow( x )

# look at the first six..
head( x )

# ..and last six records of x
tail( x )


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
