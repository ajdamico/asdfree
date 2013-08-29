# analyze survey data for free (http://asdfree.com) with the r language
# pesquisa nacional por amostra de domicilios
# 2001 - 2011

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/PNAD/" )
# years.to.download <- c( 2001:2009 , 2011 )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Pesquisa%20Nacional%20por%20Amostra%20de%20Domicilios/2001-2011%20-%20download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
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


###################################################################################
# Analyze the 2001 - 2011 Pesquisa Nacional por Amostra de Domicilios file with R #
###################################################################################


# set your working directory.
# the PNAD 2001 - 2011 data files will be stored here
# after downloading and importing them.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PNAD/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( c( "survey" , "RSQLite" , "SAScii" , "descr" , "downloader" , "stringr" ) )


# define which years to download #

# uncomment this line to download all available data sets
# uncomment this line by removing the `#` at the front
# years.to.download <- c( 2001:2009 , 2011 )

# uncomment this line to only download the most current year
# years.to.download <- 2011

# uncomment this line to download, for example, 2005 and 2007-2009
# years.to.download <- c( 2009:2007 , 2005 )


# name the database (.db) file to be saved in the working directory
pnad.dbname <- "pnad.db"


############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #

# if the pnad database file already exists in the current working directory, print a warning
if ( file.exists( paste( getwd() , pnad.dbname , sep = "/" ) ) ) warning( "the database file already exists in your working directory.\nyou might encounter an error if you are running the same year as before or did not allow the program to complete.\ntry changing the pnad.dbname in the settings above." )


require(RSQLite) 	# load RSQLite package (creates database files in R)
require(SAScii) 	# load the SAScii package (imports ascii data with a SAS script)
require(descr) 		# load the descr package (converts fixed-width files to delimited files)
require(downloader)	# downloads and then runs the source() function on scripts from github

# load the read.SAScii.sqlite function (a variant of read.SAScii that creates a database directly)
source_url( "https://raw.github.com/ajdamico/usgsd/master/SQLite/read.SAScii.sqlite.R" , prompt = FALSE )

# load pnad-specific functions (to remove invalid SAS input script fields and postStratify a database-backed survey object)
source_url( "https://raw.github.com/ajdamico/usgsd/master/Pesquisa Nacional por Amostra de Domicilios/pnad.survey.R" , prompt = FALSE )

# create a temporary file and a temporary directory..
tf <- tempfile() ; td <- tempdir()

# open the connection to the sqlite database
db <- dbConnect( SQLite() , pnad.dbname )


# download and import the tables containing missing codes
download( "https://raw.github.com/ajdamico/usgsd/master/Pesquisa%20Nacional%20por%20Amostra%20de%20Domicilios/household_nr.csv" , tf )
household.nr <- read.csv( tf , colClasses = 'character' )

