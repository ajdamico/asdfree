# analyze us government survey data with the r language
# current population survey 
# annual social and economic supplement
# 2005 - 2012

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


#########################################################################################################
# Analyze the 2005 - 2012 Current Population Survey - Annual Social and Economic Supplement file with R #
#########################################################################################################

#####################
## # # # # # # # # ##
## monetdb warning ##
## # # # # # # # # ##
#####################

# before running this script, you must install monetdb on your local computer
# follow the simple four steps outlined in this document
stop( "look at monetdb installation instructions.R first" )


# immediately identify the location of the monetdb driver (.jar)
monetdriver <- "c:/program files/monetdb/monetdb5/monetdb-jdbc-2.5.jar"

# set your monetdb directory
# all CPS data files will be stored here
# after downloading and importing
# use forward slashes instead of back slashes

setwd( "C:/My Directory/CPS/" )


# the package 'sqlsurvey' and a number of others should have been installed during the monetdb installation
require(sqlsurvey)		# load sqlsurvey package (analyzes large complex design surveys)
require(SAScii) 		# load the SAScii package (imports ascii data with a SAS script)


# here's where the .bat file will be saved.
# this location will be needed for analyses
# set the name of the .bat file that will be used to launch this monetdb in the future
( cps.bat.file <- file.path( getwd() , "cps.bat" ) )


# set the name of the monetdb database
dbname <- 'cps'

# choose a database port
# this port should not conflict with other monetdb databases
# on your local computer.  two databases with the same port number
# cannot be accessed at the same time
dbport <- 50002


# set the directory where the monetdb files will be stored on your local computer
# this path does not need to be recorded for future use - it will be stored in the .bat file
# note: this path *must* end with a slash
( cps.database.directory <- file.path( getwd() , "MonetDB/" ) )


# define which years to download #

# this line will download every year of data available
cps.years.to.download <- 2012:2005

# uncomment this line to only download the most current year
# cps.years.to.download <- 2011

# uncomment this line to download, for example, 2005 and 2009-2011
# cps.years.to.download <- c( 2011:2009 , 2005 )


############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #


#######################################################	
# function to download scripts directly from github.com
# http://tonybreyal.wordpress.com/2011/11/24/source_https-sourcing-an-r-script-from-github/
source_https <- function(url, ...) {
  # load package
  require(RCurl)

  # parse and evaluate each .R script
  sapply(c(url, ...), function(u) {
    eval(parse(text = getURL(u, followlocation = TRUE, cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl"))), envir = .GlobalEnv)
  })
}
#######################################################

# load the read.SAScii.sql function (a variant of read.SAScii that creates a database directly)
stop( 'uncomment this' )
# source_https( "https://raw.github.com/ajdamico/usgsd/master/read.SAScii.sql.R" )
stop( "also run windows.monetdb.configuration.R" )
stop( "and remove these:" )
source( "C:/Users/AnthonyD/Google Drive/private/usgsd/windows.monetdb.configuration.R" ) 
source( "C:/Users/AnthonyD/Google Drive/private/usgsd/read.SAScii.sql.R" ) 



# create the monetdb .bat file
# see the windows.monetdb.configuration.R file for more details about these parameters
windows.monetdb.configuration( 
		bat.file.location = cps.bat.file , 
		monetdb.program.path = "C:\\Program Files\\MonetDB\\MonetDB5\\" ,
		database.directory = cps.database.directory ,
		dbname = dbname ,
		dbport = dbport
	)


# immediately launch the cps .bat file
shell.exec( cps.bat.file )
# note that you'll need to run this line in future analyses,
# so store it as a string..  here's the full path to the .bat file:
print( cps.bat.file )
# place that string inside the shell.exec( ) function
# ..using all the program defaults, the line should look like this (without the # comment):
# shell.exec( "C:/My Directory/CPS/cps.bat" )


# at this point, r can create a connection to the database
# remember step 3 of the installation instructions?
# you stored "monetdb-jdbc-#.#.jar" somewhere.  write the full path to it here:
drv <- MonetDB( classPath = monetdriver )

# dynamically create the connection url
monet.url <- paste0( "jdbc:monetdb://localhost:" , dbport , "/" , dbname )

# if the next command runs before the .bat file has finished,
# it will break.  so give it two seconds to open the dos window
Sys.sleep( 2 )

# connect to the database
db <- dbConnect( drv , monet.url , user = "monetdb" , password = "monetdb" )

# set R to produce conservative standard errors instead of crashing
# http://faculty.washington.edu/tlumley/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN


# if this option is set to TRUE
# R will exactly match SUDAAN results and Stata with the MSE option results
options( survey.replicates.mse = TRUE )
# otherwise if it is commented out or set to FALSE
# R will exactly match Stata without the MSE option results

# Stata svyset command notes can be found here: http://www.stata.com/help.cgi?svyset

# this data frame contains one set of beginline parameters for each year for each file to be read in
begin.lines <-
	data.frame(
		year = 2012:2005 ,
		household = c( 988 , 988 , 953 , 994 , 981 , 994 , 989 , 992 ) ,
		family = c( 1121 , 1121 , 1082 , 1137 , 1124 , 1143 , 1138 , 1141 ) ,
		person = c( 1209 , 1209 , 1166 , 1221 , 1208 , 1227 , 1222 , 1225 )
	)


# begin looping through every year specified
for ( year in cps.years.to.download ){

	# name the final data table to be saved in the working directory
	# this default setup will name the tables x05, x06, x07 and so on
	cps.tablename <- paste0( "x" , substr( year , 3 , 4 ) )

	# # # # # # # # # # # #
	# load the main file  #
	# # # # # # # # # # # #

	# this process is slow.
	# for example, the CPS ASEC 2011 file has 204,983 person-records.

	# note: this CPS March Supplement ASCII (fixed-width file) contains household-, family-, and person-level records.

	# census.gov website containing the current population survey's main file
	CPS.ASEC.mar.file.location <- 
		ifelse( 
			# if the year to download is 2012, the filename doesn't match others..
			year == 2012 ,
			"http://smpbff2.dsd.census.gov/pub/cps/march/asec2012early_pubuse.zip" ,
			
		ifelse(
			# if the year to download is 2007, the filename also doesn't match..
			year == 2007 ,
			"http://smpbff2.dsd.census.gov/pub/cps/march/asec2007_pubuse_tax2.zip" ,
			
			# otherwise download according to a pattern -
			paste0( "http://smpbff2.dsd.census.gov/pub/cps/march/asec" , year , "_pubuse.zip" )
		) )

	# national bureau of economic research website containing the current population survey's SAS import instructions
	CPS.ASEC.mar.SAS.read.in.instructions <- 
		ifelse( 
			# if the year to download is 2012, the sas import script isn't available yet, so use 2011..
			year == 2012 ,
			"http://www.nber.org/data/progs/cps/cpsmar11.sas" ,
			paste0( "http://www.nber.org/data/progs/cps/cpsmar" , substr( year , 3 , 4 ) , ".sas" )
		)

	# create a temporary file and a temporary directory..
	tf <- tempfile() ; td <- tempdir()

	# download the CPS repwgts zipped file to the local computer
	download.file( CPS.ASEC.mar.file.location , tf , mode = "wb" )

	# unzip the file's contents and store the file name within the temporary directory
	fn <- unzip( tf , exdir = td , overwrite = T )

	# create three more temporary files
	# to store household-, family-, and person-level records ..and also the crosswalk
	tf.household <- tempfile()
	tf.family <- tempfile()
	tf.person <- tempfile()
	tf.xwalk <- tempfile()
	
	# create four file connections.

	# one read-only file connection "r" - pointing to the ASCII file
	incon <- file( fn , "r") 

	# three write-only file connections "w" - pointing to the household, family, and person files
	outcon.household <- file( tf.household , "w") 
	outcon.family <- file( tf.family , "w") 
	outcon.person <- file( tf.person , "w") 
	outcon.xwalk <- file( tf.xwalk , "w" )
	
	# start line counter #
	line.num <- 0

	# store the current scientific notation option..
	cur.sp <- getOption( "scipen" )

	# ..and change it
	options( scipen = 10 )
		
		
	# figure out the ending position for each filetype
	# take the sum of the absolute value of the width parameter of the parsed-SAScii SAS input file, for household-, family-, and person-files separately
	end.household <- sum( abs( parse.SAScii( CPS.ASEC.mar.SAS.read.in.instructions , beginline = begin.lines[ begin.lines$year == year , 'household' ] )$width ) )
	end.family <- sum( abs( parse.SAScii( CPS.ASEC.mar.SAS.read.in.instructions , beginline = begin.lines[ begin.lines$year == year , 'family' ] )$width ) )
	end.person <- sum( abs( parse.SAScii( CPS.ASEC.mar.SAS.read.in.instructions , beginline = begin.lines[ begin.lines$year == year , 'person' ] )$width ) )
	
		
	# create a while-loop that continues until every line has been examined
	# cycle through every line in the downloaded CPS ASEC 20## file..

	while( length( line <- readLines( incon , 1 ) ) > 0 ){

		# ..and if the first character is a 1, add it to the new household-only CPS file.
		if ( substr( line , 1 , 1 ) == "1" ){
			
			# write the line to the household file
			writeLines( substr( line , 1 , end.household ) , outcon.household )
			
			# store the current unique household id
			curHH <- substr( line , 2 , 6 )
		
		}
		
		# ..and if the first character is a 2, add it to the new family-only CPS file.
		if ( substr( line , 1 , 1 ) == "2" ){
		
			# write the line to the family file
			writeLines( substr( line , 1 , end.family )  , outcon.family )
			
			# store the current unique family id
			curFM <- substr( line , 7 , 8 )
		
		}
		
		# ..and if the first character is a 3, add it to the new person-only CPS file.
		if ( substr( line , 1 , 1 ) == "3" ){
			
			# write the line to the person file
			writeLines( substr( line , 1 , end.person )  , outcon.person )
			
			# store the current unique person id
			curPN <- substr( line , 7 , 8 )
			
			writeLines( paste0( curHH , curFM , curPN ) , outcon.xwalk )
			
		}

		# add to the line counter #
		line.num <- line.num + 1

		# every 10k records..
		if ( line.num %% 10000 == 0 ) {
			
			# print current progress to the screen #
			cat( "   " , prettyNum( line.num  , big.mark = "," ) , "of approximately 400,000 cps asec lines processed" , "\r" )
			
		}
	}

	# restore the original scientific notation option
	options( scipen = cur.sp )

	# close all four file connections
	close( outcon.household )
	close( outcon.family )
	close( outcon.person )
	close( outcon.xwalk )
	close( incon , add = T )


	# for example: the 2011 SAS file produced by the National Bureau of Economic Research (NBER)
	# begins each INPUT block after lines 988, 1121, and 1209, 
	# so skip SAS import instruction lines before that.
	# NOTE that this 'beginline' parameters of 988, 1121, and 1209 will change for different years.

	# store CPS ASEC march household records as a MonetDB database
	read.SAScii.sql ( 
		tf.household , 
		CPS.ASEC.mar.SAS.read.in.instructions , 
		beginline = begin.lines[ begin.lines$year == year , 'household' ] , 
		zipped = F ,
		tl = TRUE ,
		tablename = 'household' ,
		db = db
	)
	
	# store CPS ASEC march family records as a MonetDB database
	read.SAScii.sql ( 
		tf.family , 
		CPS.ASEC.mar.SAS.read.in.instructions , 
		beginline = begin.lines[ begin.lines$year == year , 'family' ] , 
		zipped = F ,
		tl = TRUE ,
		tablename = 'family' ,
		db = db
	)

	# store CPS ASEC march person records as a MonetDB database
	read.SAScii.sql ( 
		tf.person , 
		CPS.ASEC.mar.SAS.read.in.instructions , 
		beginline = begin.lines[ begin.lines$year == year , 'person' ] , 
		zipped = F ,
		tl = TRUE ,
		tablename = 'person' ,
		db = db
	)

	# create a fake sas input script for the crosswalk..
	xwalk.sas <-
	"INPUT
		@1 h_seq 5.
		@6 ffpos 2.
		@8 pppos 2.
	;"
	
	# save it to the local disk
	xwalk.sas.tf <- tempfile()
	writeLines ( xwalk.sas , con = xwalk.sas.tf )

	
	# store CPS ASEC march xwalk records as a MonetDB database
	read.SAScii.sql ( 
		tf.xwalk , 
		xwalk.sas.tf , 
		zipped = F ,
		tl = TRUE ,
		tablename = 'xwalk' ,
		db = db
	)
	
	
	# create the merged file
	dbSendUpdate( db , "create table h_xwalk as select a.ffpos , a.pppos , b.* from xwalk as a inner join household as b on a.h_seq = b.h_seq with data" )
	
	
	# create the merge fields
	h_xwalk.fields <- paste0( 'a.' , dbListFields( db , 'h_xwalk' ) )
	family.fields <- paste0( 'b.' , dbListFields( db , 'family' ) )
	
	h_f_xwalk.fields <- 
		paste( 
			c( 
				h_xwalk.fields , 
				family.fields[ family.fields != 'b.ffpos' ] 
			) ,
			collapse = ", " 
		)

	# perform the merge (including all variables except the family table's ffpos field)
	dbSendUpdate( 
		db , 
		paste( 
			"create table h_f_xwalk as select" , 
			h_f_xwalk.fields , 
			"from h_xwalk as a inner join family as b on a.h_seq = b.fh_seq and a.ffpos = b.ffpos with data" 
		) 
	)
	
	# create the merge fields
	h_f_xwalk.fields <- paste0( 'a.' , dbListFields( db , 'h_f_xwalk' ) )
	person.fields <- paste0( 'b.' , dbListFields( db , 'person' ) )
	
	hfp.fields <- 
		paste( 
			c( 
				h_f_xwalk.fields , 
				person.fields[ !( person.fields %in% c( 'b.ph_seq' , 'b.pppos' ) ) ] 
			) ,
			collapse = ", " 
		)
	
	# perform the merge (including all variables except the person table's h_seq and pppos field)
	dbSendUpdate( 
		db , 
		paste( 
			"create table hfp as select" , 
			hfp.fields , 
			"from h_f_xwalk as a inner join person as b on a.h_seq = b.ph_seq and a.pppos = b.pppos with data" 
		) 
	)
	


	# drop unnecessary tables
	dbSendUpdate( db , "drop table h_xwalk" )		# household xwalk
	dbSendUpdate( db , "drop table h_f_xwalk" )		# household family xwalk
	dbSendUpdate( db , "drop table xwalk" )			# xwalk


	# confirm that the number of records in the cps asec merged file
	# matches the number of records in the person file
	stopifnot( dbGetQuery( db , "select count(*) as count from hfp" ) == dbGetQuery( db , "select count(*) as count from person" ) )


	# # # # # # # # # # # # # # # # # #
	# load the replicate weight file  #
	# # # # # # # # # # # # # # # # # #
			
	# this process is also slow.
	# for example, the CPS ASEC 2011 replicate weight file has 204,983 person-records.

	# census.gov website containing the current population survey's replicate weights file
	CPS.replicate.weight.file.location <- 
		paste0( "http://smpbff2.dsd.census.gov/pub/cps/march/CPS_ASEC_ASCII_REPWGT_" , year , ".zip" )
		
	# census.gov website containing the current population survey's SAS import instructions
	CPS.replicate.weight.SAS.read.in.instructions <- 
		paste0( "http://smpbff2.dsd.census.gov/pub/cps/march/CPS_ASEC_ASCII_REPWGT_" , year , ".SAS" )

	# store the CPS ASEC march 20## replicate weight file as an R data frame
	read.SAScii.sql ( 
		CPS.replicate.weight.file.location , 
		CPS.replicate.weight.SAS.read.in.instructions , 
		zipped = T , 
		tl = TRUE ,
		tablename = 'rw' ,
		db = db
	)


	###################################################
	# merge cps asec file with replicate weights file #
	###################################################

	# create the merge fields
	hfp.fields <- paste0( 'a.' , dbListFields( db , 'hfp' ) )
	rw.fields <- paste0( 'b.' , dbListFields( db , 'rw' ) )
	
	final.fields <- 
		paste( 
			c( 
				hfp.fields , 
				rw.fields[ !( rw.fields %in% c( 'b.h_seq' , 'b.pppos' ) ) ] 
			) ,
			collapse = ", " 
		)
	
	dbSendUpdate( 
		db , 
		paste( 
			"create table" ,
			cps.tablename ,
			"as select" ,
			final.fields ,
			"from hfp as a inner join rw as b on a.h_seq = b.h_seq AND a.pppos = b.pppos with data"
		)
	)

	
	# confirm that the number of records in the person file
	# matches the number of records in the merged file
	stopifnot( dbGetQuery( db , paste( "select count(*) as count from" , cps.tablename ) ) == dbGetQuery( db , "select count(*) as count from person" ) )

	# drop unnecessary tables
	dbSendUpdate( db , "drop table hfp" )
	dbSendUpdate( db , "drop table rw" )
	dbSendUpdate( db , "drop table person" )
	dbSendUpdate( db , "drop table family" )
	dbSendUpdate( db , "drop table household" )
	dbSendUpdate( db , "drop table rw" )

	# add a new column "one" that simply contains the number 1 for every record in the data set
	dbSendUpdate( db , paste( "ALTER TABLE" , cps.tablename , "ADD COLUMN one" ) )
	dbSendUpdate( db , paste( "UPDATE" , cps.tablename , "SET one = 1" ) )

	# set the table read-only!
	dbSendUpdate( db , paste( "ALTER TABLE" , cps.tablename , "SET READ ONLY" ) )


	stop( 'add sqlsurveyrepdesign statement here' )
	
	stop( 'add save() commands for sqlsurveyrepdesigns' )
	
}

# disconnect from the current database
dbDisconnect( db )

# print a reminder: set the directory you just saved everything to as read-only!
winDialog( 'ok' , paste( "all done.  you should set" , getwd() , "read-only so you don't accidentally alter these files." ) )


# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
