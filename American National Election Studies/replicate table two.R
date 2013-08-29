# analyze survey data for free (http://asdfree.com) with the r language
# american national election studies
# 2008
# time series

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/ANES/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/American%20National%20Election%20Studies/replicate%20table%20two.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# this r script will replicate each of the statistics from the anes publication
# http://www.electionstudies.org/resources/papers/nes012492.pdf#page=27
# column labeled "model 3" - and see footnote text-"model 3 employs the recommended method"

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
# Analyze the 2008 TS American National Election Studies file with R #
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

# load the 2008 time series file
load( "./2008 Time Series Study/anes_timeseries_2008.rda" )

# display the number of rows in the merged data set
nrow( x )

# display the first six records in the merged data set..
head( x )
# ..and notice it's way too much information to reasonably print to the screen, so..


# determine which variables need missing values recoded 
mvrv <-
	c( "v083097" , "v083098a" , "v083098b" , "v083037a" , "v083037b" , "v081101" , "v085044a" , "v083184" , "v083216x" , "v083217" , "v083103" , "v083303" , "v083212x" , "v081102" , "v080102" )

# construct a character vector containing all columns needed for this analysis,
# choosing mostly just the variables assigned in the previous command,
# but also throwing in the stratum and psu for good measure
KeepVars <-
	c( 
		"v081205" , # stratum
		
		"v081206" ,	# psu

		mvrv		# all variables specified in the stata script
					# that need to be recoded to missings if negative
	)


# now restrict the data.frame `x` to only the specified variables..
y <- x[ , KeepVars ]
# ..and notice the data.frame `y` is much more manageable

# display the first six records
head( y )

# note the record count has not changed between x and y
stopifnot( nrow( x ) == nrow( y ) )


#########################
# perform a few recodes #

# loop through every column specified by the `mvrv` object
# and replace all records with values between -9 and -1 with missing
y[ mvrv ] <- 
	lapply( 
		y[ mvrv ] , 
		function( z ) { z[ z %in% -9:-1 ] <- NA ; z } 
	)

# create a binary 'voted for obama' variable	
y[ y$v085044a %in% 1 , 'voteobama' ] <- 1
y[ y$v085044a %in% c( 3 , 7 ) , 'voteobama' ] <- 0


# create a binary "married" variable

# everyone starts off as unmarried..
y$married <- 0
# ..but if v083216x is one, they're considered married
y[ y$v083216x %in% 1 , 'married' ] <- 1

# create a party id variable
y <-
	transform(
		y ,
		pid = 
			ifelse( v083097 %in% 1 & v083098a %in% 1 , 1 ,
			ifelse( v083097 %in% 1 & v083098a %in% 5 , 2 , 
			ifelse( v083098b %in% 5 , 3 ,
			ifelse( v083098b %in% 3 , 4 ,
			ifelse( v083098b %in% 1 , 5 ,
			ifelse( v083097 %in% 2 & v083098a %in% 5 , 6 ,
			ifelse( v083097 %in% 2 & v083098a %in% 1 , 7 , 
				NA ) ) ) ) ) ) )
	)
	
# create a binary 'black' variable	
y[ y$v081102 %in% c( 2 , 6 , 7 ) , 'black' ] <- 1
y[ y$v081102 %in% c( 1 , 4 , 5 ) , 'black' ] <- 0

# set 'the bible is the word of god' variable to missing if it's a 7
y[ y$v083184 %in% 7 , 'v083184' ] <- NA

# scale these variables to zero-one
y <-
	transform(
		y ,
		pid = ( pid - 1 ) / 6 ,
		obamaft = v083037a / 100 ,
		mccainft = v083037b / 100 ,
		female = v081101 - 1 ,
		biblewog = c( 1 , 0.5 , 0 )[ v083184 ] ,
		edu = v083217 / 17 ,
		gaymil = c( 1 , 0.667 , NA , 0.333 , 0 )[ v083212x ] ,
		obsinfo = c( 1 , 0.75 , 0.5 , 0.25 , 0 )[ v083303 ] ,
		iraqworth = c( 1 , NA , NA , NA , 0 )[ v083103 ]
	)

# end of recoding #
###################


#################################################
# survey design for taylor-series linearization #
#################################################

# create a survey design object (gss.design) with GSS design information
z <- 
	svydesign( 
		~v081205 , 
		strata = ~v081206 , 
		data = y , 
		weights = ~v080102 ,
		nest = TRUE
	)


#############################################################
# print the exact contents of the full column to the screen #
#############################################################

# specify the variables to use in your model
my.formula <- voteobama ~ pid + obamaft + mccainft + female + biblewog + edu + iraqworth + black + gaymil + obsinfo
# dependent variable = voting for obama
# all other variables specified are independent

# unweighted logistic regression assuming a simple random sample (this is wrong)
unwtd.srs.logit <- glm( my.formula , y , family = 'binomial' )

summary( unwtd.srs.logit )

# weighted logistic regression assuming a simple random sample (this is also wrong)
wtd.srs.logit <- glm( my.formula , y , family = 'binomial' , weights = v080102 )

summary( wtd.srs.logit )

# survey-adjusted logistic regression (this is correct)
svy.logit <- svyglm( my.formula , z , family = 'binomial' )

# and here's the model 3 output you were promised:
summary( svy.logit )
# compare this output to
# http://www.electionstudies.org/resources/papers/nes012492.pdf#page=27

# note that a few numbers do not match precisely precisely precisely,
# notice, for example, the "appeared informed" coefficient should round down to 1.0
# and "female" should round down to 0.0 instead of up to 0.1 - 
# even though the standard errors are correct in both cases.

# so i ran the stata code included in this document here myself:
# http://www.electionstudies.org/resources/papers/nes012492.pdf#page=28
# and stata produced this output for me:
# https://github.com/ajdamico/usgsd/blob/master/American%20National%20Election%20Studies/stata%20code%20and%20output%20almost%20matching%20table%20two.txt
# and - if you're looking ultra-carefully - you'll see my r output matches
# what happens when i re-run their stata code myself exactly..
# so i think there are just a few typos in their official pdf ;)


##################################################################
# end of printing the exact contents of the column to the screen #
##################################################################


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
