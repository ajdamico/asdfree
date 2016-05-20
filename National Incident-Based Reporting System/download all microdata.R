# analyze survey data for free (http://asdfree.com) with the r language
# national incident-based reporting system
# all available years
# all available filetypes

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NIBRS/" )
# your.username <- 'your@login.com'
# your.password <- 'yourpassword'
# rm( studies.to.download ) # or pick a few # studies.to.download <- c( "2012 Extract Files" , "2004" , "2009 Uniform Crime Reporting" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Incident-Based%20Reporting%20System/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


#######################################################################################
# download every file from every year of the national incident-based reporting system #
# then save every file as an R data frame (.rda) so future analyses can be rapid.     #
#######################################################################################


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
# the script is going to break.  to repeat.  register to access nibrs data.


# # # # # # # # # # # # # # # # # 
# end of important user warning #
# # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # # #
# warning: this takes a while #
# # # # # # # # # # # # # # # #

# even if you're only downloading a single extract and you've got a fast internet connection,
# you'll be better off leaving this script to run overnight.  if you wanna download all available files and years,
# leave it running on friday afternoon (or even better: before you leave for a weeklong vacation).
# depending on your internet and processor speeds, the entire script should take between two and ten days.
# it's running.  don't believe me?  check the working directory (set below) for a new r data file (.rda) every few hours.





# set your working directory.
# all NIBRS data files will be stored here
# after downloading.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NIBRS/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( c( "MonetDB.R" , "MonetDBLite" , "RCurl" , "SAScii" , "descr" , "downloader" , "digest" , "stringr" , "R.utils" ) )



library(SAScii) 	# load the SAScii package (imports ascii data with a SAS script)
library(RCurl)		# load RCurl package (downloads https files)
library(stringr)	# load stringr package (manipulates character strings easily)
library(downloader)	# downloads and then runs the source() function on scripts from github
library(DBI)			# load the DBI package (implements the R-database coding)
library(MonetDB.R)	# load the MonetDB.R package (connects r to a monet database)
library(MonetDBLite)# load MonetDBLite package (creates database files in R)
library(descr)		# load the descr package (converts fixed-width files to delimited files)
library(R.utils)	# load the R.utils package (counts the number of lines in a file quickly)
library(foreign)	# load foreign package (converts data files into R)


# configure a monetdb database for the nibrs #

# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )

# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite() , dbfolder )




# this script's download files should be incorporated in download_cached's hash list
options( "download_cached.hashwarn" = TRUE )
# warn the user if the hash does not yet exist

# some download caching
downloader::source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Download%20Cache/download%20cache.R" , prompt = FALSE , echo = FALSE)

download_get_filename <- function(url, curl=getCurlHandle(), ...) {
	h <- RCurl::basicHeaderGatherer()
	RCurl::curlSetOpt(nobody=T, curl=curl)
	RCurl::getURL(url, headerfunction = h$update, curl=curl, ...)
	gsub( '(.*)\\"(.*)\\"' , "\\2" , h$value()[["Content-Type"]])
}

download_to_filename <- function(url, dlfile, curl=getCurlHandle(), ...) {
	RCurl::curlSetOpt(nobody=F, httpget=T, curl=curl)
	writeBin(RCurl::getBinaryURL(url = url, curl=curl, ...), dlfile)
	0L
}
# end download caching


# follow the authentication technique described on this stackoverflow post
# http://stackoverflow.com/questions/15853204/how-to-login-and-then-download-a-file-from-aspx-web-pages-with-r



# load the read.SAScii.monetdb function (a variant of read.SAScii that creates a database directly)
source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/MonetDB/read.SAScii.monetdb.R" , prompt = FALSE )

# download the contents of the webpage hosting all nibrs data files
all.nibrs.studies <- getURL( "http://www.icpsr.umich.edu/icpsrweb/NACJD/series/00128/studies?archive=NACJD&q=&paging.rows=10000&sortBy=7" )

# find all available study numbers
study.listing <- strsplit( all.nibrs.studies , '<a href="studies/' , fixed = TRUE )[[1]][-1]

# confirm that each study.listing has a <strong> tag
stopifnot( all( grepl( "strong" , study.listing ) ) )

# extract all study numbers
study.numbers <- gsub( "^([0-9]*)\\?archive=NACJD(.*)" , "\\1" , study.listing )

