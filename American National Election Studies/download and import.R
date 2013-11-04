# analyze survey data for free (http://asdfree.com) with the r language
# american national election studies
# 1948 through 2012
# cumulative, time series, pilot, and special studies

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# your.username <- "username"
# your.password <- "password"
# library(downloader)
# setwd( "C:/My Directory/ANES/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/American%20National%20Election%20Studies/download%20and%20import.R" , prompt = FALSE , echo = TRUE )
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

# your.username <- "username"
# your.password <- "password"

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
# install.packages( c( "Hmisc" , "httr" , "stringr" , "memisc" ) )

# no need to edit anything below this line #


# # # # # # # # #
# program start #
# # # # # # # # #


require(foreign) 	# load foreign package (converts data files into R)
require(stringr)	# load stringr package (manipulates character strings easily)
require(httr)		# load httr package (downloads files from the web, with SSL and cookies)
require(Hmisc) 		# load Hmisc package (loads spss.get function)
require(memisc)		# load memisc package (loads spss portable table import functions)


# construct a list containing the pre-specified login information
values <- 
    list(
        "email" = your.username , 
        "pass" = your.password
    )

# contact the anes website to log in
POST( "http://www.electionstudies.org/studypages/download/login-process.php" , body = values )

# download the `all_datasets` page to figure out what needs to be downloaded
z <- GET( "http://www.electionstudies.org/studypages/download/datacenter_all_datasets.php" )

# create a temporary file and a temporary directory
tf <- tempfile() ; td <- tempdir()

# write the information from the `all_datasets` page to a local file
writeBin( z$content , tf )

# read that local file into a character vector,
# with one character string per line
y <- readLines( tf )

# retain only the lines containing text in bold
y <- y[ grep('<b>' , y ) ]

# remove everything in those strings before the bold tag `<b>`
y <- unlist( lapply( strsplit( y , '<b>' ) , '[[' , 2 ) )

# extract each of the study names
study.names <- unlist( lapply( strsplit( y , '<' ) , '[[' , 1 ) )

# remove colons and slashes
study.names <- gsub( '/|: ' , ' ' , study.names )

# perform some regular expression magic thanks to help from stackoverflow
# http://stackoverflow.com/questions/17775013/how-to-extract-a-string-that-both-matches-some-pattern-and-rests-between-two-oth

# extract the filenames of all .dta files available
dta.files <-
	gsub(
		"(.*a href=\\\")(.*dta\\.zip)(.*)$" , 
		"\\2" , 
		y
	)

# a few of these studies did not include `.dta` files, so blank out the file names
dta.files[ !grepl( 'dta.zip' , dta.files , fixed = TRUE ) ] <- ""

# make this character vector into a list
files.to.download <- as.list( dta.files )

# add some names to every element in the list
names( files.to.download ) <- str_trim( study.names )

# hardcode a couple of the studies that are non-standard on the anes website #

# identify studies with no data files
no.data.studies <-
	c(
		'ANES 2010 Time Series Study' ,
		'ANES 2006' ,
		"Auxiliary File ANES 2004 Time Series and Panel Contextual File" ,
		# this last one isn't a no data study, but it needs a database to load into a computer with 4GB
		# ..and it's not particularly useful
		"Auxiliary File Supplemental (off-wave non-ANES) Data File"
	)

# throw them out entirely!
files.to.download <-
	files.to.download[ !( names( files.to.download ) %in% no.data.studies ) ]
# no need to download data that's not there, huh?
	
# .sav files only
files.to.download[[ "ANES 2010-2012 Evaluations of Government and Society Study" ]] <-
	c(
		"../data/2010_2012EGSS/ANES_EGSS4_preliminary_release_sav.zip" ,
		"../data/2010_2012EGSS/ANES_EGSS3_preliminary_release_sav.zip" ,
		"../data/2010_2012EGSS/ANES_EGSS2_preliminary_release_sav.zip" ,
		"../data/2010_2012EGSS/anes2011_egss1dta.zip"
	)

# .por files only
files.to.download[[ "ANES 2008-2009 Panel Study" ]] <-
	"../data/2008_2009panel/anes2008_2009panelpor.zip"

# and this one was just duplicated then removed, so put it back in anew
files.to.download[[ "Auxiliary File ANES 2004 Time Series and Panel Contextual File" ]] <-
	"../data/2004prepost/anes2004TSandPanel_contextdta.zip"
	
# end of hardcodes #


# confirm that there are no empty strings in the files to be downloaded
if( any( sapply( files.to.download , function( z ) "" %in% z ) ) ) stop( "empty string lurkin around" )


# loop through each available study to download
for ( curStudy in seq( length( files.to.download ) ) ){

	# prepare a directory that's appropriately named
	dfn <- names( files.to.download )[[ curStudy ]]
	
	# remove the text 'anes' from the folder name
	dfn <- gsub( "ANES " , "" , dfn )
	
	# create the directory on the local disk
	dir.create( dfn )

	# loop through each file that needs to be downloaded..
	for ( i in files.to.download[[ curStudy ]] ){
	
		# determine the full http:// filepath of the file to download
		fn <- 
			gsub( 
				".." , 
				"http://www.electionstudies.org/studypages" , 
				i , 
				fixed = TRUE 
			)
		
		# print currrent progress to the screen
		cat( 'currently working on' , fn , '\r' )
		
		# download the damn file
		z <- GET( fn )
	
		# save the result to a temporary file on the local disk
		writeBin( z$content , tf )

		# unzip that temporary file to an equally-temporary directory
		z <- unzip( tf , exdir = td )
	
		# first look for a dta file
		if ( any( grepl( 'dta' , z ) ) ){
			
			# find which one it is from among everything zipped up together..
			fp <- z[ grep( 'dta' , z ) ]
		
			# ..import that puppy
			x <- read.dta( fp , convert.factors = FALSE )
		
		} else {
		
			# look for a .por file
			if ( any( grepl( 'por' , z ) ) ){
			
				# find which one it is from among everything zipped up together
				fp <- z[ grep( 'por' , z ) ]
			
				# import that puppy
				x <- 
					data.frame( 
						as.data.set(
							spss.portable.file( fp )
						) 
					)
			
			# otherwise find the .sav file
			} else {
		
				# find which one it is from among everything zipped up together
				fp <- z[ grep( 'sav' , z ) ]
			
				# import that puppy
				x <- spss.get( fp , use.value.labels = FALSE )
				
			}
		}
	
		# store the basename of the file,
		# replacing the extension with `.rda`
		bn <- gsub( 'sav|por|dta' , 'rda' , basename( fp ) )
			
		# convert all column names in the data.frame to lowercase
		names( x ) <- tolower( names( x ) )

		# construct the save filename
		sfn <-
			paste( 
				names( files.to.download )[[ curStudy ]] ,
				bn ,
				sep = "/"
			)

		# remove the text 'anes' from the filename
		sfn <- gsub( "ANES " , "" , sfn )
		
		# save the data.frame to an `.rda` file on the local disk
		save( x , file = sfn )
		
		# remove both objects from memory
		rm( x , z )
		
		# clear up RAM
		gc()
	
	}
	
}

# delete the temporary file..
file.remove( tf )

# ..and temporary directory on the local disk
unlink( td , recursive = TRUE )

# print a reminder: set the directory you just saved everything to as read-only!
message( paste0( "all done. you should set the folder " , getwd() , " read-only so you don't accidentally alter these tables." ) )


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
