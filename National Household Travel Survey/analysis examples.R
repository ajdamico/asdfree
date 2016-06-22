# analyze survey data for free (http://asdfree.com) with the r language
# national household travel survey
# 2009 person file

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NHTS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Household%20Travel%20Survey/analysis%20examples.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico the first
# ajdamico@gmail.com


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#########################################################################################################################
# prior to running this analysis script, the nhts 2009 file must be loaded as a monet database-backed survey object     #
# on the local machine. running the download and import script will create a monet database containing this file.       #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw2.github.com/ajdamico/asdfree/master/National%20Household%20Travel%20Survey/download%20and%20import.R      #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "2009 designs.rda" in C:/My Directory/NHTS or wherever the working directory was set.  #
#########################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NHTS/" )
# ..in order to set your current working directory


library(survey) 		# load survey package (analyzes complex design surveys)
library(MonetDBLite)
library(DBI)			# load the DBI package (implements the R-database coding)




# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )

# immediately connect to the monetdblite folder
db <- dbConnect( MonetDBLite::MonetDBLite() , dbfolder )


# R will exactly match SUDAAN results and Stata with the MSE option results
options( survey.replicates.mse = TRUE )
# otherwise if it is commented out or set to FALSE


# the national household travel survey download and importation script
# has already created a monet database-backed survey design object
# connected to the 2009 tables

# sqlite database-backed survey objects are described here: 
# http://r-survey.r-forge.r-project.org/survey/svy-dbi.html
# monet database-backed survey objects are similar, but:
# the database engine is, well, blazingly faster
# the setup is kinda more complicated (but all done for you)

# since this script only loads one file off of the local drive,
# there's no need to set the working directory.
# instead, simply use the full filepath to the r data file (.rda)
# as shown in the load() examples below.

# load the desired national household travel survey monet database-backed complex sample design objects

# uncomment this line by removing the `#` at the front..
load( '2009 designs.rda' )	# analyze the 2009 designs


# note: this r data file should already contain all of the designs for this year


# connect the complex sample designs to the monet database #

nhts.per.design <- open( nhts.per.design , driver = MonetDB.R() )	# person-level design



###########################
# variable recode example #
###########################


# construct a new category variable in the dataset
nhts.per.design <- update( nhts.per.design , agecat = factor( 1 + findInterval( r_age , c( seq( 5 , 65 , 5 ) , 75 , 85 ) ) ) )

# print the distribution of that category
svymean( ~ agecat , nhts.per.design )


################################################
# ..and immediately start the example analyses #
################################################

# count the total (unweighted) number of records in the person-file #

# simply use the nrow function..
nrow( nhts.per.design )

# ..on the sqlrepsurvey design object
class( nhts.per.design )


# since the nhts gets loaded as a monet database-backed survey object instead of a data frame,
# the number of unweighted records cannot be calculated by running the nrow() function on a data frame.

# running the nrow() function on the database connection object
# simply produces an error..
# nrow( db )

# because the monet database might contain multiple data tables
class( db )


# instead, perform the same unweighted count directly from the sql table
# stored inside the monet database on your hard disk (as opposed to RAM)
dbGetQuery( db , "SELECT COUNT(*) AS num_records FROM per_m_2009" )

	

# count the total (unweighted) number of records in nhts #
# broken out by state #

# note: this is easiest by simply running a sql query on the monet database directly
dbGetQuery( db , "SELECT hhstate , COUNT(*) as num_records FROM per_m_2009 GROUP BY hhstate" )



# count the weighted number of individuals in nhts #

# the non-institutionalized civilian population of the united states older than four years #
svytotal( ~one , nhts.per.design )

# note that this is exactly equivalent to summing up the weight variable
# from the original database (.db) file connection
dbGetQuery( db , "SELECT SUM( wtperfin ) AS sum_weights FROM per_m_2009" )


# the over-four population of the united states #
# by state
svytotal( ~one , nhts.per.design , byvar = ~hhstate )
# note: the above command is one example of how the r survey package differs from the r survey package


# calculate the mean of a linear variable #

# average age - nationwide
svymean( ~r_age , nhts.per.design )

# by state
svyby( ~r_age , ~hhstate , nhts.per.design , svymean )


# calculate the distribution of a categorical variable #

# percent with access to heavy rail
svymean( ~I( rail == 1 ) , nhts.per.design )

# by state
svyby( ~I( rail == 1 ) , ~hhstate , nhts.per.design , svymean )


# calculate the median and other percentiles #

# age of residents of the united states: the 25th, median, and 75th percentiles
svyquantile( ~r_age , nhts.per.design , c( .25 , .5 , .75 ) )


######################
# subsetting example #
######################

# restrict the nhts.per.design object to females only
nhts.per.design.female <- subset( nhts.per.design , r_sex == 2 )

# now any of the above commands can be re-run
# using the nhts.per.design.female object
# instead of the nhts.per.design object
# in order to analyze females only
	
# calculate the mean of a linear variable #

# average age - nationwide, restricted to females
svymean( ~r_age , nhts.per.design.female )

# median age - nationwide, restricted to females
svyquantile( ~r_age , nhts.per.design.female , 0.5 )



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by region of the country

# store the results into a new object

rail.by.region <- svyby( ~I( rail == 1 ) , ~census_r , nhts.per.design , svymean )

# print the results to the screen 
rail.by.region

# now you have the results saved into a new svyrepstat object..
class( rail.by.region )

# print only the statistics (coefficients) to the screen 
coef( rail.by.region )

# print only the standard errors to the screen 
SE( rail.by.region )

# this object can be coerced (converted) to a data frame.. 
rail.by.region <- data.frame( rail.by.region )


# ..and then immediately exported as a comma-separated value file 
# into your current working directory 
write.csv( rail.by.region , "rail by region.csv" )


# ..or directly made into a bar plot
barplot(
	rail.by.region[ , 3 ] ,
	main = "Access to Heavy Rail by Region of the Country" ,
	names.arg = c( "Northeast" , "Midwest" , "South" , "West" ) ,
	ylim = c( 0 , 1 )
)


############################
# end of analysis examples #
############################


# close the connection to the sqlrepsurvey design object
close( nhts.per.design )


# disconnect from the current monet database
dbDisconnect( db , shutdown = TRUE )

