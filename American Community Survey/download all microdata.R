# analyze survey data for free (http://asdfree.com) with the r language
# american community survey
# 2005-2014 1-year (plus when available 3-year and 5-year files)
# household-level, person-level, and merged files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# path.to.7z <- "7za"							# # only macintosh and *nix users need this line
# library(downloader)
# setwd( "C:/My Directory/ACS/" )
# single.year.datasets.to.download <- 2005:2014
# three.year.datasets.to.download <- 2007:2013
# five.year.datasets.to.download <- 2009:2014
# include_puerto_rico <- TRUE
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/American%20Community%20Survey/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com



#####################################################################################
# download all available american community survey files from the census bureau ftp #
# import each file into a monet database, merge the person and household files      #
# create a monet database-backed complex sample survey design object with r         #
#####################################################################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################################################
# macintosh and *nix users need 7za installed:  http://superuser.com/questions/548349/how-can-i-install-7zip-so-i-can-run-it-from-terminal-on-os-x  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# path.to.7z <- "7za"														# # this is probably the correct line for macintosh and *nix
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# the line above sets the location of the 7-zip program on your local computer. uncomment it by removing the `#` and change the directory if ya did #
#####################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# # # # # # # # # # # # # # # #
# warning: this takes a while #
# # # # # # # # # # # # # # # #

# even if you're only downloading a single year of data and you've got a fast internet connection,
# you'll be better off leaving this script to run overnight.  if you wanna download all available files and years,
# leave it running on friday afternoon (or even better: before you leave for a weeklong vacation).
# depending on your internet and processor speeds, the entire script should take between two and ten days.
# it's running.  don't believe me?  check the working directory (set below) for a new r data file (.rda) every few hours.




# remove the # in order to run this install.packages line only once
# install.packages( c("MonetDB.R", "MonetDBLite" , "survey" , "SAScii" , "descr" , "downloader" , "digest" , "sas7bdat" , "R.utils" ) )


library(survey) 		# load survey package (analyzes complex design surveys)
library(DBI)			# load the DBI package (implements the R-database coding)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(MonetDBLite)	# load MonetDBLite package (creates database files in R)
library(sas7bdat)		# loads files ending in .sas7bdat directly into r as data.frame objects
library(downloader)		# downloads and then runs the source() function on scripts from github
library(R.utils)		# load the R.utils package (counts the number of lines in a file quickly)


# load the download_cached and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url( 
	"https://raw.githubusercontent.com/ajdamico/asdfree/master/Download%20Cache/download%20cache.R" , 
	prompt = FALSE , 
	echo = FALSE 
)


# set your ACS data directory
# after downloading and importing
# all monet database-backed complex survey designs will be stored here
# and the monet database will be stored in the MonetDB folder within
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/ACS/" )


# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )

# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite() , dbfolder )



# choose which acs data sets to download: single-, three-, or five-year
# if you have a big hard drive, hey why not download them all?

# single-year datasets are available back to 2005
# uncomment this line to download all available single-year data sets
# uncomment this line by removing the `#` at the front
# single.year.datasets.to.download <- 2005:2014
	
# three-year datasets are available back to 2007
# uncomment this line to download all available three-year data sets
# uncomment this line by removing the `#` at the front
# three.year.datasets.to.download <- 2007:2013

# five-year datasets are available back to 2009
# uncomment this line to download all available five-year data sets
# uncomment this line by removing the `#` at the front
# five.year.datasets.to.download <- 2009:2014

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


# # # # # # # # # # # # # # # # #
# would you like to include the #
# puerto rico community survey  #
# in every download?
include_puerto_rico <- TRUE
# otherwise, set this to FALSE  #
# # # # # # # # # # # # # # # # #

	
###############################################
# DATA LOADING COMPONENT - ONLY RUN THIS ONCE #
###############################################


##########################################
# this entire script is for data-loading #
# and only needs to be run once  #
# for whichever year(s) you need #
##################################


# check if 7z is working
if( ( .Platform$OS.type != 'windows' ) && ( system( paste( path.to.7z , "-h" ) ) != 0 ) ) stop("you need to install 7-zip")
						
