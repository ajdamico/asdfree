# analyze survey data for free (http://asdfree.com) with the r language
# united states decennial census
# public use microdata sample
# 1990 , 2000, 2010

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( encoding = "windows-1252" )		# # only macintosh and *nix users need this line
# library(downloader)
# setwd( "C:/My Directory/PUMS/" )
# one.percent.files.to.download <- c( 1990 , 2000 )
# five.percent.files.to.download <- c( 1990 , 2000 )
# ten.percent.files.to.download <- 2010
# exclude.puerto.rico <- TRUE
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/United%20States%20Decennial%20Census%20Public%20Use%20Microdata%20Sample/download%20and%20import.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


####################################################################################################
# analyze the 1990, 2000, 2010 United States Decennial Census - Public Use Microdata Sample with R #
####################################################################################################


# set your working directory.
# the PUMS 1990 , 2000 , 2010 data files will be stored here
# after downloading and importing them.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PUMS/" )
# ..in order to set your current working directory


# # # are you on a non-windows system? # # #
if ( .Platform$OS.type != 'windows' ) print( 'non-windows users: read this block' )
# the census bureau's ftp site has a few SAS importation
# scripts in a non-standard format
# if so, before running this whole download program,
# you might need to run this line..
# options( encoding="windows-1252" )
# ..to turn on windows-style encoding.
# # # end of non-windows system edits.


# define which years to download #

# uncomment these three lines to download all available data sets
# one.percent.files.to.download <- c( 1990 , 2000 )
# five.percent.files.to.download <- c( 1990 , 2000 )
# ten.percent.files.to.download <- 2010
# uncomment a line by removing the `#` at the front

# uncomment these three lines to just download 2010, for example
# one.percent.files.to.download <- NULL
# five.percent.files.to.download <- NULL
# ten.percent.files.to.download <- 2010
# uncomment a line by removing the `#` at the front

# uncomment this line if you do not want puerto rico included in the downloaded microdata
# exclude.puerto.rico <- TRUE
# note that you can just subset tables later, so if you're unsure, i say leave it in, i say!


# remove the # in order to run this install.packages line only once
# install.packages( c( "MonetDBLite" , "survey" , "SAScii" , "descr" , "downloader" , "digest" , "readxl" , "stringr" , "R.utils" ) )



############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #


library(SAScii) 		# load the SAScii package (imports ascii data with a SAS script)
library(R.utils)		# load the R.utils package (counts the number of lines in a file quickly)
library(stringr)		# load stringr package (manipulates character strings easily)
library(descr) 			# load the descr package (converts fixed-width files to delimited files)
library(survey) 		# load survey package (analyzes complex design surveys)
library(MonetDBLite)
library(DBI)			# load the DBI package (implements the R-database coding)
library(downloader)		# downloads and then runs the source() function on scripts from github
library(readxl)			# imports excel .xlsx files cleanly

# load the `get.tsv` and `pums.import.and.merge` functions from my github account.
source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/United%20States%20Decennial%20Census%20Public%20Use%20Microdata%20Sample/pums%20functions.R" , prompt = FALSE )
# these are two sets of commands that will be used repeatedly in the importation code below.


# load the `monet.read.tsv` function from my github account.
source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/MonetDB/monet.read.tsv.R" , prompt = FALSE )
# this is a modification of the SAScii package's read.SAScii function
# that imports tab-separated value files directly into MonetDB

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


# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )

# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite::MonetDBLite() , dbfolder )


# # # # # # # # # # # # # # #
# file download and parsing #
# # # # # # # # # # # # # # #


# the state.name object comes pre-loaded in every R session
# but it needs a DC line, and all spaces should be underscores
states.plus.dc <-
	gsub(
		" " ,
		"_" ,
		c( "District of Columbia" , state.name )
	)

# same deal with state abbreviations..  and add in fips code with left-side zeroes for the one-digit ones.
st <-
	data.frame(

		state.abb = c( "DC" , state.abb ) ,
	
		state.name = states.plus.dc ,
		
		state.fips = 
			str_pad( 
				c( 11 , 1 , 2 , 4:6 , 8:10 , 12:13 , 15:42 , 44:51 , 53:56 ) , 
				width = 2 , 
				pad = "0"
			)
	)

