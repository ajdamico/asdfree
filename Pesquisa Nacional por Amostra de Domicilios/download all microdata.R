# analyze survey data for free (http://asdfree.com) with the r language
# pesquisa nacional por amostra de domicilios
# 2001 - 2014

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( encoding = "windows-1252" )		# # only macintosh and *nix users need this line
# library(downloader)
# setwd( "C:/My Directory/PNAD/" )
# years.to.download <- c( 2001:2009 , 2011:2015 )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Pesquisa%20Nacional%20por%20Amostra%20de%20Domicilios/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# djalma pessoa
# pessoad@gmail.com

# anthony joseph damico
# ajdamico@gmail.com


###################################################################################
# Analyze the 2001 - 2015 Pesquisa Nacional por Amostra de Domicilios file with R #
###################################################################################


# set your working directory.
# the PNAD 2001 - 2015 data files will be stored here
# after downloading and importing them.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PNAD/" )
# ..in order to set your current working directory


# # # are you on a non-windows system? # # #
if ( .Platform$OS.type != 'windows' ) print( 'non-windows users: read this block' )
# ibge's ftp site has a few SAS importation
# scripts in a non-standard format
# if so, before running this whole download program,
# you might need to run this line..
# options( encoding="windows-1252" )
# ..to turn on windows-style encoding.
# # # end of non-windows system edits.


# remove the # in order to run this install.packages line only once
# install.packages( c( "MonetDBLite" , "survey" , "SAScii" , "descr" , "downloader" , "digest" , "stringr" , "R.utils" ) )

# define which years to download #

# uncomment this line to download all available data sets
# uncomment this line by removing the `#` at the front
# years.to.download <- c( 2001:2009 , 2011:2015 )

# uncomment this line to download only a single year
# years.to.download <- 2011

# uncomment this line to download, for example, 2005 and 2007-2009
# years.to.download <- c( 2009:2007 , 2005 )


# name the database files in the "MonetDB" folder of the current working directory
pnad.dbfolder <- paste0( getwd() , "/MonetDB" )


############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #

library(MonetDBLite)
library(DBI)			# load the DBI package (implements the R-database coding)
library(SAScii) 		# load the SAScii package (imports ascii data with a SAS script)
library(descr) 			# load the descr package (converts fixed-width files to delimited files)
library(downloader)		# downloads and then runs the source() function on scripts from github
library(R.utils)		# load the R.utils package (counts the number of lines in a file quickly)


# this script's download files should be incorporated in download_cached's hash list
options( "download_cached.hashwarn" = TRUE )
# warn the user if the hash does not yet exist

# load the download_cached and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url( 
	"https://raw.githubusercontent.com/ajdamico/asdfree/master/Download%20Cache/download%20cache.R" , 
	prompt = FALSE , 
	echo = FALSE 
)


# load the read.SAScii.monetdb function (a variant of read.SAScii that creates a database directly)
source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/MonetDB/read.SAScii.monetdb.R" , prompt = FALSE )

# load pnad-specific functions (to remove invalid SAS input script fields and postStratify a database-backed survey object)
source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Pesquisa%20Nacional%20por%20Amostra%20de%20Domicilios/pnad.survey.R" , prompt = FALSE )



# create a temporary file and a temporary directory..
tf <- tempfile() ; td <- tempdir()

# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite::MonetDBLite() , pnad.dbfolder )


