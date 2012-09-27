# analyze us government survey data with the r language
# american community survey
# 2000-2011 1-year (plus when available 3-year and 5-year files)
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


##########################################################################
# Download and Create a Database with the American Community Survey in R #
##########################################################################

#####################
## # # # # # # # # ##
## monetdb warning ##
## # # # # # # # # ##
#####################

# before running this script, you must install monetdb on your local computer
# follow the simple four steps outlined in this document
stop( "look at monetdb installation instructions.R first" )

# set your monetdb directory
# all ACS data files will be stored here
# after downloading and importing
# use forward slashes instead of back slashes

setwd( "C:/My Directory/ACS/" )


require(sqlsurvey)		# load sqlsurvey package (analyzes large complex design surveys)

# here's where the .bat file will be saved.
# this location will be needed for analyses
# set the name of the .bat file that will be used to launch this monetdb in the future
( acs.bat.file <- file.path( getwd() , "acs.bat" ) )


# set the name of the monetdb database
dbname <- 'acs'

# choose a database port
# this port should not conflict with other monetdb databases
# on your local computer.  two databases with the same port number
# cannot be accessed at the same time
dbport <- 50001


# set the directory where the monetdb files will be stored on your local computer
# this path does not need to be recorded for future use - it will be stored in the .bat file
# note: this path *must* end with a slash
( acs.database.directory <- file.path( getwd() , "MonetDB/" ) )



# choose which acs data sets to download: single-, three-, or five-year
# if you have a big hard drive, hey why not download them all?

# single-year datasets are available back to 2000
single.year.datasets.to.download <- 2000:2010
	
# three-year datasets are available back to 2007
three.year.datasets.to.download <- 2007:2010

# five-year datasets are available back to 2009
five.year.datasets.to.download <- 2009:2010

# # # # # # # # # # # # # #
# other download examples #
# # # # # # # # # # # # # #

# uncomment these lines to only download the 2010 single-year file and no others
# single.year.datasets.to.download <- 2010
# three.year.datasets.to.download <- NULL
# five.year.datasets.to.download <- NULL

# uncomment these lines to only download the 2002 one-year file, the 2007 one- and three-year files, and all of the 2009 files
# single.year.datasets.to.download <- c( 2002 , 2007 , 2009 )
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


#####################
## # # # # # # # # ##
## monetdb warning ##
## # # # # # # # # ##
#####################

# do not re-create a monetdb database after you've created it once. #
# these commands need to be run once. do not run them a second time #

# load the windows.monetdb.configuration function (creates a monet database in windows)
stop( "uncomment this" )
# source_https( "https://raw.github.com/ajdamico/usgsd/master/MonetDB/windows.monetdb.configuration.R" )

stop( "and remove these:" )
stop( "github source C:\Users\AnthonyD\Google Drive\private\usgsd\MonetDB\windows.monetdb.configuration.R" )
source( "C:/Users/AnthonyD/Google Drive/private/usgsd/MonetDB/windows.monetdb.configuration.R" ) 


# create the monetdb .bat file
# see the windows.monetdb.configuration.R file for more details about these parameters
windows.monetdb.configuration( 
		bat.file.location = acs.bat.file , 
		monetdb.program.path = "C:\\Program Files\\MonetDB\\MonetDB5\\" ,
		database.directory = acs.database.directory ,
		dbname = dbname ,
		dbport = dbport
	)


# immediately launch the acs .bat file
shell.exec( acs.bat.file )
# note that you'll need to run this line in future analyses,
# so store it as a string..  here's the full path to the .bat file:
print( acs.bat.file )
# place that string inside the shell.exec( ) function
# ..using all the program defaults, the line should look like this (without the # comment):
# shell.exec( "C:/My Directory/ACS/acs.bat" )


# at this point, r can create a connection to the database
# remember step 3 of the installation instructions?
# you stored "monetdb-jdbc-#.#.jar" somewhere.  write the full path to it here:
drv <- MonetDB( classPath = "c:/program files/monetdb/monetdb5/monetdb-jdbc-2.5.jar" )

