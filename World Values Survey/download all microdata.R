# analyze survey data for free (http://asdfree.com) with the r language
# world values survey
# waves one through six

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# your.name <- "first last"
# your.email <- "email@address.com"
# your.organization <- "organization name"
# your.project <- "project name"
# your.purpose <- "description of project"
# do.you.agree <- FALSE
# library(downloader)
# setwd( "C:/My Directory/WVS/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/World%20Values%20Survey/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
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

# your.name <- "first last"
# your.email <- "email@address.com"
# your.organization <- "organization name"
# your.project <- "project name"
# your.purpose <- "description of project"
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
# install.packages( c( "httr" , "XML" ) )

# no need to edit anything below this line #


# # # # # # # # #
# program start #
# # # # # # # # #


library(httr)		# load httr package (downloads files from the web, with SSL and cookies)
library(XML)		# load XML (parses through html code to extract links)
library(foreign) 	# load foreign package (converts data files into R)
library(tools)		# allows rapid extraction of filename extensions


# initiate a temporary file and a temporary directory
tf <- tempfile() ; td <- tempdir()


# initiate a list object containing all 
# parameters necessary to automate the
# login to the worldvaluessurvey.org system
values <-
	list(
		ulthost = "WVS" ,
		CMSID = "" ,
		INID  = "" ,
		LITITLE = "" ,
		LINOMBRE = your.name ,
		LIEMPRESA = your.organization ,
		LIEMAIL = your.email ,
		LIPROJECT = your.project ,
		LIUSE = as.numeric( do.you.agree ) ,
		LIPURPOSE = your.purpose ,
		LIAGREE = as.numeric( do.you.agree ) ,
		AJArchive = "WVS Data Archive" ,
		EdFunction = "" ,
		DOP = "" ,
		PUB = ""
	)


