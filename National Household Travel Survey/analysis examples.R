# analyze survey data for free (http://asdfree.com) with the r language
# national household travel survey
# 2009 person file

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( "monetdb.sequential" = TRUE )		# # only windows users need this line
# library(downloader)
# batfile <- "C:/My Directory/NHTS/MonetDB/nhts.bat"	# # note for mac and *nix users: `nhts.bat` might be `nhts.sh` instead"
# load( 'C:/My Directory/NHTS/2009 designs.rda' )
# source_url( "https://raw.github.com/ajdamico/asdfree/master/National%20Household%20Travel%20Survey/analysis%20examples.R" , prompt = FALSE , echo = TRUE )
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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#########################################################################################################################
# prior to running this analysis script, the nhts 2009 file must be loaded as a monet database-backed sqlsurvey object  #
# on the local machine. running the download and import script will create a monet database containing this file.       #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw2.github.com/ajdamico/asdfree/master/National%20Household%20Travel%20Survey/download%20and%20import.R        #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "2009 designs.rda" in C:/My Directory/NHTS or wherever the working directory was set.  #
#########################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # #
# warning: monetdb required #
# # # # # # # # # # # # # # #


# windows machines and also machines without access
# to large amounts of ram will often benefit from
# the following option, available as of MonetDB.R 0.9.2 --
# remove the `#` in the line below to turn this option on.
# options( "monetdb.sequential" = TRUE )		# # only windows users need this line
# -- whenever connecting to a monetdb server,
# this option triggers sequential server processing
# in other words: single-threading.
# if you would prefer to turn this on or off immediately
# (that is, without a server connect or disconnect), use
# turn on single-threading only
# dbSendQuery( db , "set optimizer = 'sequential_pipe';" )
# restore default behavior -- or just restart instead
# dbSendQuery(db,"set optimizer = 'default_pipe';")


library(sqlsurvey)		# load sqlsurvey package (analyzes large complex design surveys)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)


# after running the r script above, users should have handy a few lines
# to initiate and connect to the monet database containing all national household travel survey
# run them now.  mine look like this:


#####################################################################
# lines of code to hold on to for all other `nhts` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/NHTS/MonetDB/nhts.bat"	# # note for mac and *nix users: `nhts.bat` might be `nhts.sh` instead"

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "nhts"
dbport <- 50013

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )


# # # # run your analysis commands # # # #




# R will exactly match SUDAAN results and Stata with the MSE option results
options( survey.replicates.mse = TRUE )
# otherwise if it is commented out or set to FALSE


# the national household travel survey download and importation script
# has already created a monet database-backed survey design object
# connected to the 2009 tables

# sqlite database-backed survey objects are described here: 
# http://r-survey.r-forge.r-project.org/survey/svy-dbi.html
# monet database-backed survey objects are similar, but:
# the database engine is, well, blazingly faster
# the setup is kinda more complicated (but all done for you)

# since this script only loads one file off of the local drive,
# there's no need to set the working directory.
# instead, simply use the full filepath to the r data file (.rda)
# as shown in the load() examples below.

# load the desired national household travel survey monet database-backed complex sample design objects

# uncomment this line by removing the `#` at the front..
# load( 'C:/My Directory/NHTS/2009 designs.rda' )	# analyze the 2009 designs


# note: this r data file should already contain all of the designs for this year


# connect the complex sample designs to the monet database #

nhts.per.design <- open( nhts.per.design , driver = MonetDB.R() , wait = TRUE )	# person-level design



################################################
# ..and immediately start the example analyses #
################################################

# count the total (unweighted) number of records in the person-file #

# simply use the nrow function..
nrow( nhts.per.design )

# ..on the sqlrepsurvey design object
class( nhts.per.design )


# since the nhts gets loaded as a monet database-backed survey object instead of a data frame,
# the number of unweighted records cannot be calculated by running the nrow() function on a data frame.

# running the nrow() function on the database connection object
# simply produces an error..
# nrow( db )

