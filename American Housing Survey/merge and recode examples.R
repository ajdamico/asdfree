# analyze survey data for free (http://asdfree.com) with the r language
# american housing survey
# 2009

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/AHS/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/American%20Housing%20Survey/merge%20and%20recode%20examples.R" , prompt = FALSE , echo = TRUE )
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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#########################################################################################################
# prior to running this analysis script, the ahs 2009 file must be loaded as an r data file (.rda) and  #
# in a database (.db) on the local machine. running the download all microdata script will create both. #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/usgsd/master/American%20Housing%20Survey/download%20all%20microdata.R #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "ahs.db" and './2009/national/tnewhouse_trepwgt.rda' in your getwd()   #
#########################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/AHS/" )
# ..in order to set your current working directory

# name the database (.db) file that should have been saved in the working directory
ahs.dbname <- "ahs.db"


# remove the # in order to run this install.packages line only once
# install.packages( c( "survey" , "sqldf" ) )


library(downloader)	# downloads and then runs the source() function on scripts from github
library(survey)		# load survey package (analyzes complex design surveys)
library(RSQLite) 	# load RSQLite package (creates database files in R)
library(sqldf)		# load the sqldf package (enables sql queries on data frames)


# R will exactly match SUDAAN results and Stata with the MSE option results
options( survey.replicates.mse = TRUE )
# otherwise if it is commented out or set to FALSE


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# note regarding merging and recoding: recodes in an individual american housing survey file  #
# can happen on any individual table at any time, so long as you complete all recodes before  #
# constructing the survey design object (in other words, before running the function called   #
# `svrepdesign` -- however merges require much more care.  the census bureau creates a        #
# "flat file" containing one-record-per-housing-unit (think of that like a consolidated file) #
# however rather than replicating that one-size-fits-all consolidated file creation, you'll   #
# have to reshape and merge on the columns you need by yourself.  consider the `tnewhouse`    #
# file your "starting point" and merge other information (usually by the `control` column) on #
# to that file.  but be careful when you do!  the other files contain multiple records per    #
# household or zero records per household (or both), so be sure to use LEFT JOIN if you're    #
# using SQL or all.x = TRUE if you're using r's merge function.  if you're new to merges,     #
# watch http://www.screenr.com/Znd8.  oh yeah one more thing: why is `tnewhouse` the main     #
# analytic file?  because it's the only file that contains the generalizable survey weights!  #
# you *cannot* use the american housing survey to make estimates of the us population.  your  #
# results generalize to the us housing supply (both inhabited and uninhabited).  the whole    #
# point of survey research is to _generalize_ about some broader population, so if you don't  #
# have weights that are representative of the thing you're trying to talk about, you're sol.  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# note regarding sql commands and alternatives: the recodes below use basic commands from sql #
# this is necessary for computers with limited resources, since none of the data requires ram #
# but if you've got a more powerful computer and feel more at-ease with r than with sql code  #
# you can stick with the second set of examples (non-database-backed). just be mindful of ram #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # #
# # # volume  one # # #
# # # # # # # # # # # #


###########################################################################
# how to edit, merge, and create a survey design inside a sqlite database #
###########################################################################

# this version is more complicated but requires a less powerful computer.

##############################################################
# step 1: connect to the ahs data table you'd like to recode # 
# then make a copy so you don't lose the pristine original.  #

# the command 
db <- dbConnect( SQLite() , ahs.dbname )
# connects the current instance of r to the sqlite database

# now simply copy you'd like to recode into a new table
dbSendQuery( db , "CREATE TABLE recoded_tperson_2011_nationalandmetropolitanv14 AS SELECT * FROM tperson_2011_nationalandmetropolitanv14" )
# this action protects the original 'tperson_2011_nationalandmetropolitanv14' table from any accidental errors.
# at any point, we can delete this recoded copy of the data table using the command..
# dbRemoveTable( db , "recoded_tperson_2011_nationalandmetropolitanv14" )
# ..and start fresh by re-copying the pristine file from tperson_2011_nationalandmetropolitanv14



