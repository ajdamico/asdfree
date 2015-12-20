# analyze survey data for free (http://asdfree.com) with the r language
# demographic and health surveys
# malawi 2004

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/DHS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Demographic%20and%20Health%20Surveys/analysis%20examples.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#######################################################################################################
# prior to running this replication script, all dhs public use microdata files must be loaded as R data
# files (.rda) on the local machine. running the "download and import.R" script will create these files
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Demographic%20and%20Health%20Surveys/download%20and%20import.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will save a number of .rda files in C:/My Directory/DHS/ (or the working directory was chosen)
#######################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# this r script will come close to the statistics on pdf page 324 (appendix b page 303) of
# http://dhsprogram.com/pubs/pdf/FR175/FR-175-MW04.pdf#page=324
# however, many will not match precisely (especially the standard errors)
# because they have updated their recommended methodology.  for more info, read:
# http://userforum.dhsprogram.com/index.php?t=rview&goto=2154#msg_2154



################################################################################################
# analyze the 2004 malawi individual recode table of the demographic and health surveys with R #
################################################################################################


# set your working directory.
# all DHS data files will be stored here
# after downloading and importing.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/DHS/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( "survey" )


library(survey) 	# load survey package (analyzes complex design surveys)
library(foreign) 	# load foreign package (converts data files into R)


# by default, R will crash if a primary sampling unit (psu) has a single observation
# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
# by uncommenting this line:
# options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN


# the r data.frame object can be loaded directly
# from your local hard drive,
# since the download script has already run

# load the 2004 malawi individual recodes data.frame object
load( "./Malawi/Standard DHS 2004/Individual Recode.rda" )

# display the number of rows in the individual recode data set
nrow( x )

# display the first six records in the individual recode data set
head( x )

#########################
# perform a few recodes #

# convert the weight column to a numeric type
x$weight <- as.numeric( x$v005 )

# paste the `sdist` and `v025` columns together
# into a single strata variable
x$strata <- do.call( paste , x[ , c( 'sdist' , 'v025' ) ] )
# as shown at
# http://userforum.dhsprogram.com/index.php?t=rview&goto=2154#msg_2154

# construct a simple new variable: children ever born minus dead sons minus dead daughters
x <-
	transform(
		x ,
		surviving.children = v201 - v206 - v207
	)


#################################################
# survey design for taylor-series linearization #
#################################################

# create a survey design object (malawi.2004.design) with DHS design information
malawi.2004.design <- 
	svydesign( 
		~v021 , 
		strata = ~strata , 
		data = x , 
		weights = ~weight
	)
	
# notice the 'malawi.2004.design' object used in all subsequent analysis commands


#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in dhs #

# the nrow function which works on both data frame objects..
class( x )
# ..and survey design objects
class( malawi.2004.design )


# notice that the original data frame contains the same number of records as..
nrow( x )

# ..the survey object
nrow( malawi.2004.design )

# add a new variable 'one' that simply has the number 1 for each record #

malawi.2004.design <-
	update( 
		one = 1 ,
		malawi.2004.design
	)

# count the total (unweighted) number of records in dhs #
# broken out by urban/rural #

svyby(
	~one ,
	~v025 ,
	malawi.2004.design ,
	unwtd.count
)

# count the sum of the weights in dhs #

# note: this does not generalize to anything in particular.
# but if you like, you can multiply your proportions and results
# by united nations population estimates
svytotal( 
	~one , 
	malawi.2004.design 
)
# results should only be shown as _proportions_ and not totals


# weighted counts (again: meaningless)
# broken out by urban/rural #
svyby(
	~one ,
	~v025 ,
	malawi.2004.design ,
	svytotal
)


# calculate the mean of a linear variable #

# average number of surviving children - among all 15-49 year old malawian females
svymean( 
	~surviving.children , 
	design = malawi.2004.design ,
	na.rm = TRUE
)

# by urban/rural
svyby( 
	~surviving.children , 
	~v025 ,
	design = malawi.2004.design ,
	svymean ,
	na.rm = TRUE
)


# calculate the distribution of a categorical variable #

# v101 should be treated as a factor (categorical) variable
# instead of a numeric (linear) variable
# this update statement converts it.
# the svyby command below will not run without this
malawi.2004.design <-
	update( 
		v101 = factor( v101 ) ,
		malawi.2004.design
	)


# distribution of malawian 15-49 year old females - nationwide
svymean( 
	~v101 , 
	design = malawi.2004.design ,
	na.rm = TRUE
)

# by urban/rural
svyby( 
	~v101 , 
	~v025 ,
	design = malawi.2004.design ,
	svymean , 
	na.rm = TRUE
)

# calculate the median and other percentiles #

# note that a taylor-series survey design
# does not allow calculation of standard errors

# minimum, 25th, 50th, 75th, maximum 
# hours worked in the united states
svyquantile( 
	~surviving.children , 
	design = malawi.2004.design ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	na.rm = TRUE
)

# by urban/rural
svyby( 
	~surviving.children , 
	~v025 ,
	design = malawi.2004.design ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	keep.var = F ,
	na.rm = TRUE
)

######################
# subsetting example #
######################

# restrict the malawi.2004.design object to
# 40-49 year old females only
malawi.2004.design.4049 <-
	subset(
		malawi.2004.design ,
		v447a %in% 40:49
	)
# now any of the above commands can be re-run
# using the malawi.2004.design.4049 object
# instead of the malawi.2004.design object
# in order to analyze 40-49 year olds only
	
# calculate the mean of a linear variable #

# average number of children ever born
# nationwide, restricted to females aged 40-49
svymean( 
	~v201 , 
	design = malawi.2004.design.4049 ,
	na.rm = TRUE
)



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by urban/rural

# store the results into a new object

region.by.urbanrural <-
	svyby( 
		~v101 , 
		~v025 ,
		design = malawi.2004.design ,
		svymean ,
		na.rm = TRUE
	)

# print the results to the screen 
region.by.urbanrural

# now you have the results saved into a new object of type "svyby"
class( region.by.urbanrural )

# print only the statistics (coefficients) to the screen 
coef( region.by.urbanrural )

# print only the standard errors to the screen 
SE( region.by.urbanrural )

# this object can be coerced (converted) to a data frame.. 
region.by.urbanrural <- data.frame( region.by.urbanrural )

# ..and then immediately exported as a comma-separated value file 
# into your current working directory 
write.csv( region.by.urbanrural , "region by urbanrural.csv" )

# ..or trimmed to only contain the values you need.
# here's the percent of the country who live in the northern region
northern.by.urbanrural <-
	region.by.urbanrural[ , c( "v025" , "v1011" , "se.v1011" ) ]

# that's all rows, and the three specified columns


# print the new results to the screen
northern.by.urbanrural

# this can also be exported as a comma-separated value file 
# into your current working directory..
write.csv( northern.by.urbanrural , "northern by urbanrural.csv" )



# ..or directly made into a bar plot
barplot(
	northern.by.urbanrural[ , 2 ] ,							# the second column of the data frame contains the main data
	main = "Percent Northern Residents by Urban/Rural" ,	# title the barplot
	names = c( 'Urban' , 'Rural' ) ,						# individual bar labels
	ylim = c( 0 , .2 ) , 									# set the lower and upper bound of the y axis
	cex.names = 0.8 										# shrink the column labels so they all fit
)