# if the `exclude.puerto.rico` object does not exist..
if ( !exists( 'exclude.puerto.rico' ) ){ 
	st <- rbind( st , data.frame( state.abb = "PR" , state.name = "Puerto_Rico" , state.fips = "72" ) )
} else {
	# or if it does exist and it's false..
	if ( !exclude.puerto.rico ) st <- rbind( st , data.frame( state.abb = "PR" , state.name = "Puerto_Rico" , state.fips = "72" ) )
}
# then you want puerto rico in the state table so it gets downloaded with the other states + DC
	

	
# # # # # # # # # #
# structure files #
# # # # # # # # # #


# # # # # # 1990 # # # # # #

# if 1990 was requested in either the 1% or 5% files..
if ( 1990 %in% c( one.percent.files.to.download , five.percent.files.to.download ) ){

	# create a temporary file on the local disk
	tf <- tempfile()
	of <- tempfile()
	
	# download the pums sas script provided by the census bureau
	download_cached( "http://www2.census.gov/census_1990/1990_PUMS_A/TOOLS/sas/PUMS.SAS" , tf )
	
	# read the script into working memory
	sas.90 <- readLines( tf )

	# add a leading column (parse.SAScii cannot handle a sas importation script that doesn't start at the first position)
	sas.90 <- gsub( "@2 SerialNo $ 7." , "@1 rectype $ 1 @2 SerialNo $ 7." , sas.90 , fixed = TRUE )

	# write the script back to memory
	writeLines( sas.90 , of )

	# read in the household structure
	hh.90.structure <- parse.SAScii( of , beginline = 7 )
	
	# read in the person structure
	person.90.structure <- parse.SAScii( of , beginline = 125 )
	
	# convert both variables to lowercase
	hh.90.structure$variable <- tolower( hh.90.structure$varname )
	person.90.structure$variable <- tolower( person.90.structure$varname )

	# find the starting and ending positions of all rows, in both tables (needed for monet.read.tsv later)
	hh.90.structure$beg <- cumsum( abs( hh.90.structure$width ) ) - abs( hh.90.structure$width ) + 1
	hh.90.structure$end <- cumsum( abs( hh.90.structure$width ) )

	person.90.structure$beg <- cumsum( abs( person.90.structure$width ) ) - abs( person.90.structure$width ) + 1
	person.90.structure$end <- cumsum( abs( person.90.structure$width ) )

	# rename all empty columns `blank_#` in both tables
	if ( any( blanks <- is.na( hh.90.structure$variable ) ) ){
		hh.90.structure[ is.na( hh.90.structure$variable ) , 'variable' ] <- paste0( "blank_" , 1:sum( blanks ) )
	}

	if ( any( blanks <- is.na( person.90.structure$variable ) ) ){
		person.90.structure[ is.na( person.90.structure$variable ) , 'variable' ] <- paste0( "blank_" , 1:sum( blanks ) )
	}

	# `sample` is an illegal column name in monetdb, so change it in both tables
	hh.90.structure[ hh.90.structure$variable == 'sample' , 'variable' ] <- 'sample_'
	person.90.structure[ person.90.structure$variable == 'sample' , 'variable' ] <- 'sample_'

}


# # # # # # 2000 # # # # # #

