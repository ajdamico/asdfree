# analyze survey data for free (http://asdfree.com) with the r language
# integrated public use microdata series - international

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


# this is a guide, it is not a one-size-fits-all set of commands:
# edit this code heavily for your own analysis, otherwise you are doing something wrong.


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###################################################################################################################################
# prior to running this analysis script, an ipums-international in-memory survey design must be loaded as an r data file (.rda)   #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/IPUMS%20International/download%20import%20design%20within%20memory.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that guide shows how to construct a "survey design in memory.rda" in your getwd() that can then be analyzed using syntax below. #
###################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/IPUMSI/" )
# ..in order to set your current working directory


library(survey)			# load survey package (analyzes complex design surveys)


# load the in-memory survey design object into the current session
load( "survey design in memory.rda" )

# at this point, you have a taylor series linearized,
# complex sample survey design object
this_design

	
#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in your extract #
nrow( this_design )
# ..or an equivalent command..
unwtd.count( ~ one , this_design )
# note that these unweighted statistics should sum to the counts on
# https://international.ipums.org/international/samples.shtml

# count the total (unweighted) number of records in your extract #
# broken out by some categorical variable #
svyby(
	~ one ,
	~ empstat ,
	this_design ,
	unwtd.count
)

# count the weighted number of individuals in your extract #

# the total number of individuals in the country in that year #
svytotal(
	~ one ,
	this_design
)
# note that these weighted statistics should sum to the counts divided by the sampling fraction on
# https://international.ipums.org/international/samples.shtml

# the total number of individuals in the country in that census year #
# by some categorical variable #
svyby(
	~ one ,
	~ empstat ,
	this_design ,
	svytotal
)


# calculate the mean of a linear variable #

# average age across the country
svymean( ~ age , this_design )

# by employment status
svyby(
	~ age ,
	~ empstat ,
	design = this_design ,
	svymean
)


# calculate the distribution of a categorical variable #

# percent male versus female
svymean(
	~ factor( sex ) ,
	design = this_design ,
	na.rm = TRUE
)

# by employment status
svyby(
	~ factor( sex ) ,
	~ empstat ,
	design = this_design ,
	svymean ,
	na.rm = TRUE
)

# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum ages across the country of your extract
svyquantile(
	~ age ,
	design = this_design ,
	c( 0 , .25 , .5 , .75 , 1 )
)

# by employment status
svyby(
	~ age ,
	~ empstat ,
	design = this_design ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	ci = TRUE
)

####################
# recoding example #
####################

# create a new 0/1 variable "senior" within the survey design
# using the `update` function (just like the `transform` function)
this_design <-
	update(
		this_design ,
		senior = as.numeric( age >= 65 )
	)

# this variable has now been stored within the in-memory survey design object
svymean( ~ senior , this_design )

######################
# subsetting example #
######################

# restrict the this_design object to females only
this_design_females <- subset( this_design , sex == 2 )
# now any of the above commands can be re-run
# using this_design_females object
# instead of the this_design object
# in order to analyze females only

# calculate the mean of a linear variable #

# average age of females within the country
svymean( ~ age , this_design_females )

# be sure to clean up the object when you're done if you are short on ram
rm( this_design_females ) ; gc()

###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by employment status

# store the results into a new object

sex_by_employment_status <-
	svyby(
		~ factor( sex ) ,
		~ empstat ,
		design = this_design ,
		svymean ,
		na.rm = TRUE
	)

# print the results to the screen
sex_by_employment_status

# now you have the results saved into a new object of type "svyby"
class( sex_by_employment_status )

# print only the statistics (coefficients) to the screen
coef( sex_by_employment_status )

# print only the standard errors to the screen
SE( sex_by_employment_status )

# print only the coefficients of variation to the screen
cv( sex_by_employment_status )

# this object can be coerced (converted) to a data frame..
sex_by_employment_status <- data.frame( sex_by_employment_status )

# ..and then immediately exported as a comma-separated value file
# into your current working directory
write.csv( sex_by_employment_status , "sex by employment status.csv" )

# ..or trimmed to only contain the values you need.
# here's the "percent female" by employment status,
# with accompanying standard errors
female_employment_status <-
	sex_by_employment_status[ , c( "empstat" , "factor.sex.2" , "se.factor.sex.2" ) ]


# print the new results to the screen
female_employment_status

# this can also be exported as a comma-separated value file
# into your current working directory
write.csv( female_employment_status , "female by employment status.csv" )

# ..or directly made into a bar plot
barplot(
	female_employment_status[ , 2 ] ,
	main = "Percent Female By Employment Status" ,
	names.arg = c( "Employed" , "Unemployed" , "Inactive" ) ,
	ylim = c( 0 , .75 )
)
# labels from
# https://international.ipums.org/international-action/variables/EMPSTAT#codes_section
