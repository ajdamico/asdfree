# analyze survey data for free (http://asdfree.com) with the r language
# national vital statistics system
# natality, period-linked deaths, cohort-linked deaths, mortality, and fetal death files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( encoding = "windows-1252" )											# # only macintosh and *nix users need this line
# path.to.7z <- "7za"															# # only macintosh and *nix users need this line
# path.to.winrar <- normalizePath( "C:/Program Files/winrar/winrar.exe" )		# # only windows users need this line
# library(downloader)
# setwd( "C:/My Directory/NVSS/" )
# natality.sets.to.download <- 2015:1999
# periodlinked.sets.to.download <- 2013:2001
# cohortlinked.sets.to.download <- 2010:1995
# mortality.sets.to.download <- 2014:2000
# fetaldeath.sets.to.download <- 2014:2005
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Vital%20Statistics%20System/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com



###################################################################
# download all available national vital statistics system files   # 
# from the cdc's ftp, then import each file into a monet database #
###################################################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################################################
# prior to running this script windows users need (free) winrar software installed on their computer. go to http://www.win-rar.com/download.html    #
# this code has only been tested in a microsoft windows environment, tell us what modifications are needed for other operating systems! cool thanx  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# path.to.winrar <- normalizePath( "C:/Program Files/winrar/winrar.exe" )		# # only windows users need this line
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# the line above sets the location of the winrar program on your local computer. uncomment it by removing the `#`                                   #
#####################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################################################
# macintosh and *nix users need 7za installed:  http://superuser.com/questions/548349/how-can-i-install-7zip-so-i-can-run-it-from-terminal-on-os-x  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# path.to.7z <- "7za"														# # this is probably the correct line for macintosh and *nix
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# the line above sets the location of the 7-zip program on your local computer. uncomment it by removing the `#` and change the directory if ya did #
#####################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # # #
# warning: this takes a while #
# # # # # # # # # # # # # # # #

# even if you're only downloading a single year of data and you've got a fast internet connection,
# you'll be better off leaving this script to run overnight.  if you wanna download all available files and years,
# leave it running on friday afternoon (or even better: before you leave for a weeklong vacation).
# depending on your internet and processor speeds, the entire script should take between one and three days.

# remove the # in order to run this install.packages line only once
# install.packages( c( "MonetDBLite" , "SAScii" , "descr" , "downloader" , "digest" , "R.utils" ) )


library(MonetDBLite)
library(DBI)			# load the DBI package (implements the R-database coding)
library(SAScii) 		# load the SAScii package (imports ascii data with a SAS script)
library(downloader)		# downloads and then runs the source() function on scripts from github
library(R.utils)		# load the R.utils package (counts the number of lines in a file quickly)


# load the download_cached and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url( 
	"https://raw.githubusercontent.com/ajdamico/asdfree/master/Download%20Cache/download%20cache.R" , 
	prompt = FALSE , 
	echo = FALSE 
)


# load the read.SAScii.monetdb() function,
# which imports ASCII (fixed-width) data files directly into a monet database
# using only a SAS importation script
source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/MonetDB/read.SAScii.monetdb.R" , prompt = FALSE )


# load various functions used to clean up the raw nvss posted on the cdc's ftp site before importation into monetdb
source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Vital%20Statistics%20System/import%20functions.R" , prompt = FALSE )


# set your NVSS data directory
# after downloading and importing
# all monet database-backed complex survey designs will be stored here
# and the monet database will be stored in the MonetDB folder within
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NVSS/" )


# # # are you on a non-windows system? # # #
if ( .Platform$OS.type != 'windows' ) print( 'non-windows users: read this block' )
# the cdc's ftp site has a few SAS importation
# scripts in a non-standard format
# if so, before running this whole download program,
# you might need to run this line..
# options( encoding="windows-1252" )
# ..to turn on windows-style encoding.
# # # end of non-windows system edits.


# configure a monetdb database for the nvss #

# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )

# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite::MonetDBLite() , dbfolder )



