# analyze survey data for free (http://asdfree.com) with the r language
# censo demografico
# 2010 gerais da amostra (general sample)
# household + person-level merged files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/CENSO/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Censo%20Demografico/analysis%20examples.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# djalma pessoa
# pessoad@gmail.com

# anthony joseph damico
# ajdamico@gmail.com


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###########################################################################################################
# prior to running this analysis script, the 2010 censo demografico must be loaded as a monet             #
# database-backed sqlsurvey object on the local machine. running this script will do it.                  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/Censo%20Demografico/download%20and%20import.R #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "pes 2010 design.rda" in C:/My Directory/CENSO or wherever.              #
###########################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/CENSO/" )


library(survey) 		# load survey package (analyzes complex design surveys)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(MonetDBLite)	# load MonetDBLite package (creates database files in R)


# remove certainty units
options( survey.lonely.psu = "remove" )
# for more detail, see
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html

# after running the r script above, users should have handy a few lines
# to initiate and connect to the monet database.  run them now.  mine look like this:

# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )

# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite() , dbfolder )



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
load( 'pes 2010 design.rda' )
# ..and immediately connect the complex sample designs to the monet database #
pes.d <- open( pes.design , driver = MonetDB.R() )


# alternatively, open and connect to the household-level design with these two lines instead
# load( 'dom 2010 design.rda' )
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


# average age - by state, three ways #

# using a direct sql query:
dbGetQuery( db , 'SELECT v0001 , SUM( pes_wgt * v6033 ) / SUM( pes_wgt ) AS mean_age FROM c10 WHERE v6033 < 900 GROUP BY v0001 ORDER BY v0001' )

# using syntax similar to (but not exactly the same as) the R survey pacakge
svyby( ~v6033 , ~v0001 , subset( pes.d , v6033 < 900 ) , svymean )


# calculate the distribution of a categorical variable #

# v0640 has been converted to a factor (categorical) variable in the pes.d object
# because , even though it contains the values 1 through 5,
# it was included in the check.factors= argument of the function sqlsurvey()

# marital status distribution - nationwide
svymean( ~v0640 , pes.d )

# marital status distribution - by state
svyby( ~v0640 , ~v0001 , pes.d , svymean )


# calculate the median and other percentiles #

# median age of all brazilians
svyquantile( ~v6033 , subset( pes.d , v6033 < 900 ) , c( 0.5 , 0.99 ) )
# note: quantile standard errors cannot be computed with taylor-series linearization designs


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


###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# broken out by urban / rural status

# store the results into a new object

marital.status.by.urbanrural <- svyby( ~v0640 , ~v1006 , pes.d , svymean )


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

