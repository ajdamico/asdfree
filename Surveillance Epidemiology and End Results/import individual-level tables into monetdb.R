# analyze survey data for free (http://asdfree.com) with the r language
# surveillance epidemiology and end results
# 1973 through 2011

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/SEER/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Surveillance%20Epidemiology%20and%20End%20Results/import%20individual-level%20tables%20into%20monetdb.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


#############################################
# load each data table in the seer data set #
# into a monet database on the local disk   #
#############################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###############################################################################################################
# prior to running this importation script, the seer text file must be loaded on the local machine with:      #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/asdfree/blob/master/Surveillance%20Epidemiology%20and%20End%20Results/download.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a 'SEER_1973_2013_TEXTDATA' directory in C:/My Directory/SEER (or the cw directory) #
###############################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# set your working directory.
# all SEER data files will be stored here
# after downloading.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/SEER/" )
# ..in order to set your current working directory


# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )


# remove the # in order to run this install.packages line only once
# install.packages( c( "MonetDBLite" , "SAScii" , "descr" , "R.utils" ) )


library(MonetDBLite)
library(DBI)			# load the DBI package (implements the R-database coding)
library(SAScii) 		# load the SAScii package (imports ascii data with a SAS script)
library(descr) 			# load the descr package (converts fixed-width files to delimited files)
library(downloader)		# downloads and then runs the source() function on scripts from github
library(R.utils)		# load the R.utils package (counts the number of lines in a file quickly)

# load the `read.SAScii.monetdb` function from my github account.
source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/MonetDB/read.SAScii.monetdb.R" , prompt = FALSE )
# this is a modification of the R SAScii package's read.SAScii function that imports directly into MonetDB


# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite::MonetDBLite() , dbfolder )


# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# identify all files to import into r data files (.rda) #

# first, look in the downloaded zipped file's main directory,
# and store a character vector `all.files` containing the filepaths
# to each of the files inside that directory
all.files <- list.files( "./SEER_1973_2013_TEXTDATA" , full.names = TRUE , recursive = TRUE )

# create a character vector matching the different cancer file name identifiers
words.to.match <- c( "BREAST" , "COLRECT" , "DIGOTHR" , "FEMGEN" , "LYMYLEUK" , "MALEGEN" , "RESPIR" , "URINARY" , "OTHER" )

# subset the `all.files` character vector to only retain files containing *any* of the words in the `words.to.match` vector
( ind.file.matches <- all.files[ grep( paste0( words.to.match , collapse = "|" ) , all.files ) ] )
# by encasing the above statement in parentheses, the `ind.file.matches` object will also be printed to the screen

# end of file identification  #
# # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # # # # # #
# import all individual-level files #

# create a temporary file on the local disk
edited.sas.instructions <- tempfile()

# read the sas importation script into memory
z <- readLines( grep( "\\.sas$" , list.files( recursive = TRUE ) , value = TRUE ) )

# get rid of the first through fourth lines (the -1:-4 part)
# and at the same time get rid of the word `char` (the gsub part)
z <- gsub( "char" , "" , z[-1:-4] )
# since SAScii cannot handle char# formats

# remove the leading space in front of the at signs,
z <- gsub( "@ " , "@" , z , fixed = TRUE )
# since SAScii does not expect that either

# write the result back to a temporary file on the local disk
writeLines( z , edited.sas.instructions )


# figure out what to name each of the individual-level tables in the database #

# start with the `ind.file.matches` character vector, which contains
# the filepath to each of the text files that need to be imported

# remove the major folder root path
table.names <-
	gsub( 
		"./SEER_1973_2014_TEXTDATA/incidence/" ,
		"" , 
		ind.file.matches
	)

# remove the `.txt` extension
table.names <-
	gsub( 
		".TXT" ,
		"" , 
		table.names ,
		fixed = TRUE
	)

# convert periods and slashes to underscores
table.names <- gsub( "." , "_" , table.names , fixed = TRUE )
table.names <- gsub( "/" , "_" , table.names , fixed = TRUE )

# convert all table names to strictly lowercase
table.names <- tolower( table.names )


# loop through each of the individual-level files matched above
for ( i in seq( length( table.names ) ) ){

	# print current progress to the screen
	print( paste( "currently working on" , ind.file.matches[ i ] ) )
	print( "" )

	read.SAScii.monetdb ( 
		# use the current individual-level text file..
		ind.file.matches[ i ] ,
		
		# ..and the revised sas importation instructions
		# to read the current ascii file directly into a monet database
		sas_ri = edited.sas.instructions , 
		
		# convert all column names to lowercase
		tl = TRUE ,
		
		# naming the table according to the cleaned up string (also above)
		tablename = table.names[ i ] ,
		
		connection = db
	)
	
	# construct a sql alter table statement to add a column named `tablename`
	add.tn.column.sql <-
		paste(
			"alter table" ,
			table.names[ i ] ,
			"add column tablename STRING"
		)
	
	# execute the sql 'alter table' command
	dbSendQuery( db , add.tn.column.sql )
	
	
	# construct a sql update statement to make all records in the current table
	# have `tablename` column values equal to the actual tablename
	update.tn.column.sql <-
		paste0(
			"update " ,
			table.names[ i ] ,
			" set tablename = '" ,
			table.names[ i ] ,
			"'"
		)
	# (this column will be useful when all of these tables
	# are stacked on top of each other)
		
	# execute the sql `update` command
	dbSendQuery( db , update.tn.column.sql )
	
}


# end of individual-level file importation  #
# # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # # # # # #
# stack all individual-level files  #

# construct a sql union command that will 
# combine all previously-imported tables into one!
sql.union <-
	paste(
		'create table x as' ,
		
		paste( 'select * from' , table.names , collapse = ' union ' ) ,
		
		'with data'
	)
# execute the sql `union` command
dbSendQuery( db , sql.union )


# end of stacking individual-level files  #
# # # # # # # # # # # # # # # # # # # # # #


# precisely match the overall count on http://seer.cancer.gov/data/ #
dbGetQuery( db , 'select count(*) from x' )



# note: this script does not load the population-level files,
# since they're small and should be loaded as r data files (.rda)
# take a look at the other seer importation script in this directory


# set every table you've just created as read-only inside the database.
for ( this_table in dbListTables( db ) ) dbSendQuery( db , paste( "ALTER TABLE" , this_table , "SET READ ONLY" ) )


# disconnect from the current monet database
dbDisconnect( db , shutdown = TRUE )
