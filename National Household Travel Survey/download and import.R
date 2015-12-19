# analyze survey data for free (http://asdfree.com) with the r language
# national household travel survey
# 1983 , 1990 , 1995 , 2001 , 2009

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( "monetdb.sequential" = TRUE )		# # only windows users need this line
# library(downloader)
# setwd( "C:/My Directory/NHTS/" )
# years.to.download <- c( 1983 , 1990 , 1995 , 2001 , 2009 )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Household%20Travel%20Survey/download%20and%20import.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# https://www.youtube.com/watch?v=JLt9JfaAxUg

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


# windows machines and also machines without access
# to large amounts of ram will often benefit from
# the following option, available as of MonetDB.R 0.9.2 --
# remove the `#` in the line below to turn this option on.
# options( "monetdb.sequential" = TRUE )		# # only windows users need this line
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
# prior to running this analysis script, monetdb must be installed on the local machine. follow each step outlined on this page: #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/asdfree/blob/master/MonetDB/monetdb%20installation%20instructions.R #
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
# install.packages( c( "stringr" , "sas7bdat" , "MonetDB.R" , "downloader" , "digest" , "R.utils" , 'readr' ) )


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
		cols.to.blank <- all.columns[ !( all.columns$type %in% c( 'clob' , 'varchar' ) ) , 'name' ]
		
		
		# loop through every field in the data set
		# and blank out all negative numbers
		for ( j in cols.to.blank ) dbSendQuery( db , paste( 'UPDATE' , pre , 'SET' , j , '= NULL WHERE' , j , '< 0' ) )
		
		# get rid of `id9` field #
		lowered.edited.fields <- tolower( dbListFields( db , pre ) )
		
		if ( lowered.edited.fields[ 1 ] == 'id9' ) lowered.edited.fields[ 1 ] <- 'houseid'
		
		casting.chars <- dbListFields( db , pre )
		casting.chars <- gsub( "houseid" , "CAST( LTRIM( RTRIM( CAST( houseid AS STRING ) ) ) AS STRING )" , casting.chars )
		casting.chars <- gsub( "personid" , "CAST( personid AS INTEGER )" , casting.chars )
		casting.chars <- gsub( "id9" , "CAST( LTRIM( RTRIM( CAST( id9 AS STRING ) ) ) AS STRING )" , casting.chars )
		
		
		
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
		dbSendQuery( db , sql.create.table )

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

library(stringr) 			# load stringr package (manipulates character strings easily)
library(sqlsurvey)			# load sqlsurvey package (analyzes large complex design surveys)
library(MonetDB.R)			# load the MonetDB.R package (connects r to a monet database)
library(downloader)			# downloads and then runs the source() function on scripts from github
library(sas7bdat)			# loads files ending in .sas7bdat directly into r as data.frame objects
library(foreign) 			# load foreign package (converts data files into R)
library(R.utils)			# load the R.utils package (counts the number of lines in a file quickly)
library(readr)				# load the readr package (reads fixed-width files a little easier)


# create a temporary file and a temporary directory..
tf <- tempfile() ; td <- tempdir()

# load the download_cached and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url( 
	"https://raw.githubusercontent.com/ajdamico/asdfree/master/Download%20Cache/download%20cache.R" , 
	prompt = FALSE , 
	echo = FALSE 
)




# configure a monetdb database for the nhts on windows #

# note: only run this command once.  this creates an executable (.bat) file
# in the appropriate directory on your local disk.
# when adding new files or adding a new year of data, this script does not need to be re-run.

# create a monetdb executable (.bat) file for the national household travel survey
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
# batfile <- "C:/My Directory/NHTS/MonetDB/nhts.bat"	# # note for mac and *nix users: `nhts.bat` might be `nhts.sh` instead"
# obviously, without the `#` comment character

# hold on to that line for future scripts.
# you need to run this line *every time* you access
# the national household travel survey files with monetdb.
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
# batfile <- "C:/My Directory/NHTS/MonetDB/nhts.bat"	# # note for mac and *nix users: `nhts.bat` might be `nhts.sh` instead"

# second: run the MonetDB server
monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "nhts"
dbport <- 50013

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

