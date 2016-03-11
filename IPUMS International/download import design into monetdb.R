# analyze survey data for free (http://asdfree.com) with the r language
# integrated public use microdata series - international

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


# this is a guide, it is not a one-size-fits-all set of commands:
# edit this code heavily for your own analysis, otherwise you are doing something wrong.


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
# this_extract <- "https://international.ipums.org/international-action/downloads/extract_files/[[your_projectname]]_[[your_extract_number]].csv.gz"
# # uncomment and edit the previous three lines of code # #


# # # # # choose whether to use monetdb or active working memory # # # # #


# # # there are tradeoffs to this processing speed. # # #

# # # strengths:
# # # data set does not need to fit into working active memory
# # # computations run much faster than data loaded into memory
# # # since squeezing data set into active memory does not matter,
# # # -- you can make an ipums extract with every single column just once
# # # -- and never repeat the extract creation/download/import process for that census

# # # weaknesses:
# # # database-backed commands require slightly different syntax for users familiar with survey package
# # # loading takes a long time (but you can go do something else)

# # # if the ipums-international extract files that you need to analyze do not fit into
# # # the active working memory of your available hardware, then you have no choice
# # # and you must use monetdb to analyze ipums-international with R.
# # # but on the other hand, just because you can load your needed extracts into working memory
# # # you might still benefit from using a monetdb-backed survey design.
# # # monetdb-backed designs work much better interactively just because individual analysis commands run faster.  no waiting.

# # # continue using this guide if you have chosen to use monetdb # # #

# # # if you would prefer to load your ipums extract directly into active working memory (ram),
# # # then follow the guide `download import design within memory.R` within this syntax directory instead


# # # # # # # # # # # # # # # #
# warning: this takes a while #
# # # # # # # # # # # # # # # #

# remove the # in order to run this install.packages line only once
# install.packages( c( "httr" , "XML" , "rvest" , "MonetDB.R" , "MonetDBLite" , "survey" , "SAScii" , "descr" , "downloader" , "digest" , "R.utils" ) , repos = c( "http://dev.monetdb.org/Assets/R/" , "http://cran.rstudio.com/" ) )


library(survey) 		# load survey package (analyzes complex design surveys)
library(DBI)			# load the DBI package (implements the R-database coding)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(MonetDBLite)	# load MonetDBLite package (creates database files in R)
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
	"https://raw.githubusercontent.com/ajdamico/asdfree/master/IPUMS%20International/ipumsi%20functions.R" , 
	prompt = FALSE , 
	echo = FALSE 
)
# thanks to the amazing respondents on stackoverflow for this algorithm
# http://stackoverflow.com/questions/34829920/how-to-authenticate-a-shibboleth-multi-hostname-website-with-httr-in-r



# # depending on the size of your extract,
# # this process might take a long time.
# # if you're worried that this download line is stuck,
# # you can actively watch the filesize grow
# # by refreshing your current working directory

# download the specified ipums extract to the local disk,
# then decompress it into the current working directory
csv_list <- download_ipumsi( this_extract , username , password )
# note: use the `download_ipumsi` file= parameter in order to
# store the download resultant csv file elsewhere

# store the file location
csv_file_location <- csv_list[[1]]

# store the column classes
csv_file_structure <- csv_list[[2]]

# simple check that the stored csv file matches the loaded structure
if( !( length( csv_file_structure ) == ncol( read.csv( csv_file_location , nrow = 10 ) ) ) ) stop( "number of columns in final csv file does not match ipums structure xml file" )


# if you do not specify the table name in the database,
# just use the ipums international project and extract number.
# that way, you can at least refer back to the online system
tablename <- gsub( "\\.(.*)" , "" , csv_file_location )
# otherwise, you can name your table by commenting out the previous line and using this one instead
# tablename <- 'any_other_name'



# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )

# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite() , dbfolder )



# decide whether column types should be character or numeric
colTypes <- ifelse( csv_file_structure == 'character' , 'CLOB' , 'DOUBLE PRECISION' )

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


# # # manual variable blanking # # #

# unfortunately, there is no easily-accessible missingness indicator within the ipums-international documentation.
# if you would like invalid values to be treated as missings, then you will have to review the ipums variable codebooks manually.
# let's blank out only one variable's missing values by hand:

# # note that this is different from the "in memory" guide, where three variables were blanked.
# # i recommend not blanking out *categorical* variable values in survey designs,
# # because they can trigger finnickyness/bugs.  it is safer to only blank out linear variable missing values.

# https://international.ipums.org/international-action/variables/INCWAGE#codes_section
# INCWAGE = 9999998 is "unknown/missing"
# INCWAGE = 9999999 is "not in universe"

# here's a simple loop construction #

# store one variable that has values to blank into a single character vector
vars_to_blank <- c( 'incwage' )

# one set of values to blank out, nested within a list just like the "in memory" guide
vals_to_blank <- 
	list(
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


# add a column containing all ones to the current table
dbSendQuery( db , paste0( 'alter table ' , tablename , ' add column one int' ) )
dbSendQuery( db , paste0( 'UPDATE ' , tablename , ' SET one = 1' ) )


# look at the columns available in your database..
dbListFields( db , tablename )

# ..or look at the variable names and types from ipums
cbind( cn , colTypes )


# # # construct your monetdb-backed complex sample survey design object # # #

# create a survey complex sample design object
this_db_design <-
	svydesign(
		weight = ~perwt ,									# weight variable column
		nest = TRUE ,										# whether or not psus are nested within strata
		strata = ~strata ,									# stratification variable column
		id = ~serial_ ,										# household clustering column same as "serial"
		data = tablename ,									# table name within the monet database
		dbtype = "MonetDBLite" ,
		dbname = dbfolder
	)


# run your first mean of a linear variable.
svymean( ~ age , this_db_design )
# voila!

# you now have a
# monetdb-backed
# taylor series linearized
# complex sample survey design object
# ready for analysis.  and it's ultra-fast.

# save the survey design object
# into a single r data file (.rda) that can now be
# analyzed quicker than anything else.
save( this_db_design , file = 'survey design in monetdb.rda' )


# set every table you've just created as read-only inside the database.
for ( this_table in dbListTables( db ) ) dbSendQuery( db , paste( "ALTER TABLE" , this_table , "SET READ ONLY" ) )


# disconnect from the database
dbDisconnect( db )