# because the monet database might contain multiple data tables
class( db )


# instead, perform the same unweighted count directly from the sql table
# stored inside the monet database on your hard disk (as opposed to RAM)
dbGetQuery( db , "SELECT COUNT(*) AS num_records FROM per_m_2009" )

	

# count the total (unweighted) number of records in nhts #
# broken out by state #

# note: this is easiest by simply running a sql query on the monet database directly
dbGetQuery( db , "SELECT hhstate , COUNT(*) as num_records FROM per_m_2009 GROUP BY hhstate" )



# count the weighted number of individuals in nhts #

# the non-institutionalized civilian population of the united states older than four years #
svytotal( ~one , nhts.per.design )

# note that this is exactly equivalent to summing up the weight variable
# from the original database (.db) file connection
dbGetQuery( db , "SELECT SUM( wtperfin ) AS sum_weights FROM per_m_2009" )


# the over-four population of the united states #
# by state
svytotal( ~one , nhts.per.design , byvar = ~hhstate )
# note: the above command is one example of how the r survey package differs from the r sqlsurvey package


# calculate the mean of a linear variable #

# average age - nationwide
svymean( ~r_age , nhts.per.design )

# by state
svymean( ~r_age , nhts.per.design , byvar = ~hhstate )


# calculate the distribution of a categorical variable #

# percent with access to heavy rail
svymean( ~I( rail == 1 ) , nhts.per.design )

# by state
svymean( ~I( rail == 1 ) , nhts.per.design , byvar = ~hhstate )


# calculate the median and other percentiles #

# median age of residents of the united states
svyquantile( ~r_age , nhts.per.design , , quantiles = 0.5 , se = T )

# note two additional differences between the sqlsurvey and survey packages..

# ..sqlrepsurvey designs do not allow multiple quantiles.  instead, 
# loop through and print or save multiple quantiles, simply use a for loop

# loop through the 25th, 50th, and 75th quantiles and print each result to the screen
for ( i in c( .25 , .5 , .75 ) ) print( svyquantile( ~r_age , nhts.per.design , quantiles = i , se = TRUE ) )


# ..sqlrepsurvey designs do not allow byvar arguments, meaning the only way to 
# calculate quantiles by state would be by creating subsets for each subpopulation
# and calculating the quantiles for them independently:

######################
# subsetting example #
######################

# restrict the nhts.per.design object to females only
nhts.per.design.female <- subset( nhts.per.design , r_sex == 2 )

# now any of the above commands can be re-run
# using the nhts.per.design.female object
# instead of the nhts.per.design object
# in order to analyze females only
	
# calculate the mean of a linear variable #

# average age - nationwide, restricted to females
svymean( ~r_age , nhts.per.design.female )

# median age - nationwide, restricted to females
svyquantile( ~r_age , nhts.per.design.female , quantiles = 0.5 , se = T )



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by region of the country

# store the results into a new object

rail.by.region <- svymean( ~I( rail == 1 ) , nhts.per.design , byvar = ~census_r )

# print the results to the screen 
rail.by.region

# now you have the results saved into a new svyrepstat object..
class( rail.by.region )

# print only the statistics (coefficients) to the screen 
coef( rail.by.region )

# print only the standard errors to the screen 
SE( rail.by.region )

# this object can be coerced (converted) to a data frame.. 
rail.by.region <- data.frame( rail.by.region )


# ..and then immediately exported as a comma-separated value file 
# into your current working directory 
write.csv( rail.by.region , "rail by region.csv" )


# ..or directly made into a bar plot
barplot(
	rail.by.region[ , 1 ] ,
	main = "Access to Heavy Rail by Region of the Country" ,
	names.arg = c( "Northeast" , "Midwest" , "South" , "West" ) ,
	ylim = c( 0 , 1 )
)


############################
# end of analysis examples #
############################


# close the connection to the sqlrepsurvey design object
close( nhts.per.design )


# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other `nhts` monetdb analyses #
############################################################################


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