# loop through each wave requested by the user
for ( this.wave in waves.to.download ){

	# specify..
	this.dir <- ifelse( this.wave == -1 , "./longitudinal" , paste( "./wave" , this.wave ) )

	# ..and then create a directory to save the current wave's microdata
	dir.create( this.dir , showWarnings = FALSE )
	
	# append a few bits of information required by the website, including the wave number
	values$SAID <- ""
	values$DOID <- ""
	values$CndWAVE <- this.wave

	# determine the integrated (all-country) files available for download
	agg <- GET( "http://www.worldvaluessurvey.org/AJDocumentationSmpl.jsp" , query = values )

	# extract the available links from the page above
	all.links <- unlist( xpathSApply( content( agg ) , "//*/a" , xmlAttrs ) )
	
	# determine which of those links are on a line with the text 'Download'
	dlid <- all.links[ grep( "Download" , all.links ) ]

	# extract the identification number of each file
	all.ids <- gsub( "(.*)\\('([0-9]*)'\\)" , "\\2" , dlid )

	# loop through each of those identification numbers..
	for ( this.id in all.ids ){

		# for the wave-wide files, store everything in the main wave folder
		this.subdir <- paste0( this.dir , "/" )
	
		# add the current file id as the "download id" parameter for
		# the `values` object that gets sent to the website
		values$DOID <- this.id
		values$SAID <- ""

		# pass those new query requests to the server
		POST( "http://www.worldvaluessurvey.org/AJDownloadLicense.jsp" , body = values )

		# initiate the download
		x <- GET( "http://www.worldvaluessurvey.org/AJDownload.jsp" , query = values )

		# store the file contents to the temporary file on the local disk
		writeBin( content( x , "raw" ) , tf )

		# extract the filename from the website's response header
		fn <- gsub( "attachment; filename=\"|\"" , "" , x$headers$`content-disposition` )
		
		# delete the object `x` from RAM
		rm( x )
		
		# copy the temporary file over to the current subdirectory
		file.copy( tf , paste0( this.subdir , "/" , fn ) )

		# if the file is a zipped file..
		if( file_ext( fn ) == 'zip' ){

			# unzip it into the local temporary directory
			z <- unzip( tf , exdir = td )
			
			# confirm that the unzipped file length is one or it is not an rda/dta/sav file
			stopifnot ( length( z ) == 1 | !( grepl( 'stata_dta|spss|rdata' , fn ) ) ) 

			# if it's a stata file, import with `read.dta`
			if( grepl( 'stata_dta' , tolower( fn ) ) ) x <- read.dta( z , convert.factors = FALSE )
			
			# if it's an spss file, import with `read.spss`
			if( grepl( 'spss' , tolower( fn ) ) ) x <- read.spss( z , to.data.frame = TRUE , use.value.labels = FALSE )
			
			# if it's an r data file, hey the work has been done for you!
			if( grepl( 'rdata' , tolower( fn ) ) ){
			
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
				rfn <- paste0( this.subdir , "/" , gsub( file_ext( fn ) , "rda" , fn ) )
				
				# store the data.frame object on the local disk
				save( x , file = rfn )
				
				# remove the data.frame from working memory
				rm( x )

			}
				
		}
		
		# clear up RAM
		gc()
	}

	# determine all available countries available for this wave
	countries <- GET( paste0( "http://www.worldvaluessurvey.org/AJDocumentation.jsp?CndWAVE=" , this.wave , "&COUNTRY=" ) )

	# so long as any exist..
	if( length( readHTMLTable( content( countries ) ) ) > 0 ){
		
		# extract the individual country pages,
		# storing those results into a table
		id.table <-
			cbind(
				readHTMLTable( content( countries ) )[[1]] ,
				unlist( xpathSApply( content( countries ) , "//*/tr" , xmlAttrs ) )
			)

		# remove the first row of this table of identifiers
		id.table <- id.table[ -1 , ]
		
		# rename the columns of this id table
		names( id.table ) <- c( 'country_year' , 'id' )

		# convert all columns to character types
		id.table[ , ] <- sapply( id.table[ , ] , as.character )

		# loop through each record in this table..
		for ( i in seq( nrow( id.table ) ) ){
		
			# designate a working subdirectory named based on the country_year
			this.subdir <- paste0( this.dir , "/" , id.table[ i , 'country_year' ] )

			# initiate that subdirectory
			dir.create( this.subdir , showWarnings = FALSE )

			# blank out the download id..
			values$DOID <- ""
			
			# ..but specify the country-year id
			values$SAID <- id.table[ i , 'id' ]

			# tell the server what you want.
			POST( "http://www.worldvaluessurvey.org/AJDocumentationSmpl.jsp" , body = values )
			
			# pull the country-year page contents
			this.country <- GET( "http://www.worldvaluessurvey.org/AJDocumentationSmpl.jsp" , query = values )

			# extract all links posted on the country-year page
			country.links <- unlist( xpathSApply( content( this.country ) , "//*/a" , xmlAttrs ) )
			
			# determine which of those links have the word "Download" in 'em
			dlid <- country.links[ grep( "Download" , country.links ) ]
			
			# extract the country-specific file ids
			country.ids <- gsub( "(.*)\\('([0-9]*)'\\)" , "\\2" , dlid )

			# loop through each country-specific id
			for ( this.cid in country.ids ){

				# store that result in the download id parameter of what you send to the server
				values$DOID <- this.cid

				# send another series of commands to the server, specific to this file
				POST( "http://www.worldvaluessurvey.org/AJDownloadLicense.jsp" , body = values )

				# download this file.
				x <- GET( "http://www.worldvaluessurvey.org/AJDownload.jsp" , query = values )

				# store the file contents to the temporary file on the local disk
				writeBin( content( x , "raw" ) , tf )

				# extract the filename from the website's response header
				fn <- gsub( "attachment; filename=\"|\"" , "" , x$headers$`content-disposition` )
				
				# delete the object `x` from RAM
				rm( x )
				
				# copy the temporary file over to the current subdirectory
				file.copy( tf , paste0( this.subdir , "/" , fn ) )

				# if the file is a zipped file..
				if( file_ext( fn ) == 'zip' ){

					# unzip it into the local temporary directory
					z <- unzip( tf , exdir = td )
					
					# confirm that the unzipped file length is one or it is not an rda/dta/sav file
					stopifnot ( length( z ) == 1 | !( grepl( 'stata_dta|spss|rdata' , fn ) ) ) 

					# if it's a stata file, import with `read.dta`
					if( grepl( 'stata_dta' , tolower( fn ) ) ) x <- read.dta( z , convert.factors = FALSE )
					
					# if it's an spss file, import with `read.spss`
					if( grepl( 'spss' , tolower( fn ) ) ) x <- read.spss( z , to.data.frame = TRUE , use.value.labels = FALSE )
					
					# if it's an r data file, hey the work has been done for you!
					if( grepl( 'rdata' , tolower( fn ) ) ){
					
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
						rfn <- paste0( this.subdir , "/" , gsub( file_ext( fn ) , "rda" , fn ) )
						
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
		
	}
	
}

# remove all files stored in the temporary directory
unlink( td , recursive = TRUE )


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
