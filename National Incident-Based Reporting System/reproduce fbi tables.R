# analyze survey data for free (http://asdfree.com) with the r language
# national incident-based reporting system
# 2012 populations covered, offense by type, incident by state

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( "monetdb.sequential" = TRUE )		# # only windows users need this line
# library(downloader)
# batfile <- "C:/My Directory/NIBRS/MonetDB/nibrs.bat"		# # note for mac and *nix users: `nibrs.bat` might be `nibrs.sh` instead
# source_url( "https://raw.github.com/ajdamico/usgsd/master/National%20Incident-Based%20Reporting%20System/reproduce%20fbi%20tables.R" , prompt = FALSE , echo = TRUE )
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



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#############################################################################################################################
# prior to running this analysis script, the 2012 national incident-based reporting system files must be imported into a    #
# a monet database on the local machine. before running the dbGetQuery commands below, you must load the data with this:    #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/usgsd/master/National%20Incident-Based%20Reporting%20System/download%20all%20microdata.R  #
#############################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###########################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# warning: numbers do not match published stats precisely #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###########################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# from the FBI UCR Information Dissemination helpdesk - cjis_comm@leo.gov
# The data may be different because the first link is from the FBI UCR Program’s NIBRS publication which is a snapshot in time.
# For example, the 2012 deadline for data to be included in the CIUS publication would have been in March 2013.
# The states/agencies had until the end of 2013 to submit additional data and make adjustments before the master closed early in 2014.   


# from the National Archive of Criminal Justice Data, ICPSR helpdesk - nacjd@icpsr.umich.edu
# One possibility for the numbers not tying out exactly is whether the FBI counts all the agencies in the data.
# For UCR data tables the FBI sometimes only counts agencies that reported for the entire 12 months.
# I would look to see if your counts are larger than the FBI's, and I'd see if the number of agencies you are using is different from the FBI.
# Another possibility is that the FBI can update their data at any time, and we are not always made aware of that.



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


# remove the # in order to run this install.packages line only once
# install.packages( "sqldf" )


library(MonetDB.R)	# load MonetDB.R package (creates database files in R)
library(sqldf)		# load the sqldf package (enables sql queries on data frames)



######################################################################
# lines of code to hold on to for all other `nibrs` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/NIBRS/MonetDB/nibrs.bat"		# # note for mac and *nix users: `nibrs.bat` might be `nibrs.sh` instead

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "nibrs"
dbport <- 50014

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

# lines of code to hold on to for all other `nibrs` monetdb analyses #
######################################################################


# # # # run your analysis commands # # # #


# # # # # # # # # # # # #
# reproducing table one #
# # # # # # # # # # # # #

# Number of Agencies and Population Covered by Population Group, 2012
# http://www.fbi.gov/about-us/cjis/ucr/nibrs/2012/tables/number-of-agencies-and-population-covered-by-population-group-2012


# count the number of originating agency identifiers, including their populations covered and jurisdiction sizes
a <-
	dbGetQuery( 
		db , 
		"SELECT distinct ORI , B2005 as covered_pop , B1009 as city_size FROM x35036_0001"
	)
# store that result into an R `data.frame` object `a`


# create the top row of your final table, store it in an object `tr`
# and print to the screen as well by encapsulating the whole phrase in parentheses
( tr <- sqldf( "SELECT 'overall' as city_cat , COUNT(*) , SUM( covered_pop ) from a" ) )

# find the city category cutoffs from pdf page 33 of the 35036 table codebook
# http://www.icpsr.umich.edu/cgi-bin/file?comp=none&study=35036&ds=0&file_id=1157378&path=NACJD
a$city_cat <- findInterval( a$city_size , c( 20 , 30 , 40 , 50 , 60 , 80 , 90 ) ) + 1

# recode `city_cat` == 1 to `city_cat` == "Group I (Cities 250,000 and over)" and so on..
a$city_cat <- 
	c( 
		"Group I (Cities 250,000 and over)" , 
		"Group II (Cities 100,000 - 249,999)" ,
		"Group III (Cities 50,000 - 99,999)" ,
		"Group IV (Cities 25,000 - 49,999)" ,
		"Group V (Cities 10,000 - 24,999)" ,
		"Group VI (Cities under 10,000)" ,
		"Nonmetropolitan Counties" ,
		"Metropolitan Counties"
	) [ a$city_cat ]
# the above phrase uses a sneaky bracketing trick that's only possible when your codes
# start at the number one and move up in sequential integers.  but when it works, it's beautiful.

# calculate all other rows into an `aor` object
aor <- sqldf( "SELECT city_cat , COUNT(*) , SUM( covered_pop ) FROM a GROUP BY city_cat" )

# stack the top row on top of all other rows,
z <- rbind( tr , aor )

# print the result to the screen
print( z )



# # # # # # # # # # # # #
# reproducing table two #
# # # # # # # # # # # # #

#  Incidents, Offenses, Victims, and Known Offenders by Offense Category, 2012
# http://www.fbi.gov/about-us/cjis/ucr/nibrs/2012/tables/incidents-offenses-victims-and-known-offenders-by-offense-category-2012

