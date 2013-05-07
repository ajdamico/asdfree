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


# set your working directory.
# the CPS 2005 - 2012 data files will be stored here
# after downloading and importing them.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/CPS/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( c( "survey" , "RSQLite" , "SAScii" , "descr" , "downloader" ) )


# define which years to download #

# uncomment this line to download all available data sets
# uncomment this line by removing the `#` at the front
# cps.years.to.download <- 2012:2005

# uncomment this line to only download the most current year
# cps.years.to.download <- 2011

# uncomment this line to download, for example, 2005 and 2009-2011
# cps.years.to.download <- c( 2011:2009 , 2005 )


# name the database (.db) file to be saved in the working directory
cps.dbname <- "cps.asec.db"


############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #

# if the cps database file already exists in the current working directory, print a warning
if ( file.exists( paste( getwd() , cps.dbname , sep = "/" ) ) ) warning( "the database file already exists in your working directory.\nyou might encounter an error if you are running the same year as before or did not allow the program to complete.\ntry changing the cps.dbname in the settings above." )


require(RSQLite) 	# load RSQLite package (creates database files in R)
require(survey)		# load survey package (analyzes complex design surveys)
require(SAScii) 	# load the SAScii package (imports ascii data with a SAS script)
require(descr) 		# load the descr package (converts fixed-width files to delimited files)
require(downloader)	# downloads and then runs the source() function on scripts from github


# load the read.SAScii.sqlite function (a variant of read.SAScii that creates a database directly)
source_url( "https://raw.github.com/ajdamico/usgsd/master/SQLite/read.SAScii.sqlite.R" )


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
		household = c( 993 , 988 , 953 , 994 , 981 , 994 , 989 , 992 ) ,
		family = c( 1129 , 1121 , 1082 , 1137 , 1124 , 1143 , 1138 , 1141 ) ,
		person = c( 1218 , 1209 , 1166 , 1221 , 1208 , 1227 , 1222 , 1225 )
	)


