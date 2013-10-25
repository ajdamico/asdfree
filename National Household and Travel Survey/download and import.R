# analyze survey data for free (http://asdfree.com) with the r language
# national household and travel survey
# 1983 , 1990 , 1995 , 2001 , 2009

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NHTS/" )
# years.to.download <- c( 1983 , 1990 , 1995 , 2001 , 2009 )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/National%20Household%20and%20Travel%20Survey/download%20and%20import.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# http://www.screenr.com/Zpd8

# alex karner
# alex.karner@gmail.com

# anthony joseph damico
# ajdamico@gmail.com

# if you use this script for a project, please send me a note
# it's always nice to hear about how people are using this stuff

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf


#####################################################################
# Analyze the 2009 National Household and Travel Survey file with R #
#####################################################################


# set your working directory.
# the NHTS data files will be stored here
# after downloading and importing them.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NHTS/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( c( "stringr" , "sas7bdat" , "RSQLite" , "downloader" ) )


# define which years to download #

# uncomment this line to download all available data sets
# uncomment this line by removing the `#` at the front
# years.to.download <- c( 1983 , 1990 , 1995 , 2001 , 2009 )

# uncomment this line to only download the most current year
# years.to.download <- 2009

# uncomment this line to download, for example, 2009 and 1995
# years.to.download <- c( 2009 , 1995 )


# name the database (.db) file to be saved in the working directory
nhts.dbname <- "nhts.db"


############################################
# no need to edit anything below this line #



# initiate a function
# that takes a sqlite database
# and a pre- and post- table name
# in order to copy the table over with
# a) all lowercase column names
# b) all negatives blanked out
# c) a new column of all ones
sql.process <-
	function( db , pre , post ){
			
		if ( identical( pre , post ) ) stop( "`pre` and `post` cannot be the same." )

		
		# loop through every field in the data set
		# and blank out all negative numbers
		for ( j in dbListFields( db , pre ) ) dbSendQuery( db , paste( 'UPDATE' , pre , 'SET' , j , '= NULL WHERE' , j , '< 0' ) )
		
		
		# build the 'create table' sql command
		sql.create.table <-
			paste(
				'create table' , 
				post ,
				'as select' ,

				paste(
					# select all fields in the data set..
					dbListFields( db , pre ) ,
					# re-select them, but convert them to lowercase
					tolower( dbListFields( db , pre ) ) , 
					# separate them by `as` statements
					sep = ' as ' ,
					# and mush 'em all together with commas
					collapse = ', '
				) ,
				
				# tack on a column of all ones
				', 1 as one from' ,
				pre
			)

		# actually execute the create table command
		dbSendQuery( db , sql.create.table )

		# remove the source data table
		dbRemoveTable( db , pre )
	}
# function end




# # # # # # # # #
# program start #
# # # # # # # # #

# if the nhts database file already exists in the current working directory, print a warning
if ( file.exists( paste( getwd() , nhts.dbname , sep = "/" ) ) ) warning( "the database file already exists in your working directory.\nyou might encounter an error if you are running the same year as before or did not allow the program to complete.\ntry changing the nhts.dbname in the settings above." )


require(stringr) 			# load stringr package (manipulates character strings easily)
require(RSQLite) 			# load RSQLite package (creates database files in R)
require(downloader)			# downloads and then runs the source() function on scripts from github
require(sas7bdat)			# loads files ending in .sas7bdat directly into r as data.frame objects
require(foreign) 			# load foreign package (converts data files into R)


# create a temporary file and a temporary directory..
tf <- tempfile() ; td <- tempdir()

# connect to an rsqlite database on the local disk
db <- dbConnect( SQLite() , nhts.dbname )


