# analyze survey data for free (http://asdfree.com) with the r language
# integrated public use microdata series - international

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


# this is a guide, it is not a one-size-fits-all set of commands:
# edit this code heavily for your own analysis, otherwise you are doing something wrong.


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#################################################################################################################################
# prior to running this analysis script, an ipums-international monetdb-backed survey design must be saved as an .rda file      #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/IPUMS%20International/download%20import%20design%20into%20monetdb.R #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that guide shows how to construct a "sqlsurvey design in monetdb.rda" that can then be analyzed using syntax below.           #
#################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/IPUMSI/" )
# ..in order to set your current working directory


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


# after running the r script above, users should have handy a few lines
# to initiate and connect to the monet database containing all ipums international tables
# run them now.  mine look like this:


# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/IPUMSI/MonetDB/ipumsi.bat"		# # note for mac and *nix users: `ipumsi.bat` might be `ipumsi.sh` instead

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "ipumsi"
dbport <- 50015

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )


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
load( 'sqlsurvey design in monetdb.rda' )

# connect the complex sample designs to the monet database #
this_sqlsurvey_d <- open( this_sqlsurvey_design , driver = MonetDB.R() , wait = TRUE )	# single-year design



# at this point, you have a taylor series linearized,
# complex sample survey design object
this_sqlsurvey_d

	
#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in this extract #

# simply use the nrow function..
nrow( this_sqlsurvey_d )

# ..on the sqlsurvey design object
class( this_sqlsurvey_d )


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
svymean( ~ age , this_sqlsurvey_d , se = TRUE )

# by employment status
svymean( ~ age , this_sqlsurvey_d , byvar = ~ empstat , se = TRUE , na.rm = TRUE )


# calculate the distribution of a categorical variable #

# percent male versus female
svymean( ~ sex , this_sqlsurvey_d , se = TRUE , na.rm = TRUE )

# by employment status
svymean( ~ sex , this_sqlsurvey_d , byvar = ~ empstat , se = TRUE , na.rm = TRUE )


# calculate the median and other percentiles #

# median age of your extract
svyquantile( ~ age , this_sqlsurvey_d , quantiles = 0.5 )
# note: quantile standard errors cannot be computed with taylor-series linearization designs
# this is true in both the survey and sqlsurvey packages

# note two additional differences between the sqlsurvey and survey packages..

# ..sqlsurvey designs do not allow multiple quantiles.  instead, 
# loop through and print or save multiple quantiles, simply use a for loop

# loop through the median and 99th percentiles and print both results to the screen
for ( i in c( .5 , .99 ) ) print( svyquantile( ~ age , this_sqlsurvey_d , quantiles = i ) )


# ..sqlsurvey designs do not allow byvar arguments, meaning the only way to 
# calculate quantiles by sex would be by creating subsets for each subpopulation
# and calculating the quantiles for them independently:


######################
# subsetting example #
######################

# restrict the this_sqlsurvey_d object to females only
this_sqlsurvey_d_female <- subset( this_sqlsurvey_d , sex == 2 )

# now any of the above commands can be re-run
# using the this_sqlsurvey_d_female object
# instead of the this_sqlsurvey_d object
# in order to analyze females only

# calculate the distribution of a categorical variable #

# average age - nationwide, restricted to females
svymean( ~ age , this_sqlsurvey_d_female )


###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by employment status

# store the results into a new object

sex_by_employment_status <- svymean( ~ sex , this_sqlsurvey_d , byvar = ~ empstatd , se = TRUE , na.rm = TRUE )

# print the results to the screen
sex_by_employment_status

# now you have the results saved into a new data.frame..
class( sex_by_employment_status )

# ..and then immediately exported as a comma-separated value file 
# into your current working directory 
write.csv( sex_by_employment_status , "sex by employment status.csv" )

# ..or trimmed to only contain the values you need.
# here's the "percent female" by employment status,
# with accompanying standard errors
female_employment_status <-
	sex_by_employment_status[ seq( 2 , nrow( sex_by_employment_status ) , 2 ) , 1 ]


# print the new results to the screen
female_employment_status

# this can also be exported as a comma-separated value file
# into your current working directory
write.csv( female_employment_status , "female by employment status.csv" )

# ..or directly made into a bar plot
barplot(
	female_employment_status ,
	main = "Percent Female By Employment Status" ,
	names.arg = c( "Not In Universe" , "Employed" , "Unemployed" , "Inactive" ) ,
	ylim = c( 0 , .75 )
)
# labels from
# https://international.ipums.org/international-action/variables/EMPSTAT#codes_section


# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )
