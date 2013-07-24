# analyze survey data for free (http://asdfree.com) with the r language
# national longitudinal study of adolescent health
# wave 1 public use file replication

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

# note that the university of north carolina's carolina population center only publishes standard error examples
# using the restricted access data files (shown here):
# http://www.cpc.unc.edu/projects/addhealth/data/guides/wt-guidelines.pdf#page=18
# so to confirm that the methodology below is correct, i asked the folks at unc..
# https://github.com/ajdamico/usgsd/blob/master/National%20Longitudinal%20Study%20of%20Adolescent%20Health/Gmail%20-%20precisely%20replicating%20a%20SE%20statistic%20with%20AddHealth.pdf?raw=true
# ..to provided me some example stata output run on the public use file (puf).  they did.  radical.
# https://github.com/ajdamico/usgsd/blob/master/National%20Longitudinal%20Study%20of%20Adolescent%20Health/Stata_example.txt
# this r script will replicate the statistics from that custom run of the national longitudinal study of adolescent health (addhealth) exactly



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###########################################################################################################################################
# prior to running this replication script, at least wave 1 of the addhealth public use microdata files must be loaded as R data          #
# files (.rda) on the local machine. running the "download and consolidate.R" script will create these files.                             #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/usgsd/master/National%20Longitudinal%20Study%20of%20Adolescent%20Health/download%20and%20consolidate.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will save a number of .rda files in C:/My Directory/AddHealth/ (or the working directory chosen)                            #
###########################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


#######################################################################
# Analyze the National Longitudinal Study of Adolescent Health with R #
#######################################################################


# set your working directory.
# the wave 1 AddHealth consolidated file should have been stored within this folder
# so if "wave 1 consolidated.rda" exists in the directory "C:/My Directory/AddHealth/"
# then the working directory should be set to "C:/My Directory/AddHealth/"  easy.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/AddHealth/" )
# ..in order to set your current working directory


# remove the # in order to run this install.packages line only once
# install.packages( "survey" )

# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #


require(survey)  # load survey package (analyzes complex design surveys)


# by default, R will crash if a primary sampling unit (psu) has a single observation
# set R to produce conservative standard errors instead of crashing
# http://faculty.washington.edu/tlumley/survey/exmample-lonely.html
# by keeping this line uncommented:
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN


# the r data frame can be loaded directly from your local hard drive
load( "wave 1 consolidated.rda" )


# display the number of rows in the wave 1 consolidated data set
nrow( cons )

# display the first six records in the wave 1 data set
head( cons )
# note that the data frame contains far too many variables to be viewed conveniently

# create a character vector that will be used to
# limit the file to only the variables needed
KeepVars <-
	c( 
		"gswgt1" , 		# wave 1 cross-sectional analytic weight
		
		"cluster2" , 	# primary sampling units
		
		"h1gi1y" ,		# year of birth
		
		"h1gi1m" ,		# month of birth
		
		"iyear" ,		# interview year
		
		"imonth" , 		# interview month
		
		"iday" , 		# interview day
		
		"bio_sex" ,		# male/female
		
		"ah_pvt" ,		# vocabulary test score
		
		"h1da8"			# hours of television watched
	)


# limit the r data frame (cons) containing all variables
# to a severely-restricted r data frame containing only the ten variables
# specified in character vector 'KeepVars'
x <- cons[ , KeepVars ]

# to free up RAM, remove the full r data frame
rm( cons )

# garbage collection: clear up RAM
gc()

# calculate the birth date, interview date, and `boy` variables
# to match the stata code used by unc
x <-
	transform(
		x ,
		
		# paste the year and month of birth together into a string,
		# (just set everyone's day of birth to the 15th of the month)
		# and immediately convert that string to a `date` class
		birthdate = as.Date( paste0( "19" , h1gi1y , "-" , h1gi1m , "-15" ) ) ,
		
		# paste the year-month-day of the interview all together into a string
		# and likewise, make it a date variable.
		w1intdate = as.Date( paste0( "19" , iyear , "-" , imonth , "-" , iday ) ) ,
		
		# make a `boy` true or false flag.
		boy = ( bio_sex == 1 )
		# really that simple
		
	)

# calculate the age-at-wave-1-interview
# by subtracting the interview date from the birth date,
# dividing by 365.25 (don't forget your leap years)
# and then converting the column type to an integer.
cons$w1age <- as.integer( ( cons$w1intdate - cons$birthdate ) / 365.25 )

# at this point, we've got all the variables we need to replicate unc's example stata output	
	
#################################################
# survey design for taylor-series linearization #
#################################################

# create a survey design object (y) with AddHealth design information
y <- 
	svydesign( 
		id = ~cluster2 , 
		data = x , 
		weights = ~gswgt1 , 
		nest = TRUE 
	)
	

#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in the wave 1 national longitudinal study of adolescent health data set #

# the nrow function which works on both data frame objects..
class( x )
# ..and survey design objects
class( y )


# notice that the original data frame contains the same number of records as..
nrow( x )

# ..the survey object
nrow( y )


# add a new variable 'one' that simply has the number 1 for each record #
# and can be used to calculate unweighted and weighted population sizes #

y <-
	update( 
		one = 1 ,
		y
	)


################################################################
# print the exact contents of the stata document to the screen #
################################################################

# email from unc carolina population center
# https://github.com/ajdamico/usgsd/blob/master/National%20Longitudinal%20Study%20of%20Adolescent%20Health/Gmail%20-%20precisely%20replicating%20a%20SE%20statistic%20with%20AddHealth.pdf?raw=true

# stata code (and output) from unc carolina population center
# https://github.com/ajdamico/usgsd/blob/master/National%20Longitudinal%20Study%20of%20Adolescent%20Health/Stata_example.txt


# time spent watching tv #

# unweighted counts #
# (sample size column) #
unwtd.count( ~h1da8 , y )

# weighted counts #
# (population size column) #
svytotal( ~one , y )			# total valid cases

# degrees of freedom for the survey design object
degf( y )

# weighted mean with standard error
svymean( ~h1da8 , y , na.rm = TRUE )

# alternatively, save this result into another object `z`
z <- svymean( ~h1da8 , y , na.rm = TRUE )

# ..and specifically query just the coefficient..
coef( z )

# ..or just the standard error..
SE( z )

# ..or just the confidence interval.
confint( z )
# what's that, you say?  the confidence interval doesn't precisely match stata?
# that's because stata uses the degrees of freedom of the survey object
confint( z , df = degf( y ) )
# as opposed to r's default, df = Inf


# regression time. #

# is performance on the vocab test related to
# age, sex, and/or time spent watchin' the teevee?

# here's a simple regression..
svyglm( ah_pvt ~ w1age + boy + h1da8 , y )

# ..but you might want more detail, so put it inside the summary function.
summary( svyglm( ah_pvt ~ w1age + boy + h1da8 , y ) )


########################################################################
# end of printing the exact contents of the unc document to the screen #
########################################################################


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
