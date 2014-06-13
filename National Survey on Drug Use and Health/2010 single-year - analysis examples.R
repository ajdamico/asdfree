# analyze survey data for free (http://asdfree.com) with the r language
# national survey on drug use and health
# 2010

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NSDUH/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/National%20Survey%20on%20Drug%20Use%20and%20Health/2010%20single-year%20-%20analysis%20examples.R" , prompt = FALSE , echo = TRUE )
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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#################################################################################################################################################
# prior to running this replication script, all nsduh 2011 public use microdata files must be loaded as R data                                  #
# files (.rda) on the local machine. running the "1979-2010 - download all microdata.R" script will create these files.                         #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/usgsd/blob/master/National%20Survey%20on%20Drug%20Use%20and%20Health/1979-2010%20-%20download%20all%20microdata.R #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will save a number of .rda files in C:/My Directory/NSDUH/2010/ (or the working directory chosen)                                 #
#################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


#################################################################
# Analyze the 2010 National Study on Drug Use and Health with R #
#################################################################


# set your working directory.
# the NSDUH 2010 R data files (.rda) should have been
# stored in a year-specific directory within this folder.
# so if the file "NSDUH.10.rda" exists in the directory "C:/My Directory/NSDUH/2010/" 
# then the working directory should be set to "C:/My Directory/NSDUH/"
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NSDUH/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( "survey" )


library(survey)  # load survey package (analyzes complex design surveys)


# by default, R will crash if a primary sampling unit (psu) has a single observation
# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
# by keeping this line uncommented:
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN


# the r data frame can be loaded directly from your local hard drive
load( "./2010/NSDUH.10.rda" )


# display the number of rows in the 2010 data set
nrow( NSDUH.10.df )

# display the first six records in the cross-sectional cumulative data set
head( NSDUH.10.df )
# note that the data frame contains far too many variables to be viewed conveniently

# create a character vector that will be used to
# limit the file to only the variables needed
KeepVars <-
	c( 
		"analwt_c" , 	# main analytic weight
		
		"vestr" , 		# sampling strata
		
		"verep" , 		# primary sampling units
		
		"cigrec" ,		# time since last smoked cigarettes
		
		"cigtry" , 		# age when first smoked a cigarette

		"pden" ,		# population density variable
		
		"health"		# self-reported health status
	)


# limit the r data frame (NSDUH.10.df) containing all variables
# to a severely-restricted r data frame containing only the seven variables
# specified in character vector 'KeepVars'
x <- NSDUH.10.df[ , KeepVars ]

# to free up RAM, remove the full r data frame
rm( NSDUH.10.df )

# garbage collection: clear up RAM
gc()


#################################################
# survey design for taylor-series linearization #
#################################################

# create a survey design object (y) with NSDUH design information
y <- 
	svydesign( 
		id = ~verep , 
		strata = ~vestr , 
		data = x , 
		weights = ~analwt_c , 
		nest = TRUE 
	)
	

# add a new variable 'one' that simply has the number 1 for each record #
# and can be used to calculate unweighted and weighted population sizes #

y <-
	update( 
		one = 1 ,
		y
	)
	
	
#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in nsduh #

# the nrow function which works on both data frame objects..
class( x )
# ..and survey design objects
class( y )


# notice that the original data frame contains the same number of records as..
nrow( x )

# ..the survey object
nrow( y )


# count the total (unweighted) number of records in nsduh #
# broken out by self-reported health status #

svyby(
	~one ,
	~health ,
	y ,
	unwtd.count
)



# count the weighted number of individuals in nsduh #

# the civilian, non-institutionalized population of the united states #
# aged 12 or older (including civilians living on military bases)     #
svytotal( 
	~one , 
	y 
)


# note that this is exactly equivalent to summing up the weight variable from the original NSDUH data frame

sum( x$analwt_c )

# the civilian, non-institutionalized population of the united states #
# aged 12 or older (including civilians living on military bases)     #
# by self-reported health status                                      #
svyby(
	~one ,
	~health ,
	y ,
	svytotal
)


