# analyze survey data for free (http://asdfree.com) with the r language
# behavioral risk factor surveillance system
# 1984-2013 single-year files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( "monetdb.sequential" = TRUE )
# library(downloader)
# setwd( "C:/My Directory/BRFSS/" )
# years.to.download <- 1984:2013
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Behavioral%20Risk%20Factor%20Surveillance%20System/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
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
# download all available behavioral risk factor surveillance system files from the #
# centers for disease control and prevention (cdc) website, then import each file  #
# into a monet database, and create a monet database-backed complex sample         #
# sqlsurvey design object with r                                                   #
####################################################################################


# # # # # # # # # # # # # # #
# warning: monetdb required #
# # # # # # # # # # # # # # #


# windows machines and also machines without access
# to large amounts of ram will often benefit from
# the following option, available as of MonetDB.R 0.9.2 --
# remove the `#` in the line below to turn this option on.
# options( "monetdb.sequential" = TRUE )
# -- whenever connecting to a monetdb server,
# this option triggers sequential server processing
# in other words: single-threading.
# if you would prefer to turn this on or off immediately
# (that is, without a server connect or disconnect), use
# turn on single-threading only
# dbSendQuery( db , "set optimizer = 'sequential_pipe';" )
# restore default behavior -- or just restart instead
# dbSendQuery(db,"set optimizer = 'default_pipe';")

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



library(sqlsurvey)		# load sqlsurvey package (analyzes large complex design surveys)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(foreign) 		# load foreign package (converts data files into R)
library(downloader)		# downloads and then runs the source() function on scripts from github

# set your BRFSS data directory
# after downloading and importing
# all monet database-backed complex survey designs will be stored here
# and the monet database will be stored in the MonetDB folder within
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/BRFSS/" )


# load the download.cache and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url( 
	"https://raw.github.com/ajdamico/usgsd/master/Download%20Cache/download%20cache.R" , 
	prompt = FALSE , 
	echo = FALSE 
)

# load the read.SAScii.monetdb() function,
# which imports ASCII (fixed-width) data files directly into a monet database
# using only a SAS importation script
source_url( "https://raw.github.com/ajdamico/usgsd/master/MonetDB/read.SAScii.monetdb.R" , prompt = FALSE )


# configure a monetdb database for the brfss on windows #

# note: only run this command once.  this creates an executable (.bat) file
# in the appropriate directory on your local disk.
# when adding new files or adding a new year of data, this script does not need to be re-run.

# create a monetdb executable (.bat) file for the behavioral risk factor surveillance system
batfile <-
	monetdb.server.setup(
					
					# set the path to the directory where the initialization batch file and all data will be stored
					database.directory = paste0( getwd() , "/MonetDB" ) ,
					# must be empty or not exist

					# find the main path to the monetdb installation program
					monetdb.program.path = 
						ifelse( 
							.Platform$OS.type == "windows" , 
							"C:/Program Files/MonetDB/MonetDB5" , 
							"" 
						) ,
					# note: for windows, monetdb usually gets stored in the program files directory
					# for other operating systems, it's usually part of the PATH and therefore can simply be left blank.
										
					# choose a database name
					dbname = "brfss" ,
					
					# choose a database port
					# this port should not conflict with other monetdb databases
					# on your local computer.  two databases with the same port number
					# cannot be accessed at the same time
					dbport = 50004
	)

	
# this next step is so very important.

# store a line of code that will make it easy to open up the monetdb server in the future.
# this should contain the same file path as the batfile created above,
# you're best bet is to actually look at your local disk to find the full filepath of the executable (.bat) file.
# if you ran this script without changes, the batfile will get stored in C:\My Directory\BRFSS\MonetDB\brfss.bat

# here's the batfile location:
batfile

# note that since you only run the `monetdb.server.setup()` function the first time this script is run,
# you will need to note the location of the batfile for future MonetDB analyses!

