# analyze survey data for free (http://asdfree.com) with the r language
# new york city housing and vacancy survey
# 2011

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NYCHVS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/New%20York%20City%20Housing%20and%20Vacancy%20Survey/2011%20analysis%20examples.R" , prompt = FALSE , echo = TRUE )
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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#########################################################################################################################################################
# prior to running this analysis script, the `occ` `vac` `per` `ni` data.frames for the current year must be available on the local machine. running..  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# https://raw.githubusercontent.com/ajdamico/asdfree/master/New%20York%20City%20Housing%20and%20Vacancy%20Survey/download%20all%20microdata.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# ..that script will place a 'nychvs##.rda' file with for each year downloaded into the "C:/My Directory/NYCHVS/" folder (the working directory)        #
#########################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


##########################################################################################
# this script matches the *totals* but *not* the confidence intervals presented in the   #  
# census document http://www.census.gov/housing/nychvs/data/2008/contract_items_2008.xls #
##########################################################################################

# the statistics (means, medians, sums, totals, percentiles, distributions) shown using the method below are correct.
# the errors (standard errors, standard deviations, variances, confidence intervals, significance tests) are not.
# they are (at least after lots of testing) _always_ too big, meaning that if you find a statistically significant difference
# with the code below, it would also be statistically significant according to the census bureau.  on the other hand,
# the census bureau might occasionally find statistically significant differences where the code below won't detect any difference.
# in other words, the method shown below will come up with too many _false negatives_ but never a _false positive_.

# to calculate error terms / confidence intervals the census-approved way, the only current option is to follow this
# hellishly-cumbersome document where you have to multiply stuff by hand and calculate SEs for each and every statistic.
# it. is. a. nightmare.  also, note that there's a new document every year.  here:
# http://www.census.gov/housing/nychvs/data/2008/S&A_2008.pdf

# case and point: if you want to automate the calculation of error terms (or if you don't care about error terms),
# just use the back-of-the-envelope method shown below.


# a more in-depth discussion #

# the census bureau does not release one of the clustering variables - `segment` -
# due to geo-coding and confidentiality concerns, so it is impossible to re-construct
# a taylor-series linearization R survey object design that will match the census bureau CIs
# in the excel file above exactly.  for further discussion of this, take a look at this e-mail from NYCHVS administrators
# https://github.com/ajdamico/asdfree/tree/master/New%20York%20City%20Housing%20and%20Vacancy%20Survey/the%20census%20bureau%20and%20the%20impossible%20to%20reproduce%20SEs.pdf?raw=TRUE



# set your working directory.
# the file 'nychvs08.rda' should have been stored here
# after downloading and importing it.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NYCHVS/" )
# ..in order to set your current working directory


# install the survey package by removing the `#` but hey just once.
# install.packages( "survey" )


library(survey)		# load survey package (analyzes complex design surveys)


# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN


# load the 2011 data files
load( 'nychvs11.rda' )


# recode the `tenure2` column (renters vs. owners) so it's a boolean (0 or 1) variable based on ownership of the unit
occ <- transform( occ , owners = findInterval( tenure2 , 4 ) )


# convert all 9999999 income values to zero
# (missings according to the codebook)
occ[ occ$yhincome == 9999999 , 'yhincome' ] <- 0

# convert all 99999 monthly rental values to zer
# (missings according to the codebook)
occ[ occ$rentm == 99999 , 'rentm' ] <- 0


# be sure to check the codebook for whichever values you analyze!
# here's the 2011 codebook for the occupied units data frame.
# http://www.census.gov/housing/nychvs/data/2011/occ_11_long.pdf
# note all the missings for the variables i'm using that need to be blanked out?  yeah huh.

# convert this newly-modified column to factor variables
occ$owners <- factor( occ$owners )


# add monthly contract rental categories to the data.frame
occ$rent.cat <- cut( occ$rentm , c( 0 , 499 , 699 , 799 , 899 , 999 , 1249 , 1499 , 1749 , 1999 , 2499 , Inf ) )


# the new york city borough variable is actually not numeric
# and will need to be shown broken out, so convert it to a factor
# at the get-go to make it break out automatically (you'll see)
occ$borough <- factor( occ$borough )


# # # # # #
# warning #
# # # # # #

# standard errors, confidence intervals, and variances from this survey design object
# should * not * be * used without modifications.  for a more complete discussion of the issue, view:
# https://github.com/ajdamico/asdfree/blob/master/New%20York%20City%20Housing%20and%20Vacancy%20Survey/replicate%20contract%20items%202008.R





#################
# survey design #
#################

# create survey design object with the desired table
# (occ, vac, per, ni)
# using existing data.frame of NYCHVS data

