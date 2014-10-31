# analyze survey data for free (http://asdfree.com) with the r language
# national longitudinal surveys
# nlsy97

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NLS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/usgsd/master/National%20Longitudinal%20Surveys/longitudinal%20analysis%20examples.R" , prompt = FALSE , echo = TRUE )
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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#############################################################################################################################
# prior to running this analysis script, the complete NLS microdata for your study must be loaded on your local machine     #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/usgsd/master/National%20Longitudinal%20Surveys/download%20all%20microdata.R    #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will a bunch of R data files (.rda) within the "C:/My Directory/NLS/" folder (or specified working directory) #
#############################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# set your working directory.
# the NLS files for the study you'd like to analyze
# should have been stored within this folder
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NLS/" )
# ..in order to set your current working directory


# remove the # in order to run this install.packages line only once
# install.packages( c( "downloader" , "survey" ) )


library(downloader) # downloads and then runs the source() function on scripts from github
library(survey)		# load survey package (analyzes complex design surveys)

# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN


# specify which variables you'll need for this particular analysis.  this is important.
vfta <- 
	c( 
		# 2011 TOTAL INCOME FROM WAGES AND SALARY IN PAST YEAR
		'T7545600' , 
		
		# SEX, RS GENDER (SYMBOL)
		'R0536300' , 
		
		# 1997 ASVAB MATH_VERBAL SCORE PERCENT
		'R9829600' , 
		
		# 2011 RS COLLAPSED MARITAL STATUS
		'T6662900' ,
		
		# 1997 RS RELATIONSHIP TO HOUSEHOLD PARENT FIGURE
		'R1205300'
	)
# just slop all of the variables you'll need together here in a single character vector.

# load the custom weights function to easily & automatically pull
# the weights you need for your specific analysis into R
source_url( "https://raw.githubusercontent.com/ajdamico/usgsd/master/National%20Longitudinal%20Surveys/custom%20weight%20download%20functions.R" , prompt = FALSE )
# you can read more about longitudinal weights here
# http://www.nlsinfo.org/weights


# the get.nlsy.weights function returns a data.frame object
# containing the unique person identifiers and also a column of weights.

# this makes it easy to choose the correct longitudinal weight for whatever analysis you're trying to do.

# view which points-in-time are available for a particular study
# get.nlsy.selections( "nlsy97" )

# download weights for respondents in 1997
# w97 <- get.nlsy.weights( "nlsy97" , 'YES' , 'SURV1997' )
# save those weights into an data.frame object called `w97`

# download weights for respondents who were in **any** of the 1997 or 2011 surveys
# w9711.any <- get.nlsy.weights( "nlsy97" , 'YES' , c( 'SURV1997' , 'SURV2011' ) )
# save those weights into an data.frame object called `w9711.any`

# download weights for respondents who were in **all** of the 1997 and 2011 surveys
w9711.all <- get.nlsy.weights( "nlsy97" , 'NO' , c( 'SURV1997' , 'SURV2011' ) )
# save those weights into an data.frame object called `w9711.all`

# check out the results of those two previous commands.
# table( w9711.any$weight == 0 )
# the `w970207.any` table does not have any zero-weighted records
# table( w9711.any$weight == 0 , w9711.all$weight == 0 )
# but the `w9711.all` has quite a few zeroes,
# thanks to survey attrition

# download weights for respondents who are in every single round
# w <- get.nlsy.weights( "nlsy97" , "NO" , get.nlsy.selections( "nlsy97" ) )
# save those weights into an data.frame object called `w`


# specify the name of the study you're working through
study.name <- "NLSY97 1997-2011 (rounds 1-15)"
# this is just the name of the folder within your NLS directory
# if you're unsure of the name, use
# list.files()
# to see the options ;)

