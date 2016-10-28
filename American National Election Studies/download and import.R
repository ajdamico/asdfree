# analyze survey data for free (http://asdfree.com) with the r language
# american national election studies
# 1948 through 2012
# cumulative, time series, pilot, and special studies

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# your.username <- "email@address.com"
# library(downloader)
# setwd( "C:/My Directory/ANES/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/American%20National%20Election%20Studies/download%20and%20import.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


########################################################################################
# download every file from every year of the American National Election Studies with R #
# then save every file as an R data frame (.rda) so future analyses can be rapid       #
########################################################################################


# # # # # # # # # # # # # #
# important user warning! #
# # # # # # # # # # # # # #

# you *must* visit this electionstudies.org
# website and register for a username and password, then click the link in the e-mail
# to activate your account before running this massive download automation program

# this is to protect both yourself and the respondents of the study.  register here:
# http://www.electionstudies.org/studypages/download/registration_form.php

# by registering, you are agreeing to their terms of use,
# stated at the bottom of the registration page

# once you have registered, place your username and password in the script below.
# this script will not run until a valid username and password are included in the two lines below.
# oh and don't forget to uncomment these two lines by removing the `#`

# your.username <- "email@address.com"

# this massive ftp download automation script will not work without the above lines filled in.
# if the your.username and your.password lines above are not filled in with the details you provided at registration, 
# the script is going to break.  to repeat.  register to access anes data.


# # # # # # # # # # # # # # # # # 
# end of important user warning #
# # # # # # # # # # # # # # # # #


# set your working directory.
# all ANES data files will be stored here
# after downloading.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/ANES/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( c( "Hmisc" , "httr" , "stringr" , "memisc" , "haven" , "downloader" ) )

# no need to edit anything below this line #


# # # # # # # # #
# program start #
# # # # # # # # #


library(foreign) 	# load foreign package (converts data files into R)
library(stringr)	# load stringr package (manipulates character strings easily)
library(httr)		# load httr package (downloads files from the web, with SSL and cookies)
library(Hmisc) 		# load Hmisc package (loads spss.get function)
library(memisc)		# load memisc package (loads spss portable table import functions)
library(haven)		# load stata files after version 12

# construct a list containing the pre-specified login information
values <- list( "email" = your.username )

# contact the anes website to log in
POST( "http://www.electionstudies.org/studypages/download/login-process.php" , body = values )

# download the `all_datasets` page to figure out what needs to be downloaded
z <- GET( "http://www.electionstudies.org/studypages/download/datacenter_all_datasets.php" )

# create a temporary file and a temporary directory
tf <- tempfile()

# write the information from the `all_datasets` page to a local file
writeBin( z$content , tf )

# read that local file into a character vector,
# with one character string per line
y <- readLines( tf )

# retain only the dta.zip files
y <- grep( 'dta\\.zip' , y , value = TRUE )

# remove everything in those strings before the bold tag `<b>`
all_studies <- gsub( '(.*)data/(.*)dta\\.zip\"(.*)' , "\\2dta.zip" , y )

# loop through each available study to download
for ( this_study in all_studies ){

	# decide where to save the zipped file
	study_folder <- gsub( "/(.*)" , "" , this_study )
	
	# create the directory on the local disk
	dir.create( study_folder , showWarnings = FALSE )

	# determine the full http:// filepath of the file to download
	fn <- paste0( "http://www.electionstudies.org/studypages/data/" , this_study )
	
	# print currrent progress to the screen
	cat( 'currently working on' , fn , '\r' )
	
	# download the damn file
	z <- GET( fn )

	# save the result to a temporary file on the local disk
	writeBin( z$content , tf )

	# unzip that temporary file to an equally-temporary directory
	z <- unzip( tf , exdir = study_folder )

	# find which one it is from among everything zipped up together..
	fp <- z[ grep( 'dta' , z ) ]
	
	# ..import that puppy
	x <- read_dta( fp[ 1 ] )
	
	# just check that it's the same file if there's more than
	# one file included in the zipped file.
	if( length( fp ) == 2 ) stopifnot( nrow( read_dta( fp[ 2 ] ) ) == nrow( x ) )

	# also confirm that there's a max of two files in the zipped file.
	stopifnot( length( fp ) %in% 1:2 )
		
	# store the basename of the file,
	# replacing the extension with `.rda`
	bn <- gsub( 'dta' , 'rda' , basename( fp[ 1 ] ) )
		
	# convert all column names in the data.frame to lowercase
	names( x ) <- tolower( names( x ) )

	# construct the save filename
	sfn <- paste( study_folder , bn , sep = "/"	)

	# remove the text 'anes' from the filename
	sfn <- gsub( "ANES " , "" , sfn )
	
	# save the data.frame to an `.rda` file on the local disk
	save( x , file = sfn )
	
	# remove both objects from memory
	rm( x , z )
	
	# clear up RAM
	gc()
		
}

# delete the temporary file
file.remove( tf )

# print a reminder: set the directory you just saved everything to as read-only!
message( paste0( "all done. you should set the folder " , getwd() , " read-only so you don't accidentally alter these tables." ) )

