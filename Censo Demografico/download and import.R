# analyze survey data for free (http://asdfree.com) with the r language
# censo demografico
# 2000 and 2010 gerais da amostra (general sample)
# household-level, person-level, and merged files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( "monetdb.sequential" = TRUE )		# # only windows users need this line
# options( encoding = "latin1" )		# # only macintosh and *nix users need this line
# library(downloader)
# setwd( "C:/My Directory/CENSO/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Censo%20Demografico/download%20and%20import.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# http://www.screenr.com/Zpd8

# djalma pessoa
# djalma.pessoa@ibge.gov.br

# anthony joseph damico
# ajdamico@gmail.com

# if you use this script for a project, please send me a note
# it's always nice to hear about how people are using this stuff

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf



##################################################################################
# download all available brazilian census general sample files from the ibge ftp #
# import each file into a monet database, merge the person and household files   #
# create a monet database-backed complex sample sqlsurvey design object with r   #
##################################################################################


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
# prior to running this analysis script, monetdb must be installed on the local machine.  follow each step outlined on this page: #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/usgsd/blob/master/MonetDB/monetdb%20installation%20instructions.R                                   #
###################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # # #
# warning: this takes a while #
# # # # # # # # # # # # # # # #


# remove the # in order to run this install.packages line only once
# install.packages( c( "RCurl" , "downloader" , "R.utils" , "stringr" ) )


# even if you're only downloading a single year of data and you've got a fast internet connection,
# you'll be better off leaving this script to run overnight.  if you wanna download all available files and years,
# leave it running on friday afternoon (or even better: before you leave for a weeklong vacation).
# depending on your internet and processor speeds, the entire script should take between two and ten days.
# it's running.  don't believe me?  check the working directory (set below) for a new r data file (.rda) every few hours.


library(sqlsurvey)		# load sqlsurvey package (analyzes large complex design surveys)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(RCurl)			# load RCurl package (downloads https files)
library(downloader)		# downloads and then runs the source() function on scripts from github
library(R.utils)		# load the R.utils package (counts the number of lines in a file quickly)
library(stringr) 		# load stringr package (manipulates character strings easily)

# set your censo demografico data directory
# after downloading and importing
# a monet database-backed complex survey designs will be stored here
# and the monet database will be stored in the MonetDB folder within
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/CENSO/" )


# load the read.SAScii.monetdb() function,
# which imports ASCII (fixed-width) data files directly into a monet database
# using only a SAS importation script
source_url( "https://raw.github.com/ajdamico/usgsd/master/MonetDB/read.SAScii.monetdb.R" , prompt = FALSE )


# configure a monetdb database for the censo demografico on windows #

# note: only run this command once.  this creates an executable (.bat) file
# in the appropriate directory on your local disk.
# when adding new files or adding a new year of data, this script does not need to be re-run.

# create a monetdb executable (.bat) file for the brazilian census
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
		dbname = "censo_demografico" ,
		
		# choose a database port
		# this port should not conflict with other monetdb databases
		# on your local computer.  two databases with the same port number
		# cannot be accessed at the same time
		dbport = 50011
	)

	
# this next step is so very important.

# store a line of code that will make it easy to open up the monetdb server in the future.
# this should contain the same file path as the batfile created above,
# you're best bet is to actually look at your local disk to find the full filepath of the executable (.bat) file.
# if you ran this script without changes, the batfile will get stored in C:\My Directory\CENSO\MonetDB\censo_demografico.bat

# here's the batfile location:
batfile

# note that since you only run the `monetdb.server.setup()` function the first time this script is run,
# you will need to note the location of the batfile for future MonetDB analyses!

# in future R sessions, you can create the batfile variable with a line like..
# batfile <- "C:/My Directory/CENSO/MonetDB/censo_demografico.bat"		# # note for mac and *nix users: `censo_demografico.bat` might be `censo_demografico.sh` instead
# obviously, without the `#` comment character

# hold on to that line for future scripts.
# you need to run this line *every time* you access
# the brazilian census microdata files with monetdb.
# this is the monetdb server.

# two other things you need: the database name and the database port.
# store them now for later in this script, but hold on to them for other scripts as well
dbname <- "censo_demografico"
dbport <- 50011

# now the local windows machine contains a new executable program at "c:\my directory\CENSO\monetdb\censo_demografico.bat"




