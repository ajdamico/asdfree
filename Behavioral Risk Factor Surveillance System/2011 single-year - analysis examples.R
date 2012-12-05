# analyze us government survey data with the r language
# behavioral risk factor surveillance system
# 2011

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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###################################################################################################################################################
# prior to running this analysis script, the brfss 2011 single-year file must be loaded as a monet database-backed sqlsurvey object               #
# on the local machine. running the 1984-2011 download and create database script will create a monet database containing this file               #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/usgsd/blob/master/Behavioral%20Risk%20Factor%20Surveillance%20System/1984%20-%202011%20download%20all%20microdata.R #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "b2011 design.rda" in C:/My Directory/BRFSS or wherever the working directory was set for the program            #
###################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # #
# warning: monetdb required #
# # # # # # # # # # # # # # #


# remove the # in order to run this install.packages line only once
# install.packages( "stringr" )


require(sqlsurvey)		# load sqlsurvey package (analyzes large complex design surveys)
require(stringr) 		# load stringr package (manipulates character strings easily)


# after running the r script above, users should have handy a few lines
# to initiate and connect to the monet database containing all behavioral risk factor surveillance system tables
# run them now.  mine look like this:


####################################################################
# lines of code to hold on to for all other brfss monetdb analyses #

# first: your shell.exec() function.  again, mine looks like this:
shell.exec( "C:/My Directory/BRFSS/MonetDB/monetdb.bat" )

# second: add a twenty second system sleep in between the shell.exec() function
# and the database connection lines.  this gives your local computer a chance
# to get monetdb up and running.
Sys.sleep( 20 )

# third: your six lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "brfss"
dbport <- 50003
monetdriver <- "c:/program files/monetdb/monetdb5/monetdb-jdbc-2.7.jar"
drv <- MonetDB( classPath = monetdriver )
monet.url <- paste0( "jdbc:monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( drv , monet.url , user = "monetdb" , password = "monetdb" )

# end of lines of code to hold on to for all other brfss monetdb analyses #
###########################################################################


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

load( 'C:/My Directory/BRFSS/b2011 design.rda' )	# analyze the 2011 single-year acs

# note: this r data file should already contain the 2011 single-year design


# the current sqlsurvey package contains a minor bug.
# this line manually fixes of the open() method
# for the sqlsurvey() function
open.sqlsurvey<-function(con, driver, ...){  
  con$conn<-dbConnect(driver, url=con$dbname,...)
  if (!is.null(con$subset)){
    con$subset$conn<-con$conn
  }
  con
}
# this bug has been reported to the sqlsurvey package author



# connect the complex sample designs to the monet database #
brfss.d <- open( brfss.design , driver = drv , user = "monetdb" , password = "monetdb" )	# single-year design




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
# broken out by ever having trouble accessing medical care due to cost

# store the results into a new object

coverage.by.cost.problems <- svymean( ~hlthpln1 , brfss.d , byvar = ~medcost )

# print the results to the screen 
coverage.by.cost.problems

# now you have the results saved into a new data.frame..
class( coverage.by.cost.problems )

# ..and then immediately exported as a comma-separated value file 
# into your current working directory 
write.csv( coverage.by.cost.problems , "coverage by cost problems.csv" )

# ..or trimmed to only contain the values you need.
# here's the uninsured percentage broken out by cost problems, 
# with accompanying standard errors
uninsured.rate.by.cost.problems <-
	coverage.by.cost.problems[ , 2 ]


# print the new results to the screen
uninsured.rate.by.cost.problems

# this can also be exported as a comma-separated value file 
# into your current working directory 
write.csv( uninsured.rate.by.cost.problems , "uninsured rate by cost problems.csv" )

# ..or directly made into a bar plot
barplot(
	uninsured.rate.by.cost.problems ,
	main = "Uninsured Rate by Cost-Related Access Problems" ,
	names.arg = c( "Yes" , "No" , "Don't Know" , "Refused" ) ,
	ylim = c( 0 , .60 )
)


############################
# end of analysis examples #
############################


# close the connection to the two sqlrepsurvey design objects
close( brfss.d )

# close the connection to the monet database
dbDisconnect( db )


# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
