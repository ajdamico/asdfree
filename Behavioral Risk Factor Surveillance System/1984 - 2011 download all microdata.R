# analyze us government survey data with the r language
# behavioral risk factor surveillance system
# 1984-2011 single-year files

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
# download all available behavioral risk factor surveillance system files from the #
# centers for disease control and prevention (cdc) website, then import each file  #
# into a monet database, and create a monet database-backed complex sample         #
# sqlsurvey design object with r                                                   #
####################################################################################


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


# # # # # # # # # # # # # # # #
# warning: this takes a while #
# # # # # # # # # # # # # # # #

# even if you're only downloading a single year of data and you've got a fast internet connection,
# you'll be better off leaving this script to run overnight.  if you wanna download all available years,
# leave it running on friday afternoon (or even better: before you leave for a weeklong vacation).
# depending on your internet and processor speeds, the entire script should take between two and ten days.
# it's running.  don't believe me?  check the working directory (set below) for a new r data file (.rda) every few hours.



require(sqlsurvey)		# load sqlsurvey package (analyzes large complex design surveys)
require(foreign) 		# load foreign package (converts data files into R)

# set your BRFSS data directory
# after downloading and importing
# all monet database-backed complex survey designs will be stored here
# and the monet database will be stored in the MonetDB folder within
# use forward slashes instead of back slashes

setwd( "C:/My Directory/BRFSS/" )



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

# load the read.SAScii.monetdb() function,
# which imports ASCII (fixed-width) data files directly into a monet database
# using only a SAS importation script
source_https( "https://raw.github.com/ajdamico/usgsd/master/MonetDB/read.SAScii.monetdb.R" )


# create a folder "MonetDB" in your current working directory.
# so, for example, if you set your current working directory to C:\My Directory\BRFSS\ above,
# create a new folder C:\My Directory\BRFSS\MonetDB right now.


# if the MonetDB folder doesn't exist in your current working directory,
# this line will create an error.
stopifnot( file.exists( paste0( getwd() , "/MonetDB" ) ) )


# configure a monetdb database for the brfss on windows #

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
		# this will change for different datasets -- for the basic stand alone public use file, just use brfss
		dbname = "brfss" ,
		
		# choose which port 
		dbport = 50003
	)


# this next step is so very important.

# store a line of code that will make it easy to open up the monetdb server in the future.
# this should contain the same file path as the "bat.file.location" parameter above,
# but don't simply copy the "paste0( getwd() , "\\MonetDB\\monetdb.bat" )" here,
# because if your current working directory changes at other points, you don't want this line to change.
# you're best bet is to actually look at your local disk to find the full filepath of the executable (.bat) file.
# if it's stored in C:\My Directory\BRFSS\MonetDB\monetdb.bat
# then your shell.exec line should be:


shell.exec( "C:/My Directory/BRFSS/MonetDB/monetdb.bat" )


# hold on to that line for future scripts.
# you need to run this line *every time* you access
# the basic stand alone public use files with monetdb.
# this is the monetdb server.

# two other things you need: the database name and the database port.
# store them now for later in this script, but hold on to them for other scripts as well
dbname <- "brfss"
dbport <- 50003


# hey try running it now!  a shell window should pop up.
# when it runs, my computer shows:

# MonetDB 5 server v11.13.5 "Oct2012-SP1"
# Serving database 'brfss', using 2 threads
# Compiled for x86_64-pc-winnt/64bit with 64bit OIDs dynamically linked
# Found 15.873 GiB available main-memory.
# Copyright (c) 1993-July 2008 CWI.
# Copyright (c) August 2008-2012 MonetDB B.V., all rights reserved
# Visit http://www.monetdb.org/ for further information
# Listening for connection requests on mapi:monetdb://127.0.0.1:50003/
# MonetDB/JAQL module loaded
# MonetDB/SQL module loaded

# if that shell window is not open, monetdb commands will not work.  period.


# give the shell window twenty seconds to load.
Sys.sleep( 20 )


# end of monetdb database configuration #


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



# choose which brfss data sets to download
# if you have a big hard drive, hey why not download them all?

# single-year datasets are available back to 1984
years.to.download <- 2005:2011
# pretty orwellian, huh?	

