# analyze us government survey data with the r language
# survey of consumer finances
# 1989 through 2010
# main, extract, and replicate weights

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


##################################################################################
# download every file from every year of the Survey of Consumer Finances with R  #
# then save every file as an R data frame (.rda) so future analyses can be rapid #
##################################################################################


# define which years to download #

# uncomment this line to download all available data sets
# uncomment this line by removing the `#` at the front
# years.to.download <- c( 1989 , 1992 , 1995 , 1998 , 2001 , 2004 , 2007 , 2009 , 2010 )

# uncomment this line to only download the most current year
# years.to.download <- 2010

# uncomment this line to download, for example, 1989, 2004, and 2010
# years.to.download <- c( 1989 , 2004 , 2010 )


# set your working directory.
# all SCF data files will be stored here
# after downloading.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/SCF/" )
# ..in order to set your current working directory



# no need to edit anything below this line #


# # # # # # # # #
# program start #
# # # # # # # # #

require(foreign) 	# load foreign package (converts data files into R)


# create a data frame containing one row per year of scf data,
# and columns containing the three file names -- main, extract, and replicate weight
downloads <-
	data.frame(
		year = 
			c( 1989 , 1992 , 1995 , 1998 , 2001 , 2004 , 2007 , 2009 , 2010 ) ,
		main = 
			c( 'scf89s' , 'scf92s' , 'scf95s' , 'scf98s' , 'scf01s' , 'scf2004s' , 'scf2007s' , 'scf2009ps' , 'scf2010s' ) ,
		extract = 
			c( 'scfp1989s' , 'scfp1992s' , 'scfp1995s' , 'scfp1998s' , 'scfp2001s' , 'scfp2004s' , 'scfp2007s' , 'rscfp2009panels' , 'scfp2010s' ) ,
		rw = 
			c( 'scf89rw1s' , '1992_scf92rw1s' , '1995_scf95rw1s' , '1998_scf98rw1s' , 'scf2001rw1s' , '2004_scf2004rw1s' , '2007_scfrw1s' , 'scf2009prw1s' , 'scf2010rw1s' )
	)

	
# restrict the scf filename data frame to only years to download specified by the user above
downloads <- downloads[ downloads$year %in% years.to.download , ]


# initiate a function that..
read.scf <-
	# starts with the zipped file's filename (without `.zip`)
	# and the exact url path to that zipped file, then..
	function( zip.fn , http.path = "http://www.federalreserve.gov/econresdata/scf/files/" ){
	
		# initiate a temporary file and temporary directory
		tf <- tempfile() ; td <- tempdir()

		# download the `.zip` file
		download.file(
			# ..using the url constructed from the function's inputs
			paste0( http.path , zip.fn , ".zip" ) ,
			# save this file into the temporary file on your local disk
			tf ,
			# use mode = writable + binary
			mode = 'wb'
		)

		# unzip the temporary file into the temporary directory,
		# and store the full file path of the unzipped file
		# into a new local file name (lfn) variable
		lfn <- unzip( tf , exdir = td )

		# read the stata file directly into memory
		x <- read.dta( lfn )

		# remove the temporary file and the unzipped file in the temporary directory
		file.remove( tf )
		file.remove( lfn )

		# have the function pass back just the data.frame object
		# (that is, just this specific data table)
		return( x )
	}


