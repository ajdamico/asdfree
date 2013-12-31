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


# # # # # # # # # # # # # # #
# warning: monetdb required #
# # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###################################################################################################################################
# prior to running this analysis script, monetdb must be installed on the local machine. follow each step outlined on this page: #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/usgsd/blob/master/MonetDB/monetdb%20installation%20instructions.R #
###################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #




# set your working directory.
# the NHTS data files will be stored here
# after downloading and importing them.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NHTS/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( c( "stringr" , "sas7bdat" , "MonetDB.R" , "downloader" , "R.utils" ) )


# define which years to download #

# uncomment this line to download all available data sets
# uncomment this line by removing the `#` at the front
# years.to.download <- c( 1983 , 1990 , 1995 , 2001 , 2009 )

# uncomment this line to only download the most current year
# years.to.download <- 2009

# uncomment this line to download, for example, 2009 and 1995
# years.to.download <- c( 2009 , 1995 )



############################################
# no need to edit anything below this line #



# initiate a function
# that takes a monet database
# and a pre- and post- table name
# in order to copy the table over with
# a) all lowercase column names
# b) all negatives blanked out
# c) a new column of all ones
sql.process <-
	function( db , pre , post ){
			
		if ( identical( pre , post ) ) stop( "`pre` and `post` cannot be the same." )

		
		# figure out which columns are not stored as strings
		all.tables <- dbReadTable( db , 'tables' )
		
		# pull the current table's monetdb id
		this.table.id <- all.tables[ all.tables$name == pre , 'id' ]
		
		# pull all fields in this table
		all.columns <- 
			dbGetQuery( 
				db , 
				paste(
					'select * from columns where table_id = ' ,
					this.table.id
				)
			)
		
		# blank only columns that are not varchar
		cols.to.blank <- all.columns[ !( all.columns$type %in% 'varchar' ) , 'name' ]
		
		
		# loop through every field in the data set
		# and blank out all negative numbers
		for ( j in cols.to.blank ) dbSendUpdate( db , paste( 'UPDATE' , pre , 'SET' , j , '= NULL WHERE' , j , '< 0' ) )
		
		# get rid of `id9` field #
		lowered.edited.fields <- tolower( dbListFields( db , pre ) )
		
		if ( lowered.edited.fields[ 1 ] == 'id9' ) lowered.edited.fields[ 1 ] <- 'houseid'
		
		casting.chars <- dbListFields( db , pre )
		casting.chars <- gsub( "houseid" , "CAST( houseid AS DOUBLE PRECISION )" , casting.chars )
		casting.chars <- gsub( "personid" , "CAST( personid AS DOUBLE PRECISION )" , casting.chars )
		casting.chars <- gsub( "id9" , "CAST( id9 AS DOUBLE PRECISION )" , casting.chars )
		
		
		
		# build the 'create table' sql command
		sql.create.table <-
			paste(
				'create table' , 
				post ,
				'as select' ,

				paste(
					# select all fields in the data set..
					casting.chars ,
					# re-select them, but convert them to lowercase
					lowered.edited.fields , 
					# separate them by `as` statements
					sep = ' as ' ,
					# and mush 'em all together with commas
					collapse = ', '
				) ,
				
				# tack on a column of all ones
				', 1 as one from' ,
				 
				pre ,
				
				' WITH DATA'
			)

		# actually execute the create table command
		dbSendUpdate( db , sql.create.table )

		# remove the source data table
		dbRemoveTable( db , pre )
	}
# function end


# initiate a function
# that takes two tables (named by a _year pattern)
# and returns the non-intersecting field names of the b.table
# this will be used for monetdb sql joins
nmf <- 
			function( conn , b.table , a.table , yr ){
				dbListFields( 
					conn , 
					paste0( b.table , '_' , yr ) )[ 
						!( 
							dbListFields( conn , paste0( b.table , '_' , yr ) ) %in% dbListFields( conn , paste0( a.table , '_' , yr ) ) 
						) 
					]
			}
