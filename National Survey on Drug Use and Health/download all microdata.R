# analyze survey data for free (http://asdfree.com) with the r language
# national survey on drug use and health
# 1979 through 2014
# all available files (including documentation)

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NSDUH/" )
# your.username <- 'your@login.com'
# your.password <- 'yourpassword'
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Survey%20on%20Drug%20Use%20and%20Health/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


############################################################################################
# download every file from every year of the National Survey on Drug Use and Health with R #
# then save every file as an R data frame (.rda) so future analyses can be rapid           #
############################################################################################


# # # # # # # # # # # # # #
# important user warning! #
# # # # # # # # # # # # # #

# you *must* visit this university of michigan's inter-university consortium for political and social research
# website and register for a username and password, then click the link in the e-mail
# to activate your account before running this massive download automation program

# this is to protect both yourself and the respondents of the study.  register here:
# https://www.icpsr.umich.edu/cgi-bin/newacct
# by registering, you are agreeing to the conditions of use on that page

# once you have registered, place your username and password in the script below.
# this script will not run until a valid username and password are included in the two lines below.
# and make sure you uncomment those two lines by removing the `#`s as well

# your.username <- 'your@login.com'
# your.password <- 'yourpassword'

# this download automation script will not work without the above lines filled in.
# if the your.username and your.password lines above are not filled in with the details you provided at registration, 
# the script is going to break.  to repeat.  register to access nsduh data.


# # # # # # # # # # # # # # # # # 
# end of important user warning #
# # # # # # # # # # # # # # # # #


# set your working directory.
# each year of the NSDUH will be stored in a year-specific folder here
# after downloading and importing it.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NSDUH/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( c( "SAScii" , "RCurl" , "stringr" ) )

# no need to edit anything below this line #


# # # # # # # # #
# program start #
# # # # # # # # #


library(RCurl)			# load RCurl package (downloads https files)
library(SAScii) 		# load the SAScii package (imports ascii data with a SAS script)
library(foreign)	 	# load foreign package (converts data files into R)
library(stringr)	 	# load stringr package (manipulates character strings easily)
library(downloader)		# downloads and then runs the source() function on scripts from github


# create a temporary file
tf <- tempfile()


# initiate the no.na() function
# this function replaces NA (missing) observations with whatever's in the 'value' parameter
no.na <-
    function( x , value = FALSE ){
        x[ is.na( x ) ] <- value
        x
    }

# create a studies.by.year data frame that contains all of the years of data available,
# as well as the substance abuse and mental health data (samhda) identification number (used in the downloading pattern)
studies.by.year <-
	data.frame(
	
		# the first column in this new data frame contains each available year
		# (notice some years are not available)
		year = c( 1979 , 1982 , 1985 , 1988, 1990:2014 ) ,
		
		# the second column contains the samhda id
		id = c( 
			# 1979 - 1992
			6843 , 6845 , 6844 , 9522 , 9833 , 6128 , 6887 ,
			# 1993 - 1999
			6852 , 6949 , 6950 , 2391 , 2755 , 2934 , 3239 ,
			# 2000 - 2006
			3262 , 3580 , 3903 , 4138 , 4373 , 4596 , 21240 ,
			# 2007 - 2014
			23782 , 26701 , 29621 , 32722 , 34481 , 34933 , 35509 , 36361
		)
	)

# load the download_cached and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url(
	"https://raw.githubusercontent.com/ajdamico/asdfree/master/Download%20Cache/download%20cache.R" ,
	prompt = FALSE ,
	echo = FALSE
)