############################################
# step 2: make all of your recodes at once #

# from this point forward, all commands will only touch the
# 'recoded_tperson_2011_nationalandmetropolitanv14' table.  the 'tperson_2011_nationalandmetropolitanv14' is now off-limits.

# add a new column.  call it, oh i don't know, adult?
# since it's actually a categorical variable, make it VARCHAR( 255 )
dbSendQuery( db , "ALTER TABLE recoded_tperson_2011_nationalandmetropolitanv14 ADD COLUMN adult VARCHAR( 255 )" )

# if you wanted to create a numeric variable, substitute VARCHAR( 255 ) with DOUBLE PRECISION like this:
# dbSendQuery( db , "ALTER TABLE recoded_tperson_2011_nationalandmetropolitanv14 ADD COLUMN adultx DOUBLE PRECISION" )
# ..but then use `SET adult = 1` and `SET adult = 0` instead of 'yes' and 'no' as shown below

# by hand, you could set the values of the adult column
dbSendQuery( db , "UPDATE recoded_tperson_2011_nationalandmetropolitanv14 SET adult = 'yes' WHERE age >= 18" )
dbSendQuery( db , "UPDATE recoded_tperson_2011_nationalandmetropolitanv14 SET adult = 'no' WHERE age < 18" )


# quickly check your work by running a simple SELECT COUNT(*) command with sql
dbGetQuery( db , "SELECT adult , age , COUNT(*) as number_of_records from recoded_tperson_2011_nationalandmetropolitanv14 GROUP BY adult , age ORDER BY age" )
# and notice that each value of age has been deposited in the appropriate age category



################################################################################################
# step 3: create a one-record-per-`control` table to be merged onto tnewhouse_trepwgt_2011_v14 #

# if you are unclear on why this is critical, re-read "note regarding merging and recoding" above

# create a new table in the database called `aggregated_tperson`
# with five columns:
	# unique household identifier
	# number of persons in the house
	# percent of persons in the house who are adults
	# number of adults in the household
	# sum of household salaries, with negatives bumped up to zeroes
dbSendQuery( 
	db , 
	"CREATE TABLE aggregated_tperson AS
	SELECT 
		control , 
		count(*) as num_persons , 
		avg( adult = 'yes' ) as pct_adults , 
		sum( age >= 18 ) as num_adults ,
		sum( CASE WHEN sal < 0 THEN 0 ELSE sal END ) as total_household_salaries
	FROM recoded_tperson_2011_nationalandmetropolitanv14
	GROUP BY control"
)

# at this point, you're finished with the `recoded_tperson_2011_nationalandmetropolitanv14` table,
# so it can be stricken from the record if you like.
dbRemoveTable( db , 'recoded_tperson_2011_nationalandmetropolitanv14' )

# sidenote: this newly-aggregated table on its own is pretty small
# you can probably read it into ram by itself and have a look
x <- dbReadTable( db , 'aggregated_tperson' )

# check out the first..
head( x )
# ..and last six records
tail( x )


# but this table has fewer records than the table you'll be merging it onto.
dbGetQuery( db , 'SELECT count(*) FROM aggregated_tperson' )
dbGetQuery( db , 'SELECT count(*) FROM tnewhouse_trepwgt_2011_v14' )
# that's because not every household has people in it!		


#######################################
# step 4: left join that little puppy #

# time for a left join.  are you ready for a left join?
dbSendQuery( 
	db , 
	"CREATE TABLE merged_2011 AS 
	SELECT * 
	FROM tnewhouse_trepwgt_2011_v14 AS a 
	LEFT JOIN aggregated_tperson AS b
	ON a.control = b.control"
)
# not so bad.
# keep all records in the lefthand table
# regardless of a match in the righthand table.

# so now when you look at the record counts..
dbGetQuery( db , 'SELECT count(*) FROM aggregated_tperson' )
dbGetQuery( db , 'SELECT count(*) FROM tnewhouse_trepwgt_2011_v14' )
dbGetQuery( db , 'SELECT count(*) FROM merged_2011' )
# the `merged_2011` table should match the `tnewhouse_trepwgt_2011_v14` table.

