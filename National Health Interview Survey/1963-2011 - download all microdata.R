# analyze us government survey data with the r language
# national health interview survey
# 1963 through 2011
# all available files (including documentation)

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


######################################################################################
# download every file from every year of the National Health Interview Survey with R #
# then save every file as an R data frame (.rda) so future analyses can be rapid     #
######################################################################################


# first, decide whether you would like to download the documentation as well?
# change this TRUE to FALSE if you prefer to skip that component
download.documentation <- TRUE


# set your working directory.
# each year of the NHIS will be stored in a year-specific folder here
# after downloading and importing it.
# use forward slashes instead of back slashes

setwd( "C:/My Directory/NHIS/" )


# remove the # in order to run this install.packages line only once
# install.packages( c( "SAScii" , "RCurl" ) )


# define which years to download #

# this line will download every year of data available
nhis.years.to.download <- 2011:1963

# uncomment this line to only download the most current year
# nhis.years.to.download <- 2011

# uncomment this line to download, for example, 2000 and 2009-2011
# nhis.years.to.download <- c( 2011:2009 , 2000 )


# no need to edit anything below this line #


# # # # # # # # #
# program start #
# # # # # # # # #

library(RCurl)	# load RCurl package (downloads files from the web)
require(SAScii) # load the SAScii package (imports ascii data with a SAS script)


# create a temporary file and a temporary directory
tf <- tempfile() ; td <- tempdir()

# main NHIS ftp site
main.nhis.ftp <- "ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/"


