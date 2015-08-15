# analyze survey data for free (http://asdfree.com) with the r language
# national survey of oaa participants
# all available years

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NPS/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/National%20Survey%20of%20OAA%20Participants/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
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


# set your working directory.
# the NPS data files will be stored here
# after downloading and importing them.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NPS/" )
# ..in order to set your current working directory

# remove the # in order to run this install.packages line only once
# install.packages( c( "httr" , "downloader" ) )


############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #

library(downloader)			# downloads and then runs the source() function on scripts from github
library(httr)				# load httr package (downloads files from the web, with SSL and cookies)

# load the download_cached and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url( 
	"https://raw.github.com/ajdamico/usgsd/master/Download%20Cache/download%20cache.R" , 
	prompt = FALSE , 
	echo = FALSE 
)

# create a temporary file and a temporary directory
tf <- tempfile() ; td <- tempdir()

# set the agidnet page containing all of the available microdata files
main.file.page <- "http://www.agid.acl.gov/DataFiles/NPS/"

# download the contents of that page to an object
z <- GET( main.file.page )

# store the contents of that object into a temporary file
writeBin( z$content , tf )

# read that temporary file's contents back into RAM
html <- readLines( tf )
# kinda circuitous, eh?

# limit that `html` character vector
# to only lines containing the text `serviceid`
serviceid.lines <- html[ grep( 'serviceid' , html ) ]

# get rid of all text in each line in front of `href="`
after.href <- sapply( strsplit( serviceid.lines , 'href=\"' ) , '[[' , 2 )

# and also get rid of all text in each line after `">`
before.bracket <- sapply( strsplit( after.href , "\">" ) , '[[' , 1 )

# suddenly, you've got yourself a character vector containing
# the paths to all of the available microdata files.  yippie!
all.files <- paste0( main.file.page , before.bracket )

# extract all numeric values from those filepaths,
# since the filepaths specify the year of the microdata.
all.years <- unique( as.numeric( gsub( "(.*)(year=)(.*)(&amp)(.*)" , "\\3" , all.files ) ) )
# this will allow microdata-saving to occur within year-specific directories.

# loop through every year for which microdata are available..
for ( year in all.years ){

	# look again at the `all.files` character vector,
	# and extract only the files matching the current year
	files.this.year <- all.files[ grep( year , all.files ) ]
	
	# loop through every specific microdata file available for this year..
	for ( this.file in files.this.year ){
	
		# reset the objects `file.name` and `csv.fn`
		file.name <- csv.fn <- NULL
	
		# extract the `serviceid=` value to determine the exact http filepath
		serviceid <- as.numeric( gsub( "(.*)(serviceid=)(.)" , "\\3" , this.file ) )
		
		# construct the caregiver zipped filepath
		if ( serviceid == 1 ){
		
			file.name <- 'caregiver'
		
			csv.fn <- 
				paste0(
					"http://www.agid.acl.gov/DataFiles/Documents/NPS/Caregiver" , 
					year , 
					"/Caregiver_" , 
					year , 
					"_csv.zip" 
				)
				
		}

		# construct the collected caregiver zipped filepath
		if ( serviceid == 2 ){
		
			file.name <- 'collected caregiver'
		
			csv.fn <- 
				paste0(
					"http://www.agid.acl.gov/DataFiles/Documents/NPS/Collected_Caregiver" , 
					year , 
					"/Collected_Caregiver_" , 
					year , 
					"_csv.zip" 
				)
				
		}

		# construct the family caregiver zipped filepath
		if ( serviceid == 3 ){
		
			file.name <- "family caregiver"
		
			csv.fn <- 
				paste0(
					"http://www.agid.acl.gov/DataFiles/Documents/NPS/Family_Caregiver" , 
					year , 
					"/Family_Caregiver_" , 
					year , 
					"_csv.zip" 
				)
				
		}

		# construct the home delivered meals zipped filepath
		if ( serviceid == 4 ){
		
			file.name <- 'home delivered meals'
		
			csv.fn <- 
				paste0(
					"http://www.agid.acl.gov/DataFiles/Documents/NPS/HomeDeliveredMeals" , 
					year , 
					"/Home_Meals_" , 
					year , 
					"_csv.zip" 
				)
						
		}

		# construct the congregate meals zipped filepath
		if ( serviceid == 5 ){
		
			file.name <- 'congregate meals'

			csv.fn <- 
				paste0(
					"http://www.agid.acl.gov/DataFiles/Documents/NPS/CongregateMeals" , 
					year , 
					"/Cong_Meals_" , 
					year , 
					"_csv.zip" 
				)
				
		}

		# construct the homemaker zipped filepath
		if ( serviceid == 6 ){

			file.name <- 'homemaker'
		
			csv.fn <- 
				paste0(
					"http://www.agid.acl.gov/DataFiles/Documents/NPS/Homemaker" , 
					year , 
					"/Homemaker_" , 
					year , 
					"_csv.zip" 
				)
				
		}

		# construct the info and assistance zipped filepath
		if ( serviceid == 7 ){
		
			file.name <- "info and assistance"
				
			csv.fn <- 
				paste0(
					"http://www.agid.acl.gov/DataFiles/Documents/NPS/InfoAssistance" , 
					year , 
					"/InfoAssistance_" , 
					year , 
					"_csv.zip" 
				)
				
		}

		# construct the transportation zipped filepath
		if ( serviceid == 8 ){
		
			file.name <- 'transportation'
		
			csv.fn <- 
				paste0(
					"http://www.agid.acl.gov/DataFiles/Documents/NPS/Transportation" , 
					year , 
					"/Transportation_" , 
					year , 
					"_csv.zip" 
				)
				
		}

		# construct the case management zipped filepath
		if ( serviceid == 9 ){
		
			file.name <- 'case management'
		
			csv.fn <- 
				paste0(
					"http://www.agid.acl.gov/DataFiles/Documents/NPS/CaseManagement" , 
					year , 
					"/Case_Management_" , 
					year , 
					"_csv.zip" 
				)
				
		}
		
		# and if the serviceid matches none of those, this program needs to be updated ;)
		if ( !( serviceid %in% 1:9 ) ) stop( 'unexpected serviceid' )
		
		# download the zipped csv's file to a temporary directory
		download_cached( csv.fn , tf , mode = 'wb' )
		
		# unzip the temporary file into the temporary directory
		z <- unzip( tf , exdir = td )

		# and if the zipped file contains more than one file, this program needs to be updated ;)
		if ( length( z ) > 1 ) stop( 'multi-file zipped' )
		
		# load the unzipped csv file into an R data.frame object
		x <- read.csv( z )
		
		# convert all column names to lowercase
		names( x ) <- tolower( names( x ) )
		
		# add a column of all ones
		x$one <- 1
		
		# create a new year-specific directory within the current working directory
		dir.create( as.character( year ) , showWarnings = FALSE )
		
		# save the R data.frame object to an `.rda` file for faster loading later
		save( 
			x , 
			file = 
				paste0( 
					getwd() ,
					"/" ,
					year ,
					"/" ,
					file.name ,
					".rda"
				)
		)

	}

}

# print a reminder: set the directory you just saved everything to as read-only!
message( paste0( "all done.  you should set the file " , file.path( getwd() ) , " read-only so you don't accidentally alter these tables." ) )


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