# it's recommended that after you've _created_ the monetdb server,
# you create a block of code like the one below to _access_ the monetdb server


####################################################################
# lines of code to hold on to for all other `censo_demografico` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/CENSO/MonetDB/censo_demografico.bat"		# # note for mac and *nix users: `censo_demografico.bat` might be `censo_demografico.sh` instead

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "censo_demografico"
dbport <- 50011

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )


# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other `censo_demografico` monetdb analyses #
###########################################################################

	
###############################################
# DATA LOADING COMPONENT - ONLY RUN THIS ONCE #
###############################################


##########################################
# this entire script is for data-loading #
# and only needs to be run once  #
# for whichever year(s) you need #
##################################



# define a special function to   #
# remove alphanumeric characters #
# from any data files that have  #
# been downloaded from ibge      #
ranc <- 
	function( infiles , width ){

		tf_a <- tempfile()

		outcon <- file( tf_a , "w" )

		# if there are multiple infiles,
		# loop through them all!
		for ( infile in infiles ){

			incon <- file( infile , "r")

			line.num <- 0
			
			while( length( line <- readLines( incon , 1 , skipNul = TRUE ) ) > 0 ){

				# remove all non-alphanumeric characters
				# line <- gsub( "[^[:alnum:]///' ]" , " " , line )

				# line <- iconv( line , "" , "ASCII" , sub = " " )

				line <- str_pad( line , width , side = "right" , pad = " " )
				
				# save the file on the disk
				writeLines( line , outcon )

				# add to the line counter #
				line.num <- line.num + 1

				# every 10k records, print current progress to the screen
				if ( line.num %% 10000 == 0 ) cat( " " , prettyNum( line.num , big.mark = "," ) , "census pums lines processed" , "\r" )
			}

			close( incon )
		}

		close( outcon )

		tf_a
	}



						
# create three temporary files and a temporary directory..
tf <- tempfile() ; td <- tempdir() ; tf2 <- tempfile() ; tf3 <- tempfile() ; tf4 <- tempfile()

# download the sas importation scripts (for use with SAScii) to load the census files directly into MonetDB
download( "https://raw.github.com/ajdamico/usgsd/master/Censo%20Demografico/SASinputDom.txt" , tf2 )
download( "https://raw.github.com/ajdamico/usgsd/master/Censo%20Demografico/SASinputPes.txt" , tf3 )


# designate the location of the 2010 general sample microdata files
ftp.path <-	"ftp://ftp.ibge.gov.br/Censos/Censo_Demografico_2010/Resultados_Gerais_da_Amostra/Microdados/"

# fetch all available files in the ftp site's directory
all.files <- getURL( ftp.path , dirlistonly = TRUE )

# those files are separated by newline characters in the code,
# so simply split them up into a character vector
# full of individual zipped file strings
all.files <- scan( text = all.files , what = "character", quiet = T )

# remove the two files you don't need to import
files.to.download <- all.files[ !( all.files %in% c( 'Atualizacoes.txt' , 'Documentacao.zip' ) ) ]

# launch the current monet database
pid <- monetdb.server.start( batfile )

# immediately connect to it
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )


# loop through each of the files to be downloaded..
for ( curFile in files.to.download ){

	data.file <- paste0( ftp.path , curFile )
	
	# blank out the filepaths to the previous unzipped files
	unzipped.files <- NULL
	
	# initiate a download-counter
	i <- 1
	
	# attempt the download until the files are downloaded
	# and unzip properly.
	while( length( unzipped.files ) == 0 ){
	
		# download the current brazilian census file
		download.file( data.file , tf , mode = "wb" )
		
		# unzip that pup
		unzipped.files <- unzip( tf , exdir = td )
		
		# increase the counter..
		i <- i + 1
		
		# ..and when it's tried five times, break.
		if( i > 5 ) stop( "after five download attempts, i give up." )
	}

	dom.file <- unzipped.files[ grep( 'Domicilios' , unzipped.files , useBytes = TRUE ) ]
	pes.file <- unzipped.files[ grep( 'Pessoas' , unzipped.files , useBytes = TRUE ) ]
	
	dom.curTable <- gsub( '.zip' , '_dom10' , curFile )
	pes.curTable <- gsub( '.zip' , '_pes10' , curFile )
	
	dom.curTable <- tolower( gsub( '-' , '_' , dom.curTable ) )
	pes.curTable <- tolower( gsub( '-' , '_' , pes.curTable ) )
	
	
	read.SAScii.monetdb (
		dom.file ,
		sas_ri = tf2 ,
		zipped = F ,						# the ascii file is stored in a zipped file
		tl = TRUE ,							# convert all column names to lowercase
		tablename = dom.curTable ,			# the table will be stored in the monet database
		connection = db
	)
	
	read.SAScii.monetdb (
		pes.file ,
		sas_ri = tf3 ,
		zipped = F ,						# the ascii file is stored in a zipped file
		tl = TRUE ,							# convert all column names to lowercase
		tablename = pes.curTable ,			# the table will be stored in the monet database
		connection = db
	)
	
	file.remove( unzipped.files )

	
		
}
	

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )




# launch the current monet database
pid <- monetdb.server.start( batfile )

# immediately connect to it
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )



# at this point, all tables need to be merged and then rectangulated!
# search for the word "rectangular" on this page to read more about
# rectangular data.  https://cps.ipums.org/cps-action/faq
# basically, it's just merging household characteristics on to every person.



dom.tables <- dbListTables( db )[ grep( "_dom10" , dbListTables( db ) ) ]

pes.tables <- dbListTables( db )[ grep( "_pes10" , dbListTables( db ) ) ]

dom.stack <-
	paste(
		'create table c10_dom_pre_fpc as (SELECT * FROM' ,
		paste( dom.tables , collapse = ') UNION ALL (SELECT * FROM ' ) ,
		') WITH DATA'
	)

dbSendQuery( db , dom.stack )

pes.stack <-
	paste(
		'create table c10_pes_pre_fpc as (SELECT * FROM' ,
		paste( pes.tables , collapse = ') UNION ALL (SELECT * FROM ' ) ,
		') WITH DATA'
	)

dbSendQuery( db , pes.stack )

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# launch the current monet database
pid <- monetdb.server.start( batfile )

# immediately connect to it
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

dom.fpc.create <-
	'create table c10_dom_fpc as (select v0011 , sum( v0010 ) as sum_v0010 from c10_dom_pre_fpc group by v0011) WITH DATA'

dbSendQuery( db , dom.fpc.create )

pes.fpc.create <-
	'create table c10_pes_fpc as (select v0011 , sum( v0010 ) as sum_v0010 from c10_pes_pre_fpc group by v0011) WITH DATA'

dbSendQuery( db , pes.fpc.create )

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# launch the current monet database
pid <- monetdb.server.start( batfile )

# immediately connect to it
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

dom.count.create <-
	'create table c10_dom_count_pes as (select v0001 , v0300 , count(*) as dom_count_pes from c10_pes_pre_fpc group by v0001 , v0300 ) WITH DATA'

dbSendQuery( db , dom.count.create )

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# launch the current monet database
pid <- monetdb.server.start( batfile )

# immediately connect to it
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

dom.fpc.merge <-
	'create table c10_dom as ( select a1.* , b1.dom_count_pes from (select a2.* , b2.sum_v0010 as dom_fpc from c10_dom_pre_fpc as a2 inner join c10_dom_fpc as b2 on a2.v0011 = b2.v0011) as a1 inner join c10_dom_count_pes as b1 on a1.v0001 = b1.v0001 AND a1.v0300 = b1.v0300 ) WITH DATA'
	
dbSendQuery( db , dom.fpc.merge )

pes.fpc.merge <-
	'create table c10_pes as (select a.* , b.sum_v0010 as pes_fpc from c10_pes_pre_fpc as a inner join c10_pes_fpc as b on a.v0011 = b.v0011) WITH DATA'

dbSendQuery( db , pes.fpc.merge )

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# launch the current monet database
pid <- monetdb.server.start( batfile )

# immediately connect to it
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

dbSendQuery( db , 'ALTER TABLE c10_dom ADD COLUMN dom_wgt DOUBLE PRECISION' )
dbSendQuery( db , 'ALTER TABLE c10_pes ADD COLUMN pes_wgt DOUBLE PRECISION' )

dbSendQuery( db , 'UPDATE c10_dom SET dom_wgt = v0010' )
dbSendQuery( db , 'UPDATE c10_pes SET pes_wgt = v0010' )

dbSendQuery( db , 'ALTER TABLE c10_dom DROP COLUMN v0010' )
dbSendQuery( db , 'ALTER TABLE c10_pes DROP COLUMN v0010' )