# # # # # # # # # # # # # #
# other download examples #
# # # # # # # # # # # # # #

# uncomment this line to only download the 2011 single-year file and no others
# years.to.download <- 2011

# uncomment this lines to only download the 1994, 2005, 2006, 2007, 2008, and 2009 files
# years.to.download <- c( 1994 , 2005:2009 )


	
###############################################
# DATA LOADING COMPONENT - ONLY RUN THIS ONCE #
###############################################


##########################################
# this entire script is for data-loading #
# and only needs to be run once  #
# for whichever year(s) you need #
##################################

						
#create a temporary file and a temporary directory..
tf <- tempfile() ; td <- tempdir()


# the 1984 - 2001 brfss single-year files are small enough to be read directly into RAM
# even on smaller, older personal computers with 4 gigabytes of RAM
# so take a shortcut for these files and simply download them using
# the read.xport() function from the foreign package

# loop through each year specified by the user, so long as it's within the 1984-2001 range
for ( year in intersect( years.to.download , 1984:2001 ) ){  

	# create a tablename character string variable.. for example: 'b1988'
	tablename <- paste0( 'b' , year )

	
	fn <- 
		# for files before 1990..
		ifelse( year < 1990 , 
			# the file has been stored on the cdc's ftp site with this format
			paste0( "ftp://ftp.cdc.gov/pub/data/Brfss/CDBRFS" , substr( year , 3 , 4 ) , "_XPT.zip" ) ,
			# otherwise, it's stored on the cdc's ftp site with this format
			paste0( "ftp://ftp.cdc.gov/pub/data/Brfss/CDBRFS" , substr( year , 3 , 4 ) , "XPT.zip" ) 
		) 
		
	# download the file from the cdc's ftp site
	download.file( fn , tf , mode = 'wb' )
	
	# unzip it within the temporary directory on your local hard drive and
	# store the location it's been unzipped into a new character string variable called local.fn
	local.fn <- unzip( tf , exdir = td )
	
	# read the sas transport file into r
	x <- read.xport( local.fn ) 
	
	# convert all column names in the table to all lowercase
	names( x ) <- tolower( names( x ) )
	
	# immediately export the data table to a comma separated value (.csv) file,
	# also stored on the local hard drive
	write.csv( x , tf , row.names = FALSE )

	# count the total number of records in the table
	# rows to check then read
	rtctr <- nrow( x )
	
	# prepare to handle errors if they occur (and they do occur)
	# reset all try-error objects
	first.attempt <- second.attempt <- NULL

	# first try to read the csv file into the monet database with NAs for NA strings
	first.attempt <- try( monet.read.csv( db , tf , tablename , nrows = rtctr , na.strings = "NA" , nrow.check = rtctr ) , silent = TRUE )
	
	# if the monet.read.csv() function returns an error instead of working properly..
	if( class( first.attempt ) == "try-error" ) {
	
		# try re-exporting the csv file (overwriting the original csv file)
		# using "" for the NA strings
		write.csv( x , tf , row.names = FALSE , na = "" )
		
		# try to remove the data table from the monet database
		try( dbRemoveTable( db , tablename ) , silent = TRUE )
		
		# and re-try reading the csv file directly into the monet database, this time with a different NA string setting
		second.attempt <-
			try( monet.read.csv( db , tf , tablename , nrows = rtctr , na.strings = "" , nrow.check = rtctr ) , silent = TRUE )
	}

	# if that still doesn't work, import the table manually
	if( class( second.attempt ) == "try-error" ) {
	
		# try to remove the data table from the monet database
		try( dbRemoveTable( db , tablename ) , silent = TRUE )
	
		# determine the class of each element of the brfss data table (it's either numeric or its not)
		colTypes <- 
			ifelse( 
				sapply( x , class ) == 'numeric' , 
				'DOUBLE PRECISION' , 
				'VARCHAR(255)' 
			)
		
		# combine the column names with their respective types,
		# into a single character vector containing every field
		colDecl <- paste( names( x ) , colTypes )

		# build the full sql CREATE TABLE string that will be used
		# to create the data table in the monet database
		sql.create <-
			sprintf(
				paste(
					"CREATE TABLE" ,
					tablename ,
					"(%s)"
				) ,
				paste(
					colDecl ,
					collapse = ", "
				)
			)
		
		# create the table in the database
		dbSendUpdate( db , sql.create )
		
		# now build the sql command that will copy all records from the csv file (still on the local hard disk)
		# into the monet database, using the structure that's just been defined by the sql.create object above
		sql.update <- 
			paste0( 
				"copy " , 
				rtctr , 
				" offset 2 records into " , 
				tablename , 
				" from '" , 
				tf , 
				"' using delimiters ',' null as ''" 
			)
			
		# run the sql command
		dbSendUpdate( db , sql.update )
			
	}
	
	# remove the sas transport file from the local disk
	file.remove ( local.fn )
	
	# free up RAM
	rm( x )
	
	gc()

	# repeat.
}
		

		
# the 2002 - 2011 brfss single-year files are too large to be read directly into RAM
# so import them using the read.SAScii.monetdb() function,
# a variant of the SAScii package's read.SAScii() function

# loop through each year specified by the user, so long as it's within the 2002-2011 range
for ( year in intersect( years.to.download , 2002:2011 ) ){

	# remove the temporary file (defined waaaay above) from the local disk, if it exists
	file.remove( tf )
	
	# if the file to download is 2011..
	if ( year == 2011 ){
	
		# the zipped filename and sas importation script are here:
		fn <- "ftp://ftp.cdc.gov/pub/data/brfss/LLCP2011ASC.ZIP"
		sas_ri <- "http://www.cdc.gov/brfss/technical_infodata/surveydata/2011/SASOUT11_LLCP.SAS"
		
	# otherwise, if the file to download is 2002..
	} else if ( year == 2002 ){
	
		# the zipped filename and sas importation script are here:
		fn <- paste0( "ftp://ftp.cdc.gov/pub/data/brfss/CDBRFS" , year , "ASC.ZIP" )
		sas_ri <- paste0( "http://www.cdc.gov/brfss/technical_infodata/surveydata/" , year , "/SASOUT" , substr( year , 3 , 4 ) , ".SAS" )
	
	# otherwise..
	} else {
	
		# the zipped filename and sas importation script fit this pattern:
		fn <- paste0( "ftp://ftp.cdc.gov/pub/data/brfss/CDBRFS" , substr( year , 3 , 4 ) , "ASC.ZIP" )
		sas_ri <- paste0( "http://www.cdc.gov/brfss/technical_infodata/surveydata/" , year , "/SASOUT" , substr( year , 3 , 4 ) , ".SAS" )
		
	}

	# read the entire sas importation script into memory
	z <- readLines( sas_ri )

	# throw out a few columns that cause importation trouble with monetdb
	if ( year == 2009 ) z <- z[ -159:-168 ]
	if ( year == 2011 )	z <- z[ !grepl( "CHILDAGE" , z ) ]

	# replace all underscores in variable names with x's
	z <- gsub( "_" , "x" , z , fixed = TRUE )
	
	# throw out these three fields, which overlap other fields and therefore are not supported by SAScii
	# (see the details section at the bottom of page 9 of http://cran.r-project.org/web/packages/SAScii/SAScii.pdf for more detail)
	z <- z[ !grepl( "SEQNO" , z ) ]
	z <- z[ !grepl( "IDATE" , z ) ]
	z <- z[ !grepl( "PHONENUM" , z ) ]
	
	# remove all special characters
	z <- gsub( "\t" , " " , z , fixed = TRUE )
	z <- gsub( "\f" , " " , z , fixed = TRUE )
	
	# re-write the sas importation script to a file on the local hard drive
	writeLines( z , tf )

	# actually run the read.SAScii.monetdb() function
	# and import the current fixed-width file into the monet database
	read.SAScii.monetdb (
		fn ,
		tf ,
		beginline = 70 ,
		zipped = T ,						# the ascii file is stored in a zipped file
		tl = TRUE ,							# convert all column names to lowercase
		tablename = paste0( 'b' , year ) ,	# the table will be stored in the monet database as bYYYY.. for example, 2010 will be stored as the 'b2010' table
		connection = db
	)

	# repeat.
}

