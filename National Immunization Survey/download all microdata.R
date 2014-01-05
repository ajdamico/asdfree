# analyze survey data for free (http://asdfree.com) with the r language
# national immunization survey
# 1995-2011 main files
# 2008-2011 teen files
# 2009 h1n1 flu file

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NIS/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/National%20Immunization%20Survey/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# http://www.screenr.com/Zpd8

# joe walsh
# j.thomas.walsh@gmail.com

# anthony joseph damico
# ajdamico@gmail.com

# if you use this script for a project, please send me a note
# it's always nice to hear about how people are using this stuff

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf


##########################################################
# download all national immunization survey files with R #
##########################################################


# set your working directory.
# all NIS data files will be stored here
# after downloading and importing.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NIS/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( c( "SAScii" , "downloader" ) )


# choose which files to download and import #

nis.years.to.download <- 1995:2011							# reads in all available main nis files
# nis.years.to.download <- c( 1998:2003 , 2006 )			# reads in the 1998-2003 and 2006 main nis files
# nis.years.to.download <- NULL								# skips the main nis files entirely

nis.teen.years.to.download <- 2008:2011						# reads in all available teen nis files
# nis.teen.years.to.download <- c( 2008, 2009 , 2011 )		# reads in the 2008, 2009, and 2011 teen nis files
# nis.teen.years.to.download <- NULL						# skips the teen nis files entirely

nhfs.download <- TRUE										# reads in the 2009 h1n1 file
# nhfs.download <- FALSE									# skips the h1n1 file entirely


############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #


library(SAScii) 			# load the SAScii package (imports ascii data with a SAS script)
library(downloader)			# downloads and then runs the source() function on scripts from github

# load the download.cache and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url( 
	"https://raw.github.com/ajdamico/usgsd/master/Download%20Cache/download%20cache.R" , 
	prompt = FALSE , 
	echo = FALSE 
)


# create a temporary file and a temporary directory
tf <- tempfile() ; td <- tempdir()

# within the current working directory,
# create a sub-directory to store the public use files
dir.create( "./puf" )