b.fields <- dbListFields( db , 'c10_pes' )[ !( dbListFields( db , 'c10_pes' ) %in% dbListFields( db , 'c10_dom' ) ) ]

final.merge <-
	paste0(
		'create table c10 as (SELECT a.* , b.' ,
		paste( b.fields , collapse = ', b.' ) ,
		' from c10_dom as a inner join c10_pes as b ON a.v0001 = b.v0001 AND a.v0300 = b.v0300) WITH DATA'
	)
	
dbSendQuery( db , final.merge )


# add columns named 'one' to each table..
dbSendQuery( db , 'alter table c10_dom add column one int' )
dbSendQuery( db , 'alter table c10_pes add column one int' )
dbSendQuery( db , 'alter table c10 add column one int' )

# ..and fill them all with the number 1.
dbSendQuery( db , 'UPDATE c10_dom SET one = 1' )
dbSendQuery( db , 'UPDATE c10_pes SET one = 1' )
dbSendQuery( db , 'UPDATE c10 SET one = 1' )
		
# add a column called 'idkey' containing the row number
dbSendQuery( db , 'alter table c10_dom add column idkey int auto_increment' )
dbSendQuery( db , 'alter table c10_pes add column idkey int auto_increment' )
dbSendQuery( db , 'alter table c10 add column idkey int auto_increment' )


# now the current database contains three tables more tables than it did before
	# c10_dom (household)
	# c10_pes (person)
	# c10 (merged)

# the current monet database should now contain
# all of the newly-added tables (in addition to meta-data tables)
print( dbListTables( db ) )		# print the tables stored in the current monet database to the screen


# confirm that the merged file has the same number of records as the person file
stopifnot( 
	dbGetQuery( db , "select count(*) as count from c10_pes" ) == 
	dbGetQuery( db , "select count(*) as count from c10" )
)

#####################################
# create the dom and pes headers tables
dom.fields <- dbListFields( db , 'c10_dom' )
pes.fields <- dbListFields( db , 'c10' )

dom.all <- parse.SAScii( tf2 )
pes.all <- parse.SAScii( tf3 )

dom.char <- tolower( dom.all[ dom.all$char , 'varname' ] )
pes.char <- tolower( pes.all[ pes.all$char , 'varname' ] )

dom.factors <- intersect( dom.fields , c( dom.char , pes.char ) )
pes.factors <- intersect( pes.fields , c( dom.char , pes.char ) )

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# launch the current monet database
pid <- monetdb.server.start( batfile )

# immediately connect to it
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )


#################################################
# create a sqlsurvey complex sample design object
dom.design <-
	sqlsurvey(
		weight = 'dom_wgt' ,				# weight variable column (defined in the character string)
		nest = TRUE ,						# whether or not psus are nested within strata
		strata = 'v0011' ,					# stratification variable column (defined in the character string)
		id = 'v0300' ,						# sampling unit column (defined in the character string)
		fpc = 'dom_fpc' ,					# within-data pre-computed finite population correction for the household
		table.name = 'c10_dom' ,			# table name within the monet database (defined in the character string)
		key = "idkey" ,						# sql primary key column (created with the auto_increment line)
		check.factors = dom.factors ,		# defaults to ten
		database = monet.url ,				# monet database location on localhost
		driver = MonetDB.R()
	)

# save the complex sample survey design
# into a single r data file (.rda) that can now be
# analyzed quicker than anything else.
save( dom.design , file = 'dom 2010 design.rda' )




#################################################
# create a sqlsurvey complex sample design object
pes.design <-
	sqlsurvey(
		weight = 'pes_wgt' ,				# weight variable column (defined in the character string)
		nest = TRUE ,						# whether or not psus are nested within strata
		strata = 'v0011' ,					# stratification variable column (defined in the character string)
		id = 'v0300' ,						# sampling unit column (defined in the character string)
		fpc = 'dom_fpc' ,					# within-data pre-computed finite population correction, also for the household
		table.name = 'c10' ,				# table name within the monet database (defined in the character string)
		key = "idkey" ,						# sql primary key column (created with the auto_increment line)
		check.factors = pes.factors ,		# defaults to ten
		database = monet.url ,				# monet database location on localhost
		driver = MonetDB.R()
	)

# save the complex sample survey design
# into a single r data file (.rda) that can now be
# analyzed quicker than anything else.
save( pes.design , file = 'pes 2010 design.rda' )


# close the connection to the two sqlsurvey design objects
close( dom.design )
close( pes.design )

# remove these two objects from memory
rm( dom.design , pes.design )

# clear up RAM
gc()

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )
	

# the current working directory should now contain one r data file (.rda)
# for each monet database-backed complex sample survey design object


# once complete, this script does not need to be run again.
# instead, use one of the brazilian census microdata analysis scripts
# which utilize these newly-created survey objects


# wait ten seconds, just to make sure any previous servers closed
# and you don't get a gdk-lock error from opening two-at-once
Sys.sleep( 10 )


# # # # # # # # # # # # # #
# load the 2000 censo too #
# # # # # # # # # # # # # #


# download the sas importation scripts (for use with SAScii) to load the census files directly into MonetDB
download( "https://raw.github.com/ajdamico/usgsd/master/Censo%20Demografico/LE DOMIC.sas" , tf2 )
download( "https://raw.github.com/ajdamico/usgsd/master/Censo%20Demografico/LE PESSOAS.sas" , tf3 )
download( "https://raw.github.com/ajdamico/usgsd/master/Censo%20Demografico/LE FAMILIAS.sas" , tf4 )


# designate the location of the 2000 general sample microdata files
ftp.path <-	"ftp://ftp.ibge.gov.br/Censos/Censo_Demografico_2000/Microdados/"

# fetch all available files in the ftp site's directory
all.files <- getURL( ftp.path , dirlistonly = TRUE )

# those files are separated by newline characters in the code,
# so simply split them up into a character vector
# full of individual zipped file strings
all.files <- scan( text = all.files , what = "character", quiet = T )

# remove the two files you don't need to import
files.to.download <- all.files[ !( all.files %in% c( '1_Documentacao.zip' ) ) ]

# launch the current monet database
pid <- monetdb.server.start( batfile )

# immediately connect to it
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )


# loop through each of the files to be downloaded..
for ( curFile in files.to.download ){

	data.file <- paste0( ftp.path , curFile )
	
	# blank out the filepaths to the previous unzipped files
	unzipped.files <- NULL
	
	# initiate a download-counter
	i <- 1
	
	# attempt the download until the files are downloaded
	# and unzip properly.
	
	while( length( unzipped.files ) == 0 ){
	
		# download the current brazilian census file
		download.file( data.file , tf , mode = "wb" )
		
		# unzip that pup
		unzipped.files <- unzip( tf , exdir = td )
		
		# increase the counter..
		i <- i + 1
		
		# ..and when it's tried five times, break.
		if( i > 5 ) stop( "after five download attempts, i give up." )
	}

	dom.file <- unzipped.files[ grep( 'DOM' , unzipped.files , useBytes = TRUE ) ]
	pes.file <- unzipped.files[ grep( 'PES' , unzipped.files , useBytes = TRUE ) ]
	fam.file <- unzipped.files[ grep( 'FAM' , unzipped.files , useBytes = TRUE ) ]
	
	dom.curTable <- gsub( '.zip' , '_dom00' , curFile )
	pes.curTable <- gsub( '.zip' , '_pes00' , curFile )
	fam.curTable <- gsub( '.zip' , '_fam00' , curFile )
	
	dom.curTable <- tolower( gsub( '-' , '_' , dom.curTable ) )
	pes.curTable <- tolower( gsub( '-' , '_' , pes.curTable ) )
	fam.curTable <- tolower( gsub( '-' , '_' , fam.curTable ) )
	
	
	
	read.SAScii.monetdb (
		tdl <- ranc( dom.file , 170 ) ,
		sas_ri = tf2 ,
		tl = TRUE ,							# convert all column names to lowercase
		tablename = dom.curTable ,			# the table will be stored in the monet database
		connection = db
	)
	
	stopifnot( sum( sapply( dom.file , countLines ) ) == dbGetQuery( db , paste( "select count(*) from" , dom.curTable ) )[ 1 , 1 ] )
	
	file.remove( tdl , dom.file )
	
	read.SAScii.monetdb (
		tdl <- ranc( pes.file , 390 ) ,
		sas_ri = tf3 ,
		tl = TRUE ,							# convert all column names to lowercase
		tablename = pes.curTable ,			# the table will be stored in the monet database
		connection = db
	)
	
	stopifnot( sum( sapply( pes.file , countLines ) ) == dbGetQuery( db , paste( "select count(*) from" , pes.curTable ) )[ 1 , 1 ] )
	
	file.remove( tdl , dom.file )
	
	read.SAScii.monetdb (
		tdl <- ranc( fam.file , 118 ) ,
		sas_ri = tf4 ,
		tl = TRUE ,							# convert all column names to lowercase
		tablename = fam.curTable ,			# the table will be stored in the monet database
		connection = db
	)
	
	stopifnot( sum( sapply( fam.file , countLines ) ) == dbGetQuery( db , paste( "select count(*) from" , fam.curTable ) )[ 1 , 1 ] )
	
	file.remove( tdl , dom.file )
	
	
	file.remove( unzipped.files )
		
}
	

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )




# launch the current monet database
pid <- monetdb.server.start( batfile )

# immediately connect to it
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )



# at this point, all tables need to be merged and then rectangulated!
# search for the word "rectangular" on this page to read more about
# rectangular data.  https://cps.ipums.org/cps-action/faq
# basically, it's just merging household characteristics on to every person.



dom.tables <- dbListTables( db )[ grep( "_dom00" , dbListTables( db ) ) ]

pes.tables <- dbListTables( db )[ grep( "_pes00" , dbListTables( db ) ) ]

fam.tables <- dbListTables( db )[ grep( "_fam00" , dbListTables( db ) ) ]

dom.stack <-
	paste(
		'create table c00_dom_pre_fpc as (SELECT * FROM' ,
		paste( dom.tables , collapse = ') UNION ALL (SELECT * FROM ' ) ,
		') WITH DATA'
	)

dbSendQuery( db , dom.stack )

pes.stack <-
	paste(
		'create table c00_pes_pre_fpc as (SELECT * FROM' ,
		paste( pes.tables , collapse = ') UNION ALL (SELECT * FROM ' ) ,
		') WITH DATA'
	)

dbSendQuery( db , pes.stack )

fam.stack <-
	paste(
		'create table c00_fam_pre_fpc as (SELECT * FROM' ,
		paste( fam.tables , collapse = ') UNION ALL (SELECT * FROM ' ) ,
		') WITH DATA'
	)

dbSendQuery( db , fam.stack )

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# launch the current monet database
pid <- monetdb.server.start( batfile )

# immediately connect to it
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

dom.fpc.create <-
	'create table c00_dom_fpc as (select areap , sum( p001 ) as sum_p001 from c00_dom_pre_fpc group by areap) WITH DATA'

dbSendQuery( db , dom.fpc.create )

pes.fpc.create <-
	'create table c00_pes_fpc as (select areap , sum( p001 ) as sum_p001 from c00_pes_pre_fpc group by areap) WITH DATA'

dbSendQuery( db , pes.fpc.create )

fam.fpc.create <-
	'create table c00_fam_fpc as (select areap , sum( p001 ) as sum_p001 from c00_fam_pre_fpc group by areap) WITH DATA'

dbSendQuery( db , fam.fpc.create )

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# launch the current monet database
pid <- monetdb.server.start( batfile )

# immediately connect to it
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

dom.count.create <-
	'create table c00_dom_count_pes as (select v0102 , v0300 , count(*) as dom_count_pes from c00_pes_pre_fpc group by v0102 , v0300 ) WITH DATA'

dbSendQuery( db , dom.count.create )

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# launch the current monet database
pid <- monetdb.server.start( batfile )

# immediately connect to it
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

dom.fpc.merge <-
	'create table c00_dom as ( select a1.* , b1.dom_count_pes from (select a2.* , b2.sum_p001 as dom_fpc from c00_dom_pre_fpc as a2 inner join c00_dom_fpc as b2 on a2.areap = b2.areap) as a1 inner join c00_dom_count_pes as b1 on a1.v0102 = b1.v0102 AND a1.v0300 = b1.v0300 ) WITH DATA'
	
dbSendQuery( db , dom.fpc.merge )

pes.fpc.merge <-
	'create table c00_pes as (select a.* , b.sum_p001 as pes_fpc from c00_pes_pre_fpc as a inner join c00_pes_fpc as b on a.areap = b.areap) WITH DATA'

dbSendQuery( db , pes.fpc.merge )

fam.fpc.merge <-
	'create table c00_fam as (select a.* , b.sum_p001 as fam_fpc from c00_fam_pre_fpc as a inner join c00_fam_fpc as b on a.areap = b.areap) WITH DATA'