# in future R sessions, you can create the batfile variable with a line like..
# batfile <- "C:/My Directory/BRFSS/MonetDB/brfss.bat"
# obviously, without the `#` comment character

# hold on to that line for future scripts.
# you need to run this line *every time* you access
# the behavioral risk factor surveillance system files with monetdb.
# this is the monetdb server.

# two other things you need: the database name and the database port.
# store them now for later in this script, but hold on to them for other scripts as well
dbname <- "brfss"
dbport <- 50004

# now the local windows machine contains a new executable program at "c:\my directory\brfss\monetdb\brfss.bat"


# it's recommended that after you've _created_ the monetdb server,
# you create a block of code like the one below to _access_ the monetdb server


######################################################################
# lines of code to hold on to for all other `brfss` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/BRFSS/MonetDB/brfss.bat"

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your six lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "brfss"
dbport <- 50004

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )


# # # # run your analysis commands # # # #


# choose which brfss data sets to download
# if you have a big hard drive, hey why not download them all?

# single-year datasets are available back to 1984

# uncomment this line to download all available data sets
# uncomment this line by removing the `#` at the front
# years.to.download <- 1984:2013

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

						
# create three temporary files and a temporary directory..
tf <- tempfile() ; td <- tempdir() ; zf <- tempfile() ; zf2 <- tempfile()

# create a download directory
dir.create( "download" , showWarnings = FALSE )


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
	download.cache( fn , tf , mode = 'wb' )
	
	# unzip it within the temporary directory on your local hard drive and
	# store the location it's been unzipped into a new character string variable called local.fn
	local.fn <- unzip( tf , exdir = "download" )
	
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
	
	# store the names of factor/character variables #
	ctypes <- sapply( x , class )
	charx <- names( x )[ !( ctypes %in% c( 'numeric' , 'integer' ) ) ]
	# create a new object `cYYYY` containing the non-numeric columns
	assign( paste0( 'c' , year ) , charx )
	# end of factor/character variable storage #
	
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
		

		
# the 2002 - 2013 brfss single-year files are too large to be read directly into RAM
# so import them using the read.SAScii.monetdb() function,
# a variant of the SAScii package's read.SAScii() function

