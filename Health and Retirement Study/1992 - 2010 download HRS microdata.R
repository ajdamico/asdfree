# analyze survey data for free (http://asdfree.com) with the r language
# health and retirement study
# 1992 through 2010
# hrs core (final), ahead core (final), exit interviews, imputations

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/HRS/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Health%20and%20Retirement%20Study/1992%20-%202010%20download%20HRS%20microdata.R" , prompt = FALSE , echo = TRUE )
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


##################################################################################
# download every file from every year of the Health and Retirement Study with R  #
# then save every file as an R data frame (.rda) so future analyses can be rapid #
##################################################################################


# # # # # # # # # # # # # #
# important user warning! #
# # # # # # # # # # # # # #

# you *must* visit this university of michigan's institute for social research
# website and register for a username and password, then click the link in the e-mail
# to activate your account before running this massive download automation program

# this is to protect both yourself and the respondents of the study.  register here:
# http://hrsonline.isr.umich.edu/index.php?p=reg

# by registering, you are agreeing to the conditions of use, stated here:
# http://hrsonline.isr.umich.edu/index.php?p=regcou

# once you have registered, place your username and password in the script below.
# this script will not run until a valid username and password are included in the two lines below.

your.username <- "username"
your.password <- "password"

# this massive ftp download automation script will not work without the above lines filled in.
# if the your.username and your.password lines above are not filled in with the details you provided at registration, 
# the script is going to break.  to repeat.  register to access hrs data.


# # # # # # # # # # # # # # # # # 
# end of important user warning #
# # # # # # # # # # # # # # # # #


# set your working directory.
# all HRS data files will be stored here
# after downloading.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/HRS/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( c( "SAScii" , "httr" , "XML" ) )

# no need to edit anything below this line #


# # # # # # # # #
# program start #
# # # # # # # # #


require(httr)		# load httr package (downloads files from the web, with SSL and cookies)
require(XML)		# load XML (parses through html code to extract links)
require(SAScii) 	# load the SAScii package (imports ascii data with a SAS script)
require(foreign) 	# load foreign package (converts data files into R)


# create a `download` directory inside the current working directory
download.dir <- paste( getwd() , "download" , sep = "/" )
dir.create( download.dir )


# authentication page
terms <- "https://ssl.isr.umich.edu/hrs/login2.php"

# download page
download <- "https://ssl.isr.umich.edu/hrs/files2.php"

# set the username and password
values <- 
	list( 
		fuser = your.username , 
		fpass = your.password 
	)

# accept the terms on the form, 
# generating the appropriate cookies
POST( terms , body = values )

# download the content of that download page
resp <- GET( download , query = values )

# build a function (stolen from ?htmlTreeParse) that extracts all links from a web page
getLinks = function() { 
	links = character() 
	list(a = function(node, ...) { 
		links <<- c(links, xmlGetAttr(node, "href"))
		node 
	}, 
	links = function()links)
}

h1 = getLinks()
htmlTreeParse( resp , handlers = h1 )

# save all links into a new object containing all character strings..
all.links <- h1$links()
# ..and immediately limit it to only strings containing `versid`
versid.links <- all.links[ grepl( 'versid' , all.links ) ]

# remove 'files2.php?versid=' from each string,
# so you only maintain the version ids
versids <- gsub( 'files2.php?versid=' , '' , versid.links , fixed = TRUE )