# function end




# # # # # # # # #
# program start #
# # # # # # # # #

require(stringr) 			# load stringr package (manipulates character strings easily)
require(sqlsurvey)			# load sqlsurvey package (analyzes large complex design surveys)
require(MonetDB.R)			# load the MonetDB.R package (connects r to a monet database)
require(downloader)			# downloads and then runs the source() function on scripts from github
require(sas7bdat)			# loads files ending in .sas7bdat directly into r as data.frame objects
require(foreign) 			# load foreign package (converts data files into R)
require(R.utils)			# load the R.utils package (counts the number of lines in a file quickly)


# create a temporary file and a temporary directory..
tf <- tempfile() ; td <- tempdir()




# configure a monetdb database for the nhts on windows #

# note: only run this command once.  this creates an executable (.bat) file
# in the appropriate directory on your local disk.
# when adding new files or adding a new year of data, this script does not need to be re-run.

# create a monetdb executable (.bat) file for the national household and travel survey
batfile <-
	monetdb.server.setup(
					
					# set the path to the directory where the initialization batch file and all data will be stored
					database.directory = paste0( getwd() , "/MonetDB" ) ,
					# must be empty or not exist
					
					# find the main path to the monetdb installation program
					monetdb.program.path = "C:/Program Files/MonetDB/MonetDB5" ,
					
					# choose a database name
					dbname = "nhts" ,
					
					# choose a database port
					# this port should not conflict with other monetdb databases
					# on your local computer.  two databases with the same port number
					# cannot be accessed at the same time
					dbport = 50013
	)

	
# this next step is so very important.

# store a line of code that will make it easy to open up the monetdb server in the future.
# this should contain the same file path as the batfile created above,
# you're best bet is to actually look at your local disk to find the full filepath of the executable (.bat) file.
# if you ran this script without changes, the batfile will get stored in C:\My Directory\NHTS\MonetDB\nhts.bat

# here's the batfile location:
batfile

# note that since you only run the `monetdb.server.setup()` function the first time this script is run,
# you will need to note the location of the batfile for future MonetDB analyses!

# in future R sessions, you can create the batfile variable with a line like..
# batfile <- "C:/My Directory/NHTS/MonetDB/nhts.bat"
# obviously, without the `#` comment character

# hold on to that line for future scripts.
# you need to run this line *every time* you access
# the national household and travel survey files with monetdb.
# this is the monetdb server.

# two other things you need: the database name and the database port.
# store them now for later in this script, but hold on to them for other scripts as well
dbname <- "nhts"
dbport <- 50013

# now the local windows machine contains a new executable program at "c:\my directory\NHTS\monetdb\nhts.bat"




# it's recommended that after you've _created_ the monetdb server,
# you create a block of code like the one below to _access_ the monetdb server


#####################################################################
# lines of code to hold on to for all other `nhts` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/NHTS/MonetDB/nhts.bat"

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "nhts"
dbport <- 50013

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )


# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other `nhts` monetdb analyses #
############################################################################


# define which column names are used in nhts tables but illegal in monetdb-sql
illegal.names <- c( 'serial' , 'month' , 'day' , 'date' , 'work' , 'public' , 'where' , 'chain' )


