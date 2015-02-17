# analyze survey data for free (http://asdfree.com) with the r language
# american housing survey
# latest editions of all available survey years

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/AHS/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/American%20Housing%20Survey/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

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


##############################################
# analyze the American Housing Survey with R #
##############################################


# set your working directory.
# the AHS data files will be stored here
# after downloading and importing them.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/AHS/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( c( "RSQLite" , "RCurl" , "sas7bdat" , "downloader" , "stringr" ) )


# name the database (.db) file to be saved in the working directory
ahs.dbname <- "ahs.db"


############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #

# if the ahs database file already exists in the current working directory, print a warning
if ( file.exists( paste( getwd() , ahs.dbname , sep = "/" ) ) ) warning( "the database file already exists in your working directory.\nyou might encounter an error if you are running the same year as before or did not allow the program to complete.\ntry changing the ahs.dbname in the settings above." )


library(foreign) 	# load foreign package (converts data files into R)
library(sas7bdat)	# loads files ending in .sas7bdat directly into r as data.frame objects
library(tools)		# allows rapid extraction of filename extensions
library(downloader)	# downloads and then runs the source() function on scripts from github
library(RSQLite) 	# load RSQLite package (creates database files in R)
library(RCurl)		# load RCurl package (downloads https files)
library(stringr) 	# load stringr package (manipulates character strings easily)


# load the download.cache and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url( 
	"https://raw.github.com/ajdamico/usgsd/master/Download%20Cache/download%20cache.R" , 
	prompt = FALSE , 
	echo = FALSE 
)



# create a temporary file and a temporary directory..
tf <- tempfile() ; td <- tempdir()

# open the connection to the sqlite database
db <- dbConnect( SQLite() , ahs.dbname )

# hard-code the location of the census bureau's all ahs data page
download.file( "http://www.census.gov/programs-surveys/ahs/data.All.html" , tf , mode = 'wb' )

# split up the page into separate lines
http.contents <- readLines( tf )

# isolate all puf lines
puf.lines <- grep( "href(.*)Public Use" , http.contents , value = TRUE )

# extract only the link
puf.pages <- gsub('(.*)href=\"(.*)\" title(.*)' , '\\2' , puf.lines )

# start with an empty vector..
precise.files <- NULL

# ..loop through each puf page searching for zipped files
for ( this.page in puf.pages ){

	this.contents <- readLines( textConnection( getURL( paste0( "http://www.census.gov/" , this.page ) ) ) )
	
	zipped.file.lines <- this.contents[ grep( "\\.zip" , tolower( this.contents ) ) ]

	precise.files <-
		c( 
			precise.files ,
			gsub( "(.*)downloadLink: '(.*)' }, collect(.*)" , "\\2" , zipped.file.lines )
		)
	
}


# trim whitespace
precise.files <- str_trim( precise.files )

# remove empty strings
precise.files <- precise.files[ precise.files != '' ]

# look for exact matches, only zipped.
pfi <- gsub( '\\.zip|\\.Zip|\\.ZIP' , "" , precise.files )

# these files match a `.zip` file
zip.matches <- pfi[ duplicated( pfi ) ]

# get rid of the unzipped version if there's a zipped version.
precise.files <- precise.files[ !( precise.files %in% zip.matches ) ]

# look for sas and csv exact matches.
pfi <- gsub( 'CSV' , 'SAS' , precise.files )

# these files match a `csv` file
sas.matches <- pfi[ duplicated( tolower( pfi ) ) ]

# get rid of the sas version if there's a csv version.
precise.files <- precise.files[ !( tolower( precise.files ) %in% tolower( sas.matches ) ) ]

# do not download flat files, since they're only in sas7bdat and so hard to import.
precise.files <- precise.files[ !grepl( 'flat' , tolower( precise.files ) ) ]

# remove the 2011 sas file, there's a similiar (though differently named) csv file
precise.files <-
	precise.files[ precise.files != 'http://www2.census.gov/AHS/AHS_2011/AHS_2011_PUF_v1.4_SAS.zip' ]

# remove duplicates
precise.files <- unique( precise.files )
	
# if there are multiple versions of the csv public use file..
if( sum( pfl <- grepl( 'PUF_v[0-9]\\.[0-9]' , precise.files ) ) > 1 ){

	# determine all versions available in the current archive
	versions <- gsub( '(.*)PUF_v([0-9]\\.[0-9])_CSV(.*)' , '\\2' , precise.files[ pfl ] )

	# figure out which version to keep
	vtk <- as.character( max( as.numeric( versions ) ) )
	
	# overwrite the `precise.files` vector
	# with a subset..throwing out all lower puf versions.
	precise.files <- precise.files[ !( pfl & !grepl( vtk , precise.files ) ) ]
	# now the program should only download the most current csv version hosted.
	
}