# load the sampling cluster and strata variables
load( paste0( "./" , study.name , "/" , "strpsu.rda" ) )
# note: this is *only* available for the 1997 study.
# the cluster and strata variables for earlier studies
# have not been posted.  in order to obtain them, you can
# either fill out the (free!) geocoded data application at
# http://www.bls.gov/nls/geocodeapp.htm
# or you can contact `NLSYGeocode@bls.gov` and request
# that they post the strata and cluster variables publicly
# for earlier studies the way they have done for the NLSY97 study.

# if you analyze an nlsy microdata set without
# the clustering and strata variables,
# all of your measures of precision
# (standard errors, confidence intervals,
# variances, t-tests) will be wrong.

# merge the weights data.frame with the sampling cluster data.frame
x <- merge( strpsu , w9711.all , by.x = 'R0000100' , by.y = 'id' )

# loop through all variables needed for this analysis,
# limiting that vector to the first four characters
# (this is how the files are organized on your local disk)
for ( i in unique( substr( vfta , 1 , 4 ) ) ){

	# load an R data file (.rda) into working memory
	load( paste0( "./" , study.name , "/" , i , ".rda" ) )

	# store the number of records in your current `x` data.frame
	before.nrow <- nrow( x )
	
	# merge the R data file you've just loaded onto `x`
	x <- merge( x , get( i ) )
	
	# confirm that this has not altered the record count
	stopifnot( nrow( x ) == before.nrow )
	
	# remove the smaller file you'd just loaded from working memory..
	rm( list = i ) ; gc()
	# ..and immediately clear up RAM

}

# alright!  now you've got all of the variables you need for your analysis
# bound together into a single R data.frame object.  look at the first six records
head( x )

# blank out all missing values, everywhere.
x[ x < 0 ] <- NA
# negatives in nlsy microdata are missings.

# look again
head( x )

# add a column of all ones
x$one <- 1

# divide the weights by 100 so your weights sum to the sample universe
x$weight <- x$weight / 100
# this survey is representative of a cohort of about 19 million young adults
sum( x$weight )
# there they are.  got it?

# construct a complex-sample survey design object
y <- 
	svydesign( 
		~ R1489800 , 
		strata = ~ R1489700 , 
		data = x ,
		weights = ~ weight ,
		nest = TRUE
	)
# using the sampling information plus the custom weight.



#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in the 1997 - 2011 nlsy97 #
# broken out by marital status in 2011 #

svyby(
	~one ,
	~T6662900 ,
	y ,
	unwtd.count
)

# count the weighted number of individuals in nlsy97 #

# the weighted universe of this survey
svytotal( ~one , y )


# the weighted universe of this survey
# by marital status in 2011
svyby( ~one , ~T6662900 , y , svytotal )


# hold on tight. #

##############################
# longitudinal data analysis #

# among young adults who lived both two biological parents in 1997,
# ..here is their marital status breakout in 2011
svyby(
	~ factor( T6662900 ) ,
	~( R1205300 == 1 ) ,
	y ,
	svytotal ,
	na.rm = TRUE
)

# let's say that a different way: #

# 44% of young adults who lived both two biological parents in 1997 were married in 2011.
# 35% of young adults who did not live with both two biological parents in 1997 were married in 2011.

svyby(
	~ as.numeric( T6662900 == 1 ) ,
	~( R1205300 == 1 ) ,
	y ,
	svymean ,
	na.rm = TRUE
)

# a statistically significant finding.
svyttest( ( R1205300 == 1 ) ~ as.numeric( T6662900 == 1 ) , y )

# # # # # # # # next # # # # # # # #

# calculate the median score from an aptitude assessment administered in 1997
median.score <- svyquantile( ~ R9829600 , y , 0.5 , na.rm = TRUE )

# calculate the median wages and salary earned in 2011
svyquantile( ~ T7545600 , y , 0.5 , na.rm = TRUE )

