# analyze us government survey data with the r language
# american community survey
# 2010 persons and household files

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



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################################
# prior to running this analysis script, the acs 2010 single-year file must be loaded as a database (.db) on the local machine.     #
# running the "download all microdata" script will create this database file - only the 2010 single-year db needs to be downloaded  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/usgsd/blob/master/American%20Community%20Survey/2000-2011%20-%20download%20all%20microdata.R          #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "acs2010_1yr.db" in C:/My Directory/ACS or wherever the working directory was set for the program  #
#####################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# set your working directory.
# this directory must contain the ACS 2010 database (.db) file 
# "acs2010_1yr.db" created by the R program specified above
# use forward slashes instead of back slashes

setwd( "C:/My Directory/ACS/" )


# remove the # in order to run this install.packages line only once
# install.packages( c( "survey" , "RSQLite" ) )


require(survey)		# load survey package (analyzes complex design surveys)
require(RSQLite) 	# load RSQLite package (creates database files in R)


# set R to produce conservative standard errors instead of crashing
# http://faculty.washington.edu/tlumley/survey/exmample-lonely.html
# options( survey.lonely.psu = "adjust" )


# if this option is set to TRUE
# R will exactly match SUDAAN results and Stata with the MSE option results
options( survey.replicates.mse = TRUE )
# otherwise if it is commented out or set to FALSE
# R will exactly match Stata without the MSE option results

# Stata svyset command notes can be found here: http://www.stata.com/help.cgi?svyset



# choose which file to analyze: one-year, three-year, or five-year file
# this script replicates 2010 single-year estimates,
# so leave that line uncommented and the other two choices commented out

fn <- 'acs2010_1yr' 		# analyze the 2010 single-year acs
# fn <- 'acs2010_3yr'		# analyze the 2008-2010 acs
# fn <- 'acs2010_5yr'		# analyze the 2006-2010 acs



# immediately connect to the SQLite database
# this connection will be stored in the object 'db'
db <- dbConnect( SQLite() , dbname = paste0( fn , ".db" ) )


# choose which file to analyze: merged, person-level, or household-level
# most analyses should use the merged file, since it contains
# one record per individual person, but also household information
# so leave that line uncommented and the other two choices commented out

tn <- '_m'					# analyze the merged file
# tn <- '_p'				# analyze the person-level file
# tn <- '_h'				# analyze the household-level file



# create a string containing the table of interest,
# stored inside the acs2010_#yr.db file on your local computer
sqltable <- paste0( fn , tn )


# SQL commands get passed as a character string, so
# prepare the exact character string that should be sent to the database (.db)
# use the sqltable string to identify the appropriate table name
# just print the string to the screen for testing.
paste0( "select * from " , sqltable , " limit 6" )


# run that simple command to test out the connection --
# this command sends the SQL query (passed as a character string)
# to the database connection. notice the 'limit 6' -- 
# this SQL command replicates a head( x ) command, printing the first six records of the table
dbGetQuery( db , paste0( "select * from " , sqltable , " limit 6" ) )


# alternatively, by setting the number of record limit to zero,
# this command simply prints the column names of sqltable, like names( x )
dbGetQuery( db , paste0( "select * from " , sqltable , " limit 0" ) )



############################
# variable recode examples #
############################

# due to RAM limitations, recodes to tables stored in SQL database (.db) files
# must be performed on the SQL table itself, as opposed to a temporary object.
# rather than using the transform() function on an R data frame
# or the update() function on an R survey design object, 
# tables stored in SQL can be recoded with an UPDATE statement inside a SQL query


########################################
# add a column "one" containing all 1s #
########################################

# here are three SQLite UPDATE commands (stored as character strings)
# that can be passed to the database (.db) to make a (permanent!) change to the table
# the first command creates a new column called 'one'
# the second command modifies the one column, adding 1s for every record
( first.command <- paste0( "ALTER TABLE " , sqltable , " ADD one" ) )
( second.command <- paste0( "UPDATE " , sqltable , " SET one = 1" ) )
# running the above two lines only creates a string variable..
# ..and prints the lines to the screen.
# the table within the database has not yet been modified