# loop through all main nis years specified by the user
for ( year in nis.years.to.download ){

	# print the current year to the screen
	print( year )

	
	# download all public use files #
	
	
	# create a character string containing the location to save the `dat` public use file after downloading
	puf.savename <- paste0( './puf/NISPUF' , substr( year , 3 , 4 ) , '.DAT' )
	
	# take a guess at where the `dat` file is stored on the cdc's website
	straight.dat <-
		paste0(
			"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/nis/nispuf" ,
			substr( year , 3 , 4 ) ,
			".dat"
		)
		
	# for these two years, don't even try to download the `dat` file since it's goofy.
	if ( year %in% c( 1998 , 2006 ) ){

		# trigger the `try-error` emergency loop
		sdat <- try( stop( 'get the zip instead of the dat these two years' ) , silent = TRUE )

	} else {
	
		# try to download the `dat` file from the cdc's website directly
		sdat <- try( download.cache( straight.dat , tf , mode = 'wb' ) , silent = TRUE )

	}
		
	# if the download failed (or if the failure was intentional)..
	if( class( sdat ) == 'try-error' ){
		
		# take a first guess at the location of the zipped file containing the `dat` file
		zip.dat <-
			paste0(
				"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/nis/nispuf" ,
				substr( year , 3 , 4 ) ,
				".dat.zip"
			)
		
		# try downloading the zipped file
		zdat <- try( download.cache( zip.dat , tf , mode = 'wb' ) , silent = TRUE )

		# if the download failed..
		if( class( zdat ) == 'try-error' ){
					
			# take a second guess at the location of the zipped file
			zip.dat <-
				paste0(
					"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/nis/nispuf" ,
					substr( year , 3 , 4 ) ,
					"_dat.zip"
				)
			
			# try downloading the zipped file again
			zdat <- try( download.cache( zip.dat , tf , mode = 'wb' ) , silent = TRUE )

			# if the download failed..
			if( class( zdat ) == 'try-error' ){
		
				# take a third and final guess at the location of the zipped file
				zip.dat <-
					paste0(
						"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NIS/nispuf" ,
						substr( year , 3 , 4 ) ,
						"dat.zip"
					)
				
				# try downloading the zipped file a final time
				download.cache( zip.dat , tf , mode = 'wb' )
			
			}

		}
		
		# since you're still inside the first download-zipped `if` statement,
		# unzip the `dat` file
		z <- unzip( tf , exdir = td )
	
		# confirm there's only one file in the zipped file
		if( length( z ) > 1 ) stop( 'multiple files stored inside the zipped file?  dat is not allowed.' )
	
		# move the unzipped file over to the appropriately-saved place
		file.rename( z , puf.savename )
	
	} else {
	
		# if the `dat` file was downloaded directly (not the zipped file)
		# then simply move the downloaded file to the appropriately-saved place
		file.rename( tf , puf.savename )
	
	}

	# end of puf downloading #

	
	# download and execute all scripts #

	# look for the R file first
	script.r <-
		paste0(
			"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/nis/nispuf" ,
			substr( year , 3 , 4 ) ,
			".r"
		)
	
	
	# try downloading the script directly
	rs <- try( download.cache( script.r , tf , mode = 'wb' ) , silent = TRUE )

	# if the r script does not exist..
	if( class( rs ) == 'try-error' ){	
		
		# look for a sas import script
		script.sas <-
			paste0(
				"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/nis/nispuf" ,
				substr( year , 3 , 4 ) ,
				".sas"
			)
		
		# save it to the local disk
		download.cache( script.sas , tf , mode = 'wb' )

		# load it into a character vector
		script.txt <- readLines( tf )
		
		# throw out everything at and after section d
		script.sub <- script.txt[ grep( "D. CREATES PERMANENT SAS DATASET|INFILE &flatfile LRECL=721|INFILE &flatfile LRECL=773" , script.txt ):length( script.txt ) ]

		# save the reduced sas import script to the local disk
		writeLines( script.sub , tf )
		
		# read the dat file directly into an R data.frame object,
		# using the `read.SAScii` function and the cdc's sas import script
		x <- 
			read.SAScii( 
				paste0( './puf/NISPUF' , substr( year , 3 , 4 ) , '.DAT' ) ,
				tf
			)
					
	} else {
	
		# load the r script into a character vector
		script.r <- readLines( tf )
		
		# change the path to the data to the local working directory
		script.r <- gsub( "path-to-data" , "." , script.r )
		
		# change the path to the file to the public use file directory within your current working directory
		script.r <- gsub( "path-to-file" , "./puf" , script.r )
	
		# everything after `Step 4:   ASSIGN VARIABLE LABELS` is unnecessary
		# converting these variables to factors blanks out many values that should not be blanked out
		# for a prime example, see what happens to the `seqnumhh` column.  whoops.
		
		# figure out the line position of step four within the character vector
		cutoff <- max( grep( "Step 4:   ASSIGN VARIABLE LABELS" , script.r , fixed = TRUE ) )
	
		# reduce the r script to its contents from the beginning up till step four
		script.r <- script.r[ seq( cutoff ) ]
	
		# save the r script back to the local disk
		writeLines( script.r , tf )
		
		# run the now-reduced r script
		source( tf , echo = TRUE )
		
		# create a character string containing the name of the nis puf data.frame object
		nis.df <- paste0( 'NISPUF' , substr( year , 3 , 4 ) )
		
		# copy the data.frame produced by the r script over to the object `x`
		x <- get( nis.df )
	
		# remove the data.frame produced by the r script from working memory
		rm( list = nis.df )
		
		# clear up RAM
		gc()
	
	}
	
	# convert all columns to lowercase
	names( x ) <- tolower( names( x ) )
	
	# save the r data.frame object to the local disk
	save( 
		x , 
		file = 
			paste0( 
				'./nis' , 
				year , 
				'.rda' 
			)
	)
	
	# remove the data.frame object `x` from working memory
	rm( x )
	
	# clear up RAM
	gc()

}


