# analyze survey data for free (http://asdfree.com) with the r language
# survey of income and program participation
# 2004 panel
# 12 core waves, 12 wave-specific replicate weights, 8 topical modules, 
# 4 panel year replicate weights, 4 calendar year replicate weights, 1 longitudinal weights

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/SIPP/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Survey%20of%20Income%20and%20Program%20Participation/2004%20panel%20-%20download%20and%20create%20database.R" , prompt = FALSE , echo = TRUE )
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


#####################################################################################################################
# Download and Create a Database with the 2004 Panel of the Survey of Income and Program Participation files with R #
#####################################################################################################################


# set your working directory.
# all SIPP data files will be stored here
# after downloading and importing.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/SIPP/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( c( "RSQLite" , "SAScii" , "descr" , "downloader" ) )


SIPP.dbname <- "SIPP04.db"											# choose the name of the database (.db) file on the local disk

sipp.core.waves <- 1:12												# either choose which core survey waves to download, or set to null
sipp.replicate.waves <- 1:12										# either choose which replicate weight waves to download, or set to null
sipp.topical.modules <- 1:8											# either choose which topical modules to download, or set to NULL
sipp.longitudinal.weights <- TRUE									# set to FALSE to prevent download
sipp.cy.longitudinal.replicate.weights <- paste0( 'cy' , 1:4 )		# 1-4 reads in 2004-2007
sipp.pnl.longitudinal.replicate.weights <- paste0( 'pnl' , 1:4 )	# 1-4 reads in 2004-2007
sipp.assets.extracts <- TRUE										# set to FALSE to prevent download

############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #


library(RSQLite) 	# load RSQLite package (creates database files in R)
library(SAScii) 	# load the SAScii package (imports ascii data with a SAS script)
library(downloader)	# downloads and then runs the source() function on scripts from github

# open the connection to the sqlite database
db <- dbConnect( SQLite() , SIPP.dbname )


##############################################################################
# function to fix sas input scripts where census has the incorrect column type
fix.ct <-
	function( sasfile ){
		sas_lines <- readLines( sasfile )

		# ssuid should always be numeric (it's occasionally character)
		sas_lines <- gsub( "SSUID $" , "SSUID" , sas_lines )
		
		# ctl_date and lgtwttyp contain strings not numbers
		sas_lines <- gsub( "CTL_DATE" , "CTL_DATE $" , sas_lines )
		sas_lines <- gsub( "LGTWTTYP" , "LGTWTTYP $" , sas_lines )

		# create a temporary file
		tf <- tempfile()
		
		# write the updated sas input file to the temporary file
		writeLines( sas_lines , tf )

		# return the filepath to the temporary file containing the updated sas input script
		tf
	}
##############################################################################


##################################################################################
# sas importation scripts with an `SUID` column near the end
# are incorrect.  the census bureau just left them in,
# and the SAScii package won't just throw 'em out for ya.
# so throw out the non-public lines manually.
chop.suid <-
	function( sf ){

		# create a temporary file
		tf <- tempfile()
		
		# read the sas lines into memory
		sl <- readLines( sf )

		# figure out the position of the `suid` variable..
		where.to.chop <- which( grepl( 'suid' , tolower( sl ) ) & !grepl( 'ssuid' , tolower( sl ) ) )

		# if it exists..
		if( length( where.to.chop ) > 0 ){

			# find all semicolons in the document..
			semicolons <- grep( ';' , sl )

			# ..now, more precisely, find the first semicolon after the chop-line
			end.of.chop <- min( semicolons[ semicolons > where.to.chop ] ) - 1
			
			# remove non-public lines
			sl <- sl[ -where.to.chop:-end.of.chop ]

		}

		# write the sas import script to the text file..
		writeLines( sl , tf )

		# ..and return the position of the text file on the local disk.
		tf

	}
##################################################################################


