# analyze survey data for free (http://asdfree.com) with the r language
# united states decennial census
# public use microdata sample
# 1990 , 2000

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( "monetdb.sequential" = TRUE )		# # only windows users need this line
# library(downloader)
# batfile <- "C:/My Directory/PUMS/MonetDB/pums.bat"		# # note for mac and *nix users: `pums.bat` might be `pums.sh` instead
# load( 'C:/My Directory/PUMS/pums_2000_5_m.rda' )	# analyze the 2000 5% pums file
# source_url( "https://raw.github.com/ajdamico/usgsd/master/United%20States%20Decennial%20Census%20Public%20Use%20Microdata%20Sample/2000%20analysis%20examples.R" , prompt = FALSE , echo = TRUE )
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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###################################################################################################################################################
# prior to running this analysis script, the 1% and 5% public use microdata samples from the 2000 census must be loaded on the local machine with #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/usgsd/master/United%20States%20Decennial%20Census%20Public%20Use%20Microdata%20Sample/download%20and%20import.R #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# ..that script will place a 'MonetDB' folder on the local drive containing the appropriate data tables for this code to work properly.           #
###################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

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

# # # # # # # # # # # # # #
# warning warning warning #
# # # # # # # # # # # # # #

# the statistics (means, medians, sums, totals, percentiles, distributions) shown using the method below are correct.
# the errors (standard errors, standard deviations, variances, confidence intervals, significance tests) are not.

# to calculate error terms / confidence intervals the census-approved way, the only current option is to follow this
# hellishly-cumbersome document where you have to multiply stuff by hand and calculate SEs for each and every statistic.
# it. is. a. nightmare.
# here's the year 2000 version:
# http://www.census.gov/prod/cen2000/doc/pums.pdf#page=18
# here's the 1990 census version:
# http://www2.census.gov/prod2/decennial/documents/D1-D90-PUMS-14-TECH-01.pdf#page=36

# when i compared these generalized variance formulas to the un-survey-design-adjusted standard errors,
# i found that they were pretty consistently just twice as big.  here's more detail..
# http://www.asdfree.com/search/label/new%20york%20city%20housing%20and%20vacancy%20survey%20%28nychvs%29
# ..so if you want a rough guess, just multiply the standard errors created by this program by two.  but it's unscientific..

# you could also attempt to copy the university of minnesota's minnesota population center method
# but that would involve merging on their STRATA and CLUSTER variable from their extracts.
# https://usa.ipums.org/usa/complex_survey_vars/strata_historical.shtml

# case and point: for the 1990 and 2000 united states decennial census public use microdata samples,
# you cannot _automate_ the calculation of standard errors if you want to use the _official_ census method.  sowwy.

# one more note: you can generally add standard errors to sqlsurvey output by adding the se = TRUE parameter
# svymean( ~variable , design , se = TRUE )
# svytotal( ~variable , design , se = TRUE )


library(sqlsurvey)		# load sqlsurvey package (analyzes large complex design surveys)


# after running the r script above, users should have handy a few lines
# to initiate and connect to the monet database containing all public use microdata sample tables
# run them now.  mine look like this:


############################################################################
# lines of code to hold on to for all other `PUMS` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/PUMS/MonetDB/pums.bat"		# # note for mac and *nix users: `pums.bat` might be `pums.sh` instead

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "pums"
dbport <- 50010

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )


# # # # run your analysis commands # # # #


# the public use microdata sample download and importation script
# has already created a monet database-backed survey design object
# connected to the 2000 single-year table

# sqlite database-backed survey objects are described here: 
# http://r-survey.r-forge.r-project.org/survey/svy-dbi.html
# monet database-backed survey objects are similar, but:
# the database engine is, well, blazingly faster
# the setup is kinda more complicated (but all done for you)

# since this script only loads one file off of the local drive,
# there's no need to set the working directory.
# instead, simply use the full filepath to the r data file (.rda)
# as shown in the load() examples below.


# choose which pums file in your PUMS directory to analyze

# load the desired public use microdata sample monet database-backed complex sample design object

# uncomment the correct line by removing the `#` at the front..
# load( 'C:/My Directory/PUMS/pums_1990_1_m.rda' )	# analyze the 1990 1% pums file
# load( 'C:/My Directory/PUMS/pums_1990_5_m.rda' )	# analyze the 1990 5% pums file
# load( 'C:/My Directory/PUMS/pums_2000_1_m.rda' )	# analyze the 2000 1% pums file
# load( 'C:/My Directory/PUMS/pums_2000_5_m.rda' )	# analyze the 2000 5% pums file

# note: this r data file should already contain the 2000 5% design


# connect the complex sample design to the monet database #
pums.design <- open( pums.m.design , driver = MonetDB.R() , wait = TRUE )	# merged design




################################################
# ..and immediately start the example analyses #
################################################

# count the total (unweighted) number of records in pums #

# simply use the nrow function..
nrow( pums.design )

# ..on the sqlsurvey design object
class( pums.design )


# since the pums gets loaded as a monet database-backed survey object instead of a data frame,
# the number of unweighted records cannot be calculated by running the nrow() function on a data frame.

# running the nrow() function on the database connection object
# simply produces an error..
# nrow( db )

# because the monet database might contain multiple data tables
class( db )


