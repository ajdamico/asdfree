# analyze survey data for free (http://asdfree.com) with the r language
# world values survey
# waves one through six

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# do.you.agree <- FALSE
# library(downloader)
# setwd( "C:/My Directory/WVS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/World%20Values%20Survey/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


###########################################################################
# download every file from every year of the World Values Survey with R   #
# then save every file as an R data frame (.rda) for fast future analysis #
###########################################################################


# # # # # # # # # # # # # #
# important user warning! #
# # # # # # # # # # # # # #

# you *must* visit this world values survey official website and download
# at least microdata one file "manually" in order to review and agree to
# the stated terms of service.  if you click one of the "statistical data files"
# http://www.worldvaluessurvey.org/WVSDocumentationWV1.jsp
# you can review and consent to the terms of service.

# once you have reviewed those terms, you can uncomment the lines below and
# the download automation script will fetch and import every single file.
# note that you'll have to change `do.you.agree` to TRUE as well as
# filling in the other information within the "quotes like this"

# do.you.agree <- FALSE

# this download automation script will not work without the above lines filled in.
# if the lines above are not filled in, the script is going to break.  enjoy!


# # # # # # # # # # # # # # # # # 
# end of important user warning #
# # # # # # # # # # # # # # # # #


# set your working directory.
# all WVS data files will be stored here
# after downloading.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/WVS/" )
# ..in order to set your current working directory


# specify which waves to download
waves.to.download <- c( -1 , 1:6 )
# note that the `-1` will trigger the
# downloading of the longitudinal file


# remove the # in order to run this install.packages line only once
# install.packages( c( "httr" , "XML" , "curlconverter" ) )

# no need to edit anything below this line #


# # # # # # # # #
# program start #
# # # # # # # # #


library(httr)			# load httr package (downloads files from the web, with SSL and cookies)
library(curlconverter)	# load curlconverter (simplifies downloads with cookies)
library(XML)			# load XML (parses through html code to extract links)
library(foreign) 		# load foreign package (converts data files into R)
library(tools)			# allows rapid extraction of filename extensions


# initiate a temporary file and a temporary directory
tf <- tempfile() ; td <- tempdir()


# only if the user explicitly agrees to the terms..
if( !do.you.agree ) stop( "please read the instructions" )

	
# http://stackoverflow.com/questions/40498277/programmatically-scraping-a-response-header-within-r
# http://stackoverflow.com/questions/38156180/how-to-download-a-file-behind-a-semi-broken-javascript-asp-function-with-r

# request a valid cookie from the server and then don't touch it
response <- GET(
	url = "http://www.worldvaluessurvey.org/AJDocumentation.jsp?CndWAVE=-1", 
	add_headers(
		`Accept` = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8", 
		`Accept-Encoding` = "gzip, deflate",
		`Accept-Language` = "en-US,en;q=0.8", 
		`Cache-Control` = "max-age=0",
		`Connection` = "keep-alive", 
		`Host` = "www.worldvaluessurvey.org", 
		`User-Agent` = "Mozilla/5.0 (Windows NT 10.0; WOW64; rv:50.0) Gecko/20100101 Firefox/50.0",
		`Content-type` = "application/x-www-form-urlencoded",
		`Referer` = "http://www.worldvaluessurvey.org/AJDownloadLicense.jsp", 
		`Upgrade-Insecure-Requests` = "1"))

set_cookie <- headers(response)$`set-cookie`
cookies <- strsplit(set_cookie, ';')
my_cookie <- cookies[[1]][1]