# calculate the median wages and salary earned in 2011,
# broken out by whether or not the individual scored in the top half of an aptitude assessment
# administered way back in 1997
svyby( 
	~ T7545600 , 
	~ ( R9829600 > median.score[1] ) ,
	y ,
	svyquantile ,
	0.5 ,
	na.rm = TRUE ,
	ci = TRUE
)

# so.  the top half of 1997 test scorers earned a median salary/wages of $35,500 in 2011
# while the bottom half of 1997 test scorers earned a median of $27,000


# make sense?  these two examples above show the most important feature of the NLS: longitudinal data analysis #
################################################################################################################


# calculate the mean of a linear variable #

# 2011 TOTAL INCOME FROM WAGES AND SALARY IN PAST YEAR
svymean(
	~ T7545600 ,
	design = y ,
	na.rm = TRUE
)

# by marital status in 2011
svyby(
	~ T7545600 ,
	~ T6662900 ,
	design = y ,
	svymean ,
	na.rm = TRUE
)


# calculate the distribution of a categorical variable #

# percent male
svymean(
	~factor( R0536300 )	,
	design = y ,
	na.rm = TRUE
)

# by marital status in 2011
svyby(
	~factor( R0536300 ) ,
	~T6662900 ,
	design = y ,
	svymean ,
	na.rm = TRUE
)

# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum
# 2011 TOTAL INCOME FROM WAGES AND SALARY IN PAST YEAR
svyquantile(
	~T7545600 ,
	design = y ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	na.rm = TRUE
)

# by marital status in 2011
svyby(
	~T7545600 ,
	~T6662900 ,
	design = y ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	ci = TRUE ,
	na.rm = TRUE
)

######################
# subsetting example #
######################

# restrict the y object to
# females only
y.female <-
	subset(
		y ,
		R0536300 %in% 2
	)
# now any of the above commands can be re-run
# using y.female object
# instead of the y object
# in order to analyze females only

# calculate the mean of a linear variable #

# 2011 TOTAL INCOME FROM WAGES AND SALARY IN PAST YEAR
svymean(
	~T7545600 ,
	design = y.female ,
	na.rm = TRUE
)



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by gender

# store the results into a new object

gender.by.marital.status <-
	svyby(
		~factor( R0536300 ) ,
		~T6662900 ,
		design = y ,
		svymean ,
		na.rm = TRUE
	)

# print the results to the screen
gender.by.marital.status

# now you have the results saved into a new object of type "svyby"
class( gender.by.marital.status )

# print only the statistics (coefficients) to the screen
coef( gender.by.marital.status )

# print only the standard errors to the screen
SE( gender.by.marital.status )

# this object can be coerced (converted) to a data frame..
gender.by.marital.status <- data.frame( gender.by.marital.status )

# ..and then immediately exported as a comma-separated value file
# into your current working directory
write.csv( gender.by.marital.status , "gender by marital status.csv" )

# ..or trimmed to only contain the values you need.
# here's the percent female by marital status breakouts,
# with accompanying standard errors
pf.by.ms <- gender.by.marital.status[ , c( "T6662900" , "factor.R0536300.2" , "se.factor.R0536300.2" ) ]


# print the new results to the screen
pf.by.ms

# this can also be exported as a comma-separated value file
# into your current working directory
write.csv( pf.by.ms , "percent female by marital status.csv" )

# ..or directly made into a bar plot
barplot(
	pf.by.ms[ , 2 ] ,
	main = "Among Marital Status Categories, Percent Female" ,
	names.arg = c( "Never Married" , "Married" , "Separated" , "Divorced" , "Widowed" ) ,
	ylim = c( 0 , 1 )
)
# note that the `widowed` category is bizarrely lopsided.
# why would three-quarters of widowed respondents be female?
svyby( ~ one , ~ T6662900 , y , unwtd.count )
# the sample size of this category is too small.

# this is a survey of a panel of adults who are still relatively young.
# at this young age, only eleven respondents have been  widowed.
# that percent is garbage.


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