#create a temporary file..
tf <- tempfile()

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
			
			if( year <= 2006 ){
				ftp.path <- paste0( "http://www2.census.gov/programs-surveys/acs/data/pums/" , year , "/" )
			} else {
				ftp.path <- paste0( "http://www2.census.gov/programs-surveys/acs/data/pums/" , year , "/" , size , "-Year/" )
			}
			
			# loop through both household- and person-level files
			for ( j in c( 'h' , 'p' ) ){

				# clear out the temporary directory
				unlink( list.files( tempdir() , full.names = TRUE ) , recursive = TRUE )
			
				# determine column types #
				
				if ( year %in% 2006:2007 & size == 1 ){
				
					# the 2007 single-year wyoming file does not read in with read.sas7bdat correctly,
					# so manually download the 2006 wyoming file..
					sas.file.location <-
						paste0( "http://www2.census.gov/programs-surveys/acs/data/pums/2006/unix_" , j , "wy.zip" )
					# ..because (and i confirmed this):
					# the 2007 and 2006 single-year files have the exact same columns.
				
				} else {
				
					# figure out the column types by reading in the wyoming (smallest) sas7bdat file
					sas.file.location <-
						paste0( 
							ftp.path ,
							"unix_" ,
							j ,
							"wy.zip"
						)
						
				}
							
				# store a command: "download the sas zipped file to the temporary file location"
				download.command <- download_cached( sas.file.location , tf , mode = "wb" )

				# unzip to a local directory
				wy <- unzip( tf , exdir = tempdir() )
				
				wyoming.table <- read.sas7bdat( wy[ grep( 'sas7bdat' , wy ) ] )
				
				# identify all factor/character columns
				facchar <- 
					tolower(
						names( wyoming.table )[ !( sapply( wyoming.table , class ) %in% c( 'numeric' , 'integer' ) ) ]
					)
			
				
				# now you've got a character vector containing all of the character/factor fields
				
				# save it in `headers.h` or `headers.p`
				if ( j == 'h' ) headers.h <- facchar else headers.p <- facchar
								
				
				# you don't need the `wyoming.table` for anything else, so scrap it..
				rm( wyoming.table )
				 
				# ..and clear up RAM
				gc()
				
				# end of column type determination #
	
			
				# create a character string containing the http location of the zipped csv file to be downloaded
				if( include_puerto_rico ) {
					
					ACS.file.location <- paste0( ftp.path , "csv_" , j , c( "us.zip" , "pr.zip" ) )
					
				} else {
				
					ACS.file.location <- paste0( ftp.path , "csv_" , j , "us.zip" )
					
				}
				
				fn <- tfn <- NULL
				
				for ( this_download in ACS.file.location ){
					
					# try downloading the file three times before breaking
					
					# store a command: "download the ACS zipped file to the temporary file location"
					download.command <- expression( download_cached( this_download , tf , mode = "wb" ) )

					# try the download immediately.
					# run the above command, using error-handling.
					download.error <- tryCatch( eval( download.command ) , silent = TRUE )
					
					# if the download results in an error..
					if ( class( download.error ) == 'try-error' ) {
					
						# wait 3 minutes..
						Sys.sleep( 3 * 60 )
						
						# ..and try the download a second time
						download.error <- tryCatch( eval( download.command ) , silent = TRUE )
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
					# extract the file, platform-specific
					if ( .Platform$OS.type == 'windows' ){

						tfn <- unzip( tf , exdir = tempdir() , overwrite = TRUE )

					} else {
					
						# build the string to send to the terminal on non-windows systems
						dos.command <- paste0( '"' , path.to.7z , '" x ' , tf , ' -aoa -o"' , tempdir() , '"' )

						system( dos.command )

						tfn <- list.files( tempdir() , full.names = TRUE )

					}
					
					# delete all the files that do not include the text 'csv' in their filename
					file.remove( tfn[ !grepl( 'csv' , tfn ) ] )
					
					
					# limit the files to read in to ones containing csvs
					tfn <- tfn[ grepl( 'csv' , tfn ) ]

					# store the final csv files
					fn <- unique( c( fn , tfn ) )
				
				}
					
				
				# there's a few weird "01E4" strings in the 2007 single- and three-year household files
				# that cause the monetdb importation lines to crash.
				# this block manually recodes "01E4" to 10,000 in the source csv files.
				if ( year == 2007 & j == 'h' ){
				
					# create a temporary file
					tf07 <- tempfile()

					# open a read-only file connection to the 'ss07husa.csv' table
					incon <- file( grep( "ss07husa" , fn , value = TRUE ) , 'r' )
					
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
					fn[ grep( "ss07husa" , fn ) ] <- tf07
					
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
					
					headers.h[ headers.h == 'type' ] <- 'type_'
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
				dbSendQuery( db , sql )

				# end of initiating the table in the database #
				
				# loop through each csv file
				for ( csvpath in fn ){
									
					# if the puerto rico file is out of order, read in the whole file and fix it.
					if( grepl( "pr\\.csv$" , csvpath ) ){
					
						pr_header <- tolower( names( read.csv( csvpath , nrows = 1 ) ) )
						
						pr_header[ pr_header == 'type' ] <- 'type_'
						
						if( !all( pr_header %in% names( headers ) ) ) stop( "this puerto rico file does not have the same columns" )
						
						# otherwise, maybe they're just out of order
						if( !all( names( headers ) == pr_header ) ){
						
							# read in the whole (pretty small) file
							pr_csv <- read.csv( csvpath , stringsAsFactors = FALSE )
							
							# lowercase and add an underscore to the `type` column
							names( pr_csv ) <- tolower( names( pr_csv ) )
							names( pr_csv )[ names( pr_csv ) == 'type' ] <- 'type_'
							
							# sort the `data.frame` object to match the ordering in the monetdb table
							pr_csv <- pr_csv[  dbListFields( db , tablename ) ]
							
							# save the `data.frame` to the disk, now that the columns are correctly ordered
							write.csv( pr_csv , csvpath , row.names = FALSE , na = '' )
							
							# remove the object and clear up ram
							rm( pr_csv ) ; gc()
							
						}
						
					}
					
					# now try to copy the current csv file into the database
					first.attempt <-
						try( {
							dbSendQuery( 
								db , 
								paste0( 
									"copy offset 2 into " , 
									tablename , 
									" from '" , 
									normalizePath( csvpath ) , 
									"' using delimiters ',','\\n','\"'  NULL AS ''" 
								) 
							) 
						} , silent = TRUE )
					
					# if the first.attempt did not work..
					if ( class( first.attempt ) == 'try-error' ){


						# get rid of any comma-space-comma values.
						incon <- file( csvpath , "r") 
						tf_out <- tempfile()
						outcon <- file( tf_out , "w") 
						while( length( line <- readLines( incon , 1 ) ) > 0 ){
							# remove all whitespace
							line <-  gsub( ", ," , ",," , gsub( ",( +)," , ",," , line ) )
							writeLines( line , outcon )
						}
						
						close( outcon )
						close( incon , add = TRUE )
		
						# and run the exact same command again.
						second.attempt <-
							try( {
								dbSendQuery( 
									db , 
									paste0( 
										"copy offset 2 into " , 
										tablename , 
										" from '" , 
										normalizePath( tf_out ) , 
										"' using delimiters ',','\\n','\"'  NULL AS ''" 
									) 
								) 
							} , silent = TRUE )
							
					} else {
					
						# if the first attempt worked,
						# the second attempt should also not be a `try-error`
						second.attempt <- NULL
						
					}
					
					# some of the acs files have multiple values that should be treated as NULL, (like acs2010_3yr_p)
					# so if the above copy-into attempts fail twice,
					# scan through the entire file and remove every instance of "N.A."
					# then re-run the copy-into line.
					
					# if the first attempt doesn't work..
					if ( class( second.attempt ) == 'try-error' ){
						
						# create a temporary output file
						fpo <- tempfile()

						# create a read-only file connection from the original file
						fpx <- file( normalizePath( tf_out ) , 'r' )
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
						dbSendQuery( 
								db , 
								paste0( 
									"copy offset 2 into " , 
									tablename , 
									" from '" , 
									fpo , 						# only this time, use the temporary file as the source file
									"' using delimiters ',','\\n','\"'  NULL AS ''" 
								) 
						) 
						
						# delete the temporary files from the disk
						file.remove( fpo )
						file.remove( tf_out )
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
			
			# create the merged `headers` structure files to make the check.factors=
			# component of the sqlrepsurvey() functions below run much much faster.
			headers.m <- unique( c( headers.h , headers.p ) )
			
			# create the merged table
			dbSendQuery( db , i.j )
			
			# add columns named 'one' to each table..
			dbSendQuery( db , paste0( 'alter table ' , k , '_p add column one int' ) )
			dbSendQuery( db , paste0( 'alter table ' , k , '_h add column one int' ) )
			dbSendQuery( db , paste0( 'alter table ' , k , '_m add column one int' ) )

			# ..and fill them all with the number 1.
			dbSendQuery( db , paste0( 'UPDATE ' , k , '_p SET one = 1' ) )
			dbSendQuery( db , paste0( 'UPDATE ' , k , '_h SET one = 1' ) )
			dbSendQuery( db , paste0( 'UPDATE ' , k , '_m SET one = 1' ) )
			
			# now the current database contains three tables more tables than it did before
				# _h (household)
				# _p (person)
				# _m (merged)
			print( paste( "the database now contains tables for" , k ) )
			# the current monet database should now contain
			# all of the newly-added tables (in addition to meta-data tables)
			print( dbListTables( db ) )		# print the tables stored in the current monet database to the screen




			# confirm that the merged file has the same number of records as the person file
			stopifnot( 
				dbGetQuery( db , paste0( "select count(*) as count from " , k , "_p" ) ) == 
				dbGetQuery( db , paste0( "select count(*) as count from " , k , "_m" ) )
			)
			
			
			# special exception for the 2009 3-year file..  too many missings in the weights.
			if( year <= 2009 & size %in% c( 3 , 5 ) ){
			
				# determine all weight columns in all tables
				for( this_table in paste0( "acs" , year , "_" , size , "yr_" , c( 'h' , 'm' , 'p' ) ) ){
			
					# identify all weight columns
					wgt_cols <- grep( "wgt" , dbListFields( db , this_table ) , value = TRUE )
					
					# loop through all weight columns
					for ( this_column in wgt_cols ){
					
						# set missing values to zeroes
						dbSendQuery( db , paste( "UPDATE" , this_table , "SET" , this_column , "=0 WHERE" , this_column , "IS NULL" ) )
					
					}
					
				}
			
			}
			
			
			# create a sqlrepsurvey complex sample design object
			# using the merged (household+person) table
			
			acs.m.design <- 									# name the survey object
				svrepdesign(									# sqlrepdesign function call.. type ?sqlrepdesign for more detail
					weight = ~pwgtp , 							# person-level weights are stored in column "pwgtp"
					repweights = 'pwgtp[0-9]+' ,				# the acs contains 80 replicate weights, pwgtp1 - pwgtp80.  this [0-9] format captures all numeric values
					scale = 4 / 80 ,
					rscales = rep( 1 , 80 ) ,
					mse = TRUE ,
					type = 'JK1' ,
					data = paste0( k , '_m' ) , 				# use the person-household-merge data table
					dbtype = "MonetDBLite" ,
					dbname = dbfolder
				)
				
			# workaround for a bug in survey::svrepdesign.character
			acs.m.design$mse <- TRUE

			# create a sqlrepsurvey complex sample design object
			# using the household-level table

			acs.h.design <- 									# name the survey object
				svrepdesign(									# sqlrepdesign function call.. type ?sqlrepdesign for more detail
					weight = ~wgtp , 							# household-level weights are stored in column "wgtp"
					repweights = 'wgtp[0-9]+' ,					# the acs contains 80 replicate weights, wgtp1 - wgtp80.  this [0-9] format captures all numeric values
					scale = 4 / 80 ,
					rscales = rep( 1 , 80 ) ,
					mse = TRUE ,
					type = 'JK1' ,
					data = paste0( k , '_h' ) , 				# use the household-level data table
					dbtype = "MonetDBLite" ,
					dbname = dbfolder
				)

			# workaround for a bug in survey::svrepdesign.character
			acs.h.design$mse <- TRUE
				
			# save both complex sample survey designs
			# into a single r data file (.rda) that can now be
			# analyzed quicker than anything else.
			save( acs.m.design , acs.h.design , file = paste0( k , '.rda' ) )

			# close the connection to the two sqlrepsurvey design objects
			close( acs.m.design )
			close( acs.h.design )

			# remove these two objects from memory
			rm( acs.m.design , acs.h.design )
			
			# clear up RAM
			gc()
			
		}

	}
}


# the current working directory should now contain one r data file (.rda)
# for each monet database-backed complex sample survey design object
# for each year specified and for each size (one, three, and five year) specified


# once complete, this script does not need to be run again.
# instead, use one of the american community survey analysis scripts
# which utilize these newly-created survey objects


# set every table you've just created as read-only inside the database.
for ( this_table in dbListTables( db ) ) dbSendQuery( db , paste( "ALTER TABLE" , this_table , "SET READ ONLY" ) )

# disconnect from the current monet database
dbDisconnect( db , shutdown = TRUE )

