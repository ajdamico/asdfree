# analyze survey data for free (http://asdfree.com) with the r language
# behavioral risk factor surveillance system
# 2010

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( "monetdb.sequential" = TRUE )		# # only windows users need this line
# library(downloader)
# batfile <- "C:/My Directory/BRFSS/MonetDB/brfss.bat"		# # note for mac and *nix users: `brfss.bat` might be `brfss.sh` instead
# load( 'C:/My Directory/BRFSS/b2010 design.rda' )	# analyze the 2010 single-year brfss
# source_url( "https://raw.github.com/ajdamico/asdfree/master/Behavioral%20Risk%20Factor%20Surveillance%20System/2010%20single-year%20-%20variable%20recode%20example.R" , prompt = FALSE , echo = TRUE )
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
# prior to running this analysis script, the brfss 2010 single-year file must be loaded as a monet database-backed sqlsurvey object     #
# on the local machine. running the 1984-2011 download and create database script will create a monet database containing this file     #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/asdfree/blob/master/Behavioral%20Risk%20Factor%20Surveillance%20System/download%20all%20microdata.R         #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "b2010 design.rda" in C:/My Directory/BRFSS or wherever the working directory was set for the program  #
#########################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


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


# remove the # in order to run this install.packages line only once
# install.packages( "stringr" )


library(sqlsurvey)		# load sqlsurvey package (analyzes large complex design surveys)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(stringr) 		# load stringr package (manipulates character strings easily)


# after running the r script above, users should have handy a few lines
# to initiate and connect to the monet database containing all behavioral risk factor surveillance system tables
# run them now.  mine look like this:


######################################################################
# lines of code to hold on to for all other `brfss` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/BRFSS/MonetDB/brfss.bat"		# # note for mac and *nix users: `brfss.bat` might be `brfss.sh` instead

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "brfss"
dbport <- 50004

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )


# # # # run your analysis commands # # # #


# the behavioral risk factor surveillance system download and importation script
# has already created a monet database-backed survey design object
# connected to the 2010 single-year table

# however, making any changes to the data table downloaded directly from the census bureau
# currently requires directly accessing the table using dbSendQuery() to run sql commands


# note: recoding (writing) variables in monetdb often takes much longer
# than querying (reading) variables in monetdb.  therefore, it might be wise to
# run all recodes at once, and leave your computer running overnight.


# variable recodes on monet database-backed survey objects might be
# more complicated than you'd expect, but it's far from impossible
# three steps:



################################################################
# step 1: connect to the brfss data table you'd like to recode # 
# then make a copy so you don't lose the pristine original.    #

# the command above
# db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )
# has already connected the current instance of r to the monet database

# now simply copy you'd like to recode into a new table
dbSendQuery( db , "CREATE TABLE recoded_b2010 AS SELECT * FROM b2010 WITH DATA" )
# this action protects the original 'b2010' table from any accidental errors.
# at any point, we can delete this recoded copy of the data table using the command..
# dbRemoveTable( db , "recoded_b2010" )
# ..and start fresh by re-copying the pristine file from b2010



############################################
# step 2: make all of your recodes at once #

# from this point forward, all commands will only touch the
# 'recoded_b2010' table.  the 'b2010' is now off-limits.

# add a new column.  call it, oh i don't know, drinks_per_month
# since it's actually a categorical variable, make it VARCHAR( 255 )
dbSendQuery( db , "ALTER TABLE recoded_b2010 ADD COLUMN drinks_per_month VARCHAR( 255 )" )

# if you wanted to create a numeric variable, substitute VARCHAR( 255 ) with DOUBLE PRECISION like this:
# dbSendQuery( db , "ALTER TABLE recoded_b2010 ADD COLUMN drinks_per_monthx DOUBLE PRECISION" )
# ..but then drinks_per_month would have to be be numbers (1 - 5) instead of the strings shown below ('01' - '05')


# by hand, you could set the values of the drinks_per_month column anywhere between '01' and '05'
# notice that the xdrnkmo3 column contains missing values for individuals who average zero drinks per month -
# therefore, this first command will identify these individuals using the WHERE <varname> IS NULL clause