# loop through all version ids
for ( vid in versids ){

	download.page <- paste0( "https://ssl.isr.umich.edu/hrs/files2.php?versid=" , vid )

	# read the current version id's html page
	dls <- GET( download.page )

	#############################################################################
	# figure out if there's a 'distribution set' available on the download page #
	
	# parse through the HTML code to find a specific character string
	pagetree <- htmlTreeParse( dls , useInternalNodes = TRUE )
	table.rows <- xpathSApply( pagetree , "//*/tr" , xmlValue )
	which.table <- grep( 'distribution set' , tolower( table.rows ) )
	
	fne <- NULL
	
	# if there is a distribution set
	if ( length( which.table ) > 0 ){
		
		# find the filename #
		
		# isolate the first non-empty string
		table.contents <- strsplit( table.rows[ which.table ] , " " )[[1]]
		fne <- table.contents[ table.contents != "" ][ 1 ]
		
	}
	
	# extract all `href` html links
	h2 = getLinks()
	htmlTreeParse( dls , handlers = h2 )

	# save all files to download into a new object containing all character strings..
	ftd <- h2$links()
	# ..and immediately limit it to only strings containing `filedownload2`
	ftd.links <- ftd[ grepl( 'filedownload2' , ftd ) ]

	# remove 'filedownload2.php?d=' from each string,
	# so you only maintain the download id
	ds <- gsub( 'filedownload2.php?d=' , '' , ftd.links , fixed = TRUE )
	
	# loop through all files to download
	for ( did in ds ){
	
		# determine the current file path on the university of michigan's website
		cfp <- paste0( 'https://ssl.isr.umich.edu/hrs/filedownload2.php?d=' , did )

		# figure out the filename of the file that's being downloaded
		fn <- tolower( gsub( 'filename=' , '' , HEAD( cfp )$headers$`content-disposition` ) )

		# confirm a few things are true before downloading..
		if ( 
				# since RAND releases SAS, Stata, and SPSS files, no need to download all three
				# Stata files require the least memory to load into R, so only download those.
				# check that the download file name *does not* include the words SAS or SPSS
				!grepl( "sas" , fn ) & !grepl( "spss" , fn ) 
				
				# AND
				&
				
				# either there isn't a "distribution set" on this page OR the current file IS the distribution set
				( is.null( fne ) || fn == fne )
				# extra special note: this test requires a ||
				# because | tests both sides no matter what,
				# while || only goes as far as it needs to go.
				
			){
			
			# download the file to the local disk
			current.file <- GET( cfp )
		
			
			# figure out what year it's from.  possible years are..
			poss.years <- 1992:2091
			# ..and the last two digits are..
			ltd <- substr( poss.years , 3 , 4 )
			
			# first check if the file name contains any four-digit strings..
			contains <- which( sapply( poss.years , grepl , fn ) )

			# if the filename contains more than one year, blank it out
			if( !( length( contains ) %in% 0:1 ) ) contains <- integer(0)
			
			# if the filename doesn't contain any four-digit years..
			if ( length( contains ) == 0 ){
						
				# check if the filename contain any of those two-digit strings..
				contains <- which( sapply( ltd , grepl , fn ) )
			
				# if the filename contains more than one year, blank it out
				if( !( length( contains ) %in% 0:1 ) ) contains <- integer(0)
			}
			
			# save the file into that directory..
			# and if there's no year contained in the filename, save it to the main directory
			current.download.dir <- paste( download.dir , poss.years[ contains ] , sep = "/" )
			
			# try creating the directory if it doesn't already exist
			dir.create( current.download.dir )
			
			# exact file to save it to
			fs <- paste( current.download.dir , fn , sep = '/' )
		
			# write the content of the download to a binary file
			writeBin( content( current.file , "raw" ) , fs )
			
			# if the current file is a zip file..
			if ( current.file$headers$`content-type` == 'application/zip' ){
				
				# figure out the directory it belongs in..
				uzdir <- gsub( ".zip" , "" , fs , fixed = TRUE )
			
				# create a new directory off of the filename
				dir.create( uzdir )
				
				# unzip it, and store the exact filepaths while you're at it
				uzcontents <- unzip( fs , exdir = uzdir )
				
				# loop through those filepaths
				for ( uzc in uzcontents ){
					# figure out the directory it belongs in..
					uzdir <- gsub( ".zip" , "" , uzc , fixed = TRUE )
				
					# create a new directory off of the filename
					dir.create( uzdir )
					
					# unzip those as well
					unzip( uzc , exdir = uzdir )
				}
			}
		}
	}
}


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
