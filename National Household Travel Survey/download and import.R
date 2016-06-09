# analyze survey data for free (http://asdfree.com) with the r language
# national household travel survey
# 1983 , 1990 , 1995 , 2001 , 2009

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NHTS/" )
# years.to.download <- c( 1983 , 1990 , 1995 , 2001 , 2009 )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Household%20Travel%20Survey/download%20and%20import.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# alex karner
# alex.karner@gmail.com

# anthony joseph damico
# ajdamico@gmail.com



# set your working directory.
# the NHTS data files will be stored here
# after downloading and importing them.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NHTS/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( c( "MonetDBLite" , "survey" , "SAScii" , "descr" , "downloader" , "digest" , "sas7bdat" , "R.utils" , "ff" , "readr" ) )


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

# this script's download files should be incorporated in download_cached's hash list
options( "download_cached.hashwarn" = TRUE )
# warn the user if the hash does not yet exist

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
library(survey) 			# load survey package (analyzes complex design surveys)
library(DBI)				# load the DBI package (implements the R-database coding)
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


# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )


# define which column names are used in nhts tables but illegal in monetdb-sql
illegal.names <- c( 'serial' , 'month' , 'day' , 'date' , 'work' , 'public' , 'where' , 'chain' , 'match' )


# loop through and download each year specified by the user
for ( year in years.to.download ){


	# tell us where you're at!
	cat( "now loading" , year , "..." , '\n\r' )


	# immediately connect to the monetdblite folder
	db <- dbConnect( MonetDBLite::MonetDBLite() , dbfolder )


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
					# directly into the monetdblite database you just created.
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


	# remove missing weights in 2001
	if( year == 2001 ){

		dbSendQuery( db , "UPDATE daypub_2001 SET wttrdntl = 0 WHERE wttrdntl IS NULL" )
		dbSendQuery( db , "UPDATE perpub_2001 SET wtprntl = 0 WHERE wtprntl IS NULL" )
		dbSendQuery( db , "UPDATE hhpub_2001 SET wthhntl = 0 WHERE wthhntl IS NULL" )
		
		for( this_wgt in grep( "wttdfn[0-9]" , dbListFields( db , 'pr50wt_2001' ) , value = TRUE ) ) dbSendQuery( db , paste( "UPDATE pr50wt_2001 SET" , this_wgt , "= 0 WHERE" , this_wgt , "IS NULL" ) )
		for( this_wgt in grep( "wtpfin[0-9]" , dbListFields( db , 'pr50wt_2001' ) , value = TRUE ) ) dbSendQuery( db , paste( "UPDATE pr50wt_2001 SET" , this_wgt , "= 0 WHERE" , this_wgt , "IS NULL" ) )
		for( this_wgt in grep( "wthfin[0-9]" , dbListFields( db , 'hh50wt_2001' ) , value = TRUE ) ) dbSendQuery( db , paste( "UPDATE hh50wt_2001 SET" , this_wgt , "= 0 WHERE" , this_wgt , "IS NULL" ) )
		
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
			ldt.wt <- ~wtptpfin ; ldt.repwt <- 'fptpwt[0-9]'
			hh.wt <- ~wthhntl ; hh.repwt <- 'wthfin[0-9]'
			per.wt <- ~wtprntl ; per.repwt <- 'wtpfin[0-9]'
			day.wt <- ~wttrdntl ; day.repwt <- 'wttdfn[0-9]'
			
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
			hh.wt <- ~wthhfin ; hh.repwt <- 'hhwgt[0-9]' 
			per.wt <- ~wtperfin ; per.repwt <- 'wtperfin[1-9]' 
			day.wt <- ~wttrdfin ; day.repwt <- 'daywgt[1-9]'
						
		}
	

		if ( year == 2001 ){
					
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
			nhts.ldt.design <-
				svrepdesign(
					weight = ldt.wt ,
					repweights = ldt.repwt ,
					scale = sca ,
					rscales = rsc ,
					degf = 99 ,
					type = 'JK1' ,
					mse = TRUE ,
					data = paste0( 'ldt_m_' , year ) , 			# use the person-ldt-merge data table
					dbtype = "MonetDBLite" ,
					dbname = dbfolder
				)

			# workaround for a bug in survey::svrepdesign.character
			nhts.ldt.design$mse <- TRUE

				
		
		}
		

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
		
		# immediately make the person-day-level svrepdesign object.
		nhts.day.design <-
			svrepdesign(
				weight = day.wt ,
				repweights = day.repwt ,
				scale = sca ,
				rscales = rsc ,
				degf = 99 ,
				type = 'JK1' ,
				mse = TRUE ,
				data = paste0( 'day_m_' , year ) , 	# use the person-day-merge data table
				dbtype = "MonetDBLite" ,
				dbname = dbfolder
			)

		# workaround for a bug in survey::svrepdesign.character
		nhts.day.design$mse <- TRUE
		
			
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
		
		# immediately make the person-level svrepdesign object.
		nhts.per.design <-
			svrepdesign(
				weight = per.wt ,
				repweights = per.repwt ,
				scale = sca ,
				rscales = rsc ,
				degf = 99 ,
				type = 'JK1' ,
				mse = TRUE ,
				data = paste0( 'per_m_' , year ) , 	# use the person-merge data table
				dbtype = "MonetDBLite" ,
				dbname = dbfolder
			)

		# workaround for a bug in survey::svrepdesign.character
		nhts.per.design$mse <- TRUE
		
	
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

		
		# immediately make the household-level svrepdesign object.
		nhts.hh.design <-
			svrepdesign(
				weight = hh.wt ,
				repweights = hh.repwt ,
				scale = sca ,
				rscales = rsc ,
				degf = 99 ,
				type = 'JK1' ,
				mse = TRUE ,
				data = paste0( 'hh_m_' , year ) , 	# use the household-merge data table
				dbtype = "MonetDBLite" ,
				dbname = dbfolder
			)

		# workaround for a bug in survey::svrepdesign.character
		nhts.hh.design$mse <- TRUE


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
	dbDisconnect( db , shutdown = TRUE )

}


# remove the temporary file from the local disk
file.remove( tf )

# delete the whole temporary directory
unlink( td , recursive = TRUE )


# once complete, this script does not need to be run again.
# instead, use one of the national household travel survey analysis scripts
# which utilize these newly-created survey objects


# double-check that all tables have at least one record #

# reconnect to the monetdblite database
db <- dbConnect( MonetDBLite::MonetDBLite() , dbfolder )

# all tables created by this script end in numbers
tein <- dbListTables( db )[ grep( '(.)*[0-9][0-9][0-9][0-9]' , dbListTables( db ) ) ]
# loop through all tables with underscores and check
for ( i in tein ){ stopifnot( dbGetQuery( db , paste( 'select count(*) from' , i ) ) > 0 ) }

# disconnect from the current monet database
dbDisconnect( db , shutdown = TRUE )

