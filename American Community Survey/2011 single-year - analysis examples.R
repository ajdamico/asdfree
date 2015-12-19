# analyze survey data for free (http://asdfree.com) with the r language
# american community survey
# 2011 person and household files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( 'C:/My Directory/ACS/' )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/American%20Community%20Survey/2011%20single-year%20-%20analysis%20examples.R" , prompt = FALSE , echo = TRUE )
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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################################
# prior to running this analysis script, the acs 2011 single-year file must be loaded as a monet database-backed survey object      #
# on the local machine. running the 2005-2011 download and create database script will create a monet database containing this file #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/asdfree/blob/master/American%20Community%20Survey/download%20all%20microdata.R                        #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "acs2011_1yr.rda" in C:/My Directory/ACS or wherever the working directory was set for the program #
#####################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


library(survey)			# load survey package (analyzes complex design surveys)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(MonetDBLite)	# load MonetDBLite package (creates database files in R)


# load the desired american community survey monet database-backed complex sample design objects

# uncomment one of these lines by removing the `#` at the front..
load( 'acs2011_1yr.rda' )	# analyze the 2011 single-year acs
# load( 'acs2010_1yr.rda' )	# analyze the 2010 single-year acs
# load( 'acs2010_3yr.rda' )	# analyze the 2008-2010 three-year acs
# load( 'acs2010_5yr.rda' )	# analyze the 2006-2010 five-year acs


# note: this r data file should already contain both the merged (person + household) and household-only designs

# connect the complex sample designs to the monet database #
acs.m <- open( acs.m.design , driver = MonetDB.R() )	# merged design
acs.h <- open( acs.h.design , driver = MonetDB.R() )	# household-only design


###########################
# variable recode example #
###########################


# construct a new age category variable in the dataset: 0-4, 5-9, 10-14...55-59, 60-64, 65+
acs.m <- update( acs.m , agecat = 1 + findInterval( agep , seq( 5 , 65 , 5 ) ) )

# print the distribution of that age category
svymean( ~ factor( agecat ) , acs.m )


################################################
# ..and immediately start the example analyses #
################################################

# count the total (unweighted) number of records in acs #

# simply use the nrow function..
nrow( acs.m )

# ..on the svrepdesign object
class( acs.m )


# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )

# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite() , dbfolder )


# perform the same unweighted count directly from the sql table
# stored inside the monet database on your hard disk (as opposed to RAM)
dbGetQuery( db , "SELECT COUNT(*) AS num_records FROM acs2011_1yr_m" )

	

# count the total (unweighted) number of records in acs #
# broken out by state #

# note: this is easiest by simply running a sql query on the monet database directly
dbGetQuery( db , "SELECT st , COUNT(*) as num_records FROM acs2011_1yr_m GROUP BY st" )



# count the weighted number of individuals in acs #

# the population of the united states (including group quarters residents: both institionalized and non-institutionalized) #
svytotal( ~one , acs.m )

# note that this is exactly equivalent to summing up the weight variable
# from the original database (.db) file connection
dbGetQuery( db , "SELECT SUM( pwgtp ) AS sum_weights FROM acs2011_1yr_m" )


# the population of the united states #
# by state
svytotal( ~one , acs.m , byvar = ~st )
# note: the above command is one example of how the r survey package differs from the r sqlsurvey package


# calculate the mean of a linear variable #

# average age - nationwide
svymean( ~agep , acs.m )

# by state
svymean( ~agep , acs.m , byvar = ~st )


# calculate the distribution of a categorical variable #

# first, force the variable to be a factor class
acs.m <- update( acs.m , hicov = factor( hicov ) )

# percent uninsured - nationwide
svymean( ~hicov , acs.m )

# by state
svyby( ~hicov , ~st , acs.m , svymean )


# calculate the median and other percentiles #

# 25th, median, and 75th percentile of age of residents of the united states
svyquantile( ~agep , acs.m , c( .25 , .5 , .75 ) )


######################
# subsetting example #
######################

# restrict the acs.m object to females only
acs.m.female <- subset( acs.m , sex == 2 )

# now any of the above commands can be re-run
# using the acs.m.female object
# instead of the acs.m object
# in order to analyze females only
	
# calculate the mean of a linear variable #

# average age - nationwide, restricted to females
svymean( ~agep , acs.m.female )

# median age - nationwide, restricted to females
svyquantile( ~agep , acs.m.female , 0.5 )



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by region of the country

# store the results into a new object

coverage.by.region <- svyby( ~hicov , ~region , acs.m , svymean )

# print the results to the screen 
coverage.by.region

# now you have the results saved into a new svyby object..
class( coverage.by.region )

# print only the statistics (coefficients) to the screen 
coef( coverage.by.region )

# print only the standard errors to the screen 
SE( coverage.by.region )

# this object can be coerced (converted) to a data frame.. 
coverage.by.region <- data.frame( coverage.by.region )


# ..and then immediately exported as a comma-separated value file 
# into your current working directory 
write.csv( coverage.by.region , "coverage by region.csv" )

# ..or trimmed to only contain the values you need.
# here's the uninsured percentage by region, 
# with accompanying standard errors
uninsured.rate.by.region <-
	coverage.by.region[ , c( 1 , 3 , 5 ) ]


# print the new results to the screen
uninsured.rate.by.region

# this can also be exported as a comma-separated value file 
# into your current working directory 
write.csv( uninsured.rate.by.region , "uninsured rate by region.csv" )

# ..or directly made into a bar plot
barplot(
	uninsured.rate.by.region[ , 1 ] ,
	main = "Uninsured Rate by Region of the Country" ,
	names.arg = c( "Northeast" , "Midwest" , "South" , "West" ) ,
	ylim = c( 0 , .40 )
)


############################
# end of analysis examples #
############################


# close the connection to the two svrepdesign design objects
close( acs.m )
close( acs.h )


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
