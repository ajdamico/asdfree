# analyze survey data for free (http://asdfree.com) with the r language
# california health interview survey
# odd years from 2001 until 2011, 2012-2014
# all available files (including documentation)

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/CHIS/" )
# your_username <- 'yourusername'
# your_password <- 'yourpassword'
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/California%20Health%20Interview%20Survey/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


########################################################################################
# download every file from every year of the California Health Interview Survey with R #
# then save every file as an R data frame (.rda) so future analyses can be rapid       #
########################################################################################


# # # # # # # # # # # # # #
# important user warning! #
# # # # # # # # # # # # # #

# you *must* visit ucla's website and register for a username and password, then 
# download a single year of microdata manually from their website
loginpage <- "http://healthpolicy.ucla.edu/pages/login.aspx"
# to activate your account before running this massive download automation program


# once you have registered and downloaded any year of data, place your username and password in the script below.
# this script will not run until a valid username and password are included in the two lines below.
# and make sure you uncomment those two lines by removing the `#`s as well

# your_username <- 'yourusername'
# your_password <- 'yourpassword'

# this download automation script will not work without the above lines filled in.
# if the your_username and your_password lines above are not filled in with the details you provided at registration, 
# the script is going to break.  to repeat.  register to access chis data.


# # # # # # # # # # # # # # # # # 
# end of important user warning #
# # # # # # # # # # # # # # # # #


# set your working directory.
# each year of the CHIS will be stored in a year-specific folder here
# after downloading and importing it.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/CHIS/" )
# ..in order to set your current working directory


# remove the # in order to run this install.packages line only once
# install.packages( c( "RCurl" , "downloader" ) )

# no need to edit anything below this line #


# # # # # # # # #
# program start #
# # # # # # # # #


library(RCurl)			# load RCurl package (downloads https files)
library(foreign)	 	# load foreign package (converts data files into R)
library(downloader)		# downloads and then runs the source() function on scripts from github


# load the download_cached and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url(
	"https://raw.githubusercontent.com/ajdamico/asdfree/master/Download%20Cache/download%20cache.R" ,
	prompt = FALSE ,
	echo = FALSE
)


# initiate and then set a curl handle to store information about this download
curl = getCurlHandle()

# initate a cookies file
curlSetOpt(
	cookiejar = 'cookies.txt' , 
	followlocation = TRUE , 
	autoreferer = TRUE , 
	curl = curl
)

# connect to the login page to download the contents of the `viewstate` option
html <- getURL( loginpage , curl = curl )

# extract the `viewstate` string
viewstate <- 
	as.character(
		sub(
			'.*id="__VIEWSTATE" value="([0-9a-zA-Z+/=]*).*' , 
			'\\1' , 
			html
		)
	)

# extract the `eventvalidation` string
eventvalidation <- 
	as.character(
		sub(
			'.*id="__EVENTVALIDATION" value="([0-9a-zA-Z+/=]*).*' , 
			'\\1' , 
			html
		)
	)


	
# construct a list full of parameters to pass to the ucla website
params <- 
	list(
		'ctl00$ctl29$g_3a8b961a_097a_4aa2_a7b2_9959a01104bd$ctl00$UserName'    = your_username ,
		'ctl00$ctl29$g_3a8b961a_097a_4aa2_a7b2_9959a01104bd$ctl00$Password'    = your_password ,
		'ctl00$ctl29$g_3a8b961a_097a_4aa2_a7b2_9959a01104bd$ctl00$LoginLinkButton' = 'uclaButton' ,
		'__VIEWSTATE'                                  = viewstate ,
		'__EVENTVALIDATION'                            = eventvalidation
    )
	
	
# post these parameters to the login page to authenticate
html = postForm(loginpage, .params = params, curl = curl)

# confirms the result's contents contains the word `Logout` because
# if it does not contain this text, you're not logged in.  sorry.
if ( !grepl('Logout', html) ) stop( 'YOU ARE NOT LOGGED IN' )

# initiate a temporary file and a temporary directory
tf <- tempfile() ; td <- tempdir()

# loop through every year of available chis microdata
for( this_year in c( seq( 2001 , 2011 , 2 ) , 2012:2014 ) ){

	# create an empty year-specific folder within the working directory
	dir.create( as.character( this_year ) )

	# loop through all three filetypes
	for( agegrp in c( 'adult' , 'teen' , 'child' ) ){

		# recode an off-named filetype
		if( this_year == 2014 & agegrp == 'teen' ) agegrp <- 'adolescent'
	
		# construct the full expected url of the stata file
		path_to_file <- 
			paste0( 
				"http://healthpolicy.ucla.edu/chis/data/public-use-data-file/Documents/chis" , 
				substr( this_year , 3 , 4 ) , 
				"_" , 
				agegrp , 
				"_stata.zip" 
			)

		# download the file number
		this_file <- download_cached( path_to_file , destfile = NULL , FUN = getBinaryURL , curl = curl )

		# write the file to the temporary file on the local disk
		writeBin( this_file , tf )

		# unzip the downloaded files into the year-specific directory
		unzipped_files <- unzip( tf , exdir = as.character( this_year ) )

		# loop through all .dta files that were unzipped
		for( this_dta in grep( "\\.dta$" , unzipped_files , value = TRUE ) ){
		
			# load the .dta file as an R `data.frame` object
			x <- read.dta( this_dta , convert.factors = FALSE )
			
			# convert all column names to lowercase
			names( x ) <- tolower( names( x ) )
			
			# store the `data.frame` object as an .rda file on the local disk
			save( x , file = paste0( "./" , this_year , "/" , tolower( gsub( "\\.dta$" , ".rda" , basename( this_dta ) ) ) ) )
			
			# remove this object from active memory and clear up RAM
			rm( x ) ; gc()
			
		}
	}
}


# the current working directory should now contain one folder per year of data,
# each with three R data files (.rda) in the main directory,
# as well as the original files downloaded from ucla (including the survey documentation)


# once complete, this script does not need to be run again.
# instead, use one of the analysis scripts,
# which utilize these newly-created R data files (.rda)


# print a reminder: set the directory you just saved everything to as read-only!
message( paste( "all done.  you should set" , getwd() , "read-only so you don't accidentally alter these files." ) )
