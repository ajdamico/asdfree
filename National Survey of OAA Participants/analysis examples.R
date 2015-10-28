# analyze survey data for free (http://asdfree.com) with the r language
# national survey of oaa participants
# 2012 transportation file

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NPS/" )
# source_url( "https://raw.github.com/ajdamico/asdfree/master/National%20Survey%20of%20OAA%20Participants/analysis%20examples.R" , prompt = FALSE , echo = TRUE )
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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#########################################################################################################################
# prior to running this analysis script, the 2012 transportation file must be loaded onto the local machine.  running   #
# the download all microdata script below will import all of the files that are needed.                                 #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/asdfree/master/National%20Survey%20of%20OAA%20Participants/download%20all%20microdata.R #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will files in the C:/My Directory/NPS directory or wherever the working directory was set.                #
#########################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# set your working directory.
# the NPS data files should have been stored here
# after running the program described above
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NPS/" )
# ..in order to set your current working directory

# remove the # in order to run this install.packages line only once
# install.packages( "survey" )


library(survey)		# load survey package (analyzes complex design surveys)


# load the 2012 transportation data.frame object
load( "./2012/transportation.rda" )


# # # # # # # # # #
# note note note  #
# check the codebook if you get lost.
# http://www.agidnet.org/DataFiles/Documents/NPS/Transportation2012/Codebook_Transportation_2012.html
# thnx thnx thnx  #
# # # # # # # # # #


# display the number of rows in the data set
nrow( x )

# display the first six records in the data set
head( x )


##################################################
# survey design for fay's adjusted brr weighting #
##################################################

# create a survey design object (nps.design) with NPS design information
nps.design <- 
	svrepdesign( 
		data = x , 
		repweights = "pswgt[0-9]" , 
		weights = ~pswgt , 
		type = "Fay" , 
		rho = 0.29986 , 
		mse = TRUE
	)
	
# notice the 'nps.design' object used in all subsequent analysis commands


#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in nps #

# the nrow function which works on both data frame objects..
class( x )
nrow( x )
# ..and survey design objects
class( nps.design )
nrow( nps.design )


# count the total (unweighted) number of records in nps #
# broken out by age category #

svyby(
	~one ,
	~agec ,
	nps.design ,
	unwtd.count
)



# count the weighted number of individuals in nps #

# the total population served by aoa transportation programs of the united states #
svytotal( 
	~one , 
	nps.design 
)


# note that this is exactly equivalent to summing up the weight variable
# from the original nps data frame, throwing out records with missing sampcodes

sum( x$pswgt )

# the total population served by aoa transportation programs of the united states #
# by age category
svyby(
	~one ,
	~agec ,
	nps.design ,
	svytotal
)


# calculate the mean of a linear variable #

# sf-12v2 physical summary score
svymean( 
	~pcs_12 , 
	design = nps.design ,
	na.rm = TRUE
)

# by age category
svyby( 
	~pcs_12 , 
	~agec ,
	design = nps.design ,
	svymean ,
	na.rm = TRUE
)


# calculate the distribution of a categorical variable #

# gender should be treated as a factor (categorical) variable
# instead of a numeric (linear) variable
# this update statement converts it.
# the svyby command below will not run without this
nps.design <-
	update( 
		gender = factor( gender ) ,
		nps.design
	)


# gender distribution
svymean( 
	~gender , 
	design = nps.design ,
	na.rm = TRUE
)

# by age category
svyby( 
	~gender , 
	~agec ,
	design = nps.design ,
	svymean , 
	na.rm = TRUE
)

# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum 
# pcs 12v2 physical summary score among beneficiaries
svyquantile( 
	~pcs_12 , 
	design = nps.design ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	na.rm = TRUE
)

# by age category
svyby( 
	~pcs_12 , 
	~agec ,
	design = nps.design ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	na.rm = TRUE
)

######################
# subsetting example #
######################

# restrict the nps.design object to
# females only
nps.design.female <-
	subset(
		nps.design ,
		gender %in% 2
	)
# now any of the above commands can be re-run
# using the nps.design.female object
# instead of the nps.design object
# in order to analyze females only
	
# calculate the mean of a linear variable #

# average pcs 12v2 physical summary score - restricted to females
svymean( 
	~pcs_12 , 
	design = nps.design.female ,
	na.rm = TRUE
)



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by age category

# store the results into a new object

gender.by.agecat <-
	svyby( 
		~gender , 
		~agec ,
		design = nps.design ,
		svymean ,
		na.rm = TRUE
	)

# print the results to the screen 
gender.by.agecat

# now you have the results saved into a new object of type "svyby"
class( gender.by.agecat )

# print only the statistics (coefficients) to the screen 
coef( gender.by.agecat )

# print only the standard errors to the screen 
SE( gender.by.agecat )

# this object can be coerced (converted) to a data frame.. 
gender.by.agecat <- data.frame( gender.by.agecat )

# ..and then immediately exported as a comma-separated value file 
# into your current working directory 
write.csv( gender.by.agecat , "gender by agecat.csv" )

# ..or trimmed to only contain the values you need.
# here's the percent of beneficiaries who are female
# with accompanying standard errors
female.by.agecat <-
	gender.by.agecat[ , c( "agec" , "gender2" , "se2" ) ]

# that's all rows, and the three specified columns


# print the new results to the screen
female.by.agecat

# this can also be exported as a comma-separated value file 
# into your current working directory 
write.csv( female.by.agecat , "percent female by agecat.csv" )

# ..or directly made into a bar plot
barplot(
	female.by.agecat[ , 2 ] ,									# the second column of the data frame contains the main data
	main = "Percent Female Beneficiaries by Age Category" ,		# title the barplot
	names.arg = c( "60-64" , "65-74" , "75-84" , "85+" ) ,		# category labels, taken from the codebook
	ylim = c( 0 , 1 )			 								# set the lower and upper bound of the y axis
)


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
