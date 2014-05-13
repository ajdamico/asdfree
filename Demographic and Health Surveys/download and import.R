# analyze survey data for free (http://asdfree.com) with the r language
# demographic and health surveys
# all available years
# all approved countries

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# your.username <- "username"
# your.password <- "password"
# your.project <- "project"
# library(downloader)
# setwd( "C:/My Directory/DHS/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Demographic%20and%20Health%20Surveys/download%20and%20import.R" , prompt = FALSE , echo = TRUE )
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
# download every file from every year of the Demographic and Health Surveys with R #
# then save every file as an R data frame (.rda) so future analyses can be rapid   #
####################################################################################


# # # # # # # # # # # # # #
# important user warning! #
# # # # # # # # # # # # # #

# you *must* visit this dhsprogram.com website and explain your research
# before receiving a username and password.

# this is to protect both yourself and the respondents of the study.  register here:
# http://dhsprogram.com/data/Access-Instructions.cfm

# once you have registered, place your username, password, and the name of your project in the script below.
# this script will not run until valid values are included in the lines below.
# oh and don't forget to uncomment these lines by removing the `#`

# your.username <- "username"
# your.password <- "password"
# your.project <- "project"

# this massive ftp download automation script will not work without the above lines filled in.
# if the three lines above are not filled in with the details you provided at registration, 
# the script is going to break.  to repeat.  register to access dhs data.


# # # # # # # # # # # # # # # # # 
# end of important user warning #
# # # # # # # # # # # # # # # # #


# set your working directory.
# all DHS data files will be stored here
# after downloading.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/DHS/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( c( "XML" , "httr" ) )

# no need to edit anything below this line #


# # # # # # # # #
# program start #
# # # # # # # # #


library(foreign) 	# load foreign package (converts data files into R)
library(httr)		# load httr package (downloads files from the web, with SSL and cookies)
library(XML)		# load XML (parses through html code to extract links)


# authentication page
terms <- "https://dhsprogram.com/data/dataset_admin/login_main.cfm"

# projects page
projects.page <- "https://dhsprogram.com/data/dataset_admin/"

# countries page
countries.page <- "https://dhsprogram.com/data/dataset_admin/download-datasets.cfm"

# create a temporary file and temporary directory
tf <- tempfile() ; td <- tempdir()


# set the username and password
values <- 
	list( 
		UserName = your.username , 
		UserPass = your.password 
	)

# log in.
GET( terms , query = values )
POST( terms , body = values )

# extract the available countries from the projects page
z <- GET( projects.page )

# write the information from the `projects` page to a local file
writeBin( z$content , tf )

# load the text 
y <- readLines( tf )

# figure out the project number
project.line <- unique( y[ grep( paste0( "option value(.*)" , your.project ) , y ) ] )

# confirm only one project
stopifnot( length( project.line ) == 1 ) 

# extract the project number from the line above
project.number <- gsub( "(.*)<option value=\"([0-9]*)\">(.*)" , "\\2" , project.line )

# log in again, but specifically with the project number
values <- 
	list( 
		UserName = your.username , 
		UserPass = your.password ,
		proj_id = project.number
	)

# re-access the download-datasets page
z <- 
	POST( 
		"https://dhsprogram.com/data/dataset_admin/download-datasets.cfm" , 
		body = list( proj_id = project.number ) 
	)


# figure out which countries are available for download
country.names <- xpathSApply( content( z ) , "//option" , xmlValue )
country.numbers <- xpathSApply( content( z ) , "//option" , xmlGetAttr , "value" )

# remove everything *after* select a region
country.numbers <- country.numbers[ -which( country.names == "Select Region" ):-length(country.numbers) ]
country.names <- country.names[ -which( country.names == "Select Region" ):-length(country.names) ]

# remove "select a country"
country.numbers <- country.numbers[ -1 ]
country.names <- country.names[ -1 ]


