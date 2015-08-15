# analyze survey data for free (http://asdfree.com) with the r language
# national survey of children's health
# 2011-2012 public use microdata

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NSCH/" )
# source_url( "https://raw.github.com/ajdamico/asdfree/master/National%20Survey%20of%20Children%27s%20Health/replication.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# http://www.screenr.com/Zpd8

# emily rowe
# eprowe@gmail.com

# anthony joseph damico
# ajdamico@gmail.com

# if you use this script for a project, please send me a note
# it's always nice to hear about how people are using this stuff

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#############################################################################################################################
# prior to running this replication script, the 2011-2012 public use microdata files must be loaded as R data files (.rda)  #
# on the local machine. running the "download all microdata.R" script will create this file for you.                        #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/asdfree/master/National%20Survey%20of%20Children%27s%20Health/download%20and%20import.R     #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will save a number of .rda files in C:/My Directory/NSCH/ (or the working directory was chosen)               #
#############################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# set your working directory.
# the NSCH 2011-2012 R data file (nsch 2012.rda) should have been stored in this folder.

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NSCH/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( c( 'mitools' , 'survey' ) )


library(mitools)	# allows analysis of multiply-imputed survey data
library(survey)		# load survey package (analyzes complex design surveys)


# load the 2011-2012 national survey of children's health into memory
load( "nsch 2012.rda" )


# memory conservation step #

# for machines with 4gb or less, it's necessary to subset the five implicate data frames to contain only
# the columns necessary for your particular analysis.  if running the code below generates a memory-related error,
# simply uncomment these lines and re-run the program:


# define which variables from the five imputed iterations to keep
vars.to.keep <- c( 'one' , 'povlevel_i' , 'state' , 'sample' , 'nschwt' , 'k6q40' , 'k7q05r' , 'k7q30' , 'k7q31' , 'k7q32' )
# note: this throws out all other variables
# so if you need additional columns for your analysis,
# add them to the `vars.to.keep` vector above


# restrict each `imp#` data frame to only those variables
imp1 <- imp1[ , vars.to.keep ]
imp2 <- imp2[ , vars.to.keep ]
imp3 <- imp3[ , vars.to.keep ]
imp4 <- imp4[ , vars.to.keep ]
imp5 <- imp5[ , vars.to.keep ]


# clear up RAM
gc()

# end of memory conservation step #


# construct a multiply-imputed survey design object
# that includes the five data tables - imp1 through imp5
nsch.design <- 
	svydesign( 
		
		# do not use a clustering variable
		id = ~ 1 , 
		
		# use both `state` and `sample` columns as the stratification variables
		strata = ~ state + sample , 
		
		# use the main weight within each of the imp# objects
		weights = ~nschwt , 
		
		# read the data directly from the five implicates
		data = imputationList( list( imp1 , imp2 , imp3 , imp4 , imp5 ) )
		
	)

# this is the methodologically-correct way to analyze the national survey of children's health
# main disadvantage: requires code that's less intuitive for analysts familiar with 
# the r survey package's svymean( ~formula , design ) layout


# this object can also be examined by typing the name into the console..
nsch.design

# ..or querying attributes directly.  not much yet.
attributes( nsch.design )


# `nsch.design` is a weird critter.  it's actually five survey designs, mushed into one thing.
# when you run an analysis on the nsch.design object, you're actually running the same analysis
# on all five survey designs contained in the object -
# and then the MIcombine() function will lumps them all together
# to give you the correct statistics and error terms


# oh hey look at the first (of five) survey designs..
nsch.design$designs[[1]]

# ..and here's the first design's attributes,
# which look more like a standard svydesign() object
attributes( nsch.design$designs[[1]] )

# examine the degrees of freedom of that first survey design
degf( nsch.design$designs[[1]] )

# look at the attributes of the fifth (of five) data frames
attributes( nsch.design$designs[[5]] )

# examine the degrees of freedom
degf( nsch.design$designs[[5]] )

#####################
# required recoding #
#####################

# in order to re-create some of the statistics published by the cdc
# create a few variables that are not naturally-occuring in the data set

# the `update` function does for complex sample survey designs
# (including multiply-imputed ones) what the `transform` function
# does for data.frame objects in the base R language.

nsch.design <-
	update(
		nsch.design ,
		
		# create indicator 1.3 #
		# if k6q40 is greater than one, k6q40 goes missing
		# otherwise it doesn't change.
		indicator_1.3 =
			ifelse( k6q40 > 1 , NA , k6q40 ) ,

		# create indicator 5.2 #
		# if k7q05r is 1-5 then this indicator is a 1
		# if k7q05r is a zero, then so is the indicator
		# and if it's anything else, this indicator is missing.
		indicator_5.2 =
			ifelse( k7q05r %in% 1:5 , 1 ,
			ifelse( k7q05r %in% 0 , 0 , NA ) ) ,
			
		# create indicator 5.3 #
		# if any of k7q30, k7q31, or k7q32 are ones, one.
		# otherwise if any are zeroes, zero.
		# otherwise missing.
		indicator_5.3 =
			ifelse( k7q30 == 1 | k7q31 == 1 | k7q32 == 1 , 1 ,
			ifelse( k7q30 == 0 | k7q31 == 0 | k7q32 == 0 , 0 , NA ) ) ,
			
		# create a poverty category variable
		# that precisely matches the crosstabs shown by the table creator
		povcat = findInterval( povlevel_i , c( 1 , 2 , 6 , 8 ) )
		
	)