# loop through all teen nis years specified by the user
for ( year in nis.teen.years.to.download ){

	# print the current year to the screen
	print( year )

	
	# download all public use files #
	
	
	# create a character string containing the location to save the `dat` public use file after downloading
	puf.savename <- paste0( './puf/NISTEENPUF' , substr( year , 3 , 4 ) , '.DAT' )
	
	# construct the url of the `dat` file stored on the cdc's website
	straight.dat <-
		paste0(
			"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/nis/nisteenpuf" ,
			substr( year , 3 , 4 ) ,
			".dat"
		)

	# download the `dat` file from the cdc's website directly
	download.cache( straight.dat , tf , mode = 'wb' )

	# move the downloaded file to the appropriately-saved place
	file.rename( tf , puf.savename )
	
	
	# end of puf downloading #

	
	# download and execute all scripts #

	# look for the R file first
	script.r <-
		paste0(
			"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/nis/nisteenpuf" ,
			substr( year , 3 , 4 ) ,
			".r"
		)
	
	
	# download the r script directly
	download.cache( script.r , tf , mode = 'wb' )

	# load the r script into a character vector
	script.r <- readLines( tf )
	
	# change the path to the data to the local working directory
	script.r <- gsub( "path-to-data" , "." , script.r )
	
	# change the path to the file to the public use file directory within your current working directory
	script.r <- gsub( "path-to-file" , "./puf" , script.r )

	# correct lines of the r script that just are not allowed
	script.r <- gsub( "IHQSTATUSlevels=c(,M,N,V)" , "IHQSTATUSlevels=c(NA,'M','N','V')" , script.r , fixed = TRUE )
	
	# this line also creates an error.  nope.  fix it.
	script.r <- gsub( "=c(," , "=c(NA," , script.r , fixed = TRUE )

	# everything after `Step 4:   ASSIGN VARIABLE LABELS` is unnecessary
	# converting these variables to factors blanks out many values that should not be blanked out
	# for a prime example, see what happens to the `seqnumhh` column.  whoops.
	
	# figure out the line position of step four within the character vector
	cutoff <- max( grep( "Step 4:   ASSIGN VARIABLE LABELS" , script.r , fixed = TRUE ) )

	# reduce the r script to its contents from the beginning up till step four
	script.r <- script.r[ seq( cutoff ) ]

	# save the r script back to the local disk
	writeLines( script.r , tf )
	
	# run the now-reduced r script
	source( tf , echo = TRUE )
	
	# create a character string containing the name of the nis teen puf data.frame object
	nis.df <- paste0( 'NISTEENPUF' , substr( year , 3 , 4 ) )
	
	# copy the data.frame produced by the r script over to the object `x`
	x <- get( nis.df )

	# remove the data.frame produced by the r script from working memory
	rm( list = nis.df )
	
	# clear up RAM
	gc()

	
	# convert all columns to lowercase
	names( x ) <- tolower( names( x ) )
	
	# save the r data.frame object to the local disk
	save( 
		x , 
		file = 
			paste0( 
				'./nisteen' , 
				year , 
				'.rda' 
			)
	)

	# remove the `x` object from working memory
	rm( x )
	
	# clear up RAM
	gc()

}


# download the h1n1 file if specified by the user
if ( nhfs.download ){

	# print what you're working on.
	print( "2009 h1n1 flu survey" )

	# download all public use files #

	# specify the local path to save the public use file
	puf.savename <- './puf/NHFSPUF.DAT'
	
	# specify the url to download from
	straight.dat <-
		"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/nis/nhfs/nhfspuf.dat"
		
	# download that pup
	download.cache( straight.dat , tf , mode = 'wb' )

	# copy the downloaded file over to the save location
	file.rename( tf , puf.savename )

	
	# download and execute all scripts #

	# look for the R file first
	script.r <-
		"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/nis/nhfs/nhfspuf.r"
	
	
	# download the r script to the local disk
	download.cache( script.r , tf , mode = 'wb' )

	
	# load the r script into a character vector
	script.r <- readLines( tf )
	
	# change the path to the data to the local working directory
	script.r <- gsub( "path-to-data" , "." , script.r )
	
	# change the path to the file to the public use file directory within your current working directory
	script.r <- gsub( "path-to-file" , "./puf" , script.r )

	# everything after `Step 4:   ASSIGN VARIABLE LABELS` is unnecessary
	# converting these variables to factors blanks out many values that should not be blanked out
	# for a prime example, see what happens to the `seqnumhh` column.  whoops.
	
	# figure out the line position of step four within the character vector
	cutoff <- max( grep( "Step 4:   ASSIGN VARIABLE LABELS" , script.r , fixed = TRUE ) )

	# reduce the r script to its contents from the beginning up till step four
	script.r <- script.r[ seq( cutoff ) ]

	# save the r script back to the local disk
	writeLines( script.r , tf )
	
	# run the now-reduced r script
	source( tf , echo = TRUE )
	
	# copy the data.frame produced by the r script over to `x`
	x <- NHFSPUF
	
	# remove the object `x` from working memory
	rm( NHFSPUF )
		
	# clear up RAM
	gc()
	
	# convert all column names to lowercase
	names( x ) <- tolower( names( x ) )
	
	# save the r data.frame object to the local disk
	save( 
		x , 
		file = 
			'./nhfs2009.rda'
	)
	
	# remove the data.frame object from working memory
	rm( x )
	
	# clear up RAM
	gc()

}


# print a reminder: set the directory you just saved everything to as read-only!
message( paste0( "all done.  you should set the directory " , getwd() , " read-only so you don't accidentally alter these tables." ) )


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
