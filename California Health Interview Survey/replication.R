# analyze survey data for free (http://asdfree.com) with the r language
# california health interview survey
# replication of askchis tables published by the ucla center for health policy research
# using the 2014 public use file

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/CHIS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/California%20Health%20Interview%20Survey/replication.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# note that these statistics come very close to the quick table results on shown in samhsa table 1.19B (pdf page two of this document):
# http://oas.samhsa.gov/NSDUH/2k10NSDUH/tabs/Sect1peTabs19to23.pdf
# and table 1.19D (pdf page two of this document):
# http://oas.samhsa.gov/NSDUH/2k10NSDUH/tabs/Sect1seTabs19to23.pdf
# however, because those published tables use a restricted access file, the statistics generated below do not match exactly.


# to confirm that the methodology below is correct, analysts at samhsa provided me with the same tables generated using the public use file (puf)
# https://github.com/ajdamico/asdfree/blob/master/National%20Survey%20on%20Drug%20Use%20and%20Health/NSDUH%20PUF_Table_1.19B_D%20from%20SAMHSA.pdf?raw=true
# this r script will replicate each of the statistics from that custom run of the national survey on drug use and health (nsduh) exactly


# carl ganz
# carlganz@ucla.edu



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#################################################################################################################################################
# prior to running this replication script, all chis 2014 public use microdata files must be loaded as R data                                   #
# files (.rda) on the local machine. running the "download all microdata.R" script will create these files.                                     #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/California%20Health%20Interview%20Survey/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will save a number of .rda files in C:/My Directory/CHIS/2014/ (or the working directory chosen)                                  #
#################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


#########################################################
# Analyze the California Health Interview Survey with R #
#########################################################


# set your working directory.
# the CHIS 2014 R data files (.rda) should have been
# stored in a year-specific directory within this folder.
# so if the file "adult.rda" exists in the directory "C:/My Directory/CHIS/2014/" 
# then the working directory should be set to "C:/My Directory/CHIS/"
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NSDUH/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( "survey" )


# no need to edit anything below this line #


# # # # # # # # #
# program start #
# # # # # # # # #


library(survey)  # load survey package (analyzes complex design surveys)


# if this option is set to TRUE
# R will exactly match SUDAAN results and Stata with the MSE option results
options( survey.replicates.mse = TRUE )
# otherwise if it is commented out or set to FALSE
# R will exactly match Stata without the MSE option results


# the r data frame can be loaded directly from your local hard drive
load( "./2014/adult.rda" )


####################################
# replicate-weighted survey design #
####################################

# create a survey design object (y) with CHIS design information
# http://healthpolicy.ucla.edu/chis/analyze/Documents/2012MAY02-CHIS-PUF-Weighting-and-Variance-2Frequency.pdf
# consistent with Complex Surveys: a Guide to Analysis in R by Thomas Lumley Chapter #2
y <- 
	svrepdesign( 
		data = x , 
		weights = ~ rakedw0 , 
		repweights = "rakedw[1-9]" , 
		type = "other" , 
		scale = 1 , 
		rscales = 1  , 
		mse = TRUE 
	)



#####################################
# replication of AskCHIS statistics #
#####################################


# compare to 2014 state level estimates for Adults from the AskCHIS web query system

# Health Status
hs <- svymean(~factor(ab1),chis_svy)
round(100*hs,1)
round(100*confint(hs,df=degf(chis_svy)),1)

### AskCHIS output:
browseURL("http://i.imgur.com/TAQrygz.png")
