# analyze survey data for free (http://asdfree.com) with the r language
# progress in international reading literacy study
# a few examples from the user guide, you know how it goes.

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/PIRLS/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Progress%20in%20International%20Reading%20Literacy%20Study/analysis%20examples.R" , prompt = FALSE , echo = TRUE )
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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###########################################################################################################################################
# prior to running this analysis script, the piaac multiply-imputed tables must be loaded as a replicate-weighted survey object on the    #
# local machine. running the download, import, and design script will create an r data file (.rda) with whatcha need.                     #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "https://raw.github.com/ajdamico/usgsd/master/Progress%20in%20International%20Reading%20Literacy%20Study/download%20import%20and%20design.R"  ###
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create the files "asg_ash_design.rda" and "asg_design.rda" in C:/My Directory/PIRLS or wherever the working directory was set. #
###################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PIRLS/" )


library(survey)			# load survey package (analyzes complex design surveys)
library(mitools) 		# load mitools package (analyzes multiply-imputed data)
library(downloader)		# downloads and then runs the source() function on scripts from github

# load the multiply-imputed design combination alteration function (scf.MIcombine)
# from the survey of consumer finances directory.  that function's algorithm is what pirls uses.
source_url( "https://raw.github.com/ajdamico/usgsd/master/Survey%20of%20Consumer%20Finances/scf.survey.R" , prompt = FALSE )


# the pirls directory contains two types of survey design objects:
# multiply-imputed and not-multiply-imputed.

# if the data.frame had *any* plausible value columns,
# then the survey design is a multiply-imputed one
# and the analysis syntax is slightly different.


# # # # # # # # # # # # # # # # # # # #
# let's start with a unimputed design #
# # # # # # # # # # # # # # # # # # # #

# load the ASG (student background) + ASH (home background) merged design
load( "./2011/asg_ash_design.rda" )

# if you type the survey object's name directly into the console
asg_ash_design
# it won't mention anything about having 5 implicates.
# replicates are not implicates.

# you could also look at its class
class( asg_ash_design )
# normal svrepdesign object, not imputed.


# recodes to pirls tables are simple.
# just use the `update` function
# the way you would use the `transform` function on a data.frame object

# add a column of all ones to the design
asg_ash_design <- update( asg_ash_design , one = 1 )

# the update function works the same way on unimputed and multiply-imputed designs.
# you can read more about it by typing
# ?survey::update.svyrep.design


# count the total (unweighted) number of records in the unimputed design #
nrow( asg_ash_design )


# count the total (unweighted) number of records in pirls #
# broken out by country #
svyby( ~ one , ~ idcntry , asg_ash_design , unwtd.count )

# count the weighted number of students who pirls represents worldwide
svytotal( ~ one , asg_ash_design )

# by country
svyby( ~ one , ~ idcntry , asg_ash_design , svytotal )

# calculate the mean of a linear variable #

# average contextual scale scores - across all individuals in the data set
svymean( ~ asbhela , asg_ash_design , na.rm = TRUE )

# by country
svyby( ~ asbhela , ~ idcntry , asg_ash_design , svymean , na.rm = TRUE , na.rm.all = TRUE )


# calculate the distribution of a categorical variable #

# birth year should be treated as a factor (categorical) variable
# instead of a numeric (linear) variable
# this update statement converts it.
# the commands below will not give distributions without this
asg_ash_design <- update( asg_ash_design , itbirthy = factor( itbirthy ) )


# percent of respondent by year of birth - nationwide
svymean( ~ itbirthy , asg_ash_design , na.rm = TRUE )

# by country
svyby( ~ itbirthy , ~ idcntry , asg_ash_design , svymean , na.rm = TRUE , na.rm.all = TRUE )


# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum
# contextual scale score
svyquantile( 
	~ asbhela , 
	asg_ash_design ,
	c( 0 , .25 , .5 , .75 , 1 )  , 
	method = 'constant' , 
	interval.type = 'quantile' ,
	na.rm = TRUE
)

# by year of birth
svyby( 
	~ asbhela , 
	~ itbirthy , 
	asg_ash_design ,
	svyquantile , 
	c( 0 , .25 , .5 , .75 , 1 ) , 
	method = 'constant' , 
	interval.type = 'quantile' ,
	na.rm = TRUE ,
	na.rm.all = TRUE
) 


######################
# subsetting example #
######################

