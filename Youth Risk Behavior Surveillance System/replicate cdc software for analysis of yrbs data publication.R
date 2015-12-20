# analyze survey data for free (http://asdfree.com) with the r language
# youth risk behavior surveillance system
# 2009

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# load( "C:/My Directory/YRBSS/yrbs2009.rda" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Youth%20Risk%20Behavior%20Surveillance%20System/replicate%20cdc%20software%20for%20analysis%20of%20yrbs%20data%20publication.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


################################################################################
# this script matches the SUDAAN statistics and standard errors as well as the #
# STATA svy proportions on pages 25 and 26 of this pdf:                        #
# http://www.cdc.gov/healthyyouth/yrbs/pdf/YRBS_analysis_software.pdf#page=25  #
# though slightly dated, the author of the R survey package, Dr. Thomas Lumley #
# wrote a similar document that matched a previously-published comparisons doc #
# http://staff.washington.edu/tlumley/survey/YRBS-report-extension.pdf         #
################################################################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###################################################################################################################################
# prior to running this replication script, the yrbss 2009 single-year file must be loaded as an r data file (.rda)               #
# on the local machine. running the download automation script will create the appropriate files for your pleasurable convenience #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/asdfree/blob/master/Youth%20Risk%20Behavior%20Surveillance%20System/download%20all%20microdata.R    #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "yrbs2009.rda" in C:/My Directory/YRBSS or wherever the working directory was set                #
###################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


###################################################################
# analyze the 2009 Youth Risk Behavior Surveillance System with R #
###################################################################


# uncomment this line by removing the `#` at the front..
# load( "C:/My Directory/YRBSS/yrbs2009.rda" )
# ..in order to load the year of yrbs data you want to analyze


# note: this script has not set your working directory anywhere.
# the `load` line above accessess the R data file (.rda) directly
# but any output that you generate will be stored to your working directory
# to view your current working directory, type the command `getwd()`


# remove the # in order to run this install.packages line only once
# install.packages( "survey" )


library(survey)		# load survey package (analyzes complex design surveys)



#################################################
# survey design for taylor-series linearization #
#################################################

# create taylor-series linearization survey design object
# with YRBSS design information using the data frame `x`
y <- 
	svydesign( 
		~psu , 
		strata = ~stratum , 
		data = x , 
		weights = ~weight ,
		nest = TRUE
	)


# the above complex sample survey design object `y` can be used to
# precisely replicate SUDAAN's coefficients and standard errors

# for each of the three survey questions, both print the results of
# the `svymean` call to the screen - by encapsulating the statement in ( )
# and also save it into some separate object that can be queried later
( helmet <- svymean( ~as.numeric( qn8 == 1 ) , y , na.rm = TRUE ) )
( hadsex <- svymean( ~as.numeric( qn58 == 1 ) , y , na.rm = TRUE ) )
( heroin <- svymean( ~as.numeric( qn52 == 1 ) , y , na.rm = TRUE ) )

# extract the standard errors from these three `svymean` calls
SE( helmet )
SE( hadsex )
SE( heroin )


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# warning: the syntax presented from this point forward should not be used for your analysis. please. the code below exactly matches the STATA  #
# output published by the CDC, but i only perform this exercise to prove understanding this complex sample survey data set, and not really as   #
# an analysis example.  replicating STATA precisely requires the creation of a new survey design object for every single statistic, which is    #
# unwieldy and kind of unnecessary.  instead of starting your analysis from the code in this file, use please the `analysis examples` syntax at #
# https://github.com/ajdamico/asdfree/blob/master/Youth%20Risk%20Behavior%20Surveillance%20System/2011%20single-year%20-%20analysis%20examples.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # # # # # # #
# never or rarely wear a bike helmet  #

# construct a complex sample survey design object
# from the 2009 ybrs data.frame, where all records
# missing `qn8` (the helmet question) have been excluded
y.qn8 <- 
	svydesign( 
		~psu , 
		strata = ~stratum , 
		# this `data =` line is goofy, and only useful to match STATA
		data = subset( x , !is.na( qn8 ) ) , 
		weights = ~weight ,
		nest = TRUE
	)


# print the `svymean` call to the screen - by encapsulating the statement in ( )
# and also save it into an object called `helmet` that can be queried later
( helmet <- svymean( ~as.numeric( qn8 == 1 ) , y.qn8 ) )

# extract this survey design object's degrees of freedom
degf( y.qn8 )

# query the `helmet` object's confidence intervals,
# using the `y.qn8's degrees of freedom in the interval calculation
confint( helmet , df = degf( y.qn8 ) )

# count the unweighted number of records in the survey object
nrow( y.qn8 )

# total up the weights available in `y.qn8` 
# ..and then extract only the coefficient (the coef function) 
# ..and then round to the nearest whole number (the round function)
round( coef( svytotal( ~one , y.qn8 ) ) )


# # # # # # # # # # # # # # # #
# ever had sexual intercourse #

# construct a complex sample survey design object
# from the 2009 ybrs data.frame, where all records
# missing `qn58` (the had sex question) have been excluded
y.qn58 <- 
	svydesign( 
		~psu , 
		strata = ~stratum , 
		# this `data =` line is goofy, and only useful to match STATA
		data = subset( x , !is.na( qn58 ) ) , 
		weights = ~weight ,
		nest = TRUE
	)


# print the `svymean` call to the screen - by encapsulating the statement in ( )
# and also save it into an object called `hadsex` that can be queried later
( hadsex <- svymean( ~as.numeric( qn58 == 1 ) , y.qn58 ) )

# extract this survey design object's degrees of freedom
degf( y.qn58 )

# query the `hadsex` object's confidence intervals,
# using the `y.qn58's degrees of freedom in the interval calculation
confint( hadsex , df = degf( y.qn58 ) )

# count the unweighted number of records in the survey object
nrow( y.qn58 )

# total up the weights available in `y.qn58` 
# ..and then extract only the coefficient (the coef function) 
# ..and then round to the nearest whole number (the round function)
round( coef( svytotal( ~one , y.qn58 ) ) )


# # # # # # # # # # #
# ever used heroin  #

# construct a complex sample survey design object
# from the 2009 ybrs data.frame, where all records
# missing `qn52` (the had sex question) have been excluded
y.qn52 <- 
	svydesign( 
		~psu , 
		strata = ~stratum , 
		# this `data =` line is goofy, and only useful to match STATA
		data = subset( x , !is.na( qn52 ) ) , 
		weights = ~weight ,
		nest = TRUE
	)


# print the `svymean` call to the screen - by encapsulating the statement in ( )
# and also save it into an object called `heroin` that can be queried later
( heroin <- svymean( ~as.numeric( qn52 == 1 ) , y.qn52 ) )

# extract this survey design object's degrees of freedom
degf( y.qn52 )

# query the `heroin` object's confidence intervals,
# using the `y.qn52's degrees of freedom in the interval calculation
confint( heroin , df = degf( y.qn52 ) )

# count the unweighted number of records in the survey object
nrow( y.qn52 )

# total up the weights available in `y.qn52` 
# ..and then extract only the coefficient (the coef function) 
# ..and then round to the nearest whole number (the round function)
round( coef( svytotal( ~one , y.qn52 ) ) )


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
