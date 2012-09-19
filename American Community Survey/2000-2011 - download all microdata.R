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


# set your working directory.
# all ACS data files will be stored here
# after downloading and importing.
# use forward slashes instead of back slashes

setwd( "C:/My Directory/ACS/" )


# remove the # in order to run this install.packages line only once
# install.packages( "RSQLite" )


require(RSQLite) # load RSQLite package (creates database files in R)


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
			
			# confirm that the .db file in the current working directory does not yet exist
			if ( file.exists( paste0( k , ".db" ) ) ) stop( paste0( "please delete " , getwd() , "/" , k , ".db before running this program" ) )

			# create the database (.db) file containing the acs
			db <- dbConnect( SQLite() , dbname = paste0( k , ".db" ) )

			# loop through each state (abbreviation)
			for ( i in stab ){
				
				# loop through both household- and person-level files
				for ( j in c( 'h' , 'p' ) ){
					
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

	
					# if working on the first state, initiate the table (do not append to it)
					# otherwise, append to whatever table already exists
					ap <- ifelse( i == stab[ 1 ] , FALSE , TRUE )
					
					
					# figure out the filename of the csv -
					# 2000 - 2002 contain different filenames than other years
					csvname <- 
						ifelse( year %in% 2000:2002 , 
							paste0( 'c2ss' , j , tolower( i ) , '.csv' ) ,
							paste0( 'ss' , substr( year , 3 , 4 ) , j , tolower( i ) , '.csv' ) 
						)

					
					# fix a problem with the census ftp site - 
					# the alaska file is contained within the alabama csv and vice versa
					if ( year == 2000 & j == 'p' & tolower( i ) == 'ak' ) csvname <- gsub( 'ak' , 'al' , csvname )
					if ( year == 2000 & j == 'p' & tolower( i ) == 'al' ) csvname <- gsub( 'al' , 'ak' , csvname )
					
					
					# write the csv directly into the database,
					# without overloading RAM
					dbWriteTable( 
						db , 
						
						name = paste0( k , '_' , j ) , 
						
						# construct the full filepath to the just-downloaded csv file on the local disk
						value = paste0( 
									td , 
									'/' ,
									csvname
								) , 
								
						row.names = FALSE ,
						header = TRUE ,
						sep = "," ,
						append = ap
					)

					# these files require lots of temporary disk space,
					# so delete them once they're part of the database
					file.remove( fn , tf )
	
				}
			}

			# once all state tables have been added completed..
			
			# create indexes to speed up the merge between the _p (person) and _h (household) files
			dbSendQuery( db , paste0( "CREATE INDEX " , k , "_p_dex ON " , k , "_h ( SERIALNO )" ) )
			dbSendQuery( db , paste0( "CREATE INDEX " , k , "_h_dex ON " , k , "_p ( SERIALNO )" ) )
			
			# create the merged file
			 dbSendQuery( 
				db , 
				paste0( 
					"create table " , 
					k , 
					"_m as select * from " ,
					k , 
					"_h as a inner join " , 
					k , 
					"_p as b on a.serialno = b.serialno"
				)
			)
			
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
		}
	}
}


# the current working directory should now contain one database (.db) file
# for each data set specified in the one, three, and five year vectors


# once complete, this script does not need to be run again.
# instead, use one of the american community survey analysis scripts
# which utilize these newly-created database (.db) files


# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
