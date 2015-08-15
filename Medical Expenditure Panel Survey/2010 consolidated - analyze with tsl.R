# analyze survey data for free (http://asdfree.com) with the r language
# medical expenditure panel survey
# 2010 consolidated

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/MEPS/" )
# source_url( "https://raw.github.com/ajdamico/asdfree/master/Medical%20Expenditure%20Panel%20Survey/2010%20consolidated%20-%20analyze%20with%20tsl.R" , prompt = FALSE , echo = TRUE )
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



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#############################################################################################################################################################
# prior to running this analysis script, the meps 2010 consolidated file must be loaded as an r data file (.rda) on the local machine.                      #
# running the 1996-2010 household component - download all microdata.R script will create this R data file (.rda)                                           #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/asdfree/master/Medical%20Expenditure%20Panel%20Survey/1996-2010%20household%20component%20-%20download%20all%20microdata.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "2010 - consolidated.rda" in C:/My Directory/MEPS (or wherever the working directory was chosen)                           #
#############################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



#############################################
# taylor series linearization (tsl) version #

# this script uses the tsl method to calculate standard errors
# tsl has the advantage of being computationally easier
# and the disadvantage of not producing standard errors or confidence intervals
# on percentile statistics
# (for example, tsl cannot compute the confidence interval around a median)

# if you are not sure which method to use, use the brr script instead of tsl
# available in the same folder


# the statistics (means, medians, percents, and counts) from brr and tsl designs
# will match exactly.  the standard errors and confidence intervals
# will be slightly different. both methods are considered valid.


##############################################################################
# Analyze the 2010 Medical Expenditure Panel Survey consolidated file with R #
##############################################################################


# set your working directory.
# the MEPS 2010 data file will be stored here
# after downloading and importing it.
# use forward slashes instead of back slashes


# set your working directory.
# this directory must contain the MEPS 2010 consolidated (.rda) file 
# as well as the MEPS linkage - brr (.rda) file
# created by the R program specified above
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/MEPS/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( "survey" )


library(survey)  # load survey package (analyzes complex design surveys)


# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN


# load the consolidated.2010 data frame into an R data frame
load( "2010 - consolidated.rda" )
	

####################################
# if your computer runs out of RAM #
# if you get a memory error        #
####################################

# uncomment these lines to restrict the MEPS 10 file
# to only the columns you expect to use in the analysis

# the MEPS 2010 consolidated file has almost 2,000 different columns
# most analyses only use a small fraction of those
# by removing the columns not necessary for the analysis,
# lots of RAM gets freed up

# create a character vector containing 
# the variables you need for the analysis

# KeepVars <-
	# c( 
		# # unique identifiers
		# "DUPERSID" , "PANEL" ,
		# # cluster and strata variables used for complex survey design
		# "VARPSU" , "VARSTR" , 
		# # 2010 weight
		# "PERWT10F" , 
		# # annualized insurance coverage variable
		# "INS10X" , 
		# # total annual medical expenditure variable
		# "TOTEXP10" , 
		# # region of the country variable
		# "REGION10" , 
		# # gender variable
		# "SEX"
	# )

# restrict the consolidated data table to
# only the columns specified above

# consolidated.2010 <-
	# consolidated.2010[ , KeepVars ]

# clear up RAM - garbage collection function

# gc()

############################
# end of RAM-clearing code #
############################
	
	
#################################################
# survey design for taylor-series linearization #
#################################################

# create survey design object with MEPS design information
# using existing data frame of MEPS data
meps.tsl.design <- 
	svydesign(
		id = ~VARPSU , 
		strata = ~VARSTR ,
		nest = TRUE ,
		weights = ~PERWT10F ,
		data = consolidated.2010
	)

# notice the 'meps.tsl.design' object used in all subsequent analysis commands


# if you are low on RAM, you can remove the data frame
# by uncommenting these two lines:

# rm( consolidated.2010 )

