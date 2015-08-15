# analyze survey data for free (http://asdfree.com) with the r language
# medicare current beneficiary survey
# 2009

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/MCBS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Medicare%20Current%20Beneficiary%20Survey/analysis%20examples.R" , prompt = FALSE , echo = TRUE )
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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###################################################################################################################
# prior to running this analysis script, the mcbs 2009 consolidated file must be loaded as an r data file (.rda)  #
# on the local machine. running the importation script will create both this file for ya.                         #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/Medicare%20Current%20Beneficiary%20Survey/importation.R #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/MCBS/" )
# ..in order to set your current working directory


# remove the # in order to run this install.packages line only once
# install.packages( 'survey' )


library(downloader)	# downloads and then runs the source() function on scripts from github
library(survey)		# load survey package (analyzes complex design surveys)
library(RSQLite) 	# load RSQLite package (creates database files in R)


# R will exactly match SUDAAN results and Stata with the MSE option results
options( survey.replicates.mse = TRUE )
# otherwise if it is commented out or set to FALSE


# load the 2009 mcbs consolidated cost & use file
load( "./cau/cons2009.rda" )


##########################################################
# replicate-weighted complex sample survey design object #
##########################################################

y <- 
	svrepdesign ( 
		data = x ,
		repweights = 'cs1yr[0-9]' ,
		type = "Fay" , 
		combined.weights = T , 
		rho = ( 1 - 1 / sqrt( 2.04 ) ) ,
		weights = ~cs1yrwgt
	)



# at this point, you have a replicate-weighted,
# complex sample survey design object
y

	
#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in mcbs #
# broken out by region #

svyby(
	~ one ,
	~ h_census ,
	y ,
	unwtd.count
)



# count the weighted number of medicare beneficiaries in mcbs #

# the total number of individuals ever covered by medicare in the united states during the year #
svytotal(
	~ one ,
	y
)

# the total number of beneficiaries in the united states #
# by region
svyby(
	~ one ,
	~ h_census ,
	y ,
	svytotal
)


# calculate the mean of a linear variable #

# total non-premium out-of-pocket expenditure
svymean(
	~ pamtoop ,
	design = y
)

# by region
svyby(
	~ pamtoop ,
	~ h_census ,
	design = y ,
	svymean
)


# calculate the distribution of a categorical variable #

# percent male / female.
svymean(
	~ factor( h_sex ) ,
	design = y ,
	na.rm = TRUE
)

# by region
svyby(
	~ factor( h_sex ) ,
	~ h_census ,
	design = y ,
	svymean ,
	na.rm = TRUE
)

# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum non-premium out-of-pocket expenditure, among all medicare beneficiaries
svyquantile(
	~ pamtoop ,
	design = y ,
	c( 0 , .25 , .5 , .75 , 1 )
)

# by region
svyby(
	~ pamtoop ,
	~ h_census ,
	design = y ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	ci = TRUE
)

######################
# subsetting example #
######################

# restrict the y object to females only
y.female <- subset( y , h_sex == 2 )
# now any of the above commands can be re-run
# using y.female object
# instead of the y object
# in order to analyze females only

# calculate the mean of a linear variable #

# average amount of non-premium out-of-pocket expenditure among females
svymean(
	~ pamtoop ,
	design = y.female
)

# be sure to clean up the object when you're done if you are short on ram
rm( y.female ) ; gc()

###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by region

# store the results into a new object

sex.by.region <-
	svyby(
		~ factor( h_sex ) ,
		~ h_census ,
		design = y ,
		svymean ,
		na.rm = TRUE
	)

# print the results to the screen
sex.by.region

# now you have the results saved into a new object of type "svyby"
class( sex.by.region )

# print only the statistics (coefficients) to the screen
coef( sex.by.region )

# print only the standard errors to the screen
SE( sex.by.region )

# print only the coefficients of variation to the screen
cv( sex.by.region )

# this object can be coerced (converted) to a data frame..
sex.by.region <- data.frame( sex.by.region )

# ..and then immediately exported as a comma-separated value file
# into your current working directory
write.csv( sex.by.region , "sex by region.csv" )

# ..or trimmed to only contain the values you need.
# here's the "percent female" by region,
# with accompanying standard errors
female.by.region <-
	sex.by.region[ , c( "h_census" , "factor.h_sex.2" , "se2" ) ]


# print the new results to the screen
female.by.region

# this can also be exported as a comma-separated value file
# into your current working directory
write.csv( female.by.region , "female by region.csv" )

# ..or directly made into a bar plot
barplot(
	female.by.region[ , 2 ] ,
	main = "Percent Female by Region" ,
	names.arg = c( "Unknown" , "New\nEngland" , "Middle\nAtlantic" , "East North\nCentral" , "West North\nCentral" , "South\nAtlantic" , "East South\nCentral" , "West South\nCentral" , "Mountain" , "Pacific" , "Puerto\nRico" ) ,
	ylim = c( 0 , .75 ) ,
	cex.names = 0.7 ,
	las = 2
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