# load the read.SAScii.sqlite function (a variant of read.SAScii that creates a database directly)
source_url( "https://raw.github.com/ajdamico/usgsd/master/SQLite/read.SAScii.sqlite.R" , prompt = FALSE )

# set the locations of the data files on the ftp site
SIPP.core.sas <-
	"http://thedataweb.rm.census.gov/pub/sipp/2004/l04puw1.sas"
	
SIPP.replicate.sas <-
	"http://thedataweb.rm.census.gov/pub/sipp/2004/rw04wx.sas"
	
SIPP.longitudinal.sas <-
	"http://thedataweb.rm.census.gov/pub/sipp/2004/lgtwgt2004w12.sas"
	
SIPP.longitudinal.replicate.sas <-
	"http://thedataweb.rm.census.gov/pub/sipp/2004/lrw04_xx.sas"

# if the longitudinal weights flag has been set to TRUE above..
if ( sipp.longitudinal.weights ){

	# add the longitudinal weights to the database in a table 'w12'
	read.SAScii.sqlite(
		"http://thedataweb.rm.census.gov/pub/sipp/2004/lgtwgt2004w12.zip" ,
		chop.suid( fix.ct( "http://thedataweb.rm.census.gov/pub/sipp/2004/lgtwgt2004w12.sas" ) ) ,
		beginline = 5 ,
		zipped = T ,
		tl = TRUE ,
		tablename = "wgtw12" ,
		conn = db
	)
}
	
# loop through each core wave..
for ( i in sipp.core.waves ){

	# figure out the exact ftp path of the .zip file
	SIPP.core <-
		paste0( "http://thedataweb.rm.census.gov/pub/sipp/2004/l04puw" , i , ".zip" )

	# add the core wave to the database in a table w#
	read.SAScii.sqlite (
			SIPP.core ,
			chop.suid( fix.ct( SIPP.core.sas ) ) ,
			beginline = 5 ,
			zipped = T ,
			tl = TRUE ,
			tablename = paste0( "w" , i ) ,
			conn = db
		)
}

# loop through each replicate weight wave..
for ( i in sipp.replicate.waves ){

	# figure out the exact ftp path of the .zip file
	SIPP.rw <-
		paste0( "http://thedataweb.rm.census.gov/pub/sipp/2004/rw04w" , i , ".zip" )

	# add the wave-specific replicate weight to the database in a table rw#
	read.SAScii.sqlite (
			SIPP.rw ,
			chop.suid( fix.ct( SIPP.replicate.sas ) ) ,
			beginline = 5 ,
			zipped = T ,
			tl = TRUE ,
			tablename = paste0( "rw" , i ) ,
			conn = db
		)
}

# loop through each topical module..
for ( i in sipp.topical.modules ){

	# figure out the exact ftp path of the .zip file
	SIPP.tm <-
		paste0( "http://thedataweb.rm.census.gov/pub/sipp/2004/p04putm" , i , ".zip" )

	# figure out the exact ftp path of the .sas file
	SIPP.tm.sas <-
		paste0( "http://thedataweb.rm.census.gov/pub/sipp/2004/p04putm" , i , ".sas" )
		
	# add each topical module to the database in a table tm#
	read.SAScii.sqlite (
			SIPP.tm ,
			chop.suid( fix.ct( SIPP.tm.sas ) ) ,
			beginline = 5 ,
			zipped = T ,
			tl = TRUE ,
			tablename = paste0( "tm" , i ) ,
			conn = db
		)
}

