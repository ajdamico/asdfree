# analyze survey data for free (http://asdfree.com) with the r language
# trends in international mathematics and science study
# a few examples from the user guide, you know how it goes.

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/TIMSS/" )
# source_url( "https://raw.github.com/ajdamico/asdfree/master/Trends%20in%20International%20Mathematics%20and%20Science%20Study/analysis%20examples.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# https://www.youtube.com/watch?v=JLt9JfaAxUg

# anthony joseph damico
# ajdamico@gmail.com

# if you use this script for a project, please send me a note
# it's always nice to hear about how people are using this stuff

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###############################################################################################################################################
# prior to running this analysis script, the piaac multiply-imputed tables must be loaded as a replicate-weighted survey object on the        #
# local machine. running the download, import, and design scripts will create an r data file (.rda) with whatcha need.                        #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/asdfree/master/Trends%20in%20International%20Mathematics%20and%20Science%20Study/download%20and%20import.R  #
# https://raw.github.com/ajdamico/asdfree/master/Trends%20in%20International%20Mathematics%20and%20Science%20Study/construct%20designs.R      #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create the files "asg_design.rda" in C:/My Directory/TIMSS or wherever the working directory was set.                      #
###############################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/TIMSS/" )


library(survey)			# load survey package (analyzes complex design surveys)
library(mitools) 		# load mitools package (analyzes multiply-imputed data)
library(downloader)		# downloads and then runs the source() function on scripts from github
library(RSQLite) 		# load RSQLite package (creates database files in R)

# load the multiply-imputed design combination alteration function (scf.MIcombine)
# from the survey of consumer finances directory.  that function's algorithm is what timss uses.
source_url( "https://raw.github.com/ajdamico/asdfree/master/Survey%20of%20Consumer%20Finances/scf.survey.R" , prompt = FALSE )


# the timss directory contains database-backed survey design objects #

# # # # # # # # # # # # # # # # # # # # #
# let's load a multiply-imputed design  #
# # # # # # # # # # # # # # # # # # # # #

# load the ASG (student background) design
load( "./2011/asg_design.rda" )

# here the survey object reveals its an imputation list
class( asg_design )

# establish a connection to the SQLite database
asg_design$designs <- lapply( asg_design$designs , open )

# count the total (unweighted) number of records in the imputed design #
nrow( asg_design )


# count the total (unweighted) number of records in timss #
# broken out by country #
scf.MIcombine( with( asg_design , svyby( ~ I( totwgt > 0 ) , ~ idcntry , unwtd.count ) ) )

# count the weighted number of students who timss represents worldwide
scf.MIcombine( with( asg_design , svytotal( ~ as.numeric( totwgt > 0 ) ) ) )

# by country
scf.MIcombine( 
	with( 
		asg_design , 
		svyby( 
			~ as.numeric( totwgt > 0 ) , 
			~ idcntry , 
			svytotal 
		) 
	) 
)

# calculate the mean of a linear variable #

# average mathematics achievement - across all individuals in the data set
scf.MIcombine( with( asg_design , svymean( ~ asmmat ) ) )

# by country
scf.MIcombine( with( asg_design , svyby( ~ asmmat , ~ idcntry , svymean ) ) )


# calculate the distribution of a categorical variable #

# percent of respondent males vs. females - nationwide
scf.MIcombine( with( asg_design , svymean( ~ factor( itsex ) , na.rm = TRUE ) ) )

# by country
scf.MIcombine( with( asg_design , svyby( ~ factor( itsex ) , ~ idcntry , svymean , na.rm = TRUE , na.rm.all = TRUE ) ) )


# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum
# mathematics achievement score
scf.MIcombine( 
	with( 
		asg_design , 
		svyby( 
			~ asmmat , 
			~ as.numeric( totwgt > 0 ) , 
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
			~ asmmat , 
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
aust_design <- asg_design
aust_design$designs <- lapply( aust_design$designs , subset , idcntry == 36 )
# now any of the above commands can be re-run
# using aust_design object
# instead of the asg_design object
# in order to analyze australia only

# calculate the mean of a linear variable #

# average mathematics achievement - nationwide, 
# restricted to australia
scf.MIcombine( with( aust_design , svymean( ~ asmmat ) ) )

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
