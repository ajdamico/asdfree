# analyze survey data for free (http://asdfree.com) with the r language
# american time use survey
# 2012

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/ATUS/2012/" )
# source_url( "https://raw.github.com/ajdamico/asdfree/master/American%20Time%20Use%20Survey/2012%20single-year%20-%20analysis%20examples.R" , prompt = FALSE , echo = TRUE )
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


#######################################################
# this script matches a few of the bls statistics     # 
# shown at http://www.bls.gov/tus/tables/a1_2012.pdf  #
#######################################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#############################################################################################################
# prior to running this analysis script, the atus 2012 file must be loaded onto the local machine.  running #
# the download all microdata script below will import the respondent- and activity-level files needed.      #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/asdfree/master/American%20Time%20Use%20Survey/download%20all%20microdata.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will files in the C:/My Directory/ATUS directory or wherever the working directory was set.   #
#############################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# set your working directory.
# the ATUS 2012 data files should have been stored here
# after running the program described above
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/ATUS/2012/" )
# ..in order to set your current working directory


# remove the # in order to run this install.packages line only once
# install.packages( c( "survey" , "reshape2" ) )


library(survey)		# load survey package (analyzes complex design surveys)
library(reshape2)	# load reshape2 package (transposes data frames quickly)


# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN



# if this option is set to TRUE
# R will exactly match SUDAAN results and Stata with the MSE option results
options( survey.replicates.mse = TRUE )
# otherwise if it is commented out or set to FALSE
# R will exactly match Stata without the MSE option results

# Stata svyset command notes can be found here: http://www.stata.com/help.cgi?svyset


# loading and subsetting #

# load the activity-level file
# (one record per respondent per activity)
load( "atusact.rda" )

# limit the activity file to only the columns you need
atusact <- atusact[ , c( 'tucaseid' , 'tutier1code' , 'tutier2code' , 'tuactdur24' ) ]


# load the respondent-level file
# (one record per survey respondent)
load( "atusresp.rda" )

# limit the respondent file to only the columns you need
atusresp <- atusresp[ , c( 'tucaseid' , 'tufinlwgt' , 'tulineno' ) ]

# load the roster file
# (one record per individual
# in the survey respondent's household)
load( "atusrost.rda" )

# limit the roster file to only the columns you need
atusrost <- atusrost[ , c( 'tucaseid' , 'tulineno' , 'teage' , 'tesex' ) ]

# load the respondent-level file
# (one record per survey respondent,
# with columns containing replicate weights)
load( 'atuswgts.rda' )

# limit the replicate weights file to only the `tucaseid` (unique identifier)
# and replicate weight columns (containing the text `finlwgt`
atuswgts <- atuswgts[ , c( 1 , grep( 'finlwgt' , names( atuswgts ) ) ) ]


# recode and reshape the activity-level file #

# looking at the 2012 lexicon, travel-related activities
# have a tier 1 code of 18 --
# http://www.bls.gov/tus/lexiconnoex2012.pdf#page=22

# for all records where the tier 1 code is 18 (travel)
# replace that tier 1 of 18 with whatever's stored in tier 2
atusact[ atusact$tutier1code == 18 , 'tutier1code' ] <-
	atusact[ atusact$tutier1code == 18 , 'tutier2code' ]
# this will distribute all travel-related activities
# to the appropriate tier 1 category, which matches
# the structure of the 2012 bls table available at
# http://www.bls.gov/tus/tables/a1_2012.pdf


# sum up activity duration at the respondent-level
# *and* also the tier 1 code level
# (using tucaseid as the unique identifier)
# from the activities file
x <-
	aggregate(
		tuactdur24 ~ tucaseid + tutier1code ,
		data = atusact ,
		sum
	)

# now table `x` contains
# one record per person per major activity category

# reshape this data from "long" to "wide" format,
# creating a one-record-per-person table
y <- 
	reshape( 
		x , 
		idvar = 'tucaseid' , 
		timevar = 'tutier1code' , 
		direction = 'wide' 
	)
	
# take a look at the first six records..
head( y )
# ..and notice plenty of missing values.

# throughout this new data.frame `y`
y[ is.na( y ) ] <- 0
# convert all missings to zeroes,
# since those individuals simply did not
# engage in those activities during their interview day
# (meaning they should have zero minutes of time)

# convert this entire data.frame from minutes to hours #


# take a look at the first six records..
head( y )

# except for the first column (the unique identifier,
# replace each column by the quotient of itself and sixty
y[ , -1 ] <- y[ , -1 ] / 60

# ..and look at the first six records again.
head( y )
# make sense what just happend?
# now all results will be in hours, not minutes
# meaning they'll match bls (and other) publications


# now you've got an activity file `y`
# with one record per respondent


# merge together the data.frame objects with all needed columns
# in order to create a replicate-weighted survey design object

# merge the respondent file with the newly-created activity file
# (which, remember, is also one-record-per-respondent)
resp.y <- merge( atusresp , y )

# confirm that the result of the merge has the same number of records
# as the original bls atus respondent file. (this is a worthwhile check)
stopifnot( nrow( resp.y ) == nrow( atusresp ) )

# merge that result with the roster file
# note that the roster file has multiple records per `tucaseid`
# but only the `tulineno` columns equal to 1 will match
# records in the original respondent file, this merge works.
resp.y.rost <- merge( resp.y , atusrost )