# instead, perform the same unweighted count directly from the sql table
# stored inside the monet database on your hard disk (as opposed to RAM)
dbGetQuery( db , "SELECT COUNT(*) AS num_records FROM pums_2000_5_m" )

	

# count the total (unweighted) number of records in pums #
# broken out by state #

# note: this is easiest by simply running a sql query on the monet database directly
dbGetQuery( db , "SELECT state , COUNT(*) as num_records FROM pums_2000_5_m GROUP BY state ORDER BY state" )



# count the weighted number of individuals in pums #

# the population of the united states #
# note that this should be calculated by summing up the weight variable
# from the original database (.db) file connection
dbGetQuery( db , "SELECT SUM( pweight ) AS sum_weights FROM pums_2000_5_m" )


# the population of the united states #
# by state
dbGetQuery( db , "SELECT state , SUM( pweight ) AS sum_weights FROM pums_2000_5_m GROUP BY state ORDER BY state" )
# note: the above command is one example of how the r survey package differs from the r sqlsurvey package


# calculate the mean of a linear variable #

# average age - nationwide
svymean( ~age , pums.design )

# try this by state..
problem <- try( svymean( ~age , pums.design , byvar = ~state ) , silent = TRUE )

# ..but:
if( class( problem ) == 'try-error' ) print( "this resulted in an error because it's too big of a query" )

# break it up into smaller queries
all.states <- dbGetQuery( db , 'select distinct state from pums_2000_5_m' )[ , 1 ]

# loop through each state..
for ( this.state in all.states ){

	# construct the entire query as a string (this is generally not recommended)
	svy.string <- 
		paste( 
			"svymean( ~ age , subset( pums.design , ( state ==" ,
			this.state ,
			") ) )"
		)
		
	# manually evaluate the string
	print( eval( parse( text = svy.string ) ) )

}


# calculate the distribution of a categorical variable #

# MARSTAT has been converted to a factor (categorical) variable
# instead of a numeric (linear) variable,
# because it only contains the values 1-5
# when the pums.design object was created with the function sqlrepdesign()
# the check.factors parameter was left at the default of ten,
# meaning all numeric columns with ten or fewer distinct values
# would be automatically converted to factors

# percent married - nationwide
svymean( ~marstat , pums.design )

# by state..
problem <- try( svymean( ~marstat , pums.design , byvar = ~state ) , silent = TRUE )

# ..but:
if( class( problem ) == 'try-error' ) print( "this resulted in an error because it's too big of a query" )


# loop through each state..
for ( this.state in all.states ){

	# construct the entire query as a string (this is generally not recommended)
	svy.string <- 
		paste( 
			"svymean( ~ marstat , subset( pums.design , ( state ==" ,
			this.state ,
			") ) )"
		)
		
	# manually evaluate the string
	print( eval( parse( text = svy.string ) ) )

}


# calculate the median and other percentiles #

# median age of residents of the united states
svyquantile( ~age , pums.design , quantiles = 0.5 )
# note: quantile standard errors cannot be computed with taylor-series linearization designs
# this is true in both the survey and sqlsurvey packages

# note two additional differences between the sqlsurvey and survey packages..

# ..sqlsurvey designs do not allow multiple quantiles.  instead, 
# loop through and print or save multiple quantiles, simply use a for loop

# loop through the median and 99th percentiles and print both results to the screen
for ( i in c( .5 , .99 ) ) print( svyquantile( ~age , pums.design , quantiles = i ) )



# ..sqlsurvey designs do not allow byvar arguments, meaning the only way to 
# calculate quantiles by state would be by creating subsets for each subpopulation
# and calculating the quantiles for them independently:

######################
# subsetting example #
######################

# restrict the pums.design object to females only
pums.design.female <- subset( pums.design , sex == 2 )

# now any of the above commands can be re-run
# using the pums.design.female object
# instead of the pums.design object
# in order to analyze females only
	
# calculate the distribution of a categorical variable #

# percent married - nationwide, restricted to females
svymean( ~marstat , pums.design.female )


###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# broken out by sex

# store the results into a new object

marital.status.by.sex <- svymean( ~marstat , pums.design , byvar = ~sex )

# immediately convert it to a data.frame
marital.status.by.sex <- data.frame( marital.status.by.sex )

# print the results to the screen 
marital.status.by.sex

# now you have the results saved into a new data.frame..
class( marital.status.by.sex )

# ..and then immediately exported as a comma-separated value file 
# into your current working directory 
write.csv( marital.status.by.sex , "marital status by sex.csv" )

# ..or trimmed to only contain the values you need.
# here's male versus female percents now married
# (excluding separated)
percent.now.married <-
	marital.status.by.sex[ , 1 ]


# print the new results to the screen
percent.now.married

# this can also be exported as a comma-separated value file 
# into your current working directory 
write.csv( percent.now.married , "percent now married by sex.csv" )

# ..or directly made into a bar plot
barplot(
	percent.now.married ,
	main = "Percent Currently Married" ,
	names.arg = c( "Male" , "Female" ) ,
	ylim = c( 0 , .5 )
)


############################
# end of analysis examples #
############################


# close the connection to the sqlrepsurvey design object
close( pums.design )


# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other `pums` monetdb analyses #
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
