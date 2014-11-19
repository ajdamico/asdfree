# analyze survey data for free (http://asdfree.com) with the r language
# panel study of income dynamics
# 1968 through 2011
# family, marriage history, childbirth & adoption history, parent identification, cross-year individual

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/PSID/" )
# your.username <- 'your@login.com'
# your.password <- 'yourpassword'
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Panel%20Study%20of%20Income%20Dynamics/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
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


####################################################################################
# download every file from every year of the Panel Study of Income Dynamics with R #
# then save every file as an R data frame (.rda) so future analyses can be rapid.  #
####################################################################################


# # # # # # # # # # # # # #
# important user warning! #
# # # # # # # # # # # # # #

# you *must* visit this university of michigan's institute for social research
# website and register for a username and password, then click the link in the e-mail
# to activate your account before running this massive download automation program

# this is to protect both yourself and the respondents of the study.  register here:
# http://simba.isr.umich.edu/U/ca.aspx
# by registering, you are agreeing to the conditions of use on that page

# once you have registered, place your username and password in the script below.
# this script will not run until a valid username and password are included in the two lines below.
# and make sure you uncomment those two lines by removing the `#`s as well

# your.username <- 'your@login.com'
# your.password <- 'yourpassword'

# this massive ftp download automation script will not work without the above lines filled in.
# if the your.username and your.password lines above are not filled in with the details you provided at registration, 
# the script is going to break.  to repeat.  register to access psid data.


# # # # # # # # # # # # # # # # # 
# end of important user warning #
# # # # # # # # # # # # # # # # #


# set your working directory.
# all PSID data files will be stored here
# after downloading.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PSID/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( c( "SAScii" , "RCurl" ) )

# no need to edit anything below this line #


# # # # # # # # #
# program start #
# # # # # # # # #


library(SAScii) 	# load the SAScii package (imports ascii data with a SAS script)
library(RCurl)		# load RCurl package (downloads https files)


# follow the authentication technique described on this stackoverflow post
# http://stackoverflow.com/questions/15853204/how-to-login-and-then-download-a-file-from-aspx-web-pages-with-r


# initiate and then set a curl handle to store information about this download
curl = getCurlHandle()

curlSetOpt(
	cookiejar = 'cookies.txt' , 
	followlocation = TRUE , 
	autoreferer = TRUE , 
	curl = curl
)

# connect to the login page to download the contents of the `viewstate` option
html <- 
	getURL(
		'http://simba.isr.umich.edu/u/Login.aspx' , 
		curl = curl
	)

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

# construct a list full of parameters to pass to the umich website
params <- 
	list(
		'ctl00$ContentPlaceHolder1$Login1$UserName'    = your.username ,
		'ctl00$ContentPlaceHolder1$Login1$Password'    = your.password ,
		'ctl00$ContentPlaceHolder1$Login1$LoginButton' = 'Log In' ,
		'__VIEWSTATE'                                  = viewstate ,
		'__EVENTVALIDATION'                            = eventvalidation
    )
# and now, with the username, password, and viewstate parameters all squared away
# it's time to start downloading individual files from the umich website	


# # # # # # # # # # # # #
# custom save function  #

# initiate a function that requires..
save.psid <-
	# ..a file number, a save name, the parameters list, and the curl options
	function( file , name , params , curl ){

		# logs into the umich form
		html = postForm('http://simba.isr.umich.edu/U/Login.aspx', .params = params, curl = curl)
		
		# confirms the result's contents contains the word `Logout` because
		# if it does not contain this text, you're not logged in.  sorry.
		if ( !grepl('Logout', html) ) stop( 'no longer logged in' )
	
		# initiate a temporary file and a temporary directory
		tf <- tempfile() ; td <- tempdir()
		
		# download the file number
		file <- 
			getBinaryURL( 
				paste0( 
					"http://simba.isr.umich.edu/Zips/GetFile.aspx?file=" , 
					file 
				) , 
				curl = curl 
			)
		
		# write the file to the temporary file on the local disk
		writeBin( file , tf )
		
		# unzip the temporary file to the temporary directory
		z <- unzip( tf , exdir = td )
	
		# figure out which file contains the data (so no readmes or technical docs)
		fn <- z[ grepl( ".txt" , tolower( z ) , fixed = TRUE ) & ! grepl( "_vdm|readme|doc|errata" , tolower( z ) ) ]
		
		# figure out which file contains the sas importation script
		sas_ri <- z[ grepl( '.sas' , z , fixed = TRUE ) ]

		# read the text file directly into an R data frame with `read.SAScii`
		x <- read.SAScii( fn , sas_ri )

		# convert all column names to lowercase
		names( x ) <- tolower( names( x ) )
		
		# add a `one` column
		x$one <- 1
		
		# remove the files you'd downloaded from the local disk
		file.remove( tf , z )
	
		# copy the data.frame `x` over to whatever the `name` parameter was supposed to be
		assign( name , x )
		
		# save the renamed data.frame to an R data file (.rda)
		save( list = name , file = paste0( name , '.rda' ) )
		
		# delete the data.frame `x`
		rm( x )

		# delete the data.frame (name)
		rm( list = name )
		
		# clear up RAM
		gc()
		
		# confirm that the function worked by returning TRUE
		TRUE
	}
		
# end of custom save function #
# # # # # # # # # # # # # # # #


# construct a `family` data.frame of all file names specified on
# http://simba.isr.umich.edu/Zips/ZipMain.aspx
# (note: you may have to be logged in to see those files)
family <-
	data.frame(
		year = c( 1968:1997 , seq( 1999 , 2011 , 2 ) ) ,
		file = c( 1056 , 1058:1082 , 1047:1051 , 1040 , 1052 , 1132 , 1139 , 1152 , 1156 )
	)

# loop through each record in the `family` file..
for ( i in seq( nrow( family ) ) ){
	
	# ..and save the file to the local disk, using the pre-defined function
	save.psid( family[ i , 'file' ] , paste0( "fam" , family[ i , 'year' ] ) , params , curl )
}

# automatically down the marriage, childbirth, parentid, and cross-year individual files
# the exact same way, with the exact samee pre-defined function
save.psid( 1121 , 'marriage' , params , curl )
save.psid( 1109 , 'childbirth' , params , curl )
save.psid( 1123 , 'parentid' , params , curl )
save.psid( 1053 , 'ind' , params , curl )


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