# extract all study names
study.names <- gsub( "(.*)strong>(.*)</strong></a(.*)" , "\\2" , study.listing )

# remove unnecessary words from the study names
study.names <- gsub( "National Incident-Based Reporting System, " , "" , study.names )

# remove everything except alphanumeric characters
# and spaces and dashes, so that folders can be named
study.names <- gsub( "[^-a-zA-Z0-9 ]" , "" , study.names )

# wherever study names have "(some text) year-year" put the year-year out in front
study.names <- gsub( "(.*) ([0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9])" , "\\2 \\1" , study.names )

# wherever study names have a year in the middle of the string, put the year out in front
study.names <- gsub( "(.*) ([0-9][0-9][0-9][0-9])(.*)" , "\\2 \\1\\3" , study.names )

# remove double-spaces from the study names, twice.
study.names <- gsub( "  " , " " , study.names )
study.names <- gsub( "  " , " " , study.names )

# remove leading and trailing whitespace
study.names <- str_trim( study.names )

# print the list of all study names available for download.
print( study.names )


# if you want to download all studies, ignore this next block.
# by default, this script downloads everything.  but that takes a while
# (a few days, for serious) so you might prefer to only download a subset.
# the very first study (the multiple-year concatenated file)
# takes approximately as long as all of the other files combined.  woah.


# if, for example, you wanted to download only these three studies,
# you could uncomment this next line by removing the `#` in front
# studies.to.download <- c( "2012 Extract Files" , "2004" , "2009 Uniform Crime Reporting" )
# read the text in the `study.names` object and subset according to those blocks.

# no need to edit anything below this line #


# if the object `studies.to.download` exists in working memory..
if ( exists( "studies.to.download" ) ){

	# determine which study numbers match the study names you've specified
	numbers.to.download <- match( studies.to.download , study.names )

# ..otherwise
} else {

	# just download every study number
	numbers.to.download <- seq_along( study.names )

}