dbSendQuery( db , fam.fpc.merge )

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# launch the current monet database
pid <- monetdb.server.start( batfile )

# immediately connect to it
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

dbSendQuery( db , 'ALTER TABLE c00_dom ADD COLUMN dom_wgt DOUBLE PRECISION' )
dbSendQuery( db , 'ALTER TABLE c00_pes ADD COLUMN pes_wgt DOUBLE PRECISION' )
dbSendQuery( db , 'ALTER TABLE c00_pes ADD COLUMN fam_wgt DOUBLE PRECISION' )

dbSendQuery( db , 'UPDATE c00_dom SET dom_wgt = p001' )
dbSendQuery( db , 'UPDATE c00_pes SET pes_wgt = p001' )
dbSendQuery( db , 'UPDATE c00_pes SET fam_wgt = p001' )

dbSendQuery( db , 'ALTER TABLE c00_dom DROP COLUMN p001' )
dbSendQuery( db , 'ALTER TABLE c00_pes DROP COLUMN p001' )
dbSendQuery( db , 'ALTER TABLE c00_fam DROP COLUMN p001' )


b.fields <- dbListFields( db , 'c00_fam' )[ !( dbListFields( db , 'c00_fam' ) %in% dbListFields( db , 'c00_dom' ) ) ]

semifinal.merge <-
	paste0(
		'create table c00_dom_fam as (SELECT a.* , b.' ,
		paste( b.fields , collapse = ', b.' ) ,
		' from c00_dom as a inner join c00_fam as b ON a.v0102 = b.v0102 AND a.v0300 = b.v0300) WITH DATA'
	)
	
dbSendQuery( db , semifinal.merge )


b.fields <- dbListFields( db , 'c00_pes' )[ !( dbListFields( db , 'c00_pes' ) %in% dbListFields( db , 'c00_dom_fam' ) ) ]

final.merge <-
	paste0(
		'create table c00 as (SELECT a.* , b.' ,
		paste( b.fields , collapse = ', b.' ) ,
		' from c00_dom_fam as a inner join c00_pes as b ON a.v0102 = b.v0102 AND a.v0300 = b.v0300 AND a.v0404 = b.v0404 ) WITH DATA'
	)
	
dbSendQuery( db , final.merge )

# now remove the dom + fam table,
# since that's not of much use
dbRemoveTable( db , 'c00_dom_fam' )

# add columns named 'one' to each table..
dbSendQuery( db , 'alter table c00_dom add column one int' )
dbSendQuery( db , 'alter table c00_pes add column one int' )
dbSendQuery( db , 'alter table c00_fam add column one int' )
dbSendQuery( db , 'alter table c00 add column one int' )

# ..and fill them all with the number 1.
dbSendQuery( db , 'UPDATE c00_dom SET one = 1' )
dbSendQuery( db , 'UPDATE c00_pes SET one = 1' )
dbSendQuery( db , 'UPDATE c00_fam SET one = 1' )
dbSendQuery( db , 'UPDATE c00 SET one = 1' )
		
# add a column called 'idkey' containing the row number
dbSendQuery( db , 'alter table c00_dom add column idkey int auto_increment' )
dbSendQuery( db , 'alter table c00_pes add column idkey int auto_increment' )
dbSendQuery( db , 'alter table c00_fam add column idkey int auto_increment' )
dbSendQuery( db , 'alter table c00 add column idkey int auto_increment' )


# now the current database contains four more tables than it did before
	# c00_dom (household)
	# c00_fam (family)
	# c00_pes (person)
	# c00 (merged)

# the current monet database should now contain
# all of the newly-added tables (in addition to meta-data tables)
print( dbListTables( db ) )		# print the tables stored in the current monet database to the screen


# confirm that the merged file has the same number of records as the person file
stopifnot( 
	dbGetQuery( db , "select count(*) as count from c00_pes" ) == 
	dbGetQuery( db , "select count(*) as count from c00" )
)

#####################################
# create the dom and fam and pes headers tables
dom.fields <- dbListFields( db , 'c00_dom' )
fam.fields <- dbListFields( db , 'c00_fam' )
pes.fields <- dbListFields( db , 'c00' )

dom.all <- parse.SAScii( tf2 )
pes.all <- parse.SAScii( tf3 )
fam.all <- parse.SAScii( tf4 )

