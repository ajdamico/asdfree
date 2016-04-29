# analyze survey data for free (http://asdfree.com) with the r language
# national survey of family growth
# 2002

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NSFG/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Survey%20of%20Family%20Growth/replication.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


############################################################
# this script matches the sas output here..
# http://www.cdc.gov/nchs/data/nsfg/ser2_example1_final.pdf#page=2
############################################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#################################################################################################################
# prior to running this analysis script, the national survey of family growth files must be loaded onto the     #
# local machine.  running the download all microdata script below will import all of the files that are needed. #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Survey%20of%20Family%20Growth/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will files in the C:/My Directory/NSFG directory or wherever the working directory was set.       #
#################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# set your working directory.
# the NSFG data files should have been stored here
# after running the program described above
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NSFG/" )
# ..in order to set your current working directory

# remove the # in order to run this install.packages line only once
# install.packages( "survey" )


library(survey)		# load survey package (analyzes complex design surveys)


# load the 2002 female respondent file into working memory
load( "2002femresp.rda" )


# create a taylor-series linearization design object
y <- svydesign( ~ secu_r , strata = ~ sest , data = x , weights = ~ finalwgt , nest = TRUE )

# recode according to the cdc documentation
y <- 
	update( 
		y , 
		pill = as.numeric( constat1 == 6 ) ,
		agerx = factor( findInterval( ager , c( 15 , 20 , 25 , 30 , 35 , 40 ) ) ) 
	)

# weighted counts
svyby( ~ pill , ~ agerx , y , svytotal )

# row percents
svyby( ~ pill , ~ agerx , y , svymean )
