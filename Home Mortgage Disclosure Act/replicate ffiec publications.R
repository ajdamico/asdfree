# analyze survey data for free (http://asdfree.com) with the r language
# home mortgage disclosure act
# 2006 - 2011 files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# batfile <- "C:/My Directory/HMDA/MonetDB/hmda.bat"
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Home%20Mortgage%20Disclosure%20Act/replicate%20ffiec%20publications.R" , prompt = FALSE , echo = TRUE )
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


# this r script will replicate statistics found in various
# federal financial institutions examination council (ffiec) publications
# and match the output exactly


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################################################
# prior to running this analysis script, the hmda public use files must be imported into a monet database on the local machine. you must run this:  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/usgsd/master/Home%20Mortgage%20Disclosure%20Act/download%20all%20microdata.R                                      #
#####################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # #
# warning: monetdb required #
# # # # # # # # # # # # # # #


require(MonetDB.R)	# load the MonetDB.R package (connects r to a monet database)


# after running the r script above, users should have handy a few lines
# to initiate and connect to the monet database containing the
# hmda public use files.  run them now.  mine look like this:



################################################################################
# lines of code to hold on to for the start of all other hmda monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/HMDA/MonetDB/hmda.bat"

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "hmda"
dbport <- 50005

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url )

# end of lines of code to hold on to for all other hmda monetdb analyses #
##########################################################################



# list all tables available in the current monet database
dbListTables( db )

# list all fields in the `hmda_11` table in the current monet database
dbListFields( db , 'hmda_11' )

# construct a sql command that shows the number of records broken down by each of three columns
sql <-
	'select 
		actiontype , 
		propertytype, 
		loanpurpose, 
		count(*) as num_records 
	from 
		hmda_11 
	group by 
		actiontype , 
		propertytype, 
		loanpurpose' 
# for more detail about how to construct sql queries,
# check out http://www.w3schools.com/sql/default.asp


# print aggregate statistics, broken out by three columns in the data
dbGetQuery( db , sql )
# see this result data.frame that printed to your screen?
# it's one record per: actiontype x propertytype x loanpurpose
# combination in the whole data table, with the number of records
# of each combo as the final column.  powerful.


# initiate an empty data.frame object
out <- data.frame( NULL )

# loop through the years 2006 - 2011
for ( i in c( '06' , '07' , '08' , '09' , '10' , '11' ) ){

	# construct the same sql query as above, but for all years stated above
	sql <- 
		paste0( 
			'select actiontype , propertytype , loanpurpose , count(*) as num_records from hmda_' , 
			i , 
			' group by actiontype , propertytype , loanpurpose order by actiontype , propertytype , loanpurpose' 
		)
	
	# initiate the actual sql string
	z <- dbGetQuery( db , sql )
	
	# combine all queried valued into a single row of data
	stats <-
		cbind(
			# home purchases
			sum( subset( z , actiontype %in% 1:5 & propertytype %in% 1:2 & loanpurpose %in% 1 )$num_records ) ,
			# refinance
			sum( subset( z , actiontype %in% 1:5 & propertytype %in% 1:2 & loanpurpose %in% 3 )$num_records ) ,
			# home improvement
			sum( subset( z , actiontype %in% 1:5 & propertytype %in% 1:2 & loanpurpose %in% 2 )$num_records ) ,
			# multifamily
			sum( subset( z , actiontype %in% 1:5 & propertytype %in% 3 )$num_records ) ,
			# requests for preapproval
			sum( subset( z , actiontype %in% 7:8 )$num_records ) ,
			# purchased loans
			sum( subset( z , actiontype %in% 6 )$num_records )
		)

	# add a column containing the current year in front of these other rows
	s <- data.frame( i , stats )

	# stack the current year below the other years
	out <- rbind( out , s )
}

# rename all columns in the outputted data frame to match table 3 A
names( out ) <- c( 'year' , 'home.purchase' , 'refinance' , 'home.improvement' , 'multifamily' , 'requests.for.preapproval' , 'purchased.loans' )

# the data.frame `out` now matches table 3 A
out
# note that the 2008 and 2011 rows match this table 3 A:
# http://www.federalreserve.gov/pubs/bulletin/2012/PDF/2011_HMDA.pdf#page=6
# but in order to see matches for 2009 and 2010, you have to look at the old table:
# http://www.federalreserve.gov/pubs/bulletin/2011/pdf/2010_HMDA_final.pdf#page=6
# those rows match exactly!  2006 and 2007 don't match at all.



