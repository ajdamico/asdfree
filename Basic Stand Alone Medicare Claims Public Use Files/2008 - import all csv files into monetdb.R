# analyze survey data for free (http://asdfree.com) with the r language
# basic stand alone medicare claims public use files
# 2008 files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/BSAPUF/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Basic%20Stand%20Alone%20Medicare%20Claims%20Public%20Use%20Files/2008%20-%20import%20all%20csv%20files%20into%20monetdb.R" , prompt = FALSE , echo = TRUE )
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


############################################################################################
# import all 2008 comma separated value files for the bsa medicare puf into monetdb with R #
############################################################################################


# # # # # # # # # # # # # # #
# warning: monetdb required #
# # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###################################################################################################################################
# prior to running this analysis script, monetdb must be installed on the local machine.  follow each step outlined on this page: #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/usgsd/blob/master/MonetDB/monetdb%20installation%20instructions.R                                   #
###################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# remove the # in order to run this install.packages line only once
# install.packages( "R.utils" )


require(R.utils)	# load the R.utils package (counts the number of lines in a file quickly)
require(MonetDB.R)	# load the MonetDB.R package (connects r to a monet database)


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###########################################################################################################################################################
# prior to running this analysis script, the basic stand alone public use files for 2008 must be loaded as comma separated value files (.csv) on the      #
# local machine.  running the 2008 - download all csv files script will store each of these files in the current working directory                        #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/usgsd/master/Basic%20Stand%20Alone%20Medicare%20Claims%20Public%20Use%20Files/2008%20-%20download%20all%20csv%20files.R #
###########################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# all 2008 BSA comma separated value (.csv) files
# should already be stored in the "2008" folder within this directory
# so if all 2008 BSA files are stored in C:\My Directory\BSAPUF\2008\
# set this directory to C:/My Directory/BSAPUF/
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/BSAPUF/" )


# set the current year of data to import
year <- 2008


# note: the MonetDB folder should *not* be within a year-specific directory.
# multiple bsa puf years will all be stored into the same monet database,
# in order to allow multi-year analyses.
# although the csv download script changed the working directory to a single year of data,
# this importation will include all monetdb files into a single database folder


# configure a monetdb database for the bsa pufs on windows #

# note: only run this command once.  this creates an executable (.bat) file
# in the appropriate directory on your local disk.
# when adding new files or adding a new year of data, this script does not need to be re-run.

# create a monetdb executable (.bat) file for the medicare basic stand alone public use file
batfile <-
	monetdb.server.setup(
					
					# set the path to the directory where the initialization batch file and all data will be stored
					database.directory = paste0( getwd() , "/MonetDB" ) ,
					# must be empty or not exist
					
					# find the main path to the monetdb installation program
					monetdb.program.path = "C:/Program Files/MonetDB/MonetDB5" ,
					
					# choose a database name
					dbname = "bsapuf" ,
					
					# choose a database port
					# this port should not conflict with other monetdb databases
					# on your local computer.  two databases with the same port number
					# cannot be accessed at the same time
					dbport = 50003
	)

	
# this next step is so very important.

# store a line of code that will make it easy to open up the monetdb server in the future.
# this should contain the same file path as the batfile created above,
# you're best bet is to actually look at your local disk to find the full filepath of the executable (.bat) file.
# if you ran this script without changes, the batfile will get stored in C:\My Directory\BSAPUF\MonetDB\bsapuf.bat

# here's the batfile location:
batfile

# note that since you only run the `monetdb.server.setup()` function the first time this script is run,
# you will need to note the location of the batfile for future MonetDB analyses!

# in future R sessions, you can create the batfile variable with a line like..
# batfile <- "C:/My Directory/BSAPUF/MonetDB/bsapuf.bat"
# obviously, without the `#` comment character

# hold on to that line for future scripts.
# you need to run this line *every time* you access
# the basic stand alone public use files with monetdb.
# this is the monetdb server.

# two other things you need: the database name and the database port.
# store them now for later in this script, but hold on to them for other scripts as well
dbname <- "bsapuf"
dbport <- 50003


# hey try running it now!  a shell window should pop up.
pid <- monetdb.server.start( batfile )
# store the result into another variable, which stands for process id
# this `pid` variable will allow the MonetDB server to be terminated from within R automagically.

# when the monetdb server runs, my computer shows:
# MonetDB 5 server v11.15.1 "Feb2013"
# Serving database 'bsapuf', using 8 threads
# Compiled for x86_64-pc-winnt/64bit with 64bit OIDs dynamically linked
# Found 7.860 GiB available main-memory.
# Copyright (c) 1993-July 2008 CWI.
# Copyright (c) August 2008-2013 MonetDB B.V., all rights reserved
# Visit http://www.monetdb.org/ for further information
# Listening for connection requests on mapi:monetdb://127.0.0.1:50003/
# MonetDB/JAQL module loaded
# MonetDB/SQL module loaded


# end of monetdb database configuration #



# start of files to import #

# inpatient claims
inpatient <- paste0( "./" , year , "/" , year , "_BSA_Inpatient_Claims_PUF.csv" )

# durable medical equipment
dme <- paste0( "./" , year , "/" , year , "_BSA_DME_Line_Items_PUF.csv" )

# prescription drug events
pde <- paste0( "./" , year , "/" , year , "_BSA_PartD_Events_PUF_" , 1:5 , ".csv" )

# hospice
hospice <- paste0( "./" , year , "/" , year , "_BSA_Hospice_Beneficiary_PUF.csv" )

# physician carrier
carrier <- paste0( "./" , year , "/" , year , "_BSA_Carrier_Line_Items_PUF_" , 1:7 , ".csv" )