# choose which nvss data sets to download: natality, period-linked, cohort-linked, mortality, fetal death
# if you have a big hard drive, hey why not download them all?

# natality data sets are available back to 1968,
# but i've only slogged through the layout files back to 1999
# uncomment this line to download all unlocked natality data sets
# uncomment this line by removing the `#` at the front
# natality.sets.to.download <- 2015:1999
# if you need more, you must write sas import scripts for the file layouts stored in
# ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/DVS/natality/Nat1998doc.pdf


# period-linked data sets are available back to 1995,
# but i've only slogged through the layout files back to 2001
# uncomment this line to download all unlocked period-linked data sets
# uncomment this line by removing the `#` at the front
# periodlinked.sets.to.download <- 2013:2001
# if you need more, you must write sas import scripts for the file layouts stored in
# ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/DVS/periodlinked/LinkPE00Guide.pdf


# cohort-linked data sets are available back to 1983,
# but i've only slogged through the layout files back to 1995
# uncomment this line to download all unlocked cohort-linked data sets
# uncomment this line by removing the `#` at the front
# cohortlinked.sets.to.download <- 2010:1995
# if you need more, you must write sas import scripts for the file layouts stored in
# ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/DVS/cohortlinked/LinkCO91Guide.pdf


# mortality data sets are available back to 1968,
# but i've only slogged through the layout files back to 2000
# uncomment this line to download all unlocked mortality data sets
# uncomment this line by removing the `#` at the front
# mortality.sets.to.download <- 2014:2000
# if you need more, you must write sas import scripts for the file layouts stored in
# http://www.cdc.gov/nchs/data/dvs/Mort99doc.pdf


# fetal death data sets are available back to 1982,
# but i've only slogged through the layout files back to 2005
# uncomment this line to download all unlocked mortality data sets
# uncomment this line by removing the `#` at the front
# fetaldeath.sets.to.download <- 2014:2005
# if you need more, you must write sas import scripts for the file layouts stored in
# ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/DVS/fetaldeath/2004FetalUserGuide.pdf



# # # # # # # # # # # # # #
# other download examples #
# # # # # # # # # # # # # #

# uncomment these lines to only download the 2011 natality file and no others
# natality.sets.to.download <- 2011
# periodlinked.sets.to.download <- NULL
# cohortlinked.sets.to.download <- NULL
# mortality.sets.to.download <- NULL
# fetaldeath.sets.to.download <- NULL

# uncomment these lines to only download the 2002, 2007 and 2011 natality file,
# the 2002, 2003, 2004, and 2005 cohort-linked file,
# and the 2006 fetal death file
# natality.sets.to.download <- c( 2011 , 2007 , 2002 )
# periodlinked.sets.to.download <- NULL
# cohortlinked.sets.to.download <- 2005:2002
# mortality.sets.to.download <- NULL
# fetaldeath.sets.to.download <- 2006


	
###############################################
# DATA LOADING COMPONENT - ONLY RUN THIS ONCE #
###############################################


##########################################
# this entire script is for data-loading #
# and only needs to be run once  #
# for whichever year(s) you need #
##################################

# this script's download files should be incorporated in download_cached's hash list
options( "download_cached.hashwarn" = TRUE )
# warn the user if the hash does not yet exist

# create a character string containing the cdc's vital statistics website
url.with.data <- "http://www.cdc.gov/nchs/data_access/vitalstatsonline.htm"

# pull that html code directly into R
z <- readLines( url.with.data )

# get rid of all tab characters
z <- gsub( "\t" , "" , z )

# keep only the lines in the html code containing an ftp site
files <- z[ grep( 'ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/' , z ) ]
# this, i'm assuming, points to every file available for download.  cool.


