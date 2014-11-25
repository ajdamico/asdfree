# analyze survey data for free (http://asdfree.com) with the r language
# world values survey
# united states wave six (2011)

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/WVS/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/World%20Values%20Survey/analysis%20examples.R" , prompt = FALSE , echo = TRUE )
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



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#######################################################################################################
# prior to running this replication script, all wvs public use microdata files must be loaded as R data
# files (.rda) on the local machine. running the "download all microdata.R" script will save these
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# source_url( "https://raw.github.com/ajdamico/usgsd/master/World%20Values%20Survey/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will save R data (.rda) files in C:/My Directory/WVS/ (or the working directory chosen)
#######################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



#############################################################################
# analyze the multi-country wave six file of the world values survey with R #
#############################################################################


# set your working directory.
# all WVS data files should have been stored here
# after downloading and importing.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/WVS/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( "survey" )


library(survey) 	# load survey package (analyzes complex design surveys)
library(foreign) 	# load foreign package (converts data files into R)


# by default, R will crash if a primary sampling unit (psu) has a single observation
# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
# by uncommenting this line:
# options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN


# the r data.frame object can be loaded directly
# from your local hard drive,
# since the download script has already run

# load the united states wave six (2011) data.frame object
load( "./wave 6/United States 2011/WV6_Data_United_States_2011_spss_v_2014_11-07.rda" )

# display the number of rows in the wave six data set
nrow( x )

# display the first six records in the wave six data set
head( x )


#############################
# fake survey design object #
#############################

# # # # # # #
# user note #
# # # # # # #

# the public use microdata of the world values survey
# waves 1 through 6 do not allow users to calculate
# a survey-adjusted standard error, because the wvs team
# did not require countries to submit their cluster variables

# therefore, standard errors calculated with this object are incorrect
# these confidence intervals and variances will be deceptively small-
# if this analysis properly accounted for the complex sampling design,
# you would expect larger standard errors, and therefore fewer significant differences.

# many of the technical documents include a nationwide "Estimated Error" statistic
# intended to act as a crude standard error for _all_ statistics within the country for that wave
# however, this is also a poor proxy for a correctly-implemented complex sample adjustment


# jaime diez-medrano, the director of the wvsa archive
# has recommended to the scientific advisory committee
# unfortunately, this change has not yet been made.

# it should be.  it costs nothing.
# countries that run the survey already have this microdata.


# if you would like to be able to correctly calculate
# confidence intervals with wvs data, please send a polite e-mail
# requesting that countries submit their sample design/cluster variables
# in the future and also for all historical data sets.

# this request should go to the scientific advisory committee
# http://www.worldvaluessurvey.org/WVSContents.jsp?CMSID=SAC
# as well as the president, secretariat, and wvsa archive director
# c.w.haerpfer@abdn.ac.uk
# bi.puranen@worldvaluessurvey.org
# jdiezmed@jdsurvey.net


# # # # # # # # # # #
# end of user note  #
# # # # # # # # # # #



# create a survey design object (wvs.usa) with incorrect design information
wvs.usa <- 
	svydesign( 
		~ 1 , 
		data = x , 
		weights = ~v258
	)
# the weighting variable here is the correct one:
# after a bit of scouring, i found page 48 of
# WV6_Tecnical_Report_United_States_2011.pdf
# however, the `~ 1` indicates no clustering,
# which is incorrect.
	
# notice the 'wvs.usa' object used in all subsequent analysis commands


#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in wvs #

# the nrow function which works on both data frame objects..
class( x )
# ..and survey design objects
class( wvs.usa )


# notice that the original data frame contains the same number of records as..
nrow( x )

# ..the survey object
nrow( wvs.usa )

# add a new variable 'one' that simply has the number 1 for each record #

wvs.usa <-
	update( 
		one = 1 ,
		wvs.usa
	)

# count the total (unweighted) number of records in wvs #
# broken out by interview language #

