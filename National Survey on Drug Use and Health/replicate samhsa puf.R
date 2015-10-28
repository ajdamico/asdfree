# analyze survey data for free (http://asdfree.com) with the r language
# national survey on drug use and health
# replication of tables published by the substance abuse and mental health services administration (samhsa)
# using the 2010 public use file

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NSDUH/" )
# source_url( "https://raw.github.com/ajdamico/asdfree/master/National%20Survey%20on%20Drug%20Use%20and%20Health/replicate%20samhsa%20puf.R" , prompt = FALSE , echo = TRUE )
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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#################################################################################################################################################
# prior to running this replication script, all nsduh 2011 public use microdata files must be loaded as R data                                  #
# files (.rda) on the local machine. running the "1979-2010 - download all microdata.R" script will create these files.                         #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/asdfree/blob/master/National%20Survey%20on%20Drug%20Use%20and%20Health/1979-2010%20-%20download%20all%20microdata.R #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will save a number of .rda files in C:/My Directory/NSDUH/2010/ (or the working directory chosen)                                 #
#################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


#################################################################
# Analyze the 2010 National Study on Drug Use and Health with R #
#################################################################


# set your working directory.
# the NSDUH 2010 R data files (.rda) should have been
# stored in a year-specific directory within this folder.
# so if the file "NSDUH.10.rda" exists in the directory "C:/My Directory/NSDUH/2010/" 
# then the working directory should be set to "C:/My Directory/NSDUH/"
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


# by default, R will crash if a primary sampling unit (psu) has a single observation
# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
# by keeping this line uncommented:
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN


# the r data frame can be loaded directly from your local hard drive
load( "./2010/NSDUH.10.rda" )


# display the number of rows in the 2010 data set
nrow( NSDUH.10.df )

# display the first six records in the 2010 data set
head( NSDUH.10.df )
# note that the data frame contains far too many variables to be viewed conveniently

# create a character vector that will be used to
# limit the file to only the variables needed
KeepVars <-
	c( 
		"analwt_c" , 	# main analytic weight
		
		"vestr" , 		# sampling strata
		
		"verep" , 		# primary sampling units
		
		"sumflag" ,		# illicit drug use in lifetime flag (0/1 variable)
		
		"sumyr" ,		# illicit drug use in past year flag (0/1 variable)
		
		"summon" ,		# illicit drug use in past month flag (0/1 variable)
		
		"newrace2" , 	# race/ethnicity seven category variable
		
		"catage" , 		# four age category variable
		
		"irsex" 	 	# respondent's sex
	)


# limit the r data frame (NSDUH.10.df) containing all variables
# to a severely-restricted r data frame containing only the seven variables
# specified in character vector 'KeepVars'
x <- NSDUH.10.df[ , KeepVars ]

# to free up RAM, remove the full r data frame
rm( NSDUH.10.df )

# garbage collection: clear up RAM
gc()

# calculate the age grouping variable
# to match the tables
x <-
	transform(
		x ,
		# this transform line recodes the 'catage' column as
		# 1 -> 1; 2 -> 2; 3 -> 3; and 4 -> 3
		age_grp = c( 1 , 2 , 3 , 3 )[catage] 
	)


#################################################
# survey design for taylor-series linearization #
#################################################

# create a survey design object (y) with NSDUH design information
y <- 
	svydesign( 
		id = ~verep , 
		strata = ~vestr , 
		data = x , 
		weights = ~analwt_c , 
		nest = TRUE 
	)
	

#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in the 2010 national study on drug use and health data set #

# the nrow function which works on both data frame objects..
class( x )
# ..and survey design objects
class( y )


# notice that the original data frame contains the same number of records as..
nrow( x )

# ..the survey object
nrow( y )


# add a new variable 'one' that simply has the number 1 for each record #
# and can be used to calculate unweighted and weighted population sizes #

y <-
	update( 
		one = 1 ,
		y
	)


#################################################################
# print the exact contents of the samhsa document to the screen #
#################################################################

# https://github.com/ajdamico/asdfree/blob/master/National%20Survey%20on%20Drug%20Use%20and%20Health/NSDUH%20PUF_Table_1.19B_D%20from%20SAMHSA.pdf?raw=true #


# unweighted counts #
# (sample size column) #

unwtd.count( ~one , y )							# total valid cases
svyby( ~one , ~age_grp , y , unwtd.count )		# by age group
svyby( ~one , ~irsex , y , unwtd.count )		# by sex
svyby( ~one , ~newrace2 , y , unwtd.count )		# by race/ethnicity


# weighted counts #
# (population size column) #

svytotal( ~one , y )							# total valid cases
svyby( ~one , ~age_grp , y , svytotal )			# by age group
svyby( ~one , ~irsex , y , svytotal )			# by sex
svyby( ~one , ~newrace2 , y , svytotal )		# by race/ethnicity


# percents: proportions, standard errors

# (percent and SE percent columns) #
svymean( ~sumflag , y )							# percent with illicit drug use in lifetime
svymean( ~sumyr , y )							# percent with illicit drug use in past year
svymean( ~summon , y )							# percent with illicit drug use in past month


# if you just want the mean or the SE but not both
# place the svymean() inside the coef() or SE() function
coef( svymean( ~sumflag , y ) )					# percent with illicit drug use in lifetime (just percent)
SE( svymean( ~sumflag , y ) )					# percent with illicit drug use in lifetime (just standard error)


# by age group #
svyby( ~sumflag , ~age_grp , y , svymean )		# percent with illicit drug use in lifetime
svyby( ~sumyr , ~age_grp , y , svymean )		# percent with illicit drug use in past year
svyby( ~summon, ~age_grp , y , svymean )		# percent with illicit drug use in past month


# by sex #
svyby( ~sumflag , ~irsex , y , svymean )		# percent with illicit drug use in lifetime
svyby( ~sumyr , ~irsex , y , svymean )			# percent with illicit drug use in past year
svyby( ~summon, ~irsex , y , svymean )			# percent with illicit drug use in past month


# by race/ethnicity #
svyby( ~sumflag , ~newrace2 , y , svymean )		# percent with illicit drug use in lifetime
svyby( ~sumyr , ~newrace2 , y , svymean )		# percent with illicit drug use in past year
svyby( ~summon, ~newrace2 , y , svymean )		# percent with illicit drug use in past month


###########################################################################
# end of printing the exact contents of the samhsa document to the screen #
###########################################################################


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
