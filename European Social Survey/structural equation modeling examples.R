# analyze survey data for free (http://asdfree.com) with the r language
# european social survey
# 2008 structural equation modeling examples

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/ESS/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/European%20Social%20Survey/structural%20equation%20modeling%20examples.R" , prompt = FALSE , echo = TRUE )
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



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#########################################################################################################
# prior to running this example script, the 2008 ess microdata files must be loaded as R data files     #
# on the local machine. running the "download all microdata.R" script will create everything for you.   #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/usgsd/master/European%20Social%20Survey/download%20all%20microdata.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will save a number of .rda files in C:/My Directory/ESS/ (or the working directory used)  #
#########################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# set your working directory.
# all ESS R data files should have been stored in this folder.

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/ESS/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( 'lavaan.survey' )

library(lavaan.survey)	# latent variable analysis / structural equation modeling for complex sample survey data


# by default, R will crash if a primary sampling unit (psu) has a single observation
# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
# you'll need this for the replication scripts below.
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN


# load Germany's round four main data file..
load( "./2008/DE/ESS4.rda" )
# ..and immediately save it to a more appropriately-named object
ess4.de <- x

# load Germany's round four sample design data file (sddf)..
load( "./2008/DE/ESS4__SDDF.rda" )
# ..and immediately save it to a more appropriately-named object
ess4.de.sddf <- x

# The stratify variable is not literally equal to the actual strata but contains
#    more information (which we don't need here). 

# Create a new variable that only uses the actual stratification 
#  namely, East v. West Germany.

# use a regular expression / string substitution function to..
# take the data.frame object's `stratify` variable, convert it to a character variable, search for a dash, and keep only the text before the dash.
# then convert that resultant vectors of ones and twos into a factor variable, labeled east versus west germany.
ess4.de.sddf$stratify <- factor( gsub( "(\\d+)-.+" , "\\1" , as.character( ess4.de.sddf$stratify ) ) )
levels(ess4.de.sddf$stratify) <- c("West Germany", "East Germany")

# Check against ESS documentation statement that 
# "The number of sampling points is 109 in the West, and 59 in the East"
# (p. 120 of this document:
#  http://www.europeansocialsurvey.org/docs/round4/survey/ESS4_data_documentation_report_e05_1.pdf )
stopifnot(tapply(ess4.de.sddf$psu, 
                 ess4.de.sddf$stratify, 
                 function(x) length(unique(x))) == c(109, 59))

# note that the sample design data files (sddf) do not get released
# at the same time as the main data file, for some odd reason.
# since that prevents you from knowing how good your estimates actually are,
# it's an incomplete analysis.  better to wait for the full data.
# survey research has two components:
# knowing something (the coefficient) and
# understanding how well you know it (the variance)

# merge these two files together, creating a merged object..
ess4.de.m <- merge( ess4.de , ess4.de.sddf)
# ..and immediately check that all record counts match up
stopifnot( nrow( ess4.de ) == nrow( ess4.de.m ) & nrow( ess4.de.sddf ) == nrow( ess4.de.m ) )


# create a survey design object (ess4.de.design) with ESS design information
ess4.de.design <- 
  svydesign(
    ids = ~psu ,
    strata = ~stratify ,
    probs = ~prob ,
    data = ess4.de.m
  )


#######################################################################
# Two-factor CFA of attitudes to the welfare state
#######################################################################

# This analysis uses the model of the below article. Please see the 
#  article for more information.

# Roosma, F., Gelissen, J., & van Oorschot, W. (2013). The multidimensionality
#     of welfare state attitudes: a European cross-national study. Social 
#     indicators research, 113(1), 235-255.

# Formulate the two-factor CFA using lavaan syntax
model.cfa <-    
	"range =~ gvjbevn + gvhlthc + gvslvol + gvslvue + gvcldcr + gvpdlwk
	 goals =~ sbprvpv  +  sbeqsoc  +  sbcwkfm"

# Fit the model using lavaan, accounting for possible nonnormality
#     using the MLM estimator.
fit.cfa.ml <- 
	lavaan(
		model.cfa , 
		data = ess4.de.m , 
		estimator = "MLM" , 
		int.ov.free = TRUE ,
		auto.var = TRUE , 
		auto.fix.first = TRUE , 
		auto.cov.lv.x = TRUE
	)

# Show some fit measure results, 
#     note the "scaling correction" which accounts for nonnormality
fit.cfa.ml

# Fit the two-factor model while taking the survey design into account.
fit.cfa.surv <- 
	lavaan.survey(
		fit.cfa.ml , 
		survey.design = ess4.de.design
	)

# Show some fit measure results, 
#     "scaling correction" now accounts for nonnormality AND survey design.
fit.cfa.surv

# Display parameter estimates and standard errors accounting for survey design 
summary( fit.cfa.surv , standardized = TRUE )


#######################################################################
# Invariance testing on Schwarz human values while accounting for the 
# survey design.
#######################################################################


# For more information on this analysis, see:
#
# Davidov, E., Schmidt, P., & Schwartz, S. H. (2008). "Bringing values 
#       back in: The adequacy of the European Social Survey to measure 
#       values in 20 countries". Public opinion quarterly, 72(3), 420-445.
# 
# (Cited by 201 as of 2014-03 according to Google Scholar.)

# I will test the measurement equivalence of Schwarz human values from
#    round 4 of the ESS, comparing Germany with Spain. 

# First load the Spanish data so these can be merged.


# load Spain's round four main data file..
load( "./2008/ES/S4.rda" )
# ..and immediately save it to a more appropriately-named object
ess4.es <- x