# remember to clean up your toys.
# here's how to erase the `aggregated_tperson` table
dbRemoveTable( db , 'aggregated_tperson' )

# oh!  and i think you want to recode a few more things in your newly-created table.
# if there were no persons in the household,
# the left join will have made the `num_persons` and `num_adults` fields missing.
# those should probably switch to zeroes, don't you think?
dbSendQuery( db , "UPDATE merged_2011 SET num_adults = 0 WHERE num_adults IS NULL" )
dbSendQuery( db , "UPDATE merged_2011 SET num_persons = 0 WHERE num_persons IS NULL" )
# on the other hand, `pct_adults` and `total_household_salaries` should stay missing.
# at least, that's what i would do.


#############################################################################
# step 5: create a new survey design object connecting to the recoded table #

# to initiate a new complex sample survey design on the data table
# simply re-run the svrepdesign() syntax with an updated `data = ` parameter
# pointing toward the new merged table in the sqlite database

##############################################
# survey design for a database-backed object #
ahs.merged.svydb <-
	svrepdesign(
		weights = ~repwgt0,
		repweights = "repwgt[1-9]" ,
		type = "Fay" ,
		rho = ( 1 - 1 / sqrt( 4 ) ) ,
		data = "merged_2011" ,			# note that this is the only change from other db-backed designs
		dbtype = "SQLite" ,
		dbname = ahs.dbname
	)

	
############################################
# step 6: enjoy playing with your new toys #

# mean number of persons in all american households, weighted by households.
svymean( ~ num_persons , ahs.merged.svydb )

# mean number of adults in all american households, weighted by households.
svymean( ~ num_adults , ahs.merged.svydb )

# household-weighted percent of household residents who are adults.
svymean( ~ pct_adults , ahs.merged.svydb )
# but whoops!  that breaks, because some households are missings.
# re-run the same command, but throw out the missings
svymean( ~ pct_adults , ahs.merged.svydb , na.rm = TRUE )


# average household-weighted sum of salaries, broken out by number of adults in the household.
svyby( ~ total_household_salaries , ~ num_adults , ahs.merged.svydb , svymean , na.rm = TRUE , na.rm.all = TRUE )


# done?  done.  time to clean up.

# close the database connection of the replicate-weighted survey design object
close( ahs.merged.svydb )

# remove the survey design from memory
rm( ahs.merged.svydb )

# clear up ram
gc()

# remove the `merged_2011` table from the ahs database
dbRemoveTable( db , 'merged_2011' )

# disconnect from the sqlite database
dbDisconnect( db )


# # # conclusion of volume  one # # #

# # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # #
# # # volume  two # # #
# # # # # # # # # # # #

####################################################################################
# how to edit, merge, and create a survey design by loading everything into memory #
####################################################################################

# this version is less complicated but requires a more powerful computer.

##############################################
# step 1: load the files you wanna work with # 

# pull the `tperson` table into memory
load( "./2011/national_and_metropolitan_v1.4/tperson.rda" )

# pull the merged `tnewhouse_trepwgt` table into memory
load( "./2011/national_and_metropolitan_v1.4/tnewhouse_trepwgt.rda" )


############################################
# step 2: make all of your recodes at once #


# add a new column.  call it, oh i don't know, adult?
tperson$adult <- ifelse( tperson$age >= 18 , "yes" , "no" )

# quickly check your work by running a simple table command
table( tperson[ , c( 'age' , 'adult' ) ] , useNA = 'always' )
# and notice that each value of age has been deposited in the appropriate age category



#######################################################################################
# step 3: create a one-record-per-`control` table to be merged onto tnewhouse_trepwgt #