# loop through all study numbers deemed download-worthy
for ( i in numbers.to.download ){

	# name a subdirectory within the current working directory..
	this.dir <- paste0( "./" , study.names[ i ] )

	# ..and create it.
	dir.create( study.names[ i ] )

	# determine the homepage of the current study to-be-downloaded
	hp <- 
		paste0( 
			"http://www.icpsr.umich.edu/icpsrweb/NACJD/series/00128/studies/" , 
			study.numbers[ i ] ,
			"?archive=NACJD&q=&paging.rows=10000&sortBy=7#" 
		)

	# download that homepage
	study.homepage <- getURL( hp )

	# determine which files are documentation
	m <- gregexpr( "file\\?.*?NACJD" , study.homepage )
	
	# isolate all documentation files
	all.docs <- regmatches( study.homepage , m )[[1]]
	
	# loop through each of the documentation files
	for ( j in all.docs ){
		dp <- paste0( "http://www.icpsr.umich.edu/cgi-bin/" , j )
		download_cached(dp, paste0(this.dir, "/", 
			download_get_filename(dp)), usecache=T, FUN=download_to_filename)
	}
	
	# determine which files on the study homepage are sas importation files
	m <- 
		gregexpr( 
			paste0(
				"terms2\\?study=" ,
				study.numbers[ i ] ,
				"\\&ds=[0-9][0-9]?\\&bundle=ascsas\\&path=NACJD"
			) , 
			study.homepage 
		)
	
	# isolate all of the sas read-in files
	all.sas_ri <- regmatches( study.homepage , m )[[1]]
	
	# confirm there's at least one sas file to download?
	if ( length( all.sas_ri ) == 0 ) stop( "current study doesn't have any data?" )
	
	# loop through all files that need to be downloaded
	for ( j in all.sas_ri ){
	
		# initiate a curl handle so the remote server knows it's you.
		curl = getCurlHandle()

		# set a cookie file on the local disk
		curlSetOpt(
			cookiejar = 'cookies.txt' , 
			followlocation = TRUE , 
			autoreferer = TRUE , 
			curl = curl
		)
	
		# list out the filepath on the server of the file-to-download
		dp <- paste0( "http://www.icpsr.umich.edu/cgi-bin/bob/" , j )
			
		# this script only works on study ids 0 thru 99, so if you go into triple-digits, crash.
		if ( gsub( "(.*)ds=([0-9][0-9]?)(.*)" , "\\2" , j ) == 99 ) stop( "a study contains at least ninety-nine files - program needs to be modified to deal with one hundred or more" )

		# post your username and password to the umich server
		login.page <- 
			postForm(
				"http://www.icpsr.umich.edu/ticketlogin" , 
				email = your.username ,
				password = your.password ,
				path = "NACJD" ,
				request_uri = dp ,
				style = "POST" ,
				curl = curl 
			)
	
		# consent to terms of use page
		terms.of.use.page <- 
			postForm(
				"http://www.icpsr.umich.edu/cgi-bin/terms" , 
				agree = 'yes' ,
				path = "NACJD" , 
				study = study.numbers[ i ] , 
				ds = gsub( "(.*)ds=([0-9][0-9]?)(.*)" , "\\2" , j ) , 
				bundle = "ascsas" , 
				dups = "yes" ,
				style = "POST" ,
				curl = curl
			)
		
		lfn <- download_get_filename(dp, curl=curl)
		download_cached(dp, paste0(this.dir, "/", lfn), usecache=T, FUN=download_to_filename, curl=curl)

		# unzip the downloaded file within the local drive
		z <- unzip( paste0( this.dir , "/" , lfn ) , exdir = this.dir )

		# determine the filenames that end with `sas`
		sas.import <- z[ grep( "sas$" , tolower( z ) ) ]
	
		# the 2004 - 2008 files have one character field in the sas file
		# that's been designated as numeric incorrectly.  fix it.
		if( study.names[ i ] %in% as.character( 2004:2008 ) ){
		
			# read in the file
			sip <- readLines( sas.import )
		
			# add a character string identifier to one field
			sip <- gsub( "V1012 46-49" , "V1012 $ 46-49" , sip )
			
			# overwrite the sas import script on the local disk
			writeLines( sip , sas.import )
		
		}
	
		# determine the filenames containing the word `data`
		data.file <- z[ grep( "data" , tolower( basename( z ) ) ) ]
	
		# if the current data.file is also gzipped..
		if ( grepl( "gz$" , tolower( data.file ) ) ){
		
			# gunzip it and overwrite itself in the current directory
			data.file <- gunzip( data.file )
			
		}
		
		# let the user/viewer know whatcha doin'
		print( paste( "currently importing" , data.file ) )
		
		# determine the tablename within the big database
		tablename <- gsub( "(.*)/ICPSR_(.*)/(DS|ds)(.*)" , "x\\2_\\4" , dirname( data.file ) )
		# it should be x[study number]_[dataset number]
		
		# in most cases, the sas importation script should start right at the beginning..
		beginline <- 1
		
		# read the data file into an r monetdb database
		read.SAScii.monetdb(
			fn = data.file ,
			sas_ri = sas.import ,
			tl = TRUE ,	# convert all column names to lowercase?
			tablename = tablename ,
			beginline = beginline ,
			skip.decimal.division = TRUE ,
			conn = db
		)
		
		
		# figure out which variables need to be recoded to system missing #
		
		# read the entire sas import script into a character vector
		recode.lines <- toupper( readLines( sas.import ) )
		
		# look for the start of the system missing recode block
		mvr <- intersect( grep( "RECODE TO SAS SYSMIS" , recode.lines ) , grep( "USER-DEFINED MISSING VALUE" , recode.lines ) )
		
		# fail if there are more than one.
		if ( length( mvr ) > 1 ) stop( "sas script has more than one sysmis recode block?" )
		
		# if there's just one..
		if ( length( mvr ) == 1 ){
			
			# isolate the recode lines
			recode.lines <- recode.lines[ mvr:length( recode.lines ) ]
			
			# find all lines that start with an IF statement and end with a semicolon
			lines.with.if <- grep( "IF (.*);" , recode.lines )
			
			# confirm all of those lines have a sas missing value (a dot) or a '' somewhere in there.
			lines.with.dots <- grep( "\\.|''" , recode.lines )

			# if the lines don't match up, fail cuz something's wrong.  terribly terribly wrong.
			if ( length( lines.with.if[ !( lines.with.if %in% lines.with.dots ) ] ) > 0 ) stop( "some recode line is recoding to something other than missing" )
			
			# further limit the recode lines to only lines containing an if block
			recodes <- recode.lines[ lines.with.if ]
			
			# break the recode lines up by semicolons, in case there's more than one per line
			recodes <- unlist( strsplit( recodes , ";" ) )
			
			# remove the word `IF `
			recodes <- gsub( "IF " , "" , recodes )
			
			# remove leading and trailing whitespace
			recodes <- str_trim( recodes )
			
			# remove empty strings
			recodes <- recodes[ recodes != '' ]
			
			# find which variables need to be replaced by extracting whatever's directly in front of the equals sign
			vtr <- str_trim( tolower( gsub( "(.*) THEN( ?)(.*)( ?)=(.*)" , "\\3" , recodes ) ) )
			
			# remove everything after the `THEN` block..
			ptm <- gsub( " THEN( ?)(.*)" , "" , recodes )
			
			# ..to create a vector of patterns to match
			ptm <- tolower( str_trim( ptm ) )
			
			# if the table has less than 100,000 records, read it into a data.frame as well
			# note: if you have lots of RAM, you might want to read it in regardless.
			# this loop assumes you have less than 4GB of RAM, so tables with more
			# than 100,000 records will not automatically get read in unless you comment
			# out this `if` block by adding `#` in front of this line and the accompanying `}`
			if ( dbGetQuery( db , paste( 'select count(*) from ' , tablename ) )[ 1 , 1 ] < 100000 ){
				
				# pull the data file into working memory
				x <- dbReadTable( db , tablename )
			
				# if there are any missing values to recode
				if ( length( mvr ) == 1 ){
				
					# loop through each variable to recode
					for ( k in seq_along( vtr ) ){
				
						# overwrite sas syntax with r syntax in the patterns to match commands.
						r.command <- gsub( "=" , "==" , ptm[ k ] )
						r.command <- gsub( " or " , "|" , r.command )
						r.command <- gsub( " and " , "&" , r.command )
						r.command <- gsub( " in \\(" , " %in% c\\(" , r.command )
						
						# wherever the pattern has been matched, overwrite the current variable with a missing
						x[ with( x , which( eval( parse( text = r.command ) ) ) ) , vtr[ k ] ] <- NA
						
						# if a column is *only* NAs then delete it
						if( all( is.na( x[ , vtr[ k ] ] ) ) ) x[ , vtr[ k ] ] <- NULL
						
						# clear up RAM
						gc()
						
					}
					
					# remove the current data table from the database
					dbRemoveTable( db , tablename )
					
					names( x ) <- tolower( names( x ) )
					
					# ..and overwrite it with the data.frame object
					# that you've just blessedly cleaned up
					dbWriteTable( db , tablename , x )

				}
				
				# save the r data.frame object to the local disk as an `.rda`
				save( x , file = gsub( "txt$" , "rda" , data.file ) )
			
				# remove the object from working memory
				rm( x )
				
				
			# if the current data table has more than 100,000 records..
			} else {
								
				# if there are any variables that need system missing-ing
				if( length( mvr ) == 1 ){
					
					# loop through each variable to recode
					for ( k in seq_along( vtr ) ){
					
						# update the current data table's variable-to-replace (vtr) with missing (NULL) whenever the pattern-to-match is matched.
						dbSendQuery( 
							db , 
							paste(
								"UPDATE" ,
								tablename ,
								"SET" ,
								vtr[ k ] ,
								" = NULL WHERE" ,
								ptm[ k ]
							)
						)
						
					}
					
				}
				
			}
			
		# otherwise, if there's no recoding to be done at all
		} else {
			
			# check whether the current table has less than 100000 records..
			if ( dbGetQuery( db , paste( 'select count(*) from ' , tablename ) )[ 1 , 1 ] < 100000 ){
			
				# pull the data file into working memory
				x <- dbReadTable( db , tablename )
			
				# save the r data.frame object to the local disk as an `.rda`
				save( x , file = gsub( "txt$" , "rda" , data.file ) )
			
				# remove the object from working memory
				rm( x )
				
			}
			
		}
		
		# clear up RAM	
		gc()
		
	}
	
	# at the end of each of these runs, the temporary directory
	# needs to be wiped out.  otherwise, all the big downloads
	# and unzips will eat up all the storage on a smaller hard disk
	file.remove( list.files( tempdir() , full.names = TRUE ) )
	
}

	
# disconnect from the current monetdb session
dbDisconnect( db , shutdown = TRUE )

# once complete, this script does not need to be run again.
# instead, use one of the national incident-based reporting system
# analysis scripts which utilize this central monetdb file