# dynamically create the connection url
monet.url <- paste0( "jdbc:monetdb://localhost:" , dbport , "/" , dbname )

# if the next command runs before the .bat file has finished,
# it will break.  so give it two seconds to open the dos window
Sys.sleep( 2 )

# connect to the database
db <- dbConnect( drv , monet.url , user = "monetdb" , password = "monetdb" )


# add the district (but not puerto rico) to the list of all states to download
stab <- c( state.abb , "DC" )

						
#create a temporary file and a temporary directory..
tf <- tempfile() ; td <- tempdir()


# loop through each possible acs year
for ( year in 2050:2000 ){

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
			
				# 2000 - 2006 files were stored somewhere..
				ftp.path <- paste0( 'http://www2.census.gov/acs/downloads/pums/' , year , '/' )
				
			} else {
			
				# 2007+ files were stored somewhere else..
				ftp.path <- paste0( "http://www2.census.gov/" , k , "/pums/" )
				
			}

			# loop through both household- and person-level files
			for ( j in c( 'h' , 'p' ) ){			
				
				# loop through each state (abbreviation)
				for ( i in stab ){
				
					# create a character string containing the http location of the zipped csv file to be downloaded
					ACS.file.location <-
						paste0( 
							ftp.path ,
							"csv_" ,
							j ,
							tolower( i ) ,
							".zip"
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
					
					# figure out the filename of the csv -
					# 2000 contains different filenames than other years
					csvname <- 
						ifelse( year == 2000 , 
							paste0( 'c2ss' , j , tolower( i ) , '.csv' ) ,
							paste0( 'ss' , substr( year , 3 , 4 ) , j , tolower( i ) , '.csv' ) 
						)

					
					# fix a problem with the census ftp site - 
					# the alaska file is contained within the alabama csv and vice versa
					if ( year %in% 2000:2002 & j == 'p' & tolower( i ) == 'ak' ) csvname <- gsub( 'ak' , 'al' , csvname )
					if ( year %in% 2000:2002 & j == 'p' & tolower( i ) == 'al' ) csvname <- gsub( 'al' , 'ak' , csvname )
		
					
					# quickly figure out the number of lines in the data file
					# code thanks to 
					# http://costaleconomist.blogspot.com/2010/02/easy-way-of-determining-number-of.html

					# in speed tests, increasing this chunk_size does nothing
					chunk_size <- 1000
					testcon <- file( file.path( td , csvname ) ,open = "r" )
					nooflines <- 0
					( while( ( linesread <- length( readLines( testcon , chunk_size ) ) ) > 0 )
					nooflines <- nooflines + linesread )
					close( testcon )
				
					# create the table name
					tablename <- paste0( k , '_' , j )
				
					# if this is the first state to be written to the data table,
					# initiate the table in the database
					if( i == stab[ 1 ] ){
						
						# create a column of headers and types
						# headers <- lapply( file.path( td , csvname ) , read.csv , nrows = 500 )
						
						# extract the column types..
						# hz <- headers[[1]][FALSE,]
						
						# ..and make everything lowercase
						# names( hz ) <- tolower( names( hz ) )
						
						# initiate the database (with lowercase names)
						# dbWriteTable( db , tablename , hz  )
					
					
						# either above or below, not both #
					
					
						headers <- read.csv( file.path( td , csvname ) , nrows = 500 )
						cl <- sapply( headers , class )
						colTypes <- ifelse( cl == 'integer' , 'INT' , 'VARCHAR(255)' )
						colDecl <- paste( names( headers ) , colTypes )

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
						
						dbSendUpdate( db , sql )

					}
					
					
					
					
					
					# now copy the current csv file into the database
					dbSendUpdate( 
						db , 
						paste0( 
							"copy " , 
							nooflines , 
							" offset 2 records into " , 
							tablename , 
							" from '" , 
							normalizePath( file.path( td , csvname ) ) , 
							"' using delimiters ',','\\n','\"'  NULL AS ''" 
						) 
					)
					
					# these files require lots of temporary disk space,
					# so delete them once they're part of the database
					file.remove( file.path( td , csvname ) )
				}
				
				# read all csv files into the database
				# this either reads in all the _h (household) or the _p (person) csv files
				# monet.read.csv( 
					# db , 
					# file.path( td , all.csv.files ) , 
					# tablename = paste0( k , '_' , j ) , 
					# nrows = all.csv.lengths , 
					# header = TRUE , 
					# locked = TRUE , 
					# na.strings = ""
				# )

			}
			
			
			# once all state tables have been added..
			
			# create indexes to speed up the merge between the _p (person) and _h (household) files
			# dbSendUpdate( db , paste0( "CREATE INDEX " , k , "_h_dex ON " , k , "_h ( serialno )" ) )
			# dbSendUpdate( db , paste0( "CREATE INDEX " , k , "_p_dex ON " , k , "_p ( serialno )" ) )
			
			############################################
			# create a merged (household+person) table #
			
			# figure out the fields to keep
			
			# pull all fields from the person..
			pfields <- dbListFields( db , paste0( k , '_p' ) )
			# ..and household tables
			hfields <- dbListFields( db , paste0( k , '_h' ) )
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
			
			dbSendUpdate( db , i.j )
			
			
			dbSendUpdate( db , paste0( 'alter table ' , k , '_p add column one int' ) )
			dbSendUpdate( db , paste0( 'alter table ' , k , '_h add column one int' ) )
			dbSendUpdate( db , paste0( 'alter table ' , k , '_m add column one int' ) )

			dbSendUpdate( db , paste0( 'UPDATE ' , k , '_p SET one = 1' ) )
			dbSendUpdate( db , paste0( 'UPDATE ' , k , '_h SET one = 1' ) )
			dbSendUpdate( db , paste0( 'UPDATE ' , k , '_m SET one = 1' ) )
						
			dbSendUpdate( db , paste0( 'alter table ' , k , '_p add column idkey int auto_increment' ) )
			dbSendUpdate( db , paste0( 'alter table ' , k , '_h add column idkey int auto_increment' ) )
			dbSendUpdate( db , paste0( 'alter table ' , k , '_m add column idkey int auto_increment' ) )

			
			
			# now the current database contains three tables:
				# _h (household)
				# _p (person)
				# _m (merged)
			print( dbListTables( db ) )

			# confirm that the merged file has the same number of records as the person file
			stopifnot( 
				dbGetQuery( db , paste0( "select count(*) as count from " , k , "_p" ) ) == 
				dbGetQuery( db , paste0( "select count(*) as count from " , k , "_m" ) )
			)
			
			print( 'problems start here' )
			
			acs.m.design <- 									# name the survey object
				sqlrepsurvey(									# svrepdesign function call.. type ?svrepdesign for more detail
					weight = 'pwgtp' , 							# person-level weights are stored in column "pwgtp"
					repweights = paste0( 'pwgtp' , 1:80 ) ,		# the acs contains 80 replicate weights, pwgtp1 - pwgtp80.  this [0-9] format captures all numeric values
					scale = 4 / 80 ,
					rscales = rep( 1 , 80 ) ,
					mse = TRUE ,
					table.name = paste0( k , '_m' ) , 			# use the person-household-merge data table
					key = "idkey" ,
					check.factors = TRUE ,
					database = monet.url ,
					driver = drv ,
					user = "monetdb" ,
					password = "monetdb" 
				)

			
			print( year )
			print( svymean( ~agep , acs.m.design ) )
			print( svytotal( ~I( sex ) , acs.m.design ) )

			
			print( 'add some save commands here' )
			
		}
	}
}


# the current working directory should now contain one database (.db) file
# for each data set specified in the one, three, and five year vectors


# once complete, this script does not need to be run again.
# instead, use one of the american community survey analysis scripts
# which utilize these newly-created database (.db) files


# print a reminder: set the directory you just saved everything to as read-only!
winDialog( 'ok' , paste( "all done.  you should set" , getwd() , "read-only so you don't accidentally alter these files." ) )


# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
