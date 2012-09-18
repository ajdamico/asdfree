# analyze us government survey data with the r language
# american community survey
# 2010 1-year, 3-year, and 5-year
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


#######################################################################################
# Download and Create a Database with the 2010 American Community Survey files with R #
#######################################################################################


# set your working directory.
# all ACS data files will be stored here
# after downloading and importing.
# use forward slashes instead of back slashes

setwd( "C:/My Directory/ACS/" )


# remove the # in order to run this install.packages line only once
# install.packages( "RSQLite" )


require(RSQLite) # load RSQLite package (creates database files in R)


# set R to produce conservative standard errors instead of crashing
# http://faculty.washington.edu/tlumley/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN


# choose which acs data sets to download: single-, three-, or five-year
# recommended download: all three
acs.datasets.to.download <- 
	c( 
		'acs2010_1yr' , 		# download the 2010 single-year files
		'acs2010_3yr' , 		# download the 2008-2010 files
		'acs2010_5yr' 			# download the 2006-2010 files
	)

###############################################
# DATA LOADING COMPONENT - ONLY RUN THIS ONCE #
###############################################


##########################################
# this entire script is for data-loading #
# and only needs to be run once #
#################################

# add the district and puerto rico to the list of all states to download
stab <- c( state.abb , "DC" , "PR" )

# loop through each of the acs data sets to be downloaded
for ( k in acs.datasets.to.download ){

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
					"http://www2.census.gov/" ,
					k ,
					"/pums/csv_" ,
					j ,
					tolower( i ) ,
					".zip"
				)
				
			#create a temporary file and a temporary directory..
			tf <- tempfile() ; td <- tempdir()
			
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
			unzip( tf , exdir = td , overwrite = T )

				
			# if working on the first state, initiate the table (do not append to it)
			# otherwise, append to whatever table already exists
			ap <- ifelse( i == stab[ 1 ] , FALSE , TRUE )
			
			# write the csv directly into the database,
			# without overloading RAM
			dbWriteTable( 
				db , 
				name = paste0( k , '_' , j ) , 
				value = paste0( td , '/ss10' , j , tolower( i ) , '.csv' ) , 
				row.names = FALSE ,
				header = TRUE ,
				sep = "," ,
				append = ap
			)
			
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


# the current working directory should now contain one database (.db) file
# for each data set specified in the "acs.datasets.to.download" character vector object


# once complete, this script does not need to be run again.
# instead, use one of the american community survey analysis scripts
# which utilize these newly-created database (.db) files


# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
