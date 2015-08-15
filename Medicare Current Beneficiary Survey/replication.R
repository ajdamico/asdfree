# analyze survey data for free (http://asdfree.com) with the r language
# medicare current beneficiary survey
# 2009

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/MCBS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Medicare%20Current%20Beneficiary%20Survey/replication.R" , prompt = FALSE , echo = TRUE )
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



##########################################################################################################
# this script matches the officially-published statistics found in the cms-provided tables available at: #
# http://www.cms.gov/Research-Statistics-Data-and-Systems/Research/MCBS/Data-Tables-Items/2009_HHC.html  #
##########################################################################################################



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###################################################################################################################
# prior to running this analysis script, the mcbs 2009 consolidated file must be loaded as an r data file (.rda)  #
# on the local machine. running the importation script will create both this file for ya.                         #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/Medicare%20Current%20Beneficiary%20Survey/importation.R #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/MCBS/" )
# ..in order to set your current working directory




# remove the # in order to run this install.packages line only once
# install.packages( 'survey' )


library(downloader)	# downloads and then runs the source() function on scripts from github
library(survey)		# load survey package (analyzes complex design surveys)
library(RSQLite) 	# load RSQLite package (creates database files in R)


# R will exactly match SUDAAN results and Stata with the MSE option results
options( survey.replicates.mse = TRUE )
# otherwise if it is commented out or set to FALSE


# load the 2009 mcbs consolidated cost & use file
load( "./cau/cons2009.rda" )


# perform a simple recode
x$inccat <- findInterval( x$income_c , c( 10000 , 20000 , 30000 , 50000 ) )
# create an income category variable, starting with the (imputed) linear `income_c`
# and breaking at $10,000 / $20,000 / $30,000 / $50,000


##########################################################
# replicate-weighted complex sample survey design object #
##########################################################

y <- 
	svrepdesign ( 
		data = x ,
		repweights = 'cs1yr[0-9]' ,
		type = "Fay" , 
		combined.weights = T , 
		rho = ( 1 - 1 / sqrt( 2.04 ) ) ,
		weights = ~cs1yrwgt
	)


# in file "2009_Sec1.pdf" pdf page #1
# match the overall number and standard error
svytotal( ~one , y )
# rounded to the nearest thousands, of course.
	
# in file "2009_Sec1.pdf" pdf page #5
# match the distribution of the income category
svymean( ~factor( inccat ) , y )
# and standard errors too.


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