# loop through each year specified by the user, so long as it's within the 2002-2013 range
for ( year in intersect( years.to.download , 2002:2013 ) ){

	# remove the temporary file (defined waaaay above) from the local disk, if it exists
	file.remove( tf )
	
	# if the file to download is 2012 or later..
	if ( year >= 2012 ){

		# the zipped filename and sas importation script are here:
		fn <- paste0( "http://www.cdc.gov/brfss/annual_data/" , year , "/files/LLCP" , year , "ASC.ZIP" )
		sas_ri <- paste0( "http://www.cdc.gov/brfss/annual_data/" , year , "/files/SASOUT" , substr( year , 3 , 4 ) , "_LLCP.SAS" )

	# otherwise, if the file to download is 2011..
	} else if ( year == 2011 ){
	
		# the zipped filename and sas importation script are here:
		fn <- "ftp://ftp.cdc.gov/pub/data/brfss/LLCP2011ASC.ZIP"
		sas_ri <- "http://www.cdc.gov/brfss/annual_data/2011/SASOUT11_LLCP.SAS"
		
	# otherwise..
	} else {
	
		# the zipped filename and sas importation script fit this pattern:
		fn <- paste0( "ftp://ftp.cdc.gov/pub/data/brfss/cdbrfs" , ifelse( year == 2002 , year , substr( year , 3 , 4 ) ) , "asc.zip" )
		sas_ri <- paste0( "http://www.cdc.gov/brfss/annual_data/" , year , "/sasout" , substr( year , 3 , 4 ) , ".SAS" )
		
	}

	# read the entire sas importation script into memory
	z <- readLines( sas_ri )

	# throw out a few columns that cause importation trouble with monetdb
	if ( year == 2009 ) z <- z[ -159:-168 ]
	if ( year == 2011 )	z <- z[ !grepl( "CHILDAGE" , z ) ]
	if ( year == 2013 ) z[ 361:362 ] <- c( "_FRTLT1z       2259" , "_VEGLT1z       2260" )


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

	# download the zipped file
	download.cache( fn , zf , mode = 'wb' )
	
	#unzip the file's contents and store the file name within the temporary directory
	local.fn <- unzip( zf , exdir = 'download' , overwrite = T )
	
	# if it's 2013..
	if ( year == 2013 ){
		
		# create a read connection..
		incon <- file( local.fn , "r")
		
		# ..and a write connection
		outcon <- file( zf2 , "w" )
	
		# read through every line
		while( length( line <- readLines( incon , 1 , skipNul = TRUE ) ) > 0 ){
		
			# remove the stray slash
			line <- gsub( "\\" , " " , line , fixed = TRUE )
			
			# remove the stray everythings
			line <- gsub( "[^[:alnum:]///' \\.]" , " " , line )
			line <- iconv( line , "" , "ASCII" , sub = " " )
			
			# write the result to the output connection
			writeLines( line , outcon )
			
		}
		
		# remove the original
		file.remove( local.fn )
		
		# redirect the local filename to the new file
		local.fn <- zf2
		
		# close both connections
		close( outcon )
		close( incon )
		
	}
	
	# actually run the read.SAScii.monetdb() function
	# and import the current fixed-width file into the monet database
	read.SAScii.monetdb (
		local.fn ,
		tf ,
		beginline = 70 ,
		zipped = F ,						# the ascii file is no longer stored in a zipped file
		tl = TRUE ,							# convert all column names to lowercase
		tablename = paste0( 'b' , year ) ,	# the table will be stored in the monet database as bYYYY.. for example, 2010 will be stored as the 'b2010' table
		connection = db
	)
	
	# store the names of factor/character variables #
	psas <- parse.SAScii( tf )
	charx <- tolower( psas[ psas$char %in% T , 'varname' ] )
	# create a new object `cYYYY` containing the non-numeric columns
	assign( paste0( 'c' , year ) , charx )
	# end of factor/character variable storage #
	
	# repeat.
}

# create a data frame containing all weight, psu, and stratification variables for each year
survey.vars <-
	data.frame(
		year = 1984:2013 ,
		weight = c( rep( 'x_finalwt' , 10 ) , rep( 'xfinalwt' , 17 ) , rep( 'xllcpwt' , 3 ) ) ,
		psu = c( rep( 'x_psu' , 10 ) , rep( 'xpsu' , 20 ) ) ,
		strata = c( rep( 'x_ststr' , 10 ) , rep( 'xststr' , 20 ) )
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
			weight = weight ,									# weight variable column (defined in the character string above)
			nest = TRUE ,										# whether or not psus are nested within strata
			strata = strata ,									# stratification variable column (defined in the character string above)
			id = psu ,											# sampling unit column (defined in the character string above)
			table.name = tablename ,							# table name within the monet database (defined in the character string above)
			key = "idkey" ,										# sql primary key column (created with the auto_increment line above)
			check.factors = get( paste0( 'c' , year ) ) ,		# character vector containing all factor columns for this year
			database = monet.url ,								# monet database location on localhost
			driver = MonetDB.R()
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

# and close it using the `pid`
monetdb.server.stop( pid )




######################################################################
# lines of code to hold on to for all other `brfss` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/BRFSS/MonetDB/brfss.bat"

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "brfss"
dbport <- 50004

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )


# # # # run your analysis commands # # # #


# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other `brfss` monetdb analyses #
#############################################################################


# unlike most post-importation scripts, the monetdb directory cannot be set to read-only #
message( paste( "all done.  DO NOT set" , getwd() , "read-only or subsequent scripts will not work." ) )

message( "got that? monetdb directories should not be set read-only." )


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