# loop through every year specified by the user
for ( year in natality.sets.to.download ){

	# for the current year, use a custom-built `extract.files` function
	# to determine the ftp location of the current natality file you're workin' on.
	natality <- extract.files( files[ grep( year , files ) ] , 'natality' )
	
	# download the natality file to the local working directory
	download.nchs( natality )

	# create a character vector containing all files in the current working directory
	all.files <- paste0( "./" , list.files( '.' , recursive = T ) )

	# remove pdfs from possible identifier files
	all.files <- all.files[ !grepl( "\\.pdf$" , tolower( all.files ) ) ]
	
	# extract the filepaths of the nationwide natality files
	natality.us <- all.files[ grep( 'natality/us/' , all.files ) ]
	
	# extract the filepaths of the natality files of the territories
	natality.ps <- all.files[ grep( 'natality/ps/' , all.files ) ]

	# throw out all non-digits to extract the year from the data file
	year.plus.data <- years <- gsub( "\\D" , "" , natality.us )

	# the pre-2006 files have an extra "/data" in the filepath of the sas import script
	year.plus.data[ as.numeric( year.plus.data ) %in% 1991:2005 ] <- 
		paste( year.plus.data[ as.numeric( year.plus.data ) %in% 1991:2005 ] , 'data' , sep = '/' )
	
	# use a custom-built function to re-arrange the sas importation script
	# so all column positions are sorted based on their @ sign
	sas_ri <- 
		order.at.signs( 
			# build the full http:// location of the current sas importation script
			paste0( 
				"http://www.nber.org/natality/" , 
				year.plus.data ,
				"/natl" ,
				years ,
				".sas"
			)
		)
	
	# the 2004 data file has a bunch of blanks at the end.
	# the sas importation script does not mention these in the slightest.
	if ( year == 2004 ) sas_ri <- extend.frace( sas_ri )
	# add 'em in.
	
	# prepare the downloaded data-file and the sas importation script
	# for a read.SAScii.monetdb() call.  then - hello operator - make the call!
	import.nchs( 
		natality.us , 
		sas.scripts = sas_ri ,
		db = db ,
		force.length = ifelse( year == 2004 , 1500 , FALSE )
	)
	
	
	# use a custom-built function to re-arrange the sas importation script
	# so all column positions are sorted based on their @ sign
	sas_ri <-
		order.at.signs(
			# build the full http:// location of the current sas importation script
			paste0( 
				"http://www.nber.org/natality/" , 
				year.plus.data ,
				"/natlterr" ,
				years ,
				".sas"
			)
		)

	# the 2004 data file has a bunch of blanks at the end.
	# the sas importation script does not mention these in the slightest.
	if ( year == 2004 ) sas_ri <- extend.frace( sas_ri )
	# add 'em in.
		
	# prepare the downloaded data-file and the sas importation script
	# for a read.SAScii.monetdb() call.  then - hello operator - make the call!
	import.nchs( 
		natality.ps , 
		sas.scripts = sas_ri ,
		db
	)

	# delete all files in the "/natality/us" directory (the fifty states plus DC)
	file.remove( paste0( "./natality/us/" , list.files( 'natality/us/' , recursive = T ) ) )
	
	# delete all files in the "/natality/ps" directory (the territories)
	file.remove( paste0( "./natality/ps/" , list.files( 'natality/ps/' , recursive = T ) ) )

}


# if any period-linked data sets are queued up to be downloaded..
if ( !is.null( periodlinked.sets.to.download ) ){

	# point to the period-linked sas file stored on github
	sas_ri <- "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Vital%20Statistics%20System/nchs%20period%20linked.sas"

	# create two temporary files
	pl.tf <- tempfile() ; den.tf <- tempfile()

	# download the sas import script directly to the first temporary file
	download( sas_ri , pl.tf )
	# that's the file (sas layout) used for the numerator and unlinked files.
	
	# also read it into working memory
	pl.txt <- readLines( pl.tf )

	# add a semicolon after the FLGND field in order to indicate
	# that's the end of the numerator
	pl.den <- gsub( "FLGND  868" , "FLGND  868;" , pl.txt )

	# export that revised sas script to the second temporary file
	writeLines( pl.den , den.tf )
	
	# point to the period-linked 2003 sas file stored on github
	sas_ri <- "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Vital%20Statistics%20System/nchs%20period%20linked%202003.sas"

	# create two temporary files
	pl03.tf <- tempfile() ; den03.tf <- tempfile()

	# download the sas import script directly to the first temporary file
	download( sas_ri , pl03.tf )
	# that's the file (sas layout) used for the numerator and unlinked files.
	
	# also read it into working memory
	pl03.txt <- readLines( pl03.tf )

	# add a semicolon after the FLGND field in order to indicate
	# that's the end of the numerator
	pl03.den <- gsub( "FLGND 751" , "FLGND 751;" , pl03.txt )

	# export that revised sas script to the second temporary file
	writeLines( pl03.den , den03.tf )
}


