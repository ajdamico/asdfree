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
# # # monetdb-backed designs work much better interactively just because individual analysis commands run so much faster.  no waiting.

# # # continue using this guide if you have chosen to load your extract directly into active working memory (ram) # # #

# # # if you would prefer to load your extract into a hyperfast monetdb database for your project,
# # # then follow the guide `download import design into monetdb.R` within this syntax directory instead


library(survey)			# load survey package (analyzes complex design surveys)
library(downloader)		# downloads and then runs the source() function on scripts from github
library(R.utils)		# load the R.utils package (counts the number of lines in a file quickly)

# set your IPUMSI data directory
# after downloading and importing
# all monet database-backed complex survey designs will be stored here
# and the monet database will be stored in the MonetDB folder within
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/IPUMSI/" )


# remove the # in order to run this install.packages line only once
# install.packages( c( "httr" , "XML" ) )


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


# here is the big test.

# load the ipums-international csv extract directly into active working memory (ram)
this_df <- 
	read.csv( 
		csv_file_location , 
		colClasses = csv_file_structure , 
		stringsAsFactors = FALSE 
	)
# you might want to pay attention to your windows task manager here.
# ipums-international extracts generally require large amounts of ram.
# you can open task manager with (CTRL+SHIFT+ESC) and then click on
# the "performance" tab to see how much ram is currently being consumed
# by this massive ipums-international extract that you're trying to import.

# so, now, if you can make it past this step with your current computer hardware,
# you are likely to be successful completing this script without error.
# if your ipums-international extract was too big and caused a memory error here, however,
# you'll either need to re-create an extract online with fewer columns (requiring less space)
# or you will have to switch over to the monetdb-backed script `download import design into monetdb.R`
# because monetdb does not require that analysis files fit into active working memory.

	
# count the number of lines in the csv file on your local disk
csv_lines <- countLines( csv_file_location )

# compare that file line count to the data.frame object plus one.
stopifnot( csv_lines == nrow( this_df ) + 1 )
# the imported data.frame should have one fewer line than the csv file,
# because the csv file has headers


# almost immediately afterward,
# make every column lowercase	
names( this_df ) <- tolower( names( this_df ) )

# the ipums `rectype` field is almost never useful.
this_df$rectype <- NULL

# personally, i also generally never use the ipums-international country identifier
# or the year of the census
# or the ipums-international unique sample identification number..
this_df <- this_df[ , !( names( this_df ) %in% c( 'country' , 'year' , 'sample' ) ]
# ..and throwing out as many columns as possible while you've got a data.frame
# in active working memory will make your processing move faster.



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

# and at this point, it's a simple (pretty nested) loop.
for ( this_col in seq( vars_to_blank ) ) this_df[ this_df[ , vars_to_blank[ this_col ] ] %in% vals_to_blank[[ this_col ]] , vars_to_blank[ this_col ] ] <- NA

# # # end of manual variable blanking # # #


# create a complex sample design object
this_design <-
	svydesign(
		id = ~ serial ,
		strata = ~ strata ,
		data = this_df ,
		weights = ~ perwt ,
		nest = TRUE
	)

# run your first mean of a linear variable.
svymean( ~ age , this_design )
# voila!

# you now have a
# taylor series linearized
# complex sample survey design object
# ready for analysis

# save the survey design object
save( this_design , file = "survey design in memory.rda" )