###############################
# replication success stories #
###############################

# indicator 1.3: how many children age 0-5 years were ever breastfed or fed breast milk?
# (see http://www.childhealthdata.org/browse/survey/results?q=2460&r=1 for published results.)
MIcombine( with( nsch.design , svymean( ~indicator_1.3 , na.rm = TRUE ) ) )

# confidence interval
confint( MIcombine( with( nsch.design , svymean( ~indicator_1.3 , na.rm = TRUE ) ) ) )

# broken out by poverty #

# note the `data alert` text at the bottom of their graph:
# data alert: household poverty level for the 9.3% of households in the sample with unknown values for income, household size, or both, was calculated using single imputation methods. the poverty level estimates and confidence intervals based on single imputed poverty 

# basically, this means they're not using the methods that they recommend.
# in order to access only the third implicate from the design,
# you'd use the same example syntax as above..
nsch.design$designs[[3]]
# ..and then use that design object inside a `svymean` or `svyby` or `confint` call
# just like any other non-imputed complex sample survey analysis line.

# so here are the published results to exactly match..
# http://www.childhealthdata.org/browse/survey/results?q=2460&r=1&g=458
# ..and here are the lines of code to match them.

# coefficients and single-implicate standard errors
svyby( ~indicator_1.3 , ~povcat , nsch.design$designs[[3]] , svymean , na.rm = TRUE )

# confidence intervals
confint( svyby( ~indicator_1.3 , ~povcat , nsch.design$designs[[3]] , svymean , na.rm = TRUE ) )

# but..but..but!
# those numbers are incorrect.  the *correct* method uses all five implicates
# and, frankly, isn't any more difficult to implement.

# here are the numbers that do not match the published numbers, but do use the cdc-recommended methods.

# coefficients and multiple-implicate standard errors
MIcombine( with( nsch.design , svyby( ~indicator_1.3 , ~povcat , svymean , na.rm = TRUE ) ) )

# confidence intervals
confint( MIcombine( with( nsch.design , svyby( ~indicator_1.3 , ~povcat , svymean , na.rm = TRUE ) ) ) )


# satisfied with indicator 1.3?
# let's try the same deal with indicator 5.2.


# indicator 5.2: did child repeat one or more grades in school?
# (see http://www.childhealthdata.org/browse/survey/results?q=2515&r=1 for published results.)
MIcombine( with( nsch.design , svymean( ~indicator_5.2 , na.rm = TRUE ) ) )

# confidence interval
confint( MIcombine( with( nsch.design , svymean( ~indicator_5.2 , na.rm = TRUE ) ) ) )

# once again, here are the incorrect methods that precisely match
# the numbers published on childhealthdata.org at
# http://www.childhealthdata.org/browse/survey/results?q=2515&r=1&g=458

# coefficients and single-implicate standard errors
svyby( ~indicator_5.2 , ~povcat , nsch.design$designs[[3]] , svymean , na.rm = TRUE )

# confidence intervals
confint( svyby( ~indicator_5.2 , ~povcat , nsch.design$designs[[3]] , svymean , na.rm = TRUE ) )

# and, once again, here are the actual correct methods that will not match

# coefficients and multiple-implicate standard errors
MIcombine( with( nsch.design , svyby( ~indicator_5.2 , ~povcat , svymean , na.rm = TRUE ) ) )

# confidence intervals
confint( MIcombine( with( nsch.design , svyby( ~indicator_5.2 , ~povcat , svymean , na.rm = TRUE ) ) ) )


# okay, enough messin' around with imputed poverty
# let's replicate some state numbers


# indicator 5.3: did child participate in one or more organized activities outside school?
# (see http://www.childhealthdata.org/browse/survey/results?q=2518&r=1 for published results.)

# first reproduce the main statistics..
MIcombine( with( nsch.design , svymean( ~indicator_5.3 , na.rm = TRUE ) ) )

# ..and confidence interval
confint( MIcombine( with( nsch.design , svymean( ~indicator_5.3 , na.rm = TRUE ) ) ) )


# now let's try some state breakouts..
MIcombine( with( nsch.design , svyby( ~indicator_5.3 , ~state , svymean , na.rm = TRUE ) ) )

# ..and, yet again, confidence intervals
confint( MIcombine( with( nsch.design , svyby( ~indicator_5.3 , ~state , svymean , na.rm = TRUE ) ) ) )


# check alabama (state #2)
# http://www.childhealthdata.org/browse/survey/results?q=2518&r=1&r2=2

# or new york (state #35)
# http://www.childhealthdata.org/browse/survey/results?q=2518&r=1&r2=34

# or hey maybe vermont (state #47)
# http://www.childhealthdata.org/browse/survey/results?q=2518&r=1&r2=47


# by the way, wanna know which state is which?  search for the word `state` in the sas format script
# ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/slaits/nsch_2011_2012/05_SAS_input_files/create_1112_nsch_formats.sas


# all good?  all good.


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