# loop through every year specified by the user
for ( year in periodlinked.sets.to.download ){

	# for the current year, use a custom-built `extract.files` function
	# to determine the ftp location of the current period-linked file you're workin' on.
	period.linked <- extract.files( files[ grep( year , files ) ] , 'periodlinked' )
	
	# download the period-linked file to the local working directory
	download.nchs( period.linked )

	# create a character vector containing all files in the current working directory
	all.files <- paste0( "./" , list.files( '.' , recursive = T ) )
	
	# extract the filepaths of the nationwide period-linked unlinked files
	periodlinked.us.unl <- all.files[ grep( 'periodlinked/us/unl' , all.files ) ]
	
	# extract the filepaths of the period-linked unlinked files for territories
	periodlinked.ps.unl <- all.files[ grep( 'periodlinked/ps/unl' , all.files ) ]

	# extract the filepaths of the nationwide period-linked numerator files
	periodlinked.us.num <- all.files[ grep( 'periodlinked/us/num' , all.files ) ]
	
	# extract the filepaths of the period-linked numerator files for territories
	periodlinked.ps.num <- all.files[ grep( 'periodlinked/ps/num' , all.files ) ]

	# extract the filepaths of the nationwide period-linked denominator files
	periodlinked.us.den <- all.files[ grep( 'periodlinked/us/den' , all.files ) ]
	
	# extract the filepaths of the period-linked denominator files for territories
	periodlinked.ps.den <- all.files[ grep( 'periodlinked/ps/den' , all.files ) ]

	
	# if the year is 2004 and beyond..
	if ( year > 2003 ){
	
		# use the period-linked sas import script
		sas_ri <- pl.tf
	
	# ..otherwise, if the year is 2003..
	} else if ( year == 2003 ) {
		
		# use the 2003 period-linked sas import script
		sas_ri <- pl03.tf
		
	# otherwise..
	} else {
		
			# if the year is pre-1999, use a capital letter in the filepath's crispity-crunchity center
			file.middle <- ifelse( year < 1999 , "/data/Num" , "/data/num" )
		
			# build the full sas filepath to the period-linked numerator
			sas_ri <- 
				paste0( 
					"http://www.nber.org/perinatal/" , 
					year ,
					file.middle ,
					substr( year , 3 , 4 ) ,
					".sas"
				)
	}	
	

	# prepare the downloaded data-file and the sas importation script
	# for a read.SAScii.monetdb() call.  then - hello operator - make the call!
	import.nchs( 
		periodlinked.us.num , 
		sas.scripts = sas_ri ,
		db = db
	)
	
	# prepare the downloaded data-file and the sas importation script
	# for a read.SAScii.monetdb() call.  then - hello operator - make the call!
	import.nchs( 
		periodlinked.ps.num , 
		sas.scripts = sas_ri ,
		db
	)

	
	# if the year is 2004 and beyond..
	if ( year > 2003 ){
	
		# use the period-linked sas import script
		sas_ri <- pl.tf
		
	# ..otherwise, if the year is 2003..
	} else if ( year == 2003 ) {
		
		# use the 2003 period-linked sas import script
		sas_ri <- pl03.tf
		
	# otherwise..
	} else {
	
		# build the full sas filepath to the period-linked unlinked
		sas_ri <- 
			paste0( 
				"http://www.nber.org/perinatal/" , 
				year ,
				"/data/unl" ,
				substr( year , 3 , 4 ) ,
				".sas"
			)
			
	}

	# prepare the downloaded data-file and the sas importation script
	# for a read.SAScii.monetdb() call.  then - hello operator - make the call!
	import.nchs( 
		periodlinked.us.unl , 
		sas.scripts = sas_ri ,
		db = db
	)

	# prepare the downloaded data-file and the sas importation script
	# for a read.SAScii.monetdb() call.  then - hello operator - make the call!
	import.nchs( 
		periodlinked.ps.unl , 
		sas.scripts = sas_ri ,
		db
	)
	
	# if the year is 2004 and beyond..	
	if ( year > 2003 ){
		
		# use the period-linked sas import script
		sas_ri <- den.tf
	
	# ..otherwise, if the year is 2003..
	} else if ( year == 2003 ) {
		
		# use the 2003 period-linked sas import script
		sas_ri <- den03.tf
		
	# otherwise..
	} else {
	
		# build the full sas filepath to the period-linked unlinked
		sas_ri <-
			paste0( 
				"http://www.nber.org/perinatal/" , 
				year ,
				"/data/den" ,
				substr( year , 3 , 4 ) ,
				".sas"
			)
			
	}

	# prepare the downloaded data-file and the sas importation script
	# for a read.SAScii.monetdb() call.  then - hello operator - make the call!
	import.nchs( 
		periodlinked.us.den , 
		sas.scripts = sas_ri ,
		db = db
	)

	# prepare the downloaded data-file and the sas importation script
	# for a read.SAScii.monetdb() call.  then - hello operator - make the call!
	import.nchs( 
		periodlinked.ps.den , 
		sas.scripts = sas_ri ,
		db
	)

	# delete all files in the "/periodlinked/us" directory (the fifty states plus DC)
	file.remove( paste0( "./periodlinked/us/" , list.files( 'periodlinked/us/' , recursive = T ) ) )
	
	# delete all files in the "/periodlinked/ps" directory (the fifty states plus DC)
	file.remove( paste0( "./periodlinked/ps/" , list.files( 'periodlinked/ps/' , recursive = T ) ) )

}