# create survey design object with just the `hhweight`
# (household weight) variable
occ.d <- svydesign( ~1 , data = occ , weights = ~hhweight )


	
#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in the occupancy table #
# broken out by renters vs. owners #

svyby(
	~one ,
	~owners ,
	occ.d ,
	unwtd.count
)



# count the weighted number of households in the nychvs occ table #

svytotal(
	~one ,
	occ.d
)

# note that this is exactly equivalent to summing up the weight variable
# from the original occ data frame

sum( occ$hhweight )

# the weighted number of occupied households in new york city #
# by borough
svyby(
	~one ,
	~borough ,
	occ.d ,
	svytotal
)


# calculate the mean of a linear variable #

# average monthly contract rent
svymean(
	~rentm ,
	design = occ.d
)

# by borough
svyby(
	~rentm ,
	~borough ,
	design = occ.d ,
	svymean
)


# calculate the distribution of a categorical variable #


# percent owners - city-wide
svymean(
	~owners ,
	design = occ.d
)

# by borough
svyby(
	~owners ,
	~borough ,
	design = occ.d ,
	svymean
)

# calculate the distribution of a previously-created categorical variable #

# http://www.nyc.gov/html/hpd/downloads/pdf/HPD-2011-HVS-Selected-Findings-Tables.pdf

# table 14
coef( svymean( ~rent.cat , occ.d , na.rm = TRUE ) )

# note that since we're only using the survey weights here
# (and we're not currently concerned with standard errors)
# we can re-run this analysis using the original data frame,
# summing up the weights by rent.cat
tapply( occ$hhweight , occ$rent.cat , sum )
# if you don't understand `tapply`, watch this two-minute video:
# http://www.screenr.com/JQS8



# http://www.nyc.gov/html/hpd/downloads/pdf/HPD-2011-HVS-Selected-Findings-Tables.pdf
# reproduce table 9

# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum
# household income
svyquantile(
	~yhincome ,
	design = occ.d ,
	c( 0 , .25 , .5 , .75 , 1 )
)

# by ownership
svyby(
	~yhincome ,
	~owners ,
	design = occ.d ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	keep.var = F
)

######################
# subsetting example #
######################

# here's the purpose of converting `borough` to a factor variable (as shown above)

# http://www.nyc.gov/html/hpd/downloads/pdf/HPD-2011-HVS-Selected-Findings-Tables.pdf
# reproduce second column of table 5

# restrict the occ.d object to
# renters only
rental.units <- subset( occ.d , owners == 0 )
# now any of the above commands can be re-run
# using the rental.units object
# instead of the occ.d object
# in order to analyze renters only

# calculate the mean of a linear variable #

# sum up the number of occupied households, restricted to renters
svytotal(
	~borough ,
	design = rental.units
)



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by borough

# store the results into a new object

rent.cat.by.borough <-
	svyby(
		~rent.cat ,
		~borough ,
		design = occ.d ,
		svymean ,
		na.rm = TRUE
	)

# print the results to the screen
rent.cat.by.borough

# now you have the results saved into a new object of type "svyby"
class( rent.cat.by.borough )

# print only the statistics (coefficients) to the screen
coef( rent.cat.by.borough )

# print only the standard errors to the screen
SE( rent.cat.by.borough )
# remember, those are *wrong* - they are too small.
# double them for a better back-of-the-envelope SE calculation
SE( rent.cat.by.borough ) * 2

# this object can be coerced (converted) to a data frame..
rent.cat.by.borough <- data.frame( rent.cat.by.borough )

# ..and then immediately exported as a comma-separated value file
# into your current working directory
write.csv( rent.cat.by.borough , "monthly contract rent category by borough.csv" )

# ..or trimmed to only contain the values you need.
# here's the "rental category above $2,500" rate by borough status,
# keeping only the borough column and the relevant data column
rent.above.2.5k.by.borough <-
	rent.cat.by.borough[  , c( "borough" , "rent.cat.2.5e.03.Inf."  ) ]


# print the new results to the screen
rent.above.2.5k.by.borough

# this can also be exported as a comma-separated value file
# into your current working directory
write.csv( rent.above.2.5k.by.borough , "monthly rent above 2500 by borough.csv" )

# ..or directly made into a bar plot
barplot(
	rent.above.2.5k.by.borough[ , 2 ] ,
	main = "Monthly Rent above $2,500 by Borough" ,
	names.arg = c( "Bronx" , "Brooklyn" , "Manhattan" , "Queens" , "Staten Island" ) ,
	ylim = c( 0 , .3 )
)
# with an image like that, how could anyone not love renting in manhattan?

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