# confirm that the result of the merge has the same number of records
stopifnot( nrow( resp.y.rost ) == nrow( atusresp ) )

# merge that result with the replicate weights file
z <- merge( resp.y.rost , atuswgts )

# confirm that the result of the merge has the same number of records
stopifnot( nrow( z ) == nrow( atusresp ) )


################
# quick recode #
################

# create a zero-one variable of any care or help of household members
# if the column `tuactdur24.3 is greater than zero,
# `any.care` is one, otherwise it's zero.
z$any.care <- ifelse( z$tuactdur24.3 > 0 , 1 , 0 )
# caring for and helping household members row
# which we know is top level 03 from
# http://www.bls.gov/tus/lexiconnoex2012.pdf



#######################################
# survey design for replicate weights #
#######################################

# add a column of all ones to the data.frame
z$one <- 1

# create survey design object with ATUS design information
# using the data.frame object `z` created from the merges above

atus.design <- 
	svrepdesign(
		weights = ~tufinlwgt ,
		repweights = "finlwgt[1-9]" , 
		type = "Fay" , 
		rho = ( 1 - 1 / sqrt( 4 ) ) ,
		data = z
	)


#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in atus #
# broken out by sex #

svyby(
	~one ,
	~tesex ,
	atus.design ,
	unwtd.count
)



# count the weighted number of person-days in atus #

# the number of person-days of the civilian,
# non-institutionalized population of the united states
# among americans older than 14
svytotal(
	~one ,
	atus.design
)
# divide this number by 365.25 and you'll almost precisely hit
# the 243,275,505 statistic in the `16 years and older` row
# of the `2010` column of table 1 from
# http://www.census.gov/prod/cen2010/briefs/c2010br-03.pdf#page=2
# because that's what the survey-weights generalize to.  schnaz.


# by sex
svyby(
	~one ,
	~tesex ,
	atus.design ,
	svytotal
)


# calculate the mean of a linear variable #

# average hours per day spent in personal care activities
svymean(
	~tuactdur24.1 ,
	design = atus.design
)
# note that this matches the "personal care activities" row
# "average hours per day, civilian population" column of
# http://www.bls.gov/tus/tables/a1_2012.pdf

# ..and here's the same calculation, but broken down by sex
svyby(
	~tuactdur24.1 ,
	~tesex ,
	design = atus.design ,
	svymean
)


# calculate the distribution of a categorical variable #

# the column any.care (created in the quick recode section above)
# should be treated as a factor (categorical) variable
# instead of a numeric (linear) variable
# this update statement converts it.
atus.design <-
	update(
		any.care = factor( any.care ) ,
		atus.design
	)


# percent performing any care of household members during the day - nationwide
svymean(
	~any.care ,
	design = atus.design
)

# note that this matches the "caring for and helping household members" row
# "average percent engaged in the activity per day" columns of
# http://www.bls.gov/tus/tables/a1_2012.pdf

# ..and here's the same calculation, but broken down by sex
svyby(
	~any.care ,
	~tesex ,
	design = atus.design ,
	svymean
)

# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum
# hours per day spent caring for other household members
svyquantile(
	~tuactdur24.3 ,
	design = atus.design ,
	c( 0 , .25 , .5 , .75 , 1 )
)

# by sex
svyby(
	~tuactdur24.3 ,
	~tesex ,
	design = atus.design ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	ci = T
)

######################
# subsetting example #
######################

# restrict the atus.design object to
# only individuals who cared for any other
# household member during the day
atus.design.caretaker <-
	subset(
		atus.design ,
		any.care %in% 1
	)
# now any of the above commands can be re-run
# using atus.design.caretaker object
# instead of the atus.design object
# in order to analyze caretakers only

# calculate the mean of a linear variable #

# among respondents performing any caretaking: average caretaker hours during the day - nationwide
svymean(
	~tuactdur24.3 ,
	design = atus.design.caretaker
)

# note that this matches the "caring for and helping household members" row
# "average hours per day for persons who engaged in the activity" columns of
# http://www.bls.gov/tus/tables/a1_2012.pdf

# ..and here's the same calculation, but broken down by sex
svyby(
	~tuactdur24.3 ,
	~tesex ,
	design = atus.design.caretaker ,
	svymean
)

###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by sex

# store the results into a new object

any.caretaking.by.sex <-
	svyby(
		~any.care ,
		~tesex ,
		design = atus.design ,
		svymean
	)

# print the results to the screen
any.caretaking.by.sex

# now you have the results saved into a new object of type "svyby"
class( any.caretaking.by.sex )

# print only the statistics (coefficients) to the screen
coef( any.caretaking.by.sex )

# print only the standard errors to the screen
SE( any.caretaking.by.sex )

# this object can be coerced (converted) to a data frame..
any.caretaking.by.sex <- data.frame( any.caretaking.by.sex )

# ..and then immediately exported as a comma-separated value file
# into your current working directory..
write.csv( any.caretaking.by.sex , "any caretaking by sex.csv" )

# ..or directly made into a bar plot
barplot(
	any.caretaking.by.sex[ , 3 ] ,
	main = "Percent Performing Any Caretaking Activity by Sex" ,
	names.arg = c( "Male" , "Female" ) ,
	ylim = c( 0 , .5 )
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