# loop through every year specified by the user
for ( year in cohortlinked.sets.to.download ){

	# for the current year, use a custom-built `extract.files` function
	# to determine the ftp location of the current cohort-linked file you're workin' on.
	cohort.linked <- extract.files( files[ grep( year , files ) ]  , 'cohortlinked' )
	
	# download the cohort-linked file to the local working directory
	download.nchs( cohort.linked )

	# create a character vector containing all files in the current working directory
	all.files <- paste0( "./" , list.files( '.' , recursive = T ) )

	# remove pdfs from possible identifier files
	all.files <- all.files[ !grepl( "\\.pdf$" , tolower( all.files ) ) ]
	
	# extract the filepaths of the nationwide cohort-linked unlinked files
	cohortlinked.us.unl <- all.files[ grep( 'cohortlinked/us/unl' , all.files ) ]

	# extract the filepaths of the territories cohort-linked unlinked files
	cohortlinked.ps.unl <- all.files[ grep( 'cohortlinked/ps/unl' , all.files ) ]

	# extract the filepaths of the nationwide cohort-linked numerator files
	cohortlinked.us.num <- all.files[ grep( 'cohortlinked/us/num' , all.files ) ]

	# extract the filepaths of the territories cohort-linked numerator files
	cohortlinked.ps.num <- all.files[ grep( 'cohortlinked/ps/num' , all.files ) ]

	# extract the filepaths of the nationwide cohort-linked denominator files
	cohortlinked.us.den <- all.files[ grep( 'cohortlinked/us/den' , all.files ) ]

	# extract the filepaths of the territories cohort-linked denominator files
	cohortlinked.ps.den <- all.files[ grep( 'cohortlinked/ps/den' , all.files ) ]

	# throw out all non-digits to extract the year from the data file
	years <- gsub( "\\D" , "" , cohortlinked.us.num )

	# for years after 2004, simply use the 2004 sas import scripts
	years[ years > 2004 ] <- 2004

	# if the year is 2004, don't add "/data" to the folder filepath.
	if ( years == 2004 ) y_d <- years else y_d <- paste0( years , "/data" )

	# build the character string containing the filepath
	# of the sas file of the cohort-linked numerator file
	num_ri <-
		paste0( 
			"http://www.nber.org/lbid/" , 
			y_d ,
			"/linkco" ,
			years ,
			"us_num.sas"
		)
	
	# build the character string containing the filepath
	# of the sas file of the cohort-linked denominator file
	den_ri <-
		paste0( 
			"http://www.nber.org/lbid/" , 
			y_d ,
			"/linkco" ,
			years ,
			"us_den.sas"
		)

	# build the character string containing the filepath
	# of the sas file of the cohort-linked unlinked file
	unl_ri <-
		paste0( 
			"http://www.nber.org/lbid/" , 
			y_d ,
			"/linkco" ,
			years ,
			"us_unl.sas"
		)

	# prepare the downloaded data-file and the sas importation script
	# for a read.SAScii.monetdb() call.  then - hello operator - make the call!
	import.nchs( 
		cohortlinked.us.num , 
		sas.scripts = num_ri ,
		db = db
	)

	# prepare the downloaded data-file and the sas importation script
	# for a read.SAScii.monetdb() call.  then - hello operator - make the call!
	import.nchs( 
		cohortlinked.us.den , 
		sas.scripts = den_ri ,
		db = db
	)

	# prepare the downloaded data-file and the sas importation script
	# for a read.SAScii.monetdb() call.  then - hello operator - make the call!
	import.nchs( 
		cohortlinked.us.unl , 
		sas.scripts = unl_ri ,
		db = db
	)

	# prepare the downloaded data-file and the sas importation script
	# for a read.SAScii.monetdb() call.  then - hello operator - make the call!
	import.nchs( 
		cohortlinked.ps.num , 
		sas.scripts = num_ri ,
		db
	)

	# prepare the downloaded data-file and the sas importation script
	# for a read.SAScii.monetdb() call.  then - hello operator - make the call!
	import.nchs( 
		cohortlinked.ps.den , 
		sas.scripts = den_ri ,
		db
	)

	# prepare the downloaded data-file and the sas importation script
	# for a read.SAScii.monetdb() call.  then - hello operator - make the call!
	import.nchs( 
		cohortlinked.ps.unl , 
		sas.scripts = unl_ri ,
		db ,
		azr = ( year == 2005 )
	)
	
	# delete all files in the "/cohortlinked/us" directory (the fifty states plus DC)
	file.remove( paste0( "./cohortlinked/us/" , list.files( 'cohortlinked/us/' , recursive = T ) ) )
	
	# delete all files in the "/cohortlinked/ps" directory (the fifty states plus DC)
	file.remove( paste0( "./cohortlinked/ps/" , list.files( 'cohortlinked/ps/' , recursive = T ) ) )
	
}