# home health agency
hha <- paste0( "./" , year , "/" , year , "_BSA_HHA_Beneficiary_PUF.csv" )

# outpatient
outpatient <- paste0( "./" , year , "/" , year , "_BSA_Outpatient_Procedures_PUF_" , 1:3 , ".csv" )

# skilled nursing facility
snf <- paste0( "./" , year , "/" , year , "_BSA_SNF_Beneficiary_PUF.csv" )

# chronic conditions
cc <- paste0( "./" , year , "/" , year , "_Chronic_Conditions_PUF.csv" )

# institutional provider & beneficiary summary
ipbs <- paste0( "./" , year , "/" , year , " IPBS PUF.csv" )

# prescription drug profiles
rxp <- paste0( "./" , year , "/" , year , "_PD_Profiles_PUF.csv" )


# end of files to import #



# notice the dbname and dbport (assigned above during the monetdb configuration)
# get used in this line
monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )

# now put everything together and create a connection to the monetdb server.
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )
# from now on, the 'db' object will be used for r to connect with the monetdb server


# note: slow. slow. slow. #
# the following monet.read.csv() functions take a while. #
# run them all together overnight if possible. #
# you'll never have to do this again.  hooray! #


# store the 2008 inpatient claims table in the database as the 'inpatient08' table
monet.read.csv( 

	# use the monet database connection initiated above
	db , 

	# store the external csv file contained in the 'inpatient' character string
	inpatient , 

	# save the csv file in the monetdb to a data table named 'inpatient08'
	paste0( 'inpatient' , substr( year , 3 , 4 ) ) , 

	# count the number of records in the csv file(s)
	nrows = sapply( inpatient , countLines ) 
)


# store the 2008 durable medical equipment table in the database as the 'dme08' table
monet.read.csv( 
	db , 
	dme , 
	paste0( 'dme' , substr( year , 3 , 4 ) ) , 
	nrows = sapply( dme , countLines ) 
)

# store the five 2008 prescription drug events tables in the database as a single 'pde08' table
monet.read.csv( 
	db , 
	pde , 
	paste0( 'pde' , substr( year , 3 , 4 ) ) , 
	nrows = sapply( pde , countLines ) 
)

# store the 2008 hospice table in the database as the 'hospice08' table
monet.read.csv( 
	db , 
	hospice , 
	paste0( 'hospice' , substr( year , 3 , 4 ) ) , 
	nrows = sapply( hospice , countLines ) 
)

# store the seven 2008 carrier line items tables in the database as a single 'carrier08' table
monet.read.csv( 
	db , 
	carrier , 
	paste0( 'carrier' , substr( year , 3 , 4 ) ) , 
	nrows = sapply( carrier , countLines ) 
)

# store the 2008 home health agency table in the database as the 'hha08' table
monet.read.csv( 
	db , 
	hha , 
	paste0( 'hha' , substr( year , 3 , 4 ) ) , 
	nrows = sapply( hha , countLines ) 
)

# store the three 2008 outpatient claims tables in the database as a single 'outpatient08' table
monet.read.csv( 
	db , 
	outpatient , 
	paste0( 'outpatient' , substr( year , 3 , 4 ) ) , 
	nrows = sapply( outpatient , countLines ) 
)

# store the 2008 snf table in the database as the 'snf08' table
monet.read.csv( 
	db , 
	snf , 
	paste0( 'snf' , substr( year , 3 , 4 ) ) , 
	nrows = sapply( snf , countLines ) 
)

# store the 2008 chronic conditions table in the database as the 'cc08' table
monet.read.csv( 
	db , 
	cc , 
	paste0( 'cc' , substr( year , 3 , 4 ) ) , 
	nrows = sapply( cc , countLines ) 
)


# count the number of rows in the institutional provider & beneficiary summary table
# just once, since it will be used twice in the monet.read.csv() function
ipbs.rows <- sapply( ipbs , countLines )

# store the 2008 ipbs table in the database as the 'ipbs08' table
monet.read.csv( 
	db , 
	ipbs , 
	paste0( 'ipbs' , substr( year , 3 , 4 ) ) , 
	nrows = ipbs.rows , 
	nrow.check = ipbs.rows 
)

# store the 2008 prescription drug profile table in the database as the 'rxp08' table
monet.read.csv( 
	db , 
	rxp , 
	paste0( 'rxp' , substr( year , 3 , 4 ) ) , 
	nrows = sapply( rxp , countLines ) ,
	nrow.check = 10000
)


# the current monet database folder should now
# contain eight newly-added tables
dbListTables( db )		# print the tables stored in the current monet database to the screen


# the current monet database can now be accessed
# like any other database in the r language
# here's an example of how to examine the first six records
# of the prescription drug events file
dbGetQuery( db , "select * from pde08 limit 6" )
# additional analysis examples are stored in the other scripts


# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )


######################################################################
# lines of code to hold on to for all other bsa puf monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/BSAPUF/MonetDB/bsapuf.bat"

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "bsapuf"
dbport <- 50003

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

# # # # run your analysis commands # # # #


# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other bsa puf monetdb analyses #
#############################################################################


# once complete, this script does not need to be run again for this year of data.
# instead, use the example monetdb analysis scripts


# unlike most post-importation scripts, the monetdb directory cannot be set to read-only #
message( paste( "all done.  DO NOT set" , getwd() , "read-only or subsequent scripts will not work." ) )

message( "got that? monetdb directories should not be set read-only." )
# don't worry, you won't update any of these tables so long as you exclusively stick with the dbGetQuery() function
# instead of the dbSendUpdate() function (you'll see examples in the analysis scripts)


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
