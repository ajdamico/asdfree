# analyze survey data for free (http://asdfree.com) with the r language
# national beneficiary survey
# round four

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NBS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Beneficiary%20Survey/replication.R" , prompt = FALSE , echo = TRUE )
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


############################################################
# this script matches the sudaan output generated here..
# https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Beneficiary%20Survey/sudaan%20example%20output.png
# ..that follows the exact sudaan example syntax published here
# http://www.ssa.gov/disabilityresearch/documents/NBS%20R4%20Users%20Guide%20Appendices%28508%29.pdf#page=333
############################################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#################################################################################################################
# prior to running this analysis script, the national beneficiary survey round 4 files must be loaded onto the  #
# local machine.  running the download all microdata script below will import all of the files that are needed. #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Beneficiary%20Survey/download%20all%20microdata.R     #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will files in the C:/My Directory/NPS directory or wherever the working directory was set.        #
#################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# set your working directory.
# the NBS data files should have been stored here
# after running the program described above
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NBS/" )
# ..in order to set your current working directory

# remove the # in order to run this install.packages line only once
# install.packages( "survey" )


library(survey)		# load survey package (analyzes complex design surveys)


# load the survey round four file into working memory
load( "round 04.rda" )


# create a taylor-series linearization design object
y <- svydesign( ~ a_psu_pub , strata = ~ a_strata , data = x , weights = ~ wtr4_ben )


# calculate the percent of male respondents
svymean( ~orgsampinfo_sex , y )
# as coded on pdf page 69 of the general round four documentation
# http://www.ssa.gov/disabilityresearch/documents/NBS%20R4%20PUF%20Codebook%28508%29.pdf#69


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