# loop through every year specified by the user
for ( year in mortality.sets.to.download ){

	# for the current year, use a custom-built `extract.files` function
	# to determine the ftp location of the current mortality file you're workin' on.
	mortality <- extract.files( files[ grep( year , files ) ] , 'mortality' )
	
	# download the mortality file to the local working directory
	download.nchs( mortality )

	# create a character vector containing all files in the current working directory
	all.files <- paste0( "./" , list.files( '.' , recursive = T ) )

	# remove pdfs from possible identifier files
	all.files <- all.files[ !grepl( "\\.pdf$" , tolower( all.files ) ) ]
	
	# extract the filepaths of the nationwide mortality files
	mortality.us <- all.files[ grep( 'mortality/us/' , all.files ) ]

	# extract the filepaths of the territories mortality files
	mortality.ps <- all.files[ grep( 'mortality/ps/' , all.files ) ]

	# throw out all non-digits to extract the year from the data file
	year.plus.data <- years <- gsub( "\\D" , "" , mortality.us )

	# the pre-2006 files have an extra "/data" in the filepath of the sas import script
	year.plus.data[ as.numeric( year.plus.data ) <= 2005 ] <- 
		paste( year.plus.data[ as.numeric( year.plus.data ) <= 2005 ] , 'data' , sep = '/' )
	

	# build the character string containing the filepath
	# of the sas file of the mortality file
	sas_ri <- paste0( "http://www.nber.org/mortality/" , year.plus.data , "/mort" , years , ".sas" )

	# throw out all non-digits to extract the year from the mortality territory file
	cap.at.1995 <- as.numeric( gsub( "\\D" , "" , mortality.ps ) )

	# if the year is after named filepath..
	if ( year > cap.at.1995 ){
	
		# use the sas importation script as it is.
		terr_ri <- sas_ri
	
	# ..otherwise..
	} else {
	
		# use the `terr` filepath
		terr_ri <-
			paste0( 
				"http://www.nber.org/mortality/" , 
				cap.at.1995 ,
				"/terr" ,
				substr( cap.at.1995 , 3 , 4 ) ,
				".sas"
			)
		
	}
		
	# prepare the downloaded data-file and the sas importation script
	# for a read.SAScii.monetdb() call.  then - hello operator - make the call!
	import.nchs( 
		mortality.us , 
		sas.scripts = order.at.signs( sas_ri , add.blank = TRUE ) ,
		db = db
	)

	# prepare the downloaded data-file and the sas importation script
	# for a read.SAScii.monetdb() call.  then - hello operator - make the call!
	import.nchs( 
		mortality.ps , 
		sas.scripts = order.at.signs( sas_ri , add.blank = TRUE ) ,
		db
	)

	# delete all files in the "/mortality/us" directory (the fifty states plus DC)
	file.remove( paste0( "./mortality/us/" , list.files( 'mortality/us/' , recursive = T ) ) )
	
	# delete all files in the "/mortality/ps" directory (the fifty states plus DC)
	file.remove( paste0( "./mortality/ps/" , list.files( 'mortality/ps/' , recursive = T ) ) )

}


