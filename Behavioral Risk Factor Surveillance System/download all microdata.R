# analyze survey data for free (http://asdfree.com) with the r language
# behavioral risk factor surveillance system
# 1984-2014 single-year files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# setInternet2( FALSE )						# # only windows users need this line
# options( encoding = "windows-1252" )		# # only macintosh and *nix users need this line
# library(downloader)
# setwd( "C:/My Directory/BRFSS/" )
# years.to.download <- 1984:2014
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Behavioral%20Risk%20Factor%20Surveillance%20System/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com



####################################################################################
# download all available behavioral risk factor surveillance system files from the #
# centers for disease control and prevention (cdc) website, then import each file  #
# into a monet database, and create a monet database-backed survey object with r   #
####################################################################################


# # # are you on a windows system? # # #
if ( .Platform$OS.type == 'windows' ) print( 'windows users: read this block' )
# you might need to change your internet connectivity settings
# using this next line -
# setInternet2( FALSE )
# - will change the download method of your R console
# however, if you have already downloaded anything
# in the same console, the `setInternet2( TRUE )`
# setting will be unchangeable in that R session
# so make sure you are using a fresh instance
# of your windows R console before designating
# setInternet2( FALSE )


# # # # # # # # # # # # # # # #
# warning: this takes a while #
# # # # # # # # # # # # # # # #

# even if you're only downloading a single year of data and you've got a fast internet connection,
# you'll be better off leaving this script to run overnight.  if you wanna download all available years,
# leave it running on friday afternoon (or even better: before you leave for a weeklong vacation).
# depending on your internet and processor speeds, the entire script should take between two and ten days.
# it's running.  don't believe me?  check the working directory (set below) for a new r data file (.rda) every few hours.


# remove the # in order to run this install.packages line only once
# install.packages( c("MonetDB.R", "MonetDBLite" , "survey" , "SAScii" , "descr" , "downloader" , "digest" ) )


library(survey)			# load survey package (analyzes complex design surveys)
library(DBI)			# load the DBI package (implements the R-database coding)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(MonetDBLite)	# load MonetDBLite package (creates database files in R)
library(foreign) 		# load foreign package (converts data files into R)
library(downloader)		# downloads and then runs the source() function on scripts from github
library(R.utils)		# load the R.utils package (counts the number of lines in a file quickly)


# set your BRFSS data directory
# after downloading and importing
# all monet database-backed complex survey designs will be stored here
# and the monet database will be stored in the MonetDB folder within
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/BRFSS/" )


# # # are you on a non-windows system? # # #
if ( .Platform$OS.type != 'windows' ) print( 'non-windows users: read this block' )
# the cdc's ftp site has a few SAS importation
# scripts in a non-standard format
# if so, before running this whole download program,
# you might need to run this line..
# options( encoding="windows-1252" )
# ..to turn on windows-style encoding.
# # # end of non-windows system edits.


# load the download_cached and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url( 
	"https://raw.githubusercontent.com/ajdamico/asdfree/master/Download%20Cache/download%20cache.R" , 
	prompt = FALSE , 
	echo = FALSE 
)

# load the read.SAScii.monetdb() function,
# which imports ASCII (fixed-width) data files directly into a monet database
# using only a SAS importation script
source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/MonetDB/read.SAScii.monetdb.R" , prompt = FALSE )




# choose which brfss data sets to download
# if you have a big hard drive, hey why not download them all?

# single-year datasets are available back to 1984

# uncomment this line to download all available data sets
# uncomment this line by removing the `#` at the front
# years.to.download <- 1984:2014

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


# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )

# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite() , dbfolder )

# create a download directory
dir.create( "download" , showWarnings = FALSE )


