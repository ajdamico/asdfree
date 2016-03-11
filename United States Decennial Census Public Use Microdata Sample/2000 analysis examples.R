# analyze survey data for free (http://asdfree.com) with the r language
# united states decennial census
# public use microdata sample
# 1990 , 2000

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/PUMS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/United%20States%20Decennial%20Census%20Public%20Use%20Microdata%20Sample/2000%20analysis%20examples.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#################################################################################################################################################################
# prior to running this analysis script, the 1% and 5% public use microdata samples from the 2000 census must be loaded on the local machine with               #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/United%20States%20Decennial%20Census%20Public%20Use%20Microdata%20Sample/download%20and%20import.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# ..that script will place a 'MonetDB' folder on the local drive containing the appropriate data tables for this code to work properly.                         #
#################################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PUMS/" )


# # # # # # # # # # # # # #
# warning warning warning #
# # # # # # # # # # # # # #

# the statistics (means, medians, sums, totals, percentiles, distributions) shown using the method below are correct.
# the errors (standard errors, standard deviations, variances, confidence intervals, significance tests) are not.

# to calculate error terms / confidence intervals the census-approved way, the only current option is to follow this
# hellishly-cumbersome document where you have to multiply stuff by hand and calculate SEs for each and every statistic.
# it. is. a. nightmare.
# here's the 2010 version:
# http://www2.census.gov/census_2010/12-Stateside_PUMS/0TECH_DOC/
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

# case and point: for the united states decennial census public use microdata samples,
# you cannot _automate_ the calculation of standard errors if you want to use the _official_ census method.  sowwy.


library(survey) 		# load survey package (analyzes complex design surveys)
library(DBI)			# load the DBI package (implements the R-database coding)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(MonetDBLite)	# load MonetDBLite package (creates database files in R)



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
# load( 'pums_1990_1_m.rda' )	# analyze the 1990 1% pums file
# load( 'pums_1990_5_m.rda' )	# analyze the 1990 5% pums file
# load( 'pums_2000_1_m.rda' )	# analyze the 2000 1% pums file
load( 'pums_2000_5_m.rda' )		# analyze the 2000 5% pums file
# load( 'pums_2010_10_m.rda' )	# analyze the 2010 10% pums file

# note: this r data file should already contain the 2000 5% design


# connect the complex sample design to the monet database #
pums.design <- open( pums.m.design , driver = MonetDB.R() )	# merged design


# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )

# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite() , dbfolder )


################################################
# ..and immediately start the example analyses #
################################################

# count the total (unweighted) number of records in pums #

# simply use the nrow function..
nrow( pums.design )

# ..on the survey design object
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
# note: the above command is one example of how the r survey package differs from the r survey package


# calculate the mean of a linear variable #

# average age - nationwide
svymean( ~age , pums.design )

# average age - by state
svyby( ~age , ~state , pums.design , svymean )


# calculate the distribution of a categorical variable #
pums.design <- update( pums.design , marstat = factor( marstat ) )

# percent married - nationwide
svymean( ~marstat , pums.design )

# by state..
svyby( ~marstat , ~state , pums.design , svymean )


# calculate the median and other percentiles #

# median age of residents of the united states
svyquantile( ~age , pums.design , c( 0.5 , 0.99 ) )


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

marital.status.by.sex <- svyby( ~marstat , ~sex , pums.design , svymean )

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
	marital.status.by.sex[ , 2 ]


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


# close the connection to the svydesign object
close( pums.design )


# disconnect from the current monet database
dbDisconnect( db )