# determine the full url of a WVS file based on the file id
getFileById <- 
	function(fileId,cookie=my_cookie) {

		response <- GET(
			url = "http://www.worldvaluessurvey.org/jdsStatJD.jsp?ID=2.72.48.149%09IT%09undefined%0941.8902%2C12.4923%09Lazio%09Roma%09Orange%20SA%20Telecommunications%20Corporation&url=http%3A%2F%2Fwww.worldvaluessurvey.org%2FAJDocumentation.jsp&referer=null&cms=Documentation", 
			add_headers(
				`Accept` = "*/*", 
				`Accept-Encoding` = "gzip, deflate",
				`Accept-Language` = "en-US,en;q=0.8", 
				`Cache-Control` = "max-age=0",
				`Connection` = "keep-alive", 
				`X-Requested-With` = "XMLHttpRequest",
				`Host` = "www.worldvaluessurvey.org", 
				`User-Agent` = "Mozilla/5.0 (Windows NT 10.0; WOW64; rv:50.0) Gecko/20100101 Firefox/50.0",
				`Content-type` = "application/x-www-form-urlencoded",
				`Referer` = "http://www.worldvaluessurvey.org/AJDocumentation.jsp?CndWAVE=-1",
				`Cookie` = cookie))

		post_data <- list( 
			ulthost = "WVS",
			CMSID = "",
			CndWAVE = "-1",
			SAID = "-1",
			DOID = fileId,
			AJArchive = "WVS Data Archive",
			EdFunction = "",
			DOP = "",
			PUB = "")  

		response <- POST(
			url = "http://www.worldvaluessurvey.org/AJDownload.jsp", 
			config(followlocation = FALSE),
			add_headers(
				`Accept` = "*/*", 
				`Accept-Encoding` = "gzip, deflate",
				`Accept-Language` = "en-US,en;q=0.8", 
				`Cache-Control` = "max-age=0",
				`Connection` = "keep-alive",
				`Host` = "www.worldvaluessurvey.org",
				`User-Agent` = "Mozilla/5.0 (Windows NT 10.0; WOW64; rv:50.0) Gecko/20100101 Firefox/50.0",
				`Content-type` = "application/x-www-form-urlencoded",
				`Referer` = "http://www.worldvaluessurvey.org/AJDocumentation.jsp?CndWAVE=-1",
				`Cookie` = cookie),
			body = post_data,
			encode = "form")

		location <- headers(response)$location
		location
	}






