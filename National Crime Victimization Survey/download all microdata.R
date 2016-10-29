# analyze survey data for free (http://asdfree.com) with the r language
# national crime victimization survey
# all available years
# all available filetypes

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NCVS/" )
# your.username <- 'your@login.com'
# your.password <- 'yourpassword'
# options( encoding = "windows-1252" )				# # only macintosh and *nix users need this line
# rm( studies.to.download ) 						# or pick a few # studies.to.download <- c( "2003 Record-Type Files" , "2012 Identity Theft Supplement" , "1995 School Crime Supplement" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Crime%20Victimization%20Survey/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


####################################################################################
# download every file from every year of the National Crime Victimization Survey   #
# then save every file as an R data frame (.rda) so future analyses can be rapid.  #
####################################################################################


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
# the script is going to break.  to repeat.  register to access ncvs data.


# # # # # # # # # # # # # # # # # 
# end of important user warning #
# # # # # # # # # # # # # # # # #


# set your working directory.
# all NCVS data files will be stored here
# after downloading.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NCVS/" )
# ..in order to set your current working directory


# # # are you on a non-windows system? # # #
if ( .Platform$OS.type != 'windows' ) print( 'non-windows users: read this block' )
# a few SAS importation scripts have a non-standard format
# before running this whole download program,
# you might need to run this line..
# options( encoding="windows-1252" )
# ..to turn on windows-style encoding.
# # # end of non-windows system edits.


# remove the # in order to run this install.packages line only once
# install.packages( c( "MonetDBLite" , "survey" , "SAScii" , "descr" , "downloader" , "digest" , "stringr" , "R.utils" , "RCurl" ) )



library(SAScii) 		# load the SAScii package (imports ascii data with a SAS script)
library(RCurl)			# load RCurl package (downloads https files)
library(stringr)		# load stringr package (manipulates character strings easily)
library(downloader)		# downloads and then runs the source() function on scripts from github
library(MonetDBLite)
library(DBI)			# load the DBI package (implements the R-database coding)
library(descr)			# load the descr package (converts fixed-width files to delimited files)
library(R.utils)		# load the R.utils package (counts the number of lines in a file quickly)
library(foreign)		# load foreign package (converts data files into R)


# follow the authentication technique described on this stackoverflow post
# http://stackoverflow.com/questions/15853204/how-to-login-and-then-download-a-file-from-aspx-web-pages-with-r


# create a temporary file
tf <- tempfile()

# this script's download files should be incorporated in download_cached's hash list
options( "download_cached.hashwarn" = TRUE )
# warn the user if the hash does not yet exist

# load the download_cached and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url(
	"https://raw.githubusercontent.com/ajdamico/asdfree/master/Download%20Cache/download%20cache.R" ,
	prompt = FALSE ,
	echo = FALSE
)

# load the read.SAScii.monetdb function (a variant of read.SAScii that creates a database directly)
source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/MonetDB/read.SAScii.monetdb.R" , prompt = FALSE )

# download the contents of the webpage hosting all ncvs data files
all.ncvs.studies <- getURL( "http://www.icpsr.umich.edu/icpsrweb/NACJD/series/95/studies?archive=NACJD&q=&paging.rows=10000&sortBy=7" )

# find all available study numbers
study.listing <- strsplit( all.ncvs.studies , '<a href="studies/' , fixed = TRUE )[[1]][-1]

# confirm that each study.listing has a <strong> tag
stopifnot( all( grepl( "strong" , study.listing ) ) )

# extract all study numbers
study.numbers <- gsub( "^([0-9]*)\\?archive=NACJD(.*)" , "\\1" , study.listing )

# extract all study names
study.names <- gsub( "(.*)strong>(.*)</strong></a(.*)" , "\\2" , study.listing )

# remove unnecessary words from the study names
study.names <- gsub( "the National Crime Victimization Survey's" , "" , study.names )

# remove everything except alphanumeric characters
# and spaces and dashes, so that folders can be named
study.names <- gsub( "[^-a-zA-Z0-9 ]" , "" , study.names )

# wherever study names have "(some text) year-year" put the year-year out in front
study.names <- gsub( "(.*) ([0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9])" , "\\2 \\1" , study.names )

# wherever study names have a year in the middle of the string, put the year out in front
study.names <- gsub( "(.*) ([0-9][0-9][0-9][0-9])(.*)" , "\\2 \\1\\3" , study.names )