# create an R `data.frame` object containing all offense category rows as well as four columns of blanks to be filled in
oc <-
	data.frame( 
		offense.category = c( "Assault Offenses" , "Homicide Offenses" , "Kidnapping/Abduction" , "Sex Offenses, Forcible" , "Sex Offenses, Nonforcible" , "Arson" , "Bribery" , "Burglary/Breaking & Entering" , "Counterfeiting/Forgery" , "Destruction/Damage/Vandalism" , "Embezzlement" , "Extortion/Blackmail" , "Fraud Offenses" , "Larceny/Theft Offenses" , "Motor Vehicle Theft" , "Robbery" , "Stolen Property Offenses" , "Drug/Narcotic Offenses" , "Gambling Offenses" , "Pornography/Obscene Material" , "Prostitution Offenses" , "Weapon Law Violations" ) ,
		incidents = NA ,
		offenses = NA , 
		victims = NA ,
		knownoffenders = NA
	)

# take a look at the empty table
print( oc )
	
# list out the offense codes that will be used for each of those rows in the `oc` table
offense.codes <-
	list( 131:133 , 91:92 , 100 , 111:114 , 361:362 , 200 , 510 , 220 , 250 , 290 , 270 , 210 , 261:265 , 231:238 , 240 , 120 , 280 , 351:352 , 391:394 , 370 , 401:403 , 520 )


# loop through the numbers one through four (the final digit of the x35036_000# table)
for ( i in 1:4 ){

	# loop through each row in the `oc` table
	for ( j in seq( nrow( oc ) ) ){
	
		# construct the current tablename
		tablename <- paste0( "x35036_000" , i )
	
		# fill in the current row (j) and current column (i + 1) with..
		oc[ j , i + 1 ] <- 
			# a monetdb query
			dbGetQuery( 
				db , 
				# that sums up the records where v20061, v20062, or v20063 match the `offense.codes`
				# for the current offense category
				paste( 
					'SELECT 
						sum( ( ( v20061 IN ( ' ,
						paste( offense.codes[[ j ]] , collapse = "," ) ,
						' ) ) OR ( v20062 IN ( ' ,
						paste( offense.codes[[ j ]] , collapse = "," ) ,
						' ) ) OR ( v20063 IN ( ' ,
						paste( offense.codes[[ j ]] , collapse = "," ) ,
						' ) ) ) )
					FROM' ,
					tablename
				)
			)[ 1 , 1 ]
	
	}
	
}

# blazed right through, didn't it?
# monetdb is quite fast on millions of records, huh?
print( oc )



# # # # # # # # # # # # # #
# reproducing table three #
# # # # # # # # # # # # # #

	
# Crimes Against Persons Offenses, Offense Category by State, 2012
# http://www.fbi.gov/about-us/cjis/ucr/nibrs/2012/table-pdfs/crimes-against-persons-offenses-offense-category-by-state-2012


# just print out the entire table using a single, hardcoded but nicely crafted sql command
dbGetQuery( 
	db , 
	"SELECT 
	
		b1008 
			AS stateab ,
		
		COUNT( DISTINCT ori ) 
			AS num_participating_agencies ,
		
		COUNT(*) 
			AS total_incidents ,
		
		SUM( ( ( v20061 IN ( 131 , 132 , 133 , 91 , 92 , 100 , 111 , 112 , 113 , 114 , 361 , 362 ) ) OR 
			( v20062 IN ( 131 , 132 , 133 , 91 , 92 , 100 , 111 , 112 , 113 , 114 , 361 , 362 ) ) OR 
			( v20063 IN ( 131 , 132 , 133 , 91 , 92 , 100 , 111 , 112 , 113 , 114 , 361 , 362 ) ) ) ) 
			AS total_incidents_against_persons , 
		
		SUM( ( ( v20061 IN ( 131 , 132 , 133 ) ) OR 
			( v20062 IN ( 131 , 132 , 133 ) ) OR 
			( v20063 IN ( 131 , 132 , 133 ) ) ) ) 
			AS assault , 
		
		SUM( ( ( v20061 IN ( 91 , 92 ) ) 
			OR ( v20062 IN ( 91 , 92 ) ) 
			OR ( v20063 IN ( 91 , 92 ) ) ) ) 
			AS homicide , 
		
		SUM( ( ( v20061 IN ( 100 ) ) OR 
			( v20062 IN ( 100 ) ) OR 
			( v20063 IN ( 100 ) ) ) ) 
			AS kidnapping , 
		
		SUM( ( ( v20061 IN ( 111 , 112 , 113 , 114 ) ) OR 
			( v20062 IN ( 111 , 112 , 113 , 114 ) ) OR 
			( v20063 IN ( 111 , 112 , 113 , 114 ) ) ) ) 
			AS sex_forcible , 
		
		SUM( ( ( v20061 IN ( 361 , 362 ) ) OR 
			( v20062 IN ( 361 , 362 ) ) OR 
			( v20063 IN ( 361 , 362 ) ) ) ) 
			AS sex_nonforcible 
		
	FROM 
		x35036_0001
	
	GROUP BY 
	
		stateab" 

)



#############################################################################
# end of lines of code to hold on to for all other `nibrs` monetdb analyses #

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other `nibrs` monetdb analyses #
#############################################################################


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
