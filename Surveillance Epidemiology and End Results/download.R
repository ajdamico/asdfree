# analyze survey data for free (http://asdfree.com) with the r language
# surveillance epidemiology and end results
# 1973 and beyond

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# your.username <- "username"
# your.password <- "password"
# library(downloader)
# setwd( "C:/My Directory/SEER/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Surveillance%20Epidemiology%20and%20End%20Results/download.R" , prompt = FALSE , echo = TRUE )
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


###########################################################
# download the main seer zipped file onto your local disk #
###########################################################


# # # # # # # # # # # # # #
# important user warning! #
# # # # # # # # # # # # # #


# it is free.  no money.  public data.  zero cost. #

# you *must* visit this national cancer institute website and agree to their terms
# in order to receive a username and password (a few days later)
# https://seer.cancer.gov/seertrack/data/request/

# once they've e-mailed you a login and password,
# fill them in below, and the download script will work

# your.username <- "username"
# your.password <- "password"

# this download automation script will not work without the above lines filled in.
# if the your.username and your.password lines above are not filled in,
# the script is going to break.  to repeat.  you must fill in a form to access seer data.


# # # # # # # # # # # # # # # # # 
# end of important user warning #
# # # # # # # # # # # # # # # # #


# set your working directory.
# all SEER data files will be stored here
# after downloading.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/SEER/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( "downloader" , "digest" )

# no need to edit anything below this line #


# # # # # # # # #
# program start #
# # # # # # # # #


library(downloader)		# downloads and then runs the source() function on scripts from github


# create a temporary file on your local disk
tf <- tempfile()


# find the seerstat page containing the link to the latest zipped file
ssp <- readLines( "http://seer.cancer.gov/data/options.html" )


# find the latest filepath
fp <- 
	# extract just the https:// address
	gsub( '(.*)\"https://(.*)\\.(zip|ZIP)\"(.*)' , "\\2.\\3" , 
		# find the line with the zipped file on it
		grep( "\\.(zip|ZIP)" , ssp , value = TRUE ) 
	)

# there can be only one
stopifnot( length( fp ) == 1 )


# build the https:// path to the seer ascii data file,
# which includes the login information you should have entered above
seer.url <- 
	paste0(
		"https://" ,
		your.username ,
		":" ,
		your.password ,
		"@" , 
		fp
	)

	
# download the zipped file to the temporary file
download( seer.url , tf )

# unzip it into your current working directory
unzip( tf )

# remove the temporary file from your local disk
file.remove( tf )


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