# add the two sipp assets extracts to the database
if( sipp.assets.extracts ){

	read.SAScii.sqlite (
			"http://thedataweb.rm.census.gov/pub/sipp/2004/p04putm3_aoa.zip" ,
			chop.suid( "http://thedataweb.rm.census.gov/pub/sipp/2004/p04putm3_aoa.sas" ) ,
			beginline = 5 ,
			zipped = T ,
			tl = TRUE ,
			tablename = "aoa3" ,
			conn = db
		)

	read.SAScii.sqlite (
			"http://thedataweb.rm.census.gov/pub/sipp/2004/p04putm6_aoa.zip" ,
			chop.suid( "http://thedataweb.rm.census.gov/pub/sipp/2004/p04putm6_aoa.sas" ) ,
			beginline = 4 ,
			zipped = T ,
			tl = TRUE ,
			tablename = "aoa6" ,
			conn = db
		)

	# remove the overlapping variable names
	# from the tm3 and tm6 data tables,
	# since they should now be pulled from aoa3 and aoa6
		
	# pull all field names from the wave 6 assets extract
	aoa6.fields <- dbListFields( db , 'aoa6' )
	
	# remove ssuid and epppnum
	aoa6.fields <- aoa6.fields[ !( aoa6.fields %in% c( 'ssuid' , 'epppnum' ) ) ]
	
	# find non-intersecting fields in both of those topical modules
	tm3.nis <- dbListFields( db , 'tm3' )[ !( dbListFields( db , 'tm3' ) %in% aoa6.fields ) ]
	tm6.nis <- dbListFields( db , 'tm6' )[ !( dbListFields( db , 'tm6' ) %in% aoa6.fields ) ]

	# create temporary tables, without the intersection columns
	tm3.ct <- 
		paste( 
			'create table temp_tm3 as select' ,
			paste( tm3.nis , collapse = " , " ) ,
			'from tm3'
		)
	
	tm6.ct <- 
		paste( 
			'create table temp_tm6 as select' ,
			paste( tm6.nis , collapse = " , " ) ,
			'from tm6'
		)
	
	# send those create table commands to the database
	dbSendQuery( db , tm3.ct )
	dbSendQuery( db , tm6.ct )
	
	# remove the `tm3` and `tm6` tables completely
	dbRemoveTable( db , 'tm3' )
	dbRemoveTable( db , 'tm6' )
	
	# copy over the newly-reduced `tm3` and `tm6` tables
	# to their prior name
	dbSendQuery( db , 'create table tm3 as select * from temp_tm3' )
	dbSendQuery( db , 'create table tm6 as select * from temp_tm6' )
		
	# remove the `temp_tm3` and `temp_tm6` tables completely
	dbRemoveTable( db , 'temp_tm3' )
	dbRemoveTable( db , 'temp_tm6' )
	
}

# loop through each longitudinal replicate weight file..
for ( i in c( sipp.cy.longitudinal.replicate.weights , sipp.pnl.longitudinal.replicate.weights ) ){

	# figure out the exact ftp path of the .zip file
	SIPP.lrw <-
		paste0( "http://thedataweb.rm.census.gov/pub/sipp/2004/lrw04_" , i , ".zip" )
		
	# add each longitudinal replicate weight file to the database in a table cy1-4 or pnl1-4
	read.SAScii.sqlite (
			SIPP.lrw ,
			chop.suid( fix.ct( SIPP.longitudinal.replicate.sas ) ) ,
			beginline = 5 ,
			zipped = T ,
			tl = TRUE ,
			tablename = i ,
			conn = db
		)
}
# the current working directory should now contain one database (.db) file


# database goodwill check!
# does every table in this sqlite database have *at least* one record?
for ( tablename in dbListTables( db ) ){
	stopifnot( dbGetQuery( db , paste( 'select count(*) from' , tablename ) ) > 0 )
}
# end of checking that every imported table has at least one record.


# disconnect from the database
dbDisconnect( db )


# once complete, this script does not need to be run again.
# instead, use one of the survey of income and program participation analysis scripts
# which utilize this newly-created database (.db) files



# print a reminder: set the directory you just saved everything to as read-only!
message( paste0( "all done.  you should set the file " , file.path( getwd() , SIPP.dbname ) , " read-only so you don't accidentally alter these tables." ) )


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
