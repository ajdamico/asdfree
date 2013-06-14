# analyze us government survey data with the r language
# survey of income and program participation
# 2008 panel
# 11 core waves, 11 wave-specific replicate weights, 9 topical modules, 
# 2 panel year replicate weights, 2 calendar year replicate weights, 1 longitudinal weights

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
# Download and Create a Database with the 2008 Panel of the Survey of Income and Program Participation files with R #
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


SIPP.dbname <- "SIPP08.db"														# choose the name of the database (.db) file on the local disk

sipp.core.waves <- 1:12															# either choose which core survey waves to download, or set to NULL
sipp.replicate.waves <- 1:12													# either choose which replicate weight waves to download, or set to NULL
sipp.topical.modules <- 1:11													# either choose which topical modules to download, or set to NULL
sipp.longitudinal.weights <- TRUE												# set to FALSE to prevent download
sipp.cy.longitudinal.replicate.weights <- paste0( 'cy' , c( "09" , "10" ) )		# reads in 2009-2010
sipp.pnl.longitudinal.replicate.weights <- paste0( 'pnl' , c( "09" , "10" ) )	# reads in 2009-2010

############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #


require(RSQLite) 	# load RSQLite package (creates database files in R)
require(SAScii) 	# load the SAScii package (imports ascii data with a SAS script)
require(downloader)	# downloads and then runs the source() function on scripts from github


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

###################################################################################
# function to fix sas input scripts where repwgt values are collapsed into one line
# (the SAScii function cannot currently handle this SAS configuration on its own)
fix.repwgt <-
	function( sasfile ){
		sas_lines <- readLines( sasfile )

		# identify the line containing REPWGT
		rep.position <- grep( "REPWGT" , sas_lines )
		
		# look at the line directly above it..
		line.above <- strsplit( sas_lines[ rep.position - 1 ] , "-" )[[1]]
		
		# ..and figure out what position it ends at
		end.position <- as.numeric( line.above[ length( line.above ) ] )
		
		# start with a line containing ()
		j <- sas_lines[ rep.position ]

		# courtesy of this discussion on stackoverflow.com
		# http://stackoverflow.com/questions/8613237/extract-info-inside-all-parenthesis-in-r-regex
		# break it into two strings without the ()
		k <- gsub( 
				"[\\(\\)]", 
				"" , 
				regmatches(
					j , 
					gregexpr( 
						"\\(.*?\\)" , 
						j
					)
				)[[1]]
			)

		# number of repweights
		l <- as.numeric( gsub( "REPWGT1-REPWGT" , "" , k )[1] )

		# length of repweights (assumes no decimals!)
		m <- as.numeric( k[2] )

		# these should start at the end position (determined above) plus one
		start.vec <- ( end.position + 1 ) + ( m * 0:( l - 1 ) )
		end.vec <- ( end.position ) + ( m * 1:l )
		
		
		# vector of all repweight lines
		repwgt.lines <-
			paste0( "REPWGT" , 1:l , " " , start.vec , "-" , end.vec )

		# collapse them all together into one string
		repwgt.line <- paste( repwgt.lines , collapse = " " )

		# finally replace the old line with the new line in the sas input script
		sas_lines <- gsub( j , repwgt.line , sas_lines , fixed = TRUE )
		
		# create a temporary file
		tf <- tempfile()
		
		# write the updated sas input file to the temporary file
		writeLines( sas_lines , tf )

		# return the filepath to the temporary file containing the updated sas input script
		tf
	}
##################################################################################


# load the read.SAScii.sqlite function (a variant of read.SAScii that creates a database directly)
source_url( "https://raw.github.com/ajdamico/usgsd/master/SQLite/read.SAScii.sqlite.R" , prompt = FALSE )

# set the locations of the data files on the ftp site
SIPP.core.sas <-
	"http://smpbff2.dsd.census.gov/pub/sipp/2008/l08puw1.sas"
	
SIPP.replicate.sas <-
	"http://smpbff2.dsd.census.gov/pub/sipp/2008/rw08wx.sas"
	
SIPP.longitudinal.sas <-
	"http://smpbff2.dsd.census.gov/pub/sipp/2008/lgtwgt2008w7.sas"

SIPP.longitudinal.replicate.sas <-
	"http://smpbff2.dsd.census.gov/pub/sipp/2008/lrw08_xx.sas"

# if the longitudinal weights flag has been set to TRUE above..
if ( sipp.longitudinal.weights ){

	# add the longitudinal weights to the database in a table 'w12'
	read.SAScii.sqlite(
		"http://smpbff2.dsd.census.gov/pub/sipp/2008/lgtwgt2008w7.zip" ,
		fix.ct( "http://smpbff2.dsd.census.gov/pub/sipp/2008/lgtwgt2008w7.sas" ) ,
		beginline = 5 ,
		zipped = T ,
		tl = TRUE ,
		tablename = "wgtw7" ,
		db = db
	)
}
	
# loop through each core wave..
for ( i in sipp.core.waves ){

	# figure out the exact ftp path of the .zip file
	SIPP.core <-
		paste0( "http://smpbff2.dsd.census.gov/pub/sipp/2008/l08puw" , i , ".zip" )

	# add the core wave to the database in a table w#
	read.SAScii.sqlite (
			SIPP.core ,
			fix.ct( SIPP.core.sas ) ,
			beginline = 5 ,
			zipped = T ,
			tl = TRUE ,
			tablename = paste0( "w" , i ) ,
			db = db
		)
}

# loop through each replicate weight wave..
for ( i in sipp.replicate.waves ){

	# figure out the exact ftp path of the .zip file
	SIPP.rw <-
		paste0( "http://smpbff2.dsd.census.gov/pub/sipp/2008/rw08w" , i , ".zip" )

	# add the wave-specific replicate weight to the database in a table rw#
	read.SAScii.sqlite (
			SIPP.rw ,
			fix.ct( SIPP.replicate.sas ) ,
			beginline = 5 ,
			zipped = T ,
			tl = TRUE ,
			tablename = paste0( "rw" , i ) ,
			db = db
		)
}

# loop through each topical module..
for ( i in sipp.topical.modules ){

	# figure out the exact ftp path of the .zip file
	SIPP.tm <-
		paste0( "http://smpbff2.dsd.census.gov/pub/sipp/2008/p08putm" , i , ".zip" )

	# figure out the exact ftp path of the .sas file
	SIPP.tm.sas <-
		paste0( "http://smpbff2.dsd.census.gov/pub/sipp/2008/p08putm" , i , ".sas" )
		
	# add each topical module to the database in a table tm#
	read.SAScii.sqlite (
			SIPP.tm ,
			fix.ct( SIPP.tm.sas ) ,
			beginline = 5 ,
			zipped = T ,
			tl = TRUE ,
			tablename = paste0( "tm" , i ) ,
			db = db
		)
}

# loop through each longitudinal replicate weight file..
for ( i in c( sipp.cy.longitudinal.replicate.weights , sipp.pnl.longitudinal.replicate.weights ) ){

	# figure out the exact ftp path of the .zip file
	SIPP.lrw <-
		paste0( "http://smpbff2.dsd.census.gov/pub/sipp/2008/repwgt120_" , i , ".zip" )
		
	# add each longitudinal replicate weight file to the database in a table cy1-4 or pnl1-4
	read.SAScii.sqlite (
			SIPP.lrw ,
			fix.repwgt( SIPP.longitudinal.replicate.sas ) ,
			beginline = 7 ,
			zipped = T ,
			tl = TRUE ,
			tablename = i ,
			db = db
		)
}
# the current working directory should now contain one database (.db) file


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