# if 2000 was requested in either the 1% or 5% files..
if ( 2000 %in% c( one.percent.files.to.download , five.percent.files.to.download ) ){

	# create a temporary file on the local disk
	pums.layout <- paste0( tempfile() , '.xls' )

	# download the layout excel file
	download_cached( "http://www2.census.gov/census_2000/datasets/PUMS/FivePercent/5%25_PUMS_record_layout.xls" ,	pums.layout , mode = 'wb' )

	# initiate a quick layout read-in function #
	code.str <-
		function( fn , sheet ){

			# read the sheet (specified as a function input) to an object `stru
			stru <- data.frame( read_excel( fn , sheet = sheet , skip = 1 ) )
			
			# make all column names of the `stru` data.frame lowercase
			names( stru ) <- tolower( names( stru ) )
			
			# remove leading and trailing whitespace, and convert everything to lowercase
			# in the `variable` column of the `stru` table
			stru$variable <- str_trim( tolower( stru$variable ) )
			
			# keep only four columns, and only unique records from the `stru` table
			stru <- unique( stru[ , c( 'beg' , 'end' , 'a.n' , 'variable' ) ] )
			
			# throw out records missing a beginning position
			stru <- stru[ !is.na( stru$beg ) , ]
			
			# calculate the width of each field
			stru <- transform( stru , width = end - beg + 1 )

			# remove overlapping fields
			stru <- 
				stru[ 
					!( stru$variable %in% 
						c( 'ancfrst1' , 'ancscnd1' , 'lang1' , 'pob1' , 'migst1' , 'powst1' , 'occcen1' , 'occsoc1' , 'filler' ) ) , ]
			
			# remove fields that are invalid in monetdb
			stru[ stru$variable == "sample" , 'variable' ] <- 'sample_'
	
			hardcoded.numeric.columns <-
				c( "serialno" , "hweight" , "persons" , "elec" , "gas" , "water" , "oil" , "rent" , "mrt1amt" , "mrt2amt" , "taxamt" , "insamt" , "condfee" , "mhcost" , "smoc" , "smocapi" , "grent" , "grapi" , "hinc" , "finc" , "pweight" , "age" , "ancfrst5" , "ancscnd5" , "yr2us" , "trvtime" , "weeks" , "hours" , "incws" , "incse" , "incint" , "incss" , "incssi" , "incpa" , "incret" , "incoth" , "inctot" , "earns" , "poverty" )
	
			# add a logical `char` field to both of these data.frames
			stru$char <- ( stru$a.n %in% 'A' & !( stru$variable %in% hardcoded.numeric.columns ) )
						
			# since this is the last line of the function `code.str`
			# whatever this object `stru` is at the end of the function
			# will be _returned_ by the function
			stru
		}

	# read in the household file structure from excel sheet 1
	hh.00.structure <- code.str( pums.layout , 1 )

	# read in the person file structure from excel sheet 2
	person.00.structure <- code.str( pums.layout , 2 )
	
}


# # # # # # 2010 # # # # # #

# if 2010 was requested in the 10% files..
if ( 2010 %in% ten.percent.files.to.download ){

	# create a temporary file on the local disk
	pums.layout <- paste0( tempfile() , ".xlsx" )

	# download the layout excel file
	download_cached( "http://www2.census.gov/census_2010/12-Stateside_PUMS/2010%20PUMS%20Record%20Layout.xlsx" ,	pums.layout , mode = 'wb' )

	# initiate a quick layout read-in function #
	code.str <-
		function( fn , sheet ){

			# read the sheet (specified as a function input) to an object `stru
			stru <- data.frame( read_excel( fn , sheet = sheet , skip = 1 ) )
			
			# make all column names of the `stru` data.frame lowercase
			names( stru ) <- tolower( names( stru ) )
			
			# remove leading and trailing whitespace, and convert everything to lowercase
			# in the `variable` column of the `stru` table
			stru$variable <- str_trim( tolower( stru$variable ) )
			
			# keep only four columns, and only unique records from the `stru` table
			stru <- unique( stru[ , c( 'beg' , 'end' , 'a.n' , 'variable' ) ] )
			
			# throw out records missing a beginning position
			stru <- stru[ !is.na( stru$beg ) , ]
			
			# calculate the width of each field
			stru <- transform( stru , width = end - beg + 1 )

			# remove racedet duplicate
			stru <- stru[ !is.na( stru$beg ) , ]
			
			# remove fields that are invalid in monetdb
			stru[ stru$variable == "sample" , 'variable' ] <- 'sample_'
	
			hardcoded.numeric.columns <-
				c( "serialno" , "hweight" , "persons" , "elec" , "gas" , "water" , "oil" , "rent" , "mrt1amt" , "mrt2amt" , "taxamt" , "insamt" , "condfee" , "mhcost" , "smoc" , "smocapi" , "grent" , "grapi" , "hinc" , "finc" , "pweight" , "age" , "ancfrst5" , "ancscnd5" , "yr2us" , "trvtime" , "weeks" , "hours" , "incws" , "incse" , "incint" , "incss" , "incssi" , "incpa" , "incret" , "incoth" , "inctot" , "earns" , "poverty" )
	
			# add a logical `char` field to both of these data.frames
			stru$char <- ( stru$a.n %in% 'A' & !( stru$variable %in% hardcoded.numeric.columns ) )
						
			# since this is the last line of the function `code.str`
			# whatever this object `stru` is at the end of the function
			# will be _returned_ by the function
			stru
		}

	# read in the household file structure from excel sheet 1
	hh.10.structure <- code.str( pums.layout , 1 )

	# read in the person file structure from excel sheet 2
	person.10.structure <- code.str( pums.layout , 2 )
	
}


