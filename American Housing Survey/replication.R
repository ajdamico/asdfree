# analyze survey data for free (http://asdfree.com) with the r language
# american housing survey
# 2009

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/AHS/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/American%20Housing%20Survey/replication.R" , prompt = FALSE , echo = TRUE )
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


###########################################################################################
# this script matches the officially-published statistics found in the census bureau doc: #
# https://www.census.gov/housing/ahs/files/ahs09/2009%20National%20Standard%20Errors.xls  #
###########################################################################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#########################################################################################################
# prior to running this analysis script, the ahs 2009 file must be loaded as an r data file (.rda) and  #
# in a database (.db) on the local machine. running the download all microdata script will create both. #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/usgsd/master/American%20Housing%20Survey/download%20all%20microdata.R #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "ahs.db" and './2009/national/tnewhouse_trepwgt.rda' in your getwd()   #
#########################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/AHS/" )
# ..in order to set your current working directory

# name the database (.db) file that should have been saved in the working directory
ahs.dbname <- "ahs.db"


# remove the # in order to run this install.packages line only once
# install.packages( "survey" )


library(downloader)	# downloads and then runs the source() function on scripts from github
library(survey)		# load survey package (analyzes complex design surveys)
library(RSQLite) 	# load RSQLite package (creates database files in R)



# R will exactly match SUDAAN results and Stata with the MSE option results
options( survey.replicates.mse = TRUE )
# otherwise if it is commented out or set to FALSE


##############################################
# survey design for a database-backed object #
##############################################

# create survey design object with AHS design information
# using existing table of AHS data
ahs.svydb <-
	svrepdesign(
		weights = ~repwgt0,
		repweights = "repwgt[1-9]" ,
		type = "Fay" ,
		rho = ( 1 - 1 / sqrt( 4 ) ) ,
		data = "tnewhouse_trepwgt_2009_nationalv11" ,
		dbtype = "SQLite" ,
		dbname = ahs.dbname
	)

# coefficient matches 111805.795255002 in cell E10 of `TAB11`
# SE matches 448.629 in cell E10 of `TAB11 - Std Errs`
svytotal( ~one , subset( ahs.svydb , status == 1 ) )

# coefficient matches 76427.9827373352 in cell F10 of `TAB11`
# SE matches 310.859 in cell F10 of `TAB11 - Std Errs`
svytotal( ~one , subset( ahs.svydb , status == 1 & tenure == 1 ) )

	
##################################################
# survey design for an object loaded into memory #
##################################################

# load the merged household + replicate weight table
load( "./2009/national_v1.1/tnewhouse_trepwgt.rda" )

# create survey design object with AHS design information
# using existing table of AHS data
ahs.svynodb <-
	svrepdesign(
		weights = ~repwgt0,
		repweights = "repwgt[1-9]" ,
		type = "Fay" ,
		rho = ( 1 - 1 / sqrt( 4 ) ) ,
		data = tnewhouse_trepwgt
	)

# coefficient matches 111805.795255002 in cell E10 of `TAB11`
# SE matches 448.629 in cell E10 of `TAB11 - Std Errs`
svytotal( ~one , subset( ahs.svynodb , status == 1 ) )

# coefficient matches 76427.9827373352 in cell F10 of `TAB11`
# SE matches 310.859 in cell F10 of `TAB11 - Std Errs`
svytotal( ~one , subset( ahs.svynodb , status == 1 & tenure == 1 ) )


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
