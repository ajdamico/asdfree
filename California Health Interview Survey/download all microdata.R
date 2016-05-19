# setwd( "C:/My Directory/CHIS")
your.username <- "your_username"
your.password <- "your_password"






loginpage <- "http://healthpolicy.ucla.edu/pages/login.aspx"



library(foreign)

library(RCurl)		# load RCurl package (downloads https files)

# initiate and then set a curl handle to store information about this download
curl = getCurlHandle()

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


	
# construct a list full of parameters to pass to the umich website
params <- 
	list(
		'ctl00$ctl29$g_3a8b961a_097a_4aa2_a7b2_9959a01104bd$ctl00$UserName'    = your.username ,
		'ctl00$ctl29$g_3a8b961a_097a_4aa2_a7b2_9959a01104bd$ctl00$Password'    = your.password ,
		'ctl00$ctl29$g_3a8b961a_097a_4aa2_a7b2_9959a01104bd$ctl00$LoginLinkButton' = 'uclaButton' ,
		'__VIEWSTATE'                                  = viewstate ,
		'__EVENTVALIDATION'                            = eventvalidation
    )
	
	
html = postForm(loginpage, .params = params, curl = curl)

# confirms the result's contents contains the word `Logout` because
# if it does not contain this text, you're not logged in.  sorry.

# initiate a temporary file and a temporary directory
tf <- tempfile() ; td <- tempdir()

for( this_year in c( seq( 2001 , 2011 , 2 ) , 2012:2014 ) ){

	dir.create( as.character( this_year ) )

	for( agegrp in c( 'adult' , 'teen' , 'child' ) ){

		path_to_file <- paste0( "http://healthpolicy.ucla.edu/chis/data/public-use-data-file/Documents/chis" , substr( this_year , 3 , 4 ) , "_" , agegrp , "_stata.zip" )

		# download the file number
		this_file <- getBinaryURL( path_to_file , curl = curl )

		# write the file to the temporary file on the local disk
		writeBin( this_file , tf )

		unzipped_files <- unzip( tf , exdir = as.character( this_year ) )

		for( this_dta in grep( "\\.dta$" , unzipped_files , value = TRUE ) ){
		
			x <- read.dta( this_dta )
			
			names( x ) <- tolower( names( x ) )
			
			save( x , file = paste0( "./" , this_year , "/" , tolower( gsub( "\\.dta$" , ".rda" , basename( this_dta ) ) ) ) )
			
			rm( x ) ; gc()
			
		}
		
	}
}