dbSendQuery( db , "UPDATE recoded_b2010 SET drinks_per_month = '01' WHERE xdrnkmo3 = 0" )
dbSendQuery( db , "UPDATE recoded_b2010 SET drinks_per_month = '02' WHERE xdrnkmo3 >= 1 AND xdrnkmo3 < 11" )
dbSendQuery( db , "UPDATE recoded_b2010 SET drinks_per_month = '03' WHERE xdrnkmo3 >= 11 AND xdrnkmo3 < 26" )
dbSendQuery( db , "UPDATE recoded_b2010 SET drinks_per_month = '04' WHERE xdrnkmo3 >= 26 AND xdrnkmo3 < 51" )
dbSendQuery( db , "UPDATE recoded_b2010 SET drinks_per_month = '05' WHERE xdrnkmo3 >= 51" )



# quickly check your work by running a simple SELECT COUNT(*) command with sql
dbGetQuery( db , "SELECT drinks_per_month , xdrnkmo3 , COUNT(*) as number_of_records from recoded_b2010 GROUP BY drinks_per_month , xdrnkmo3 ORDER BY xdrnkmo3" )
# and notice that each value of xdrnkmo3 has been deposited in the appropriate number of drinks category



#############################################################################
# step 3: create a new survey design object connecting to the recoded table #

# to initiate a new complex sample survey design on the data table
# that's been recoded to include 'drinks_per_month"
# simply re-run the sqlsurvey() function and update the table.name =
# argument so it now points to the recoded_ table in the monet database

# this process runs much faster if you create a character vector containing all non-numeric columns
# otherwise, just set `check.factors = 10` within the sqlsurvey function and it take a guess at which columns
# are character strings or factor variables and which columns should be treated as numbers

# step 3a: load the pre-recoded (previous) design 

# load( 'C:/My Directory/BRFSS/b2010 design.rda' )	# analyze the 2010 single-year brfss
# uncomment the line above by removing the `#`

# step 3b: extract the character columns
all.classes <- sapply( brfss.design$zdata , class )
factor.columns <- names( all.classes[ !( all.classes %in% c( 'integer' , 'numeric' ) ) ] )

# *if and only if* the column you added is also a character/factor, non-numeric column
# then add it to this character vector as i've done here:
factor.columns <- c( factor.columns , 'drinks_per_month' )

# step 3c: re-create a sqlsurvey complex sample design object
# using the *recoded* table

brfss.recoded.design <-
	sqlsurvey(
		weight = 'xfinalwt' ,
		nest = TRUE ,
		strata = 'xststr' ,
		id = 'xpsu' ,
		table.name = 'recoded_b2010' ,				# note: this is the solitary change
													# the weight, strata, and id variables are hard-coded in this sqlsurvey() function call,
													# but their values haven't changed from the original 1984 - 2011 download all microdata.R script
		key = "idkey" ,
		check.factors = factor.columns ,			# specify which columns are non-numeric.. or remove this parameter and sqlsurvey() will guess for you.
		database = monet.url ,
		driver = MonetDB.R()
	)



# sqlite database-backed survey objects are described here: 
# http://r-survey.r-forge.r-project.org/survey/svy-dbi.html
# monet database-backed survey objects are similar, but:
# the database engine is, well, blazingly faster
# the setup is kinda more complicated (but all done for you)



# save this new complex sample survey design
# into an r data file (.rda) that can now be
# analyzed quicker than anything else.
# unless you've set your working directory elsewhere, 
# spell out the entire filepath to the .rda file
# use forward slashes instead of backslashes

# uncomment this line by removing the `#` at the front..
# save( brfss.recoded.design , file = "C:/My Directory/BRFSS/recoded b2010 design.rda" )



# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )



# # # # # # # # # # # # # # # # #
# you've completed your recodes #
# # # # # # # # # # # # # # # # #

# everything's peaches and cream from here on in.

# to analyze your newly-recoded year of data:

# close r

# open r back up

library(sqlsurvey)		# load sqlsurvey package (analyzes large complex design surveys)
library(MonetDB.R)			# load the MonetDB.R package (connects r to a monet database)

# run your..
# lines of code to hold on to for all other brfss monetdb analyses #
# (the same block of code i told you to hold onto at the end of the download script)

# load your new the survey object

# uncomment this line by removing the `#` at the front..
# load( "C:/My Directory/BRFSS/recoded b2010 design.rda" )


