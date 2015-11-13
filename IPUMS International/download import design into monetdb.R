# analyze survey data for free (http://asdfree.com) with the r language
# integrated public use microdata series - international

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# https://www.youtube.com/watch?v=JLt9JfaAxUg

# anthony joseph damico
# ajdamico@gmail.com

# if you use this script for a project, please send me a note
# it's always nice to hear about how people are using this stuff

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf


######################################################################################
# download a single year and single country census microdata extract csv file from   #
# the minnesota population center's ipums-international online repository.  prior to #
# working through this guide, you must create a csv-formatted extract through their  #
# online system.  that extract must contain the variables "PERWT" "SERIAL" "STRATA"  #
# otherwise you will not be able to construct a proper complex sample and all your   #
# results will be wrong, whoopsies.  once you have submitted the extract through the #
# ipums-international site and received "IPUMS-International data extract is ready." #
# you can copy and paste the zipped extract's exact url below, along with your login #
######################################################################################


# # uncomment and edit the following three lines of code # #
# username <- 'your_email'
# password <- 'your_password'
# url <- "https://international.ipums.org/international-action/downloads/extract_files/[your_projectname]_[your_extract_number].csv.gz"
# # uncomment and edit the previous three lines of code # #



# # # # # choose whether to use monetdb or active working memory # # # # #

# # # on my personal laptop, this mean of a linear variable -
# system.time( svymean( ~ age , this_design , se = TRUE ) )
# # # - requires about one second of processing with a monetdb-backed
# # # survey design setup, but requires about 40 seconds when loaded in ram

# # # there are tradeoffs to this processing speed. # # #

# # # strengths:
# # # data set does not need to fit into working active memory
# # # computations run much faster than data loaded into memory
# # # since squeezing data set into active memory does not matter,
# # # -- you can make an ipums extract with every single column just once
# # # -- and never repeat the extract creation/download/import process for that census

# # # weaknesses:
# # # sqlsurvey package does not have complete toolkit available in survey package
# # # sqlsurvey commands require slightly different syntax for users familiar with survey package
# # # loading takes a long time (but you can go do something else)
# # # column types (categorical versus linear) are guessed sloppily and irritating to change

# # # if the ipums-international extract files that you need to analyze do not fit into
# # # the active working memory of your available hardware, then you have no choice
# # # and you must use monetdb to analyze ipums-international with R.
# # # but on the other hand, just because you can load your needed extracts into working memory
# # # you might still benefit from using a monetdb-backed sqlsurvey design.
# # # monetdb-backed designs work much better interactively just because they process so much faster.  no waiting.

# # # # # continue using this guide if you have chosen to use monetdb # # # # #


# # # # # # # # # # # # # # #
# warning: monetdb required #
# # # # # # # # # # # # # # #


# windows machines and also machines without access
# to large amounts of ram will often benefit from
# the following option, available as of MonetDB.R 0.9.2 --
# remove the `#` in the line below to turn this option on.
# options( "monetdb.sequential" = TRUE )		# # only windows users need this line
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
# https://github.com/ajdamico/asdfree/blob/master/MonetDB/monetdb%20installation%20instructions.R                                 #
###################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # # #
# warning: this takes a while #
# # # # # # # # # # # # # # # #


library(sqlsurvey)		# load sqlsurvey package (analyzes large complex design surveys)
library(downloader)		# downloads and then runs the source() function on scripts from github
library(R.utils)		# load the R.utils package (counts the number of lines in a file quickly)


# set your IPUMSI data directory
# after downloading and importing
# all monet database-backed complex survey designs will be stored here
# and the monet database will be stored in the MonetDB folder within
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/IPUMSI/" )


# load the download_ipumsi and related functions
# to programmatically authenticate and download
source_url( 
	"https://raw.github.com/ajdamico/asdfree/master/IPUMS%20International/ipumsi%20functions.R" , 
	prompt = FALSE , 
	echo = FALSE 
)



# # depending on the size of your extract,
# # this process might take a long time.
# # if you're worried that this download line is stuck,
# # you can actively watch the filesize grow
# # by refreshing your current working directory

# download the specified ipums extract to the local disk,
# then decompress it into the current working directory
csv_file_location <- download_ipumsi( this_extract , username , password )
# note: use the `download_ipumsi` file= parameter in order to
# store the download resultant csv file elsewhere

# figure out which whether columns are character or numeric
csv_file_structure <- structure_ipumsi( this_extract , username , password )

# simple check that the stored csv file matches the loaded structure
if( !( length( csv_file_structure ) == ncol( read.csv( csv_file_location , nrow = 10 ) ) ) ) stop( "number of columns in final csv file does not match ipums structure xml file" )


# if you do not specify the table name in the database,
# just use the ipums international project and extract number.
# that way, you can at least refer back to the online system
tablename <- gsub( "\\.(.*)" , "" , csv_file_location )
# otherwise, you can name your table by commenting out the previous line and using this one instead
# tablename <- 'any_other_name'