# if you are unclear on why this is critical, re-read "note regarding merging and recoding" above
aggregated.tperson <-
	sqldf( 
		"SELECT 
			control , 
			count(*) as num_persons , 
			avg( adult = 'yes' ) as pct_adults , 
			sum( age >= 18 ) as num_adults ,
			sum( CASE WHEN sal < 0 THEN 0 ELSE sal END ) as total_household_salaries
		FROM tperson
		GROUP BY control"
	)
# note that there are lots of ways to create a one-record-per-`control` aggregated table.
# google around for keywords like aggregate, cast, reshape, melt
# if you'd rather stick with the r language instead of sql GROUP BY statements.

	
# at this point, you're finished with the `tperson` table,
# so it can be stricken from the record if you like.
rm( tperson )

# clear up ram
gc()

# check out the first..
head( aggregated.tperson )
# ..and last six records
tail( aggregated.tperson )


# but this table has fewer records than the table you'll be merging it onto.
nrow( aggregated.tperson )
nrow( tnewhouse_trepwgt )
# that's because not every household has people in it!		


###################################
# step 4: merge that little puppy #

# keep all records in the lefthand table, regardless of a match.
x <- merge( tnewhouse_trepwgt , aggregated.tperson , all.x = TRUE )
# the merge-column `control` did not need to be specified
# because it was the only intersecting column name.

# here are the column names of tnewhouse_trepwgt
names( tnewhouse_trepwgt )

# here are the column names of aggregated.tperson
names( aggregated.tperson )

# here are where those two character vectors intersect
intersect( names( tnewhouse_trepwgt ) , names( aggregated.tperson ) )
# see?  and it's the default `merge` field -- as seen if you type `?merge`

# so now when you look at the record counts..
nrow( aggregated.tperson )
nrow( tnewhouse_trepwgt )
nrow( x )
# the `x` table should match the `tnewhouse_trepwgt` table.

# remember to clean up your toys.
# here's how to erase both of the pre-merged tables
rm( aggregated.tperson , tnewhouse_trepwgt )

# clear up ram
gc()

# oh!  and i think you want to recode a few more things in your newly-created table.
# if there were no persons in the household,
# the left join will have made the `num_persons` and `num_adults` fields missing.
# those should probably switch to zeroes, don't you think?
x[ is.na( x$num_adults ) , 'num_adults' ] <- 0
x[ is.na( x$num_persons ) , 'num_persons' ] <- 0
# on the other hand, `pct_adults` and `total_household_salaries` should stay missing.
# at least, that's what i would do.


#############################################################################
# step 5: create a new survey design object connecting to the recoded table #

# to initiate a new complex sample survey design on the data table
# simply re-run the svrepdesign() syntax with an updated `data = ` parameter
# pointing toward the new merged table

#########################################
# survey design for an in-memory object #
ahs.merged.svynodb <-
	svrepdesign(
		weights = ~repwgt0,
		repweights = "repwgt[1-9]" ,
		type = "Fay" ,
		rho = ( 1 - 1 / sqrt( 4 ) ) ,
		data = x						# note that this is the only change from other non-db-backed designs
	)

# now that the survey design has been created, you no longer need `x` either
rm( x )

# clear up ram
gc()
	
############################################
# step 6: enjoy playing with your new toys #

# mean number of persons in all american households, weighted by households.
svymean( ~ num_persons , ahs.merged.svynodb )

# mean number of adults in all american households, weighted by households.
svymean( ~ num_adults , ahs.merged.svynodb )

# household-weighted percent of household residents who are adults.
svymean( ~ pct_adults , ahs.merged.svynodb )
# but whoops!  that breaks, because some households are missings.
# re-run the same command, but throw out the missings
svymean( ~ pct_adults , ahs.merged.svynodb , na.rm = TRUE )


# average household-weighted sum of salaries, broken out by number of adults in the household.
svyby( ~ total_household_salaries , ~ num_adults , ahs.merged.svynodb , svymean , na.rm = TRUE , na.rm.all = TRUE )


# done?  done.  time to clean up.

# remove the survey design from memory
rm( ahs.merged.svynodb )

# clear up ram
gc()


# # # conclusion of volume  two # # #


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
