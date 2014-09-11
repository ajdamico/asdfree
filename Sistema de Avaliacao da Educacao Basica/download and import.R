# analyze survey data for free (http://asdfree.com) with the r language
# sistema de avaliacao da educacao basica
# all available years

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/SAEB/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Sistema%20de%20Avaliacao%20da%20Educacao%20Basica/download%20and%20import.R" , prompt = FALSE , echo = TRUE )
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



################################################################
# download all sistema de avaliacao da educacao basico with R, #
# then save every file as both sqlite and (where possible) rda #
################################################################


# set your working directory.
# all SAEB files will be stored here
# after downloading and importing it.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/SAEB/" )
# ..in order to set your current working directory


# remove the # in order to run this install.packages line only once
# install.packages( c ( "SAScii" , "RSQLite" , "downloader" ) )



############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #


library(RSQLite) 	# load RSQLite package (creates database files in R)
library(SAScii)		# load the SAScii package (imports ascii data with a SAS script)
library(downloader)	# downloads and then runs the source() function on scripts from github


# specify which years of saeb data are currently available for download
years.to.download <- c( 1995 , 1997 , 1999 , 2001 , 2003 , 2005 , 2011 )



# load the download.cache and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url(
	"https://raw.github.com/ajdamico/usgsd/master/Download%20Cache/download%20cache.R" ,
	prompt = FALSE ,
	echo = FALSE
)


# within the current working directory,
# create a directory to save all downloaded files
dir.create( "./download" )


# create a temporary file and a temporary directory
tf <- tempfile() ; td <- tempdir()