# loop through each available country #
for ( j in seq( length( country.numbers ) ) ){

	# extract the current country number..
	this.number <- country.numbers[ j ]
	# ..and current country name
	this.name <- country.names[ j ] 

	# create the country directory on the local disk
	dir.create( paste0( "./" , this.name ) )

	# create a website key pointing the specific country
	values <- 
		list( 
			proj_id = project.number ,
			Apr_Ctry_list_id = this.number ,
			submitted = 2 ,
			action = "View Surveys" ,
			submit = "View Surveys"
		)

	# re-access the download data page
	# using the new country-specific key
	z <- 
		POST( 
			"https://dhsprogram.com/data/dataset_admin/download-datasets.cfm" , 
			body = values 
		)
		
	# pull all links
	link.names <- xpathSApply( content( z ) , "//a" , xmlValue )
	link.urls <- xpathSApply( content( z ) , "//a" , xmlGetAttr , "href" )

	# extract all links containing the current country's name
	valid.surveys <- grep( this.name , link.names )

	# de-parse link titles and specific urls
	link.names <- unlist( link.names [ valid.surveys ] )
	link.urls <- unlist( link.urls [ valid.surveys ] )

	# loop through each available data set within the country #
	for ( this.link in link.urls ){

		# access each dataset's link
		z <- GET( paste0( "https://dhsprogram.com" , this.link ) )

		# read the table from each country page, remove the country name, and remove extraneous characters
		this.title <- gsub( ": |," , "" , gsub( this.name , "" , readHTMLTable( content(z) )[[1]][1,1] ) )

		# create a dataset-specific folder within the country folder within the current working directory
		dir.create( paste0( "./" , this.name , "/" , this.title ) )

		# store all dataset-specific links
		all.links <- xpathSApply( content( z ) , "//div//a" , xmlGetAttr , "href" )

		# keep only /data/dataset/ links
		data.link <- unique( all.links[ grepl( "/data/dataset/" , all.links ) ] )

		# there's only one of these urls.
		stopifnot( length( data.link ) == 1 )

		# follow the dataset-link again
		z <- GET( paste0( "https://dhsprogram.com" , data.link ) )

		# now pull all the file names, sizes, and titles
		y <- readHTMLTable( content( z ) )

		# only download the survey data sets, so just the first item in the table
		y <- y[[1]]

		# also find the country codes and links
		all.links <- unique( tolower( xpathSApply( content( z ) , "//div//a" , xmlGetAttr , "href" ) ) )

		# loop through each of the available survey data sets..
		for ( i in seq( nrow( y ) ) ){
			
			# clear up RAM
			gc()
			
			# if it's a table header..
			if ( is.na( y[ i , 'File Size' ] ) ){
			
				# find the filename
				fname <- y[ i , 'File Name' ]
			
				# check whether the previous folder was also missing
				if( i != 1 ) if( is.na( y[ i - 1 , 'File Size' ] ) ){
					fname <- paste( y[ i - 1 , 'File Name' ] , y[ i , 'File Name' ] )
				}
			
				# assign a new save-folder
				cur.folder <- paste0( "./" , this.name , "/" , this.title , '/' , fname )
				
				# and create it.
				dir.create( cur.folder )
				
			# ..otherwise it's a microdata file!
			} else {
			
				# figure out the url to download
				file.url <- all.links[ grep( y[ i , 'File Name' ] , all.links ) ]

				# download the actual microdata file
				current.file <- GET( paste0( "https://dhsprogram.com" , file.url ) )

				# final folder to save it
				fs <- paste( cur.folder , tolower( gsub( " System file| data" , "" , y[ i , 'File Format' ] ) ) , sep = '/' )
			
				# make sure the file-specific folder exists
				dir.create( fs , showWarnings = FALSE )
			
				# write the content of the download to a binary file
				writeBin( content( current.file , "raw" ) , tf )
				
				# unzip the contents of the zipped file
				z <- unzip( tf , exdir = fs )

				# and now, if there's a stata file, import it!
				if ( any( st <- grepl( "\\.dta$" , tolower( z ) ) ) ){
					
					# remove any prior `x` tables ; clear up RAM
					rm( x ) ; gc()
					
					# load the current stata file into working memory
					x <- read.dta( z[ which( st ) ] , convert.factors = FALSE )
				
					# save the file on the local disk, within the appropriate country-survey filepath
					save( x , file = paste0( cur.folder , ".rda" ) )
					
				}

				# if a file has not been saved as an rda yet,
				# look for an spss file as well.  this way, stata always takes priority.
				if ( !file.exists( paste0( cur.folder , ".rda" ) ) ){
				
					# if there's any spss file, import it!
					if ( any( st <- grepl( "\\.sav$" , tolower( z ) ) ) ){
						
						# remove any prior `x` tables ; clear up RAM
						rm( x ) ; gc()
					
						# load the current stata file into working memory
						x <- read.spss( z[ which( st ) ] , to.data.frame = TRUE , use.value.labels = FALSE )
					
						# save the file on the local disk, within the appropriate country-survey filepath
						save( x , file = paste0( cur.folder , ".rda" ) )
						
					}
				}
				
			}

		}
	}
}


# delete the temporary file..
file.remove( tf )

# ..and temporary directory on the local disk
unlink( td , recursive = TRUE )

# print a reminder: set the directory you just saved everything to as read-only!
message( paste0( "all done. you should set the folder " , getwd() , " read-only so you don't accidentally alter these tables." ) )


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
