# analyze survey data for free (http://asdfree.com) with the r language
# national plan and provider enumeration system files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( encoding = "windows-1252" )			# # only macintosh and *nix users need this line
# library(downloader)
# setwd( "C:/My Directory/NPPES/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Plan%20and%20Provider%20Enumeration%20System/replicate%20cms%20state%20counts.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

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


# this r script will create the state x count table available at:
# https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Plan%20and%20Provider%20Enumeration%20System/replication%20of%20CMS-provided%20state%20counts%20from%20PUF.csv

# which replicated the "May 2013" counts table provided to me by
# the centers for medicare and medicaid services (cms), available at:
# https://github.com/ajdamico/asdfree/blob/master/National%20Plan%20and%20Provider%20Enumeration%20System/Public%20File%20May%202013.xlsx?raw=true

# here's some additional detail from the folks at cms regarding this file:
#
# This spreadsheet will contain three tabs. 
# 1. Data in the first tab is provided from the public file which has the breakdown by state.
#	The state for ‘54847’ records are recorded as empty.
#	These ‘54847’ records are the deactivated NPIs.
# 2. Second tab has the data for the ‘54847’ deactivated NPIs with state breakdown.
#	This data was taken from NPPES Production database.
# 3. Third tab is the result of combining data from tabs 1 and 2, which the user is interested in.
#
# Notes:
# 1. Outside analysts cannot reproduce the data provided in the second/third tab
#	as the business requirement only allows limited data for the deactivated records.
# 2. If the users want to categorize these deactivated NPIs (Tab2 data) by deactivation date,
#	they can use the column "NPI Deactivation Date" as a filter only for these records.


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################################
# prior to running this analysis script, the national plan and provider enumeration system must be imported into a monet database   #
# on the local machine. you must run this:                                                                                          #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Plan%20and%20Provider%20Enumeration%20System/download%20and%20import.R  #
#####################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # are you on a non-windows system? # # #
if ( .Platform$OS.type != 'windows' ) print( 'non-windows users: read this block' )
# ibge's ftp site has a few SAS importation
# scripts in a non-standard format
# if so, before running this whole download program,
# you might need to run this line..
# options( encoding="windows-1252" )
# ..to turn on windows-style encoding.
# # # end of non-windows system edits.


library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(MonetDBLite)	# load MonetDBLite package (creates database files in R)


# after running the r script above, users should have handy a few lines
# to initiate and connect to the monet database containing the latest
# national plan and provider enumeration system table.  run them now.  mine look like this:


# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )

# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite() , dbfolder )
# from now on, the 'db' object will be used for r to connect with the monetdb server


# now R has connected to the MonetDB
# seen in the command below stored as the `db` object


# perform a simple count directly from the sql table
# stored inside the monet database on your hard disk
# (as opposed to RAM)
dbGetQuery( db , 'select count(*) from npi' )


# look at all tables in the monet database
dbListTables( db )
# note: `npi` is the only table that's not administrative
# all other tables shown here come standard with MonetDB

# look at all of the field names of the `npi` table
dbListFields( db , 'npi' )
# note: this is similar to running the names()
# function on an R data.frame object


# run a more complex sql SELECT query
# that provides counts of practice locations by state
# ordered by the number of records

# the results are saved into a new data.frame object `z`..
z <- 
	dbGetQuery( 
		db , 
		'select 
			provider_business_practice_location_address_state_name , 
			count(*) as count 
		from 
			npi 
		group by 
			provider_business_practice_location_address_state_name 
		order by 
			count 
			desc' 
	)


# ..which can then be viewed immediately..

# look at the first six records
head( z )

# look at the last six records
tail( z )

# ..or exported as a comma-separated value file 
# into your current working directory 
write.csv( z , "counts by state.csv" )
	

# disconnect from the current monet database
dbDisconnect( db )


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
