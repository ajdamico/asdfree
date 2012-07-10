# importation and analysis of us government survey data
# national health interview survey
# 2011 personsx

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# http://www.screenr.com/Zpd8

# anthony joseph damico
# ajdamico@gmail.com

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf


##########################################################################
# Analyze the 2011 National Health Interview Survey personsx file with R #
##########################################################################


# set your working directory.
# the NHIS 2011 data file will be stored here
# after downloading and importing it.
# use forward slashes instead of back slashes

setwd( "C:/My Directory/NHIS/" )


# remove the # in order to run this install.packages line only once
# install.packages( c( "survey" , "SAScii" ) )


require(survey) # load survey package (analyzes complex design surveys)
require(SAScii) # load the SAScii package (imports ascii data with a SAS script)


# set R to produce conservative standard errors instead of crashing
# http://faculty.washington.edu/tlumley/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN


###############################################
# DATA LOADING COMPONENT - ONLY RUN THIS ONCE #
###############################################

# this process is slow.
# note the record counter while waiting for these commands to run.
# the NHIS 2011 personsx file has 101,875 records.

NHIS.11.personsx.SAS.read.in.instructions <-
	"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Program_Code/NHIS/2011/personsx.sas"
	
NHIS.11.personsx.file.location <-
	"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/2011/personsx.zip"

# store the NHIS file as an R data frame
NHIS.11.personsx.df <-
	read.SAScii (
		NHIS.11.personsx.file.location ,
		NHIS.11.personsx.SAS.read.in.instructions ,
		zipped = T 
	)

# the read.SAScii function produces column names with all capital letters
# convert them all to lowercase
names( NHIS.11.personsx.df ) <- tolower( names( NHIS.11.personsx.df ) )

# save the data frame now for instantaneous loading later.
# this stores the NHIS 2011 personsx table as an R data file.
save( NHIS.11.personsx.df , file = "NHIS.11.personsx.data.rda" )

##########################################################################
# END OF DATA LOADING COMPONENT - DO NOT RUN DATA LOADING COMMANDS AGAIN #
##########################################################################

# now the "NHIS.11.personsx.df" data frame can be loaded directly
# from your local hard drive.  this is much faster.
load( "NHIS.11.personsx.data.rda" )
	
	
#################################################
# survey design for taylor-series linearization #
#################################################

# create survey design object with NHIS design information
# using existing data frame of NHIS data
nhissvy <- 
	svydesign(
		id = ~psu_p , 
		strata = ~strat_p ,
		nest = TRUE ,
		weights = ~wtfa ,
		data = NHIS.11.personsx.df
	)

# notice the 'nhissvy' object used in all subsequent analysis commands

	
#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in nhis #

# simply use the nrow function
nrow( nhissvy )

# the nrow function which works on both data frame objects..
class( NHIS.11.personsx.df )
# ..and survey design objects
class( nhissvy )

# count the total (unweighted) number of records in nhis #
# broken out by region of the country #

svyby(
	~age_p ,
	~region ,
	nhissvy ,
	unwtd.count
)



# count the weighted number of individuals in nhis #

# add a new variable 'one' that simply has the number 1 for each record #

nhissvy <-
	update( 
		one = 1 ,
		nhissvy
	)

# the civilian, non-institutionalized population of the united states #
svytotal( 
	~one , 
	nhissvy 
)


# note that this is exactly equivalent to summing up the weight variable
# from the original NHIS data frame

sum( NHIS.11.personsx.df$wtfa )

# the civilian, non-institutionalized population of the united states #
# by region of the country
svyby(
	~one ,
	~region ,
	nhissvy ,
	svytotal
)


# calculate the mean of a linear variable #

# average age - nationwide
svymean( 
	~age_p , 
	design = nhissvy
)

# by region of the country
svyby( 
	~age_p , 
	~region ,
	design = nhissvy ,
	svymean
)


# calculate the distribution of a categorical variable #

# percent uninsured - nationwide
svymean( 
	~factor( notcov ) , 
	design = nhissvy
)

# by region of the country
svyby( 
	~factor( notcov ) , 
	~region ,
	design = nhissvy ,
	svymean
)


# calculate the median and other percentiles #

# note that a taylor-series survey design
# does not allow calculation of standard errors

# minimum, 25th, 50th, 75th, maximum 
# ages in the united states
svyquantile( 
	~age_p , 
	design = nhissvy ,
	c( 0 , .25 , .5 , .75 , 1 )
)

# by region of the country
svyby( 
	~age_p , 
	~region ,
	design = nhissvy ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	keep.var = F
)


######################
# subsetting example #
######################

# restrict the nhissvy object to
# females only
nhissvy.female <-
	subset(
		nhissvy ,
		sex %in% 2
	)
# now any of the above commands can be re-run
# using the nhissvy.female object
# instead of the nhissvy object
# in order to analyze females only
	
# calculate the mean of a linear variable #

# average age - nationwide, restricted to females
svymean( 
	~age_p , 
	design = nhissvy.female
)


###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by region of the country

# store the results into a new object

coverage.by.region <-
	svyby( 
		~factor( notcov ) , 
		~region ,
		design = nhissvy ,
		svymean
	)

# print the results to the screen 
coverage.by.region

# now you have the results saved into a new object of type "svyby"
class( coverage.by.region )

# print only the statistics (coefficients) to the screen 
coef( coverage.by.region )

# print only the standard errors to the screen 
SE( coverage.by.region )

# this object can be coerced (converted) to a data frame.. 
coverage.by.region <- data.frame( coverage.by.region )

# ..and then immediately exported as a comma-separated value file 
# into your current working directory 
write.csv( coverage.by.region , "coverage by region.csv" )

# ..or trimmed to only contain the values you need.
# here's the uninsured percentage by region, 
# with accompanying standard errors
uninsured.rate.by.region <-
	coverage.by.region[ , c( "region" , "factor.notcov.1" , "se.factor.notcov.1" ) ]

# that's all four rows and the three specified columns


# print the new results to the screen
uninsured.rate.by.region

# this can also be exported as a comma-separated value file 
# into your current working directory 
write.csv( uninsured.rate.by.region , "uninsured rate by region.csv" )

# ..or directly made into a bar plot
barplot(
	uninsured.rate.by.region[ , 2 ] ,
	main = "Uninsured Rate by Region of the Country" ,
	names.arg = c( "Northeast" , "Midwest" , "South" , "West" ) ,
	ylim = c( 0 , .25 )
)


# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