# loop through each record in the `downloads` table..
for ( i in seq( nrow( downloads ) ) ){
	
	# download and import the main data table
	scf.m <- read.scf( downloads[ i , 'main' ] )
	
	# download and import the extract data table
	scf.e <- read.scf( downloads[ i , 'extract' ] )
	
	# if downloading the 2001 file, the http path must be changed..
	if ( downloads[ i , 'year' ] == 2001 ){
	
		# read in the replicate weights file using the modified path
		rw <- 
			read.scf(
				downloads[ i , 'rw' ] ,
				http.path = "http://www.federalreserve.gov/pubs/oss/oss2/2001/"
			)
	
	# ..otherwise..
	} else {
	
		# read in the replicate weights file using the default path
		# (specified in the `read.scf` function initiation above)
		rw <- read.scf( downloads[ i , 'rw' ] ) 
		
	}
	
	
	names( scf.m ) <- tolower( names( scf.m ) )
	names( scf.e ) <- tolower( names( scf.e ) )
	names( rw ) <- tolower( names( rw ) )
	
	# the number of rows in the main file should exactly equal
	# the number of rows in the extract file
	stopifnot( nrow( scf.m ) == nrow( scf.e ) )
	
	
	# the 2007 replicate weights file has a goofy extra record for some reason..
	# ..so delete it manually.
	# if the current year being downloaded is 2007,
	# then overwrite the replicate weights table (rw)
	# with the same table, but missing unique id 1817
	# (which is the non-matching record)
	if ( downloads[ i , 'year' ] == 2007 ) rw <- rw[ !( rw$yy1 == 1817 ) , ]
	
	
	# the number of rows in the main file should exactly equal
	# the number of rows in the replicate weights file, times five
	if( nrow( scf.m ) != ( nrow( rw ) * 5 ) ){
		print( "the number of records in the main file doesn't equal five times the number in the rw file" )
		print( paste( 'scf.m rows:' , nrow( scf.m ) , " / rw rows:" , nrow( rw ) ) )
		stop( "this must be fixed before continuing." )
	}
	
	# the 1989 files contain unique identifiers `x1` and `xx1`
	# instead of `y1` and `yy1` .. change those two columns in all three data files.
	if ( downloads[ i , 'year' ] == 1989 ){
		names( scf.m )[ names( scf.m ) == 'x1' ] <- 'y1' ; names( scf.m )[ names( scf.m ) == 'xx1' ] <- 'yy1' ;
		names( scf.e )[ names( scf.e ) == 'x1' ] <- 'y1' ; names( scf.e )[ names( scf.e ) == 'xx1' ] <- 'yy1'
		names( rw )[ names( rw ) == 'x1' ] <- 'y1' ; names( rw )[ names( rw ) == 'xx1' ] <- 'yy1'
	}

	# confirm that the only overlapping columns
	# between the three data sets are `y1`
	# (the unique primary economic unit id - peu)
	# and `yy1` (the five records of the peu)
	stopifnot( all.equal( sort( intersect( names( scf.m ) , names( scf.e ) ) ) , c( 'y1' , 'yy1' ) ) )
	stopifnot( all.equal( sort( intersect( names( scf.m ) , names( rw ) ) ) , c( 'y1' , 'yy1' ) ) )
	stopifnot( all.equal( sort( intersect( names( scf.e ) , names( rw ) ) ) , c( 'y1' , 'yy1' ) ) )

	# throw out the unique identifiers ending with `1`
	# because they only match one-fifth of the records in the survey data
	rw$y1 <- NULL

	# `scf.m` currently contains
	# five records per household -- all five of the implicates.

	# add a column `one` to every record, containing just the number one
	scf.m$one <- 1
	
	# break `scf.m` into five different data sets
	# based on the final character of the column 'y1'
	# which separates the five implicates
	scf.1 <- scf.m[ substr( scf.m$y1 , nchar( scf.m$y1 ) , nchar( scf.m$y1 ) ) == 1 , ]
	scf.2 <- scf.m[ substr( scf.m$y1 , nchar( scf.m$y1 ) , nchar( scf.m$y1 ) ) == 2 , ]
	scf.3 <- scf.m[ substr( scf.m$y1 , nchar( scf.m$y1 ) , nchar( scf.m$y1 ) ) == 3 , ]
	scf.4 <- scf.m[ substr( scf.m$y1 , nchar( scf.m$y1 ) , nchar( scf.m$y1 ) ) == 4 , ]
	scf.5 <- scf.m[ substr( scf.m$y1 , nchar( scf.m$y1 ) , nchar( scf.m$y1 ) ) == 5 , ]

	# count the total number of records in `scf.m`
	m.rows <- nrow( scf.m )
	
	# remove the main file from memory
	rm( scf.m )
	
	# clear up RAM
	gc()
	
	
	# merge the contents of the extract data frames
	# to each of the five implicates
	imp1 <- merge( scf.1 , scf.e )
	imp2 <- merge( scf.2 , scf.e )
	imp3 <- merge( scf.3 , scf.e )
	imp4 <- merge( scf.4 , scf.e )
	imp5 <- merge( scf.5 , scf.e )
	
	# remove the unmerged implicates from memory
	rm( scf.1 , scf.2 , scf.3 , scf.4 , scf.5 )
	
	# clear up RAM
	gc()
	
	# confirm that the number of records did not change
	stopifnot( 
		sum( nrow( imp1 ) , nrow( imp2 ) , nrow( imp3 ) , nrow( imp4 ) , nrow( imp5 ) ) == m.rows 
	)
	
	# throw out the `scf.e` data frame to free up RAM
	# for the next iteration of this loop
	rm( scf.e )
	
	# free up RAM
	gc()

	# sort all five implicates by the unique identifier
	imp1 <- imp1[ order( imp1$yy1 ) , ]
	imp2 <- imp2[ order( imp2$yy1 ) , ]
	imp3 <- imp3[ order( imp3$yy1 ) , ]
	imp4 <- imp4[ order( imp4$yy1 ) , ]
	imp5 <- imp5[ order( imp5$yy1 ) , ]
	
	
	# replace all missing values in the replicate weights table with zeroes..
	rw[ is.na( rw ) ] <- 0

	# ..then multiply the replicate weights by the multiplication factor
	rw[ , paste0( 'wgt' , 1:999 ) ] <- rw[ , paste0( 'wt1b' , 1:999 ) ] * rw[ , paste0( 'mm' , 1:999 ) ]

	# only keep the unique identifier and the final (combined) replicate weights
	rw <- rw[ , c( 'yy1' , paste0( 'wgt' , 1:999 ) ) ]
	
	# sort the replicate weights data frame by the unique identifier as well
	rw <- rw[ order( rw$yy1 ) , ]
	
	
	# pick an R data file (.rda) filename to save 
	# the final merged data frame `x` onto your local disk
	file.to.save <- paste0( 'scf' , downloads[ i , 'year' ] , '.rda' )
	
	# if this is the 2009 file, it's actually a 2007-2009 panel,
	# so note that in the R data file (.rda) filename
	if ( grepl( '2009' , file.to.save ) ) file.to.save <- gsub( '2009' , '2009_panel' , file.to.save )
	
	# save the five implicates and the replicate weight file as that file name
	save( imp1 , imp2 , imp3 , imp4 , imp5 , rw , file = file.to.save )
	
	# throw out all data frames to free up RAM
	# for the next iteration of this loop
	rm( imp1 , imp2 , imp3 , imp4 , imp5 , rw )
	
	# free up RAM
	gc()
}


# print a reminder: set the directory you just saved everything to as read-only!
winDialog( 'ok' , paste( "all done.  you should set" , getwd() , "read-only so you don't accidentally alter these files." ) )


# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
