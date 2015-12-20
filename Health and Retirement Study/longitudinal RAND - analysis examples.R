# analyze survey data for free (http://asdfree.com) with the r language
# health and retirement study
# longitudinal RAND contributed file

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/HRS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Health%20and%20Retirement%20Study/longitudinal%20RAND%20-%20analysis%20examples.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#########################################################################################################################################
# prior to running this analysis script, the longitudinal RAND-contributed HRS files must be imported into a SQLite database on the     #
# local machine. running the import longitudinal RAND contributed files.R script to create the database automatically                   #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/Health%20and%20Retirement%20Study/import%20longitudinal%20RAND%20contributed%20files.R   #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will place the four RAND HRS files into a database "RAND.db" in the "C:/My Directory/HRS/" folder (the working directory) #
#########################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# set your working directory.
# the SQLite database file should have been stored within this folder
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/HRS/" )
# ..in order to set your current working directory


# remove the # in order to run this install.packages line only once
# install.packages( "survey" )


library(survey)		# load survey package (analyzes complex design surveys)
library(RSQLite) 	# load RSQLite package (creates database files in R)

# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN



# choose the name of the database
db.name <- 'RAND.db'


db <- dbConnect( SQLite() , db.name )			# connect to the SQLite database (.db)


# create two new tables called 'temp5resp' and 'temp10resp'
# which throw out all missing values of the weight column for one particular wave
dbSendQuery( db , "CREATE TABLE temp10resp AS SELECT * FROM hrs WHERE r10wtresp >= 0" )
dbSendQuery( db , "CREATE TABLE temp4resp AS SELECT * FROM hrs WHERE r4wtresp >= 0" )


# create two survey design objects with HRS design information #
# using the temporary tables stored in the SQLite database     #


# review PDF page 24 of this document to determine what 
# waves / years / ages are included in the HRS
# http://hrsonline.isr.umich.edu/sitedocs/surveydesign.pdf


# create a survey design using the fourth wave weights -
# wave four interviews were conducted in 1998 and generalize to the 
# united states noninstitutionalized population aged 50 and above
# (as shown in PDF page 24 of the document above, 
# not all waves generalize exactly to the 50+ population!)
r4 <- 
	svydesign(
		~raehsamp ,
		strata = ~raestrat ,
		weights = ~r4wtresp , 
		nest = TRUE ,
		data = 'temp4resp' ,
		dbtype = 'SQLite' ,
		dbname = db.name
	)

# create a survey design using the tenth wave weights -
# wave ten interviews were conducted in 2010 and generalize to the 
# united states noninstitutionalized population aged 50 and above
r10 <- 
	svydesign(
		~raehsamp ,
		strata = ~raestrat ,
		weights = ~r10wtresp , 
		nest = TRUE ,
		data = 'temp10resp' ,
		dbtype = 'SQLite' ,
		dbname = db.name
	)


# since the power of the health and retirement study is its longitudinal design,
# the above two survey objects will be used throughout these analysis commands..
# however, the 'interpretation' (who each set of results generalizes to)
# should be examined carefully, since in some cases 2010 weights are used to talk about
# these individuals in 1998 and vice versa
	
#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in the 1998 hrs #
# broken out by employment status #

svyby(
	~one ,
	~r4work ,
	r4 ,
	unwtd.count
)

# count the total (unweighted) number of records in the 2010 hrs #
# broken out by employment status #

svyby(
	~one ,
	~r10work ,
	r10 ,
	unwtd.count
)


# count the weighted number of individuals in hrs #

# the civilian, non-institutionalized population of the united states #
# aged 50+ in 1998
svytotal(
	~one ,
	r4
)

# the civilian, non-institutionalized population of the united states #
# aged 50+ in 2010
svytotal(
	~one ,
	r10
)


# the civilian, non-institutionalized population of the united states #
# aged 50+ in 1998 by employment status in that year
svyby(
	~one ,
	~r4work ,
	r4 ,
	svytotal
)

# aged 50+ in 2010 by employment status in that year
svyby(
	~one ,
	~r10work ,
	r10 ,
	svytotal
)


