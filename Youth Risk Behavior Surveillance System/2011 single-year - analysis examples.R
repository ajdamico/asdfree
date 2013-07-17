# analyze survey data for free (http://asdfree.com) with the r language
# youth risk behavior surveillance system
# 2011

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
# prior to running this analysis script, the yrbss 2011 single-year file must be loaded as an r data file (.rda)                                #
# on the local machine. running the 1991 - 2011 download automation script will create the appropriate files for your pleasurable convenience   #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/usgsd/blob/master/Youth%20Risk%20Behavior%20Surveillance%20System/1991%20-%202011%20download%20all%20microdata.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "yrbs2011.rda" in C:/My Directory/YRBSS or wherever the working directory was set for the program              #
#################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# remove the # in order to run this install.packages line only once
# install.packages( "survey" )


require(survey)		# load survey package (analyzes complex design surveys)


# set R to produce conservative standard errors instead of crashing
# http://faculty.washington.edu/tlumley/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN


# uncomment this line by removing the `#` at the front..
# load( "C:/My Directory/YRBSS/yrbs2011.rda" )
# ..in order to load the year of yrbs data you want to analyze


# note: this script has not set your working directory anywhere.
# the `load` line above accessess the R data file (.rda) directly
# but any output that you generate will be stored to your working directory
# to view your current working directory, type the command `getwd()`


#################################################
# survey design for taylor-series linearization #
#################################################

# create survey design object with YRBSS design information
# using existing data frame of YRBSS data loaded as `x`
y <- 
	svydesign( 
		id = ~psu , 
		strata = ~stratum , 
		data = x , 
		weights = ~weight ,
		nest = TRUE
	)

	
#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in yrbss #
# either by referring to the original data.frame..
nrow( x )
# ..or using the survey design object
unwtd.count( ~one , y )


# quick note for all the friendly folks who don't read the codebook carefully.
message( "don't be thrown off. in the 2011 yrbs, q2 = 1 indicates female, q2 = 2 indicates male." )


# broken out by male/female #

svyby(
	~one ,
	~q2 ,
	y ,
	unwtd.count
)

# count the weighted number of individuals in yrbss #
svytotal(
	~one ,
	y
)
# note that this sums to the same total as the unweighted count
# most complex sample survey weights sum up to the total population they represent
# these do not.
# so if you want to count results in millions of americans:
# you'll have to divide the number of 9th-12th graders by the number of records in this data set


# basically, in the short-term, this just means that the `svytotal` function won't be of much use to ya  ;)


# calculate the mean of a linear variable #

# average body mass index percentile within the respondent's age and sex cohort
svymean( ~bmipct , design = y , na.rm = TRUE )

# by sex
svyby(
	~bmipct ,
	~q2 ,
	design = y ,
	svymean ,
	na.rm = TRUE ,
	na.rm.all = TRUE
)



# calculate the distribution of a categorical variable #

# qn11 should be treated as a factor (categorical) variable
# instead of a numeric (linear) variable
# this update statement converts it.
y <-
	update(
		qn11 = factor( qn11 ) ,
		y
	)


# percent who had driven drunk in the past month
svymean(
	~qn11 ,
	design = y ,
	na.rm = TRUE
)

# by sex
svyby(
	~qn11 ,
	~q2 ,
	design = y ,
	svymean ,
	na.rm = TRUE ,
	na.rm.all = TRUE
)

# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum
# body mass index percentile within the respondent's age and sex cohort
svyquantile(
	~bmipct ,
	design = y ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	na.rm = TRUE
)

# by sex
svyby(
	~bmipct ,
	~q2 ,
	design = y ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	ci = T ,
	na.rm = TRUE ,
	na.rm.all = TRUE
)

######################
# subsetting example #
######################

# restrict the y object to
# females only
y.female <-
	subset(
		y ,
		q2 %in% 1
	)
# now any of the above commands can be re-run
# using y.female object
# instead of the y object
# in order to analyze females only

# calculate the mean of a linear variable #

# average body mass index percentile within the respondent's age and sex cohort
svymean(
	~bmipct ,
	design = y.female ,
	na.rm = TRUE
)



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by sex

# store the results into a new object

drunk.driving.by.sex <-
	svyby(
		~qn11 ,
		~q2 ,
		design = y ,
		svymean ,
		na.rm = TRUE
	)

# print the results to the screen
drunk.driving.by.sex

# now you have the results saved into a new object of type "svyby"
class( drunk.driving.by.sex )

# print only the statistics (coefficients) to the screen
coef( drunk.driving.by.sex )

# print only the standard errors to the screen
SE( drunk.driving.by.sex )

# this object can be coerced (converted) to a data frame..
drunk.driving.by.sex <- data.frame( drunk.driving.by.sex )

# you can throw out records where respondents did not
# answer the sex question (q2)
drunk.driving.by.sex <-
	drunk.driving.by.sex[ drunk.driving.by.sex$q2 %in% 1:2 , ]
# by overwriting the data.frame with itself,
# only keeping records where the value of q2 is a 1 or a 2
# for more detail on this technique, view twotorials.com
# videos #019, #047, or #058

# print the new results to the screen
drunk.driving.by.sex

# ..and then immediately exported as a comma-separated value file
# into your current working directory
write.csv( drunk.driving.by.sex , "drunk driving by sex.csv" )


# ..or directly made into a bar plot
barplot(
	drunk.driving.by.sex[ , 2 ] ,
	main = "Percent of Adolescents Who Have Driven Drunk in the Past 30 Days" ,
	names.arg = c( "Female" , "Male" ) ,
	ylim = c( 0 , .1 )
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