# loop through each year of nsduh data available, starting with the most current first
# the rev() function reverses the order, so instead of starting with the 1979 and finishing with 2010,
# the program downloads 2010 first and then works backward.
for ( i in rev( seq( nrow( studies.by.year ) ) ) ){

	# initiate a curl handle so the remote server knows it's you.
	curl = getCurlHandle()

	# set a cookie file on the local disk
	curlSetOpt(
		cookiejar = 'cookies.txt' , 
		followlocation = TRUE , 
		autoreferer = TRUE , 
		curl = curl
	)

	
	# create a new object storing an atomic character string with only the study id
	id <- as.character( studies.by.year[ i , "id" ] )
	# create a new object containing the current year
	year <- studies.by.year[ i , 'year' ]

	# the file names use five digits, so add a leading zero when id has four digits
	id5 <- str_pad( id , 5 , pad = '0' )
	
	# print the current file year to the screen
	cat( "  current progress: preparing the nsduh" , year , "file                    " , "\r" )

	# list out the filepath on the server of the file-to-download
	dp <- paste0( "http://www.icpsr.umich.edu/cgi-bin/bob/zipcart2?study=" , id5 , "&ds=1&path=ICPSR" )
		
	# post your username and password to the umich server
	login.page <- 
		postForm(
			"http://www.icpsr.umich.edu/ticketlogin" , 
			email = your.username ,
			password = your.password ,
			path = "ICPSR" ,
			request_uri = dp ,
			style = "POST" ,
			curl = curl 
		)
	
	# consent to terms of use page
	terms.of.use.page <- 
		postForm(
			"http://www.icpsr.umich.edu/cgi-bin/terms" , 
			agree = 'yes' ,
			path = "ICPSR" , 
			study = id5 , 
			ds = 1 , 
			bundle = "all" , 
			dups = "yes" ,
			style = "POST" ,
			curl = curl
		)

	# download the current stata file onto the local disk
	this_zip <- download_cached( dp , destfile = NULL , FUN = getBinaryURL , curl = curl )

	# initiate a heading object
	h <- basicHeaderGatherer()

	# pull the filename off of the server
	try( doc <- getURI( dp , headerfunction = h$update , curl = curl ) , silent = TRUE )
	
	# extract the name from that `h` object
	lfn <- gsub( '(.*)\\"(.*)\\"' , "\\2" , h$value()[["Content-Type"]] )
	
	# save the actual downloaded-file to the filepath specified on the local disk
	writeBin( this_zip , tf )
	
	# remove the zipped file from RAM
	rm( this_zip ) ; gc()
	
	# unzip the contents of the stata file into the current working directory
	unzip( tf )

	# remove the temporary file
	file.remove( tf )

	# current unzip directory
	unzip.dir <- paste0( getwd() , "/ICPSR_" , id5 )

	# current year directory
	year.dir <- paste0( getwd() , "/" , year )

	# rename the file directory to the current year
	file.rename( unzip.dir , year.dir )

	# set the path to stata file
	path.to.dta <- paste0( getwd() , "/" , year , "/DS0001/" , id5 , "-0001-Data.dta" )

	# read in the stata file
	stata.attempt <- try( x <- read.dta( path.to.dta , convert.factors = FALSE ) , silent = TRUE )
	
	
	# if the stata file type isn't valid for the R `foreign` package, import the spss file instead..
	if( class( stata.attempt ) == 'try-error' ){

		# clear up RAM
		rm( x ) ; gc()
	
		# find the rda file
		path.to.rda <- paste0( getwd() , "/" , year , "/DS0001/" , id5 , "-0001-Data.rda" )
	
		# load it
		load( path.to.rda )
		
		# copy it over to the data.frame object `x`
		x <- get( paste0( 'da' , id5 , '.0001' ) )
		
		# remove the original data.frame
		rm( list = paste0( 'da' , id5 , '.0001' ) ) ; gc()
		
		# find all factor variables
		fvars <- names( x )[ sapply( x , is.factor ) ]
		
		# loop through each of them, converting them all to numeric.
		for ( fv in fvars ) x[ , fv ] <- as.numeric( x[ , fv ] )
	
	}

	# path to the supplemental recodes file
	path.to.supp <- paste0( getwd() , "/" , year , "/DS0001/" , id5 , "-0001-Supplemental_syntax.do" )

	# read the supplemental recodes lines into R
	commented.supp.syntax <- readLines( path.to.supp )

	# and remove any stata comments
	uncommented.supp.syntax <- SAS.uncomment( commented.supp.syntax , "/*" , "*/" )

	# remove blank lines
	supp.syntax <- uncommented.supp.syntax[ uncommented.supp.syntax != "" ]

	# confirm all remaining recode lines contain the word 'replace'
	# right now, the supplemental recodes are relatively straightforward.
	# should any of them contain non-'replace' syntax, this part of this
	# R script will require more flexibility
	stopifnot( 
		length( supp.syntax ) == 
		sum( unlist( lapply( "replace" , grepl , supp.syntax ) ) )
	)

	# figure out exactly how many recodes will need to be processed
	# (this variable will be used for the progress monitor that prints to the screen)
	how.many.recodes <- length( supp.syntax )
	
	# loop through the entire stata supplemental recodes file
	for ( j in seq( supp.syntax ) ){

		# add a screen counter to show how many supplemental recodes have been performed so far
		cat( "  current progress: supplemental recode" , j , "of" , how.many.recodes , "on the nsduh" , year , "file                " , "\r" )

		# isolate the current stata "replace .. if .." command
		current.replacement <- supp.syntax[ j ]
		
		# locate the name of the current variable to be overwritten
		space.positions <- 
			gregexpr( 
				" " , 
				current.replacement 
			)[[1]]
		
		variable <- substr( current.replacement , space.positions[1] + 1 , space.positions[2] - 1 )
		
		# figure out the logical test contained after the stata 'if' parameter
		condition.to.blank <- unlist( strsplit( current.replacement , " if " ) )[2]
		
		# add an x$ to indicate which data frame to alter in R
		condition.test <- gsub( variable , paste0( "x$" , variable ) , condition.to.blank )
		
		# build the entire recode line, with a "<- NA" to overwrite
		# each of these codes with missing values
		recode.line <- 
			paste0( 
				"x[ no.na( " , 
				condition.test ,
				") , '" ,
				variable ,
				"' ] <- NA"
			)
			
		# uncomment this to print the current recode to the screen
		# print( recode.line )
		
		# execute the actual recode
		eval( parse( text = recode.line ) )
		
	}


	# convert all column names to lowercase
	names( x ) <- tolower( names( x ) )

	# determine the name of the R object (data.frame) to save the final table as..
	# NSDUH.YY.df
	df.name <- paste( "NSDUH" , substr( year , 3 , 4 ) , "df" , sep = "." )

	# save the R data frame to that file-specific name
	assign( df.name , x )
		
	# save the R data frame to a .rda file on the local computer
	save( list = df.name , file = paste0( getwd() , "/" , year , "/" , gsub( "df" , "rda" , df.name ) ) )

	# remove both x and the renamed, saved data frame
	rm( x )
	rm( list = df.name )

	# clear up RAM
	gc()

}


# the current working directory should now contain one folder per year of data,
# each with an R data file (.rda) in the main directory,
# as well as the original files downloaded from samhsa (including the survey documentation)


# once complete, this script does not need to be run again.
# instead, use one of the analysis scripts,
# which utilize these newly-created R data files (.rda)


# print a reminder: set the directory you just saved everything to as read-only!
message( paste( "all done.  you should set" , getwd() , "read-only so you don't accidentally alter these files." ) )

