

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





library(R.utils)


library(sqlsurvey)		# load sqlsurvey package (analyzes large complex design surveys)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(foreign) 		# load foreign package (converts data files into R)
library(downloader)		# downloads and then runs the source() function on scripts from github
source_url( "https://raw.github.com/ajdamico/asdfree/master/IPUMS%20International/ipumsi%20functions.R" , prompt = FALSE , echo = TRUE )



# download the specified ipums extract to the local disk,
# then decompress it into the current working directory
csv_file_location <- download_ipumsi( this_extract , username , password )
# note: use the `download_ipumsi` file= parameter in order to
# store the download resultant csv file elsewhere

# figure out which numeric variables have implied decimals
csv_file_decimals <- decimals_ipumsi( this_extract , username , password )

# figure out which whether columns are character or numeric
csv_file_structure <- structure_ipumsi( this_extract , username , password )

# simple check that the stored csv file matches the loaded structure
if( !( length( csv_file_structure ) == ncol( read.csv( csv_file_location , nrow = 10 ) ) ) ) stop( "number of columns in final csv file does not match ipums structure xml file" )


# if you do not specify the table name in the database,
# just use the ipums international extract number.
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



pid <- monetdb.server.start( batfile )

db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )




colTypes <- ifelse( csv_file_structure == 'character' , 'VARCHAR(255)' , 'DOUBLE PRECISION' )# ifelse( csv_file_decimals == 0 , 'BIGINT' , 'DOUBLE PRECISION' ) )
cn <- toupper( names( read.csv( csv_file_location , nrow = 1 ) ) )
cn[ cn %in% c( "SERIAL" , "SAMPLE" , .SQL92Keywords ) ] <- paste0( cn[ cn %in% c( "SERIAL" , "SAMPLE" , .SQL92Keywords ) ] , "_" )
cn <- tolower( cn )
colDecl <- paste( cn , colTypes )
sql <- sprintf( paste( "CREATE TABLE" , tablename , "(%s)" ) ,	paste( colDecl , collapse = ", " ) )

dbSendQuery( db , sql )


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


# immediately after read-in,
# divide any columns with implied decimals by 10^(# of implied decimals)
stop( 'is this necessary? e-mailed lara' )
# for ( this_col in seq( cn ) ) {
	# if( !( csv_file_decimals[ this_col ] == 0 ) ) {
		# dbSendQuery( db , paste( "UPDATE" , tablename , "SET" , cn[ this_col ] , " = " , cn[ this_col ] , " / " , 10^( csv_file_decimals[ this_col ] ) ) )
	# }
# }


# monet.read.csv( db , csv_file_location , tablename , lower.case.names = TRUE , best.effort = TRUE )



csv_lines <- countLines( csv_file_location )

dbtable_lines <- dbGetQuery( db , paste( 'SELECT COUNT(*) FROM' , tablename ) )[ 1 , 1 ]

stopifnot( csv_lines == dbtable_lines + 1 )

dbDisconnect( db )

monetdb.server.stop( pid )

pid <- monetdb.server.start( batfile )

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

if( length( vars_to_blank ) != length( vals_to_blank ) ) stop( "these lengths must be the same." )
	
for ( this_col in seq( vars_to_blank ) ){

	# for any column matching one of the values-to-blank, update those particular rows to be NULL instead
	dbSendQuery( db , paste( "UPDATE" , tablename , "SET" , vars_to_blank[ this_col ] , "= NULL WHERE" , vars_to_blank[ this_col ] , "IN (" , paste( vals_to_blank[[ this_col ]] , collapse = "," ) , ")" ) )

}

# # # end of manual variable blanking # # #

dbDisconnect( db )

monetdb.server.stop( pid )

pid <- monetdb.server.start( batfile )

db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

# add a column containing all ones to the current table
dbSendQuery( db , paste0( 'alter table ' , tablename , ' add column one int' ) )
dbSendQuery( db , paste0( 'UPDATE ' , tablename , ' SET one = 1' ) )


# add a column containing the record (row) number
dbSendQuery( db , paste0( 'alter table ' , tablename , ' add column idkey int auto_increment' ) )

# create a sqlsurvey complex sample design object
this_design <-
	sqlsurvey(
		weight = "perwt" ,									# weight variable column
		nest = TRUE ,										# whether or not psus are nested within strata
		strata = "strata" ,									# stratification variable column
		id = "serial_" ,									# household clustering column same as "serial"
		table.name = tablename ,							# table name within the monet database
		key = "idkey" ,										# sql primary key column (created with the auto_increment line above)
		# check.factors = get( paste0( 'c' , year ) ) ,		# character vector containing all factor columns for this year
		database = monet.url ,								# monet database location on localhost
		driver = MonetDB.R()
	)

svymean( ~ age , this_design , se = TRUE )

# save the complex sample survey design
# into a single r data file (.rda) that can now be
# analyzed quicker than anything else.
save( this_design , file = 'this extract in monetdb.rda' )