# these two lines of R code actually send the SQL commands to the database
# note that since each command updates millions of records,
# these lines run slowly.  if you're impatient, buy a solid-state hard drive.
dbGetQuery( db , first.command )		# add the 'one' column
dbGetQuery( db , second.command )		# recode all records' column 'one' to 1



######################
# add a "child" flag #
######################

# here are three SQLite UPDATE commands (stored as character strings)
# that can be passed to the database (.db) to make a (permanent!) change to the table
# the first command creates a new column called 'child'
# the second command modifies the child column, adding zeroes for records with AGEP >= 19, 
# the third command also modifies the child column, adding ones for records with AGEP < 19
( first.command <- paste0( "ALTER TABLE " , sqltable , " ADD child" ) )
( second.command <- paste0( "UPDATE " , sqltable , " SET child = 0 WHERE AGEP >= 19" ) )
( third.command <- paste0( "UPDATE " , sqltable , " SET child = 1 WHERE AGEP < 19" ) )
# running the above three lines only creates a string variable..
# ..and prints the lines to the screen.
# the table within the database has not yet been modified


# these three lines of R code actually send the SQL commands to the database
# note that since each command updates millions of records,
# these lines run slowly.  if you're impatient, buy a solid-state hard drive.
dbGetQuery( db , first.command )		# add the child column
dbGetQuery( db , second.command )		# recode AGEP >= 19 records to child = 0
dbGetQuery( db , third.command )		# recode AGEP < 19 records to child = 1


# check the new variable by running simple counts on the table #
dbGetQuery( db , paste0( "SELECT child, AGEP , count(*) as counts FROM " , sqltable , " GROUP BY child, AGEP ORDER BY AGEP" ) )



######################
# add age categories #
######################


# example of a linear recode with multiple categories, and a loop to perform each recode quickly

original.variable.name <- 'AGEP'								# variable to recode from	

cutpoints <- 
	c( -1 , 10 , 19 , 25 , 35 , 45 , 55 , 65 , 75 , 85 , 100 )	# points to split the variable

new.variable.name <- 'agecat'									# new variable to create


# step one: add the column

( first.command <- paste0( "ALTER TABLE " , sqltable , " ADD " , new.variable.name ) )
dbGetQuery( db , first.command )


# step two: loop through each cutpoint (except the last, because no category label is needed for AGEP >= 100)
for ( i in 1:( length( cutpoints ) - 1 ) ){


	# print a counter to the screen
	cat( 
		'     currently creating category' , 
		i , 
		'of' , 
		new.variable.name , 
		'from' , 
		original.variable.name , 
		'with' , 
		( length( cutpoints ) - 1 ) , 
		'distinct categories' , 
		'\r'
	)

	
	# step three: create the specific category (still just a character string)
	
	( second.command <- 
		paste0( 
			"UPDATE " , 
			sqltable , 
			" SET " , 
			new.variable.name , 
			" = " , 
			i , 
			" WHERE " , 
			original.variable.name , 
			" BETWEEN " , 					# notice the BETWEEN operator ( http://www.w3schools.com/sql/sql_between.asp )
			cutpoints[ i ] , 				# acts as INCLUSIVE on both sides
			" AND " , 						# in RSQLite.  therefore,
			cutpoints[ i + 1] - 1			# subtract one from the upper bound to prevent overlapping age categories.
		) 
	)
	
	
	# step four: send the character string command to the database
	
	dbGetQuery( db , second.command )		# recode AGEP >= cutpoints[ i ] AND AGEP <= ( cutpoints[ i + 1 ] - 1 ) records to agecat = i

}

# check the new variable by running simple counts on the table #
dbGetQuery( 
	db , 
	paste0( 
		"SELECT " , 
		new.variable.name , 
		" , " , 
		original.variable.name , 
		" , count(*) as counts FROM " , 
		sqltable , 
		" GROUP BY " , 
		new.variable.name , 
		" , " , 
		original.variable.name 
	) 
)


