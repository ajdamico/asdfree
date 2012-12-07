# analyze us government survey data with the r language
# american community survey
# 2005-2011 1-year (plus when available 3-year and 5-year files)
# household-level, person-level, and merged files

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



#####################################################################################
# download all available american community survey files from the census bureau ftp #
# import each file into a monet database, merge the person and household files      #
# create a monet database-backed complex sample sqlsurvey design object with r      #
#####################################################################################


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
# you'll be better off leaving this script to run overnight.  if you wanna download all available files and years,
# leave it running on friday afternoon (or even better: before you leave for a weeklong vacation).
# depending on your internet and processor speeds, the entire script should take between two and ten days.
# it's running.  don't believe me?  check the working directory (set below) for a new r data file (.rda) every few hours.



require(sqlsurvey)		# load sqlsurvey package (analyzes large complex design surveys)


# set your ACS data directory
# after downloading and importing
# all monet database-backed complex survey designs will be stored here
# and the monet database will be stored in the MonetDB folder within
# use forward slashes instead of back slashes

setwd( "C:/My Directory/ACS/" )



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
# so, for example, if you set your current working directory to C:\My Directory\ACS\ above,
# create a new folder C:\My Directory\ACS\MonetDB right now.


# if the MonetDB folder doesn't exist in your current working directory,
# this line will create an error.
stopifnot( file.exists( paste0( getwd() , "/MonetDB" ) ) )


# configure a monetdb database for the acs on windows #

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
		# this will change for different datasets -- for the basic stand alone public use file, just use acs
		dbname = "acs" ,
		
		# choose which port 
		dbport = 50001
	)


# this next step is so very important.

# store a line of code that will make it easy to open up the monetdb server in the future.
# this should contain the same file path as the "bat.file.location" parameter above,
# but don't simply copy the "paste0( getwd() , "\\MonetDB\\monetdb.bat" )" here,
# because if your current working directory changes at other points, you don't want this line to change.
# you're best bet is to actually look at your local disk to find the full filepath of the executable (.bat) file.
# if it's stored in C:\My Directory\ACS\MonetDB\monetdb.bat
# then your shell.exec line should be:


shell.exec( "C:/My Directory/ACS/MonetDB/monetdb.bat" )


# hold on to that line for future scripts.
# you need to run this line *every time* you access
# the basic stand alone public use files with monetdb.
# this is the monetdb server.

# two other things you need: the database name and the database port.
# store them now for later in this script, but hold on to them for other scripts as well
dbname <- "acs"
dbport <- 50001


# hey try running it now!  a shell window should pop up.
# when it runs, my computer shows:

# MonetDB 5 server v11.13.5 "Oct2012-SP1"
# Serving database 'acs', using 2 threads
# Compiled for x86_64-pc-winnt/64bit with 64bit OIDs dynamically linked
# Found 15.873 GiB available main-memory.
# Copyright (c) 1993-July 2008 CWI.
# Copyright (c) August 2008-2012 MonetDB B.V., all rights reserved
# Visit http://www.monetdb.org/ for further information
# Listening for connection requests on mapi:monetdb://127.0.0.1:50001/
# MonetDB/JAQL module loaded
# MonetDB/SQL module loaded

# if that shell window is not open, monetdb commands will not work.  period.


# give the shell window ten seconds to load.
Sys.sleep( 10 )


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



# choose which acs data sets to download: single-, three-, or five-year
# if you have a big hard drive, hey why not download them all?

# single-year datasets are available back to 2005
single.year.datasets.to.download <- 2005:2011
	
# three-year datasets are available back to 2007
three.year.datasets.to.download <- 2007:2011

# five-year datasets are available back to 2009
five.year.datasets.to.download <- 2009:2010

# # # # # # # # # # # # # #
# other download examples #
# # # # # # # # # # # # # #

# uncomment these lines to only download the 2011 single-year file and no others
# single.year.datasets.to.download <- 2011
# three.year.datasets.to.download <- NULL
# five.year.datasets.to.download <- NULL

# uncomment these lines to only download the 2005 one-year file, the 2007 one- and three-year files, and all of the 2009 files
# single.year.datasets.to.download <- c( 2005 , 2007 , 2009 )
# three.year.datasets.to.download <- c( 2007 , 2009 )
# five.year.datasets.to.download <- 2009


	
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