# # # # # # # #
# importation #
# # # # # # # #
		
# if the user specified the download of this data set..
if ( 1990 %in% one.percent.files.to.download ){

	# construct a character vector containing one `zip` file's url for each state
	# the character vector contains the full http:// filepath to all of the census microdata
	fp.90.1 <- 
		paste0( 
			"http://www2.census.gov/census_1990/pums_1990_b/PUMSBX" ,
			st[ , 'state.abb' ] ,
			".zip"
		)

	# run the `get.tsv` function on each of the files specified in the character vector (created above)
	# and provide a corresponding file number parameter for each character string.
	tsv.90.1 <-
		mapply(
			get.tsv ,
			fp.90.1 ,
			fileno = seq( nrow( st ) ) ,
			MoreArgs = 
				list(
					zipped = TRUE ,
					hh.stru = hh.90.structure ,
					person.stru = person.90.structure 
				)
		)

	# using the monetdb connection, import each of the household- and person-level tab-separated value files
	# into the database, naming the household, person, and also merged file with these character strings
	pums.m.design <-
		pums.import.merge.design(
			db = db , 
			fn = tsv.90.1 , 
			merged.tn = "pums_1990_1_m" , 
			hh.tn = "pums_1990_1_h" , 
			person.tn = "pums_1990_1_p" ,
			hh.stru = hh.90.structure ,
			person.stru = person.90.structure
		)

	# save the monetdb-backed complex sample survey design object to the local disk
	save( pums.m.design , file = "pums_1990_1_m.rda" )

}

# if the user specified the download of this data set..
if ( 1990 %in% five.percent.files.to.download ){

	# exclude puerto rico
	warning( "puerto rico is not available in the 1990 five percent pums!" )

	# create a state table without puerto rico
	st.no.pr <- st[ !( st$state.abb %in% 'PR' ) , ]
	
	# construct a character vector containing one `zip` file's url for each state
	# the character vector contains the full http:// filepath to all of the census microdata
	fp.90.5 <- 
		paste0( 
			"http://www2.census.gov/census_1990/1990_PUMS_A/PUMSAX" ,
			st.no.pr[ , 'state.abb' ] ,
			".zip"
		)

	# run the `get.tsv` function on each of the files specified in the character vector (created above)
	# and provide a corresponding file number parameter for each character string.
	tsv.90.5 <-
		mapply(
			get.tsv ,
			fp.90.5 ,
			fileno = seq( nrow( st.no.pr ) ) ,
			MoreArgs = 
				list(
					zipped = TRUE ,
					hh.stru = hh.90.structure ,
					person.stru = person.90.structure 
				)
		)

	# using the monetdb connection, import each of the household- and person-level tab-separated value files
	# into the database, naming the household, person, and also merged file with these character strings
	pums.m.design <-
		pums.import.merge.design(
			db = db ,
			fn = tsv.90.5 , 
			merged.tn = "pums_1990_5_m" , 
			hh.tn = "pums_1990_5_h" , 
			person.tn = "pums_1990_5_p" ,
			hh.stru = hh.90.structure ,
			person.stru = person.90.structure
		)

	# save the monetdb-backed complex sample survey design object to the local disk
	save( pums.m.design , file = "pums_1990_5_m.rda" )

}