# loop through each wave requested by the user
for ( this.wave in waves.to.download ){

	# specify..
	this.dir <- ifelse( this.wave == -1 , "./longitudinal" , paste( "./wave" , this.wave ) )

	# ..and then create a directory to save the current wave's microdata
	dir.create( this.dir , showWarnings = FALSE )
	
	if( this.wave == -1 ) dl_page <- "http://www.worldvaluessurvey.org/AJDocumentationSmpl.jsp?CndWAVE=-1&SAID=-1&INID=" else dl_page <- paste0( "http://www.worldvaluessurvey.org/AJDocumentationSmpl.jsp?CndWAVE=" , this.wave )
	
	# determine the integrated (all-country) files available for download
	agg <- readLines( dl_page )
	
	# determine which of those links are on a line with the text 'Download'
	dlid <- gsub( "(.*)DocDownload(License)?\\('(.*)'\\)(.*)" , "\\3" , grep( "DocDownload(License)?\\('" , agg , value = TRUE ) )
	
	# extract the identification number of each file
	all.ids <- gsub( "(.*)\\('([0-9]*)'\\)" , "\\2" , dlid )

	# find country-specific files as well
	if( this.wave > -1 ){

		countries <- readLines( paste0( "http://www.worldvaluessurvey.org/AJDocumentation.jsp?CndWAVE=" , this.wave , "&COUNTRY=" ) )

		# determine which of those table identifiers lead to actual files
		table_ids <- gsub( '(.*)tr id=\\"(.*)\\" >(.*)' , "\\2" , grep( "tr id" , countries , value = TRUE ) )
		
		# remove zeroes
		table_ids <- table_ids[ table_ids != "0" ]
		
		for( this_country in table_ids ){

			# read the country-specific download page
			dl_page <- readLines( paste0( "http://www.worldvaluessurvey.org/AJDocumentationSmpl.jsp?CndWAVE=" , this.wave , "&SAID=" , this_country ) )
		
			# extract the identification number of each file
			dlid <- gsub( "(.*)DocDownload(License)?\\('(.*)'\\)(.*)" , "\\3" , grep( "DocDownload(License)?\\('" , dl_page , value = TRUE ) )
		
			# add the identification number to the list of files to be downloaded
			all.ids <- c( all.ids , dlid )
		
		}
		
	}
	
	# loop through each of those identification numbers..
	for ( this.id in all.ids ){

		# for the wave-wide files, store everything in the main wave folder
		this.subdir <- paste0( this.dir , "/" )
		
		fn <- getFileById(this.id)

		browserGET <- "curl 'http://www.worldvaluessurvey.org/WVSDocumentationWV4.jsp' -H 'Host: www.worldvaluessurvey.org' -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:49.0) Gecko/20100101 Firefox/49.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'Connection: keep-alive' -H 'Upgrade-Insecure-Requests: 1'"
		getDATA <- (straighten(browserGET) %>% make_req)[[1]]()


		getPDF <- paste0( "curl '" , fn , "' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: en-US,en;q=0.5' -H 'Connection: keep-alive' -H 'Cookie: JSESSIONID=59558DE631D107B61F528C952FC6E21F' -H 'Host: www.worldvaluessurvey.org' -H 'Referer: http://www.worldvaluessurvey.org/AJDocumentationSmpl.jsp' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; WOW64; rv:49.0) Gecko/20100101 Firefox/49.0'" )
		appIP <- straighten(getPDF)
		# replace cookie
		appIP[[1]]$cookies$JSESSIONID <- getDATA$cookies$value
		appReq <- make_req(appIP)
		response <- appReq[[1]]()
		writeBin(response$content, tf )

		# extract the filename from the website's response header
		this_fn <- basename( response$url )

		# correct filenames for WVS longitudinal documents as of 2015-05-09
		if(this.wave == -1 & this_fn == "")
			this_fn = "WVS_EVS_Integrated_Dictionary_Codebook v_2014_09_22.xls"

		if(this.wave == -1 & this_fn == "04-25.xls")
			this_fn = "WVS_Values Surveys Integrated Dictionary_TimeSeries_v_2014-04-25.xls"
		
		# delete the object `x` from RAM
		rm( x )
		
		# copy the temporary file over to the current subdirectory
		file.copy( tf , paste0( this.subdir , "/" , this_fn ) )

		# if the file is a zipped file..
		if( file_ext( this_fn ) == 'zip' ){

			# unzip it into the local temporary directory
			z <- unzip( tf , exdir = td )
			
			# confirm that the unzipped file length is one or it is not an rda/dta/sav file
			stopifnot ( length( z ) == 1 | !( grepl( 'stata_dta|spss|rdata' , this_fn ) ) ) 

			# if it's a stata file, import with `read.dta`
			if( grepl( 'stata_dta' , tolower( this_fn ) ) ) try( x <- read.dta( z , convert.factors = FALSE ) , silent = TRUE )
			
			# if it's an spss file, import with `read.spss`
			if( grepl( 'spss' , tolower( this_fn ) ) ) try( x <- read.spss( z , to.data.frame = TRUE , use.value.labels = FALSE ) , silent = TRUE )
			
			# if it's an r data file, hey the work has been done for you!
			if( grepl( 'rdata' , tolower( this_fn ) ) ){
			
				# store all loaded object names into `dfn`
				dfn <- load( z )
				
				# if multiple objects were loaded..  check their `class`
				dfc <- sapply( dfn , function( z ) class( get( z ) ) )
				
				# confirm only one `data.frame` object exists
				stopifnot( sum( dfc == 'data.frame' ) == 1 )
				
				# store that object into `x`
				x <- get( dfn[ dfc == 'data.frame' ] )
				
				# remove all newly-loaded objects from memory
				rm( list = dfn )
				
			}

			# if a data.frame object has been imported..
			if( exists( 'x' ) ){
				
				# convert all column names to lowercase
				names( x ) <- tolower( names( x ) )
				
				# determine the filepath to store this data.frame object on the local disk
				# if it was "thisfile.sav" then make it "yourdirectory/subdirectory/thisfile.rda"
				rfn <- paste0( this.subdir , "/" , gsub( file_ext( this_fn ) , "rda" , this_fn ) )
				
				# store the data.frame object on the local disk
				save( x , file = rfn )
				
				# remove the data.frame from working memory
				rm( x )

			}
				
		}
		
		# clear up RAM
		gc()
	}

}

# remove all files stored in the temporary directory
unlink( td , recursive = TRUE )