# fourth: store the process id
pid <- as.integer( dbGetQuery( db , "SELECT value FROM env() WHERE name = 'monet_pid'" )[[1]] )


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
	monetdb.server.start( batfile )
	
	# immediately connect to it..
	db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

	# ..and store the process id
	pid <- as.integer( dbGetQuery( db , "SELECT value FROM env() WHERE name = 'monet_pid'" )[[1]] )

	# 1983 is just sas transport files, so import them independently.
	if ( year == 1983 ){

		# sas xport file import #

		# download the main four data sets
		# zipped file to the temporary file on your local disk
		download_cached( 
			url = paste0( "http://nhts.ornl.gov/" , year , "/download/Xpt.zip" ) , 
			destfile = tf , 
			mode = 'wb' 
		)

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
						
			names( x ) <- tolower( names( x ) )			
			
			# read the data.frame `x`
			# directly into the monet database you just created.
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
		download_cached( 
			url = paste0( "http://nhts.ornl.gov/" , year , "/download/Ascii.zip" ) , 
			destfile = tf , 
			mode = 'wb' 
		)

		# unzip the temporary (zipped) file into the temporary directory
		# and store the filepath of the unzipped file(s) into a character vector `z`
		z <- unzip( tf , exdir = td )
		
		# `citation` document does not need to be imported
		z <- z[ !grepl( 'citation' , tolower( z ) ) ]

		
		# if it's 1995, there's a special structure to the tables
		if ( year == 1995 ){

			# isolate .lsc files
			lsc <- z[ grepl( 'lsc$|LSC$' , z ) ]
			
			# isolate .txt files
			txt <- z[ grepl( 'txt$|TXT$' , z ) ]
		
			# loop through each text file
			for ( i in txt ){
				
				# find the .lst filepath with the same name as the .txt
				lst.filepath <- gsub( 'txt$|TXT$' , 'lst' , i )
			
				# the 1995 person .lst file isn't cased the same as its data file.
				lst.filepath <- gsub( "PERS95_2" , "pers95_2" , lst.filepath )
			
				# read in the lsc file
				lst.file <- tolower( readLines( lst.filepath ) )
				
				# identify the `field` row
				first.field <- min( grep( 'field' , lst.file ) )

				lf <- readLines( lst.filepath )
				lf <- lf[ ( first.field + 1 ):length( lf ) ]
				while( any( grepl( "   " , lf ) ) ) lf <- gsub( "   " , "  " , lf )
				lf <- gsub( "^  " , "" , lf )
				lf <- lf[ lf != '' ]
				lf <- gsub( "([0-9])  ([0-9])" , "\\1.\\2" , lf )
				lf <- gsub( "  " , "," , lf )
				lf.tf <- tempfile()
				writeLines( lf , lf.tf )
				stru <- read.csv( lf.tf , h = F )
				
				stru[ , 1 ] <- as.character( stru[ , 1 ] )
			
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
				tablename <- tolower( paste0( gsub( "_" , "" , gsub( "[0-9]+" , "" , fn.before.dot ) , fixed = TRUE ) , year ) )
				
				# there are a couple of illegal names.  change them.
				for ( j in illegal.names ) txt.field <- gsub( j , paste0( j , "_" ) , txt.field )

				
				# print the current import progress to the screen
				cat( "currently importing" , basename( i ) , '\n\r' )

				# import the actual text file into working memory
				x <- 
					read_fwf( 
						i , 
						col_positions = fwf_widths( floor( as.numeric( txt.w ) ) , col_names = txt.field ) ,
						na = c( 'NA' , '' , ' ' ) ,
						col_types = paste( ifelse( txt.type == 'Numeric' , 'd' , 'c' ) , collapse = "" )
					)
				
				names( x ) <- tolower( names( x ) )
					
				# deal with decimals
				decimals <- gsub( "(.*)\\." , "" , ifelse( grepl( "\\." , txt.w ) , txt.w , "0" ) )

				for ( j in seq( txt.w ) ) if( decimals[ j ] > 0 ) x[ , j ] <- x[ , j ] / ( 10^as.numeric( decimals[j] ) )
					
				# read the data.frame `x`
				# directly into the monet database you just created.
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
				tablename <- tolower( paste0( gsub( "_" , "" , gsub( "[0-9]+" , "" , fn.before.dot ) , fixed = TRUE ) , year ) )
				
				# print the current import progress to the screen
				cat( "currently importing" , basename( i ) , '\n\r' )

				# read the comma separated value (csv) file you just downloaded
				# directly into the monet database you just created.
				monet.read.csv( db , i , tablename , header = TRUE , nrow.check = 250000 , lower.case.names = TRUE , newline = '\\r\\n' )
				# yes.  you did all that.  nice work.
				
				# clear up RAM
				gc()
				
				# re-read the same file into memory so you can figure out what columns are factor or character
				this.table <- read.csv( i , nrow = 250000 )
				
				# store all factor and character column names into an external object
				this.header <-
					names( this.table )[ sapply( this.table , function( z ) class( z ) %in% c( 'factor' , 'character' ) ) ]

				# and name that object the current tablename dot header for future use.
				assign( 
					paste0( tolower( tablename ) , '.header' ) , 
					this.header
				)
				
				# remove the stuff you no longer need
				rm( this.table , this.header )
				
				# clear up RAM once again
				gc()
				
				
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
				download_cached( 
					url = paste0( 'http://nhts.ornl.gov/' , year , '/download/roster.zip' ) , 
					destfile = tf , 
					mode = 'wb' 
				)
						
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

					names( x ) <- tolower( names( x ) )
					
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
					download_cached( 
						url = "http://nhts.ornl.gov/2001/download/replicates_ascii.zip" , 
						destfile = tf , 
						mode = 'wb' 
					)
				} else {
					download_cached( 
						url = paste0( "http://nhts.ornl.gov/" , year , "/download/ReplicatesASCII.zip" ) , 
						destfile = tf , 
						mode = 'wb' 
					)
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
					monet.read.csv( db , i , tablename , header = TRUE , nrow.check = 250000 , lower.case.names = TRUE , newline = '\\r\\n' )
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

	}

	
	# more stuff that's only available in the years where replicate weights
	# are freely available as csv files.
	if ( year > 1995 ){

		if ( year == 2001 ){
		
			day.table <- 'daypub'
			wt.table <- 'pr50wt'
			per.table <- 'perpub'
			hh.table <- 'hhpub'
			
			# replicate weight scaling factors
			sca <- 98 / 99
			rsc <- rep( 1 , 99 )
			
			# weights and replicate weights
			ldt.wt <- 'wtptpfin' ; ldt.repwt <- 'fptpwt[0-9]'
			hh.wt <- 'wthhntl' ; hh.repwt <- 'fhhwt[0-9]'
			per.wt <- 'wtprntl' ; per.repwt <- 'fperwt[0-9]'
			day.wt <- 'wttrdntl' ; day.repwt <- 'ftrdwt[0-9]'
			
		} else {
		
			day.table <- 'dayvpub'
			wt.table <- 'per50wt'
			per.table <- 'pervpub'
			hh.table <- 'hhvpub'

			# replicate weight scaling factors
			sca <- 99 / 100
			rsc <- rep( 1 , 100 )
			
			# weights and replicate weights
			ldt.wt <- NULL ; ldt.repwt <- NULL
			hh.wt <- 'wthhfin' ; hh.repwt <- 'hhwgt[0-9]' 
			per.wt <- 'wtperfin' ; per.repwt <- 'wtperfin[1-9]' 
			day.wt <- 'wttrdfin' ; day.repwt <- 'daywgt[1-9]'
						
		}
	

		if ( year == 2001 ){
					
			# kill and re-start the server before every merge #

			# disconnect from the current monet database
			dbDisconnect( db )

			# and close it using the `pid`
			monetdb.server.stop( pid )

			# wait ten seconds, just to make sure any previous servers closed
			# and you don't get a gdk-lock error from opening two-at-once
			Sys.sleep( 10 )

			# launch the current monet database
			monetdb.server.start( batfile )

			# immediately connect to it..
			db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

			# ..and store the process id
			pid <- as.integer( dbGetQuery( db , "SELECT value FROM env() WHERE name = 'monet_pid'" )[[1]] )

			# end of mserver death and resurrection #

		
			# merge the `ldt` table with the ldt weights
			nonmatching.fields <- nmf( db , 'ldt50wt' , 'ldtpub' , year )
			
			dbSendQuery( 
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
					' as b on a.houseid = b.houseid AND CAST( a.personid AS INTEGER ) = CAST( b.personid AS INTEGER ) WITH DATA' 
				)
			)
			# table `ldt_m_YYYY` now available for analysis!
		
			# add the `idkey` column to the merged ldt-level table
			dbSendQuery( db , paste0( 'alter table ldt_m_' , year , ' add column idkey int auto_increment' ) )
			
			# immediately make the person-ldt-level sqlrepsurvey object.
			nhts.ldt.design <- 									# name the survey object
				sqlrepsurvey(									# sqlrepdesign function call.. type ?sqlrepdesign for more detail
					weight = ldt.wt , 
					repweights = ldt.repwt ,
					scale = sca ,
					rscales = rsc ,
					degf = 99 ,
					mse = TRUE ,
					table.name = paste0( 'ldt_m_' , year ) , 	# use the person-ldt-merge data table
					key = "idkey" ,
					# use the `.header` object to determine which columns are character or factor types
					check.factors = get( paste0( 'ldtpub' , year , '.header' ) ) ,
					database = monet.url ,
					driver = MonetDB.R()
				)
		
		}
		

		# kill and re-start the server before every merge #

		# disconnect from the current monet database
		dbDisconnect( db )

		# and close it using the `pid`
		monetdb.server.stop( pid )

		# wait ten seconds, just to make sure any previous servers closed
		# and you don't get a gdk-lock error from opening two-at-once
		Sys.sleep( 10 )

		# launch the current monet database
		monetdb.server.start( batfile )

		# immediately connect to it..
		db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

		# ..and store the process id
		pid <- as.integer( dbGetQuery( db , "SELECT value FROM env() WHERE name = 'monet_pid'" )[[1]] )

		# end of mserver death and resurrection #

		
		# merge the `day` table with the person-level weights
		nonmatching.fields <- nmf( db , wt.table , day.table , year )
		
		dbSendQuery( 
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
				' as b on a.houseid = b.houseid AND CAST( a.personid AS INTEGER ) = CAST( b.personid AS INTEGER ) WITH DATA' 
			)
		)
		# table `day_m_YYYY` now available for analysis!

		# add the `idkey` column to the merged person-day-level table
		dbSendQuery( db , paste0( 'alter table day_m_' , year , ' add column idkey int auto_increment' ) )
		
		# immediately make the person-day-level sqlrepsurvey object.
		nhts.day.design <- 									# name the survey object
			sqlrepsurvey(									# sqlrepdesign function call.. type ?sqlrepdesign for more detail
				weight = day.wt ,
				repweights = day.repwt ,
				scale = sca ,
				rscales = rsc ,
				degf = 99 ,
				mse = TRUE ,
				table.name = paste0( 'day_m_' , year ) , 	# use the person-day-merge data table
				key = "idkey" ,
				# use the `.header` object to determine which columns are character or factor types
				check.factors = get( paste0( day.table , year , '.header' ) ) ,
				database = monet.url ,
				driver = MonetDB.R()
			)


		# kill and re-start the server before every merge #

		# disconnect from the current monet database
		dbDisconnect( db )

		# and close it using the `pid`
		monetdb.server.stop( pid )

		# wait ten seconds, just to make sure any previous servers closed
		# and you don't get a gdk-lock error from opening two-at-once
		Sys.sleep( 10 )

		# launch the current monet database
		monetdb.server.start( batfile )

		# immediately connect to it..
		db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

		# ..and store the process id
		pid <- as.integer( dbGetQuery( db , "SELECT value FROM env() WHERE name = 'monet_pid'" )[[1]] )

		# end of mserver death and resurrection #

			
		# merge the person table with the person-level weights
		nonmatching.fields <- nmf( db , wt.table , per.table , year )
		
		dbSendQuery( 
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
				' as b on a.houseid = b.houseid AND CAST( a.personid AS INTEGER ) = CAST( b.personid AS INTEGER ) WITH DATA' 
			)
		)
		# table `per_m_YYYY` now available for analysis!

		# add the `idkey` column to the merged person-level table
		dbSendQuery( db , paste0( 'alter table per_m_' , year , ' add column idkey int auto_increment' ) )
		
		# immediately make the person-level sqlrepsurvey object.
		nhts.per.design <- 									# name the survey object
			sqlrepsurvey(									# sqlrepdesign function call.. type ?sqlrepdesign for more detail
				weight = per.wt ,
				repweights = per.repwt ,
				scale = sca ,
				rscales = rsc ,
				degf = 99 ,
				mse = TRUE ,
				table.name = paste0( 'per_m_' , year ) , 	# use the person-merge data table
				key = "idkey" ,
				# use the `.header` object to determine which columns are character or factor types
				check.factors = get( paste0( per.table , year , '.header' ) ) ,
				database = monet.url ,
				driver = MonetDB.R()
			)

	
		# kill and re-start the server before every merge #

		# disconnect from the current monet database
		dbDisconnect( db )

		# and close it using the `pid`
		monetdb.server.stop( pid )

		# wait ten seconds, just to make sure any previous servers closed
		# and you don't get a gdk-lock error from opening two-at-once
		Sys.sleep( 10 )

		# launch the current monet database
		monetdb.server.start( batfile )

		# immediately connect to it..
		db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

		# ..and store the process id
		pid <- as.integer( dbGetQuery( db , "SELECT value FROM env() WHERE name = 'monet_pid'" )[[1]] )

		# end of mserver death and resurrection #

		
		# merge the household table with the household-level weights
		nonmatching.fields <- nmf( db , 'hh50wt' , hh.table , year )
		
		dbSendQuery( 
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

		
		# add the `idkey` column to the merged household-level table
		dbSendQuery( db , paste0( 'alter table hh_m_' , year , ' add column idkey int auto_increment' ) )
		
		# immediately make the household-level sqlrepsurvey object.
		nhts.hh.design <- 									# name the survey object
			sqlrepsurvey(									# sqlrepdesign function call.. type ?sqlrepdesign for more detail
				weight = hh.wt ,
				repweights = hh.repwt ,
				scale = sca ,
				rscales = rsc ,
				degf = 99 ,
				mse = TRUE ,
				table.name = paste0( 'hh_m_' , year ) , 	# use the household-merge data table
				key = "idkey" ,
				# use the `.header` object to determine which columns are character or factor types
				check.factors = get( paste0( hh.table , year , '.header' ) ) ,
				database = monet.url ,
				driver = MonetDB.R()
			)


		# done.  phew.  save all the objects to the current working directory
		if ( year == 2001 ){

			save( 
				nhts.ldt.design , nhts.day.design , nhts.per.design , nhts.hh.design ,
				file = '2001 designs.rda'
			)
			
		} else {
		
			save( 
				nhts.day.design , nhts.per.design , nhts.hh.design ,
				file = paste( year , 'designs.rda' )
			)
			
		}
	
	
	}
	
	# disconnect from the current monet database
	dbDisconnect( db )

	# and close it using the `pid`
	monetdb.server.stop( pid )

}


