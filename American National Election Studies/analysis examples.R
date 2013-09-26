# analyze survey data for free (http://asdfree.com) with the r language
# american national election studies
# 2012
# time series

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/ANES/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/American%20National%20Election%20Studies/analysis%20examples.R" , prompt = FALSE , echo = TRUE )
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



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################
# prior to running this replication script, all anes public use microdata files must be loaded as R data            #
# files (.rda) on the local machine. running the "download and import.R" script will create these files.            #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/usgsd/blob/master/American%20National%20Election%20Studies/download%20and%20import.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will save a number of .rda files in C:/My Directory/ANES/ (or the working directory was chosen)       #
#####################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



######################################################################
# Analyze the 2012 TS American National Election Studies file with R #
######################################################################


# set your working directory.
# all ANES data files will be stored here
# after downloading and importing.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/ANES/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( "survey" )


require(survey)  # load survey package (analyzes complex design surveys)


# by default, R will crash if a primary sampling unit (psu) has a single observation
# set R to produce conservative standard errors instead of crashing
# http://faculty.washington.edu/tlumley/survey/exmample-lonely.html
# by uncommenting this line:
# options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN

# load the 2012 time series file
load( "./2012 Time Series Study/anes_timeseries_2012.rda" )

# display the number of rows in the merged data set
nrow( x )

# display the first six records in the merged data set..
head( x )
# ..and notice it's way too much information to reasonably print to the screen, so..


# create a character vector that will be used to
# limit the file to only the variables needed
KeepVars <-
	c( 
		"caseid" ,				# unique record identifiers
		
		"weight_full" , 		# full-sample weights
		
		"strata_full" ,			# full-sample strata variable

		"sample_fullpsu" ,		# newly-created full-sample cluster variable
		
		"dem_agegrp_iwdate" , 	# respondent age group
		
		"gender_respondent" ,	# respondent sex
		
		"dem_hrsrecent" ,		# how many hours do you work the average week
		
		"tea_supp"				# do you support or oppose the tea party
	)

	
# # # # # # # # # # # # # # # # # # # # # # #
# create a clustering variable for both the #
# face-to-face and the web version together #
# # # # # # # # # # # # # # # # # # # # # # #

# confirm that the `mode` column contains
# only ones and twos (face-to-face and web)
stopifnot( all( x$mode %in% c( 1 , 2 ) ) )

# for face-to-face responses, the cluster variable
# is the same as it is for sample_ftfpsu
x[ x$mode %in% 1 , 'sample_fullpsu' ] <-
	x[ x$mode %in% 1 , 'sample_ftfpsu' ]
	
# for the web responses, the cluster variable
# should be completely unique.
# the easiest way to create a unique variable is
# to find a starting point..
starting.point <- max( x$sample_ftfpsu , na.rm = TRUE ) + 1

# ..and then extract the unique record numbers
# of each of the web records, but re-hash them to start at 1
web.psu.line <- as.numeric( as.factor( which( x$mode %in% 2 ) ) )

# at this point, add them to the starting point and slip 'em in
x[ x$mode %in% 2 , 'sample_fullpsu' ] <- web.psu.line

# # # # # # # # # # # # # # # # # # # #
# end of clustering variable creation #
# # # # # # # # # # # # # # # # # # # #



# limit the r data frame (x) containing all variables
# to a severely-restricted r data frame containing only the seven variables
# specified in character vector 'KeepVars'
y <- x[ , KeepVars ]

# to free up RAM, remove the full r data frame
rm( x )

# garbage collection: clear up RAM
gc()


# anyone with a negative value in any of these variables..
negatives.to.blank <- c( "dem_agegrp_iwdate" , "gender_respondent" , "dem_hrsrecent" , "tea_supp" )
# ..should actually have a missing instead
y[ , negatives.to.blank ] <- sapply( y[ , negatives.to.blank ] , function( z ) { z[ z < 0 ] <- NA ; z } )




#################################################
# survey design for taylor-series linearization #
#################################################

# create a survey design object (anes.design) with ANES design information
anes.design <- 
	svydesign( 
		~sample_fullpsu , 
		strata = ~strata_full , 
		data = y , 
		weights = ~weight_full , 
		nest = TRUE 
	)
	
# notice the 'anes.design' object used in all subsequent analysis commands


#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in anes #

# the nrow function which works on both data frame objects..
class( y )
# ..and survey design objects
class( anes.design )


# notice that the original data frame contains the same number of records as..
nrow( y )

# ..the survey object
nrow( anes.design )


# count the total (unweighted) number of records in anes #
# broken out by age group #

svyby(
	~tea_supp ,
	~dem_agegrp_iwdate ,
	anes.design ,
	unwtd.count
)



