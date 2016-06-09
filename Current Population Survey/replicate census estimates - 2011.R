# analyze survey data for free (http://asdfree.com) with the r language
# current population survey 
# annual social and economic supplement
# 2011

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/CPS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Current%20Population%20Survey/replicate%20census%20estimates%20-%202011.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com




#############################################################################################################
# this script matches the results of the SAS, SUDAAN, and WesVar code presented in                          #  
# http://smpbff2.dsd.census.gov/pub/cps/march/Use_of_the_Public_Use_Replicate_Weight_File_final_PR_2010.doc #
#############################################################################################################




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###################################################################################################################################
# prior to running this analysis script, the cps march 2011 file must be loaded as a database (.db) on the local machine.         #
# running the 2011 download all microdata script will create this database file                                                   #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/asdfree/blob/master/Current%20Population%20Survey/2005-2012%20asec%20-%20download%20all%20microdata.R #
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


library(survey)		# load survey package (analyzes complex design surveys)
library(DBI)			# load the DBI package (implements the R-database coding)


# if this option is set to TRUE
# R will exactly match SUDAAN results and Stata with the MSE option results
options( survey.replicates.mse = TRUE )
# otherwise if it is commented out or set to FALSE
# R will exactly match Stata without the MSE option results

# Stata svyset command notes can be found here: http://www.stata.com/help.cgi?svyset


# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )


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
		dbtype = "MonetDBLite" ,
		dbname = dbfolder
	)

# workaround for a bug in survey::svrepdesign.character
y$mse <- TRUE


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