###################################
# end of variable recode examples #
###################################



# using a database-backed survey object
# (described here: http://faculty.washington.edu/tlumley/survey/svy-dbi.html )
# create the american community survey 2010 single-year design


# choose between the RAM-intensive survey object (with correct standard errors)
# or the RAM-minimizing survey object (with incorrect standard errors)

#######################################################################
# this svrepdesign() call uses RAM-hogging code (requires about 11GB) #
# and includes the correct standard error computations in the output  #
# if using a less-powerful computer, skip this next block and         #
# uncomment the following one to compute statistics only (no errors)  #
#######################################################################


acs.10.m.design <- 									# name the survey object
	svrepdesign(									# svrepdesign function call.. type ?svrepdesign for more detail
		weights = ~PWGTP, 							# person-level weights are stored in column "PWGTP"
		repweights = "pwgtp[0-9]" ,					# the acs contains 80 replicate weights, pwgtp1 - pwgtp80.  this [0-9] format captures all numeric values
		type = "Fay", 								# use a fay's adjustment of four..  
		rho = ( 1 - 1 / sqrt( 4 ) ),				# ..note that these two lines are the SUDAAN equivalent of using adjfay = 4;
		data = paste0( fn , '_m' ) , 				# use the person-household-merge data table
		dbname = paste0( './' , fn , '.db' ) , 		# stored inside the database (acs2010_1yr.db)
		dbtype="SQLite"								# use SQLite as the SQL engine
	)

# end of database-backed survey object creation #
	

###########################################################################
# this svydesign() call minimizes RAM usage but will produce incorrect    #
# standard errors (SEs) for all subsequent analyses.                      #
# if you think buying 11GB of RAM is expensive, try buying a SAS license. #
###########################################################################


# acs.10.m.design <- 									# name the survey object
	# svydesign(										# svydesign function call.. type ?svydesign for more detail
		# ~1 ,											# specify non-existent PSUs (responsible for incorrect SE calculation)
		# weights = ~PWGTP, 							# person-level weights are stored in column "PWGTP"
		# data = paste0( fn , '_m' ) , 					# use the person-household-merge data table
		# dbname = paste0( './' , fn , '.db' ) , 		# stored inside the database (acs2010_1yr.db)
		# dbtype="SQLite"								# use SQLite as the SQL engine
	# )

# end of low-RAM, incorrect-SE database-backed survey object creation #	


	
#####################
# analysis examples #
#####################


# count the total (unweighted) number of records in acs #

# simply use the nrow function..
nrow( acs.10.51.m.design )

# ..on the survey design object
class( acs.10.51.m.design )


# since the acs gets loaded as a database-backed survey object instead of a data frame,
# the number of unweighted records cannot be calculated by running the nrow() function on a data frame.

# running the nrow() function on the database connection object
# simply produces an error..
# nrow( db )

# because the database (.db) file might contain multiple data tables
class( db )


# instead, perform the same unweighted count directly from the 'sqltable'
# stored inside the database (.db) file on your hard disk (as opposed to RAM)..

# ..and note that the exclusion of puerto rico means that the survey design object (acs.10.51.m.design)
# no longer matches the original data table 'sqltable'..
dbGetQuery( db , paste0( "select count(*) as num_records from " , sqltable ) )

# ..to run unweighted analyses, the 'sqltable' must be limited
# with a WHERE statement that directly removes puerto rico records
dbGetQuery( db , paste0( "select count(*) as num_records from " , sqltable ) )

	

# count the total (unweighted) number of records in acs #
# broken out by state #

# note the choice of 'one' field here is mostly arbitrary.
# so long as the first field has no missings (one has the value of 1 for every record)
# and the second field designates how to break out the table (by state: ~ST)
# the unwtd.count() option will work within the svyby()

svyby(
	~one ,
	~ST ,
	acs.10.51.m.design ,
	unwtd.count
)