# loop through each of the ahs files slated for download..
for ( fn in precise.files ){
	
	# figure out the year of data..
	this.year <- gsub( "http://www2.census.gov/programs-surveys/ahs/([0-9]*)/(.*)" , "\\1" , fn )
	this.year <- gsub( "http://www2.census.gov/AHS/AHS_([0-9]*)/(.*)" , "\\1" , this.year )
	
	# ..and where to put it
	year.dir <- paste0( getwd() , "/" , this.year )
	
	# clear up the `data.loaded` object
	data.loaded <- NULL
	
	# and while you're at it, clear up ram.
	gc()
	
	# initiate a new temporary file on the local disk
	tf <- tempfile() 
	
	# download the exact file to the local disk
	attempt.one <- try( download.cache( fn , tf , mode = 'wb' ) , silent = TRUE )
	
	if( class( attempt.one ) == 'try-error' ){
		Sys.sleep( 60 )
		download.cache( fn , tf , mode = 'wb' , fun = download )
	}
	

	# extract the filename (without extension)
	prefix <- gsub( "\\.(.*)" , "" , basename( fn ) )
	
	# if the filename contains something like `AHS_YYYY_`,
	# remove that text as well
	prefix.without.ahs.year <- 
		gsub( 
			paste0(
				"AHS_" ,
				this.year ,
				"_"
			) ,
			"" ,
			prefix
		)
		
	# from this point forward, prefix should be lowercase
	# since it won't affect any filenames
	prefix <- tolower( prefix )
	
	# figure out the file extension of what you've downloaded
	extension <- file_ext( fn )
	
	# clear out the previous temporary filename, just in case.
	previous.tf <- NULL
	
	# if the file is a zipped file..
	if ( tolower( extension ) %in% 'zip' ){
	
		# unzip it to the temporary directory,
		# overwriting the single file's filepath
		# with all of the filepaths in a multi-element character vector
		tf <- unzip( tf , exdir = td )
		
		# if the zipped file has nothing in it
		if( length( tf ) == 0 ){
		
			# wait five seconds
			Sys.sleep( 5 )
		
			# remove the failed-download file
			file.remove( tf )
			
			# re-initiate the temporary file
			tf <- tempfile() 
	
			# re-try the download, this time forcing a download
			# (just in case the cache'd file was incomplete or corrupted)
			download.cache( fn , tf , mode = 'wb' , usecache = FALSE )
			
			# unzip it once again
			tf <- unzip( tf , exdir = td )
			
		} 
		
		# if the length of the unzipped/downloaded file is still nada, break.
		if( length( tf ) == 0 ) stop( 'file download failed twice.' )
		
		# once again, extract all file extensions to the local disk
		extension <- file_ext( tf )
		
		# from this point forward, the prefix should be lowercase
		# since it won't affect any filenames
		prefix <- tolower( gsub( "\\.(.*)" , "" , basename( tf ) ) )
		
		# construct the full path to the zipped file on the local disk
		zip.path <- 
			paste0(
				"/" ,
				gsub( 
					paste0(
						"(AHS_|AHS%20)" ,
						this.year ,
						"(_|%20)"
					) ,
					"" ,
					substr( 
						basename( fn ) ,
						1 ,
						nchar( basename( fn ) ) - 4
					)
				)
			)
		
		# 2001 has a backward filename that's causing a duplicate to be missed
		zip.path <- gsub( paste0( this.year , "(_|%20)AHS" ) , "" , zip.path )

		# 1997 has a typo in national
		zip.path <- gsub( "Nationa_" , "National_" , zip.path )
		
		# `_CSV` and `_PUF` and `PUF_` are all unnecessary characters
		zip.path <- gsub( "(_|%20)CSV" , "" , zip.path )
		zip.path <- gsub( "(_|%20)PUF" , "" , zip.path )
		zip.path <- gsub( "PUF(_|%20)" , "" , zip.path )
		# remove them to reduce carpal tunnel
		
		# finally, before actually constructing the folder
		# make sure it's all lower case because i hate holding shift
		# and without spaces, because %20 gets confusing
		zip.path <- tolower( gsub( "( |%20)" , "_" , zip.path ) )
	
	# if the file to-be-extracted is not a zipped file,
	# simply store it in a sub-folder of the current year.
	} else zip.path <- ""

	
	# loop through each of the available files
	for ( i in seq( extension ) ){
	
		# start with a fresh `x` object every time
		rm( x )
		
		# clear up ram
		gc()
	
		# tell us what you're at!
		cat( "now loading" , this.year , "..." , prefix[ i ] , '\n\r' )

		# if the current file is an importable format..
		if( tolower( extension[ i ] ) %in% c( 'xpt' , 'sas7bdat' , 'csv' ) ){

			# ..try to import it using the appropriate function
			import.attempt <-
				try( {
				
						if ( tolower( extension[ i ] ) == 'xpt' ) x <- read.xport( tf[ i ] )
						
						if ( tolower( extension[ i ] )  == 'csv' ) x <- read.csv( tf[ i ] , stringsAsFactors = FALSE , quote = "'" )
						
						if ( tolower( extension[ i ] )  == 'sas7bdat' ) x <- read.sas7bdat( tf[ i ] )

						
						# if the file that's just been imported is a weight file..
						if ( grepl( 'wgt|weight' , prefix[ i ] ) ){
						
							# determine the control column's position
							ccp <- which( tolower( names( x ) ) == 'control' )
							
							# convert all columns except for the `control` column to numeric
							x[ , -ccp ] <- sapply( x[ , -ccp ] , as.numeric )
							
							# overwrite all of those missings with zeroes
							x[ is.na( x ) ] <- 0
						
						# if it's not the weight table
						
						} else {
							# add a column of all ones
							x$one <- 1
							
							# blank out negative fives through negative nines
							for ( j in seq( ncol( x ) ) ) x[ x[ , j ] %in% -5:-9 , j ] <- NA
						}
						
						

					} , 
					silent = TRUE
				)

			# if that attempt succeeded..
			if ( class( import.attempt ) != 'try-error' ){
				
				# clear up ram
				gc()
				
				# create the save-file-path 
				dir.create( paste0( year.dir , zip.path ) , showWarnings = FALSE , recursive = TRUE )
				
				# construct the full filepath for the filename
				this.filename <-
					paste0(
						year.dir ,
						zip.path , 
						"/" ,
						prefix[ i ] ,
						".rda"
					)
				
				# confirm the file isn't a duplicate of some sort
				if ( file.exists( this.filename ) ) stop( 'cannot overwrite files' )
				
				# convert all column names to lowercase
				names( x ) <- tolower( names( x ) )
			
				# construct the name to be saved within the sqlite database
				db.tablename <-
					paste(
						prefix[ i ] ,
						this.year ,
						gsub( "[^a-zA-Z0-9]" , "" , zip.path ) ,
						sep = "_"
					)
				
				# some tables should not be read into the database,
				# like the `newformat` tables (which are just metadata)
				if ( !( grepl( 'newformat' , db.tablename ) ) ){
					
					# if the dbWriteTable tries to overwrite something else,
					# break.  the program should not work.
					stopifnot( 
						# store the current data.frame (x) in the sqlite database
						dbWriteTable( 
							db , 
							db.tablename , 
							x , 
							row.names = FALSE , 
							overwrite = FALSE 
						)
					)
					
				}
				
				# copy the data.frame `x` to a less mysteriously-named object
				assign( prefix[ i ] , x )
				
				# remove the `x` object
				rm( x )
				
				# clear up ram
				gc()
				
				# save the newly-renamed object as an `.rda` file on the local disk
				save( list = prefix[ i ] , file = this.filename )
							
				# remove that object from working memory as well
				rm( list = prefix[ i ] )
				
				# clear up ram
				gc()
		
				# confirm that this data file has been loaded.
				data.loaded <- TRUE
		
			} else {
			
				# set the data.loaded flag to false
				data.loaded <- FALSE
			
			}
		
		} else {
		
			# set the data.loaded flag to false
			data.loaded <- FALSE
			
		}

		# if the data file did not get loaded as an `.rda` file and sqlite table..
		if ( !data.loaded ){

			# determine whether one or many files did not get loaded..
			if ( length( tf ) == 1 ){
			
				# construct the full filepath of the original (not `.rda`) file
				this.filename <-
					paste0(
						year.dir ,
						"/" ,
						prefix.without.ahs.year ,
						"." ,
						extension
					)

			} else {
			
				# create another subdirectory..
				dir.create( paste0( year.dir , zip.path ) )
			
				# ..with the filenames of all non-loaded files
				this.filename <-
					paste0(
						year.dir ,
						zip.path ,
						'/' ,
						basename( tf )
					)
					
			}

			# copy all files over to their appropriate filepaths
			file.copy( tf , this.filename )
			# so now unloaded files get saved on the local disk as well.
	
		}
	
	}
	
	
	# if the microdata contains both a household-level file..
	hhlf <- prefix[ grep( 'hous' , prefix ) ]
	# ..and a replicate weight file
	wgtf <- prefix[ grep( 'wgt|weight' , prefix ) ]
	
	# merge these two tables immediately #
	
	# if there are more than one of either, break the program.
	stopifnot( length( hhlf ) <= 1 & length( wgtf ) <= 1 )
	
	# if both are available..
	if ( length( hhlf ) == 1 & length( wgtf ) == 1 ){

		# perform the merge twice #
		
		# first: using the r data files #
		
		# determine the filepath of the household-level file
		hhlfn <-
			paste0(
				year.dir ,
				zip.path , 
				"/" ,
				hhlf ,
				".rda"
			)

		# determine the filepath of the replicate-weighted file
		wgtfn <-
			paste0(
				year.dir ,
				zip.path , 
				"/" ,
				wgtf ,
				".rda"
			)

		# load both the household-level..
		load( hhlfn )
		
		# ..and weights data tables into working memory
		load( wgtfn )
		
		# confirm both tables have the same number of records
		stopifnot( nrow( get( hhlf ) ) == nrow( get( wgtf ) ) )
		
		# confirm both tables have only one intersecting column name: `control`
		stopifnot( all( intersect( names( get( hhlf ) ) , names( get( wgtf ) ) ) %in% c( 'smsa' , 'control' ) ) )
		
		# merge these two files together
		x <- merge( get( hhlf ) , get( wgtf ) )
		
		# remove the weights file from memory
		rm( list = wgtf )
		
		# clear up ram
		gc()
		
		# confirm that the resultant `x` table has the same number of records
		# as the household-level data table
		stopifnot( nrow( x ) == nrow( get( hhlf ) ) )
		
		# remove the household-level file from memory
		rm( list = hhlf )
		
		# clear up ram
		gc()
		
		# determine the name of the hhlf+weights object..
		mergef <- paste( hhlf , wgtf , sep = '_' )
		
		# ..and save `x` as that.
		assign( mergef , x )
		
		# determine the filepath of the merged file
		merge.fp <-
			paste0(
				year.dir ,
				zip.path , 
				"/" ,
				mergef ,
				".rda"
			)
			
		# save the merged file to the local disk as well	
		save( list = mergef , file = merge.fp )
						
		# remove this data.frame object from memory
		rm( list = mergef )
			
		# clear up ram
		gc()
	
		# end of data.frame merge #
		
		
		
		# second: within the sqlite database #
		
		# determine the sqlite data table name of the household-level file
		db.hhfn <-
			paste(
				hhlf ,
				this.year ,
				gsub( "[^a-zA-Z0-9]" , "" , zip.path ) ,
				sep = "_"
			)

		# determine the sqlite data table name of the replicate weight file
		db.wgtfn <-
			paste(
				wgtf ,
				this.year ,
				gsub( "[^a-zA-Z0-9]" , "" , zip.path ) ,
				sep = "_"
			)

		# confirm that the number of records in the household-level table
		# matches the number of records in the weights table
		stopifnot( 
			dbGetQuery( db , paste( 'SELECT count(*) FROM' , db.hhfn ) ) ==
			dbGetQuery( db , paste( 'SELECT count(*) FROM' , db.wgtfn ) )
		)

		# determine the sqlite data table name of the merged file
		db.mergefn <-
			paste(
				hhlf , 
				wgtf ,
				this.year ,
				gsub( "[^a-zA-Z0-9]" , "" , zip.path ) ,
				sep = "_"
			)
			
		# merge the two tables with an inner join using the `control` column
		dbSendQuery( 
			db ,
			paste(
				"CREATE TABLE" ,
				db.mergefn ,
				"AS SELECT * FROM" ,
				db.hhfn , 
				"AS a INNER JOIN" ,
				db.wgtfn ,
				"AS b USING (" ,
				paste( intersect( dbListFields( db , db.hhfn ) , dbListFields( db , db.wgtfn ) ) , collapse = " , " ) ,
				")"
			)
		)
	
		# confirm that the number of records in the household-level table
		# matches the number of records in the result table
		stopifnot( 
			dbGetQuery( db , paste( 'SELECT count(*) FROM' , db.hhfn ) ) ==
			dbGetQuery( db , paste( 'SELECT count(*) FROM' , db.mergefn ) )
		)			
	
		# end of sqlite merge #
		
	}
	
}


# take a look at all the new data tables that have been added to your RAM-free SQLite database
dbListTables( db )

# disconnect from the current database
dbDisconnect( db )

# remove all files in the temporary folder
unlink( td , recursive = TRUE )

# print a reminder: set the directory you just saved everything to as read-only!
message( paste0( "all done.  you should set the file " , getwd() , " read-only so you don't accidentally alter these tables." ) )


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