# count the weighted number of individuals in anes #

# add a new variable 'one' that simply has the number 1 for each record #

anes.design <-
	update( 
		one = 1 ,
		anes.design
	)

# eligible voters in the united states #
svytotal( 
	~one , 
	anes.design 
)
# note: weights are *not* scaled to the eligible voting population
# therefore, results should only be shown as _proportions_ and not totals


# eligible voters in the united states #
# broken out by age group #
svyby(
	~one ,
	~dem_agegrp_iwdate ,
	anes.design ,
	svytotal
)


# calculate the mean of a linear variable #

# average hours worked per week - among all eligible voters
svymean( 
	~dem_hrsrecent , 
	design = anes.design ,
	na.rm = TRUE
)

# by age group
svyby( 
	~dem_hrsrecent , 
	~dem_agegrp_iwdate ,
	design = anes.design ,
	svymean ,
	na.rm = TRUE
)


# calculate the distribution of a categorical variable #

# tea_supp should be treated as a factor (categorical) variable
# instead of a numeric (linear) variable
# this update statement converts it.
# the svyby command below will not run without this
anes.design <-
	update( 
		tea_supp = factor( tea_supp ) ,
		anes.design
	)


# distribution of tea party support (support/oppose/neither) - nationwide
svymean( 
	~tea_supp , 
	design = anes.design ,
	na.rm = TRUE
)

# by age group
svyby( 
	~tea_supp , 
	~dem_agegrp_iwdate ,
	design = anes.design ,
	svymean , 
	na.rm = TRUE
)

# calculate the median and other percentiles #

# note that a taylor-series survey design
# does not allow calculation of standard errors

# minimum, 25th, 50th, 75th, maximum 
# hours worked in the united states
svyquantile( 
	~dem_hrsrecent , 
	design = anes.design ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	na.rm = TRUE
)

# by age group
svyby( 
	~dem_hrsrecent , 
	~dem_agegrp_iwdate ,
	design = anes.design ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	keep.var = F ,
	na.rm = TRUE
)

######################
# subsetting example #
######################

# restrict the anes.design object to
# females only
anes.design.female <-
	subset(
		anes.design ,
		gender_respondent %in% 2
	)
# now any of the above commands can be re-run
# using the anes.design.female object
# instead of the anes.design object
# in order to analyze females only
	
# calculate the mean of a linear variable #

# average hours worked - nationwide, restricted to females
svymean( 
	~dem_hrsrecent , 
	design = anes.design.female ,
	na.rm = TRUE
)



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by age group

# store the results into a new object

tea_supp.by.age <-
	svyby( 
		~tea_supp , 
		~dem_agegrp_iwdate ,
		design = anes.design ,
		svymean ,
		na.rm = TRUE
	)

# print the results to the screen 
tea_supp.by.age

# now you have the results saved into a new object of type "svyby"
class( tea_supp.by.age )

# print only the statistics (coefficients) to the screen 
coef( tea_supp.by.age )

# print only the standard errors to the screen 
SE( tea_supp.by.age )

# this object can be coerced (converted) to a data frame.. 
tea_supp.by.age <- data.frame( tea_supp.by.age )

# ..and then immediately exported as a comma-separated value file 
# into your current working directory 
write.csv( tea_supp.by.age , "tea_supp by age.csv" )

# ..or trimmed to only contain the values you need.
# here's the percent of the country who self-identify as
# tea party supporters by age, with accompanying standard errors
tea_supp.rate.by.age <-
	tea_supp.by.age[ , c( "dem_agegrp_iwdate" , "tea_supp1" , "se.tea_supp1" ) ]

# that's all rows, and the three specified columns


# print the new results to the screen
tea_supp.rate.by.age

# this can also be exported as a comma-separated value file 
# into your current working directory 
write.csv( tea_supp.rate.by.age , "tea_supp rate by age.csv" )


# construct a character vector containing the labels of each age group
age.group.labels <- c( "17 - 20" , "21 - 24" , "25 - 29" , "30 - 34" , "35 - 39" , "40 - 44" , "45 - 49" , "50 - 54" , "55 - 59" , "60 - 64" , "65 - 69" , "70 - 74" , "75 or older" )


# ..or directly made into a bar plot
barplot(
	tea_supp.rate.by.age[ , 2 ] ,				# the second column of the data frame contains the main data
	main = "Tea Party Support by Age Group" ,	# title the barplot
	names.arg = age.group.labels ,				# the first column of the data frame contains the names of each bar
	ylim = c( 0 , .4 ) , 						# set the lower and upper bound of the y axis
	cex.names = 0.8 ,							# shrink the column labels so they all fit
	las = 2										# rotate the labels so they're vertical
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
