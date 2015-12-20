# analyze survey data for free (http://asdfree.com) with the r language
# european social survey
# integrated and country-specific files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# your.email <- "email@address.com"
# library(downloader)
# setwd( "C:/My Directory/ESS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/European%20Social%20Survey/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# daniel oberski
# daniel.oberski@gmail.com

# anthony joseph damico
# ajdamico@gmail.com


############################################################################
# download every file from every year of the European Social Survey with R #
# then save every file as an R data frame (.rda) for fast future analyses  #
############################################################################


# # # # # # # # # # # # # #
# important user warning! #
# # # # # # # # # # # # # #

# you *must* visit this norwegian social science data services
# website and register, then click the link in the e-mail
# to activate your account before running this massive download automation program

# this is to protect both yourself and the respondents of the study.  register here:
# http://www.europeansocialsurvey.org/user/new

# once you have registered, place your e-mail address in the script below.
# this script will not run until a valid e-mail address is included in the line below.
# also, you'll have to uncomment them by removing the `#` in order for R to work ;)

# your.email <- "email@address.com"

# this massive ftp download automation script will not work without the above lines filled in.
# if the your.email line above is not filled in with the details you provided at registration, 
# the script is going to break.  to repeat.  register to access ess data.


# # # # # # # # # # # # # # # # # 
# end of important user warning #
# # # # # # # # # # # # # # # # #


# set your working directory.
# all ESS data files will be stored here
# after downloading.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/ESS/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( c( "XML" , "memisc" , "httr" ) )

# no need to edit anything below this line #


# # # # # # # # #
# program start #
# # # # # # # # #


library(httr)		# load httr package (downloads files from the web, with SSL and cookies)
library(XML)		# load XML (parses through html code to extract links)
library(memisc)		# load memisc package (loads spss portable table import functions)
library(foreign) 	# load foreign package (converts data files into R)
library(tools)		# load the `file_ext` function within the file utilities section


# designate a temporary file and temporary directory
tf <- tempfile() ; td <- tempdir()

# store your e-mail address in a list to be passed to the website
values <- list( u = your.email )

# authenticate on the ess website
POST( "http://www.europeansocialsurvey.org/user/login" , body = values )

GET( "http://www.europeansocialsurvey.org/user/login" , query = values )


# figure out all integrated file locations
ifl <- GET( "http://www.europeansocialsurvey.org/data/round-index.html" )

# extract all integrated filepaths
ifl.block <- htmlParse( ifl , asText = TRUE )

# find all links, with parsing explanation thanks to
# http://stackoverflow.com/questions/19097089/how-to-extract-childrenhtml-contents-from-an-xmldocumentcontent-object
z <- xpathSApply( ifl.block , "//a", function(u) xmlAttrs(u)["href"])

# isolate all links to unduplicated file downloads
downloads <- unique( z[ grep( "download.html?file=" , z , fixed = TRUE ) ] )

# download every other year, starting with 2002.
all.possible.years <- seq( 2002 , 3000 , 2 )

