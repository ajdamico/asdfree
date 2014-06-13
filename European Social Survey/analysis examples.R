# analyze survey data for free (http://asdfree.com) with the r language
# european social survey
# 2010 examples

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/ESS/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/European%20Social%20Survey/analysis%20examples.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# http://www.screenr.com/Zpd8

# daniel oberski
# daniel.oberski@gmail.com

# anthony joseph damico
# ajdamico@gmail.com

# if you use this script for a project, please send me a note
# it's always nice to hear about how people are using this stuff

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf


#######################################################################
# analyze the 2010 European Social Survey integrated data file with R #
#######################################################################



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#######################################################################################################################
# prior to running this replication script, the 2010 ESS microdata files must be loaded as R data files (.rda)        #
# on the local machine. running the "download all microdata.R" script will create this file for you with zero hassle. #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/usgsd/master/European%20Social%20Survey/download%20all%20microdata.R                #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will save a number of .rda files in C:/My Directory/ESS/ (or the working directory was chosen)          #
#######################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# set your working directory.
# all ESS data files will be stored here
# after downloading and importing.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/ESS/" )
# ..in order to set your current working directory


# install.packages( c( 'survey' , 'downloader' ) )


library(survey)		# load survey package (analyzes complex design surveys)
library(downloader)	# downloads and then runs the source() function on scripts from github



# by default, R will crash if a primary sampling unit (psu) has a single observation
# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
# by uncommenting this line:
# options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# note about using country-specific data rather than the `integrated` multi-country files:  #
# the integrated files produced by the ESS data administrators do not include design info.  #
# that's fine if you don't care about standard errors or confidence intervals, but ...      #
# you should.                                                                               #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# load belgium's round five main data file..
load( "./2010/BE/ESS5.rda" )
# ..and immediately save it to a more appropriately-named object
ess5.be <- x

# load belgium's round five sample design data file (sddf)..
load( "./2010/BE/ESS5__SDDF.rda" )
# ..and immediately save it to a more appropriately-named object
ess5.be.sddf <- x


# note that the sample design data files (sddf) do not get released
# at the same time as the main data file, for some odd reason.
# since that prevents you from knowing how good your estimates actually are,
# it's an incomplete analysis.  better to wait for the full data.
# survey research has two components:
# knowing something (the coefficient) and
# understanding how well you know it (the variance)



# merge these two files together, creating a merged object..
ess5.be.m <- merge( ess5.be , ess5.be.sddf )
# ..and immediately check that all record counts match up
stopifnot( nrow( ess5.be ) == nrow( ess5.be.m ) & nrow( ess5.be.sddf ) == nrow( ess5.be.m ) )


# display the number of rows in the cross-sectional cumulative data set
nrow( ess5.be.m )

# display the first six records in the cross-sectional cumulative data set
head( ess5.be.m )
# note that the data frame contains far too many variables to be viewed conveniently


# # # # # # # optional data.frame reduction # # # # # # #

# create a character vector that will be used to
# limit the file to only the variables needed
KeepVars <-
	c( 
		# average hours of television viewed
		"tvtot" , 
		
		# child living at home
		"chldhm" ,
	
		# gender
		"gndr" ,
		
		# complex sample survey design variables #
		# ( you need these, don't remove them )  #
		
		# clusters
		"psu" ,
		
		# strata
		"stratify" ,
		
		# probability of sampling
		"prob"
		
	)


# limit the r data frame (ess5.be.m) containing all variables
# to a severely-restricted r data frame containing only the seven variables
# specified in character vector 'KeepVars'
x <- ess5.be.m[ , KeepVars ]

# remove the object `ess5.be.m` from memory
rm( ess5.be.m )

# garbage collection: clear up RAM
gc()

# # # # # # # end of optional reduction # # # # # # #
# but if you didn't "slim down" your data file,
# you'll need to run this next line of code:
# x <- ess5.be.m


#################################################
# survey design for taylor-series linearization #
#################################################

# create a survey design object (ess5.be.design) with ESS design information
ess5.be.design <- 
	svydesign(
		ids = ~psu ,
		strata = ~stratify ,
		probs = ~prob ,
		data = x
	)
	
# notice the 'ess5.be.design' object used in all subsequent analysis commands


#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in ESS #

# the nrow function which works on both data frame objects..
class( x )
# ..and survey design objects
class( ess5.be.design )


# number of records in the data.frame object `x`
nrow( x )

# same number.  schnazzy, huh?
nrow( ess5.be.design )


# count the weighted number of individuals in ESS #

# add a new variable 'one' that simply has the number 1 for each record #

