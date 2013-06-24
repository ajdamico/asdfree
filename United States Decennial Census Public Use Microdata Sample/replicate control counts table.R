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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###################################################################################################################################################
# prior to running this analysis script, the 1% and 5% public use microdata samples from the 2000 census must be loaded on the local machine with #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/usgsd/master/United%20States%20Decennial%20Census%20Public%20Use%20Microdata%20Sample/download%20and%20import.R #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# ..that script will place a 'MonetDB' folder on the local drive containing the appropriate data tables for this code to work properly.           #
###################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


#############################################################################
# this script matches the unweighted and weighted totals shown in the       #
# census document: http://www.census.gov/prod/cen2000/doc/pums.pdf#page=645 #
#############################################################################


require(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)

# after running the r script above, users should have handy a few lines
# to initiate and connect to the monet database containing all public use microdata sample tables
# run them now.  mine look like this:


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


# # # # # sql-based analysis starts here # # # # #

# 1-percent pums file household counts by state
dbGetQuery( 
	db , 
	'select 
		state ,
		count( * ) as household_unweighted ,
		sum( hweight ) as household_weighted
	from
		pums_2000_1_h
	group by
		state'
)

# 1-percent pums file person counts by state
dbGetQuery( 
	db , 
	'select 
		state ,
		count( * ) as person_unweighted ,
		sum( pweight ) as person_weighted
	from
		pums_2000_1_m
	group by
		state'

)

# 5-percent pums file household counts by state
dbGetQuery( 
	db , 
	'select 
		state ,
		count( * ) as household_unweighted ,
		sum( hweight ) as household_weighted
	from
		pums_2000_5_h
	group by
		state'

)

# 5-percent pums file person counts by state
dbGetQuery( 
	db , 
	'select 
		state ,
		count( * ) as person_unweighted ,
		sum( pweight ) as person_weighted
	from
		pums_2000_5_m
	group by
		state'
)

# # # # # sql-based analysis ends here # # # # #

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other `brfss` monetdb analyses #
#############################################################################


# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