# create a data frame containing all weight, psu, and stratification variables for each year
survey.vars <-
	data.frame(
		year = 1984:2011 ,
		weight = c( rep( 'x_finalwt' , 10 ) , rep( 'xfinalwt' , 17 ) , 'xllcpwt' ) ,
		psu = c( rep( 'x_psu' , 10 ) , rep( 'xpsu' , 18 ) ) ,
		strata = c( rep( 'x_ststr' , 10 ) , rep( 'xststr' , 18 ) )
	)

# convert all columns in the survey.vars table to character strings,
# except the first
survey.vars[ , -1 ] <- sapply( survey.vars[ , -1 ] , as.character )

# hey why not take a look?
print( survey.vars )


# now loop through every year that's been imported..
for ( year in years.to.download ){

	# create four new variables containing character strings that point to..
	
	# the table name within the monet database
	tablename <- paste0( "b" , year )
	
	# the taylor-series linearization columns used in the complex sample survey design
	strata <- survey.vars[ survey.vars$year == year , 'strata' ]
	psu <- survey.vars[ survey.vars$year == year , 'psu' ]
	weight <- survey.vars[ survey.vars$year == year , 'weight' ]

	# add a column containing all ones to the current table
	dbSendUpdate( db , paste0( 'alter table ' , tablename , ' add column one int' ) )
	dbSendUpdate( db , paste0( 'UPDATE ' , tablename , ' SET one = 1' ) )
	
	# add a column containing the record (row) number
	dbSendUpdate( db , paste0( 'alter table ' , tablename , ' add column idkey int auto_increment' ) )

	# create a sqlsurvey complex sample design object
	brfss.design <-
		sqlsurvey(
			weight = weight ,			# weight variable column (defined in the character string above)
			nest = TRUE ,				# whether or not psus are nested within strata
			strata = strata ,			# stratification variable column (defined in the character string above)
			id = psu ,					# sampling unit column (defined in the character string above)
			table.name = tablename ,	# table name within the monet database (defined in the character string above)
			key = "idkey" ,				# sql primary key column (created with the auto_increment line above)
			# check.factors = 10 ,		# defaults to ten
			database = monet.url ,		# monet database location on localhost
			driver = drv ,				# monet driver location on the local disk
			user = "monetdb" ,			# username
			password = "monetdb" 		# password
		)

	# save the complex sample survey design
	# into a single r data file (.rda) that can now be
	# analyzed quicker than anything else.
	save( brfss.design , file = paste( tablename , 'design.rda' ) )

	# repeat.
}


# the current working directory should now contain one r data file (.rda)
# for each monet database-backed complex sample survey design object
# for each year specified


# once complete, this script does not need to be run again.
# instead, use one of the behavioral risk factor surveillance system
# analysis scripts, which utilize these newly-created survey objects


# the current monet database should now contain
# all of the newly-added tables (in addition to meta-data tables)
dbListTables( db )		# print the tables stored in the current monet database to the screen


# disconnect from the current monet database
dbDisconnect( db )


####################################################################
# lines of code to hold on to for all other brfss monetdb analyses #

# first: your shell.exec() function.  again, mine looks like this:
shell.exec( "C:/My Directory/BRFSS/MonetDB/monetdb.bat" )

# second: add a twenty second system sleep in between the shell.exec() function
# and the database connection lines.  this gives your local computer a chance
# to get monetdb up and running.
Sys.sleep( 20 )

# third: your six lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "brfss"
dbport <- 50003
monetdriver <- "c:/program files/monetdb/monetdb5/monetdb-jdbc-2.7.jar"
drv <- MonetDB( classPath = monetdriver )
monet.url <- paste0( "jdbc:monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( drv , monet.url , user = "monetdb" , password = "monetdb" )

# end of lines of code to hold on to for all other brfss monetdb analyses #
###########################################################################


# unlike most post-importation scripts, the monetdb directory cannot be set to read-only #
winDialog( 'ok' , paste( "all done.  DO NOT set" , getwd() , "read-only or subsequent scripts will not work." ) )

winDialog( 'ok' , "got that? monetdb directories should not be set read-only." )


# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/