ess5.be.design <-
	update( 
		one = 1 ,
		ess5.be.design
	)

	
# from pdf page 8 of the ESS round five report..
# http://www.europeansocialsurvey.org/docs/round5/survey/ESS5_data_documentation_report_e03_0.pdf
# ..the sample frame is all persons aged 15 and over resident within private households, regardless of their
# nationality, citizenship, language or legal status currently in belgium.

# and, for a more detailed description of how belgium's survey was collected, check out pdf page 19
# http://www.europeansocialsurvey.org/docs/round5/survey/ESS5_data_documentation_report_e03_0.pdf#page=19


# here's the sum of the weights..
svytotal( 
	~one , 
	ess5.be.design 
)
# ..which is completely meaningless on its own.



# count the total (unweighted) number of records in ESS #
# broken out by child living at home #

svyby(
	~one ,
	~chldhm ,
	ess5.be.design ,
	unwtd.count
)





# calculate the mean of a linear variable #

# average hours of television viewed - among belgian residents aged 15+
svymean( 
	~tvtot , 
	design = ess5.be.design ,
	na.rm = TRUE
)

# by child living at home
svyby( 
	~tvtot , 
	~chldhm ,
	design = ess5.be.design ,
	svymean ,
	na.rm = TRUE
)


# calculate the distribution of a categorical variable #

# gndr should be treated as a factor (categorical) variable
# instead of a numeric (linear) variable
# this update statement converts it.
# the svyby command below will not run without this
ess5.be.design <-
	update( 
		gndr = factor( gndr ) ,
		ess5.be.design
	)


# gender distribution among belgian residents aged 15+
svymean( 
	~gndr , 
	design = ess5.be.design ,
	na.rm = TRUE
)

# by child living at home
svyby( 
	~gndr , 
	~chldhm ,
	design = ess5.be.design ,
	svymean , 
	na.rm = TRUE
)

# calculate the median and other percentiles #

# note that a taylor-series survey design
# does not allow calculation of standard errors

# minimum, 25th, 50th, 75th, maximum 
# hours of television viewed in belgium
svyquantile( 
	~tvtot , 
	design = ess5.be.design ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	na.rm = TRUE
)

# by child living at home
svyby( 
	~tvtot , 
	~chldhm ,
	design = ess5.be.design ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	keep.var = F ,
	na.rm = TRUE
)

######################
# subsetting example #
######################

# restrict the ess5.be.design object to
# females only
ess5.be.design.female <-
	subset(
		ess5.be.design ,
		gndr == 2
	)
# now any of the above commands can be re-run
# using the ess5.be.design.female object
# instead of the ess5.be.design object
# in order to analyze females only
	
# calculate the mean of a linear variable #

# average hours of television viewed - among belgian residents aged 15+, restricted to females
svymean( 
	~tvtot , 
	design = ess5.be.design.female ,
	na.rm = TRUE
)



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by child living at home

# store the results into a new object

gndr.by.chldhm <-
	svyby( 
		~gndr , 
		~chldhm ,
		design = ess5.be.design ,
		svymean ,
		na.rm = TRUE
	)

# print the results to the screen 
gndr.by.chldhm

# now you have the results saved into a new object of type "svyby"
class( gndr.by.chldhm )

# print only the statistics (coefficients) to the screen 
coef( gndr.by.chldhm )

# print only the standard errors to the screen 
SE( gndr.by.chldhm )

# this object can be coerced (converted) to a data frame.. 
gndr.by.chldhm <- data.frame( gndr.by.chldhm )

# ..and then immediately exported as a comma-separated value file 
# into your current working directory 
write.csv( gndr.by.chldhm , "gndr by chldhm.csv" )

# ..or trimmed to only contain the values you need.
# here's the percent of belgian residents aged 15+ who are female
# broken down by having a child at home, with accompanying standard errors
female.rate.by.chldhm <-
	gndr.by.chldhm[ , c( "chldhm" , "gndr2" , "se.gndr2" ) ]

# that's all rows, and the three specified columns


# print the new results to the screen
female.rate.by.chldhm

# this can also be exported as a comma-separated value file 
# into your current working directory 
write.csv( female.rate.by.chldhm , "female rate by chldhm.csv" )

# ..or directly made into a bar plot
barplot(
	female.rate.by.chldhm[ , 2 ] ,													# the second column contains the main statistics
	main = "% of 15+ Year Old Belgians who are Female, by Child Living at Home" ,	# title the barplot
	names.arg = c( "Child at Home" , "No Child in Household" ) ,					# title the bars
	ylim = c( 0 , .6 )  															# set the lower and upper bound of the y axis
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
