# analyze survey data for free (http://asdfree.com) with the r language
# current population survey 
# annual social and economic supplement
# 2012

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/CPS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Current%20Population%20Survey/2012%20asec%20-%20analysis%20examples.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# important note about the current population survey: interviews are conducted in march #
# about experiences during the previous year.  therefore, the census bureau's 2012 file #
# includes information (income, work experience, health insurance) pertaining to 2011   #
# whenever you use the current population survey to talk about america, subract a year. #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################################
# prior to running this analysis script, the cps march 2012 file must be loaded as a database (.db) on the local machine.           #
# running the 2012 download all microdata script will create this database file                                                     #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/Current%20Population%20Survey/download%20all%20microdata.R              #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "cps.asec.db" with 'asec12' in C:/My Directory/ACS or wherever the working directory was set       #
#####################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# set your working directory.
# the CPS 2012 data files should have been stored here
# after running the program described above
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/CPS/" )
# ..in order to set your current working directory



library(survey)				# load survey package (analyzes complex design surveys)
library(DBI)			# load the DBI package (implements the R-database coding)
library(MonetDBLite)		# load MonetDBLite package (creates database files in R)


# if this option is set to TRUE
# R will exactly match SUDAAN results and Stata with the MSE option results
options( survey.replicates.mse = TRUE )
# otherwise if it is commented out or set to FALSE
# R will exactly match Stata without the MSE option results

# Stata svyset command notes can be found here: http://www.stata.com/help.cgi?svyset


# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )


#######################################
# survey design for replicate weights #
#######################################

# create survey design object with CPS design information
# using existing data frame of CPS data
y <- 
	svrepdesign(
		weights = ~marsupwt, 
		repweights = "pwwgt[1-9]", 
		type = "Fay", 
		rho = (1-1/sqrt(4)),
		data = "asec12" ,
		combined.weights = T ,
		dbtype = "MonetDBLite" ,
		dbname = dbfolder
	)

# workaround for a bug in survey::svrepdesign.character
y$mse <- TRUE


	
#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in cps #
# broken out by employment status #

svyby(
	~moop ,
	~workyn ,
	y ,
	unwtd.count
)



# count the weighted number of individuals in cps #

# the civilian, non-institutionalized population of the united states #
svytotal(
	~one ,
	y
)

# note that this is exactly equivalent to summing up the weight variable
# from the original cps data frame

db <- dbConnect( MonetDBLite() , dbfolder )					# connect to the SQLite database (.db)
dbGetQuery( db , 'select sum( marsupwt ) from asec12' )		# run a single query, summing the person-weight
dbDisconnect( db )											# disconnect from the database but do not shut it down


# the civilian, non-institutionalized population of the united states #
# by employment status
svyby(
	~one ,
	~workyn ,
	y ,
	svytotal
)


# calculate the mean of a linear variable #

# average out-of-pocket medical expenditure - nationwide (includes over-the-counter)
svymean(
	~moop ,
	design = y
)

# by employment status
svyby(
	~moop ,
	~workyn ,
	design = y ,
	svymean
)


# calculate the distribution of a categorical variable #

# A-MARITL should be treated as a factor (categorical) variable
# instead of a numeric (linear) variable
# this update statement converts it.
# the svyby command below will not run without this
y <-
	update(
		a_maritl = factor( a_maritl ) ,
		y
	)


# percent married - nationwide
svymean(
	~a_maritl ,
	design = y
)

# by employment status
svyby(
	~a_maritl ,
	~workyn ,
	design = y ,
	svymean
)

# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum
# out-of-pocket medical expenditure in the united states (includes over-the-counter)
svyquantile(
	~moop ,
	design = y ,
	c( 0 , .25 , .5 , .75 , 1 )
)

# by employment status
svyby(
	~moop ,
	~workyn ,
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
		a_sex %in% 2
	)
# now any of the above commands can be re-run
# using y.female object
# instead of the y object
# in order to analyze females only

# calculate the mean of a linear variable #

# average out-of-pocket medical expenditure - nationwide, restricted to females
svymean(
	~moop ,
	design = y.female
)



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by employment status

# store the results into a new object

marital.status.by.employment <-
	svyby(
		~a_maritl ,
		~workyn ,
		design = y ,
		svymean
	)

# print the results to the screen
marital.status.by.employment

# now you have the results saved into a new object of type "svyby"
class( marital.status.by.employment )

# print only the statistics (coefficients) to the screen
coef( marital.status.by.employment )

# print only the standard errors to the screen
SE( marital.status.by.employment )

# this object can be coerced (converted) to a data frame..
marital.status.by.employment <- data.frame( marital.status.by.employment )

# ..and then immediately exported as a comma-separated value file
# into your current working directory
write.csv( marital.status.by.employment , "marital status by employment.csv" )

# ..or trimmed to only contain the values you need.
# here's the "married - spouse present" rate by employment status,
# with accompanying standard errors
# keeping only the second and third rows (since the first row contains minors)
married.sp.by.employment <-
	marital.status.by.employment[ 2:3 , c( "workyn" , "a_maritl1" , "se1" ) ]


# print the new results to the screen
married.sp.by.employment

# this can also be exported as a comma-separated value file
# into your current working directory
write.csv( married.sp.by.employment , "married sp by employment.csv" )

# ..or directly made into a bar plot
barplot(
	married.sp.by.employment[ , 2 ] ,
	main = "Married (SP) by Employment Status" ,
	names.arg = c( "Employed" , "Not Employed" ) ,
	ylim = c( 0 , .6 )
)