svyby(
	~one ,
	~v257 ,
	wvs.usa ,
	unwtd.count
)

# count the sum of the weights in wvs #

# note: this does not generalize to anything in particular.
# but if you like, you can multiply your proportions and results
# by united nations or us census bureau population estimates
svytotal( 
	~one , 
	wvs.usa 
)
# results should only be shown as _proportions_ and not totals


# weighted counts (again: meaningless)
# broken out by interview language #
svyby(
	~one ,
	~v257 ,
	wvs.usa ,
	svytotal
)


# calculate the mean of a linear variable #

# average age
svymean( 
	~v242 , 
	design = wvs.usa ,
	na.rm = TRUE
)

# by interview language
svyby( 
	~v242 , 
	~v257 ,
	design = wvs.usa ,
	svymean ,
	na.rm = TRUE
)


# calculate the distribution of a categorical variable #

# v4 should be treated as a factor (categorical) variable
# instead of a numeric (linear) variable
# this update statement converts it.
# the svyby command below will not run without this
wvs.usa <-
	update( 
		v4 = factor( v4 ) ,
		wvs.usa
	)


# distribution of importance of family - nationwide
svymean( 
	~v4 , 
	design = wvs.usa ,
	na.rm = TRUE
)

# by interview language
svyby( 
	~v4 , 
	~v257 ,
	design = wvs.usa ,
	svymean , 
	na.rm = TRUE
)

# calculate the median and other percentiles #

# note that a taylor-series survey design
# does not allow calculation of standard errors

# minimum, 25th, 50th, 75th, maximum 
# hours worked in the united states
svyquantile( 
	~v242 , 
	design = wvs.usa ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	na.rm = TRUE
)

# by interview language
svyby( 
	~v242 , 
	~v257 ,
	design = wvs.usa ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	keep.var = F ,
	na.rm = TRUE
)

######################
# subsetting example #
######################

# restrict the wvs.usa object to
# females only
wvs.usa.females <-
	subset(
		wvs.usa ,
		v240 == 2
	)
# now any of the above commands can be re-run
# using the wvs.usa.females object
# instead of the wvs.usa object
# in order to analyze females only
	
# calculate the mean of a linear variable #

# average age, restricted to females
svymean( 
	~v242 , 
	design = wvs.usa.females ,
	na.rm = TRUE
)



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by interview language

# store the results into a new object

family.by.language <-
	svyby( 
		~v4 , 
		~v257 ,
		design = wvs.usa ,
		svymean ,
		na.rm = TRUE
	)

# print the results to the screen 
family.by.language

# now you have the results saved into a new object of type "svyby"
class( family.by.language )

# print only the statistics (coefficients) to the screen 
coef( family.by.language )

# print only the standard errors to the screen 
SE( family.by.language )

# this object can be coerced (converted) to a data frame.. 
family.by.language <- data.frame( family.by.language )

# ..and then immediately exported as a comma-separated value file 
# into your current working directory 
write.csv( family.by.language , "importance of family by interview language.csv" )

# ..or trimmed to only contain the values you need.
# here's the percent of who say family is "very important"
# by interview langauge
very.important.by.language <-
	family.by.language[ , c( "v257" , "v41" , "se.v41" ) ]

# that's all rows, and the three specified columns


# print the new results to the screen
very.important.by.language

# this can also be exported as a comma-separated value file 
# into your current working directory..
write.csv( very.important.by.language , "very important by language.csv" )



# ..or directly made into a bar plot
barplot(
	very.important.by.language[ , 2 ] ,							# the second column of the data frame contains the main data
	main = 'Percent Indicating Family "Very Important"' ,		# title the barplot
	names = c( 'English Interview' , 'Spanish Interview' ) ,	# individual bar labels
	ylim = c( 0 , 1 ) , 										# set the lower and upper bound of the y axis
	cex.names = 2 												# column label sizes
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
