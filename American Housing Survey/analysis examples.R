# analyze survey data for free (http://asdfree.com) with the r language
# american housing survey
# 2011

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/AHS/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/American%20Housing%20Survey/analysis%20examples.R" , prompt = FALSE , echo = TRUE )
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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#########################################################################################################
# prior to running this analysis script, the ahs 2009 file must be loaded as an r data file (.rda) and  #
# in a database (.db) on the local machine. running the download all microdata script will create both. #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/usgsd/master/American%20Housing%20Survey/download%20all%20microdata.R #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "ahs.db" and './2009/national/tnewhouse_trepwgt.rda' in your getwd()   #
#########################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/AHS/" )
# ..in order to set your current working directory


# remove the # in order to run this install.packages line only once
# install.packages( "survey" )


library(downloader)	# downloads and then runs the source() function on scripts from github
library(survey)		# load survey package (analyzes complex design surveys)
library(RSQLite) 	# load RSQLite package (creates database files in R)


# R will exactly match SUDAAN results and Stata with the MSE option results
options( survey.replicates.mse = TRUE )
# otherwise if it is commented out or set to FALSE


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# two survey-design object constructions are presented below.  if you have a powerful #
# computer, read everything into ram. otherwise, use the sqlite-backed object. one of #
# the two blocks of code below uncommented (but not both): add or remove all the `#`  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


##############################################
# survey design for a database-backed object #

# name the database (.db) file that should have been saved in the working directory
ahs.dbname <- "ahs.db"

# initiation of the replicate-weighted survey design object
ahs.design <-
	svrepdesign(
		weights = ~repwgt0,
		repweights = "repwgt[1-9]" ,
		type = "Fay" ,
		rho = ( 1 - 1 / sqrt( 4 ) ) ,
		data = "tnewhouse_trepwgt_2011_v14" ,
		dbtype = "SQLite" ,
		dbname = ahs.dbname
	)

# end of database-backed survey design creation #
#################################################


#########################################
# survey design for an in-memory object #

# name of the merged household-level + replicate weights `.rda` file on the local disk
# load( "./2011/v1.4/tnewhouse_trepwgt.rda" )

# initiation of the replicate-weighted survey design object
# ahs.design <-
	# svrepdesign(
		# weights = ~repwgt0,
		# repweights = "repwgt[1-9]" ,
		# type = "Fay" ,
		# rho = ( 1 - 1 / sqrt( 4 ) ) ,
		# data = tnewhouse_trepwgt
	# )

# to conserve memory, it's often useful to
# remove the data.frame object after creating
# the `ahs.design` object since it's no longer needed.
# rm( tnewhouse_trepwgt ) ; gc()
	
# end of in-memory survey design creation #
###########################################

# at this point, you have a replicate-weighted,
# complex sample survey design object
ahs.design
# for most analysis commands, it doesn't matter whether it's backed by a sqlite database or not.
# it only makes a difference on processing time and whether your computer's memory overloads.
# so, regardless of which of the two above options you chose,
# you can now start having fun with these

	
#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in ahs #
# broken out by region #

svyby(
	~one ,
	~region ,
	ahs.design ,
	unwtd.count
)



# count the weighted number of housing units in ahs #

# the total number of housing units in the united states #
svytotal(
	~one ,
	ahs.design
)

# the total number of housing units in the united states #
# by region
svyby(
	~one ,
	~region ,
	ahs.design ,
	svytotal
)


# calculate the mean of a linear variable #

# amount of monthly rent, if any
svymean(
	~rent ,
	design = subset( ahs.design , rent > 0 )
)

# by region
svyby(
	~rent ,
	~region ,
	design = subset( ahs.design , rent > 0 ) ,
	svymean
)


# calculate the distribution of a categorical variable #

# percent owners, renters, non-paying renters, missing.
svymean(
	~factor( tenure ) ,
	design = ahs.design ,
	na.rm = TRUE
)

# by region
svyby(
	~factor( tenure ) ,
	~region ,
	design = ahs.design ,
	svymean ,
	na.rm = TRUE
)

# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum rents, among housing units with any rent
svyquantile(
	~rent ,
	design = subset( ahs.design , rent > 0 ) ,
	c( 0 , .25 , .5 , .75 , 1 )
)

# by region
svyby(
	~rent ,
	~region ,
	design = subset( ahs.design , rent > 0 ) ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	ci = TRUE
)

######################
# subsetting example #
######################

# restrict the ahs.design object to
# the northeast only
ahs.design.northeast <- subset( ahs.design , region == 1 )
# now any of the above commands can be re-run
# using ahs.design.northeast object
# instead of the ahs.design object
# in order to analyze the northeast only

# calculate the mean of a linear variable #

# average amount of northeastern housing units with any rent
svymean(
	~rent ,
	design = subset( ahs.design.northeast , rent > 0 )
)

# be sure to clean up the object when you're done if you are short on ram
rm( ahs.design.northeast ) ; gc()

###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by region

# store the results into a new object

householder.by.region <-
	svyby(
		~factor( tenure ) ,
		~region ,
		design = ahs.design ,
		svymean ,
		na.rm = TRUE
	)

# print the results to the screen
householder.by.region

# now you have the results saved into a new object of type "svyby"
class( householder.by.region )

# print only the statistics (coefficients) to the screen
coef( householder.by.region )

# print only the standard errors to the screen
SE( householder.by.region )

# print only the coefficients of variation to the screen
cv( householder.by.region )

# this object can be coerced (converted) to a data frame..
householder.by.region <- data.frame( householder.by.region )

# ..and then immediately exported as a comma-separated value file
# into your current working directory
write.csv( householder.by.region , "householder by region.csv" )

# ..or trimmed to only contain the values you need.
# here's the "percent female" by region,
# with accompanying standard errors
owner_occupants.by.region <-
	householder.by.region[ , c( "region" , "factor.tenure.1" , "se1" ) ]


# print the new results to the screen
owner_occupants.by.region

# this can also be exported as a comma-separated value file
# into your current working directory
write.csv( owner_occupants.by.region , "owner occupants by region.csv" )

# ..or directly made into a bar plot
barplot(
	owner_occupants.by.region[ , 2 ] ,
	main = "Percent Owner-Occupancy by Region" ,
	names.arg = c( "Northeast" , "Midwest" , "South" , "West" ) ,
	ylim = c( 0 , .75 )
)

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