dom.char <- tolower( dom.all[ dom.all$char , 'varname' ] )
pes.char <- tolower( pes.all[ pes.all$char , 'varname' ] )
fam.char <- tolower( fam.all[ fam.all$char , 'varname' ] )

dom.factors <- intersect( dom.fields , dom.char )
fam.factors <- intersect( fam.fields , fam.char )
pes.factors <- intersect( pes.fields , c( dom.char , fam.char , pes.char ) )

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# launch the current monet database
pid <- monetdb.server.start( batfile )

# immediately connect to it
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )


#################################################
# create a sqlsurvey complex sample design object
dom.design <-
	sqlsurvey(
		weight = 'dom_wgt' ,				# weight variable column (defined in the character string)
		nest = TRUE ,						# whether or not psus are nested within strata
		strata = 'areap' ,					# stratification variable column (defined in the character string)
		id = 'v0300' ,						# sampling unit column (defined in the character string)
		fpc = 'dom_fpc' ,					# within-data pre-computed finite population correction for the household
		table.name = 'c00_dom' ,			# table name within the monet database (defined in the character string)
		key = "idkey" ,						# sql primary key column (created with the auto_increment line)
		check.factors = dom.factors ,		# defaults to ten
		database = monet.url ,				# monet database location on localhost
		driver = MonetDB.R()
	)

# save the complex sample survey design
# into a single r data file (.rda) that can now be
# analyzed quicker than anything else.
save( dom.design , file = 'dom 2000 design.rda' )




#################################################
# create a sqlsurvey complex sample design object
pes.design <-
	sqlsurvey(
		weight = 'pes_wgt' ,				# weight variable column (defined in the character string)
		nest = TRUE ,						# whether or not psus are nested within strata
		strata = 'areap' ,					# stratification variable column (defined in the character string)
		id = 'v0300' ,						# sampling unit column (defined in the character string)
		fpc = 'dom_fpc' ,					# within-data pre-computed finite population correction, also for the household
		table.name = 'c00' ,				# table name within the monet database (defined in the character string)
		key = "idkey" ,						# sql primary key column (created with the auto_increment line)
		check.factors = pes.factors ,		# defaults to ten
		database = monet.url ,				# monet database location on localhost
		driver = MonetDB.R()
	)

# save the complex sample survey design
# into a single r data file (.rda) that can now be
# analyzed quicker than anything else.
save( pes.design , file = 'pes 2000 design.rda' )


#################################################
# create a sqlsurvey complex sample design object
fam.design <-
	sqlsurvey(
		weight = 'fam_wgt' ,				# weight variable column (defined in the character string)
		nest = TRUE ,						# whether or not psus are nested within strata
		strata = 'areap' ,					# stratification variable column (defined in the character string)
		id = 'v0300' ,						# sampling unit column (defined in the character string)
		fpc = 'dom_fpc' ,					# within-data pre-computed finite population correction, also for the household
		table.name = 'c00_fam' ,			# table name within the monet database (defined in the character string)
		key = "idkey" ,						# sql primary key column (created with the auto_increment line)
		check.factors = fam.factors ,		# defaults to ten
		database = monet.url ,				# monet database location on localhost
		driver = MonetDB.R()
	)

# save the complex sample survey design
# into a single r data file (.rda) that can now be
# analyzed quicker than anything else.
save( fam.design , file = 'fam 2000 design.rda' )


# close the connection to the three sqlsurvey design objects
close( dom.design )
close( pes.design )
close( fam.design )

# remove these three objects from memory
rm( dom.design , pes.design , fam.design )

# clear up RAM
gc()

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )
	

# the current working directory should now contain one r data file (.rda)
# for each monet database-backed complex sample survey design object


# once complete, this script does not need to be run again.
# instead, use one of the brazilian census microdata analysis scripts
# which utilize these newly-created survey objects


# wait ten seconds, just to make sure any previous servers closed
# and you don't get a gdk-lock error from opening two-at-once
Sys.sleep( 10 )

##################################################################################
# lines of code to hold on to for all other `censo_demografico` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/CENSO/MonetDB/censo_demografico.bat"		# # note for mac and *nix users: `censo_demografico.bat` might be `censo_demografico.sh` instead

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "censo_demografico"
dbport <- 50011

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )


# # # # run your analysis commands # # # #


# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other `censo_demografico` monetdb analyses #
#########################################################################################


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
