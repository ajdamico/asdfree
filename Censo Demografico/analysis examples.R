# analyze survey data for free (http://asdfree.com) with the r language
# censo demografico
# 2010 gerais da amostra (general sample)
# household + person-level merged files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( "monetdb.sequential" = TRUE )		# # only windows users need this line
# library(downloader)
# batfile <- "C:/My Directory/CENSO/MonetDB/censo_demografico.bat"		# # note for mac and *nix users: `censo_demografico.bat` might be `censo_demografico.sh` instead
# load( 'C:/My Directory/CENSO/pes 2010 design.rda' )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Censo%20Demografico/analysis%20examples.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# https://www.youtube.com/watch?v=JLt9JfaAxUg

# djalma pessoa
# pessoad@gmail.com

# anthony joseph damico
# ajdamico@gmail.com

# if you use this script for a project, please send me a note
# it's always nice to hear about how people are using this stuff

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###############################################################################################
# prior to running this analysis script, the 2010 censo demografico must be loaded as a monet #
# database-backed sqlsurvey object on the local machine. running this script will do it.      #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/Censo%20Demografico/download%20and%20import.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "pes 2010 design.rda" in C:/My Directory/CENSO or wherever.  #
###############################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


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

# remove certainty units
options( survey.lonely.psu = "remove" )
# for more detail, see
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html

# after running the r script above, users should have handy a few lines
# to initiate and connect to the monet database containing all behavioral risk factor surveillance system tables
# run them now.  mine look like this:



##################################################################################
# lines of code to hold on to for all other `censo_demografico` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/CENSO/MonetDB/censo_demografico.bat"		# # note for mac and *nix users: `censo_demografico.bat` might be `censo_demografico.sh` instead

# second: run the MonetDB server
monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "censo_demografico"
dbport <- 50011

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

# fourth: store the process id
pid <- as.integer( dbGetQuery( db , "SELECT value FROM env() WHERE name = 'monet_pid'" )[[1]] )


# if you are running windows, you might see a performance improvement
# by turning off multi-threading with this command:
if (.Platform$OS.type == "windows") dbSendQuery( db , "set optimizer = 'sequential_pipe';" )
# this must be set every time you start the server.

# # # # run your analysis commands # # # #



# to turn multi-threading back on (this is the default)
# either shut down and re-start the server
# with monetdb.server.stop then monetdb.server.start
# or simply run this line:
# dbSendQuery( db , "set optimizer = 'default_pipe';" )


# the censo demografico download and importation script
# has already created a monet database-backed survey design object
# connected to the 2010 person-level table

# sqlite database-backed survey objects are described here: 
# http://r-survey.r-forge.r-project.org/survey/svy-dbi.html
# monet database-backed survey objects are similar, but:
# the database engine is, well, blazingly faster
# the setup is kinda more complicated (but all done for you)

# since this script only loads one file off of the local drive,
# there's no need to set the working directory.
# instead, simply use the full filepath to the r data file (.rda)


# uncomment this line by removing the `#` to load the person-level table..
# load( 'C:/My Directory/CENSO/pes 2010 design.rda' )
# ..and immediately connect the complex sample designs to the monet database #
pes.d <- open( pes.design , driver = MonetDB.R() , wait = TRUE )


# alternatively, open and connect to the household-level design with these two lines instead
# load( 'C:/My Directory/CENSO/dom 2010 design.rda' )
# dom.d <- open( dom.design , driver = MonetDB.R() , wait = TRUE )


################################################
# ..and immediately start the example analyses #
################################################

# count the total (unweighted) number of records in the 2010 census #

# simply use the nrow function..
nrow( pes.d )

# ..on the sqlsurvey design object
class( pes.d )


# since the the 2010 census gets loaded as a monet database-backed survey object instead of a data frame,
# the number of unweighted records cannot be calculated by running the nrow() function on a data frame.

# running the nrow() function on the database connection object
# simply produces an error..
# nrow( db )

# because the monet database might contain multiple data tables
class( db )


# instead, perform the same unweighted count directly from the sql table
# stored inside the monet database on your hard disk (as opposed to RAM)
dbGetQuery( db , "SELECT COUNT(*) AS num_records FROM c10" )

	

# count the total (unweighted) number of records in the 2010 census #
# broken out by state #

# note: this is easiest by simply running a sql query on the monet database directly
dbGetQuery( db , "SELECT v0001 , COUNT(*) as num_records FROM c10 GROUP BY v0001" )

# or, if you'd prefer results ordered by state, then say so!
dbGetQuery( db , "SELECT v0001 , COUNT(*) as num_records FROM c10 GROUP BY v0001 ORDER BY v0001" )



# count the weighted number of individuals in the 2010 census #

# the total 2010 population of brazil #
# note that this should be calculated by summing up the weight variable
# from the original database (.db) file connection
dbGetQuery( db , "SELECT SUM( pes_wgt ) AS sum_weights FROM c10" )


