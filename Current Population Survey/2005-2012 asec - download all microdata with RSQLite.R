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

setwd( "C:/My Directory/CPS/" )


# remove the # in order to run this install.packages line only once
# install.packages( c( "survey" , "RSQLite" , "SAScii" ) )


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
source_https( "https://raw.github.com/ajdamico/usgsd/master/read.SAScii.sql.R" )


require(RSQLite) 	# load RSQLite package (creates database files in R)
require(survey)		# load survey package (analyzes complex design surveys)
require(SAScii) 	# load the SAScii package (imports ascii data with a SAS script)


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

	# name the database (.db) file to be saved in the working directory
	cps.dbname <- paste( "cps.asec" , year , "db" , sep = ".")

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
	# to store household-, family-, and person-level records
	tf.household <- tempfile()
	tf.family <- tempfile()
	tf.person <- tempfile()

	# create four file connections.

	# one read-only file connection "r" - pointing to the ASCII file
	incon <- file( fn , "r") 

	# three write-only file connections "w" - pointing to the household, family, and person files
	outcon.household <- file( tf.household , "w") 
	outcon.family <- file( tf.family , "w") 
	outcon.person <- file( tf.person , "w") 

	# build a merge file at the same time as distributing the main file into three other files
	xwalk <- xwalk.10k <- data.frame( NULL )

	# start line counter #
	line.num <- 0

	# store the current scientific notation option..
	cur.sp <- getOption( "scipen" )

	# ..and change it
	options( scipen = 10 )
		
	# create a while-loop that continues until every line has been examined
	# cycle through every line in the downloaded CPS ASEC 2011 file..

	while( length( line <- readLines( incon , 1 ) ) > 0 ){

		# ..and if the first character is a 1, add it to the new household-only CPS file.
		if ( substr( line , 1 , 1 ) == "1" ){
			
			# write the line to the household file
			writeLines( line , outcon.household )
			
			# store the current unique household id
			curHH <- substr( line , 2 , 6 )
		
		}
		
		# ..and if the first character is a 2, add it to the new family-only CPS file.
		if ( substr( line , 1 , 1 ) == "2" ){
		
			# write the line to the family file
			writeLines( line , outcon.family )
			
			# store the current unique family id
			curFM <- substr( line , 7 , 8 )
		
		}
		
		# ..and if the first character is a 3, add it to the new person-only CPS file.
		if ( substr( line , 1 , 1 ) == "3" ){
			
			# write the line to the person file
			writeLines( line , outcon.person )
			
			# store the current unique person id
			curPN <- substr( line , 7 , 8 )
			
			# merge file creation #
			
			# ..and add the current unique household x family x person identifier values to the merge file
			xwalk.temp <- 
				data.frame( 
					h_seq = as.numeric( curHH ) , 
					ffpos = as.numeric( curFM ) , 
					pppos = as.numeric( curPN ) 
				)
			
			# ..and also stack it at the bottom of the current xwalk.10k
			xwalk.10k <- rbind( xwalk.10k , xwalk.temp )
			
		}

		# add to the line counter #
		line.num <- line.num + 1

		# every 10k records..
		if ( line.num %% 10000 == 0 ) {
			
			# add the current xwalk.10k to the bottom of the total xwalk #
			xwalk <- rbind( xwalk , xwalk.10k )
			
			# blank out xwalk.10k #
			xwalk.10k <- NULL
			
			# clear up RAM
			gc()
			
			# print current progress to the screen #
			cat( "   " , prettyNum( line.num  , big.mark = "," ) , "of approximately 400,000 cps asec lines processed" , "\r" )
			
		}
	}


	# add the remaining xwalk.10k to the bottom of the total xwalk #
	xwalk <- rbind( xwalk , xwalk.10k )

	# blank out xwalk.10k #
	xwalk.10k <- NULL

	# clear up RAM
	gc()

	# restore the original scientific notation option
	options( scipen = cur.sp )

	# close all four file connections
	close( outcon.household )
	close( outcon.family )
	close( outcon.person )
	close( incon , add = T )


	# open the connection to the sqlite database
	db <- dbConnect( SQLite() , cps.dbname )


	# the 2011 SAS file produced by the National Bureau of Economic Research (NBER)
	# begins each INPUT block after lines 988, 1121, and 1209, 
	# so skip SAS import instruction lines before that.
	# NOTE that this 'beginline' parameters of 988, 1121, and 1209 will change for different years.

	# store CPS ASEC march household records as a SQLite database
	read.SAScii.sql ( 
		tf.household , 
		CPS.ASEC.mar.SAS.read.in.instructions , 
		beginline = begin.lines[ begin.lines$year == year , 'household' ] , 
		zipped = F ,
		tl = TRUE ,
		tablename = 'household' ,
		dbname = cps.dbname 
	)

	# create an index to speed up the merge
	dbSendQuery( db , paste0( "CREATE INDEX household_index ON household ( h_seq )" ) )

		
	# store CPS ASEC march family records as a SQLite database
	read.SAScii.sql ( 
		tf.family , 
		CPS.ASEC.mar.SAS.read.in.instructions , 
		beginline = begin.lines[ begin.lines$year == year , 'family' ] , 
		zipped = F ,
		tl = TRUE ,
		tablename = 'family' ,
		dbname = cps.dbname
	)

	# create an index to speed up the merge
	dbSendQuery( db , paste0( "CREATE INDEX family_index ON family ( fh_seq , ffpos )" ) )


	# store CPS ASEC march person records as a SQLite database
	read.SAScii.sql ( 
		tf.person , 
		CPS.ASEC.mar.SAS.read.in.instructions , 
		beginline = begin.lines[ begin.lines$year == year , 'person' ] , 
		zipped = F ,
		tl = TRUE ,
		tablename = 'person' ,
		dbname = cps.dbname
	)

	# create an index to speed up the merge
	dbSendQuery( db , paste0( "CREATE INDEX person_index ON person ( ph_seq , pppos )" ) )

	# reset the database (.db)
	dbBeginTransaction( db )
	dbCommit( db )
	
	# store CPS ASEC march 2011 xwalk records as a SQLite database	
	dbWriteTable( db , 'xwalk' , xwalk )
	
	# create an index to speed up the merge
	dbSendQuery( db , paste0( "CREATE INDEX xwalk_index ON xwalk ( h_seq , ffpos , pppos )" ) )

	# remove the xwalk table from memory
	rm( xwalk )
	
	# clear up RAM
	gc()

	
	# create the merged file
	dbSendQuery( db , "create table h_xwalk as select * from xwalk as a inner join household as b on a.h_seq = b.h_seq" )
	dbSendQuery( db , "create table h_f_xwalk as select * from h_xwalk as a inner join family as b on a.h_seq = b.fh_seq AND a.ffpos = b.ffpos" )
	dbSendQuery( db , "create table h_f_p as select * from h_f_xwalk as a inner join person as b on a.h_seq = b.ph_seq AND a.pppos = b.pppos" )
	dbSendQuery( db , paste0( "CREATE INDEX hfp_index ON xwalk ( h_seq , ffpos , pppos )" ) )


	# drop unnecessary tables
	dbSendQuery( db , "drop table h_xwalk" )
	dbSendQuery( db , "drop table h_f_xwalk" )
	dbSendQuery( db , "drop table xwalk" )


	# confirm that the number of records in the 2011 cps asec merged file
	# matches the number of records in the person file
	stopifnot( dbGetQuery( db , "select count(*) as count from h_f_p" ) == dbGetQuery( db , "select count(*) as count from person" ) )


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
	read.SAScii.sql ( 
		CPS.replicate.weight.file.location , 
		CPS.replicate.weight.SAS.read.in.instructions , 
		zipped = T , 
		tl = TRUE ,
		tablename = 'rw' ,
		dbname = cps.dbname
	)

	# create an index to speed up the merge
	dbSendQuery( db , paste0( "CREATE INDEX rw_index ON rw ( h_seq , pppos )" ) )


	###################################################
	# merge cps asec file with replicate weights file #
	###################################################

	dbSendQuery( db , "create table x as select * from h_f_p as a inner join rw as b on a.h_seq = b.h_seq AND a.pppos = b.pppos" )

	# drop unnecessary tables
	dbSendQuery( db , "drop table h_f_p" )
	dbSendQuery( db , "drop table rw" )

	# confirm that the number of records in the 2011 person file
	# matches the number of records in the merged file
	stopifnot( dbGetQuery( db , "select count(*) as count from x" ) == dbGetQuery( db , "select count(*) as count from person" ) )

	# add a new column "one" that simply contains the number 1 for every record in the data set
	dbSendQuery( db , "ALTER TABLE x ADD one" )
	dbSendQuery( db , "UPDATE x SET one = 1" )

	# disconnect from the current database
	dbDisconnect( db )
	
}
# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