# the 1984 - 2001 brfss single-year files are small enough to be read directly into RAM
# even on smaller, older personal computers with 4 gigabytes of RAM
# so take a shortcut for these files and simply download them using
# the read.xport() function from the foreign package
dlfile <- tempfile()
csvfile <- tempfile()

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
	download_cached( fn , dlfile , mode = 'wb' )
	
	# unzip it within the temporary directory on your local hard drive and
	# store the location it's been unzipped into a new character string variable called local.fn
	local.fn <- unzip( dlfile , exdir = "download" )
	
	# read the sas transport file into r
	x <- read.xport( local.fn ) 
	
	# convert all column names in the table to all lowercase
	names( x ) <- tolower( names( x ) )
	
	# do not allow this illegal sql column name
	names( x )[ names( x ) == 'level' ] <- 'level_'
	
	# immediately export the data table to a comma separated value (.csv) file,
	# also stored on the local hard drive
	write.csv( x , csvfile , row.names = FALSE )

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
	first.attempt <- try( monet.read.csv( db , csvfile , tablename , na.strings = "NA" , nrow.check = rtctr , lower.case.names = TRUE ) , silent = TRUE )
	
	# if the monet.read.csv() function returns an error instead of working properly..
	if( class( first.attempt ) == "try-error" ) {
	
		# try re-exporting the csv file (overwriting the original csv file)
		# using "" for the NA strings
		write.csv( x , csvfile , row.names = FALSE , na = "" )
		
		# try to remove the data table from the monet database
		try( dbRemoveTable( db , tablename ) , silent = TRUE )
		
		# and re-try reading the csv file directly into the monet database, this time with a different NA string setting
		second.attempt <-
			try( monet.read.csv( db , csvfile , tablename , na.strings = "" , nrow.check = rtctr , lower.case.names = TRUE ) , silent = TRUE )
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
		dbSendQuery( db , sql.create )
		
		# now build the sql command that will copy all records from the csv file (still on the local hard disk)
		# into the monet database, using the structure that's just been defined by the sql.create object above
		sql.update <- 
			paste0( 
				"copy " , 
				rtctr , 
				" offset 2 records into " , 
				tablename , 
				" from '" , 
				csvfile , 
				"' using delimiters ',' null as ''" 
			)
			
		# run the sql command
		dbSendQuery( db , sql.update )
			
	}
		
	# free up RAM
	rm( x )
	gc()

	# repeat.
}
		

		
# the 2002 - 2014 brfss single-year files are too large to be read directly into RAM
# so import them using the read.SAScii.monetdb() function,
# a variant of the SAScii package's read.SAScii() function

impfile <- tempfile()
sasfile <- tempfile()

