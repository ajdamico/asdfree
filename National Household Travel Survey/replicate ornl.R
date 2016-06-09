# analyze survey data for free (http://asdfree.com) with the r language
# national household travel survey
# 2009 day, person, and household files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NHTS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Household%20Travel%20Survey/replicate%20ornl.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


############################################################################################
# this script matches the statistics in "Table1" of http://nhts.ornl.gov/2009/pub/stt.xlsx #
############################################################################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###############################################################################################################################
# prior to running this analysis script, the nhts 2009 file must be loaded as a monet database-backed survey object           #
# on the local machine. running the download and import script will create a monet database containing this file.             #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Household%20Travel%20Survey/download%20and%20import.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "2009 designs.rda" in C:/My Directory/NHTS or wherever the working directory was set.        #
###############################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


library(survey) 		# load survey package (analyzes complex design surveys)
library(DBI)			# load the DBI package (implements the R-database coding)


# R will exactly match SUDAAN results and Stata with the MSE option results
options( survey.replicates.mse = TRUE )
# otherwise if it is commented out or set to FALSE


# the national household travel survey download and importation script
# has already created a monet database-backed survey design object
# connected to the 2009 tables

# sqlite database-backed survey objects are described here: 
# http://r-survey.r-forge.r-project.org/survey/svy-dbi.html
# monet database-backed survey objects are similar, but:
# the database engine is, well, blazingly faster
# the setup is kinda more complicated (but all done for you)

# since this script only loads one file off of the local drive,
# there's no need to set the working directory.
# instead, simply use the full filepath to the r data file (.rda)
# as shown in the load() examples below.

# load the desired national household travel survey monet database-backed complex sample design objects

# uncomment this line by removing the `#` at the front..
load( '2009 designs.rda' )	# analyze the 2009 designs


# note: this r data file should already contain all of the designs for this year


# connect the complex sample designs to the monet database #

nhts.day.design <- open( nhts.day.design , driver = MonetDB.R() )	# day-level design
nhts.hh.design <- open( nhts.hh.design , driver = MonetDB.R() )		# household-only design
nhts.per.design <- open( nhts.per.design , driver = MonetDB.R() )	# person-level design


# construct a handy function to calculate the margin of error for any formula
nhts.moe <-
	function( formula , design , FUN = svytotal , na.rm = FALSE ){
		
		( coef( FUN( formula , design , na.rm = na.rm ) ) - confint( FUN( formula , design , na.rm = na.rm ) , df = degf( design ) + 1 ) )[ 1 ]
		
	}
# end of function creation


############################################
# replication of household-level estimates #
############################################

# excel cell H6
svytotal( ~one , nhts.hh.design )

# excel cells H7 - H10
svytotal( ~I( hhsize == 1 ) , nhts.hh.design )
svytotal( ~I( hhsize == 2 ) , nhts.hh.design )
svytotal( ~I( hhsize == 3 ) , nhts.hh.design )
svytotal( ~I( hhsize > 3 ) , nhts.hh.design )

# excel cells I7 - I10
nhts.moe( ~I( hhsize == 1 ) , nhts.hh.design )
nhts.moe( ~I( hhsize == 2 ) , nhts.hh.design )
nhts.moe( ~I( hhsize == 3 ) , nhts.hh.design )
nhts.moe( ~I( hhsize > 3 ) , nhts.hh.design )


# excel cell H35
svytotal( ~I( hhvehcnt ) , nhts.hh.design )

# excel cell I35
nhts.moe( ~I( hhvehcnt ) , nhts.hh.design )


#########################################
# replication of person-level estimates #
#########################################

# excel cell H24
svytotal( ~I( r_sex == 1 ) , nhts.per.design )

# excel cell I24
nhts.moe( ~I( r_sex == 1 ) , nhts.per.design )

# excel cell H25
svytotal( ~I( r_sex == 2 ) , nhts.per.design )

# excel cell I25
nhts.moe( ~I( r_sex == 2 ) , nhts.per.design )

# excel cell H13
svytotal( ~I( r_age < 16 ) , nhts.per.design )

# excel cell I13
nhts.moe( ~I( r_age < 16 ) , nhts.per.design )

# excel cell H27
svytotal( ~I( driver == 1 ) , nhts.per.design , na.rm = TRUE )

# excel cell I27
nhts.moe( ~I( driver == 1 ) , nhts.per.design , na.rm = TRUE )

# excel cell H28
svytotal( ~I( r_sex == 1 & driver == 1 ) , nhts.per.design , na.rm = TRUE )

# excel cell I28
nhts.moe( ~I( r_sex == 1 & driver == 1 ) , nhts.per.design , na.rm = TRUE )

# excel cell H29
svytotal( ~I( r_sex == 2 & driver == 1 ) , nhts.per.design , na.rm = TRUE )

# excel cell I29
nhts.moe( ~I( r_sex == 2 & driver == 1 ) , nhts.per.design , na.rm = TRUE )

# excel cell H31
svytotal( ~I( worker == 1 ) , nhts.per.design , na.rm = TRUE )

# excel cell I31
nhts.moe( ~I( worker == 1 ) , nhts.per.design , na.rm = TRUE )



#######################################
# replication of trip-level estimates #
#######################################

# excel cell H41
svytotal( ~one , nhts.day.design )

# excel cell I41
nhts.moe( ~one , nhts.day.design )

# excel cell H43
svytotal( ~trpmiles , nhts.day.design , na.rm = TRUE )

# excel cell I43
nhts.moe( ~trpmiles , nhts.day.design , na.rm = TRUE )


######################
# end of replication #
######################


# close the connection to the three sqlrepsurvey design objects
close( nhts.hh.design )
close( nhts.per.design )
close( nhts.day.design )

