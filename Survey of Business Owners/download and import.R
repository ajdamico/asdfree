# analyze survey data for free (http://asdfree.com) with the r language
# survey of business owners
# 2007

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/SBO/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Survey%20of%20Business%20Owners/download%20and%20import.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


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
# install.packages( c( "MonetDBLite" , "mitools" , "downloader" , "digest" , "survey" )  )


# name the database folder to be saved in the working directory
SBO.dbname <- "sbo"


############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #


library(MonetDBLite)
library(DBI)				# load the DBI package (implements the R-database coding)
library(mitools) 			# load mitools package (analyzes multiply-imputed data)
library(survey) 			# load survey package (analyzes complex design surveys)
library(downloader)			# downloads and then runs the source() function on scripts from github


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


# load sbo-specific functions (a specially-designed series of multiply-imputed, hybrid-survey-object setup to match the census bureau's tech docs)
source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Survey%20of%20Business%20Owners/sbosvy%20functions.R" , prompt = FALSE )


# create a temporary file and a temporary directory..
tf <- tempfile() ; td <- tempdir()

# download the 2007 public use microdata sample (pums)
# zipped file to the temporary file on your local disk
download_cached( "http://www2.census.gov/econ/sbo/07/pums/pums_csv.zip" , tf , mode = 'wb' )

# unzip the temporary (zipped) file into the temporary directory
# and store the filepath of the unzipped file(s) into a character vector `z`
z <- unzip( tf , exdir = td )

# name the database files in the "SIPP08" folder of the current working directory
dbfolder <- paste0( getwd() , "/" , SBO.dbname )

# connect to the MonetDBLite database (.db)
db <- dbConnect( MonetDBLite::MonetDBLite() , dbfolder )

# read the comma separated value (csv) file you just downloaded
# directly into the monetdb database you just created.
dbWriteTable( db , 'y' , z , sep = "," , header = TRUE , lower.case.names = TRUE )
# yes.  you did all that.  nice work.

# add a new numeric column called `one` to the `y` data table
dbSendQuery( db , 'ALTER TABLE y ADD COLUMN one DOUBLE PRECISION' )
# and fill it with all 1s for every single record.
dbSendQuery( db , 'UPDATE y SET one = 1' )

# add a new numeric column called `newwgt` to the `y` data table
dbSendQuery( db , 'ALTER TABLE y ADD COLUMN newwgt DOUBLE PRECISION' )

# and use the weights displayed in the census bureau's technical documentation
dbSendQuery( db , 'UPDATE y SET newwgt = 10 * tabwgt * SQRT( 1 - 1 / tabwgt )' )
# http://www2.census.gov/econ/sbo/07/pums/2007_sbo_pums_users_guide.pdf#page=7

# take a look at all the new data tables that have been added to your RAM-free monetdb database
dbListTables( db )

# disconnect from the current database
dbDisconnect( db , shutdown = TRUE )

# remove the temporary file from the local disk
file.remove( tf )

# delete the whole temporary directory
unlink( td , recursive = TRUE )