# just like r, sql - structured query language - is ultra-flexible too
# construct an entire table in sql

# here's the construction to correctly calculate each of the values in the 2011 row
# in table 3 b on the bottom of pdf page 6 of this document:
# http://www.federalreserve.gov/pubs/bulletin/2012/PDF/2011_HMDA.pdf#page=6
sql <-
	'select 
		sum( ( loanpurpose = 1 AND propertytype IN ( 1 , 2 ) ) ) as home_purchase ,
		sum( ( loanpurpose = 3 AND propertytype IN ( 1 , 2 ) ) ) as refinance ,
		sum( ( loanpurpose = 2 AND propertytype IN ( 1 , 2 ) ) ) as home_improvement ,
		sum( ( propertytype = 3 ) ) as multifamily ,
		count( * ) as total
	from 
		hmda_11 
	where 
		actiontype = 1'

# actually run the command and print the results to the screen
dbGetQuery( db , sql )

# re-create the sql command above, but for 2006 - 2011
sql <-
	paste0(
		'select 
			sum( ( loanpurpose = 1 AND propertytype IN ( 1 , 2 ) ) ) as home_purchase ,
			sum( ( loanpurpose = 3 AND propertytype IN ( 1 , 2 ) ) ) as refinance ,
			sum( ( loanpurpose = 2 AND propertytype IN ( 1 , 2 ) ) ) as home_improvement ,
			sum( ( propertytype = 3 ) ) as multifamily ,
			count( * ) as total
		from 
			hmda_' ,
		c( '06' , '07' , '08' , '09' , '10' , '11' )
		,
		' where 
			actiontype = 1'
	)
# this gives *six* different character strings (in a character vector)
# collapse them all together into a single sql command, separated by UNIONs..
union.sql <- paste( sql , collapse = " UNION " )

# and you're done!  encapsulate the whole statement in parentheses
# to both create the `out` data.frame and print the result to the screen
( out <- dbGetQuery( db , union.sql ) )

# okay, maybe add rownames
rownames( out ) <- 2006:2011

# same deal as before.
out
# that the 2008 and 2011 rows match this table 3 B:
# http://www.federalreserve.gov/pubs/bulletin/2012/PDF/2011_HMDA.pdf#page=6
# but in order to see matches for 2009 and 2010, you have to look at the old table:
# http://www.federalreserve.gov/pubs/bulletin/2011/pdf/2010_HMDA_final.pdf#page=6
# those rows match exactly!  2006 and 2007 don't match at all.


# # # # # # # # # # # # # # # # # # #
# race/ethnicity replication counts #

# nearly replicate table 14's race and ethnicity breakdowns of loan numbers
# (along the righthand side of the 2011 table on pdf page 28 of the latest report)
# http://www.federalreserve.gov/pubs/bulletin/2012/pdf/2011_HMDA.pdf#page=28

# for the _race other than white only_ category,
# produce the aian, asian, black, and naopi values.
# note that a few of these are off by less than ten records.  who cares.
dbGetQuery( db , 'select race , count(*) from hmda_11 where actiontype = 1 AND loanpurpose = 1 AND occupancy = 1 AND lienstatus = 1 AND propertytype IN ( 1 , 2 ) group by race order by race' )

# for the _white, by ethnicity_ category,
# produce the white non-hispanic number on its own
# and then joint plus hispanic misses the published number by two.
dbGetQuery( db , 'select ethnicity , count(*) from hmda_11 where actiontype = 1 AND loanpurpose = 1 AND occupancy = 1 AND lienstatus = 1 AND propertytype IN ( 1 , 2 ) AND race = 5 group by ethnicity order by ethnicity' )


# if you really really care why it's off by a few records, here's the sas script from the ffiec.  have fun!
# https://raw.github.com/ajdamico/usgsd/master/Home%20Mortgage%20Disclosure%20Act/bulletin_macros_postbob.sas


# race/ethnicity replication counts #
# # # # # # # # # # # # # # # # # # #


##############################################################################
# lines of code to hold on to for the end of all other hmda monetdb analyses #

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other hmda monetdb analyses #
##########################################################################

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