# loop through each possible acs year
for ( year in 2050:2005 ){

	# loop through each possible acs dataset size category
	for ( size in c( 1 , 3 , 5 ) ){
	
		# create a new variable 'years.for.this.size' containing all the years that should be downloaded
		# for the states size category
		if ( size == 1 ) years.for.this.size <- single.year.datasets.to.download
		if ( size == 3 ) years.for.this.size <- three.year.datasets.to.download
		if ( size == 5 ) years.for.this.size <- five.year.datasets.to.download
		
		# ..and if the current year is in the 'years.for.this.size vector, start the download
		# all download commands are contained within this loop
		if ( year %in% years.for.this.size ){
			
			# construct the database name
			k <- paste0( "acs" , year , "_" , size , "yr" )
			
			# construct the path on the census ftp site containing the state tables
			if ( year < 2007 ){
			
				# 2005 - 2006 files were stored somewhere..
				ftp.path <- paste0( 'http://www2.census.gov/acs/downloads/pums/' , year , '/' )
				
			} else {
			
				# 2007+ files were stored somewhere else..
				ftp.path <- paste0( "http://www2.census.gov/" , k , "/pums/" )
				
			}

			# loop through both household- and person-level files
			for ( j in c( 'h' , 'p' ) ){			
				
				# create a character string containing the http location of the zipped csv file to be downloaded
				ACS.file.location <-
					paste0( 
						ftp.path ,
						"csv_" ,
						j ,
						"us.zip"
					)
				
				# try downloading the file three times before breaking
				
				# store a command: "download the ACS zipped file to the temporary file location"
				download.command <- expression( download.file( ACS.file.location , tf , mode = "wb" ) )

				# try the download immediately.
				# run the above command, using error-handling.
				download.error <- tryCatch( eval( download.command ) , silent = T )
				
				# if the download results in an error..
				if ( class( download.error ) == 'try-error' ) {
				
					# wait 3 minutes..
					Sys.sleep( 3 * 60 )
					
					# ..and try the download a second time
					download.error <- tryCatch( eval( download.command ) , silent = T )
				}
				
				# if the download results in a second error..
				if ( class( download.error ) == 'try-error' ) {

					# wait 3 more minutes..
					Sys.sleep( 3 * 60 )
					
					# ..and try the download a third time.
					# but this time, if it fails, crash the program with a download error
					eval( download.command )
				}
				
				# once the download has completed..
				
				# unzip the file's contents to the temporary directory
				fn <- unzip( tf , exdir = td , overwrite = T )
				
				
				# delete all the files that do not include the text 'csv' in their filename
				file.remove( fn[ !grepl( 'csv' , fn ) ] )
				
				
				# limit the files to read in to ones containing csvs
				fn <- fn[ grepl( 'csv' , fn ) ]

				
				# there's a few weird "01E4" strings in the 2007 single- and three-year household files
				# that cause the monetdb importation lines to crash.
				# this block manually recodes "01E4" to 10,000 in the source csv files.
				if ( year == 2007 & j == 'h' ){
				
					# create a temporary file
					tf07 <- tempfile()

					# open a read-only file connection to the 'ss07husa.csv' table
					incon <- file( fn[1] , 'r' )
					
					# open a writable file connection to the temporary file
					outcon <- file( tf07 , 'w' )

					# read through every line in the ss07husa.csv table
					while( length( x <- readLines( incon , 1 ) ) > 0 ) {
						# replace that 01E4 (which represents 1 x 10^4) with the numeric value 10,000
						x <- gsub( "01E4" , "10000" , x )
						# write them all to the temporary file
						writeLines( x , outcon )
					}

					# close both file connections
					close( incon )
					close( outcon )
					
					# replace the first element of the 'fn' vector (which should be ss07husa.csv)
					# with the file path to the temporary file instead
					fn[1] <- tf07
				}


				# create the table name
				tablename <- paste0( k , '_' , j )
			

				# initiate the table in the database using any of the csv files #
				csvpath <- fn[ 1 ]
			
				# read in the first five hundred records of the csv file
				headers <- read.csv( csvpath , nrows = 500 )
				
				# figure out the column type (class) of each column
				cl <- sapply( headers , class )
				
				# convert all column names to lowercase
				names( headers ) <- tolower( names( headers ) )
				
				# if one of the column names is the word 'type'
				# change it to 'type_' -- monetdb doesn't like columns called 'type'
				if ( 'type' %in% tolower( names( headers ) ) ){
					print( "warning: column name 'type' unacceptable in monetdb.  changing to 'type_'" )
					names( headers )[ names( headers ) == 'type' ] <- 'type_'
				}
				
				# the american community survey data only contains integers and character strings..
				# so store integer columns as numbers and all others as characters
				# note: this won't work on other data sets, since they might have columns with non-integers (decimals)
				colTypes <- ifelse( cl == 'integer' , 'INT' , 'VARCHAR(255)' )
				
				# create a character vector grouping each column name with each column type..
				colDecl <- paste( names( headers ) , colTypes )

				# ..and then construct an entire 'create table' sql command
				sql <-
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
				
				# actually execute the 'create table' sql command
				dbSendUpdate( db , sql )

				# end of initiating the table in the database #
				
				# loop through each csv file
				for ( csvpath in fn ){
				
					
					# quickly figure out the number of lines in the data file
					# code thanks to 
					# http://costaleconomist.blogspot.com/2010/02/easy-way-of-determining-number-of.html

					# in speed tests, increasing this chunk_size does nothing
					chunk_size <- 1000
					testcon <- file( csvpath ,open = "r" )
					nooflines <- 0
					( while( ( linesread <- length( readLines( testcon , chunk_size ) ) ) > 0 )
					nooflines <- nooflines + linesread )
					close( testcon )
				
					
					
					# now try to copy the current csv file into the database
					first.attempt <-
						try( {
							dbSendUpdate( 
								db , 
								paste0( 
									"copy " , 
									nooflines , 
									" offset 2 records into " , 
									tablename , 
									" from '" , 
									normalizePath( csvpath ) , 
									"' using delimiters ',','\\n','\"'  NULL AS ''" 
								) 
							) 
						} , silent = TRUE )
					
					
					# some of the acs files have multiple values that should be treated as NULL, (like acs2010_3yr_p)
					# so if the above copy-into attempt failed, scan through the entire file and remove every instance of "N.A."
					# then re-run the copy-into line.
					
					# if the first attempt doesn't work..
					if ( class( first.attempt ) == 'try-error' ){
						
						# create a temporary output file
						fpo <- tempfile()

						# create a read-only file connection from the original file
						fpx <- file( normalizePath( csvpath ) , 'r' )
						# create a write-only file connection to the temporary file
						fpt <- file( fpo , 'w' )

						# loop through every line in the original file..
						while ( length( line <- readLines( fpx , 1 ) ) > 0 ){
						
							# replace 'N.A.' with nothings..
							line <- gsub( "N.A." , "" , line , fixed = TRUE )
							
							# and write the result to the temporary file connection
							writeLines( line , fpt )
						}
						
						# close the temporary file connection
						close( fpt )
						
						# re-run the copy into command..
						dbSendUpdate( 
								db , 
								paste0( 
									"copy " , 
									nooflines , 
									" offset 2 records into " , 
									tablename , 
									" from '" , 
									fpo , 						# only this time, use the temporary file as the source file
									"' using delimiters ',','\\n','\"'  NULL AS ''" 
								) 
						) 
						
						# delete the temporary file from the disk
						file.remove( fpo )
					}

					
					# erase the first.attempt object (which stored the result of the original copy-into line)
					first.attempt <- NULL
					
					
					
					# these files require lots of temporary disk space,
					# so delete them once they're part of the database
					file.remove( csvpath )
				}
				
			}
			
			
			############################################
			# create a merged (household+person) table #
			
			# figure out the fields to keep
			
			# pull all fields from the person..
			pfields <- names( dbGetQuery( db , paste0( "select * from " , k , "_p limit 1") ) )
			# ..and household tables
			hfields <- names( dbGetQuery( db , paste0( "select * from " , k , "_h limit 1") ) )
			
			# then throw fields out of the person file that match fields in the household table
			pfields <- pfields[ !( pfields %in% hfields ) ]
			# and also throw out the 'rt' field from the household table
			hfields <- hfields[ hfields != 'rt' ]
			
			# construct a massive join statement		
			i.j <-
				paste0(
					"create table " ,					# create table statement
					k , "_m as select " ,				# select from statement
					"'M' as rt, " ,
					paste( paste0( 'a.' , hfields ) , collapse = ", " ) ,
					", " ,
					paste( pfields , collapse = ", " ) ,
					" from " , k , "_h as a inner join " , k , "_p as b " ,
					"on a.serialno = b.serialno with data" 
				)
			
			
			# disconnect from..
			dbDisconnect( db )
			# ..and reconnect to the database
			db <- dbConnect( drv , monet.url , user = "monetdb" , password = "monetdb" )

			# create the merged table
			dbSendUpdate( db , i.j )
			
			# add columns named 'one' to each table..
			dbSendUpdate( db , paste0( 'alter table ' , k , '_p add column one int' ) )
			dbSendUpdate( db , paste0( 'alter table ' , k , '_h add column one int' ) )
			dbSendUpdate( db , paste0( 'alter table ' , k , '_m add column one int' ) )

			# ..and fill them all with the number 1.
			dbSendUpdate( db , paste0( 'UPDATE ' , k , '_p SET one = 1' ) )
			dbSendUpdate( db , paste0( 'UPDATE ' , k , '_h SET one = 1' ) )
			dbSendUpdate( db , paste0( 'UPDATE ' , k , '_m SET one = 1' ) )
					
			# add a column called 'idkey' containing the row number
			dbSendUpdate( db , paste0( 'alter table ' , k , '_p add column idkey int auto_increment' ) )
			dbSendUpdate( db , paste0( 'alter table ' , k , '_h add column idkey int auto_increment' ) )
			dbSendUpdate( db , paste0( 'alter table ' , k , '_m add column idkey int auto_increment' ) )
			
			
			# now the current database contains three tables more tables than it did before
				# _h (household)
				# _p (person)
				# _m (merged)
			print( paste( "the database now contains tables for" , k ) )
			print( dbListTables( db ) )

			# confirm that the merged file has the same number of records as the person file
			stopifnot( 
				dbGetQuery( db , paste0( "select count(*) as count from " , k , "_p" ) ) == 
				dbGetQuery( db , paste0( "select count(*) as count from " , k , "_m" ) )
			)
			
			# disconnect from..
			dbDisconnect( db )
			# ..and reconnect to the database
			db <- dbConnect( drv , monet.url , user = "monetdb" , password = "monetdb" )

			
			# create a sqlrepsurvey complex sample design object
			# using the merged (household+person) table
			
			acs.m.design <- 									# name the survey object
				sqlrepsurvey(									# sqlrepdesign function call.. type ?sqlrepdesign for more detail
					weight = 'pwgtp' , 							# person-level weights are stored in column "pwgtp"
					repweights = paste0( 'pwgtp' , 1:80 ) ,		# the acs contains 80 replicate weights, pwgtp1 - pwgtp80.  this [0-9] format captures all numeric values
					scale = 4 / 80 ,
					rscales = rep( 1 , 80 ) ,
					mse = TRUE ,
					table.name = paste0( k , '_m' ) , 			# use the person-household-merge data table
					key = "idkey" ,
					# check.factors = 10 ,						# defaults to ten
					database = monet.url ,
					driver = drv ,
					user = "monetdb" ,
					password = "monetdb" 
				)

			# create a sqlrepsurvey complex sample design object
			# using the household-level table

			acs.h.design <- 									# name the survey object
				sqlrepsurvey(									# sqlrepdesign function call.. type ?sqlrepdesign for more detail
					weight = 'wgtp' , 							# household-level weights are stored in column "wgtp"
					repweights = paste0( 'wgtp' , 1:80 ) ,		# the acs contains 80 replicate weights, wgtp1 - wgtp80.  this [0-9] format captures all numeric values
					scale = 4 / 80 ,
					rscales = rep( 1 , 80 ) ,
					mse = TRUE ,
					table.name = paste0( k , '_h' ) , 			# use the household-level data table
					key = "idkey" ,
					# check.factors = 10 ,						# defaults to ten
					database = monet.url ,
					driver = drv ,
					user = "monetdb" ,
					password = "monetdb" 
				)

			# save both complex sample survey designs
			# into a single r data file (.rda) that can now be
			# analyzed quicker than anything else.
			save( acs.m.design , acs.h.design , file = paste0( k , '.rda' ) )
						
		}
	}
}