# loop through and download each year specified by the user
for ( year in years.to.download ){


	# tell us where you're at!
	cat( "now loading" , year , "..." , '\n\r' )

	
	# 1983 is just sas transport files, so import them independently.
	if ( year == 1983 ){

		# sas xport file import #

		# download the main four data sets
		# zipped file to the temporary file on your local disk
		download.file( paste0( "http://nhts.ornl.gov/" , year , "/download/Xpt.zip" ) , tf , mode = 'wb' )

		# unzip the temporary (zipped) file into the temporary directory
		# and store the filepath of the unzipped file(s) into a character vector `z`
		z <- unzip( tf , exdir = td )

		# only `.xpt` files should be imported
		z <- z[ grepl( '.xpt' , tolower( z ) , fixed = TRUE ) ]

		# loop through each `xpt` file to import
		for ( i in z ){
		
			# remove the file extension from the filename
			fn.before.dot <- gsub( "\\.(.*)" ,"" , basename( i ) )
			
			# make the tablename the filename
			tablename <- paste0( tolower( fn.before.dot ) , year )

			cat( "currently importing" , basename( i ) , '\n\r' )

			# import the current `xpt` file into working memory
			x <- read.xport( i )

			# read the data.frame `x`
			# directly into the rsqlite database you just created.
			dbWriteTable( db , tablename , x , header = TRUE , row.names = FALSE )
			# yes.  you did all that.  nice work.

			# delete the csv file from your local disk,
			# you're not going to use it again, so why not?
			file.remove( i )
			
			# clear the object `x` from working memory
			rm( x )
			
			# clear up RAM
			gc()
			
		}
	
	# for all other years..
	} else {

		# datasets import #

		# download the main four data sets
		# zipped file to the temporary file on your local disk
		download.file( paste0( "http://nhts.ornl.gov/" , year , "/download/Ascii.zip" ) , tf , mode = 'wb' )

		# unzip the temporary (zipped) file into the temporary directory
		# and store the filepath of the unzipped file(s) into a character vector `z`
		z <- unzip( tf , exdir = td )

		# make `z` lowercase
		z <- tolower( z )
		
		# `citation` document does not need to be imported
		z <- z[ !grepl( 'citation' , tolower( z ) ) ]

		
		# if it's 1995, there's a special structure to the tables
		# that need read.SAScii.sqlite..
		if ( year == 1995 ){

			# isolate .lsc files
			lsc <- z[ grepl( '.lsc' , z , fixed = TRUE ) ]
			
			# isolate .txt files
			txt <- z[ grepl( '.txt' , z , fixed = TRUE ) ]
		
			# loop through each text file
			for ( i in txt ){
				
				# find the .lsc filepath with the same name as the .txt
				lst.filepath <- gsub( '.txt' , '.lst' , i , fixed = TRUE )
			
				# read in the lsc file
				lst.file <- tolower( readLines( lst.filepath ) )
				
				# identify the `field` row
				first.field <- min( grep( 'field' , lst.file ) )
			
				# use these hardcoded file widths
				w <- c( 5 , 20 , 9 , 12 , 12 , 3 , 9 )
				
				# import the structure
				stru <- 
					read.fwf( 
						lst.filepath , 
						widths = w ,
						skip = first.field
					)
			
				# remove any blank fields at the end
				stru <- stru[ !is.na( stru[ , 1 ] ) , ]
			
				# extract the field structure
				txt.field <- str_trim( stru[ , 2 ] )
				txt.type <- str_trim( stru[ , 3 ] )
				txt.w <- str_trim( stru[ , 4 ] )

				# pull only the characters before the extension					
				fn.before.dot <- gsub( "\\.(.*)" ,"" , basename( i ) )

				# make the tablename the first three letters of the filename,
				# remove any numbers, also any underscores
				tablename <- paste0( gsub( "_" , "" , gsub( "[0-9]+" , "" , fn.before.dot ) , fixed = TRUE ) , year )
				
				# print the current import progress to the screen
				cat( "currently importing" , basename( i ) , '\n\r' )

				# import the actual text file into working memory
				x <- 
					read.fwf( 
						i , 
						widths = as.numeric( txt.w ) ,
						col.names = txt.field ,
						colClasses = ifelse( txt.type == 'Numeric' , 'numeric' , 'character' )
					)

				# read the data.frame `x`
				# directly into the rsqlite database you just created.
				dbWriteTable( db , tablename , x , header = TRUE , row.names = FALSE )

				# delete the csv file from your local disk,
				# you're not going to use it again, so why not?
				file.remove( i )
				
				# clear the object `x` from working memory
				rm( x )
				
				# clear up RAM
				gc()
				
						
			
			}
		
		# for all other years..
		} else {

			# look for `.asc` files, make them `.csv` files
			if( any( grepl( '.asc' , z ) ) ){

				# identify the files with `.asc` extensions
				asc.files <- z[ grepl( '.asc' , z ) ]
			
				# rename the filepaths from `asc` to `csv`
				csv.files <- gsub( '.asc' , '.csv' , asc.files , fixed = TRUE )

				# copy the files over to csv files,
				# no other changes.
				file.copy( asc.files , csv.files )

				# overwrite the `.asc` filepaths to `.csv`
				z[ grepl( '.asc' , z ) ] <- csv.files
			}

		
			# loop through each of the csv files downloaded
			for ( i in z ){
				
				# pull only the characters before the extension					
				fn.before.dot <- gsub( "\\.(.*)" ,"" , basename( i ) )

				# make the tablename the first three letters of the filename,
				# remove any numbers, also any underscores
				tablename <- paste0( gsub( "_" , "" , gsub( "[0-9]+" , "" , fn.before.dot ) , fixed = TRUE ) , year )
				
				# print the current import progress to the screen
				cat( "currently importing" , basename( i ) , '\n\r' )

				# read the comma separated value (csv) file you just downloaded
				# directly into the rsqlite database you just created.
				dbWriteTable( db , tablename , i , sep = "," , header = TRUE , row.names = FALSE )
				# yes.  you did all that.  nice work.

				# delete the csv file from your local disk,
				# you're not going to use it again, so why not?
				file.remove( i )
				
			}

			# end of datasets #

			
			# replicate weights are only available in an importable format
			# for the 2009 file..the 2001 file is stuck in the sas7bdat time warp
			# the years before that don't have replicate weights at all.
			if ( year > 2001 ){
			
				# roster file import #
				download.file( paste0( 'http://nhts.ornl.gov/' , year , '/download/roster.zip' ) , tf , mode = 'wb' )
						
				# unzip the temporary (zipped) file into the temporary directory
				# and store the filepath of the unzipped file(s) into a character vector `z`
				z <- unzip( tf , exdir = td )

				# only `sas7bdat` files need to be imported
				z <- z[ grepl( 'sas7bdat' , tolower( z ) ) ]

				
				# loop through each of the sas7bdat files downloaded
				for ( i in z ){
					
					fn.before.dot <- gsub( "\\.(.*)" ,"" , basename( i ) )
					
					# make the tablename the filename
					tablename <- paste0( tolower( fn.before.dot ) , year )

					cat( "currently importing" , basename( i ) , '\n\r' )

					# import the current sas7bdat file into working memory
					x <- read.sas7bdat( i )

					# read the data.frame `x`
					# directly into the rsqlite database you just created.
					dbWriteTable( db , tablename , x , header = TRUE , row.names = FALSE )
					# yes.  you did all that.  nice work.

					# delete the csv file from your local disk,
					# you're not going to use it again, so why not?
					file.remove( i )
					
					# clear the object `x` from working memory
					rm( x )
					
					# clear up RAM
					gc()
					
				}

			
				# replicate weights import #

				# download the person and household replicate weights
				# zipped file to the temporary file on your local disk
				download.file( paste0( "http://nhts.ornl.gov/" , year , "/download/ReplicatesASCII.zip" ) , tf , mode = 'wb' )

				# unzip the temporary (zipped) file into the temporary directory
				# and store the filepath of the unzipped file(s) into a character vector `z`
				z <- unzip( tf , exdir = td )

				# `citation` document does not need to be imported
				z <- z[ !grepl( 'citation' , tolower( z ) ) ]

				# `.lst` files not needed
				z <- z[ !grepl( '.lst' , tolower( z ) , fixed = TRUE ) ]
				
				# loop through each of the csv files downloaded
				for ( i in z ){
					
					fn.before.dot <- gsub( "\\.(.*)" ,"" , basename( i ) )
					
					# make the tablename the filename
					tablename <- paste0( tolower( fn.before.dot ) , year )

					cat( "currently importing" , basename( i ) , '\n\r' )

					# read the comma separated value (csv) file you just downloaded
					# directly into the rsqlite database you just created.
					dbWriteTable( db , tablename , i , sep = "," , header = TRUE , row.names = FALSE )
					# yes.  you did all that.  nice work.

					# delete the csv file from your local disk,
					# you're not going to use it again, so why not?
					file.remove( i )
					
				}

				# end of replicate weights import #



			}

		}
		
	}

	# find all tables from this year
	tables.this.year <- dbListTables( db )[ grep( year , dbListTables( db ) ) ]
	
	# convert all tables to lowercase..
	for ( i in tables.this.year ){

		new.tablename <- gsub( year , paste0( '_' , year ) , i )

		prefix <- strsplit( new.tablename , '_' )[[1]]
		
		sql.process( db , i , new.tablename )

		# add indexes for faster joins #

		# if `personid` is available in the table..
		if ( 'personid' %in% dbListFields( db , new.tablename ) ){
			
			# ..use both `houseid` and `personid` for the sort columns..
			dbSendQuery( db , paste0( 'create index ' , prefix , '_index ON ' , prefix , '_' , year , ' ( houseid , personid )' ) )
			
		# otherwise,
		} else {
			
			# if `houseid` is available in the table..
			if ( 'houseid' %in% dbListFields( db , new.tablename ) ){
			
				# ..just use `houseid`
				dbSendQuery( db , paste0( 'create index ' , prefix , '_index ON ' , prefix , '_' , year , ' ( houseid )' ) )
			
			}
		
		}
		
	}

	
	# more stuff that's only available in the years where replicate weights
	# are freely available as csv files.
	if ( year > 2001 ){

		# merge the `day` table with the person-level weights
		dbSendQuery( 
			db , 
			paste0(
				'create table day_m_' , 
				year , 
				' as select * from dayvpub_' ,
				year ,
				' as a inner join per50wt_' ,
				year ,
				' as b on a.houseid = b.houseid AND a.personid = b.personid' 
			)
		)
		# table `day_m_YYYY` now available for analysis!


		# merge the person table with the person-level weights
		dbSendQuery( 
			db , 
			paste0(
				'create table per_m_' ,
				year ,
				' as select * from pervpub_' ,
				year , 
				' as a inner join per50wt_' ,
				year ,
				' as b on a.houseid = b.houseid AND a.personid = b.personid' 
			)
		)
		# table `per_m_YYYY` now available for analysis!


		# merge the household table with the household-level weights
		dbSendQuery( 
			db , 
			paste0(
				'create table hh_m_' ,
				year ,
				' as select * from hhvpub_' ,
				year ,
				' as a inner join hh50wt_' ,
				year ,
				' as b on a.houseid = b.houseid' 
			)
		)
		# table `hh_m_YYYY` now available for analysis!

	}

}
	
# take a look at all the new data tables that have been added to your RAM-free SQLite database
dbListTables( db )

# disconnect from the current database
dbDisconnect( db )

# remove the temporary file from the local disk
file.remove( tf )

# delete the whole temporary directory
unlink( td , recursive = TRUE )

# print a reminder: set the directory you just saved everything to as read-only!
message( paste0( "all done.  you should set the file " , file.path( getwd() , nhts.dbname ) , " read-only so you don't accidentally alter these tables." ) )


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
