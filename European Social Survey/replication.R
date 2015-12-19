# analyze survey data for free (http://asdfree.com) with the r language
# european social survey
# 2004 and 2010 examples

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/ESS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/European%20Social%20Survey/replication.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #


# note that these statistics come very close to the statistics and standard errors published by the survey administrators
# however, occasionally exact statistics do not match because of un-reproducible version changes between
# the current downloadable microdata file and the microdata version used at original publication.


# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# https://www.youtube.com/watch?v=JLt9JfaAxUg

# daniel oberski
# daniel.oberski@gmail.com

# anthony joseph damico
# ajdamico@gmail.com

# if you use this script for a project, please send me a note
# it's always nice to hear about how people are using this stuff

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#########################################################################################################################
# prior to running this replication script, the 2004 and 2010 ess microdata files must be loaded as R data files (.rda) #
# on the local machine. running the "download all microdata.R" script will create this file for you with zero hassle.   #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/European%20Social%20Survey/download%20all%20microdata.R                  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will save a number of .rda files in C:/My Directory/ESS/ (or the working directory was chosen)            #
#########################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# set your working directory.
# all ESS R data files should have been stored in this folder.

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/ESS/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( c( 'lme4' , 'survey' , 'downloader' , 'digest' ) )


library(lme4)		# allows random effects modeling
library(survey)		# load survey package (analyzes complex design surveys)
library(downloader)	# downloads and then runs the source() function on scripts from github



# by default, R will crash if a primary sampling unit (psu) has a single observation
# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
# you'll need this for the replication scripts below.
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN



# warning: for non-simple random sample data sets, nesstar3 will
# not produce standard errors or confidence intervals correctly.

# only a few of the country-rounds _are_ simple random samples,
# so if you need any measure of variance,
# it's safer to use the R survey design object


######################################################################
# replicate the european social survey's nesstar online query system #
######################################################################


# here's a basic regression from the 2010 (5th round) edition 3 nesstar webview: http://nesstar.ess.nsd.uib.no/    #
# https://github.com/ajdamico/asdfree/blob/master/European%20Social%20Survey/nesstar%20example%20output.pdf?raw=true #


# load the 2010 integrated survey data into memory
load( "./2010/integrated.rda" )
# the integrated data file `x` is now ready for action

# remove records that are missing in either of the two regression variables
y <- subset( x , !is.na( tvtot ) & !is.na( trstun ) )

# sum up the weight variable
sum( y$dweight )

# run a simple regression using the design weight,
# using `tv watching time` as the independent and 
# `trust in the united nations` as the dependent variables
summary( lm( trstun ~ tvtot , y , weights = y$dweight ) )

# everything below the `valid N` is based on a frequency-weighted (instead of probability-weighted) sample,
# so the standard errors and F statistic starts to get slightly off here.

# but the coefficients and intercepts match.


# the middle of pdf page 4 of
# http://www.europeansocialsurvey.org/docs/methodology/ESS_weighting_data.pdf
# says

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# If you analyse data from complex designs, please bear in mind:                                                          #
# The confidence intervals computed in Nesstar WebView 3.0 are only correct for data collected by simple random sampling. #
# For more complex sample designs, design effects should be taken into consideration.                                     #
# A detailed description of the ESS sample designs can be found in the ESS Documentation Report.                          #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# but only a few country-rounds are collected as simple random samples.
# that means that most numbers related to the variance - 
# standard errors, significance values, confidence intervals, f statistics, etc. etc. -
# will be incorrectly small with nesstar.  safer to use the R survey design if you're statistical testing anything.




#########################################################################
# replicate the estimation of design effects for ess round one document #
#########################################################################


# here's some step-by-step calculations that either exactly or nearly match the official document
# http://www.europeansocialsurvey.org/docs/round1/methods/ESS1_sddf_documentation.pdf


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# some few reasons to accept the methods below as correct #

# 1) we've been able to reproduce some of the design effects precisely

# 2) others are reproduced to the precision given (2 and 3 digits)

# 3) some of this document's results were multiplied by hand (1.19 * 1.3 = 1.547), which truncates any decimals

# 4) 2157.239 magically becomes 2155 on pdf page 6

# we feel quite confident that these discrepancies are just due to the fact that the "official" design effects were calculated on earlier versions of the data, which were only slightly different.

