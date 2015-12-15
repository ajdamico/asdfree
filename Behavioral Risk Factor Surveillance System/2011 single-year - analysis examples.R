# analyze survey data for free (http://asdfree.com) with the r language
# behavioral risk factor surveillance system
# 2011

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/BRFSS/" )
# source_url( "https://raw.github.com/ajdamico/asdfree/master/Behavioral%20Risk%20Factor%20Surveillance%20System/2011%20single-year%20-%20analysis%20examples.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#########################################################################################################################################
# prior to running this analysis script, the brfss 2011 single-year file must be loaded as a monet database-backed sqlsurvey object     #
# on the local machine. running the 1984-2011 download and create database script will create a monet database containing this file     #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/asdfree/blob/master/Behavioral%20Risk%20Factor%20Surveillance%20System/download%20all%20microdata.R       #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "b2011 design.rda" in C:/My Directory/BRFSS or wherever the working directory was set for the program  #
#########################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# remove the # in order to run this install.packages line only once
# install.packages( "stringr" )

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/BRFSS/" )


library(survey)			# load survey package (analyzes complex design surveys)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(MonetDBLite)	# load MonetDBLite package (creates database files in R)
library(stringr) 		# load stringr package (manipulates character strings easily)



# uncomment one of these lines by removing the `#` at the front..
# load( 'b2010 design.rda' )	# analyze the 2010 single-year acs
load( 'b2011 design.rda' )	# analyze the 2011 single-year acs
# load( 'b2009 design.rda' )	# analyze the 2009 single-year acs
# load( 'b1984 design.rda' )	# analyze the 1984 single-year acs


# connect the complex sample designs to the monet database #
brfss.d <- open( brfss.design , driver = MonetDB.R() )	# single-year design


# - but they're not (at least for these analysis examples),
# so you have to run three quick recodes
brfss.d <- 
	update( 
		brfss.d ,
		hlthpln1 = factor( hlthpln1 ) ,
		sex = factor( sex ) ,
		medcost = factor( medcost )
	)


################################################
# ..and immediately start the example analyses #
################################################

# count the total (unweighted) number of records in brfss #

# simply use the nrow function..
nrow( brfss.d )

# ..on the survey design object
class( brfss.d )


# since the brfss gets loaded as a monet database-backed survey object instead of a data frame,
# the number of unweighted records cannot be calculated by running the nrow() function on a data frame.

# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )

# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite() , dbfolder )

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
svymean( ~age , brfss.d , na.rm = TRUE )

# by state
svyby( ~age , ~ xstate , brfss.d , svymean , na.rm = TRUE )


# calculate the distribution of a categorical variable #

# percent uninsured - nationwide
svymean( ~hlthpln1 , brfss.d )

# by state
svyby( ~hlthpln1 , ~xstate , brfss.d , svymean )


# calculate the median and other percentiles #

# median age of residents of the united states
svyquantile( ~age , brfss.d , 0.5 , na.rm = TRUE )
# note: quantile standard errors cannot be computed with taylor-series linearization designs


# print the median and 99th percentiles
svyquantile( ~age , brfss.d , c( 0.5 , 0.99 ) , na.rm = TRUE )


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

cost.problems.by.coverage <- svyby( ~medcost , ~hlthpln1 , brfss.d , svymean )

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