# loop through each year specified by the user, so long as it's within the 2002-2014 range
for ( year in intersect( years.to.download , 2002:2014 ) ){


	# if the file to download is 2012 or later..
	if ( year >= 2012 ){

		# the zipped filename and sas importation script are here:
		fn <- paste0( "http://www.cdc.gov/brfss/annual_data/" , year , "/files/LLCP" , year , "ASC.ZIP" )
		sas_ri <- paste0( "http://www.cdc.gov/brfss/annual_data/" , year , "/files/sasout" , substr( year , 3 , 4 ) , "_llcp.sas" )

	# otherwise, if the file to download is 2011..
	} else if ( year == 2011 ){
	
		# the zipped filename and sas importation script are here:
		fn <- "ftp://ftp.cdc.gov/pub/data/brfss/LLCP2011ASC.ZIP"
		sas_ri <- "http://www.cdc.gov/brfss/annual_data/2011/sasout11_llcp.sas"
		
	# otherwise..
	} else {
	
		# the zipped filename and sas importation script fit this pattern:
		fn <- paste0( "ftp://ftp.cdc.gov/pub/data/brfss/cdbrfs" , ifelse( year == 2002 , year , substr( year , 3 , 4 ) ) , "asc.zip" )
				
		sas_ri <- 
			paste0( 
				"http://www.cdc.gov/brfss/annual_data/" , 
				year , 
				"/files/sasout" , substr( year , 3 , 4 ) , 
				ifelse( year > 2006 , ".SAS" , ".sas" )
			)

		
	}

	# read the entire sas importation script into memory
	z <- readLines( sas_ri )

	# throw out a few columns that cause importation trouble with monetdb
	if ( year == 2009 ) z <- z[ -159:-168 ]
	if ( year == 2011 )	z <- z[ !grepl( "CHILDAGE" , z ) ]
	if ( year == 2013 ) z[ 361:362 ] <- c( "_FRTLT1z       2259" , "_VEGLT1z       2260" )
	if ( year == 2014 ) z[ 86 ] <- "COLGHOUS $ 64"

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
	writeLines( z , impfile )

	# download the zipped file
	download_cached( fn , dlfile , mode = 'wb' )
	
	#unzip the file's contents and store the file name within the temporary directory
	local.fn <- unzip( dlfile , exdir = 'download' , overwrite = T )
	
	# if it's 2013 or beyond..
	if ( year >= 2013 ){
		
		# create a read connection..
		incon <- file( local.fn , "r")
		
		# ..and a write connection
		outcon <- file( sasfile , "w" )
	
		# read through every line
		while( length( line <- readLines( incon , 1 , skipNul = TRUE ) ) > 0 ){
		
			# remove the stray slash
			line <- gsub( "\\" , " " , line , fixed = TRUE )
			
			# remove the stray everythings
			line <- gsub( "[^[:alnum:]///' \\.]" , " " , line )
			
			# mac/unix converts some weird characters to two digits
			# while windows convers the to one.  deal with it.
			line <- iconv( line , "" , "ASCII" , sub = "abcxyz" )
			line <- gsub( "abcxyzabcxyz" , " " , line )
			line <- gsub( "abcxyz" , " " , line )
	
			# write the result to the output connection
			writeLines( line , outcon )
			
		}
		
		# remove the original
		file.remove( local.fn )
		
		# redirect the local filename to the new file
		local.fn <- sasfile
		
		# close both connections
		close( outcon )
		close( incon )
		
	}
	
	# actually run the read.SAScii.monetdb() function
	# and import the current fixed-width file into the monet database
	read.SAScii.monetdb (
		local.fn ,
		impfile ,
		beginline = 70 ,
		zipped = F ,						# the ascii file is no longer stored in a zipped file
		tl = TRUE ,							# convert all column names to lowercase
		tablename = paste0( 'b' , year ) ,	# the table will be stored in the monet database as bYYYY.. for example, 2010 will be stored as the 'b2010' table
		connection = db
	)
	
	# store the names of factor/character variables #
	psas <- parse.SAScii( impfile )
	charx <- tolower( psas[ psas$char %in% T , 'varname' ] )
	# create a new object `cYYYY` containing the non-numeric columns
	assign( paste0( 'c' , year ) , charx )
	# end of factor/character variable storage #
	# repeat.
}

# create a data frame containing all weight, psu, and stratification variables for each year
survey.vars <-
	data.frame(
		year = 1984:2014 ,
		weight = c( rep( 'x_finalwt' , 18 ) , rep( 'xfinalwt' , 9 ) , rep( 'xllcpwt' , 4 ) ) ,
		psu = c( rep( 'x_psu' , 18 ) , rep( 'xpsu' , 13 ) ) ,
		strata = c( rep( 'x_ststr' , 18 ) , rep( 'xststr' , 13 ) )
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
	strata <- as.formula( paste( "~" , survey.vars[ survey.vars$year == year , 'strata' ] ) )
	psu <- as.formula( paste( "~" , survey.vars[ survey.vars$year == year , 'psu' ] ) )
	weight <- as.formula( paste( "~" , survey.vars[ survey.vars$year == year , 'weight' ] ) )

	# add a column containing all ones to the current table
	dbSendQuery( db , paste0( 'alter table ' , tablename , ' add column one int' ) )
	dbSendQuery( db , paste0( 'UPDATE ' , tablename , ' SET one = 1' ) )
	
	# create a database-backed complex sample design object
	brfss.design <-
		svydesign(
			weight = weight ,									# weight variable column (defined in the character string above)
			nest = TRUE ,										# whether or not psus are nested within strata
			strata = strata ,									# stratification variable column (defined in the character string above)
			id = psu ,											# sampling unit column (defined in the character string above)
			data = tablename ,									# table name within the monet database (defined in the character string above)
			dbtype = "MonetDBLite" ,
			dbname = dbfolder
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


# set every table you've just created as read-only inside the database.
for ( this_table in dbListTables( db ) ) dbSendQuery( db , paste( "ALTER TABLE" , this_table , "SET READ ONLY" ) )


# disconnect from the current monet database
dbDisconnect( db , shutdown = TRUE )




