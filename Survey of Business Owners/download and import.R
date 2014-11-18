# analyze survey data for free (http://asdfree.com) with the r language
# survey of business owners
# 2007

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/SBO/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Survey%20of%20Business%20Owners/download%20and%20import.R" , prompt = FALSE , echo = TRUE )
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


##########################################################
# Analyze the 2007 Survey of Business Owners file with R #
##########################################################


# set your working directory.
# the SBO 2007 data files will be stored here
# after downloading and importing them.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/SBO/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( c( "survey" , "RSQLite" , "mitools" , "downloader" ) )


# name the database (.db) file to be saved in the working directory
sbo.dbname <- "sbo07.db"


############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #

# if the sbo database file already exists in the current working directory, print a warning
if ( file.exists( paste( getwd() , sbo.dbname , sep = "/" ) ) ) warning( "the database file already exists in your working directory.\nyou might encounter an error if you are running the same year as before or did not allow the program to complete.\ntry changing the sbo.dbname in the settings above." )


library(RSQLite) 			# load RSQLite package (creates database files in R)
library(mitools) 			# load mitools package (analyzes multiply-imputed data)
library(survey) 			# load survey package (analyzes complex design surveys)
library(downloader)			# downloads and then runs the source() function on scripts from github


# load the download.cache and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url( 
	"https://raw.github.com/ajdamico/usgsd/master/Download%20Cache/download%20cache.R" , 
	prompt = FALSE , 
	echo = FALSE 
)


# load sbo-specific functions (a specially-designed series of multiply-imputed, hybrid-survey-object setup to match the census bureau's tech docs)
source_url( "https://raw.github.com/ajdamico/usgsd/master/Survey%20of%20Business%20Owners/sbosvy%20functions.R" , prompt = FALSE )


# create a temporary file and a temporary directory..
tf <- tempfile() ; td <- tempdir()

# download the 2007 public use microdata sample (pums)
# zipped file to the temporary file on your local disk
download.cache( "http://www2.census.gov/econ/sbo/07/pums/pums_csv.zip" , tf , mode = 'wb' )

# unzip the temporary (zipped) file into the temporary directory
# and store the filepath of the unzipped file(s) into a character vector `z`
z <- unzip( tf , exdir = td )

# connect to an rsqlite database on the local disk
db <- dbConnect( SQLite() , sbo.dbname )

# load the mathematical functions in the r package RSQLite.extfuns
initExtension(db)

# read the comma separated value (csv) file you just downloaded
# directly into the rsqlite database you just created.
dbWriteTable( db , 'z' , z , sep = "," , header = TRUE )
# yes.  you did all that.  nice work.

# re-write the same table, but with lowercase column names	
dbSendQuery( 
	db , 
	paste(
		'CREATE TABLE y AS SELECT' ,
		paste( 
			dbListFields( db , 'z' ) , 
			tolower( dbListFields( db , 'z' ) ) , 
			collapse = ', ' , 
			sep = ' as '
		) ,
		"FROM z"
	)
)
# and since the data table `z` has a bunch of messy capital-letter column names
dbRemoveTable( db , 'z' )
# delete it from the rsqlite database

# add a new numeric column called `one` to the `y` data table
dbSendQuery( db , 'ALTER TABLE y ADD COLUMN one DOUBLE PRECISION' )
# and fill it with all 1s for every single record.
dbSendQuery( db , 'UPDATE y SET one = 1' )

# add a new numeric column called `newwgt` to the `y` data table
dbSendQuery( db , 'ALTER TABLE y ADD COLUMN newwgt DOUBLE PRECISION' )

# and use the weights displayed in the census bureau's technical documentation
dbSendQuery( db , 'UPDATE y SET newwgt = 10 * tabwgt * SQRT( 1 - 1 / tabwgt )' )
# http://www2.census.gov/econ/sbo/07/pums/2007_sbo_pums_users_guide.pdf#page=7

# take a look at all the new data tables that have been added to your RAM-free SQLite database
dbListTables( db )

# disconnect from the current database
dbDisconnect( db )

# remove the temporary file from the local disk
file.remove( tf )

# delete the whole temporary directory
unlink( td , recursive = TRUE )

# print a reminder: set the directory you just saved everything to as read-only!
message( paste0( "all done.  you should set the file " , file.path( getwd() , sbo.dbname ) , " read-only so you don't accidentally alter these tables." ) )


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