######################################################################
# lines of code to hold on to for all other `brfss` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/BRFSS/MonetDB/brfss.bat"		# # note for mac and *nix users: `brfss.bat` might be `brfss.sh` instead

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your six lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "brfss"
dbport <- 50004

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )


# # # # run your analysis commands # # # #

# connect the recoded complex sample design to the monet database #
brfss.r <- open( brfss.recoded.design , driver = MonetDB.R() , wait = TRUE )	# recoded

# ..and now you can exactly match the monthly alcohol consumption categories provided by the cdc's web-enabled analysis tool at..
# https://github.com/ajdamico/asdfree/blob/master/Behavioral%20Risk%20Factor%20Surveillance%20System/WEAT%202010%20Alcohol%20Consumption%20by%20Gender%20-%20Crosstab%20Analysis%20Results.pdf?raw=true #


# replicate the row total column #

# calculate unweighted sample sizes
dbGetQuery( 
	db , 
	'select 
		drinks_per_month , count(*) as sample_size 
	from 
		recoded_b2010 
	group by 
		drinks_per_month
	order by
		drinks_per_month'
)


# run the column % and S.E. of column %
# print the column percent to the screen
( column.pct <- svymean( ~drinks_per_month , brfss.r , se = TRUE ) )

# extract the covariance matrix attribute from the svymean() output
# take only the values of the diagonal (which contain the variances of each value)
# square root them all to calculate the standard error
# save the result into the se.column.pct object and at the same time
# print the standard errors of the column percent to the screen
# ( by surrounding the assignment command with parentheses )
( se.column.pct <- sqrt( diag( attr( column.pct , 'var' ) ) ) )

# confidence interval lower bounds for column percents
column.pct - qnorm( 0.975 ) * se.column.pct 

# confidence interval upper bounds for column percents
column.pct + qnorm( 0.975 ) * se.column.pct


# run the sample size (weighted) and S.E. of weighted size rows

# run the sample size and S.E. of weighted size columns
# print the sample size (weighted) column to the screen
( sample.size <- svytotal( ~drinks_per_month , brfss.r , se = TRUE ) )


# extract the covariance matrix attribute from the svymean() output
# take only the values of the diagonal (which contain the variances of each value)
# square root them all to calculate the standard error
# save the result into the se.sample.size object and at the same time
# print the standard errors of the weighted size column to the screen
# ( by surrounding the assignment command with parentheses )
( se.sample.size <- sqrt( diag( attr( sample.size , 'var' ) ) ) )

# confidence interval lower bounds for weighted size
sample.size - qnorm( 0.975 ) * se.sample.size 

# confidence interval upper bounds for weighted size
sample.size + qnorm( 0.975 ) * se.sample.size



# replicate the male and female columns #

# calculate unweighted sample sizes
dbGetQuery( 
	db , 
	'select 
		drinks_per_month , sex , count(*) as sample_size 
	from 
		recoded_b2010 
	group by 
		drinks_per_month, sex
	order by
		drinks_per_month, sex'
)


# run the column % and S.E. of column %
# print the column percent to the screen
( column.pct <- svymean( ~drinks_per_month , brfss.r , byvar = ~sex , se = TRUE ) )

# extract the covariance matrix attribute from the svymean() output
# take only the values of the diagonal (which contain the variances of each value)
# square root them all to calculate the standard error
# save the result into the se.column.pct object and at the same time
# print the standard errors of the column percent to the screen
# ( by surrounding the assignment command with parentheses )
( se.column.pct <- sqrt( diag( attr( column.pct , 'var' ) ) ) )

# since se.column.pct is exported with a 'byvar' parameter as a simple numeric vector
class( se.column.pct )
# reshape this numeric vector into a data frame that matches the 'column.pct' object
se.column.pct <- data.frame( rbind( se.column.pct[ 1:5 ] , se.column.pct[ 6:10 ] ) )
# and don't forget to tack on the sex column
se.column.pct$sex <- c( 1 , 2 )
# now the same commands can be run as before to quickly calculate the confidence intervals


# confidence interval lower bounds for column percents
column.pct - qnorm( 0.975 ) * se.column.pct 

# confidence interval upper bounds for column percents
column.pct + qnorm( 0.975 ) * se.column.pct



# are we done here?  yep, we're done.

# close the connection to the recoded sqlsurvey design object
close( brfss.r )


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