# gc()

	
#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in meps #

# simply use the nrow function
nrow( meps.tsl.design )

# the nrow function which works on both data frame objects..
class( consolidated.2010 )
# ..and survey design objects
class( meps.tsl.design )

# count the total (unweighted) number of records in meps #
# broken out by region of the country #

svyby(
	~TOTEXP10 ,
	~REGION10 ,
	meps.tsl.design ,
	unwtd.count
)



# count the weighted number of individuals in meps #

# add a new variable 'one' that simply has the number 1 for each record #

meps.tsl.design <-
	update( 
		one = 1 ,
		meps.tsl.design
	)

# the civilian, non-institutionalized population of the united states #
svytotal( 
	~one , 
	meps.tsl.design 
)


# note that this is exactly equivalent to summing up the weight variable
# from the original MEPS data frame
# (assuming this data frame was not cleared out of RAM above)

sum( consolidated.2010$PERWT10F )

# the civilian, non-institutionalized population of the united states #
# by region of the country
svyby(
	~one ,
	~REGION10 ,
	meps.tsl.design ,
	svytotal
)


# calculate the mean of a linear variable #

# average medical expenditure - nationwide
svymean( 
	~TOTEXP10 , 
	design = meps.tsl.design
)

# by region of the country
svyby( 
	~TOTEXP10 , 
	~REGION10 ,
	design = meps.tsl.design ,
	svymean
)


# calculate the distribution of a categorical variable #

# INS10X should be treated as a factor (categorical) variable
# instead of a numeric (linear) variable
# this update statement converts it.
# the svyby command below will not run without this
meps.tsl.design <-
	update( 
		INS10X = factor( INS10X ) ,
		meps.tsl.design
	)


# percent uninsured - nationwide
svymean( 
	~INS10X , 
	design = meps.tsl.design
)

# by region of the country
svyby( 
	~INS10X , 
	~REGION10 ,
	design = meps.tsl.design ,
	svymean
)

# calculate the median and other percentiles #

# note that a taylor-series survey design
# does not allow calculation of standard errors

# minimum, 25th, 50th, 75th, maximum 
# medical expenditure in the united states
svyquantile( 
	~TOTEXP10 , 
	design = meps.tsl.design ,
	c( 0 , .25 , .5 , .75 , 1 )
)

# by region of the country
svyby( 
	~TOTEXP10 , 
	~REGION10 ,
	design = meps.tsl.design ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	keep.var = F
)

######################
# subsetting example #
######################

# restrict the meps.tsl.design object to
# females only
meps.tsl.design.female <-
	subset(
		meps.tsl.design ,
		SEX %in% 2
	)
# now any of the above commands can be re-run
# using the meps.tsl.design.female object
# instead of the meps.tsl.design object
# in order to analyze females only
	
# calculate the mean of a linear variable #

# average medical expenditure - nationwide, restricted to females
svymean( 
	~TOTEXP10 , 
	design = meps.tsl.design.female
)



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by region of the country

# store the results into a new object

coverage.by.region <-
	svyby( 
		~INS10X , 
		~REGION10 ,
		design = meps.tsl.design ,
		svymean
	)

# print the results to the screen 
coverage.by.region

# now you have the results saved into a new object of type "svyby"
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
	coverage.by.region[ 2:5 , c( "REGION10" , "INS10X2" , "se.INS10X2" ) ]

# that's rows 2 through 5, and the three specified columns


# print the new results to the screen
uninsured.rate.by.region

# this can also be exported as a comma-separated value file 
# into your current working directory 
write.csv( uninsured.rate.by.region , "uninsured rate by region.csv" )

# ..or directly made into a bar plot
barplot(
	uninsured.rate.by.region[ , 2 ] ,
	main = "Uninsured Rate by Region of the Country" ,
	names.arg = c( "Northeast" , "Midwest" , "South" , "West" ) ,
	ylim = c( 0 , .25 )
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