# loop through each of the integrated files..
for ( curDownload in downloads ){

	# download the integrated file's whole page
	download.page <- GET( paste0( "http://www.europeansocialsurvey.org" , curDownload ) )

	# again, convert the page to an R-readable format..
	download.block <- htmlParse( download.page , asText = TRUE )

	# ..then extract all of the links.
	z <- xpathSApply( download.block , "//a", function(u) xmlAttrs(u)["href"])

	# extract the only link with the text `spss` in it.
	spss.file <- z[ grep( "spss" , z ) ]

	# print the current progress to the screen
	cat( paste( "importing" , spss.file , '...\n' ) )
	
	# download the current file
	current.file <- GET( paste0( "http://www.europeansocialsurvey.org" , spss.file ) )

	# the current year is the last four characters of the file's url
	current.year <- substr( spss.file , nchar( spss.file ) - 3 , nchar( spss.file ) )

	# write the current file to the temporary file on your local disk
	writeBin( content( current.file , "raw" ) , tf )

	# unzip the temporary file to the temporary directory
	spss.files <- unzip( tf , exdir = td )

	# delete the temporary file
	file.remove( tf )
	
	# look for a dot.sav file within the extracted files
	sav.file <- spss.files[ grep( '.sav' , spss.files , fixed = TRUE ) ]

	# read that dot.sav file as a data.frame object
	x <- read.spss( sav.file , to.data.frame = TRUE , use.value.labels = FALSE )

	# create a year-specific folder
	dir.create( paste0( "./" , current.year ) )
	
	# create a year-specific documentation subfolder
	dir.create( paste0( "./" , current.year , '/docs' ) )
	
	# designate the filepath where the integrated `x` object should be saved
	fn <- paste0( "./" , current.year , '/integrated.rda' )

	# convert all column names to lowercase
	names( x ) <- tolower( names( x ) )
	
	# save the R data.frame object to the filepath determined above
	save( x , file = fn )

	# remove the object from working memory
	rm( x )

	# clear up RAM
	gc()

	# figure out which round of data currently being worked on..
	current.round <- which( current.year == all.possible.years )
	
	# download the current round's entire available data page
	download.page <- GET( paste0( "http://www.europeansocialsurvey.org/data/download.html?r=" , current.round ) )
	
	# again, convert the page to an R-readable format..
	download.block <- htmlParse( download.page , asText = TRUE )

	# ..then extract all of the links.
	z <- xpathSApply( download.block , "//a", function(u) xmlAttrs(u)["href"])

	# remove all e-mail addresses
	z <- z[ !grepl( 'mailto' , z ) ]
	
	# remove all files ending in `.html`
	z <- z[ file_ext( z ) != 'html' ]

	# isolate the filepaths of all pdf files
	pdfs <- z[ file_ext( z ) == 'pdf' ]
	
	# isolate the filepaths of all current round file downloads
	crd <- unique( z[ grep( paste0( "/download.html?file=ESS" , current.round ) , z , fixed = TRUE ) ] )
	
	# download and save all pdfs
	for ( cur.pdf in pdfs ){
		
		# load the pdf file into working memory
		current.pdf <- GET( paste0( "http://www.europeansocialsurvey.org" , cur.pdf ) )
		
		# determine where to save the pdf on the local disk
		fn <- paste0( "./" , current.year , '/docs/' , basename( cur.pdf ) )
			
		# save the pdf to the local disk
		writeBin( content( current.pdf , "raw" ) , fn )
		
	}
	
	
	# download and save all data files
	for ( cur.crd in crd ){
		
		# print current progress to the screen
		cat( paste( "importing" , cur.crd , '...\n' ) )
		
		# extract the hosted file name
		hfn <- gsub( "(.*)(file=)(.*?)(&)(.*)" , "\\3" , cur.crd )
		
		
		# figure out whether it's a country-specific download #
		
		# country-specific downloads
		if( grepl( 'c=' , cur.crd ) ){

			# if so, extract the country name
			cn <- gsub( "(.*)(c=)([A-Z][A-Z])(.*)" , "\\3" , cur.crd )
			
			# and determine.. 
			cd <- paste0( './' , current.year , '/' , cn )
			
			# ..and create the country directory
			dir.create( cd , showWarnings = FALSE )
		
		} else {
		
			# otherwise there's no country-specific directory here
			cd <- paste0( './' , current.year , '/' )
		
			# leave the country name blank
			cn <- ''
		
		}
		
		# build the entire download file path
		dfp <-
			paste0( 
				"http://www.europeansocialsurvey.org/file/download?f=" ,
				hfn ,
				'.spss.zip&c=' ,
				cn ,
				"&y=" ,
				current.year
			)
		
		# download the current file directly into memory
		current.file <- GET( dfp )
		
		# save the downloaded file to the temporary file location
		writeBin( content( current.file , "raw" ) , tf )

		# unzip the temporary file into the temporary directory,
		# and store all local filepaths into the object `spss.files`
		spss.files <- unzip( tf , exdir = td )

		# determine the save location
		fn <- paste0( cd , '/' , gsub( cn , '' , hfn ) , '.rda' )

		# first, look for the .sav file
		if ( any( grepl( 'sav' , spss.files ) ) ){
		
			# read that dot.sav file as a data.frame object
			x <- read.spss( spss.files[ grep( 'sav' , spss.files ) ] , to.data.frame = TRUE , use.value.labels = FALSE )
			
		} else {
		
			# otherwise, read in from the `.por` file
			attempt.one <- 
				try( 
					# read that dot.por file as a data.frame object
					x <- read.spss( spss.files[ grep( 'por' , spss.files ) ] , to.data.frame = TRUE , use.value.labels = FALSE ) ,
					silent = TRUE
				)
				
			# if the prior attempt failed..
			if ( class( attempt.one ) == 'try-error' ){
				# otherwise, convert all factor variables to character
				attempt.two <- 
					try( 
						# use the `memisc` package's `spss.portable.file` framework instead
						x <-
							data.frame(
								as.data.set(
									spss.portable.file( 
										spss.files[ grep( 'por' , spss.files ) ] 
									)
								)
							) ,
						silent = TRUE
					)
					
			} else attempt.two <- NULL
			
			
			# if the prior attempt failed..
			if ( class( attempt.two ) == 'try-error' ){
			
				# use the `memisc` package's `spss.portable.file` framework instead
				b <-
					as.data.set(
						spss.portable.file( 
							spss.files[ grep( 'por' , spss.files ) ] 
						)
					)
				
				# convert all factor variables to character variables
				b <- sapply( b , function( z ) { if( class( z ) == 'factor' ) z <- as.character( z ) ; z } )
				
				# now run the conversion that caused the issue.
				x <- data.frame( b )
			
			}
					
		}
		
		# convert all column names to lowercase
		names( x ) <- tolower( names( x ) )
		
		# save the R data.frame object to the appropriate save file location
		save( x , file = fn )

		# remove the big objects from working memory
		rm( x , current.file )

		# clear up RAM
		gc()

		# remove the temporary file
		file.remove( tf )
			
	}
	
}

# remove all contents of the temporary directory
unlink( td , recursive = TRUE )

