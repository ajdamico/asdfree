# analyze survey data for free (http://asdfree.com) with the r language
# national health interview survey
# 2011 personsx

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NHIS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Health%20Interview%20Survey/2011%20personsx%20-%20analyze.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico the first
# ajdamico@gmail.com



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################################
# prior to running this analysis script, the nhis 2011 personsx file must be loaded as an R data file (.rda) on the local machine.  #
# running the "1963-2011 - download all microdata.R" script will create this R data file (note: only 2011 files need to be loaded)  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/asdfree/blob/master/National%20Health%20Interview%20Survey/1963-2011%20-%20download%20all%20microdata.R #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "/2011/personsx.rda" in C:/My Directory/NHIS (or wherever the working directory was chosen)        #
#####################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



##########################################################################
# Analyze the 2011 National Health Interview Survey personsx file with R #
##########################################################################


# set your working directory.
# the NHIS 2011 personsx data file should have been
# stored in a year-specific directory within this folder.
# so if the file "personsx.rda" exists in the directory "C:/My Directory/NHIS/2011/" 
# then the working directory should be set to "C:/My Directory/NHIS/"
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NHIS/" )
# ..in order to set your current working directory


# remove the # in order to run this install.packages line only once
# install.packages( "survey" )

library(survey) # load survey package (analyzes complex design surveys)


# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN


# choose what year of data to analyze
# note: this can be changed to any year that has already been downloaded locally
# by the "1963-2011 - download all microdata.R" program above
year <- 2011


# construct the filepath (within the current working directory) to the personsx.rda file
path.to.rda.file <- paste( getwd() , year , "personsx.rda" , sep = "/" )

# print that filepath to the screen
print( path.to.rda.file )


# now the "NHIS.11.personsx.df" data frame can be loaded directly
# from your local hard drive.  this is much faster.
load( path.to.rda.file )


# construct a string containing the data frame name of the personsx data table
# stored within the R data file (.rda)
# note: for 2011, this data frame will be named "NHIS.11.personsx.df"
# but constructing it dynamically will allow analyses of other years
# by simply changing the 'year' variable above
df.name <- paste( "NHIS" , substr( year , 3 , 4 ) , "personsx" , "df" , sep = "." )

# copy the personsx data frame to the variable x for easier analyses
# (because NHIS.11.personsx.df is unwieldy to keep typing)
x <- get( df.name )

# remove the original copy of the data frame from memory
rm( list = df.name )

# clear up RAM
gc()


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
		data = x
	)

# notice the 'nhissvy' object used in all subsequent analysis commands

	
#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in nhis #

# simply use the nrow function
nrow( nhissvy )

# the nrow function which works on both data frame objects..
class( x )
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

sum( x$wtfa )

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