# loop through all years slated for download
for ( year in years.to.download ){

	# the years prior to 2002 have a different zipped filepath on the ftp:// site than the years 2002 and later.
	# knowing that, define the full filepath of the zipped file to download
	if ( year < 2002 ){
		file.to.download <- paste0( "ftp://ftp.inep.gov.br/microdados/micro_saeb" , year , ".zip" )
	} else file.to.download <- paste0( "ftp://ftp.inep.gov.br/microdados/microdados_saeb_" , year , ".zip" )

	# specify the location on the local disk to save that zipped file
	local.zip <- paste0( "./download/microdados_saeb_" , year , ".zip" )

	# download the current file.  if it's been downloaded in the past,
	# simply pull it from your computer's cache instead.
	download.cache( file.to.download , local.zip )

	# specify the directory of the current year
	year.directory <- paste0( "./" , year )

	# create that directory,
	# also within the current working directory
	dir.create( year.directory )

	# unzip all files contained in the zipped file
	# into the temporary directory
	z <- unzip( local.zip , exdir = td )

	# does the zipped file contain any more zipped files?
	other.zips <- z[ grep( '\\.zip$' , tolower( z ) ) ]
	
	# if so, go through them, unzip them, add them to the object `z`
	for ( i in other.zips ){
		
		# unzip each of those again to the temporary directory
		z.zip <- unzip( i , exdir = td )
	
		# add filepaths to the `z` object each time
		z <- c( z , z.zip )
	}

	# this file is corrupt and not needed
	if ( any( to.fix <- grepl( "INPUTS_SAS_SPSS/ALUNOS/~$PUT_SAS_QUIMICA_03ANO.SAS" , z , fixed = TRUE ) ) ){
		
		# delete it from its location on the hard drives
		file.remove( z[ to.fix ] )
		
		# remove it from `z`
		z <- z[ !to.fix ]
	}

	# since text files (containing data) and sas files (containing importation instructions) need to align
	# any files where they do not need to be renamed.  diretor, docente, escola, turma are all examples
	# of imperfect filename matches.  align them in every case in `z`
	if( any( to.fix <- grepl( "DIRETOR_|DOCENTE_|ESCOLA_|TURMA_" , z ) ) ){
		
		# rename all files containing `diretor` to `diretores`
		file.rename( z[ to.fix ] , gsub( "DIRETOR_" , "DIRETORES_" , z[ to.fix ] , fixed = TRUE ) )
		
		# update the `z` object (the character vector containing the file positions on the local disk)
		z <- gsub( "DIRETOR_" , "DIRETORES_" , z , fixed = TRUE )

		# same as above
		file.rename( z[ to.fix ] , gsub( "DOCENTE_" , "DOCENTES_" , z[ to.fix ] , fixed = TRUE ) )
		z <- gsub( "DOCENTE_" , "DOCENTES_" , z , fixed = TRUE )

		# same as same as above
		file.rename( z[ to.fix ] , gsub( "ESCOLA_" , "ESCOLAS_" , z[ to.fix ] , fixed = TRUE ) )
		z <- gsub( "ESCOLA_" , "ESCOLAS_" , z , fixed = TRUE )

		# (same as)^3 above
		file.rename( z[ to.fix ] , gsub( "TURMA_" , "TURMAS_" , z[ to.fix ] , fixed = TRUE ) )
		z <- gsub( "TURMA_" , "TURMAS_" , z , fixed = TRUE )

	}

			
	# identify all files ending with `.sas` and `.txt` and `.csv`
	sas.files <- z[ grep( '\\.sas$' , tolower( z ) ) ]
	text.files <- z[ grep( '\\.txt$' , tolower( z ) ) ]
	csv.files <- z[ grep( '\\.csv$' , tolower( z ) ) ]
	# store each of those into separate character vectors, subsets of `z`

	# confirm each sas file matches a text file and vice versa
	stopifnot ( all( gsub( "\\.txt$" , "" , tolower( basename( text.files ) ) ) %in% gsub( "i[m|n]put_sas_(.*)\\.sas$" , "\\1" , tolower( basename( sas.files ) ) ) ) ) 

	# loop through each available sas importation file..
	for ( i in sas.files ){
		
		# write the file to the disk
		w <- readLines( i )
		
		# remove all tab characters
		w <- gsub( '\t' , ' ' , w )
		
		# overwrite the file on the disk with the newly de-tabbed text
		writeLines( w , i )
	}

	# loop through each available txt (data) file..
	for ( this.text in text.files ){

		# remove the `.txt` to determine the name of the current table
		table.name <- gsub( "\\.txt$" , "" , tolower( basename( this.text ) ) )

		# find the appropriate sas importation instructions to be used for the current table
		this.sas <- sas.files[ match( table.name , gsub( "i[m|n]put_sas_(.*)\\.sas$" , "\\1" , tolower( basename( sas.files ) ) ) ) ]
		
		# read the data file directly into an R data frame object
		x <- read.SAScii( this.text , this.sas )

		# connect to (and, if it doesn't exist, initiate) a sqlite database
		db <- dbConnect( SQLite() , paste0( "./" , year , "/saeb.db" ) )
	
		# store the `x` data.frame object in sqlite database as well
		dbWriteTable( db , table.name , x )
		
		# disconnect from the sqlite database
		dbDisconnect( db )

		# copy the object `x` over to what it actually should be named
		assign( table.name , x )
		
		# remove the `x` object from working memory
		rm( x )

		# clear up RAM
		gc()

		# save the current table in the year-specific folder on the local drive
		save( list = table.name , file = paste0( "./" , year , "/" , table.name , ".rda" ) )

		# remove the current table from working memory
		rm( list = table.name )

		# clear up RAM
		gc()

	}

	# loop through each available csv (also data) file..
	for ( this.csv in csv.files ){
	
		# connect to (and, if it doesn't exist, initiate) a sqlite database
		db <- dbConnect( SQLite() , paste0( "./" , year , "/saeb.db" ) )
	
		# remove the `.csv` to determine the name of the current table
		table.name <- gsub( "\\.csv$" , "" , tolower( basename( this.csv ) ) )

		# specify the chunk size to read in
		chunk_size <- 250000

		# create a file connection to the current csv
		input <- file( this.csv , "r")

		# read in the first chunk
		headers <- read.csv( input , sep = ";" , dec = "," , na.strings = "." , nrows = chunk_size )
		
		cc <- sapply( headers , class )

		# initiate the current table
		dbWriteTable( db , table.name , headers , overwrite = TRUE , row.names = FALSE )
		
		# so long as there are lines to read, add them to the current table
		tryCatch({
		   while (TRUE) {
			   part <- 
				read.csv(
					input , 
					header = FALSE ,
					nrows = chunk_size , 
					sep = ";" ,
					dec = "," ,
					na.strings = "." , 
					colClasses = cc
				)
				
			   dbWriteTable( db , table.name , part , append = TRUE , row.names = FALSE )
		   }
		   
		} , error = function(e) { if ( grepl( "no lines available" , conditionMessage( e ) ) ) TRUE else stop( conditionMessage( e ) ) }
		)
		
		# clear up RAM
		rm( headers , part ) ; gc()
		
		# disconnect from the sqlite database
		dbDisconnect( db )
		
	}
	
}

# remove all files stored on the local disk in the temporary directory
unlink( td , recursive = TRUE )


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