download( "https://raw.github.com/ajdamico/usgsd/master/Pesquisa%20Nacional%20por%20Amostra%20de%20Domicilios/person_nr.csv" , tf )
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

	# starting in 2011, the IBGE ftp site has both different filepaths and storage structures
	if ( year > 2010 ){

		# newer microdata filepath on the IBGE FTP site
		ftp.path <-
			paste0(
				"ftp://ftp.ibge.gov.br/Trabalho_e_Rendimento/Pesquisa_Nacional_por_Amostra_de_Domicilios_anual/microdados/" ,
				year ,
				"/"
			)
		
		# newer data file location inside the FTP directory
		data.file <- paste0( ftp.path , "/Dados.zip" )
		
		# newer sas importation instructions location inside the FTP directory
		sas.input.instructions <- paste0( ftp.path , "/Dicionarios.zip" )

		# download the household and person ascii data files to the local computer..
		download.file( data.file , tf , mode = "wb" )

		# ..then unzip them into the temporary directory
		files <- unzip( tf , exdir = td )

		# download the sas importation instructions inside the same FTP directory..
		download.file( sas.input.instructions , tf , mode = "wb" )

		# ..then also unzip them into the temporary directory
		files <- c( files , unzip( tf , exdir = td ) )

	} else {
	
		# 2001 - 2009 contain the microdata in a single file

		# older microdata filepath on the IBGE FTP site
		ftp.path <-
			paste0(
				"ftp://ftp.ibge.gov.br/Trabalho_e_Rendimento/Pesquisa_Nacional_por_Amostra_de_Domicilios_anual/microdados/reponderacao_2001_2009/PNAD_reponderado_" ,
				year ,
				".zip"
			)
	
		# download the data and sas importation instructions all at once..
		download.file( ftp.path , tf , mode = "wb" )
		
		# ..then also unzip them into the temporary directory
		files <- unzip( tf , exdir = td )
		
	}

	# convert the character vector containing the filepaths where all data and import instructions are stored to lowercase
	files <- tolower( files )
	
	# remove the UF column and the mistake with "LOCAL ÚLTIMO FURTO"
	# described in the remove.uf() function that was loaded with source_url as pnad.survey.R
	dom.sas <- remove.uf( files[ grepl( paste0( 'input[^?]dom' , year , '.txt' ) , files ) ] )
	pes.sas <- remove.uf( files[ grepl( paste0( 'input[^?]pes' , year , '.txt' ) , files ) ] )

	# since `files` contains multiple file paths,
	# determine the filepath on the local disk to the household (dom) and person (pes) files
	dom.fn <- files[ grepl( paste0( 'dados/dom' , year ) , files ) ]
	pes.fn <- files[ grepl( paste0( 'dados/pes' , year ) , files ) ]

	# store the PNAD household records as a SQLite database
	read.SAScii.sqlite ( 
		dom.fn , 
		dom.sas , 
		zipped = F , 
		tl = TRUE ,
		# this default table naming setup will name the household-level tables dom2001, dom2002, dom2003 and so on
		tablename = paste0( 'dom' , year ) ,
		db = db
	)
	
	# store the PNAD person records as a SQLite database
	read.SAScii.sqlite ( 
		pes.fn , 
		pes.sas , 
		zipped = F , 
		tl = TRUE ,
		# this default table naming setup will name the person-level tables pes2001, pes2002, pes2003 and so on
		tablename = paste0( 'pes' , year ) ,
		db = db
	)

	# the ASCII and SAS importation instructions stored in temporary files
	# on the local disk are no longer necessary, so delete them.
	file.remove( files )

	
	# missing level blank-outs #
	# this section loops through the non-response values & variables for all years
	# and sets those variables to NULL.
	cat( 'non-response variable blanking-out only occurs on numeric variables\n' )
	cat( 'categorical variable blanks are usually 9 in the psid\n' )
	cat( 'thanks for listening\n' )
	
	# loop through each row in the missing household-level  codes table
	for ( curRow in seq( nrow( household.nr ) ) ){

		# if the variable is in the current table..
		if( household.nr[ curRow , 'variable' ] %in% dbListFields( db , paste0( 'dom' , year ) ) ){

			# ..and the variable should be recoded for that year
			if( year %in% eval( parse( text = household.nr[ curRow , 'year' ] ) ) ){
		
				# update all variables where that code equals the `missing` code to NA (NULL in SQLite)
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
		
				# update all variables where that code equals the `missing` code to NA (NULL in SQLite)
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

	
	# create indexes to speed up the merge of the household- and person-level files.
	dbSendQuery( db , paste0( "CREATE INDEX pes_index" , year , " ON pes" , year , " ( v0101 , v0102 , v0103 )" ) )
	dbSendQuery( db , paste0( "CREATE INDEX dom_index" , year , " ON dom" , year , " ( v0101 , v0102 , v0103 )" ) )

	# clear up RAM
	gc()
	
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
			# NOTE: the substr() function luckily works in SQLite() databases, but may not work if you change SQL database engines to something else.
			" as select * , 1 as one , substr( a.v0102 , 1 , 2 ) as uf , substr( a.v0102 , 1 , 1 ) as region from pes" , 
			year , 
			" as a inner join dom" , 
			year , 
			" as b on a.v0101 = b.v0101 AND a.v0102 = b.v0102 AND a.v0103 = b.v0103" 
		)
	)

	# determine if the table contains a `v4619` variable.
	# v4619 is the factor of subsampling used to compensate the loss of units in some states
	# for 2011, the variable v4619 is one and so it is not needed.
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
	dbSendQuery( db , paste0( 'update pnad' , year , ' set pre_wgt = v4619 * v4610' ) )
	
	
	# confirm that the number of records in the pnad merged file
	# matches the number of records in the person file
	stopifnot( 
		dbGetQuery( db , paste0( "select count(*) as count from pes" , year ) ) == 
		dbGetQuery( db , paste0( "select count(*) as count from pnad" , year ) ) 
	)

	
}

# take a look at all the new data tables that have been added to your RAM-free SQLite database
dbListTables( db )

# disconnect from the current database
dbDisconnect( db )

# remove the temporary file from the local disk
file.remove( tf )

# print a reminder: set the directory you just saved everything to as read-only!
message( paste0( "all done.  you should set the file " , file.path( getwd() , pnad.dbname ) , " read-only so you don't accidentally alter these tables." ) )


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