# create a monetdb executable (.bat) file for the ipums international
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
					dbname = "ipumsi" ,
					
					# choose a database port
					# this port should not conflict with other monetdb databases
					# on your local computer.  two databases with the same port number
					# cannot be accessed at the same time
					dbport = 50015
	)


# this next step is so very important.

# store a line of code that will make it easy to open up the monetdb server in the future.
# this should contain the same file path as the batfile created above,
# you're best bet is to actually look at your local disk to find the full filepath of the executable (.bat) file.
# if you ran this script without changes, the batfile will get stored in C:\My Directory\IPUMSI\MonetDB\ipumsi.bat

# here's the batfile location:
batfile

# note that since you only run the `monetdb.server.setup()` function the first time this script is run,
# you will need to note the location of the batfile for future MonetDB analyses!

# in future R sessions, you can create the batfile variable with a line like..
# batfile <- "C:/My Directory/IPUMSI/MonetDB/ipumsi.bat"		# # note for mac and *nix users: `ipumsi.bat` might be `ipumsi.sh` instead
# obviously, without the `#` comment character

# hold on to that line for future scripts.
# you need to run this line *every time* you access
# the ipums international files with monetdb.
# this is the monetdb server.

# two other things you need: the database name and the database port.
# store them now for later in this script, but hold on to them for other scripts as well
dbname <- "ipumsi"
dbport <- 50015

# now the local windows machine contains a new executable program at "c:\my directory\ipumsi\monetdb\ipumsi.bat"




# it's recommended that after you've _created_ the monetdb server,
# you create a block of code like the one below to _access_ the monetdb server


#######################################################################
# lines of code to hold on to for all other `ipumsi` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/IPUMSI/MonetDB/ipumsi.bat"		# # note for mac and *nix users: `ipumsi.bat` might be `ipumsi.sh` instead

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "ipumsi"
dbport <- 50015

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )


# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other `ipumsi` monetdb analyses #
##############################################################################


# re-initiate the same monetdb server
pid <- monetdb.server.start( batfile )

# re-connecto to the same monetdb server
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

# decide whether column types should be character or numeric
colTypes <- ifelse( csv_file_structure == 'character' , 'VARCHAR(255)' , 'DOUBLE PRECISION' )

# determine the column names from the csv file
cn <- toupper( names( read.csv( csv_file_location , nrow = 1 ) ) )

# for any column names that conflict with a monetdb reserved word, add an underscore
cn[ cn %in% MonetDB.R:::reserved_monetdb_keywords ] <- paste0( cn[ cn %in% MonetDB.R:::reserved_monetdb_keywords ] , "_" )

# force all column names to be lowercase, since MonetDB.R is now case-sensitive
cn <- tolower( cn )

# paste column names and column types together sequentially
colDecl <- paste( cn , colTypes )

# construct a character string containing the create table command
sql_create_table <- 
	sprintf( 
		paste( "CREATE TABLE" , tablename , "(%s)" ) ,
		paste( colDecl , collapse = ", " ) 
	)

# construct the table in the database
dbSendQuery( db , sql_create_table )


# import the csv file into the database.
dbSendQuery( 
	db , 
	paste0(
		"COPY OFFSET 2 INTO " ,
		tablename ,
		" FROM '" ,
		normalizePath( csv_file_location ) ,
		"' USING DELIMITERS ',','\\n','\"' NULL AS ''" 
		# , " BEST EFFORT"	# <-- if your import breaks for some reason,
							# you could try uncommenting the preceding line
	)
)


# count the number of lines in the csv file on your local disk
csv_lines <- countLines( csv_file_location )

# count the number of records in the imported table
dbtable_lines <- dbGetQuery( db , paste( 'SELECT COUNT(*) FROM' , tablename ) )[ 1 , 1 ]

# the imported table should have one fewer line than the csv file,
# because the csv file has headers
stopifnot( csv_lines == dbtable_lines + 1 )

# disconnect from the database
dbDisconnect( db )

# shut it down
monetdb.server.stop( pid )

# re-initiate the same monetdb server
pid <- monetdb.server.start( batfile )

# re-connecto to the same monetdb server
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )


# # # manual variable blanking # # #

# unfortunately, there is no easily-accessible missingness indicator within the ipums-international documentation.
# if you would like invalid values to be treated as missings, then you will have to review the ipums variable codebooks manually.
# let's blank out two variables' missing values by hand:

# https://international.ipums.org/international-action/variables/EMPSTAT#codes_section
# EMPSTAT = 0 is "not in universe"
# EMPSTAT = 9 is "unknown/missing"

# https://international.ipums.org/international-action/variables/INCWAGE#codes_section
# INCWAGE = 9999998 is "unknown/missing"
# INCWAGE = 9999999 is "not in universe"

# here's a simple loop construction #

# the two variables that have values to blank into a single character vector
vars_to_blank <- c( 'empstat' , 'incwage' )