# remove the temporary file from the local disk
file.remove( tf )

# delete the whole temporary directory
unlink( td , recursive = TRUE )


# once complete, this script does not need to be run again.
# instead, use one of the national household travel survey analysis scripts
# which utilize these newly-created survey objects


# wait ten seconds, just to make sure any previous servers closed
# and you don't get a gdk-lock error from opening two-at-once
Sys.sleep( 10 )


# one more quick re-connection
monetdb.server.start( batfile )

db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

pid <- as.integer( dbGetQuery( db , "SELECT value FROM env() WHERE name = 'monet_pid'" )[[1]] )

# set every table you've just created as read-only inside the database.
for ( this_table in dbListTables( db ) ) dbSendQuery( db , paste( "ALTER TABLE" , this_table , "SET READ ONLY" ) )

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )


#####################################################################
# lines of code to hold on to for all other `nhts` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/NHTS/MonetDB/nhts.bat"	# # note for mac and *nix users: `nhts.bat` might be `nhts.sh` instead"

# second: run the MonetDB server
monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "nhts"
dbport <- 50013

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

# fourth: store the process id
pid <- as.integer( dbGetQuery( db , "SELECT value FROM env() WHERE name = 'monet_pid'" )[[1]] )


# # # # run your analysis commands # # # #

# double-check that all tables have at least one record #
# all tables created by this script end in numbers
tein <- dbListTables( db )[ grep( '(.)*[0-9][0-9][0-9][0-9]' , dbListTables( db ) ) ]
# loop through all tables with underscores and check
for ( i in tein ){ stopifnot( dbGetQuery( db , paste( 'select count(*) from' , i ) ) > 0 ) }

# # # # end of all analysis commands # # # #

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