# download and import the tables containing missing codes
download( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Pesquisa%20Nacional%20por%20Amostra%20de%20Domicilios/household_nr.csv" , tf )
household.nr <- read.csv( tf , colClasses = 'character' )

download( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Pesquisa%20Nacional%20por%20Amostra%20de%20Domicilios/person_nr.csv" , tf )
person.nr <- read.csv( tf , colClasses = 'character' )

# convert these tables to lowercase
names( household.nr ) <- tolower( names( household.nr ) )
names( person.nr ) <- tolower( names( person.nr ) )

# remove all spaces between missing codes
household.nr$code <- gsub( " " , "" , household.nr$code )
person.nr$code <- gsub( " " , "" , person.nr$code )

# convert all code column names to lowercase
household.nr$variable <- tolower( household.nr$variable )
person.nr$variable <- tolower( person.nr$variable )


# begin looping through every pnad year specified
for ( year in years.to.download ){

	cat( 'currently working on' , year )

	# # # # # # # # # # # #
	# load the main file  #
	# # # # # # # # # # # #

	# this process is slow.
	# for example, the PNAD 2011 file has 358,919 person-records.

	# note: this PNAD ASCII (fixed-width file) contains household- and person-level records.

	if ( year < 2013 ){
		
		# figure out the exact filepath of the re-weighted pnad year
		ftp.path <-
			paste0(
				"ftp://ftp.ibge.gov.br/Trabalho_e_Rendimento/Pesquisa_Nacional_por_Amostra_de_Domicilios_anual/microdados/reponderacao_2001_2012/PNAD_reponderado_" ,
				year , if( year %in% c( 2003 , 2007 , 2009:2012 ) ) "_2012_20150814" ,
				".zip"
			)

		# download the data and sas importation instructions all at once..
		download_cached( ftp.path , tf , mode = "wb" )
		
		# ..then also unzip them into the temporary directory
		files <- unzip( tf , exdir = td )

	# if the files aren't already in a convenient zipped file..
	} else {
	
		# point to their main path
		ftp.path <-
			paste0( 
				"ftp://ftp.ibge.gov.br/Trabalho_e_Rendimento/Pesquisa_Nacional_por_Amostra_de_Domicilios_anual/microdados/" , 
				year , 
				"/" 
			)
	
		# blank out the files object from the previous go-round of the loop
		files <- NULL
	
		# loop through each of the files you might need
		for ( this.file in c( "Dados.zip" , "Dicionarios_e_input.zip" ) ) {
		
			if ( year == 2013 & this.file == "Dicionarios_e_input.zip" ) this.file <- "Dicionarios_e_input_20150814.zip"
		
			if( year == 2014 ) this.file <- gsub( "\\.zip" , "_20161116.zip" , this.file )
			
		
			try({
				
				# give downloading 'em a shot
				download_cached( paste0( ftp.path , this.file ) , tf , mode = 'wb' )
				
				# unzip them into the same place
				files <- c( files , unzip( tf , exdir = td ) )
				
			} , silent = TRUE )
			
		}
	
	}

	# manually set the encoding of the unziped files so they don't break things.
	if( year %in% 2013:2014 & .Platform$OS.type != 'windows' ) Encoding( files ) <- 'UTF-8' else Encoding( files ) <- 'latin1'
	
	
	# remove the UF column and the mistake with "LOCAL ÚLTIMO FURTO"
	# described in the remove.uf() function that was loaded with source_url as pnad.survey.R
	dom.sas <- remove.uf( files[ grepl( paste0( 'input[^?]dom' , year , '.txt' ) , tolower( files ) ) ] )
	pes.sas <- remove.uf( files[ grepl( paste0( 'input[^?]pes' , year , '.txt' ) , tolower( files ) ) ] )

	# in 2003 and 2007, the age variable had been read in as a factor variable
	# which breaks certain commands by treating the variable incorrectly as a factor
	if( year %in% c( 2003 , 2007 ) ){
		pes_lines <- readLines( pes.sas )
		pes_lines <- gsub( "@00027( *)V8005( *)\\$3\\." , "@00027 V8005 3\\." , pes_lines )
		writeLines( pes_lines , pes.sas )
	}
	
	# since `files` contains multiple file paths,
	# determine the filepath on the local disk to the household (dom) and person (pes) files
	dom.fn <- files[ grepl( paste0( '/dom' , year ) , tolower( files ) ) ]
	pes.fn <- files[ grepl( paste0( '/pes' , year ) , tolower( files ) ) ]

	first_attempt_dom <- 
		try({
			# store the PNAD household records as a MonetDBLite database
			read.SAScii.monetdb ( 
				dom.fn , 
				dom.sas , 
				zipped = F , 
				tl = TRUE ,
				# this default table naming setup will name the household-level tables dom2001, dom2002, dom2003 and so on
				tablename = paste0( 'dom' , year ) ,
				conn = db
			)

			} , silent = TRUE )
	
	# if the read.SAScii.monetdb attempts broke,
	# remove the dots in the files
	# and try again
	if( class( first_attempt_dom ) == 'try-error' ){
			
		dom.fn2 <- tempfile()
		fpx <- file( normalizePath( dom.fn ) , 'r' )
		# create a write-only file connection to the temporary file
		fpt <- file( dom.fn2 , 'w' )

		# loop through every line in the original file..
		while ( length( line <- readLines( fpx , 1 ) ) > 0 ){
		
			# replace '.' with nothings..
			line <- gsub( " ." , "  " , line , fixed = TRUE )
			line <- gsub( ". " , "  " , line , fixed = TRUE )
			
			# and write the result to the temporary file connection
			writeLines( line , fpt )
		}
		
		# close the temporary file connection
		close( fpx )
		close( fpt )

		# store the PNAD household records as a MonetDBLite database
		read.SAScii.monetdb ( 
			dom.fn2 , 
			dom.sas , 
			zipped = F , 
			tl = TRUE ,
			# this default table naming setup will name the household-level tables dom2001, dom2002, dom2003 and so on
			tablename = paste0( 'dom' , year ) ,
			conn = db
		)
		
		files <- c( files , dom.fn2 )
		
		stopifnot( countLines( dom.fn ) == dbGetQuery( db , paste0( "SELECT COUNT(*) FROM dom" , year ) )[ 1 , 1 ] )
		
	}
	
	first_attempt_pes <- 
		try({
		
			# store the PNAD person records as a MonetDBLite database
			read.SAScii.monetdb ( 
				pes.fn , 
				pes.sas , 
				zipped = F , 
				tl = TRUE ,
				# this default table naming setup will name the person-level tables pes2001, pes2002, pes2003 and so on
				tablename = paste0( 'pes' , year ) ,
				conn = db
			)
	
		} , silent = TRUE )
	
	# if the read.SAScii.monetdb attempts broke,
	# remove the dots in the files
	# and try again
	if( class( first_attempt_pes ) == 'try-error' ){

		pes.fn2 <- tempfile()
		
		fpx <- file( normalizePath( pes.fn ) , 'r' )
		# create a write-only file connection to the temporary file
		fpt <- file( pes.fn2 , 'w' )

		# loop through every line in the original file..
		while ( length( line <- readLines( fpx , 1 ) ) > 0 ){
		
			# replace '.' with nothings..
			line <- gsub( " ." , "  " , line , fixed = TRUE )
			line <- gsub( ". " , "  " , line , fixed = TRUE )
			line <- gsub( "\U00A0" , " " , line )

			# and write the result to the temporary file connection
			writeLines( line , fpt )
		}
		
		# close the temporary file connection
		close( fpx )
		close( fpt )
		
	
		# store the PNAD person records as a MonetDBLite database
		read.SAScii.monetdb ( 
			pes.fn2 , 
			pes.sas , 
			zipped = F , 
			tl = TRUE ,
			# this default table naming setup will name the person-level tables pes2001, pes2002, pes2003 and so on
			tablename = paste0( 'pes' , year ) ,
			conn = db
		)

		files <- c( files , pes.fn2 )
		
		stopifnot( countLines( pes.fn ) == dbGetQuery( db , paste0( "SELECT COUNT(*) FROM pes" , year ) )[ 1 , 1 ] )
		
	}
			
	# the ASCII and SAS importation instructions stored in temporary files
	# on the local disk are no longer necessary, so delete them.
	attempt.one <- try( file.remove( files ) , silent = TRUE )
	# weird brazilian file encoding operates differently on mac+*nix versus windows, so try both ways.
	if( class( attempt.one ) == 'try-error' ) { Encoding( files ) <- '' ; file.remove( files ) }
	
	# add 4617 and 4618 to 2001 file
	if( year == 2001 ){
	
		dbSendQuery( db , "ALTER TABLE dom2001 ADD COLUMN v4617 real" )
		dbSendQuery( db , "ALTER TABLE dom2001 ADD COLUMN v4618 real" )
	
		dbSendQuery( db , "UPDATE dom2001 SET v4617 = strat" )
		dbSendQuery( db , "UPDATE dom2001 SET v4618 = psu" )
		
	}
	
	# missing level blank-outs #
	# this section loops through the non-response values & variables for all years
	# and sets those variables to NULL.
	cat( 'non-response variable blanking-out only occurs on numeric variables\n' )
	cat( 'categorical variable blanks are usually 9 in the pnad\n' )
	cat( 'thanks for listening\n' )
	
	# loop through each row in the missing household-level  codes table
	for ( curRow in seq( nrow( household.nr ) ) ){

		# if the variable is in the current table..
		if( household.nr[ curRow , 'variable' ] %in% dbListFields( db , paste0( 'dom' , year ) ) ){

			# ..and the variable should be recoded for that year
			if( year %in% eval( parse( text = household.nr[ curRow , 'year' ] ) ) ){
		
				# update all variables where that code equals the `missing` code to NA (NULL in MonetDBLite)
				dbSendQuery( 
					db , 
					paste0( 
						'update dom' , 
						year , 
						' set ' , 
						household.nr[ curRow , 'variable' ] , 
						" = NULL where " ,
						household.nr[ curRow , 'variable' ] ,
						' = ' ,
						household.nr[ curRow , 'code' ]
					)
				)
			
			}
		}
	}

	# loop through each row in the missing person-level codes table
	for ( curRow in seq( nrow( person.nr ) ) ){

		# if the variable is in the current table..
		if( person.nr[ curRow , 'variable' ] %in% dbListFields( db , paste0( 'pes' , year ) ) ){
		
			# ..and the variable should be recoded for that year
			if( year %in% eval( parse( text = person.nr[ curRow , 'year' ] ) ) ){
		
				# update all variables where that code equals the `missing` code to NA (NULL in MonetDBLite)
				dbSendQuery( 
					db , 
					paste0( 
						'update pes' , 
						year , 
						' set ' , 
						person.nr[ curRow , 'variable' ] , 
						" = NULL where " ,
						person.nr[ curRow , 'variable' ] ,
						' = ' ,
						person.nr[ curRow , 'code' ]
					)
				)
			
			}
		}
	}

	# confirm no fields are in `dom` unless they are in `pes`
	b_fields <- dbListFields( db , paste0( 'dom' , year ) )[ !( dbListFields( db , paste0( 'dom' , year ) ) %in% dbListFields( db , paste0( 'pes' , year ) ) ) ]
	
	# create the merged file
	dbSendQuery( 
		db , 
		paste0( 
			# this default table naming setup will name the final merged tables pes2001, pes2002, pes2003 and so on
			"create table pnad" , 
			year , 
			# also add a new column "one" that simply contains the number 1 for every record in the data set
			# also add a new column "uf" that contains the state code, since these were thrown out of the SAS script
			# also add a new column "region" that contains the larger region, since these are shown in the tables
			# NOTE: the substr() function luckily works in MonetDBLite::MonetDBLite() databases, but may not work if you change SQL database engines to something else.
			" as select a.* , " ,
			paste( b_fields , collapse = "," ) ,
			" , 1 as one , substr( a.v0102 , 1 , 2 ) as uf , substr( a.v0102 , 1 , 1 ) as region from pes" , 
			year , 
			" as a inner join dom" , 
			year , 
			" as b on a.v0101 = b.v0101 AND a.v0102 = b.v0102 AND a.v0103 = b.v0103" 
		)
	)

	# determine if the table contains a `v4619` variable.
	# v4619 is the factor of subsampling used to compensate the loss of units in some states
	# for 2012, the variable v4619 is one and so it is not needed.
	# if it does not, create it.
	any.v4619 <- 'v4619' %in% dbListFields( db , paste0( 'pnad' , year ) )

	# if it's not in there, copy it over
	if ( !any.v4619 ) {
		dbSendQuery( db , paste0( 'alter table pnad' , year , ' add column v4619 real' ) )
		dbSendQuery( db , paste0( 'update pnad' , year , ' set v4619 = 1' ) )
	}
	
	# now create the pre-stratified weight to be used in all of the survey designs
	# if it's not in there, copy it over
	dbSendQuery( db , paste0( 'alter table pnad' , year , ' add column pre_wgt real' ) )

	if( year < 2004 ){
		dbSendQuery( db , paste0( 'update pnad' , year , ' set pre_wgt = v4610' ) )
	} else {
		dbSendQuery( db , paste0( 'update pnad' , year , ' set pre_wgt = v4619 * v4610' ) )	
	}
	
	# confirm that the number of records in the pnad merged file
	# matches the number of records in the person file
	stopifnot( 
		dbGetQuery( db , paste0( "select count(*) as count from pes" , year ) ) == 
		dbGetQuery( db , paste0( "select count(*) as count from pnad" , year ) ) 
	)

	
}

# take a look at all the new data tables that have been added to your RAM-free MonetDBLite database
dbListTables( db )

# disconnect from the current database
dbDisconnect( db , shutdown = TRUE )

# remove the temporary file from the local disk
file.remove( tf )

