# analyze us government survey data with the r language
# national plan and provider enumeration system files

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


##########################################################################
# download the most current national provider identifier database with R #
##########################################################################


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



# the MonetDB directory will be created within
# the current working directory
# so if you would like the NPI database stored in 
# C:\My Directory\NPPES\
# set this directory to C:/My Directory/NPPES/
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NPPES/" )


# no need to edit anything below this line #


# # # # # # # # #
# program start #
# # # # # # # # #


# the latest npi data file will be stored
# in a temporary file on the local disk

# create two temporary files and a temporary directory
# on the local disk
tf <- tempfile() ; tf2 <- tempfile() ; td <- tempdir()


# create an `attempt` object
# that will cause the `while` loop below
# to execute _at least_ once
# but possibly more
attempt <- try( stop( ) , silent = TRUE )

# the full filepath changes every month,
# so attempt the current Month_Year combo
# but then go back in time until you get it right.
date.to.try <- Sys.Date() + 28

while( class( attempt ) == 'try-error' ){
	
	# subtract 28 days and try again
	date.to.try <- date.to.try - 28
	
	# isolate the current month
	curMonth <- 
		format( date.to.try , "%b" )
	
	# isolate the current year
	curYear <- 
		format( date.to.try , "%Y" )
	
	# build the entire http:// filepath
	# to the latest data set
	fn <- 
		paste0(
			'http://nppes.viva-it.com/NPPES_Data_Dissemination_' ,
			curMonth , 
			'_' ,
			curYear , 
			'.zip'
		)
	
	# try to download the file to
	# the temporary file on the local disk
	attempt <- try( download.file( fn , tf , mode = 'wb' ) , silent = TRUE )

}


# after downloading the file successfully,
# unzip the temporary file to the temporary folder..
z <- unzip( tf , exdir = td )

# ..and identify the appropriate 
# comma separated value (csv) file
# within the `.zip` file
csv.file <- z[ grepl( 'csv' , z ) & !grepl( 'FileHeader' , z ) ]




# create a monetdb executable (.bat) file for the medicare basic stand alone public use file
batfile <-
	monetdb.server.setup(
					
					# set the path to the directory where the initialization batch file and all data will be stored
					database.directory = getwd() ,
					# must be empty or not exist
					
					# find the main path to the monetdb installation program
					monetdb.program.path = "C:/Program Files/MonetDB/MonetDB5" ,
					
					# choose a database name
					dbname = "nppes" ,
					
					# choose a database port
					# this port should not conflict with other monetdb databases
					# on your local computer.  two databases with the same port number
					# cannot be accessed at the same time
					dbport = 50006
	)

	
# this next step is so very important.

# store a line of code that will make it easy to open up the monetdb server in the future.
# this should contain the same file path as the batfile created above,
# you're best bet is to actually look at your local disk to find the full filepath of the executable (.bat) file.
# if you ran this script without changes, the batfile will get stored in C:\My Directory\NPPES\nppes.bat

# here's the batfile location:
batfile

# note that since you only run the `monetdb.server.setup()` function the first time this script is run,
# you will need to note the location of the batfile for future MonetDB analyses!

# in future R sessions, you can create the batfile variable with a line like..
# batfile <- "C:/My Directory/NPPES/nppes.bat"
# obviously, without the `#` comment character

# hold on to that line for future scripts.
# you need to run this line *every time* you access
# the basic stand alone public use files with monetdb.
# this is the monetdb server.

# two other things you need: the database name and the database port.
# store them now for later in this script, but hold on to them for other scripts as well
dbname <- "nppes"
dbport <- 50006


# hey try running it now!  a shell window should pop up.
pid <- monetdb.server.start( batfile )
# store the result into another variable, which stands for process id
# this `pid` variable will allow the MonetDB server to be terminated from within R automagically.


# when the monetdb server runs, my computer shows:

# MonetDB 5 server v11.15.7 "Feb2013-SP2"
# Serving database 'nppes', using 8 threads
# Compiled for x86_64-pc-winnt/64bit with 64bit OIDs dynamically linked
# Found 7.860 GiB available main-memory.
# Copyright (c) 1993-July 2008 CWI.
# Copyright (c) August 2008-2013 MonetDB B.V., all rights reserved
# Visit http://www.monetdb.org/ for further information
# Listening for connection requests on mapi:monetdb://127.0.0.1:50006/
# MonetDB/JAQL module loaded
# MonetDB/SQL module loaded


# notice the dbname and dbport (assigned above during the monetdb configuration)
# get used in this line
monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )

# now put everything together and create a connection to the monetdb server.
db <- dbConnect( MonetDB.R() , monet.url )
# from now on, the 'db' object will be used for r to connect with the monetdb server


# note: slow. slow. slow. #
# the following commands take a while. #
# run them all together overnight if possible. #
# you'll never have to do this again.  hooray! #


# determine the number of lines
# that need to be imported into MonetDB
num.lines <- countLines( csv.file )

# read the first thousand records
# of the csv.file into R
col.check <- read.csv( csv.file , nrow = 1000 )

# determine the field names
fields <- names( col.check )

# convert the field names to lowercase
fields <- tolower( fields )

# remove all `.` characters from field names
fields <- gsub( "." , "_" , fields , fixed = TRUE )

# fields containing the word `code`
# and none of country, state, gender, taxonomy, or postal
# should be numeric types.
# all others should be character types.
colTypes <- 
	ifelse( 
		grepl( "code" , fields ) & !grepl( "country|state|gender|taxonomy|postal" , fields ) , 
		'DOUBLE PRECISION' , 
		'VARCHAR(255)' 
	)

# build a sql string..
colDecl <- paste( fields , colTypes )

# ..to initiate this table in the monet database
sql.create <-
	sprintf(
		paste(
			"CREATE TABLE npi (%s)"
		) ,
		paste(
			colDecl ,
			collapse = ", "
		)
	)

# run the actual MonetDB table creation command
dbSendUpdate( db , sql.create )


# create a read-only input connection..
incon <- file( csv.file , "r" )

# ..and a write-only output connection
outcon <- file( tf2 , "w" )

# loop through every line in the input connection,
# 50,000 lines at a time
while( length( z <- readLines( incon , n = 50000 ) ) > 0 ){

	# replace all double-backslahses with nothing..
	z <- gsub( "\\" , "" , z , fixed = TRUE )
	
	# ..and write the resultant lines
	# to the output file connection
	writeLines( z , outcon )

	# remove the `z` object
	rm( z )
	
	# clear up RAM
	gc()
}

# shut down both file connections
close( incon )
close( outcon )

# confirm that the new temporary file
# contains the same number of records as
# the original csv.file
stopifnot( countLines( tf2 ) == countLines( csv.file ) )

# build a sql COPY INTO command
# that will import the newly-created `tf2`
# into the monet database
sql.update <- 
	paste0( 
		"copy " , 
		num.lines , 
		" offset 2 records into npi from '" , 
		normalizePath( tf2 ) , 
		"' using delimiters ',','\\n','\"' NULL as ''" 
	)

# execute the COPY INTO command
dbSendUpdate( db , sql.update )

# # # # # # # # #
# end of import #
# # # # # # # # #

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )


####################################################################
# lines of code to hold on to for all other nppes monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/NPPES/nppes.bat"

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "nppes"
dbport <- 50006

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url )

# # # # run your analysis commands # # # #


# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other nppes monetdb analyses #
###########################################################################


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
