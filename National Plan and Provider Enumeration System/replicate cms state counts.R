# analyze survey data for free (http://asdfree.com) with the r language
# national plan and provider enumeration system files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# batfile <- "C:/My Directory/NPPES/nppes.bat"
# source_url( "https://raw.github.com/ajdamico/usgsd/master/National%20Plan%20and%20Provider%20Enumeration%20System/replicate%20cms%20state%20counts.R" , prompt = FALSE , echo = TRUE )
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


# this r script will create the state x count table available at:
# https://raw.github.com/ajdamico/usgsd/master/National%20Plan%20and%20Provider%20Enumeration%20System/replication%20of%20CMS-provided%20state%20counts%20from%20PUF.csv

# which replicated the "May 2013" counts table provided to me by
# the centers for medicare and medicaid services (cms), available at:
# https://github.com/ajdamico/usgsd/blob/master/National%20Plan%20and%20Provider%20Enumeration%20System/Public%20File%20May%202013.xlsx?raw=true

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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###################################################################################################################################
# prior to running this analysis script, the national plan and provider enumeration system must be imported into a monet database #
# on the local machine. you must run this:                                                                                        #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/usgsd/master/National%20Plan%20and%20Provider%20Enumeration%20System/download%20and%20import.R  #                                        #
###################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # #
# warning: monetdb required #
# # # # # # # # # # # # # # #


library(MonetDB.R)	# load the MonetDB.R package (connects r to a monet database)


# after running the r script above, users should have handy a few lines
# to initiate and connect to the monet database containing the latest
# national plan and provider enumeration system table.  run them now.  mine look like this:



####################################################################
# lines of code to hold on to for all other nppes monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/NPPES/nppes.bat"

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "nppes"
dbport <- 50006

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

# end of lines of code to hold on to for all other nppes monetdb analyses #
###########################################################################



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
	


# # # # # # # # # # # # # # # #
# create a monet.frame object #
# # # # # # # # # # # # # # # #

# initiate a monet.frame object,
# which in many ways behaves
# like an R data.frame
x <- monet.frame( db , 'npi' )
# for more detail about and
# example usage cases of monet.frame objects,
# type ?monet.frame into the console


# note: the entire nppes data table is too large to entirely load onto a computer with 4GB of RAM
# however, pulling only certain columns into your computer's RAM at once should load properly



# extraction based on column _numbers_ #

# create an R data.frame object `y` from the monet.frame object `x`
# pulling the first ten columns of the data table
# and removing the RAM-related warning.
y <- 
	as.data.frame( 
		x[ , c( 1:2 , 31:32 , 37 ) ] , 
		warnSize = FALSE 
	)

# from here, a table comparable to the object `z` above
# can simply be printed directly to the screen
# using the base R `table` function
table( y$provider_business_practice_location_address_state_name )

# remove `y` from RAM
rm( y ) ; gc()


# extraction based on column _names_ #

vars.to.keep <- 
	c( 'npi' , 'entity_type_code' , 'provider_business_practice_location_address_city_name' ,
		'provider_business_practice_location_address_state_name' , 'provider_enumeration_date' )

# create an R data.frame object `y` from the monet.frame object `x`
# pulling the first ten columns of the data table
# and removing the RAM-related warning.
y <- 
	as.data.frame( 
		x[ , vars.to.keep ] , 
		warnSize = FALSE 
	)

# from here, a table comparable to the object `z` above
# can simply be printed directly to the screen
# using the base R `table` function
table( y$provider_business_practice_location_address_state_name )

# remove `y` from RAM
rm( y ) ; gc()


###########################################################################
# end of lines of code to hold on to for all other nppes monetdb analyses #

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other nppes monetdb analyses #
###########################################################################

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
