# analyze us government survey data with the r language
# united states decennial census
# public use microdata sample
# 1990 , 2000

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


#################################################################################################
# analyze the 1990 and 2000 United States Decennial Census - Public Use Microdata Sample with R #
#################################################################################################


# set your working directory.
# the PUMS 1990 , 2000 data files will be stored here
# after downloading and importing them.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PUMS/" )
# ..in order to set your current working directory



# # # # # # # # # # # # # # #
# warning: monetdb required #
# # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###################################################################################################################################
# prior to running this analysis script, monetdb must be installed on the local machine.  follow each step outlined on this page: #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/usgsd/blob/master/MonetDB/monetdb%20installation%20instructions.R                                   #
###################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# define which years to download #

# uncomment these two lines to download all available data sets
# one.percent.files.to.download <- c( 1990 , 2000 )
# five.percent.files.to.download <- c( 1990 , 2000 )
# uncomment a line by removing the `#` at the front

# uncomment this line if you do not want puerto rico included in the downloaded microdata
# exclude.puerto.rico <- TRUE
# note that you can just subset tables later, so if you're unsure, i say leave it in, i say!


# remove the # in order to run this install.packages line only once
# install.packages( c( 'R.utils' , 'stringr' , 'descr' , 'downloader' , 'SAScii' ) )


# # # # # # # # # # # # # #
# warning: perl required! #
# # # # # # # # # # # # # #

# if you do not have perl installed, this two-minute video
# walks through how to get it (for free): http://www.screenr.com/QiN8

# remove the # in order to run this install.packages line only once
# install.packages('gdata')



############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #


require(SAScii) 		# load the SAScii package (imports ascii data with a SAS script)
require(gdata) 			# load the gdata package (imports excel [.xls] files into R)
require(R.utils)		# load the R.utils package (counts the number of lines in a file quickly)
require(stringr)		# load stringr package (manipulates character strings easily)
require(descr) 			# load the descr package (converts fixed-width files to delimited files)
require(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
require(downloader)		# downloads and then runs the source() function on scripts from github


# load the `get.tsv` and `pums.import.and.merge` functions from my github account.
source_url( "https://raw.github.com/ajdamico/usgsd/master/United States Decennial Census Public Use Microdata Sample/pums functions.R" , prompt = FALSE )
# these are two sets of commands that will be used repeatedly in the importation code below.


# load the `monet.read.tsv` function from my github account.
source_url( "https://raw.github.com/ajdamico/usgsd/master/MonetDB/monet.read.tsv.R" , prompt = FALSE )
# this is a modification of the SAScii package's read.SAScii function
# that imports tab-separated value files directly into MonetDB



# # # # # # # # #
# monetdb setup #
# # # # # # # # #


# configure a monetdb database for the us census pums on windows #

# note: only run this command once.  this creates an executable (.bat) file
# in the appropriate directory on your local disk.
# when adding new files or adding a new year of data, this script does not need to be re-run.

# create a monetdb executable (.bat) file for the american community survey
batfile <-
	monetdb.server.setup(
					
					# set the path to the directory where the initialization batch file and all data will be stored
					database.directory = paste0( getwd() , "/MonetDB" ) ,
					# must be empty or not exist
					
					# find the main path to the monetdb installation program
					monetdb.program.path = "C:/Program Files/MonetDB/MonetDB5" ,
					
					# choose a database name
					dbname = "pums" ,
					
					# choose a database port
					# this port should not conflict with other monetdb databases
					# on your local computer.  two databases with the same port number
					# cannot be accessed at the same time
					dbport = 50010
	)

	
# this next step is so very important.

# store a line of code that will make it easy to open up the monetdb server in the future.
# this should contain the same file path as the batfile created above,
# you're best bet is to actually look at your local disk to find the full filepath of the executable (.bat) file.
# if you ran this script without changes, the batfile will get stored in C:\My Directory\PUMS\MonetDB\pums.bat

# here's the batfile location:
batfile

# note that since you only run the `monetdb.server.setup()` function the first time this script is run,
# you will need to note the location of the batfile for future MonetDB analyses!

# in future R sessions, you can create the batfile variable with a line like..
# batfile <- "C:/My Directory/PUMS/MonetDB/pums.bat"
# obviously, without the `#` comment character

# hold on to that line for future scripts.
# you need to run this line *every time* you access
# the us census public use microdata sample files with monetdb.
# this is the monetdb server.

# two other things you need: the database name and the database port.
# store them now for later in this script, but hold on to them for other scripts as well
dbname <- "pums"
dbport <- 50010

# now the local windows machine contains a new executable program at "c:\my directory\PUMS\monetdb\pums.bat"




# it's recommended that after you've _created_ the monetdb server,
# you create a block of code like the one below to _access_ the monetdb server


############################################################################
# lines of code to hold on to for all other `PUMS` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/PUMS/MonetDB/pums.bat"

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "pums"
dbport <- 50010

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url )


# # # # but the lines of code below will re-start the server
# # # # so let's close down the connection and the server for the moment.


# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other `pums` monetdb analyses #
############################################################################



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
	
	# download the pums sas script provided by the census bureau
	download.file( "http://www2.census.gov/census_1990/1990_PUMS_A/TOOLS/sas/PUMS.SAS" , tf )
	
	# read the script into working memory
	sas.90 <- readLines( tf )

	# add a leading column (parse.SAScii cannot handle a sas importation script that doesn't start at the first position)
	sas.90 <- gsub( "@2 SerialNo $ 7." , "@1 rectype $ 1 @2 SerialNo $ 7." , sas.90 , fixed = TRUE )

	# write the script back to memory
	writeLines( sas.90 , tf )

	# read in the household structure
	hh.90.structure <- parse.SAScii( tf , beginline = 7 )
	
	# read in the person structure
	person.90.structure <- parse.SAScii( tf , beginline = 125 )
	
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

# if 1990 was requested in either the 1% or 5% files..
if ( 2000 %in% c( one.percent.files.to.download , five.percent.files.to.download ) ){

	# create a temporary file on the local disk
	pums.layout <- tempfile()

	# download the layout excel file
	download.file( "http://www2.census.gov/census_2000/datasets/PUMS/FivePercent/5%25_PUMS_record_layout.xls" ,	pums.layout , mode = 'wb' )

	# initiate a quick layout read-in function #
	code.str <-
		function( fn , sheet ){

			# read the sheet (specified as a function input) to an object `stru
			stru <- read.xls( fn , sheet = sheet , skip = 1 )
			
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

	# run the MonetDB server, determine the server path, connect to the server
	pid <- monetdb.server.start( batfile )
	monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
	db <- dbConnect( MonetDB.R() , monet.url )

	# using the monetdb connection, import each of the household- and person-level tab-separated value files
	# into the database, naming the household, person, and also merged file with these character strings
	pums.1990.1.m.design <-
		pums.import.merge.design(
			db = db , monet.url = monet.url ,
			fn = tsv.90.1 , 
			merged.tn = "pums_1990_1_m" , 
			hh.tn = "pums_1990_1_h" , 
			person.tn = "pums_1990_1_p"
		)

	# save the monetdb-backed complex sample survey design object to the local disk
	save( pums.1990.1.m.design , file = "pums_1990_1_m.rda" )

	# disconnect from the current monet database..
	dbDisconnect( db )
	# and close it using the `pid`
	monetdb.server.stop( pid )

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

	# run the MonetDB server, determine the server path, connect to the server
	pid <- monetdb.server.start( batfile )
	monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
	db <- dbConnect( MonetDB.R() , monet.url )

	# using the monetdb connection, import each of the household- and person-level tab-separated value files
	# into the database, naming the household, person, and also merged file with these character strings
	pums.1990.5.m.design <-
		pums.import.merge.design(
			db = db , monet.url = monet.url ,
			fn = tsv.90.5 , 
			merged.tn = "pums_1990_5_m" , 
			hh.tn = "pums_1990_5_h" , 
			person.tn = "pums_1990_5_p"
		)

	# save the monetdb-backed complex sample survey design object to the local disk
	save( pums.1990.5.m.design , file = "pums_1990_5_m.rda" )
	
	# disconnect from the current monet database..
	dbDisconnect( db )
	# and close it using the `pid`
	monetdb.server.stop( pid )

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

	# run the MonetDB server, determine the server path, connect to the server
	pid <- monetdb.server.start( batfile )
	monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
	db <- dbConnect( MonetDB.R() , monet.url )

	# using the monetdb connection, import each of the household- and person-level tab-separated value files
	# into the database, naming the household, person, and also merged file with these character strings
	pums.2000.1.m.design <-
		pums.import.merge.design(
			db = db , monet.url = monet.url ,
			fn = tsv.00.1 , 
			merged.tn = "pums_2000_1_m" , 
			hh.tn = "pums_2000_1_h" , 
			person.tn = "pums_2000_1_p"
		)

	# save the monetdb-backed complex sample survey design object to the local disk
	save( pums.2000.1.m.design , file = "pums_2000_1_m.rda" )

	# disconnect from the current monet database..
	dbDisconnect( db )
	# and close it using the `pid`
	monetdb.server.stop( pid )

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

	# run the MonetDB server, determine the server path, connect to the server
	pid <- monetdb.server.start( batfile )
	monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
	db <- dbConnect( MonetDB.R() , monet.url )

	# using the monetdb connection, import each of the household- and person-level tab-separated value files
	# into the database, naming the household, person, and also merged file with these character strings
	pums.2000.5.m.design <-
		pums.import.merge.design(
			db = db , monet.url = monet.url ,
			fn = tsv.00.5 , 
			merged.tn = "pums_2000_5_m" , 
			hh.tn = "pums_2000_5_h" , 
			person.tn = "pums_2000_5_p"
		)

	# save the monetdb-backed complex sample survey design object to the local disk
	save( pums.2000.5.m.design , file = "pums_2000_5_m.rda" )
	
	# disconnect from the current monet database..
	dbDisconnect( db )
	# and close it using the `pid`
	monetdb.server.stop( pid )
		
}



#####################################################################
# lines of code to hold on to for all other `pums` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/PUMS/MonetDB/pums.bat"

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "pums"
dbport <- 50010

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url )


# # # # run your analysis commands # # # #


# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other `pums` monetdb analyses #
############################################################################


# unlike most post-importation scripts, the monetdb directory cannot be set to read-only #
message( paste( "all done.  DO NOT set" , getwd() , "read-only or subsequent scripts will not work." ) )

message( "got that? monetdb directories should not be set read-only." )


# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