# begin looping through every cps year specified
for ( year in cps.years.to.download ){


	# name the final data table to be saved in the working directory
	# this default setup will name the tables asec05, asec06, asec07 and so on
	cps.tablename <- paste0( "asec" , substr( year , 3 , 4 ) )


	# # # # # # # # # # # #
	# load the main file  #
	# # # # # # # # # # # #

	# this process is slow.
	# for example, the CPS ASEC 2011 file has 204,983 person-records.

	# note: this CPS March Supplement ASCII (fixed-width file) contains household-, family-, and person-level records.

	# census.gov website containing the current population survey's main file
	CPS.ASEC.mar.file.location <- 
		ifelse( 
			# if the year to download is 2007, the filename doesn't match the others..
			year == 2007 ,
			"http://smpbff2.dsd.census.gov/pub/cps/march/asec2007_pubuse_tax2.zip" ,
			
			# otherwise download according to a pattern -
			paste0( "http://smpbff2.dsd.census.gov/pub/cps/march/asec" , year , "_pubuse.zip" )
		)

	# national bureau of economic research website containing the current population survey's SAS import instructions
	CPS.ASEC.mar.SAS.read.in.instructions <- 
			paste0( "http://www.nber.org/data/progs/cps/cpsmar" , substr( year , 3 , 4 ) , ".sas" )

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


	# open the connection to the sqlite database
	db <- dbConnect( SQLite() , cps.dbname )


	# the 2011 SAS file produced by the National Bureau of Economic Research (NBER)
	# begins each INPUT block after lines 988, 1121, and 1209, 
	# so skip SAS import instruction lines before that.
	# NOTE that this 'beginline' parameters of 988, 1121, and 1209 will change for different years.

	# store CPS ASEC march household records as a SQLite database
	read.SAScii.sqlite ( 
		tf.household , 
		CPS.ASEC.mar.SAS.read.in.instructions , 
		beginline = begin.lines[ begin.lines$year == year , 'household' ] , 
		zipped = F ,
		tl = TRUE ,
		tablename = 'household' ,
		db = db
	)
	
	# create an index to speed up the merge
	dbSendQuery( db , "CREATE INDEX household_index ON household ( h_seq )" )


	# store CPS ASEC march family records as a SQLite database
	read.SAScii.sqlite ( 
		tf.family , 
		CPS.ASEC.mar.SAS.read.in.instructions , 
		beginline = begin.lines[ begin.lines$year == year , 'family' ] , 
		zipped = F ,
		tl = TRUE ,
		tablename = 'family' ,
		db = db
	)

	# create an index to speed up the merge
	dbSendQuery( db , "CREATE INDEX family_index ON family ( fh_seq , ffpos )" )


	# store CPS ASEC march person records as a SQLite database
	read.SAScii.sqlite ( 
		tf.person , 
		CPS.ASEC.mar.SAS.read.in.instructions , 
		beginline = begin.lines[ begin.lines$year == year , 'person' ] , 
		zipped = F ,
		tl = TRUE ,
		tablename = 'person' ,
		db = db
	)

	# create an index to speed up the merge
	dbSendQuery( db , "CREATE INDEX person_index ON person ( ph_seq , pppos )" )


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

	
	# store CPS ASEC march xwalk records as a SQLite database
	read.SAScii.sqlite ( 
		tf.xwalk , 
		xwalk.sas.tf , 
		zipped = F ,
		tl = TRUE ,
		tablename = 'xwalk' ,
		db = db
	)

	# create an index to speed up the merge
	dbSendQuery( db , "CREATE INDEX xwalk_index ON xwalk ( h_seq , ffpos , pppos )" )

		
	# reset the database (.db)
	# dbBeginTransaction( db )
	# dbCommit( db )
	
	# clear up RAM
	gc()

	
	# create the merged file
	dbSendQuery( db , "create table h_xwalk as select * from xwalk as a inner join household as b on a.h_seq = b.h_seq" )
	dbSendQuery( db , "create table h_f_xwalk as select * from h_xwalk as a inner join family as b on a.h_seq = b.fh_seq AND a.ffpos = b.ffpos" )
	dbSendQuery( db , "create table hfp as select * from h_f_xwalk as a inner join person as b on a.h_seq = b.ph_seq AND a.pppos = b.pppos" )
	dbSendQuery( db , "CREATE INDEX hfp_index ON hfp ( h_seq , ffpos , pppos )" )


	# drop unnecessary tables
	dbSendQuery( db , "drop table h_xwalk" )
	dbSendQuery( db , "drop table h_f_xwalk" )
	dbSendQuery( db , "drop table xwalk" )


	# confirm that the number of records in the 2011 cps asec merged file
	# matches the number of records in the person file
	stopifnot( dbGetQuery( db , "select count(*) as count from hfp" ) == dbGetQuery( db , "select count(*) as count from person" ) )


	# # # # # # # # # # # # # # # # # #
	# load the replicate weight file  #
	# # # # # # # # # # # # # # # # # #
			
	# this process is also slow.
	# the CPS ASEC 2011 replicate weight file has 204,983 person-records.

	# census.gov website containing the current population survey's replicate weights file
	CPS.replicate.weight.file.location <- 
		paste0( "http://smpbff2.dsd.census.gov/pub/cps/march/CPS_ASEC_ASCII_REPWGT_" , year , ".zip" )
		
	# census.gov website containing the current population survey's SAS import instructions
	CPS.replicate.weight.SAS.read.in.instructions <- 
		paste0( "http://smpbff2.dsd.census.gov/pub/cps/march/CPS_ASEC_ASCII_REPWGT_" , year , ".SAS" )

	# store the CPS ASEC march 2011 replicate weight file as an R data frame
	read.SAScii.sqlite ( 
		CPS.replicate.weight.file.location , 
		CPS.replicate.weight.SAS.read.in.instructions , 
		zipped = T , 
		tl = TRUE ,
		tablename = 'rw' ,
		db = db
	)

	# create an index to speed up the merge
	dbSendQuery( db , "CREATE INDEX rw_index ON rw ( h_seq , pppos )" )


	###################################################
	# merge cps asec file with replicate weights file #
	###################################################

	sql <- paste( "create table" , cps.tablename , "as select * from hfp as a inner join rw as b on a.h_seq = b.h_seq AND a.pppos = b.pppos" )
	
	dbSendQuery( db , sql )
	
	# confirm that the number of records in the 2011 person file
	# matches the number of records in the merged file
	stopifnot( dbGetQuery( db , paste( "select count(*) as count from " , cps.tablename ) ) == dbGetQuery( db , "select count(*) as count from person" ) )


	# drop unnecessary tables
	dbSendQuery( db , "drop table hfp" )
	dbSendQuery( db , "drop table rw" )
	dbSendQuery( db , "drop table household" )
	dbSendQuery( db , "drop table family" )
	dbSendQuery( db , "drop table person" )

	
	# add a new column "one" that simply contains the number 1 for every record in the data set
	dbSendQuery( db , paste( "ALTER TABLE" , cps.tablename , "ADD one REAL" ) )
	dbSendQuery( db , paste( "UPDATE" , cps.tablename , "SET one = 1" ) )

	# disconnect from the current database
	dbDisconnect( db )
	
}


# print a reminder: set the directory you just saved everything to as read-only!
message( paste0( "all done.  you should set the file " , file.path( getwd() , cps.dbname ) , " read-only so you don't accidentally alter these tables." ) )


# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
