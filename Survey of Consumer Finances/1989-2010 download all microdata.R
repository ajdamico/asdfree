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

# this line will download every year of data available
years.to.download <- c( 1989 , 1992 , 1995 , 1998 , 2001 , 2004 , 2007 , 2010 )

# uncomment this line to only download the most current year
# years.to.download <- 2010

# uncomment this line to download, for example, 1989, 2004, and 2010
# years.to.download <- c( 1989 , 2004 , 2010 )


# set your working directory.
# all SCF data files will be stored here
# after downloading.
# use forward slashes instead of back slashes

setwd( "C:/My Directory/SCF/" )


# remove the # in order to run this install.packages line only once
# install.packages( "SQLite" )


# no need to edit anything below this line #


# # # # # # # # #
# program start #
# # # # # # # # #

require(foreign) 	# load foreign package (converts data files into R)
require(RSQLite) 	# load RSQLite package (creates database files in R)


# create a data frame containing one row per year of scf data,
# and columns containing the three file names -- main, extract, and replicate weight
downloads <-
	data.frame(
		year = 
			c( 1989 , 1992 , 1995 , 1998 , 2001 , 2004 , 2007 , 2010 ) ,
		main = 
			c( 'scf89s' , 'scf92s' , 'scf95s' , 'scf98s' , 'scf01s' , 'scf2004s' , 'scf2007s' , 'scf2010s' ) ,
		extract = 
			c( 'scfp1989s' , 'scfp1992s' , 'scfp1995s' , 'scfp1998s' , 'scfp2001s' , 'scfp2004s' , 'scfp2007s' , 'scfp2010s' ) ,
		rw = 
			c( 'scf89rw1s' , '1992_scf92rw1s' , '1995_scf95rw1s' , '1998_scf98rw1s' , 'scf2001rw1s' , '2004_scf2004rw1s' , '2007_scfrw1s' , 'scf2010rw1s' )
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
		scf.rw <- 
			read.scf(
				downloads[ i , 'rw' ] ,
				http.path = "http://www.federalreserve.gov/pubs/oss/oss2/2001/"
			)
	
	# ..otherwise..
	} else {
	
		# read in the replicate weights file using the default path
		# (specified in the `read.scf` function initiation above)
		scf.rw <- read.scf( downloads[ i , 'rw' ] ) 
		
	}
	
	
	names( scf.m ) <- tolower( names( scf.m ) )
	names( scf.e ) <- tolower( names( scf.e ) )
	names( scf.rw ) <- tolower( names( scf.rw ) )
	
	# the number of rows in the main file should exactly equal
	# the number of rows in the extract file
	stopifnot( nrow( scf.m ) == nrow( scf.e ) )
	
	# the number of rows in the main file should exactly equal
	# the number of rows in the replicate weights file, times five
	if( nrow( scf.m ) != ( nrow( scf.rw ) * 5 ) ){
		print( "the number of records in the main file doesn't equal five times the number in the rw file" )
		print( paste( 'scf.m rows:' , nrow( scf.m ) , " / scf.rw rows:" , nrow( scf.rw ) ) )
	}
	
	# the 1989 files contain unique identifiers `x1` and `xx1`
	# instead of `y1` and `yy1` .. change those two columns in all three data files.
	if ( downloads[ i , 'year' ] == 1989 ){
		names( scf.m )[ names( scf.m ) == 'x1' ] <- 'y1' ; names( scf.m )[ names( scf.m ) == 'xx1' ] <- 'yy1' ;
		names( scf.e )[ names( scf.e ) == 'x1' ] <- 'y1' ; names( scf.e )[ names( scf.e ) == 'xx1' ] <- 'yy1'
		names( scf.rw )[ names( scf.rw ) == 'x1' ] <- 'y1' ; names( scf.rw )[ names( scf.rw ) == 'xx1' ] <- 'yy1'
	}
		
	# confirm that the only overlapping columns
	# between the three data sets are `y1`
	# (the unique primary economic unit id - peu)
	# and `yy1` (the five records of the peu)
	stopifnot( all.equal( sort( intersect( names( scf.m ) , names( scf.e ) ) ) , c( 'y1' , 'yy1' ) ) )
	stopifnot( all.equal( sort( intersect( names( scf.m ) , names( scf.rw ) ) ) , c( 'y1' , 'yy1' ) ) )
	stopifnot( all.equal( sort( intersect( names( scf.e ) , names( scf.rw ) ) ) , c( 'y1' , 'yy1' ) ) )

	# throw out the unique identifiers ending with `1`
	# because they only match one-fifth of the records in the survey data
	scf.rw$y1 <- NULL

	# store the number of records in the main data table
	m.rows <- nrow( scf.m )
	
	# create a new temporary file
	tf <- tempfile()
	
	# connect to a new SQLite database,
	# stored in the temporary file on your local disk
	db <- dbConnect( SQLite() , tf )
	
	# write all three tables into that SQLite database,
	# so as not to overload RAM on smaller machines
	dbWriteTable( db, 'main'  , scf.m , row.names = FALSE )
	dbWriteTable( db , 'extract' , scf.e , row.names = FALSE )
	dbWriteTable( db , 'rw' , scf.rw , row.names = FALSE )

	# remove those three tables from RAM
	rm( scf.m , scf.e , scf.rw )
	
	# free up RAM
	gc()
	
	# conduct the merges between the three tables 
	# with the SQLite database (without using RAM)
	
	# merge the main table to the extract,
	# creating a new table called `m_e`
	
	# this merge will use both 'y1' and 'yy1'
	dbSendQuery( db , "CREATE TABLE m_e AS SELECT * FROM main INNER JOIN extract ON main.y1 == extract.y1 AND main.yy1 == extract.yy1" )
	
	# merge the `m_e` table to the replicate weights file,
	# creating a new table called `x`
	
	# this merge will only use 'yy1'
	dbSendQuery( db , "CREATE TABLE x AS SELECT * FROM m_e INNER JOIN rw ON m_e.yy1 == rw.yy1" )
	
	# read the SQLite data table back from the SQLite database into RAM
	x <- dbReadTable( db , 'x' )

	
	# clean up messy variable names from the SQLite merge #
	
	# fields that end with `.2` should be deleted
	# (they are duplicates resulting from the merge above)
	
	# this identifies them..
	drop.vars <- names( x )[ substr( names( x ) , nchar( names( x ) ) - 1 , nchar( names( x ) ) ) == ".2" ]
	
	# ..and this removes them.
	x <- x[ , !( names( x ) %in% drop.vars ) ]

	# fields that end with `.1` should have the `.1` removed
	# (they were given the `.1` from the merge above)
	
	# this identifies them..
	clip.vars <- substr( names( x ) , nchar( names( x ) ) - 1 , nchar( names( x ) ) ) == ".1"
	
	# ..and this renames them
	names( x )[ clip.vars ] <- gsub( ".1" , "" , names( x )[ clip.vars ] , fixed = TRUE )

	# end of variable name cleanup #
	
	
	# disconnect from the SQLite database..
	dbDisconnect( db )
	
	# ..and delete it from your local disk
	file.remove( tf )
	
	# confirm that the number of records did not change
	stopifnot( nrow( x ) == m.rows )
	
	# pick an R data file (.rda) filename to save 
	# the final merged data frame `x` onto your local disk
	file.to.save <- paste0( 'scf' , downloads[ i , 'year' ] , '.rda' )
	
	# save `x` as that file name
	save( x , file = file.to.save )
	
	# throw out the `x` data frame to free up RAM
	# for the next iteration of this loop
	rm( x )
	
	# free up RAM
	gc()
}


# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