# loop through every year specified by the user
for ( year in fetaldeath.sets.to.download ){

	# for 2007 and beyond, use the 2007 sas script.
	# otherwise use the 2006 sas script
	sas_ri <-
		ifelse(
			year >= 2007 ,
			"https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Vital%20Statistics%20System/nchs%20fetal%20death%202007.sas" ,
			"https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Vital%20Statistics%20System/nchs%20fetal%20death%202006.sas"
		)

	# create a temporary file
	fd.tf <- tempfile()

	# download the sas importation script to the local disk
	download( sas_ri , fd.tf )

	# build the full filepath of the fetal death zipped file
	fn <- 
		paste0( 
			"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/DVS/fetaldeathus/Fetal" , 
			year , 
			"US.zip" 
		)
		
	# read the fetal death nationwide zipped file directly into RAM with the sas importation script
	us <-
		read.SAScii(
			fn ,
			fd.tf ,
			zipped = TRUE
		)
	
	# convert all column names to lowercase
	names( us ) <- tolower( names( us ) )
	
	
	# build the full filepath of the fetal death zipped file
	fn <- 
		paste0( 
			"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/DVS/fetaldeathter/Fetal" , 
			year , 
			"PS.zip" 
		)
		
	# read the fetal death territory zipped file directly into RAM with the sas importation script
	ps <-
		read.SAScii(
			fn ,
			fd.tf ,
			zipped = TRUE
		)

	# convert all column names to lowercase
	names( ps ) <- tolower( names( ps ) )

	# save both data.frame objects to an R data file
	save( us , ps , file = paste0( "./fetal death " , year , ".rda" ) )

	# remove both nationwide and territory data.frame object
	rm( us , ps )
	
	# clear up RAM
	gc()
}


# the current working directory should now contain a monetdb/ folder
# as well as one R data file (.rda) for every fetal death file
# the monetdb/ folder contains a database with all
# natality, cohort-linked, period-linked, and mortality tables, ready for action.


# once complete, this script does not need to be run again.
# instead, use one of the national vital statistics system analysis scripts
# which utilize these newly-created survey objects


# disconnect from the current monet database
dbDisconnect( db , shutdown = TRUE )

