# analyze survey data for free (http://asdfree.com) with the r language
# american community survey
# 2011 person and household files

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
# prior to running this analysis script, the acs 2011 single-year file must be loaded as a monet database-backed sqlsurvey object   #
# on the local machine. running the 2005-2011 download and create database script will create a monet database containing this file #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/usgsd/blob/master/American%20Community%20Survey/download%20all%20microdata.R                          #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "acs2011_1yr.rda" in C:/My Directory/ACS or wherever the working directory was set for the program #
#####################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # #
# warning: monetdb required #
# # # # # # # # # # # # # # #


require(sqlsurvey)		# load sqlsurvey package (analyzes large complex design surveys)
require(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)


# after running the r script above, users should have handy a few lines
# to initiate and connect to the monet database containing all american community survey tables
# run them now.  mine look like this:


####################################################################
# lines of code to hold on to for all other `acs` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/ACS/MonetDB/acs.bat"

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "acs"
dbport <- 50001

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url )


# # # # run your analysis commands # # # #


# the american community survey download and importation script
# has already created a monet database-backed survey design object
# connected to the 2011 single-year table

# sqlite database-backed survey objects are described here: 
# http://faculty.washington.edu/tlumley/survey/svy-dbi.html
# monet database-backed survey objects are similar, but:
# the database engine is, well, blazingly faster
# the setup is kinda more complicated (but all done for you)

# since this script only loads one file off of the local drive,
# there's no need to set the working directory.
# instead, simply use the full filepath to the r data file (.rda)
# as shown in the load() examples below.

# choose which file in your ACS directory to analyze:
# one-year, three-year, or five-year file from any of the available years.
# this script replicates the 2011 single-year estimates,
# so leave that line uncommented and the other three choices commented out.

# load the desired american community survey monet database-backed complex sample design objects

# uncomment one of these lines by removing the `#` at the front..
# load( 'C:/My Directory/ACS/acs2011_1yr.rda' )	# analyze the 2011 single-year acs
# load( 'C:/My Directory/ACS/acs2010_1yr.rda' )	# analyze the 2010 single-year acs
# load( 'C:/My Directory/ACS/acs2010_3yr.rda' )	# analyze the 2008-2010 three-year acs
# load( 'C:/My Directory/ACS/acs2010_5yr.rda' )	# analyze the 2006-2010 five-year acs

# note: this r data file should already contain both the merged (person + household) and household-only designs


# connect the complex sample designs to the monet database #
acs.m <- open( acs.m.design , driver = MonetDB.R() )	# merged design
acs.h <- open( acs.h.design , driver = MonetDB.R() )	# household-only design



################################################
# ..and immediately start the example analyses #
################################################

# count the total (unweighted) number of records in acs #

# simply use the nrow function..
nrow( acs.m )

# ..on the sqlrepsurvey design object
class( acs.m )


# since the acs gets loaded as a monet database-backed survey object instead of a data frame,
# the number of unweighted records cannot be calculated by running the nrow() function on a data frame.

# running the nrow() function on the database connection object
# simply produces an error..
# nrow( db )

# because the monet database might contain multiple data tables
class( db )


# instead, perform the same unweighted count directly from the sql table
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

# HICOV has been converted to a factor (categorical) variable
# instead of a numeric (linear) variable,
# because it only contains the values 1 and 2.
# when the acs.m object was created with the function sqlrepdesign()
# the check.factors parameter was left at the default of ten,
# meaning all numeric columns with ten or fewer distinct values
# would be automatically converted to factors

# percent uninsured - nationwide
svymean( ~hicov , acs.m )

# by state
svymean( ~hicov , acs.m , byvar = ~st )


# calculate the median and other percentiles #

# median age of residents of the united states
svyquantile( ~agep , acs.m , , quantiles = 0.5 , se = T )

# note two additional differences between the sqlsurvey and survey packages..

# ..sqlrepsurvey designs do not allow multiple quantiles.  instead, 
# loop through and print or save multiple quantiles, simply use a for loop

# loop through the 25th, 50th, and 75th quantiles and print each result to the screen
for ( i in c( .25 , .5 , .75 ) ) print( svyquantile( ~agep , acs.m , quantiles = i , se = TRUE ) )


# ..sqlrepsurvey designs do not allow byvar arguments, meaning the only way to 
# calculate quantiles by state would be by creating subsets for each subpopulation
# and calculating the quantiles for them independently:

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
svyquantile( ~agep , acs.m.female , quantiles = 0.5 , se = T )



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by region of the country

# store the results into a new object

coverage.by.region <- svymean( ~hicov , acs.m , byvar = ~region )

# print the results to the screen 
coverage.by.region

# now you have the results saved into a new svyrepstat object..
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
	coverage.by.region[ substr( rownames( coverage.by.region) , 1 , 2 ) == "2:" , ]


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


# close the connection to the two sqlrepsurvey design objects
close( acs.m )
close( acs.h )


# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other `acs` monetdb analyses #
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