# if the user specified the download of this data set..
if ( 2000 %in% one.percent.files.to.download ){

	# construct a character vector containing one `zip` file's url for each state
	# the character vector contains the full http:// filepath to all of the census microdata
	fp.00.1 <- 
		paste0( 
			"http://www2.census.gov/census_2000/datasets/PUMS/OnePercent/" ,
			st[ , 'state.name' ] ,
			"/revisedpums1_" ,
			st[ , 'state.fips' ] ,
			".txt"
		)

	# run the `get.tsv` function on each of the files specified in the character vector (created above)
	# and provide a corresponding file number parameter for each character string.
	tsv.00.1 <-
		mapply(
			get.tsv ,
			fp.00.1 ,
			fileno = seq( nrow( st ) ) ,
			MoreArgs = 
				list(
					zipped = FALSE ,
					hh.stru = hh.00.structure ,
					person.stru = person.00.structure 
				)
		)

	# using the monetdb connection, import each of the household- and person-level tab-separated value files
	# into the database, naming the household, person, and also merged file with these character strings
	pums.m.design <-
		pums.import.merge.design(
			db = db ,
			fn = tsv.00.1 , 
			merged.tn = "pums_2000_1_m" , 
			hh.tn = "pums_2000_1_h" , 
			person.tn = "pums_2000_1_p" ,
			hh.stru = hh.00.structure ,
			person.stru = person.00.structure
		)

	# save the monetdb-backed complex sample survey design object to the local disk
	save( pums.m.design , file = "pums_2000_1_m.rda" )

}

# if the user specified the download of this data set..
if ( 2000 %in% five.percent.files.to.download ){

	# construct a character vector containing one `zip` file's url for each state
	# the character vector contains the full http:// filepath to all of the census microdata
	fp.00.5 <- 
		paste0( 
			"http://www2.census.gov/census_2000/datasets/PUMS/FivePercent/" ,
			st[ , 'state.name' ] ,
			"/REVISEDPUMS5_" ,
			st[ , 'state.fips' ] ,
			".TXT"
		)

	# run the `get.tsv` function on each of the files specified in the character vector (created above)
	# and provide a corresponding file number parameter for each character string.
	tsv.00.5 <-
		mapply(
			get.tsv ,
			fp.00.5 ,
			fileno = seq( nrow( st ) ) ,
			MoreArgs = 
				list(
					zipped = FALSE ,
					hh.stru = hh.00.structure ,
					person.stru = person.00.structure 
				)
		)

	# using the monetdb connection, import each of the household- and person-level tab-separated value files
	# into the database, naming the household, person, and also merged file with these character strings
	pums.m.design <-
		pums.import.merge.design(
			db = db ,
			fn = tsv.00.5 , 
			merged.tn = "pums_2000_5_m" , 
			hh.tn = "pums_2000_5_h" , 
			person.tn = "pums_2000_5_p" ,
			hh.stru = hh.00.structure ,
			person.stru = person.00.structure
		)

	# save the monetdb-backed complex sample survey design object to the local disk
	save( pums.m.design , file = "pums_2000_5_m.rda" )

}


# if the user specified the download of this data set..
if ( 2010 %in% ten.percent.files.to.download ){

	# construct a character vector containing one `zip` file's url for each state
	# the character vector contains the full http:// filepath to all of the census microdata
	fp.10.10 <- 
		paste0( 
			"http://www2.census.gov/census_2010/12-Stateside_PUMS/" ,
			st[ , 'state.name' ] ,
			"/" ,
			tolower( st[ , 'state.abb' ] ) ,
			".2010.pums.01.txt"
		)

	# run the `get.tsv` function on each of the files specified in the character vector (created above)
	# and provide a corresponding file number parameter for each character string.
	tsv.10.10 <-
		mapply(
			get.tsv ,
			fp.10.10 ,
			fileno = seq( nrow( st ) ) ,
			MoreArgs = 
				list(
					zipped = FALSE ,
					hh.stru = hh.10.structure ,
					person.stru = person.10.structure 
				)
		)

	# using the monetdb connection, import each of the household- and person-level tab-separated value files
	# into the database, naming the household, person, and also merged file with these character strings
	pums.m.design <-
		pums.import.merge.design(
			db = db ,
			fn = tsv.10.10 , 
			merged.tn = "pums_2010_10_m" , 
			hh.tn = "pums_2010_10_h" , 
			person.tn = "pums_2010_10_p" ,
			hh.stru = hh.10.structure ,
			person.stru = person.10.structure
		)

	# save the monetdb-backed complex sample survey design object to the local disk
	save( pums.m.design , file = "pums_2010_10_m.rda" )

}


# set every table you've just created as read-only inside the database.
for ( this_table in dbListTables( db ) ) dbSendQuery( db , paste( "ALTER TABLE" , this_table , "SET READ ONLY" ) )


# disconnect from the current monet database
dbDisconnect( db , shutdown = TRUE )

