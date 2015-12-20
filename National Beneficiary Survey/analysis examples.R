# analyze survey data for free (http://asdfree.com) with the r language
# national beneficiary survey
# round four

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NBS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Beneficiary%20Survey/analysis%20examples.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#################################################################################################################
# prior to running this analysis script, the national beneficiary survey round 4 files must be loaded onto the  #
# local machine.  running the download all microdata script below will import all of the files that are needed. #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Beneficiary%20Survey/download%20all%20microdata.R     #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will files in the C:/My Directory/NBS directory or wherever the working directory was set.        #
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



# # # # # # # # # #
# note note note  #
# the variable names in the codebook include an "r4_" in front of every variable
# http://www.ssa.gov/disabilityresearch/documents/NBS%20R4%20PUF%20Codebook(508).pdf
# but that's silly!  i've already removed them in the download-automation script
# thnx thnx thnx  #
# # # # # # # # # #


# display the number of rows in the data set
nrow( x )

# display the first six records in the data set
head( x )


#####################
# tsl survey design #
#####################

# create a survey design object (nbs.design) with nbs design information
nbs.design <- svydesign( ~ a_psu_pub , strata = ~ a_strata , data = x , weights = ~ wtr4_ben )
# notice the 'nbs.design' object used in all subsequent analysis commands


#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in nbs #

# the nrow function which works on both data frame objects..
class( x )
nrow( x )
# ..and survey design objects
class( nbs.design )
nrow( nbs.design )


# count the total (unweighted) number of records in nbs #
# broken out by age category #

svyby(
	~one ,
	~c_intage_pub ,
	nbs.design ,
	unwtd.count
)



# count the weighted number of individuals in nbs #

# the total population served by ssi and di programs of the united states in 2010 #
svytotal( 
	~one , 
	nbs.design 
)


# note that this is exactly equivalent to summing up the weight variable
# from the original nbs data frame

sum( x$wtr4_ben )

# the total population served by the us social security administration's    #
# supplemental security insurance and disability insurance programs in 2010 #
# by age category
svyby(
	~one ,
	~c_intage_pub ,
	nbs.design ,
	svytotal
)


# calculate the mean of a linear variable #

# total benefits for the month before the interview date
svymean( 
	~n_totssbenlastmnth_pub , 
	design = nbs.design ,
	na.rm = TRUE
)

# by age category
svyby( 
	~n_totssbenlastmnth_pub , 
	~c_intage_pub ,
	design = nbs.design ,
	svymean ,
	na.rm = TRUE
)


# calculate the distribution of a categorical variable #

# gender should be treated as a factor (categorical) variable
# instead of a numeric (linear) variable
# this update statement converts it.
# the svyby command below will not run without this
nbs.design <-
	update( 
		orgsampinfo_sex = factor( orgsampinfo_sex ) ,
		nbs.design
	)


# gender distribution
svymean( 
	~orgsampinfo_sex , 
	design = nbs.design ,
	na.rm = TRUE
)

# by age category
svyby( 
	~orgsampinfo_sex , 
	~c_intage_pub ,
	design = nbs.design ,
	svymean , 
	na.rm = TRUE
)

# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum 
# total benefits for the month before the interview date
svyquantile( 
	~n_totssbenlastmnth_pub , 
	design = nbs.design ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	na.rm = TRUE
)

# by age category
svyby( 
	~n_totssbenlastmnth_pub , 
	~c_intage_pub ,
	design = nbs.design ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	na.rm = TRUE ,
	keep.var = FALSE
)

######################
# subsetting example #
######################

# restrict the nbs.design object to
# ssi recipients only
# as defined on pdf page 70 of the codebook
# http://www.ssa.gov/disabilityresearch/documents/NBS%20R4%20PUF%20Codebook%28508%29.pdf#page=70
# anyone with an `orgsampinfo_bstatus` variable of a one or a three is an ssi recipient
nbs.design.ssi <-
	subset(
		nbs.design ,
		orgsampinfo_bstatus %in% c( 1 , 3 )
	)
# now any of the above commands can be re-run
# using the nbs.design.ssi object
# instead of the nbs.design object
# in order to analyze ssi recipients only
	
# calculate the mean of a linear variable #

# total benefits for the month before the interview date - restricted to ssi recipients
svymean( 
	~n_totssbenlastmnth_pub , 
	design = nbs.design.ssi ,
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
		~orgsampinfo_sex , 
		~c_intage_pub ,
		design = nbs.design ,
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
	gender.by.agecat[ , c( "c_intage_pub" , "orgsampinfo_sex0" , "se.orgsampinfo_sex0" ) ]

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
	names.arg = c( "18-25" , "26-40" , "41-55" , "56+" ) ,		# category labels, taken from the codebook
	ylim = c( 0 , 1 )			 								# set the lower and upper bound of the y axis
)

