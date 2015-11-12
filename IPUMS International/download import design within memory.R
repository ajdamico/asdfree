

# # # on my personal laptop, this mean of a linear variable -
# system.time( svymean( ~ age , this_design ) )
# # # - requires about one second of processing with a monetdb-backed
# # # survey design setup, but requires about 40 seconds when loaded in ram

# # # there are tradeoffs to this processing speed. # # #

# # # strengths:
# # # the survey package (only usable on data within memory) has a much more complete toolkit than the sqlsurvey package
# # # data import (but not analysis) is often quicker and easier to troubleshoot
# # # column types (categorical versus linear) are more fluid and faster to modify during analysis commands

# # # weaknesses:
# # # data set must fit into working active memory
# # # computations run slower than a column-store database like monetdb
# # # since you may have to squeeze the data set into active memory,
# # # -- you might need to create smaller ipums extracts with only a subset of available columns
# # # -- and never return to the extract creation/download/import process if you find you did not request something

# # # if the ipums-international extract files that you need to analyze do not fit into
# # # the active working memory of your available hardware, then you have no choice
# # # and you must use monetdb to analyze ipums-international with R.
# # # but on the other hand, just because you can load your needed extracts into working memory
# # # you might still benefit from using a monetdb-backed sqlsurvey design.
# # # monetdb-backed designs work much better interactively just because they process so much faster.  no waiting.



library(survey)
library(R.utils)
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

		
this_df <- 
	read.csv( 
		csv_file_location , 
		colClasses = csv_file_structure , 
		stringsAsFactors = FALSE 
	)

# immediately after read-in,
# divide any columns with implied decimals by 10^(# of implied decimals)
stop( 'is this necessary? e-mailed lara' )
# for ( this_col in seq( ncol( this_df ) ) ) {
	# if( !( csv_file_decimals[ this_col ] == 0 ) ) {
		# this_df[ , this_col ] <- ( this_df[ , this_col ] / 10^( csv_file_decimals[ this_col ] ) )
	# }
# }

# almost immediately afterward,
# make every column lowercase	
names( this_df ) <- tolower( names( this_df ) )
	
this_df$rectype <- NULL
	
csv_lines <- countLines( csv_file_location )

stopifnot( csv_lines == nrow( this_df ) + 1 )


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

# and at this point, it's a simple (pretty nested) loop.
for ( this_col in seq( vars_to_blank ) ) this_df[ this_df[ , vars_to_blank[ this_col ] ] %in% vals_to_blank[[ this_col ]] , vars_to_blank[ this_col ] ] <- NA

# # # end of manual variable blanking # # #


this_design <-
	svydesign(
		id = ~ serial ,
		strata = ~ strata ,
		data = this_df ,
		weights = ~ perwt ,
		nest = TRUE
	)
	
svymean( ~ age , this_design )
	

save( this_design , file = "this extract in memory.rda" )