# calculate the mean of a linear variable #

# among individuals who have ever smoked: time since last smoked a cigarette - nationwide distribution
svymean( 
	~cigtry , 
	design = y ,
	na.rm = TRUE
)

# by self-reported health status
svyby( 
	~cigtry , 
	~health ,
	design = y ,
	svymean ,
	na.rm = TRUE
)


# calculate the distribution of a categorical variable #

# cigrec should be treated as a factor (categorical) variable
# instead of a numeric (linear) variable
# this update statement converts it.
# the svyby command below will not run without this
y <-
	update( 
		cigrec = factor( cigrec ) ,
		y
	)


# among individuals who have ever smoked: time since last smoked a cigarette distribution - nationwide
svymean( 
	~cigrec , 
	design = y ,
	na.rm = TRUE
)

# by self-reported health status
svyby( 
	~cigrec , 
	~health ,
	design = y ,
	svymean , 
	na.rm = TRUE
)

# calculate the median and other percentiles #

# note that a taylor-series survey design
# does not allow calculation of standard errors

# minimum, 25th, 50th, 75th, maximum 
# among individuals who have ever smoked: age at first cigarette - nationwide
svyquantile( 
	~cigtry , 
	design = y ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	na.rm = TRUE
)

# by self-reported health status
svyby( 
	~cigtry , 
	~health ,
	design = y ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	keep.var = F ,
	na.rm = TRUE
)

######################
# subsetting example #
######################

# restrict the y object to residents of core based statistical areas (cbsas) with 1 million or more persons
# (for the definition of a cbsa, check out: http://en.wikipedia.org/wiki/Core_Based_Statistical_Area)
y.city <-
	subset(
		y ,
		pden == 1
	)
# now any of the above commands can be re-run
# using the y.city object
# instead of the y object
# in order to analyze residents of high-population cbsas only
	
# calculate the mean of a linear variable #

# among individuals who have ever smoked: average age when first tried a cigarette - restricted to densely-urban populations
svymean( 
	~cigtry , 
	design = y.city ,
	na.rm = TRUE
)



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by self-reported health status

# store the results into a new object

cigrec.by.health <-
	svyby( 
		~cigrec , 
		~health ,
		design = y ,
		svymean ,
		na.rm = TRUE
	)

# print the results to the screen 
cigrec.by.health

# now you have the results saved into a new object of type "svyby"
class( cigrec.by.health )

# print only the statistics (coefficients) to the screen 
coef( cigrec.by.health )

# print only the standard errors to the screen 
SE( cigrec.by.health )

# this object can be coerced (converted) to a data frame.. 
cigrec.by.health <- data.frame( cigrec.by.health )

# ..and then immediately exported as a comma-separated value file 
# into your current working directory 
write.csv( cigrec.by.health , "cigrec by health.csv" )

# ..or trimmed to only contain the values you need.
# among individuals who ever smoked, 
# here's the percent who haven't had a cigarette in the past three years
# 'threeplus' by region, with accompanying standard errors
threeplus.rate.by.health <-
	cigrec.by.health[ , c( "health" , "cigrec4" , "se.cigrec4" ) ]

# that's all rows, and the three specified columns


# print the new results to the screen
threeplus.rate.by.health

# this can also be exported as a comma-separated value file 
# into your current working directory 
write.csv( threeplus.rate.by.health , "threeplus rate by health.csv" )

# ..or directly made into a bar plot
barplot(
	# the second column of the data frame contains the main data
	threeplus.rate.by.health[ , 2 ] ,																						
	# title the barplot
	main = "Among Americans Aged 12 or Older Who Have Ever Smoked:\nPercent Who Have Not Smoked For 3+ Years,\nBy Self-Reported Health Status" ,	
	# create a character vector containing the five self-reported health status categories
	names.arg = c( "Excellent" , "Very Good" , "Good" , "Fair" , "Poor" ) ,
	# set the lower and upper bound of the y axis
	ylim = c( 0 , .60 ) 							
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
