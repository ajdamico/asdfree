# analyze survey data for free (http://asdfree.com) with the r language
# surveillance epidemiology and end results
# 1973 through 2011

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( "monetdb.sequential" = TRUE )
# library(downloader)
# setwd( "C:/My Directory/SEER/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Surveillance%20Epidemiology%20and%20End%20Results/import%20individual-level%20tables%20into%20monetdb.R" , prompt = FALSE , echo = TRUE )
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


#############################################
# load each data table in the seer data set #
# into a monet database on the local disk   #
#############################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###############################################################################################################
# prior to running this importation script, the seer text file must be loaded on the local machine with:      #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/usgsd/blob/master/Surveillance%20Epidemiology%20and%20End%20Results/download.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a 'SEER_1973_2011_TEXTDATA' directory in C:/My Directory/SEER (or the cw directory) #
###############################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # #
# warning: monetdb required #
# # # # # # # # # # # # # # #


# windows machines and also machines without access
# to large amounts of ram will often benefit from
# the following option, available as of MonetDB.R 0.9.2 --
# remove the `#` in the line below to turn this option on.
# options( "monetdb.sequential" = TRUE )
# -- whenever connecting to a monetdb server,
# this option triggers sequential server processing
# in other words: single-threading.
# if you would prefer to turn this on or off immediately
# (that is, without a server connect or disconnect), use
# turn on single-threading only
# dbSendQuery( db , "set optimizer = 'sequential_pipe';" )
# restore default behavior -- or just restart instead
# dbSendQuery(db,"set optimizer = 'default_pipe';")

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###################################################################################################################################
# prior to running this analysis script, monetdb must be installed on the local machine.  follow each step outlined on this page: #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/usgsd/blob/master/MonetDB/monetdb%20installation%20instructions.R                                   #
###################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# set your working directory.
# all SEER data files will be stored here
# after downloading.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/SEER/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( c( "SAScii" , "descr" , "MonetDB.R" ) )


library(SAScii) 		# load the SAScii package (imports ascii data with a SAS script)
library(descr) 			# load the descr package (converts fixed-width files to delimited files)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(downloader)		# downloads and then runs the source() function on scripts from github


# load the `read.SAScii.monetdb` function from my github account.
source_url( "https://raw.github.com/ajdamico/usgsd/master/MonetDB/read.SAScii.monetdb.R" , prompt = FALSE )
# this is a modification of the R SAScii package's read.SAScii function that imports directly into MonetDB


# configure a monetdb database for the seer on windows #

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
					monetdb.program.path = 
						ifelse( 
							.Platform$OS.type == "windows" , 
							"C:/Program Files/MonetDB/MonetDB5" , 
							"" 
						) ,
					# note: for windows, monetdb usually gets stored in the program files directory
					# for other operating systems, it's usually part of the PATH and therefore can simply be left blank.
					
					# choose a database name
					dbname = "seer" ,
					
					# choose a database port
					# this port should not conflict with other monetdb databases
					# on your local computer.  two databases with the same port number
					# cannot be accessed at the same time
					dbport = 50008
	)

	
# this next step is so very important.

# store a line of code that will make it easy to open up the monetdb server in the future.
# this should contain the same file path as the batfile created above,
# you're best bet is to actually look at your local disk to find the full filepath of the executable (.bat) file.
# if you ran this script without changes, the batfile will get stored in C:\My Directory\SEER\MonetDB\seer.bat

# here's the batfile location:
batfile

# note that since you only run the `monetdb.server.setup()` function the first time this script is run,
# you will need to note the location of the batfile for future MonetDB analyses!

# in future R sessions, you can create the batfile variable with a line like..
# batfile <- "C:/My Directory/SEER/MonetDB/seer.bat"
# obviously, without the `#` comment character

# hold on to that line for future scripts.
# you need to run this line *every time* you access
# the surveillance epidemiology and end results program files with monetdb.
# this is the monetdb server.

# two other things you need: the database name and the database port.
# store them now for later in this script, but hold on to them for other scripts as well
dbname <- "seer"
dbport <- 50008

# now the local windows machine contains a new executable program at "c:\my directory\seer\monetdb\seer.bat"




# it's recommended that after you've _created_ the monetdb server,
# you create a block of code like the one below to _access_ the monetdb server


#####################################################################
# lines of code to hold on to for all other `seer` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/SEER/MonetDB/seer.bat"

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "seer"
dbport <- 50008

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )




# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# identify all files to import into r data files (.rda) #

# first, look in the downloaded zipped file's main directory,
# and store a character vector `all.files` containing the filepaths
# to each of the files inside that directory
all.files <- list.files( "./SEER_1973_2011_TEXTDATA" , full.names = TRUE , recursive = TRUE )

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
z <- readLines( "./SEER_1973_2011_TEXTDATA/incidence/read.seer.research.nov13.sas" )

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
		"./SEER_1973_2011_TEXTDATA/incidence/" ,
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
			"add column tablename varchar(255)"
		)
	
	# execute the sql 'alter table' command
	dbSendUpdate( db , add.tn.column.sql )
	
	
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
	dbSendUpdate( db , update.tn.column.sql )
	
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
dbSendUpdate( db , sql.union )


# end of stacking individual-level files  #
# # # # # # # # # # # # # # # # # # # # # #


# precisely match the overall count on http://seer.cancer.gov/data/ #
dbGetQuery( db , 'select count(*) from x' )



# note: this script does not load the population-level files,
# since they're small and should be loaded as r data files (.rda)
# take a look at the other seer importation script in this directory


# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other `seer` monetdb analyses #
############################################################################



#####################################################################
# lines of code to hold on to for all other `seer` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/SEER/MonetDB/seer.bat"

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "seer"
dbport <- 50008

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )


# # # # run your analysis commands # # # #


# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other `seer` monetdb analyses #
############################################################################


# unlike most post-importation scripts, the monetdb directory cannot be set to read-only #
message( paste( "all done.  DO NOT set" , getwd() , "read-only or subsequent scripts will not work." ) )

message( "got that? monetdb directories should not be set read-only." )


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