# the two sets of values to blank out, each nested within a list
vals_to_blank <- 
	list(
		c( 0 , 9 ) ,
		c( 9999998 , 9999999 )
	)

# confirm that you have one variable for each vector of values to blank
if( length( vars_to_blank ) != length( vals_to_blank ) ) stop( "these lengths must be the same." )

# loop through each of the variables to blank..
for ( this_col in seq( vars_to_blank ) ){

	# ..for any column matching one of the values-to-blank, update those particular rows to be NULL instead
	dbSendQuery( 
		db , 
		paste( 
			"UPDATE" , 
			tablename , 
			"SET" , 
			vars_to_blank[ this_col ] , 
			"= NULL WHERE" , 
			vars_to_blank[ this_col ] , 
			"IN (" , 
			paste( vals_to_blank[[ this_col ]] , collapse = "," ) , 
			")" 
		) 
	)

}

# # # end of manual variable blanking # # #

# disconnect from the database
dbDisconnect( db )

# shut it down
monetdb.server.stop( pid )

# re-initiate the same monetdb server
pid <- monetdb.server.start( batfile )

# re-connecto to the same monetdb server
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

# add a column containing all ones to the current table
dbSendQuery( db , paste0( 'alter table ' , tablename , ' add column one int' ) )
dbSendQuery( db , paste0( 'UPDATE ' , tablename , ' SET one = 1' ) )

# add a column containing the record (row) number
dbSendQuery( db , paste0( 'alter table ' , tablename , ' add column idkey int auto_increment' ) )


# # # # figure out which variables should be treated as factors (categorical) and which should be treated as numeric (linear) # # # #
# this is one of the drawbacks of sqlsurvey.  you must specify this information within the survey design object, not on the fly     #

# look at the columns available in your database..
dbListFields( db , tablename )

# ..or look at the variable names and types from ipums
cbind( cn , colTypes )

# if you like, you can query individual columns to determine how many unique levels they have
# for example, the `age` column should have approximately 100 distinct values because
# human beings live to be about 100 years old.
nrow( dbGetQuery( db , paste( "SELECT DISTINCT age FROM" , tablename ) ) )
# since 100 distinct values is really a linear variable and not categorical,
# it should *not* be included in the `these_factors` vector below.

# similarly, you can look at the first five records in your table with
dbGetQuery( db , paste( "SELECT * FROM" , tablename , "LIMIT 5" ) )

# for my personal extract, i would say that these variables
# are actually categorical variables, despite being stored as numbers
these_factors <- c( 'rectype' , 'country' , 'sex' , 'empstat' , 'empstatd' )


# # # alternative alternative alternative # # #
# if you do not provide the `check.factors=` parameter (or if you provide a number)
# then `sqlsurvey()` will check *every* variable to determine whether each variable has
# at least x distinct number of levels (x defaults to 10),
# and if the column does have >= x distinct levels, then the column will be stored as numeric.
# allowing `sqlsurvey` to calculate this on its own might take some time,
# but you can go do something else while you wait.

# it is more computationally-intensive to let sqlsurvey guess which variables are categorical and which are numeric,
# but it takes more of your personal time to provide the `these_factors` object yourself.  so whose time is more valuable?



# # # construct your monetdb-backed complex sample survey design object # # #

# create a sqlsurvey complex sample design object
this_design <-
	sqlsurvey(
		weight = "perwt" ,									# weight variable column
		nest = TRUE ,										# whether or not psus are nested within strata
		strata = "strata" ,									# stratification variable column
		id = "serial_" ,									# household clustering column same as "serial"
		table.name = tablename ,							# table name within the monet database
		key = "idkey" ,										# sql primary key column (created with the auto_increment line above)
		
		check.factors = these_factors ,						# character vector containing all factor columns for this extract
															# remember that the `check.factors=` parameter is optional
															# but failing to provide it will make this entire command take much longer
															# since the server needs to manually check whether or not each column has
															# at least 10 distinct levels or not.
															
		database = monet.url ,								# monet database location on localhost
		driver = MonetDB.R()
	)


# run your first sqlsurvey-based mean of a linear variable.
svymean( ~ age , this_design , se = TRUE )
# voila!

# you now have a
# monetdb-backed
# taylor series linearized
# complex sample survey design object
# ready for analysis.  and it's ultra-fast.

# save the survey design object
# into a single r data file (.rda) that can now be
# analyzed quicker than anything else.
save( this_design , these_factors , file = 'sqlsurvey design in monetdb.rda' )
# be sure to save the `these_factors` vector as well,
# just in case you do any recoding in the future

# disconnect from the database
dbDisconnect( db )

# shut it down
monetdb.server.stop( pid )

# unlike most post-importation scripts, the monetdb directory cannot be set to read-only #
message( paste( "all done.  DO NOT set" , getwd() , "read-only or subsequent scripts will not work." ) )

message( "got that? monetdb directories should not be set read-only." )
