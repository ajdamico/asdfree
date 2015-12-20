# analyze survey data for free (http://asdfree.com) with the r language
# national immunization survey
# 2011 main files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NIS" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Immunization%20Survey/analysis%20examples.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# joe walsh
# j.thomas.walsh@gmail.com

# anthony joseph damico
# ajdamico@gmail.com



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################
# prior to running this analysis script, the nis main 2011 single-year file must be loaded as an r data file (.rda) #
# on the local machine. running the download all microdata script will download and import this file nicely for ya  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Immunization%20Survey/download%20all%20microdata.R        #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "nis2011.rda" in C:/My Directory/NIS or wherever the working directory was set.    #
#####################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# remove the # in order to run this install.packages line only once
# install.packages( "survey" )



library(survey) # load survey package (analyzes complex design surveys)




# set your working directory.
# all NIS data files should have been stored here
# after downloading and importing.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NIS/" )
# ..in order to set your current working directory



# set the number of digits shown in all output

options( digits = 15 )


# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN


# load the national immunization survey's 2011 main data.frame object
load( 'nis2011.rda' )

# add a column of all ones
x$one <- 1

#####################################################################
# survey design for taylor-series linearization decisions decisions #
#####################################################################

# you got two choices for survey design constructions..


# # # # # # # # # # # # # # # # # # # # # # # # # # #
# use all records, regardless of provider follow-up #

# create survey design object with NIS design information

# y <-
	# svydesign(
		# id = ~seqnumhh , 
		# strata = ~stratum_d , 
		# weights = ~rddwt_d , 
		# data = subset( x , rddwt_d > 0 ) 
	# )  


# # # # # # # # # # # # # # # # # # # # # # # # # # #
# use only records including the provider follow-up #

# create survey design object with NIS design information
y <-
	svydesign(
		id = ~seqnumhh , 
		strata = ~stratum_d , 
		weights = ~provwt_d , 
		data = subset( x , provwt_d > 0 ) 
	)  

	
#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in nis #
# since a number of records have zero weights,
# referring to the original data.frame does not work.
nrow( x )

# instead, use the survey design object directly.
unwtd.count( ~one , y )


# broken out by male/female #

svyby(
	~one ,
	~sex ,
	y ,
	unwtd.count
)

# count the weighted number of individuals in nis #
svytotal(
	~one ,
	y
)
# hey look at that big number!  know what that is?
# it's the number of american children aged 19-35 months
# that is, the sample frame of this classy survey.


# calculate the mean of a linear variable #

# what percent of 19-35 month olds are up-to-date on their polio shots?
svymean( ~p_utdpol , design = y )

# by sex
svyby(
	~p_utdpol ,
	~sex ,
	design = y ,
	svymean
)



# calculate the distribution of a categorical variable #

# cbf_01 should be treated as a factor (categorical) variable
# instead of a numeric (linear) variable
# this update statement converts it.
y <-
	update(
		cbf_01 = factor( cbf_01 ) ,
		y
	)


# percent of 19-35 month olds who have ever been fed breast milk
svymean(
	~cbf_01 ,
	design = y
)

# by sex
svyby(
	~cbf_01 ,
	~sex ,
	design = y ,
	svymean
)


# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum
# doses of polio
svyquantile(
	~p_numpol ,
	design = y ,
	c( 0 , .25 , .5 , .75 , 1 ) 
)

# by sex
svyby(
	~p_numpol ,
	~sex ,
	design = y ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	ci = T
)

######################
# subsetting example #
######################

# restrict the y object to
# females only
y.female <-
	subset(
		y ,
		sex == 2
	)
# now any of the above commands can be re-run
# using y.female object
# instead of the y object
# in order to analyze females only

# calculate the mean of a linear variable #

# percent of females who are up-to-date on their polio vaccinations
svymean(
	~p_utdpol ,
	design = y.female ,
	na.rm = TRUE
)



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by sex

# store the results into a new object

breastfed.by.sex <-
	svyby(
		~cbf_01 ,
		~sex ,
		design = y ,
		svymean ,
		na.rm = TRUE
	)

# print the results to the screen
breastfed.by.sex

# now you have the results saved into a new object of type "svyby"
class( breastfed.by.sex )

# print only the statistics (coefficients) to the screen
coef( breastfed.by.sex )

# print only the standard errors to the screen
SE( breastfed.by.sex )

# this object can be coerced (converted) to a data frame..
breastfed.by.sex <- data.frame( breastfed.by.sex )

# ..and then immediately exported as a comma-separated value file
# into your current working directory
write.csv( breastfed.by.sex , "breastfed by sex.csv" )


# ..or directly made into a bar plot
barplot(
	breastfed.by.sex[ , 2 ] ,
	main = "Percent of 19-35 Month Olds Who Have Been Breastfed, By Sex" ,
	names.arg = c( "Male" , "Female" ) ,
	ylim = c( 0 , 1 )
)
