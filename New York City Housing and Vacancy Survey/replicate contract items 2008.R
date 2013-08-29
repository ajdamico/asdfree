# analyze survey data for free (http://asdfree.com) with the r language
# new york city housing and vacancy survey
# 2008

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NYCHVS/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/New%20York%20City%20Housing%20and%20Vacancy%20Survey/replicate%20contract%20items%202008.R" , prompt = FALSE , echo = TRUE )
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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#########################################################################################################################################################
# prior to running this analysis script, the `occ` `vac` `per` `ni` data.frames for the current year must be available on the local machine. running..  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# https://raw.github.com/ajdamico/usgsd/master/New%20York%20City%20Housing%20and%20Vacancy%20Survey/2002%20-%202011%20-%20download%20all%20microdata.R  #
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
# https://github.com/ajdamico/usgsd/tree/master/New%20York%20City%20Housing%20and%20Vacancy%20Survey/the%20census%20bureau%20and%20the%20impossible%20to%20reproduce%20SEs.pdf?raw=TRUE



# set your working directory.
# the file 'nychvs08.rda' should have been stored here
# after downloading and importing it.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NYCHVS/" )
# ..in order to set your current working directory


# install the survey package by removing the `#` but hey just once.
# install.packages( "survey" )


require(survey)		# load survey package (analyzes complex design surveys)


# set R to produce conservative standard errors instead of crashing
# http://faculty.washington.edu/tlumley/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN


# load all four of the 2008 data files
load( 'nychvs08.rda' )


# recode the `tenure2` column (renters vs. owners) so it's a boolean (0 or 1) variable based on ownership of the unit
occ <- transform( occ , owners = findInterval( tenure2 , 4 ) )

# blank out some of the structure class values
occ[ occ$strclass %in% c( 6 , 11:12 ) , 'strclass' ] <- NA


# convert both of these newly-modified columns to factor variables
occ$strclass <- factor( occ$strclass )
occ$owners <- factor( occ$owners )


# create survey design object with just the `hhweight`
# (household weight) variable
y <- svydesign( ~1 , data = occ , weights = ~hhweight )

# # # # # #
# warning #
# # # # # #

# at this point, using svymean, svyquantile, svytotal and all other functions listed on
# http://faculty.washington.edu/tlumley/survey/
# will result in confidence intervals and standard errors that are *too small* - that is, false positives.

# to get only false negatives, simply multiply the standard errors by *two*
# or (this is exactly equivalent) multiply the variance by four.


# ready to start reproducing excel column D from this document?
# http://www.census.gov/housing/nychvs/data/2008/contract_items_2008.xls


# calculate the overall occupied housing units
a <- svytotal( ~one , y )
# here's cell D9
coef( a )

# multiply the variance by four
attr( a , 'var' ) <- attr( a , 'var' ) * 4

# our statistic has not changed..
coef( a )
# ..but now the standard error will be doubled.
# here's the widened +/- 90% confidence interval
SE( a ) * qnorm( 0.95 )
# remember, this will be slightly larger than cell E9 in every case
# so you'll get some false negatives.  for more detail, look up
# the epidemiological terms `sensitivity` and `specificity`
# this test is not sensitive enough, but it is specific.  ;)

# or print the confidence interval directly
confint( a , level = 0.9 )


# calculate the statistics shown in D14 - D22..
a <- svytotal( ~strclass , y , na.rm = TRUE )
# ..still calculating the modified (widened) SE
attr( a , 'var' ) <- attr( a , 'var' ) * 4

coef( a )
SE( a ) * qnorm( 0.95 )
confint( a , level = 0.9 )


# calculate the statistics shown in D26 - D27..
a <- svytotal( ~owners , y , na.rm = TRUE )
# ..still calculating the modified (widened) SE
attr( a , 'var' ) <- attr( a , 'var' ) * 4

coef( a )
SE( a ) * qnorm( 0.95 )
confint( a , level = 0.9 )


# calculate the statistics shown in D31 - D101..
a <- svyby( ~one , ~ subboro + borough , y , svytotal )

# now for `svyby` commands, note the difference in this off-the-cuff modification #

# instead of modifying the variance attribute,
# simply multiply the standard error by two.
a$se <- a$se * 2


coef( a )
SE( a ) * qnorm( 0.95 )
confint( a , level = 0.9 )


# yeah.  i get that this method isn't terribly desirable.
# but your choices are:
# a) follow the generalized variance formula: http://www.census.gov/housing/nychvs/data/2008/S&A_2008.pdf
# b) pay the census bureau for custom crosstabs
# c) do it my way.
# best of luck to you  ;)


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
