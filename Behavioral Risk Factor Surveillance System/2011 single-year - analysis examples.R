# analyze survey data for free (http://asdfree.com) with the r language
# behavioral risk factor surveillance system
# 2011

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# batfile <- "C:/My Directory/BRFSS/MonetDB/brfss.bat"
# load( 'C:/My Directory/BRFSS/b2011 design.rda' )	# analyze the 2011 single-year brfss
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Behavioral%20Risk%20Factor%20Surveillance%20System/2011%20single-year%20-%20analysis%20examples.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# http://www.screenr.com/Zpd8

# anthony joseph damico
# ajdamico@gmail.com

# if you use this script for a project, please send me a note
# it's always nice to hear about how people are using this stuff

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#########################################################################################################################################
# prior to running this analysis script, the brfss 2011 single-year file must be loaded as a monet database-backed sqlsurvey object     #
# on the local machine. running the 1984-2011 download and create database script will create a monet database containing this file     #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/usgsd/blob/master/Behavioral%20Risk%20Factor%20Surveillance%20System/download%20all%20microdata.R         #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "b2011 design.rda" in C:/My Directory/BRFSS or wherever the working directory was set for the program  #
#########################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # #
# warning: monetdb required #
# # # # # # # # # # # # # # #


# remove the # in order to run this install.packages line only once
# install.packages( "stringr" )


require(sqlsurvey)		# load sqlsurvey package (analyzes large complex design surveys)
require(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
require(stringr) 		# load stringr package (manipulates character strings easily)


# after running the r script above, users should have handy a few lines
# to initiate and connect to the monet database containing all behavioral risk factor surveillance system tables
# run them now.  mine look like this:


######################################################################
# lines of code to hold on to for all other `brfss` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/BRFSS/MonetDB/brfss.bat"

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "brfss"
dbport <- 50004

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url )


# # # # run your analysis commands # # # #


# the behavioral risk factor surveillance system download and importation script
# has already created a monet database-backed survey design object
# connected to the 2011 single-year table

# sqlite database-backed survey objects are described here: 
# http://faculty.washington.edu/tlumley/survey/svy-dbi.html
# monet database-backed survey objects are similar, but:
# the database engine is, well, blazingly faster
# the setup is kinda more complicated (but all done for you)

# since this script only loads one file off of the local drive,
# there's no need to set the working directory.
# instead, simply use the full filepath to the r data file (.rda)
# as shown in the load() examples below.


# choose which single-year file in your BRFSS directory to analyze
# this script replicates the 2011 single-year estimates,
# so leave that line uncommented and the other three choices commented out.

# load the desired behavioral risk factor surveillance system monet database-backed complex sample design objects

# note: this r data file should already contain the 2011 single-year design


# if the column classes are already correct, you could use this line -

# connect the complex sample designs to the monet database #
# brfss.d <- open( brfss.design , driver = MonetDB.R() )	# single-year design

# - but they're not (at least for these analysis examples),
# so you have to run three quick recodes


################################################################################################
# create a new survey design object with the variables you're going to use as character/factor #

# this process runs much faster if you create a character vector containing all non-numeric columns
# otherwise, just set `check.factors = 10` within the sqlsurvey function and it take a guess at which columns
# are character strings or factor variables and which columns should be treated as numbers

# step 1: load the pre-recoded (previous) design 

# uncomment this line by removing the `#` at the front..
# load( 'C:/My Directory/BRFSS/b2011 design.rda' )	# analyze the 2011 single-year brfss

# step 2: extract the character columns
all.classes <- sapply( brfss.design$zdata , class )
factor.columns <- names( all.classes[ !( all.classes %in% c( 'integer' , 'numeric' ) ) ] )

# since we're going to use the uninsured, medical cost, and sex variables in this analysis
# and the cdc's sas code has these variables listed as numeric not character strings..
# http://www.cdc.gov/brfss/annual_data/2011/SASOUT11_LLCP.SAS
# ..they need to be converted over to character
factor.columns <- c( factor.columns , 'hlthpln1' , 'sex' , 'medcost' )

# step 3: re-create a sqlsurvey complex sample design object

brfss.d <-
	sqlsurvey(
		weight = brfss.design$weight ,
		nest = TRUE ,
		strata = brfss.design$strata ,
		id = brfss.design$id ,
		table.name = brfss.design$table ,						
		key = brfss.design$key ,
		check.factors = factor.columns ,			# specify which columns are non-numeric.. or remove this parameter and sqlsurvey() will guess for you.
		database = monet.url ,
		driver = MonetDB.R()
	)



################################################
# ..and immediately start the example analyses #
################################################

# count the total (unweighted) number of records in brfss #

# simply use the nrow function..
nrow( brfss.d )

