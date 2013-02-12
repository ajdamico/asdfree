# analyze us government survey data with the r language
# area resource file
# 2011-2012

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
# install.packages( c( 'SAScii' , 'descr' , 'RSQLite' , 'downloader' ) )



############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #


# load necessary libraries
require(RSQLite) 	# load RSQLite package (creates database files in R)
require(SAScii) 	# load the SAScii package (imports ascii data with a SAS script)
require(descr) 		# load the descr package (converts fixed-width files to delimited files)
require(foreign) 	# load foreign package (converts data files into R)
require(downloader)	# downloads and then runs the source() function on scripts from github


# load the read.SAScii.sqlite function (a variant of read.SAScii that creates a database directly)
source_url( "https://raw.github.com/ajdamico/usgsd/master/SQLite/read.SAScii.sqlite.R" )


# create a temporary database file and another temporary file
temp.db <- tempfile()
tf <- tempfile()


# download the most current ARF file
# and save it as the temporary file
download.file( "http://datawarehouse.hrsa.gov/datadownload/ARF/arf2011-2012.zip" , tf , mode = 'wb' )


# unzip all of the files in the downloaded .zip file into the current working directory
# then save all of their unzipped locations into a character vector called 'files'
files <- unzip( tf , exdir = getwd() )
# note that this saves *all* of the files contained in the .zip
# into the current working directory -- including the ARF documentation 


# identify ascii file on your locak disk
fn <- files[ grep( '\\.asc' , files ) ]


# identify sas (read-in) import instructions
sas_ri <- files[ grep( '\\.sas' , files ) ]


# create and connect to a temporary SQLite database
db <- dbConnect( SQLite() , temp.db )


# parse through the ARF without touching RAM #
read.SAScii.sqlite( 
		fn = fn ,
		sas_ri = sas_ri ,
		tl = TRUE ,			# convert all column names to lowercase?
		tablename = 'arf' ,
		db = db
	)


# read the ARF into RAM
arf <- dbReadTable( db , 'arf' )


# disconnect from the temporary SQLite database
dbDisconnect( db )

# and delete it
file.remove( temp.db )


# save the arf data table as an R data file (.rda)
# (for quick loading later)
save( arf , file = file.path( getwd() , "arf2011.rda" ) )


# uncomment this line to export the arf data table as a csv file
# write.csv( arf , file.path( getwd() , "arf2011.csv" ) )


# uncomment this line to export the arf data table as a stata file
# write.dta( arf , file.path( getwd() , "arf2011.dta" ) )


# delete the ARF table from RAM
rm( arf )

# clear up RAM
gc()


# print a reminder: set the directory you just saved everything to as read-only!
message( paste( "all done.  you should set" , getwd() , "read-only so you don't accidentally alter these files." ) )

# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
