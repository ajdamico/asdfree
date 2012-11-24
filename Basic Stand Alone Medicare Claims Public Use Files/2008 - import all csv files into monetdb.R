# analyze us government survey data with the r language
# basic stand alone medicare claims public use files
# 2008 files

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
# install.packages( c( "RCurl" , "R.utils" ) )


require(RCurl)		# load RCurl package (downloads files from the web)
require(R.utils)	# load the R.utils package (counts the number of lines in a file quickly)
require(RMonetDB)	# load the RMonetDB package (connects r to a monet database)


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

setwd( "C:/My Directory/BSAPUF/" )


# set the current year of data to import
year <- 2008


#######################################################	
# function to download scripts directly from github.com
# http://tonybreyal.wordpress.com/2011/11/24/source_https-sourcing-an-r-script-from-github/
source_https <- function(url, ...) {
  # load package
  require(RCurl)

  # parse and evaluate each .R script
  sapply(c(url, ...), function(u) {
    eval(parse(text = getURL(u, followlocation = TRUE, cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl"))), envir = .GlobalEnv)
  })
}
#######################################################

# load the windows.monetdb.configuration() function,
# which allows the easy creation of an executable (.bat) file
# to run the monetdb server specific to this data
source_https( "https://raw.github.com/ajdamico/usgsd/master/MonetDB/windows.monetdb.configuration.R" )


# create a folder "MonetDB" in your current working directory.
# so, for example, if you set your current working directory to C:\My Directory\BSAPUF\ above,
# create a new folder C:\My Directory\BSAPUF\MonetDB right now.


# if the MonetDB folder doesn't exist in your current working directory,
# this line will create an error.
stopifnot( file.exists( paste0( getwd() , "/MonetDB" ) ) )


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
windows.monetdb.configuration( 

		# choose a location to store the file that will run the monetdb server on your local computer
		# this can be stored anywhere, but why not put it in the monetdb directory
		bat.file.location = paste0( getwd() , "\\MonetDB\\monetdb.bat" ) , 
		
		# figure out the file path of the MonetDB software on your local machine.
		# on my windows machine, monetdb version 5.0 defaulted to this directory, but double-check yours:
		monetdb.program.path = "C:\\Program Files\\MonetDB\\MonetDB5\\" ,
		
		# assign the directory where the database will be stored.
		# this setting will store the database within the MonetDB folder of the current working directory
		database.directory = paste0( getwd() , "\\MonetDB\\" ) ,
		
		# create a server name for the dataset you want to save into monetdb.
		# this will change for different datasets -- for the basic stand alone public use file, just use bsapuf
		dbname = "bsapuf" ,
		
		# choose which port 
		dbport = 50003
	)


# this next step is so very important.

# store a line of code that will make it easy to open up the monetdb server in the future.
# this should contain the same file path as the "bat.file.location" parameter above,
# but don't simply copy the "paste0( getwd() , "\\MonetDB\\monetdb.bat" )" here,
# because if your current working directory changes at other points, you don't want this line to change.
# you're best bet is to actually look at your local disk to find the full filepath of the executable (.bat) file.
# if it's stored in C:\My Directory\BSAPUF\MonetDB\monetdb.bat
# then your shell.exec line should be:


shell.exec( "C:/My Directory/BSAPUF/MonetDB/monetdb.bat" )


# hold on to that line for future scripts.
# you need to run this line *every time* you access
# the basic stand alone public use files with monetdb.
# this is the monetdb server.

# two other things you need: the database name and the database port.
# store them now for later in this script, but hold on to them for other scripts as well
dbname <- "bsapuf"
dbport <- 50003


# hey try running it now!  a shell window should pop up.
# when it runs, my computer shows:

# MonetDB 5 server v11.11.11 "Jul2012-SP2"
# Serving database 'bsapuf', using 2 threads
# Compiled for x86_64-pc-winnt/64bit with 64bit OIDs dynamically linked
# Found 15.873 GiB available main-memory.
# Copyright (c) 1993-July 2008 CWI.
# Copyright (c) August 2008-2012 MonetDB B.V., all rights reserved
# Visit http://www.monetdb.org/ for further information
# Listening for connection requests on mapi:monetdb://127.0.0.1:50003/
# MonetDB/SQL module loaded

# if that shell window is not open, monetdb commands will not work.  period.


# give the shell window ten seconds to load.
Sys.sleep( 10 )


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
ipbs <- paste0( "./" , year , "/" , year , "_IPBS_PUF.csv" )

# end of files to download #


# the monetdb installation instructions asked you to note the filepath of the monetdb java (.jar) file
# you need it now.  create a new 'monetdriver' object containing a character string
# with the filepath of the java database connection file
monetdriver <- "c:/program files/monetdb/monetdb5/monetdb-jdbc-2.7.jar"

# convert the driver to a monetdb driver
drv <- MonetDB( classPath = monetdriver )

# notice the dbname and dbport (assigned above during the monetdb configuration)
# get used in this line
monet.url <- paste0( "jdbc:monetdb://localhost:" , dbport , "/" , dbname )

# now put everything together and create a connection to the monetdb server.
db <- dbConnect( drv , monet.url , user = "monetdb" , password = "monetdb" )
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


######################################################################
# lines of code to hold on to for all other bsa puf monetdb analyses #

# first: your shell.exec() function.  again, mine looks like this:
shell.exec( "C:/My Directory/BSAPUF/MonetDB/monetdb.bat" )

# second: add a ten second system sleep in between the shell.exec() function
# and the database connection lines.  this gives your local computer a chance
# to get monetdb up and running.
Sys.sleep( 10 )

# third: your six lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "bsapuf"
dbport <- 50003
monetdriver <- "c:/program files/monetdb/monetdb5/monetdb-jdbc-2.7.jar"
drv <- MonetDB( classPath = monetdriver )
monet.url <- paste0( "jdbc:monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( drv , monet.url , user = "monetdb" , password = "monetdb" )

# end of lines of code to hold on to for all other bsa puf monetdb analyses #
#############################################################################


# once complete, this script does not need to be run again for this year of data.
# instead, use the example monetdb analysis scripts


# unlike most post-importation scripts, the monetdb directory cannot be set to read-only #
winDialog( 'ok' , paste( "all done.  DO NOT set" , getwd() , "read-only or subsequent scripts will not work." ) )

winDialog( 'ok' , "got that? monetdb directories should not be set read-only." )
# don't worry, you won't update any of these tables so long as you exclusively stick with the dbGetQuery() function
# instead of the dbSendUpdate() function (you'll see examples in the analysis scripts)


# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
