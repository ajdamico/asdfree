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


# # # # run your recode commands # # # #


# the previous download and importation script
# has already created a monet database-backed survey design object
# connected to the single-year extract file

# however, making any changes to the data table downloaded directly from ipums-international
# currently requires directly accessing the table using dbSendQuery() to run sql commands


# note: recoding (writing) variables in monetdb often takes much longer
# than querying (reading) variables in monetdb.  therefore, it might be wise to
# run all recodes at once, and leave your computer running overnight.


# variable recodes on monet database-backed survey objects might be
# more complicated than you'd expect, but it's far from impossible
# three steps:



#################################################################
# step 1: connect to the ipumsi data table you'd like to recode # 
# then make a copy so you don't lose the pristine original.    ##

# the command above
# db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )
# has already connected the current instance of r to the monet database


# do you know what tablename was used?  the tablename is one of the tables
# stored in the current monetdb server, which you can easily view with
dbListTables( db )
# the previous download/import/design guide defaults the tablename to
# the ipumsi-international [[projectname]]_[[extractnumber]]

# once you identify which tablename, create a character string with it.
# tablename <- 'yourtable'
# uncomment the line above and edit `yourtable` with something real.

# now simply copy you'd like to recode into a new table
dbSendQuery( db , paste0( "CREATE TABLE recoded_" , tablename , " AS SELECT * FROM " , tablename , " WITH DATA" ) )
# this action protects the original table from any accidental errors.
# at any point, we can delete this recoded copy of the data table using the command..
# dbRemoveTable( db , paste0( "recoded_" , tablename ) )
# ..and start fresh by re-copying the pristine file from the original table in your database



############################################
# step 2: make all of your recodes at once #

# from this point forward, all commands will only touch the
# 'recoded_yourtable' table.  the 'yourtable' is now off-limits.

# add a new column.  call it, oh i don't know, age_categories
# since it's actually a categorical variable, make it VARCHAR( 255 )
dbSendQuery( db , paste0( "ALTER TABLE recoded_" , tablename , " ADD COLUMN age_categories VARCHAR( 255 )" ) )

# if you wanted to create a numeric variable, substitute VARCHAR( 255 ) with DOUBLE PRECISION like this:
# dbSendQuery( db , paste0( "ALTER TABLE recoded_" , tablename , " ADD COLUMN age_categories DOUBLE PRECISION" ) )
# ..but then age_categories would have to be be numbers (1 - 5) instead of the strings shown below ('01' - '05')


dbSendQuery( db , paste0( "UPDATE recoded_" , tablename , " SET age_categories = '01' WHERE age < 10" ) )
dbSendQuery( db , paste0( "UPDATE recoded_" , tablename , " SET age_categories = '02' WHERE age >= 10 AND age < 19" ) )
dbSendQuery( db , paste0( "UPDATE recoded_" , tablename , " SET age_categories = '03' WHERE age >= 19 AND age < 35" ) )
dbSendQuery( db , paste0( "UPDATE recoded_" , tablename , " SET age_categories = '04' WHERE age >= 35 AND age < 65" ) )
dbSendQuery( db , paste0( "UPDATE recoded_" , tablename , " SET age_categories = '05' WHERE age >= 65" ) )


# quickly check your work by running a simple SELECT COUNT(*) command with sql
dbGetQuery( db , paste0( "SELECT age_categories , age , COUNT(*) as number_of_records from recoded_" , tablename , " GROUP BY age_categories , age ORDER BY age" ) )
# and notice that each value of age has been deposited in the appropriate age category



#############################################################################
# step 3: create a new survey design object connecting to the recoded table #

# to initiate a new complex sample survey design on the data table
# that's been recoded to include 'age_categories"
# simply re-run the sqlsurvey() function and update the table.name =
# argument so it now points to the recoded_ table in the monet database

# this process runs much faster if you create a character vector containing all non-numeric columns
# otherwise, just set `check.factors = 10` within the sqlsurvey function and it take a guess at which columns
# are character strings or factor variables and which columns should be treated as numbers

# step 3a: load the pre-recoded (previous) design 

# load( 'sqlsurvey design in monetdb.rda' )
# uncomment the line above by removing the `#`

# # remember that this `rda` file contains not only `this_sqlsurvey_design` 
# # but also the `these_factors` character vector, which is really what we need.


# step 3b: add any character columns

# *if and only if* the column you added is also a character/factor, non-numeric column
# then add it to this character vector as i've done here:
recoded_factors <- c( these_factors , 'age_categories' )

# step 3c: re-create a sqlsurvey complex sample design object
# using the *recoded* table

# create a sqlsurvey complex sample design object
recoded_sqlsurvey_design <-
	sqlsurvey(
		weight = "perwt" ,									# weight variable column
		nest = TRUE ,										# whether or not psus are nested within strata
		strata = "strata" ,									# stratification variable column
		id = "serial_" ,									# household clustering column same as "serial"
		table.name = paste0( 'recoded_' , tablename ) ,		# **recoded** table name within the monet database
		key = "idkey" ,										# sql primary key column (created with the auto_increment line above)
		
		check.factors = recoded_factors ,					# character vector containing all factor columns for this extract
															# remember that the `check.factors=` parameter is optional
															# but failing to provide it will make this entire command take much longer
															# since the server needs to manually check whether or not each column has
															# at least 10 distinct levels or not.
															
		database = monet.url ,								# monet database location on localhost
		driver = MonetDB.R()
	)

# you now have a
# **recoded**
# monetdb-backed
# taylor series linearized
# complex sample survey design object
# ready for analysis.  and it's ultra-fast.


# run your first recoded sqlsurvey-based distribution of a categorical variable.
svymean( ~ age_categories , recoded_sqlsurvey_design , se = TRUE )
# voila!


# save the survey design object
# into a single r data file (.rda) that can now be
# analyzed quicker than anything else.
save( recoded_sqlsurvey_design , recoded_factors , file = 'recoded sqlsurvey design in monetdb.rda' )
# be sure to save the `recoded_factors` vector as well,
# just in case you do any recoding in the future


# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )
