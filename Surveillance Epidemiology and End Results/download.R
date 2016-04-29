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
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Surveillance%20Epidemiology%20and%20End%20Results/download.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


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


# load the download_cached and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url( 
	"https://raw.githubusercontent.com/ajdamico/asdfree/master/Download%20Cache/download%20cache.R" , 
	prompt = FALSE , 
	echo = FALSE 
)


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
download_cached( seer.url , tf , FUN = download )

# unzip it into your current working directory
unzip( tf )

# remove the temporary file from your local disk
file.remove( tf )

