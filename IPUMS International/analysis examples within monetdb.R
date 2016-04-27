# analyze survey data for free (http://asdfree.com) with the r language
# integrated public use microdata series - international

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


# this is a guide, it is not a one-size-fits-all set of commands:
# edit this code heavily for your own analysis, otherwise you are doing something wrong.


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#################################################################################################################################
# prior to running this analysis script, an ipums-international monetdb-backed survey design must be saved as an .rda file      #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/IPUMS%20International/download%20import%20design%20into%20monetdb.R #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that guide shows how to construct a "survey design in monetdb.rda" that can then be analyzed using syntax below.              #
#################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/IPUMSI/" )
# ..in order to set your current working directory


library(survey) 		# load survey package (analyzes complex design surveys)
library(DBI)			# load the DBI package (implements the R-database coding)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(MonetDBLite)	# load MonetDBLite package (creates database files in R)


# after running the r script above, users should have handy a few lines
# to initiate and connect to the monet database containing all ipums international tables
# run them now.  mine look like this:


# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )

# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite() , dbfolder )



# do you know what tablename was used?  the tablename is one of the tables
# stored in the current monetdb server, which you can easily view with
dbListTables( db )
# the previous download/import/design guide defaults the tablename to
# the ipumsi-international [[projectname]]_[[extractnumber]]

# once you identify which tablename, create a character string with it.
# tablename <- 'yourtable'
# uncomment the line above and edit `yourtable` with something real.


# # # # run your analysis commands # # # #


# the ipums international download and importation script
# has already created a monet database-backed survey design object


# load the desired ipums international monet database-backed complex sample design objects
load( 'survey design in monetdb.rda' )

# connect the complex sample designs to the monet database #
this_db_d <- open( this_db_design , driver = MonetDB.R() )	# single-year design



# at this point, you have a taylor series linearized,
# complex sample survey design object
this_db_d

	
##################
# recode example #
##################
	
this_db_d <- update( this_db_d , age_categories = factor( 1 + findInterval( age , c( 10 , 19 , 35 , 65 ) ) ) )

svymean( ~ age_categories , this_db_d )

	
#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in this extract #

# simply use the nrow function..
nrow( this_db_d )

# ..on the survey design object
class( this_db_d )


# since the current ipums-international extract gets loaded as a monet database-backed survey object instead of a data frame,
# the number of unweighted records cannot be calculated by running the nrow() function on a data frame.

# running the nrow() function on the database connection object
# simply produces an error..
# nrow( db )

# because the monet database might contain multiple data tables
class( db )


# instead, perform the same unweighted count directly from the sql table
# stored inside the monet database on your hard disk (as opposed to RAM)
dbGetQuery( db , paste( "SELECT COUNT(*) AS num_records FROM" , tablename ) )
# note that these unweighted statistics should sum to the counts on
# https://international.ipums.org/international/samples.shtml


# count the total (unweighted) number of records in your extract #
# broken out by some categorical variable #

# note: this is easiest by simply running a sql query on the monet database directly
dbGetQuery( db , paste( "SELECT empstat , COUNT(*) as num_records FROM" , tablename , "GROUP BY empstat" ) )



# count the weighted number of individuals in your extract #

# the total number of individuals in the country in that year #
dbGetQuery( db , paste( "SELECT SUM( perwt ) AS sum_weights FROM" , tablename ) )
# note that these weighted statistics should sum to the counts divided by the sampling fraction on
# https://international.ipums.org/international/samples.shtml

# the total number of individuals in the country in that census year #
# by some categorical variable #
dbGetQuery( db , paste( "SELECT empstat , SUM( perwt ) AS sum_weights FROM" , tablename , "GROUP BY empstat" ) )
# note that these weighted statistics should sum to the counts divided by the sampling fraction on
# https://international.ipums.org/international/samples.shtml


# calculate the mean of a linear variable #

# average age across the country
svymean( ~ age , this_db_d )

# by employment status
svyby( ~ age , ~ empstat , this_db_d , svymean , na.rm = TRUE )


# calculate the distribution of a categorical variable #

# percent male versus female
svymean( ~ sex , this_db_d , na.rm = TRUE )

# by employment status
svyby( ~ sex , ~ empstat , this_db_d , svymean , na.rm = TRUE )


# calculate the median and other percentiles #

# median and 99th percentile of age of your extract
svyquantile( ~ age , this_db_d , c( 0.5 , 0.99 ) )
# note: quantile standard errors cannot be computed with taylor-series linearization designs


######################
# subsetting example #
######################

# restrict the this_db_d object to females only
this_db_d_female <- subset( this_db_d , sex == 2 )

# now any of the above commands can be re-run
# using the this_db_d_female object
# instead of the this_db_d object
# in order to analyze females only

# calculate the distribution of a categorical variable #

# average age - nationwide, restricted to females
svymean( ~ age , this_db_d_female )


###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by employment status

# store the results into a new object

sex_by_employment_status <- svyby( ~ sex , ~ empstat , this_db_d , svymean , na.rm = TRUE )

# print the results to the screen
sex_by_employment_status

# now you have the results saved into a new data.frame..
class( sex_by_employment_status )

# ..and then immediately exported as a comma-separated value file 
# into your current working directory 
write.csv( sex_by_employment_status , "sex by employment status.csv" )


# disconnect from the current monet database
dbDisconnect( db , shutdown = TRUE )