# load Spain's round four sample design data file (sddf)..
load( "./2008/ES/S4__SDDF.rda" )
# ..and immediately save it to a more appropriately-named object
ess4.es.sddf <- x

# merge these two files together, creating a merged object..
ess4.es.m <- merge( ess4.es , ess4.es.sddf)
# ..and immediately check that all record counts match up
stopifnot( nrow( ess4.es ) == nrow( ess4.es.m ) & nrow( ess4.es.sddf ) == nrow( ess4.es.m ) )


# Make sure PSU names are unique between the two countries
# do this by pasting on a "de-" to the german psus, and..
ess4.de.m$psu <- paste( "de" , ess4.de.m$psu , sep="-" )
# by pasting an "es-" to the front of the spanish psus.
ess4.es.m$psu <- paste( "es" , ess4.es.m$psu , sep="-" )


# Join the two countries into a wonderful union that pleases all.
ess4.m <- rbind( ess4.de.m , ess4.es.m )


# Create a new survey design object that 
ess4.design <- 
  svydesign(
    ids = ~psu,
    strata = ~stratify ,
    probs = ~prob ,
    data = ess4.m
  )

# Model based on Schwarz human value theory. 
#   Note that this is the basic starting model, not the final model used
#   by Davidov et al. They merge certain values and allow cross-loadings.

free.values.model.syntax <- " 
  Universalism =~ ipeqopt + ipudrst + impenv
  Benevolence  =~ iphlppl + iplylfr

  Tradition    =~ ipmodst + imptrad
  Conformity   =~ ipfrule + ipbhprp 
  Security     =~ impsafe + ipstrgv
"

# Fit two-group configural invariance model
free.values.fit <- 
	lavaan(
		free.values.model.syntax , 
		data = ess4.m , 
		auto.cov.lv.x = TRUE , 
		auto.fix.first = TRUE , 
		auto.var = TRUE ,
		int.ov.free = TRUE , 
		estimator = "MLM" ,
		group = "cntry"
	)

summary( free.values.fit , standardized = TRUE )

# Fit two-group metric invariance model
free.values.fit.eq <- 
	lavaan(
		free.values.model.syntax , 
		data = ess4.m , 
		auto.cov.lv.x = TRUE , 
		auto.fix.first = TRUE , 
		auto.var = TRUE ,
		int.ov.free = TRUE , 
		estimator = "MLM" ,
		group = "cntry" , 
		group.equal = "loadings"
	)

summary( free.values.fit.eq , standardized = TRUE )

# Metric invariance test
#   (anova() would work here too, but not below)
lavTestLRT( free.values.fit , free.values.fit.eq , SB.classic = TRUE )


free.values.fit.surv <- lavaan.survey( free.values.fit , ess4.design )

# Compare chisquares of the survey and non-survey SEM analyses
#    For the configural invariance model
free.values.fit
free.values.fit.surv


free.values.fit.eq.surv <- lavaan.survey( free.values.fit.eq , ess4.design )

# Compare chisquares of the survey and non-survey SEM analyses
#    For the metric invariance model
free.values.fit.eq
free.values.fit.eq.surv


# Perform metric invariance test accounting for the survey design
lavTestLRT(free.values.fit.surv, free.values.fit.eq.surv, SB.classic = TRUE)

# The two models are more dissimilar after survey design is accounted for.

#######################################################################
# An example with a latent variable regression
#######################################################################

# See

# Davidov, E., Meuleman, B., Billiet, J., & Schmidt, P. (2008). Values and 
#       support for immigration: A cross-country comparison. European 
#       Sociological Review, 24(5), 583-599.

# The human values scale again, but this time:
#     1) only two value dimensions are modeled;
#     2) the two latent value dimensions are used to predict anti-immigration
#         attitudes in the two countries.
#     3) a test is performed on the difference between countries in 
#         latent regression coefficients.

reg.syntax <- "
  SelfTranscendence =~ ipeqopt + ipudrst + impenv + iphlppl + iplylfr
  Conservation =~ ipmodst + imptrad + ipfrule + ipbhprp + impsafe + ipstrgv

  ALLOW =~ imdfetn + impcntr

  ALLOW ~ SelfTranscendence + Conservation
"


reg.vals.fit <- 
	lavaan(
		reg.syntax , 
		data = ess4.m , 
		group = "cntry" ,
		estimator = "MLM" ,
		auto.cov.lv.x = TRUE , 
		auto.fix.first = TRUE , 
		auto.var = TRUE , 
		int.ov.free = TRUE
	)

reg.vals.fit.eq <- 
	lavaan( 
		reg.syntax , 
		data = ess4.m , 
		group = "cntry" , 
		group.equal = "regressions" ,
		estimator = "MLM" ,
		auto.cov.lv.x = TRUE , 
		auto.fix.first = TRUE , 
		auto.var = TRUE , 
		int.ov.free = TRUE
	)

	
summary( reg.vals.fit.eq , standardize = TRUE )

# Test whether the relationship between values and anti-immigration attitudes
#    is equal in Germany and Spain
lavTestLRT( reg.vals.fit , reg.vals.fit.eq , SB.classic = TRUE)


# Now do the same but accounting for the sampling design.
reg.vals.fit.surv <- lavaan.survey( reg.vals.fit , ess4.design )
reg.vals.fit.eq.surv <- lavaan.survey( reg.vals.fit.eq , ess4.design )

lavTestLRT(reg.vals.fit.surv, reg.vals.fit.eq.surv, SB.classic = TRUE)

# The two models are less dissimilar after survey design is accounted for.



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