# remove unnecessary words from the study names
study.names <- gsub( "United States|National Crime Victimization Survey" , "" , study.names )

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
# studies.to.download <- c( "2003 Record-Type Files" , "2012 Identity Theft Supplement" , "1995 School Crime Supplement" )
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



# this 2009 protective behaviors supplement does not have data, only programming source code
numbers.to.download <- numbers.to.download[ numbers.to.download != which( study.names ==  "2009 Protective Behaviors of Student Victims of Bullying A Rare Events Analysis of the School Crime Supplement to the" ) ]


# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )


# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite::MonetDBLite() , dbfolder )


# loop through all study numbers deemed download-worthy
for ( i in numbers.to.download ){

	# name a subdirectory within the current working directory..
	this.dir <- paste0( "./" , study.names[ i ] )

	# ..and create it.
	dir.create( study.names[ i ] )

	# determine the homepage of the current study to-be-downloaded
	hp <- 
		paste0( 
			"http://www.icpsr.umich.edu/icpsrweb/NACJD/series/95/studies/" , 
			study.numbers[ i ] ,
			"?archive=NACJD&q=&paging.rows=10000&sortBy=7" 
		)

	# download that homepage
	study.homepage <- getURL( hp )

	# determine which files are documentation
	m <- gregexpr( "file\\?.*?NACJD" , study.homepage )
	
	# isolate all documentation files
	all.docs <- regmatches( study.homepage , m )[[1]]
	
	# loop through each of the documentation files
	for ( j in all.docs ){
	
		# write out the name of the documentation filepath
		dp <- paste0( "http://www.icpsr.umich.edu/cgi-bin/" , j )
		
		# download the current document
		this.doc <- download_cached( dp , destfile = NULL , FUN = getBinaryURL )
	
		# initiate a header
		h <- basicHeaderGatherer()
		
		# pull the filename off of the server
		try( doc <- getURI( dp , headerfunction = h$update ) , silent = TRUE )
		
		# extract the name from that `h` object
		lfn <- gsub( '(.*)\\"(.*)\\"' , "\\2" , h$value()[["Content-Type"]] )
		
		# save the actual downloaded-file to the filepath specified on the local disk
		writeBin( this.doc , paste0( this.dir , "/" , lfn ) )
	
	}
	
	# determine which files on the study homepage are sas importation files
	m <- 
		gregexpr( 
			paste0(
				"terms2\\?study=" ,
				study.numbers[ i ] ,
				"&ds=[0-9]&bundle=ascsas&path=NACJD"
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
			
		# this script only works on study ids 1 thru 9, so if you go into double-digits, crash.
		if ( gsub( "(.*)ds=([0-9])(.*)" , "\\2" , j ) == 9 ) stop( "a study contains at least nine files - program needs to be modified to deal with ten or more" )

		# post your username and password to the umich server
		login.page <- 
			postForm(
				"https://www.icpsr.umich.edu/rpxlogin" , 
				email = your.username ,
				password = your.password ,
				path = "NACJD" ,
				request_uri = dp ,
				app_seq = "" ,
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
				ds = gsub( "(.*)ds=([0-9])(.*)" , "\\2" , j ) , 
				bundle = "ascsas" , 
				dups = "yes" ,
				style = "POST" ,
				curl = curl
			)
	
		# download the current sas file onto the local disk
		this.sas_ri <- download_cached( dp , destfile = NULL , FUN = getBinaryURL , curl = curl )

		# initiate a heading object
		h <- basicHeaderGatherer()

		# pull the filename off of the server
		try( doc <- getURI( dp , headerfunction = h$update , curl = curl ) , silent = TRUE )
		
		# extract the name from that `h` object
		lfn <- gsub( '(.*)\\"(.*)\\"' , "\\2" , h$value()[["Content-Type"]] )
		
		# save the actual downloaded-file to the filepath specified on the local disk
		writeBin( this.sas_ri , paste0( this.dir , "/" , lfn ) )
	
		# remove the downloaded file from working memory
		rm( this.sas_ri , curl , h )
		
		# clear up RAM
		gc()
	
		# unzip the downloaded file within the local drive
		z <- unzip( paste0( this.dir , "/" , lfn ) , exdir = this.dir )

		# the gag factor adjustment does not have a data file.
		# the unbounded files are just complicated versions of the record-type files.
		# the 1995-1999 longitudinal file is a pita to import and won't see much usage.
		# so skip them all.  if you'd like to improve this script, go right ahead.
		if ( !grepl( "longitudinal|gag factors|unbounded" , tolower( this.dir ) ) ){
			
			# determine the filenames that end with `sas`
			sas.import <- z[ grep( "sas$" , tolower( z ) ) ]
		
			# determine the filenames containing the word `data`
			data.file <- z[ grep( "data" , tolower( basename( z ) ) ) ]
		
			# if the current data.file is also gzipped..
			if ( grepl( "gz$" , tolower( data.file ) ) ){
			
				# gunzip it and overwrite itself in the current directory
				data.file <- gunzip( data.file )
				
			}
			
			# let the user/viewer know whatcha doin'
			print( paste( "currently importing" , data.file ) )
			
			# in most cases, the sas importation script should start right at the beginning..
			beginline <- 1
			
			# ..but hardcode the beginline for a few scripts
			if ( j == "terms2?study=4429&ds=1&bundle=ascsas&path=NACJD" & study.names[ i ] == "2005 School Crime Supplement" ) beginline <- 794
			
			# skip one goofy line in the 2005 ppcs #
			if( study.names[ i ] == "2005 Police-Public Contact Survey" ) tbe <- TRUE else tbe <- FALSE
			# end of hardcoding
			
			tablename <- gsub( "-" , "_" , tolower( basename( data.file ) ) )
			tablename <- gsub( "(.*)\\.(.*)" , "\\1" , tablename )
			tablename <- gsub( "_data" , "" , tablename )
			tablename <- paste0( 'x' , tablename )
			
			# read the data file into an r sqlite database
			read.SAScii.monetdb(
				fn = data.file ,
				sas_ri = sas.import ,
				tl = TRUE ,	# convert all column names to lowercase?
				tablename = tablename ,
				beginline = beginline ,
				skip.decimal.division = TRUE ,
				conn = db ,
				try_best_effort = tbe
			)
			
			
			gc()
			
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
				
				# confirm all of those lines have a sas missing value (a dot) somewhere in there.
				lines.with.dots <- grep( "\\." , recode.lines )

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
				pre_vtr <- vtr <- str_trim( tolower( gsub( "(.*) THEN( ?)(.*)( ?)=(.*)" , "\\3" , recodes ) ) )

				# reserved words have been recoded within `read.SAScii.monetdb` and need to be recoded here as well
				for ( j in vtr[ vtr %in% tolower( MonetDBLite:::reserved_monetdb_keywords ) ] ) vtr[ vtr == j ] <- paste0( j , "_" )

				# remove everything after the `THEN` block..
				ptm <- gsub( " THEN( ?)(.*)" , "" , recodes )
				
				# ..to create a vector of patterns to match
				ptm <- tolower( str_trim( ptm ) )
				
				# reserved words have been recoded within `read.SAScii.monetdb` and need to be recoded here as well
				for ( j in intersect( pre_vtr , tolower( MonetDBLite:::reserved_monetdb_keywords ) ) ) ptm <- gsub( j , paste0( j , "_" ) , ptm )
				
				# hardcode weird sas import file
				if( study.names[ i ] == "1995 School Crime Supplement" & ptm[ 1 ] == "/* v9=9" ) ptm[ 1 ] <- "v9=9"
				# end of hardcoding

			}
		
			# if the table has less than 100,000 records, read it into a data.frame as well
			# note: if you have lots of RAM, you might want to read it in regardless.
			# this loop assumes you have less than 4GB of RAM, so tables with more
			# than 100,000 records will not automatically get read in unless you comment
			# out this `if` block by adding `#` in front of this line and the accompanying `}`
			if ( dbGetQuery( db , paste0( 'select count(*) from ' , tablename ) )[ 1 , 1 ] < 100000 ){
				
				# pull the data file into working memory
				x <- dbReadTable( db , tablename )
			
				print( paste( "revising" , tablename ) )
				
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
					
					# ..and overwrite it with the data.frame object
					# that you've just blessedly cleaned up
					dbWriteTable( db , tablename , x )

				}
				
				# save the r data.frame object to the local disk as an `.rda`
				save( x , file = gsub( "\\-Data\\.txt$" , "rda" , data.file ) )
			
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
			
		}
		
		# clear up RAM	
		gc()
			
	}
	
}


# take a look at all the new data tables that have been added to your RAM-free MonetDBLite database
dbListTables( db )

# disconnect from the current database
dbDisconnect( db , shutdown = TRUE )