# the current working directory should now contain one r data file (.rda)
# for each monet database-backed complex sample survey design object
# for each year specified and for each size (one, three, and five year) specified


# once complete, this script does not need to be run again.
# instead, use one of the american community survey analysis scripts
# which utilize these newly-created survey objects


# the current monet database should now contain
# all of the newly-added tables (in addition to meta-data tables)
dbListTables( db )		# print the tables stored in the current monet database to the screen


# disconnect from the current monet database
dbDisconnect( db )


##################################################################
# lines of code to hold on to for all other acs monetdb analyses #

# first: your shell.exec() function.  again, mine looks like this:
shell.exec( "C:/My Directory/ACS/MonetDB/monetdb.bat" )

# second: add a ten second system sleep in between the shell.exec() function
# and the database connection lines.  this gives your local computer a chance
# to get monetdb up and running.
Sys.sleep( 10 )

# third: your six lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "acs"
dbport <- 50001
monetdriver <- "c:/program files/monetdb/monetdb5/monetdb-jdbc-2.7.jar"
drv <- MonetDB( classPath = monetdriver )
monet.url <- paste0( "jdbc:monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( drv , monet.url , user = "monetdb" , password = "monetdb" )

# end of lines of code to hold on to for all other acs monetdb analyses #
#########################################################################


# unlike most post-importation scripts, the monetdb directory cannot be set to read-only #
winDialog( 'ok' , paste( "all done.  DO NOT set" , getwd() , "read-only or subsequent scripts will not work." ) )

winDialog( 'ok' , "got that? monetdb directories should not be set read-only." )


# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