# restrict the asg_design object to australia
aust_design <- subset( asg_ash_design , idcntry == 36 )
# now any of the above commands can be re-run
# using aust_design object
# instead of the asg_design object
# in order to analyze australia only

# calculate the mean of a linear variable #

# average reading achievement - nationwide, 
# restricted to australia
svymean( ~ asbhela , aust_design , na.rm = TRUE )

# remove both designs to clear up memory
rm( aust_design , asg_ash_design )

# clear up RAM
gc()


# # # # # # # # # # # # # # # # # # # # # # #
# now let's load a multiply-imputed design  #
# # # # # # # # # # # # # # # # # # # # # # #

# load the ASG (student background) design
load( "./2011/asg_design.rda" )

# here the survey object reveals its an imputation list
class( asg_design )

# recodes to pirls tables are simple.
# just use the `update` function
# the way you would use the `transform` function on a data.frame object

# add a column of all ones to the multiply-imputed design
asg_design <- update( asg_design , one = 1 )

# the update function works the same way on unimputed and multiply-imputed designs.
# you can read more about it by typing
# ?survey::update.svyrep.design


# count the total (unweighted) number of records in the imputed design #
nrow( asg_design )


# count the total (unweighted) number of records in pirls #
# broken out by country #
scf.MIcombine( with( asg_design , svyby( ~ one , ~ idcntry , unwtd.count ) ) )

# count the weighted number of students who pirls represents worldwide
scf.MIcombine( with( asg_design , svytotal( ~ one ) ) )

# by country
scf.MIcombine( with( asg_design , svyby( ~ one , ~ idcntry , svytotal ) ) )

# calculate the mean of a linear variable #

# average reading achievement - across all individuals in the data set
scf.MIcombine( with( asg_design , svymean( ~ asrrea ) ) )

# by country
scf.MIcombine( with( asg_design , svyby( ~ asrrea , ~ idcntry , svymean ) ) )


# # # # # # # # # # #
# sidenote sidenote #
# need to save RAM? #
# keep only columns #
# you need.  use... #

# choose which variables to keep (this line you should edit)
kv <- c( 'asrrea' , 'one' , 'idcntry' , 'itsex' )

# toss unnecessary columns from the multiply-imputed design (this line you should not edit)
asg_design$designs <- lapply( asg_design$designs , function( z ) { z$variables <- z$variables[ , kv ] ; z } )

# suddenly, your RAM has been freed up.  cool.
# # # # # # # # # #
# end of sidenote #
# # # # # # # # # #


# calculate the distribution of a categorical variable #

# sex should be treated as a factor (categorical) variable
# instead of a numeric (linear) variable
# this update statement converts it.
# the commands below will not give distributions without this
asg_design <- update( asg_design , itsex = factor( itsex ) )


# percent of respondent males vs. females - nationwide
scf.MIcombine( with( asg_design , svymean( ~ itsex , na.rm = TRUE ) ) )

# by country
scf.MIcombine( with( asg_design , svyby( ~ itsex , ~ idcntry , svymean , na.rm = TRUE , na.rm.all = TRUE ) ) )


# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum
# reading achievement score
scf.MIcombine( 
	with( 
		asg_design , 
		svyby( 
			~ asrrea , 
			~ one , 
			svyquantile , 
			c( 0 , .25 , .5 , .75 , 1 )  , 
			method = 'constant' , 
			interval.type = 'quantile'
		) 
	) 
)

# by sex
scf.MIcombine( 
	with( 
		asg_design , 
		svyby( 
			~ asrrea , 
			~ itsex , 
			svyquantile , 
			c( 0 , .25 , .5 , .75 , 1 ) , 
			method = 'constant' , 
			interval.type = 'quantile' ,
			na.rm = TRUE ,
			na.rm.all = TRUE
		) 
	) 
)


######################
# subsetting example #
######################

# restrict the asg_design object to australia
aust_design <- subset( asg_design , idcntry == 36 )
# now any of the above commands can be re-run
# using aust_design object
# instead of the asg_design object
# in order to analyze australia only

# calculate the mean of a linear variable #

# average reading achievement - nationwide, 
# restricted to australia
scf.MIcombine( with( aust_design , svymean( ~ asrrea ) ) )

# remove both designs to clear up memory
rm( aust_design , asg_design )

# clear up RAM
gc()


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
