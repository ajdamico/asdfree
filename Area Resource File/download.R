# analyze survey data for free (http://asdfree.com) with the r language
# area resource file
# 2014-2015

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/ARF/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Area%20Resource%20File/download.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


#######################################################
# download the most current Area Resource File with R #
# then save every file as an R data frame (.rda)      #
#######################################################


# set your working directory.
# all ARF files will be stored here
# after downloading and importing it.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/ARF/" )
# ..in order to set your current working directory


# remove the # in order to run this install.packages line only once
# install.packages( c( 'SAScii' , 'descr' , 'MonetDBLite' , 'downloader' , 'digest' ) )



############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #


# load necessary libraries
library(DBI)			# load the DBI package (sets up main SQL configuration and connectivity functions)
library(MonetDBLite) 	# load MonetDBLite package (creates database files in R)
library(SAScii) 		# load the SAScii package (imports ascii data with a SAS script)
library(descr) 			# load the descr package (converts fixed-width files to delimited files)
library(foreign) 		# load foreign package (converts data files into R)
library(downloader)		# downloads and then runs the source() function on scripts from github


# load the read.SAScii.sqlite function (a variant of read.SAScii that creates a database directly)
source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/MonetDB/read.SAScii.monetdb.R" , prompt = FALSE )

# store the downloaded file locally forever
source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Download%20Cache/download%20cache.R" , prompt = FALSE , echo = FALSE )

# create a temporary file
tf <- tempfile()

# download the most current ARF file
# and save it as the temporary file
download_cached( "http://datawarehouse.hrsa.gov/DataDownload/ARF/AHRF_2014-2015.zip" , tf , mode = 'wb' )


# unzip all of the files in the downloaded .zip file into the current working directory
# then save all of their unzipped locations into a character vector called 'files'
files <- unzip( tf , exdir = getwd() )
# note that this saves *all* of the files contained in the .zip
# into the current working directory -- including the ARF documentation 


# identify ascii file on your local disk
fn <- files[ grep( '\\.asc' , files ) ]

# make an overwritten file
fn_ue <- gsub( "\\.asc" , "_ascii.asc" , fn )

# store the pre-run encoding configuration
pre_encoding <- getOption( "encoding" )

# switch the environment to ascii (very strict) encoding
options( encoding = "ASCII" )

# load in the whole file (in ASCII)
arf_load <- readLines( fn )

# overwrite the file with the stricter encoding
writeLines( arf_load , fn_ue )

# remove this object from memory & clear up RAM
rm( arf_load ) ; gc()

# restore the previous encoding settings
options( encoding = pre_encoding )

# identify sas (read-in) import instructions
sas_ri <- files[ grep( '\\.sas' , files ) ]

# create and connect to a temporary MonetDBLite database
db <- dbConnect( MonetDBLite::MonetDBLite() )


# parse through the ARF without touching RAM #
read.SAScii.monetdb( 
	fn = fn_ue ,
	sas_ri = sas_ri ,
	tl = TRUE ,			# convert all column names to lowercase?
	tablename = 'arf' ,
	conn = db ,
	na_strings = "."	# unlike most other datasets, na strings are dots
)


# read the ARF into RAM
arf <- dbReadTable( db , 'arf' )


# disconnect from the temporary MonetDBLite database
dbDisconnect( db , shutdown = TRUE )


# save the arf data table as an R data file (.rda)
# (for quick loading later)
save( arf , file = file.path( getwd() , "arf2014.rda" ) )


# uncomment this line to export the arf data table as a csv file
# write.csv( arf , file.path( getwd() , "arf2014.csv" ) )


# uncomment this line to export the arf data table as a stata file
# Recode blanks to NA, first. You get an "empty string is not valid in Stata's documented format" message otherwise.
# arf[arf == ""] <- NA
# write.dta( arf , file.path( getwd() , "arf2014.dta" ) )


# delete the ARF table from RAM
rm( arf )

# clear up RAM
gc()


# print a reminder: set the directory you just saved everything to as read-only!
message( paste( "all done.  you should set" , getwd() , "read-only so you don't accidentally alter these files." ) )