# hold on tight. #

##############################
# longitudinal data analysis #

# among americans who were:
	# 50 or older in 1998 and not institutionalized in 1998
	# still alive in 2010 (but possibly institutionalized)..

# ..here is their work status breakout as of 2010:
svyby(
	~one ,
	~r10work ,
	r4 ,
	svytotal
)


# among americans who were:
	# 50 or older in 1998 and not institutionalized in 1998 AND
	# still alive in 2010 (but possibly institutionalized)..

# ..about 800,000 individuals were both *not* working in 1998 but then working in 2010
svyby(
	~one ,
	~r4work + r10work ,
	r4 ,
	svytotal
)

# make sense?  the two examples above show the most important feature of the HRS: longitudinal data analysis #
##############################################################################################################


# calculate the mean of a linear variable #

# average number of people living in the household, including the respondent and spouse - nationwide
svymean(
	~h10hhres ,
	design = r10 ,
	na.rm = TRUE
)

# by work status
svyby(
	~h10hhres ,
	~r10work ,
	design = r10 ,
	svymean ,
	na.rm = TRUE
)


# calculate the distribution of a categorical variable #

# percent married - nationwide
svymean(
	~factor( r10mstat ) ,
	design = r10 ,
	na.rm = TRUE
)

# by work status
svyby(
	~factor( r10mstat ) ,
	~r10work ,
	design = r10 ,
	svymean ,
	na.rm = TRUE
)

# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum
# number of people living in the household, including the respondent and spouse - nationwide
svyquantile(
	~h10hhres ,
	design = r10 ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	na.rm = TRUE
)

# by work status
svyby(
	~h10hhres ,
	~r10work ,
	design = r10 ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	ci = T ,
	na.rm = TRUE
)

######################
# subsetting example #
######################

# restrict the r10 object to
# females only
r10.female <-
	subset(
		r10 ,
		ragender %in% 2
	)
# now any of the above commands can be re-run
# using r10.female object
# instead of the r10 object
# in order to analyze females only

# calculate the mean of a linear variable #

# number of people living in the household, including the respondent and spouse - nationwide
svymean(
	~h10hhres ,
	design = r10.female ,
	na.rm = TRUE
)



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by work status

# store the results into a new object

marital.status.by.work <-
	svyby(
		~factor( r10mstat ) ,
		~r10work ,
		design = r10 ,
		svymean ,
		na.rm = TRUE
	)

# print the results to the screen
marital.status.by.work

# now you have the results saved into a new object of type "svyby"
class( marital.status.by.work )

# print only the statistics (coefficients) to the screen
coef( marital.status.by.work )

# print only the standard errors to the screen
SE( marital.status.by.work )

# this object can be coerced (converted) to a data frame..
marital.status.by.work <- data.frame( marital.status.by.work )

# ..and then immediately exported as a comma-separated value file
# into your current working directory
write.csv( marital.status.by.work , "marital status by work.csv" )

# ..or trimmed to only contain the values you need.
# here's the "married - spouse present" rate by work status,
# with accompanying standard errors
# keeping only the second and third rows (since the first row contains minors)
married.sp.by.work <-
	marital.status.by.work[ , c( "r10work" , "factor.r10mstat.1" , "se.factor.r10mstat.1" ) ]


# print the new results to the screen
married.sp.by.work

# this can also be exported as a comma-separated value file
# into your current working directory
write.csv( married.sp.by.work , "married sp by work.csv" )

# ..or directly made into a bar plot
barplot(
	married.sp.by.work[ , 2 ] ,
	main = "Married (SP) by Work Status" ,
	names.arg = c( "Working for Pay" , "Not Working for Pay" ) ,
	ylim = c( 0 , 1 )
)


# # # # # # # # # # # # # # # # # # # # # # # #
# when finished, remove the temporary tables! # 
dbRemoveTable( db , 'temp4resp' )
dbRemoveTable( db , 'temp10resp' )
# and disconnect from the database #
dbDisconnect( db )
# # # # # # # # # # # # # # # # # # # # # # # #


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
