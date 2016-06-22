# analyze survey data for free (http://asdfree.com) with the r language
# american housing survey
# 2009

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/AHS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/American%20Housing%20Survey/replication.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico the first
# ajdamico@gmail.com


###########################################################################################
# this script matches the officially-published statistics found in the census bureau doc: #
# https://www.census.gov/housing/ahs/files/ahs09/2009%20National%20Standard%20Errors.xls  #
###########################################################################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#########################################################################################################
# prior to running this analysis script, the ahs 2009 file must be loaded as an r data file (.rda) and  #
# in a database (.db) on the local machine. running the download all microdata script will create both. #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/American%20Housing%20Survey/download%20all%20microdata.R #
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

