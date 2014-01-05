# analyze survey data for free (http://asdfree.com) with the r language
# current population survey 
# annual social and economic supplement
# 2011

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/CPS/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Current%20Population%20Survey/replicate%20census%20estimates%20-%202011.R" , prompt = FALSE , echo = TRUE )
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




#############################################################################################################
# this script matches the results of the SAS, SUDAAN, and WesVar code presented in                          #  
# http://smpbff2.dsd.census.gov/pub/cps/march/Use_of_the_Public_Use_Replicate_Weight_File_final_PR_2010.doc #
#############################################################################################################




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###################################################################################################################################
# prior to running this analysis script, the cps march 2011 file must be loaded as a database (.db) on the local machine.         #
# running the 2011 download all microdata script will create this database file                                                   #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/usgsd/blob/master/Current%20Population%20Survey/2005-2012%20asec%20-%20download%20all%20microdata.R #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "cps.asec.db" with 'asec11' in C:/My Directory/ACS or wherever the working directory was set     #
###################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# set your working directory.
# the CPS 2011 data files should have been stored here
# after running the program described above
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/CPS/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( c ( "survey" , "RSQLite" ) )


library(survey)		# load survey package (analyzes complex design surveys)
library(RSQLite) 	# load RSQLite package (creates database files in R)

# set R to produce conservative standard errors instead of crashing
# http://faculty.washington.edu/tlumley/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN



# if this option is set to TRUE
# R will exactly match SUDAAN results and Stata with the MSE option results
options( survey.replicates.mse = TRUE )
# otherwise if it is commented out or set to FALSE
# R will exactly match Stata without the MSE option results

# Stata svyset command notes can be found here: http://www.stata.com/help.cgi?svyset


#######################################
# survey design for replicate weights #
#######################################

# create survey design object with CPS design information
# using existing data frame of CPS data
y <- 
	svrepdesign(
		weights = ~marsupwt, 
		repweights = "pwwgt[1-9]", 
		type = "Fay", 
		rho = (1-1/sqrt(4)),
		data = "asec11" ,
		combined.weights = T ,
		dbtype = "SQLite" ,
		dbname = "cps.asec.db"
	)

#############################################################################################################
# these commands replicate the results of the SAS, SUDAAN, and WesVar code presented in                     #  
# http://smpbff2.dsd.census.gov/pub/cps/march/Use_of_the_Public_Use_Replicate_Weight_File_final_PR_2010.doc #
#############################################################################################################

# restrict the y object to..
males.above15.inpoverty <-
	subset( 
		y ,
		a_age > 15 &		# age 16+
		a_sex %in% 1 &		# males
		perlis %in% 1		# in poverty
	)

# count the weighted number of individuals
# and also calculate the standard error,
# using the newly-created survey design subset
svytotal( ~one , males.above15.inpoverty )

# note that this exactly matches the SAS-produced file
# march 2011 asec replicate weight sas output.png

##################################
# end of census code replication #
##################################

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