# loop through and download each year specified by the user
for ( year in years.to.download ){


	# tell us where you're at!
	cat( "now loading" , year , "..." , '\n\r' )


	# wait ten seconds, just to make sure any previous servers closed
	# and you don't get a gdk-lock error from opening two-at-once
	Sys.sleep( 10 )

	# launch the current monet database
	pid <- monetdb.server.start( batfile )
	
	# immediately connect to it
	db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

	
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

			# there are a couple of illegal names.  change them.
			for ( j in toupper( illegal.names ) ) names( x )[ names( x ) == j ] <- paste0( j , '_' )
						
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
				
				# find the .lst filepath with the same name as the .txt
				lst.filepath <- gsub( '.txt' , '.lst' , i , fixed = TRUE )
			
				# read in the lsc file
				lst.file <- tolower( readLines( lst.filepath ) )
				
				# identify the `field` row
				first.field <- min( grep( 'field' , lst.file ) )
			
				# use these hardcoded file widths
				# w <- c( 5 , 20 , 9 , 12 , 12 , 3 , 9 )
				w <- c( 5 , 14 , 16 , 11 , 12 , 3 , 9 )
				
				# import the structure
				stru <- 
					read.fwf( 
						lst.filepath , 
						widths = w ,
						skip = first.field
					)
			
				# remove any blank fields at the end
				stru <- stru[ !is.na( as.numeric( stru[ , 1 ] ) ) , ]
			
				# extract the field structure
				txt.field <- tolower( str_trim( stru[ , 2 ] ) )
				txt.type <- str_trim( stru[ , 3 ] )
				txt.w <- str_trim( stru[ , 4 ] )

				# pull only the characters before the extension					
				fn.before.dot <- gsub( "\\.(.*)" ,"" , basename( i ) )

				# make the tablename the first three letters of the filename,
				# remove any numbers, also any underscores
				tablename <- paste0( gsub( "_" , "" , gsub( "[0-9]+" , "" , fn.before.dot ) , fixed = TRUE ) , year )
				
				# there are a couple of illegal names.  change them.
				for ( j in illegal.names ) txt.field <- gsub( j , paste0( j , "_" ) , txt.field )

				
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
				# directly into the monet database you just created.
				monet.read.csv( db , i , tablename , nrows = countLines( i ) , header = TRUE , nrow.check = 250000 )
				# yes.  you did all that.  nice work.

				# delete the csv file from your local disk,
				# you're not going to use it again, so why not?
				file.remove( i )
				
			}

			# end of datasets #


			# the roster file is only available in an importable format
			# for the 2009 files..
			# the years before that don't have roster files at all.
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

			}
			
			# replicate weights are only available in an importable format
			# for the 2001 and 2009 files..
			# the years before that don't have replicate weights at all.
			if ( year > 1995 ){
			
				# replicate weights import #

				# download the person and household replicate weights
				# zipped file to the temporary file on your local disk
				if ( year == 2001 ){
					download.file( "http://nhts.ornl.gov/2001/download/replicates_ascii.zip" , tf , mode = 'wb' )
				} else {
					download.file( paste0( "http://nhts.ornl.gov/" , year , "/download/ReplicatesASCII.zip" ) , tf , mode = 'wb' )
				}
					
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
					# directly into the monet database you just created.
					monet.read.csv( db , i , tablename , nrows = countLines( i ) , header = TRUE , nrow.check = 250000 )
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

		prefix <- strsplit( new.tablename , '_' )[[1]][1]
		
		sql.process( db , i , new.tablename )

		# add indexes for faster joins #

		# if `personid` is available in the table..
		if ( 'personid' %in% dbListFields( db , new.tablename ) ){
			
			# ..use both `houseid` and `personid` for the sort columns..
			dbSendUpdate( db , paste0( 'create index ' , prefix , '_' , year , '_index ON ' , prefix , '_' , year , ' ( houseid , personid )' ) )
			
		# otherwise,
		} else {
			
			# if `houseid` is available in the table..
			if ( 'houseid' %in% dbListFields( db , new.tablename ) ){
			
				# ..just use `houseid`
				dbSendUpdate( db , paste0( 'create index ' , prefix , '_' , year , '_index ON ' , prefix , '_' , year , ' ( houseid )' ) )
			
			}
		
		}
		
	}

	
	# more stuff that's only available in the years where replicate weights
	# are freely available as csv files.
	if ( year > 1995 ){

		if ( year == 2001 ){
			day.table <- 'daypub'
			wt.table <- 'pr50wt'
			per.table <- 'perpub'
			hh.table <- 'hhpub'
		} else {
			day.table <- 'dayvpub'
			wt.table <- 'per50wt'
			per.table <- 'pervpub'
			hh.table <- 'hhvpub'
		}
	

		if ( year == 2001 ){
		
			# merge the `ldt` table with the ldt weights
			nonmatching.fields <- nmf( db , 'ldt50wt' , 'ldtpub' , year )
			
			dbSendUpdate( 
				db , 
				paste0(
					'create table ldt_m_' , 
					year , 
					' as select a.* , ' ,
					paste( "b." , nonmatching.fields , collapse = ", " , sep = "" ) , 
					' from ' ,
					'ldtpub' ,
					'_' ,
					year ,
					' as a inner join ' ,
					'ldt50wt' ,
					'_' ,
					year ,
					' as b on a.houseid = b.houseid AND a.personid = b.personid WITH DATA' 
				)
			)
			# table `ldt_m_YYYY` now available for analysis!
		
		}
		
	
		# merge the `day` table with the person-level weights
		nonmatching.fields <- nmf( db , wt.table , day.table , year )
		
		dbSendUpdate( 
			db , 
			paste0(
				'create table day_m_' , 
				year , 
				' as select a.* , ' ,
				paste( "b." , nonmatching.fields , collapse = ", " , sep = "" ) , 
				' from ' ,
				day.table ,
				'_' ,
				year ,
				' as a inner join ' ,
				wt.table ,
				'_' ,
				year ,
				' as b on a.houseid = b.houseid AND a.personid = b.personid WITH DATA' 
			)
		)
		# table `day_m_YYYY` now available for analysis!


		# merge the person table with the person-level weights
		nonmatching.fields <- nmf( db , wt.table , per.table , year )
		
		dbSendUpdate( 
			db , 
			paste0(
				'create table per_m_' ,
				year ,
				' as select a.* , ' ,
				paste( "b." , nonmatching.fields , collapse = ", " , sep = "" ) , 
				' from ' ,
				per.table , 
				'_' ,
				year , 
				' as a inner join ' ,
				wt.table ,
				'_' ,
				year ,
				' as b on a.houseid = b.houseid AND a.personid = b.personid WITH DATA' 
			)
		)
		# table `per_m_YYYY` now available for analysis!


		# merge the household table with the household-level weights
		nonmatching.fields <- nmf( db , 'hh50wt' , hh.table , year )
		
		dbSendUpdate( 
			db , 
			paste0(
				'create table hh_m_' ,
				year ,
				' as select a.* , ' ,
				paste( "b." , nonmatching.fields , collapse = ", " , sep = "" ) , 
				' from ' ,
				hh.table ,
				'_' ,
				year ,
				' as a inner join hh50wt_' ,
				year ,
				' as b on a.houseid = b.houseid WITH DATA' 
			)
		)
		# table `hh_m_YYYY` now available for analysis!

	}
	
	# disconnect from the current monet database
	dbDisconnect( db )

	# and close it using the `pid`
	monetdb.server.stop( pid )

}
	
# take a look at all the new data tables that have been added to your RAM-free SQLite database
dbListTables( db )

# double-check the tables for correct sizes
for ( i in dbListTables( db ) ){ print( i ) ; print( dbGetQuery( db , paste( 'select count(*) from' , i ) ) ) }

stop( 'create survey objects' )

# disconnect from the current database
dbDisconnect( db )

# remove the temporary file from the local disk
file.remove( tf )

# delete the whole temporary directory
unlink( td , recursive = TRUE )


# once complete, this script does not need to be run again.
# instead, use one of the national household and travel survey analysis scripts
# which utilize these newly-created survey objects


# wait ten seconds, just to make sure any previous servers closed
# and you don't get a gdk-lock error from opening two-at-once
Sys.sleep( 10 )

#####################################################################
# lines of code to hold on to for all other `nhts` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/NHTS/MonetDB/nhts.bat"

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "nhts"
dbport <- 50013

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )


# # # # run your analysis commands # # # #


# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other `nhts` monetdb analyses #
############################################################################


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