# begin looping through every year specified
for ( year in nhis.years.to.download ){

	# year-specific output directory
	output.directory <- paste0( getwd() , "/" , year , "/" )
	
	# if the year-specific output directory doesn't exist, create it
	try( dir.create( output.directory ) , silent = T )

	
	# # # # # # # # # # # # # # # # # # # #
	# download documentation if specified #
	# # # # # # # # # # # # # # # # # # # #
	
	if ( download.documentation ){

		# year-specific docs output directory
		docs.output.directory <- paste0( output.directory , "docs/" )
	
		# if the docs directory within the year-specific output directory doesn't exist, create it
		try( dir.create( docs.output.directory ) , silent = T )
	
		# create the full string to the FTP folder of the current year
		# for the documentation directory
		doc.nhis.ftp <- paste0( "ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/NHIS/" , year , "/" )
		
		# extract all the file names in the current nhis ftp directory
		doc.files <- getURL( doc.nhis.ftp , dirlistonly = TRUE )
		doc.files <- tolower( strsplit( doc.files , "\r*\n" )[[1]] )
		
		# loop through each file and save it to the year-specific docs directory
		for ( fn in doc.files ) download.file( paste0( doc.nhis.ftp , fn ) , destfile = paste0( docs.output.directory , fn ) , mode = 'wb' )
		
	}
	
	# # # # # # # # # # # # # # # # # #
	# documentation download complete #
	# # # # # # # # # # # # # # # # # #

	
	# create the full string to the FTP folder of the current year
	year.nhis.ftp <- paste0( main.nhis.ftp , year , "/" )

	# figure out what all of the files within that folder are named
	ftp.files <- getURL( year.nhis.ftp , dirlistonly = TRUE )
	ftp.files <- tolower( strsplit( ftp.files , "\r*\n" )[[1]] )


	# # # # # # # # # # # # # # # # # # # #
	# make a bunch of download exceptions #
	# # # # # # # # # # # # # # # # # # # #

	##############################################
	# manual recode for 2004 directory structure #
	##############################################

	# since everything is in its own directory,
	# just go straight to the file!
	if ( year == 2004 )	ftp.files <- c(
		"./familyfile/familyxx.exe",
		"./household/househld.exe",
		"./InjuryPoison/injpoiep.exe",
		# note that this skips the injury verbatim file!
		# "./InjuryVerbatim/injverbt.exe",
		"./person/personsx.exe",
		"./sampleadult/samadult.exe",
		"./samplechild/samchild.exe" )


	#################################
	# data files to skip completely #
	#################################
	
	# the 1974 healthin file has WTBDD2W and WTBDD2WB (in the SAS input file) in the wrong order
	if ( year == 1974 ) ftp.files <- ftp.files[ ! ( ftp.files %in% 'healthin.exe' ) ]
		
	# skip 1988 mdevices file
	if ( year == 1988 ) ftp.files <- ftp.files[ ! ( ftp.files %in% "mdevices.exe" ) ]

	# skip 1994 and 1995 dfs files
	if ( year %in% c( 1994 , 1995 ) ) ftp.files <- ftp.files[ ! ( ftp.files %in% c( "dfschild.exe" , "dfsadult.exe" ) ) ]

	# skip the 1992 nursing home files
	if ( year == 1992 ) ftp.files <- ftp.files[ ! ( ftp.files %in% c( "conditnh.exe" , "drvisinh.exe" , "hospitnh.exe" , "househnh.exe" , "personnh.exe" ) ) ]

	# skip the 2007 alternative medicine and injury verbatim files
	if ( year == 2007 ) ftp.files <- ftp.files[ ! ( ftp.files %in% c( "althealt.exe" , "injverbt.exe" ) ) ]

	# skip the 1999 and 2000 injury verbatim file
	if ( year %in% c( 1998:2000 , 2008 , 2009 ) ) ftp.files <- ftp.files[ ! ( ftp.files %in% "injverbt.exe" ) ]

	# # # # # # # # # # # # # # # # # # #
	# finished with download exceptions #
	# # # # # # # # # # # # # # # # # # #
	
	
	# if a file.zip and a file.exe both exist, only take the file.exe #
	
	# identify all .exe files..
	exe.filenames <- ftp.files[ grepl( ".exe" , ftp.files ) ]
	
	# identify all .zip files..
	zip.filenames <- ftp.files[ grepl( ".zip" , ftp.files ) ]
	
	# identify overlap between .zip and .exe files
	exe.filenames <- gsub( ".exe" , "" , exe.filenames )
	zip.filenames <- gsub( ".zip" , "" , zip.filenames )
	duplicate.filenames <- zip.filenames[ (zip.filenames %in% exe.filenames) ]
	zip.filenames.with.exe.matches <- paste( duplicate.filenames , ".zip" , sep = "" )
	
	# throw out .zip files that match a .exe file exactly
	ftp.files <- ftp.files[ ! ( ftp.files %in% zip.filenames.with.exe.matches ) ]
	
	# end of throwing out file.zip files that match file.exe files #	
	
	# throw out folders (assumed to be files without a . in them)
	# (any files in folders within the main year folder need to be downloaded separately)
	ftp.files <- ftp.files[ grepl( "\\." , ftp.files ) ]

	# loop through every fn (filename) inside of the ftp.files available
	for ( fn in ftp.files ){
	
		# print the current year and file name
		print( paste( "currently working on" , year , "file" , fn ) )
	
		# determine the exact ftp location (efl) of the file on the nhis ftp site
		efl <- paste0( year.nhis.ftp , fn )

		# figure out where the final '/' lies in the string
		sl <- max( gregexpr( "\\/" , fn )[[1]] )
		
		# figure out where the laste '.' lies in the string
		dp <- max( gregexpr( "\\." , fn )[[ 1 ]] )
				
		# use that to figure out the extension
		ext <- substr( fn , dp + 1 , nchar( fn ) ) 
		
		# if the file is a (.pdf) or a (.txt)..
		if ( ext %in% c( 'pdf' , 'txt' ) ){
		
			# simply download the file into the local directory
			download.file( efl , destfile = paste0( output.directory , fn ) , mode = 'wb' )
			
		# otherwise, treat the file as a data file
		# that needs to be imported as an R data frame
		} else {
			
			# isolate the fn up to (but not including) the decimal point
			# store as fv (fileval)
			fv <- substr( fn , sl + 1 , dp - 1 )
			
			# determine the path to the SAS read-in line
			# substr( fn , 1 , dp - 1 ) identifies the string up to the final '.sas' to allow the 2004 files' folder structure to work
			sas_ri <- paste0( "ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Program_Code/NHIS/" , year , "/" , substr( fn , 1 , dp - 1 ) , ".sas" )

			# read the nhis file directly into an R data frame
			nhis.df <- read.SAScii( efl , sas_ri , zipped = T )

			# convert all column names to lowercase
			names( nhis.df ) <- tolower( names( nhis.df ) )
			
			# determine the name of the R object (data.frame) to save the final table as..
			# NHIS.YY.fileval.df
			df.name <- paste( "NHIS" , substr( year , 3 , 4 ) , fv , "df" , sep = "." )
			
			# save the R data frame to that file-specific name
			assign( df.name , nhis.df )
				
			# save the R data frame to a .rda file on the local computer
			save( list = df.name , file = paste0( output.directory , "/" , fv , ".rda" ) )
			
			# remove both data frame objects from memory
			rm( list = c( "nhis.df" , df.name ) )
		
			# clear up RAM
			gc()

		}	
	}
	
	###########################
	# imputed income download #
	###########################
	
	# if the year is after 1996, then download the imputed income files
	if ( year > 1996 ){
		
		# imputed income files must be downloaded using a different method #
	
		# the imputed income files are in a different folder on the nhis ftp
		year.nhis.ftp <- paste0( main.nhis.ftp , year , "_imputed_income/" )

		# figure out what all of the files within that folder are named
		ftp.files <- getURL( year.nhis.ftp , dirlistonly = TRUE )
		ftp.files <- tolower( strsplit( ftp.files , "\r*\n" )[[1]] )

		# identify if the directory contains any .pdf or .txt files
		pdf.and.txt.files <- ftp.files[ grepl( '\\.pdf|\\.txt' , ftp.files ) ]
		
		# loop through each of those files..
		for ( i in pdf.and.txt.files ){
		
			# determine the exact ftp location (efl) of the file on the nhis ftp site
			efl <- paste0( year.nhis.ftp , i )
	
			# ..and simply download the file into the local directory
			download.file( efl , destfile = paste0( output.directory , i ) , mode = 'wb' )
			
		}
		
		# search for the SAS importation script (.sas)
		# this will determine which data file to read in
		sas.file <- ftp.files[ grepl( '.sas' , ftp.files ) ]

		# if the SAS importation script is 'imcmimp' - then the starting line for read.SAScii should be 80
		# if the SAS importation script is 'incimps' - then the starting line for read.SAScii should be 60
		SAScii.start <- ifelse( tolower( sas.file ) == 'incmimp.sas' , 80 , 60 )
		
		
		# the data file to download should have the exact same prefix
		# but either .exe or .zip as a suffix
		possible.exe <- gsub( '.sas' , '.exe' , sas.file )
		possible.zip <- gsub( '.sas' , '.zip' , sas.file )
		
		# if the '.exe' file exists in the directory,
		if ( possible.exe %in% ftp.files ){
		
			# use that as the file to download
			efl <- paste0( year.nhis.ftp , possible.exe )
			
		} else {
		
			# otherwise, assume the .zip file exists in the directory
			efl <- paste0( year.nhis.ftp , possible.zip )
			
		}
		
		# download the compressed file from the nhis ftp site
		# and save it to a temporary file on your local disk
		download.file( efl , tf , mode = "wb" )
		
		# unzip the file into a temporary directory.
		# the unzipped file should contain *five* ascii files
		income.file.names <- sort( unzip( tf , exdir = td ) )
			
		# loop through all five imputed income files
		for ( i in 1:length( income.file.names ) ){

			# print current progress to the screen
			print( paste( "currently working on imputed income file" , i , "of 5" ) )
		
			# read the ascii dat file directly into R with read.SAScii()
			ii <- 
				read.SAScii( 
					income.file.names[ i ] , 				# location of the ascii file in a temp directory on the local disk
					paste0( year.nhis.ftp , sas.file ) ,	# location of the sas import instructions on the nhis ftp site
					beginline = SAScii.start				# code line in the sas import instructions where the INPUT block begins (determined above)
				)

			# the read.SAScii function produces column names in whatever case specified by the sas importation script
			# convert them all to lowercase
			names( ii ) <- tolower( names( ii ) )

			# dump rectype variable from the imputed income data frame
			# it is already on the personsx file, so it will screw up the merge
			ii$rectype <- NULL
			
			# store the imputed income data table into a new data frame (named ii1 through ii5)
			assign( 
				paste0( "ii" , i ) , 
				ii
			)
			
			# delete ii (since it's also saved as ii#)
			ii <- NULL
			
			# garbage collection - free up RAM from recently-deleted data tables
			gc()
			
		}
		
		# save all five imputed income data frames to a single .rda file #
		
		# determine the output file name (ofn)
		ofn <- paste0( output.directory , gsub( '.sas' , '.rda' , sas.file ) )
		
		# then save ii1 - ii5 to that .rda file on the local disk
		save( list = paste0( "ii" , 1:5 ) , file = "ii.rda" )
		
		# remove all five imputed income data tables from RAM
		rm( list = paste0( "ii" , 1:5 ) )
		
		# garbage collection - free up RAM from recently-deleted data tables
		gc()
		
	}
}
# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