# ..on the sqlsurvey design object
class( brfss.d )


# since the brfss gets loaded as a monet database-backed survey object instead of a data frame,
# the number of unweighted records cannot be calculated by running the nrow() function on a data frame.

# running the nrow() function on the database connection object
# simply produces an error..
# nrow( db )

# because the monet database might contain multiple data tables
class( db )


# instead, perform the same unweighted count directly from the sql table
# stored inside the monet database on your hard disk (as opposed to RAM)
dbGetQuery( db , "SELECT COUNT(*) AS num_records FROM b2011" )

	

# count the total (unweighted) number of records in brfss #
# broken out by state #

# note: this is easiest by simply running a sql query on the monet database directly
dbGetQuery( db , "SELECT xstate , COUNT(*) as num_records FROM b2011 GROUP BY xstate" )



# count the weighted number of individuals in brfss #

# the adult non-institutionalized population of the united states #
# note that this should be calculated by summing up the weight variable
# from the original database (.db) file connection
dbGetQuery( db , "SELECT SUM( xllcpwt ) AS sum_weights FROM b2011" )


# the adult non-institutionalized population of the united states #
# by state
dbGetQuery( db , "SELECT xstate , SUM( xllcpwt ) AS sum_weights FROM b2011 group by xstate" )
# note: the above command is one example of how the r survey package differs from the r sqlsurvey package


# calculate the mean of a linear variable #

# average age - nationwide
svymean( ~age , brfss.d )

# by state
svymean( ~age , brfss.d , byvar = ~xstate )


# calculate the distribution of a categorical variable #

# HLTHPLN1 has been converted to a factor (categorical) variable
# instead of a numeric (linear) variable,
# because it only contains the values 1, 2, 7, and 9
# when the brfss.d object was created with the function sqlrepdesign()
# the check.factors parameter was left at the default of ten,
# meaning all numeric columns with ten or fewer distinct values
# would be automatically converted to factors

# percent uninsured - nationwide
svymean( ~hlthpln1 , brfss.d )

# by state
svymean( ~hlthpln1 , brfss.d , byvar = ~xstate )


# calculate the median and other percentiles #

# median age of residents of the united states
svyquantile( ~age , brfss.d , quantiles = 0.5 )
# note: quantile standard errors cannot be computed with taylor-series linearization designs
# this is true in both the survey and sqlsurvey packages

# note two additional differences between the sqlsurvey and survey packages..

# ..sqlsurvey designs do not allow multiple quantiles.  instead, 
# loop through and print or save multiple quantiles, simply use a for loop

# loop through the median and 99th percentiles and print both results to the screen
for ( i in c( .5 , .99 ) ) print( svyquantile( ~age , brfss.d , quantiles = i ) )



# ..sqlsurvey designs do not allow byvar arguments, meaning the only way to 
# calculate quantiles by state would be by creating subsets for each subpopulation
# and calculating the quantiles for them independently:

######################
# subsetting example #
######################

# restrict the brfss.d object to females only
brfss.d.female <- subset( brfss.d , sex == 2 )

# now any of the above commands can be re-run
# using the brfss.d.female object
# instead of the brfss.d object
# in order to analyze females only
	
# calculate the distribution of a categorical variable #

# percent uninsured - nationwide, restricted to females
svymean( ~hlthpln1 , brfss.d.female )


###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# broken out by health insurance status

# store the results into a new object

cost.problems.by.coverage <- svymean( ~medcost , brfss.d , byvar = ~hlthpln1 )

# print the results to the screen 
cost.problems.by.coverage

# now you have the results saved into a new data.frame..
class( cost.problems.by.coverage )

# ..and then immediately exported as a comma-separated value file 
# into your current working directory 
write.csv( cost.problems.by.coverage , "cost problems by coverage.csv" )

# ..or trimmed to only contain the values you need.
# here's the cost problem percentage broken out by insurance status, 
# with accompanying standard errors
cost.problems.by.insurance.status <-
	data.frame( cost.problems.by.coverage )[ 1:2 , 1 ]


# print the new results to the screen
cost.problems.by.insurance.status

# this can also be exported as a comma-separated value file 
# into your current working directory 
write.csv( cost.problems.by.insurance.status , "cost problems by insurance status.csv" )

# ..or directly made into a bar plot
barplot(
	cost.problems.by.insurance.status ,
	main = "Any Cost-Related Access Problems By Insurance Status" ,
	names.arg = c( "Insured" , "Uninsured" ) ,
	ylim = c( 0 , .60 )
)


############################
# end of analysis examples #
############################


# close the connection to the two sqlrepsurvey design objects
close( brfss.d )


# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other `brfss` monetdb analyses #
#############################################################################


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