# a reason for this may be that design effects were mostly estimated in the ESS a priori, to inform sampling design; the post-data collection deff's that exist appear more as illustration than anything else and were apparently not subjected to much scrutiny. 




# load france's round two sample design data file (sddf)..
load( "./2004/FR/ESS2__SDDF.rda" )
# ..and immediately save it to a more appropriately-named object
ess2.fr.sddf <- x

# load france's round two main data file..
load( "./2004/FR/ESS2.rda" )
# ..and immediately save it to a more appropriately-named object
ess2.fr <- x

# merge these two files together, creating a merged object..
ess2.fr.m <- merge( ess2.fr , ess2.fr.sddf )
# ..and immediately check that all record counts match up
stopifnot( nrow( ess2.fr ) == nrow( ess2.fr.m ) & nrow( ess2.fr.sddf ) == nrow( ess2.fr.m ) )

# construct one complex-sample survey design..
ess2.fr.design <- 
	svydesign(
		ids = ~psu ,
		strata = ~stratify ,
		probs = ~prob ,
		data = ess2.fr.m
	)
# ..and keep it in your back pocket.

# # # # # # # # # # # # # # # # # # # # # # # # # #
# let's run some calculations by hand, shall we?  #
# # # # # # # # # # # # # # # # # # # # # # # # # #

# example on top of pdf page 6
# "normalized" weights as suggested, although it makes no difference
w.tilde <- ( ess2.fr.m$dweight / sum( ess2.fr.m$dweight ) ) * nrow( ess2.fr.m ) 


( ssqw <- sum( w.tilde ^ 2 ) )						# slightly different from 2157.239 on pdf page 6
( sqsw <- sum( w.tilde ) ^ 2 )						# matches the seven digit number on pdf page 6
( deff.p <- nrow( ess2.fr.m ) * ( ssqw / sqsw ) )	# matches the 3-digit number given on pdf page 6


# within each unique psu, sum up and then square the weights
wcsq <- 
	tapply(
		ess2.fr.m$dweight , 
		ess2.fr.m$psu , 
		function(wcj) sum( wcj )^2
	)

# sum that result, and you're close to..
sum( wcsq )  										# the 19604 in the second example on pdf page 6

# ..in that same example, the ssq _is_ given as 2155, contrary to 2157 above
( b.star <- sum( wcsq ) / ssqw ) 					# pdf page six says 9.09

# fit a linear mixed-effects model on the variable of interest, by psu
m <- lmer( stflife ~ 1 | psu , data = ess2.fr.m )

# calculate the variance component estimate
vcm <- VarCorr(m)

# extract the variance component of the psu
var.psu <- vcm$psu[1]

#  square the residual standard deviation to obtain the variance
var.resid <- attr( vcm , "sc" ) ^ 2

# calculate the anova estimator
(rho.psu <- var.psu / (var.psu + var.resid)) 		# pdf page six says 0.0373

# from all of those components, calculate the cluster-based design effect 
( deff.c <- 1 + ( b.star - 1 ) * rho.psu )			# this rounds the same way as 1.3 on pdf page six

# multiply this out, and the numbers are slightly off of the 1.547 on pdf page six
( deff <- deff.p * deff.c )

# but watch this!
( deff.rounded <- round( deff.p , 2 ) * round( deff.c , 1 ) )
# silly, right?


# what's the takeaway from this replication exercise?
# in general, if rounding is the only driver in your different results,
# it's safe to assume that any methodological differences are not worth arguing about.


# remember how we created the R `complex-sample` design object earlier?
# now let's use that to get nearly the same result in one step.


# step one: calculate the stflife variable mean, retaining the design effect information
svymean( ~stflife , ess2.fr.design , deff = TRUE )
# we'd done all that work above to hit 1.547,
# but now, by just using the built-in survey package's functions,
# we can come staggeringly close by requesting the design effect with `deff = TRUE`


# note that the 1.547 uses only the clusters and mostly ignores stratification
# that's why "model-based" deff estimators are usually smaller than the more standard "design-based" ones.
# (model-based deff estimators do not allow for heteroskedasticity over clusters)

# so now you have the calculations both ways.
# for ease of use without any sort of methodological sacrifice,
# we implore you to construct your ESS analyses with the R survey package

# pretty cool, huh?  ;)



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
