# analyze us government survey data with the r language
# survey of income and program participation
# 1996 panel
# 12 core waves, 12 wave-specific replicate weights, 12 topical modules, 
# 1 panel year replicate weights, 4 calendar year replicate weights, 1 longitudinal weights

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
# Download and Create a Database with the 1996 Panel of the Survey of Income and Program Participation files with R #
#####################################################################################################################


# set your working directory.
# all SIPP data files will be stored here
# after downloading and importing.
# use forward slashes instead of back slashes

setwd( "C:/My Directory/SIPP/" )


# remove the # in order to run this install.packages line only once
# install.packages( c( "RSQLite" , "SAScii" , "descr" ) )


SIPP.dbname <- "SIPP96.db"											# choose the name of the database (.db) file on the local disk

sipp.core.waves <- 1:12												# either choose which core survey waves to download, or set to NULL
sipp.replicate.waves <- 1:12										# either choose which replicate weight waves to download, or set to NULL
sipp.topical.modules <- 1:12										# either choose which topical modules to download, or set to NULL
sipp.longitudinal.weights <- TRUE									# set to FALSE to prevent download
sipp.cy.longitudinal.replicate.weights <- paste0( 'cy' , 1:4 )		# 1-3 reads in 1996-1999
sipp.pnl.longitudinal.replicate.weights <- 'pnl'					# set to NULL to prevent download

############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #


require(RSQLite) 	# load RSQLite package (creates database files in R)
require(SAScii) 	# load the SAScii package (imports ascii data with a SAS script)


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
# (the SAScii function cannot currently handle this SAS configuration on its own
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

# load the read.SAScii.sqlite function (a variant of read.SAScii that creates a database directly)
source_https( "https://raw.github.com/ajdamico/usgsd/master/SQLite/read.SAScii.sqlite.R" )

# set the locations of the data files on the ftp site
SIPP.core.sas <-
	"http://smpbff2.dsd.census.gov/pub/sipp/1996/sip96lgt.sas"
	
SIPP.replicate.sas <-
	"http://smpbff2.dsd.census.gov/pub/sipp/1996/rw96wx.sas"
	
SIPP.longitudinal.replicate.sas <-
	"http://smpbff2.dsd.census.gov/pub/sipp/1996/lrw96_xx.sas"


# if the longitudinal weights flag has been set to TRUE above..
if ( sipp.longitudinal.weights ){

	# the census SIPP FTP site does not have a SAS input script,
	# so create one using the dictionary at
	# http://smpbff2.dsd.census.gov/pub/sipp/1996/ctl_ferd.asc

	# write an example SAS import script using the dash method
	sas.import.with.at.signs <-
		"INPUT
			@1 	   LGTKEY      8.
			@9      SPANEL       4.
			@13      SSUID      12.
			@25      EPPPNUM      4.
			@29      LGTPNLWT   10.
			@39      LGTPNWT1   10.
			@49      LGTPNWT2   10.
			@59      LGTPNWT3   10.
			@69      LGTPNWT4   10.
		;"
		
	# create a temporary file
	sas.import.with.at.signs.tf <- tempfile()
	# write the sas code above to that temporary file
	writeLines ( sas.import.with.at.signs , con = sas.import.with.at.signs.tf )

	# end of fake SAS input script creation #
	
	# add the longitudinal weights to the database in a table 'w12'
	read.SAScii.sqlite(
		"http://smpbff2.dsd.census.gov/pub/sipp/1996/ctl_fer.zip" ,
		fix.ct( sas.import.with.at.signs.tf ) ,
		# note no beginline = parameter in this read.SAScii.sqlite() call
		zipped = T ,
		tl = TRUE ,
		tablename = "wgtw12" ,
		db = db
	)
}
	
# loop through each core wave..
for ( i in sipp.core.waves ){

	# figure out the exact ftp path of the .zip file
	SIPP.core <-
		paste0( "http://smpbff2.dsd.census.gov/pub/sipp/1996/l96puw" , i , ".zip" )

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
		paste0( "http://smpbff2.dsd.census.gov/pub/sipp/1996/rw96w" , i , ".zip" )

	# add the wave-specific replicate weight to the database in a table rw#
	read.SAScii.sqlite (
			SIPP.rw ,
			fix.ct( fix.repwgt( SIPP.replicate.sas ) ) ,
			beginline = 7 ,
			zipped = T ,
			tl = TRUE ,
			tablename = paste0( "rw" , i ) ,
			db = db
		)
}

# loop through each topical module..
for ( i in sipp.topical.modules ){

	# figure out the exact ftp path of the .zip file
	if ( i == 10 ) {
		SIPP.tm <- "http://smpbff2.dsd.census.gov/pub/sipp/1996/p96putm10.zip" 
	} else {
		SIPP.tm <-
			paste0( "http://smpbff2.dsd.census.gov/pub/sipp/1996/tm96puw" , i , ".zip" )
	}
		
	# figure out the exact ftp path of the .sas file
	SIPP.tm.sas <-
		paste0( "http://smpbff2.dsd.census.gov/pub/sipp/1996/p96putm" , i , ".sas" )
		
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
		paste0( "http://smpbff2.dsd.census.gov/pub/sipp/1996/lrw96" , i , ".zip" )
		
	# add each longitudinal replicate weight file to the database in a table cy1-4 or pnl
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
winDialog( 'ok' , paste0( "all done.  you should set the file " , file.path( getwd() , SIPP.dbname ) , " read-only so you don't accidentally alter these tables." ) )


# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