# also note that this command can be exactly replicated with a SQL query instead.
# first save the command (as a character string) into by.state.command,
# and also print it to the screen by putting parentheses around the whole thing..
( by.state.command <- paste0( "select ST, count(*) as num_records from " , sqltable , " GROUP BY ST" ) )

# ..then actually run the command on the database (.db) file
dbGetQuery( db , by.state.command )



# count the weighted number of individuals in acs #

# the population of the united states (including group quarters residents: both institionalized and non-institutionalized) #
svytotal( 
	~one ,
	acs.10.51.m.design 
)

# note that this is exactly equivalent to summing up the weight variable
# from the original database (.db) file connection

# prepare the command..
( sum.weights.command <- paste0( "select sum( PWGTP ) as sum_weights from " , sqltable ) )

# ..and run it.
dbGetQuery( db , sum.weights.command )


# the population of the united states #
# by state
svyby(
	~one ,
	~ST ,
	acs.10.51.m.design ,
	svytotal
)


# calculate the mean of a linear variable #

# average age - nationwide
svymean( 
	~AGEP , 
	design = acs.10.51.m.design
)

# by state
svyby( 
	~AGEP , 
	~ST ,
	design = acs.10.51.m.design ,
	svymean
)


# calculate the distribution of a categorical variable #

# HICOV should be treated as a factor (categorical) variable
# instead of a numeric (linear) variable,
# even though it only contains the values 1 and 2
# placing it inside the factor() function converts it on the fly

# percent uninsured - nationwide
svymean( 
	~factor( HICOV ) , 
	design = acs.10.51.m.design
)

# by state
svyby( 
	~factor( HICOV ) , 
	~ST ,
	design = acs.10.51.m.design ,
	svymean
)

# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum 
# ages of residents of the united states
svyquantile( 
	~AGEP , 
	design = acs.10.51.m.design ,
	c( 0 , .25 , .5 , .75 , 1 )
)

# by state
svyby( 
	~AGEP , 
	~ST ,
	design = acs.10.51.m.design ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) , 
	ci = T
)

######################
# subsetting example #
######################

# restrict the acs.10.51.m.design object to
# females only
acs.10.51.m.design.female <-
	subset(
		acs.10.51.m.design ,
		SEX %in% 2
	)
# now any of the above commands can be re-run
# using the acs.10.51.m.design.female object
# instead of the acs.10.51.m.design object
# in order to analyze females only
	
# calculate the mean of a linear variable #

# average age - nationwide, restricted to females
svymean( 
	~AGEP , 
	design = acs.10.51.m.design.female
)



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by region of the country

# store the results into a new object

coverage.by.region <-
	svyby( 
		~factor( HICOV ) , 
		~REGION ,
		design = acs.10.51.m.design ,
		svymean
	)

# print the results to the screen 
coverage.by.region

# now you have the results saved into a new object of type "svyby"
class( coverage.by.region )

# print only the statistics (coefficients) to the screen 
coef( coverage.by.region )

# print only the standard errors to the screen 
SE( coverage.by.region )
# remember: standard errors will be incorrect unless
# the survey object was created with the RAM-hogging method

# this object can be coerced (converted) to a data frame.. 
coverage.by.region <- data.frame( coverage.by.region )

# ..and then immediately exported as a comma-separated value file 
# into your current working directory 
write.csv( coverage.by.region , "coverage by region.csv" )

# ..or trimmed to only contain the values you need.
# here's the uninsured percentage by region, 
# with accompanying standard errors
uninsured.rate.by.region <-
	coverage.by.region[ , c( "REGION" , "factor.HICOV.2" , "se2" ) ]


# print the new results to the screen
uninsured.rate.by.region

# this can also be exported as a comma-separated value file 
# into your current working directory 
write.csv( uninsured.rate.by.region , "uninsured rate by region.csv" )

# ..or directly made into a bar plot
barplot(
	uninsured.rate.by.region[ , 2 ] ,
	main = "Uninsured Rate by Region of the Country" ,
	names.arg = c( "Northeast" , "Midwest" , "South" , "West" ) ,
	ylim = c( 0 , .25 )
)

# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