# the total 2010 population of brazil
# by state
dbGetQuery( db , "SELECT v0001 , SUM( pes_wgt ) AS sum_weights FROM c10 group by v0001" )


# calculate the mean of a linear variable #

# note that the age variable `v6033` contains missings
# values above 900 should be excluded from the results.


# average age - nationwide, three ways #

# using a direct sql query:
dbGetQuery( db , 'SELECT SUM( pes_wgt * v6033 ) / SUM( pes_wgt ) AS mean_age FROM c10 WHERE v6033 < 900' )

# using syntax that matches the R survey package:
svymean( ~v6033 , subset( pes.d , v6033 < 900 ) )

# including the standard error - warning: computationally intensive
# svymean( ~v6033 , subset( pes.d , v6033 < 900 ) , se = TRUE )


# average age - by state, three ways #

# using a direct sql query:
dbGetQuery( db , 'SELECT v0001 , SUM( pes_wgt * v6033 ) / SUM( pes_wgt ) AS mean_age FROM c10 WHERE v6033 < 900 GROUP BY v0001 ORDER BY v0001' )

# using syntax similar to (but not exactly the same as) the R survey pacakge
svymean( ~v6033 , subset( pes.d , v6033 < 900 ) , byvar = ~v0001 )

# including the standard error - warning: computationally intensive
# svymean( ~v6033 , subset( pes.d , v6033 < 900 ) , byvar = ~v0001 , se = TRUE )



# calculate the distribution of a categorical variable #

# v0640 has been converted to a factor (categorical) variable in the pes.d object
# because , even though it contains the values 1 through 5,
# it was included in the check.factors= argument of the function sqlsurvey()

# marital status distribution - nationwide
svymean( ~v0640 , pes.d )

# including the standard error - warning: computationally intensive
# svymean( ~v0640 , pes.d , se = TRUE )

# marital status distribution - by state
svymean( ~v0640 , pes.d , byvar = ~v0001 )

# including the standard error - warning: computationally intensive
# svymean( ~v0640 , pes.d , byvar = ~v0001 , se = TRUE )


# calculate the median and other percentiles #

# median age of all brazilians
svyquantile( ~v6033 , subset( pes.d , v6033 < 900 ) , quantiles = 0.5 )
# note: quantile standard errors cannot be computed with taylor-series linearization designs
# this is true in both the survey and sqlsurvey packages

# note two additional differences between the sqlsurvey and survey packages..

# ..sqlsurvey designs do not allow multiple quantiles.  instead, 
# loop through and print or save multiple quantiles, simply use a for loop

# loop through the median and 99th percentiles and print both results to the screen
for ( i in c( .5 , .99 ) ) print( svyquantile( ~v6033 , subset( pes.d , v6033 < 900 ) , quantiles = i ) )



# ..sqlsurvey designs do not allow byvar arguments, meaning the only way to 
# calculate quantiles by state would be by creating subsets for each subpopulation
# and calculating the quantiles for them independently:

######################
# subsetting example #
######################

# restrict the pes.d object to females only
pes.d.female <- subset( pes.d , v0601 == 2 )

# now any of the above commands can be re-run
# using the pes.d.female object
# instead of the pes.d object
# in order to analyze females only
	
# calculate the distribution of a categorical variable #

# marital status distribution - nationwide, restricted to females
svymean( ~v0640 , pes.d.female )

# including the standard error - warning: computationally intensive
# svymean( ~v0640 , pes.d.female , se = TRUE )


###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# broken out by urban / rural status

# store the results into a new object

marital.status.by.urbanrural <- svymean( ~v0640 , pes.d , byvar = ~v1006 )

# including the standard error - warning: computationally intensive
# marital.status.by.urbanrural <- svymean( ~v0640 , pes.d , byvar = ~v1006 , se = TRUE )


# print the results to the screen 
marital.status.by.urbanrural

# now you have the results saved into a new data.frame..
class( marital.status.by.urbanrural )

# ..and then immediately exported as a comma-separated value file 
# into your current working directory 
write.csv( marital.status.by.urbanrural , "marital status by urbanrural.csv" )

# ..or trimmed to only contain the values you need.
# here's the percent married broken out by urban/rural status,
married.by.urbanrural <-
	data.frame( marital.status.by.urbanrural )[ 1:2 , 1 ]


# print the new results to the screen
married.by.urbanrural

# this can also be exported as a comma-separated value file 
# into your current working directory 
write.csv( married.by.urbanrural , "percent married by urbanrural.csv" )

# ..or directly made into a bar plot
barplot(
	married.by.urbanrural ,
	main = "Percent Married" ,
	names.arg = c( "Urban" , "Rural" ) ,
	ylim = c( 0 , .40 )
)


############################
# end of analysis examples #
############################


# close the connection to the sqlrepsurvey design object
close( pes.d )

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other `censo_demografico` monetdb analyses #
#########################################################################################


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
