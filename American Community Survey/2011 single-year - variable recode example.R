# analyze survey data for free (http://asdfree.com) with the r language
# american community survey
# 2011 person and household files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( "monetdb.sequential" = TRUE )
# library(downloader)
# batfile <- "C:/My Directory/ACS/MonetDB/acs.bat"		# # note for mac and *nix users: `acs.bat` might be `acs.sh` instead
# load( 'C:/My Directory/ACS/acs2011_1yr.rda' )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/American%20Community%20Survey/2011%20single-year%20-%20variable%20recode%20example.R" , prompt = FALSE , echo = TRUE )
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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################################
# prior to running this analysis script, the acs 2011 single-year file must be loaded as a monet database-backed sqlsurvey object   #
# on the local machine. running the 2005-2011 download and create database script will create a monet database containing this file #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/usgsd/blob/master/American%20Community%20Survey/download%20all%20microdata.R                          #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "acs2011_1yr.rda" in C:/My Directory/ACS or wherever the working directory was set for the program #
#####################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # #
# warning: monetdb required #
# # # # # # # # # # # # # # #


# windows machines and also machines without access
# to large amounts of ram will often benefit from
# the following option, available as of MonetDB.R 0.9.2 --
# remove the `#` in the line below to turn this option on.
# options( "monetdb.sequential" = TRUE )
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
# to initiate and connect to the monet database containing all american community survey tables
# run them now.  mine look like this:


####################################################################
# lines of code to hold on to for all other `acs` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/ACS/MonetDB/acs.bat"		# # note for mac and *nix users: `acs.bat` might be `acs.sh` instead

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "acs"
dbport <- 50001

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )


# # # # run your analysis commands # # # #


# the american community survey download and importation script
# has already created a monet database-backed survey design object
# connected to the 2011 single-year table

# however, making any changes to the data table downloaded directly from the census bureau
# currently requires directly accessing the table using dbSendQuery() to run sql commands


# note: recoding (writing) variables in monetdb often takes much longer
# than querying (reading) variables in monetdb.  therefore, it might be wise to
# run all recodes at once, and leave your computer running overnight.


# variable recodes on monet database-backed survey objects might be
# more complicated than you'd expect, but it's far from impossible
# three steps:



##############################################################
# step 1: connect to the acs data table you'd like to recode # 
# then make a copy so you don't lose the pristine original.  #

# the command above
# db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )
# has already connected the current instance of r to the monet database

# now simply copy you'd like to recode into a new table
dbSendQuery( db , "CREATE TABLE recoded_acs2011_1yr_m AS SELECT * FROM acs2011_1yr_m WITH DATA" )
# this action protects the original 'acs2011_1yr_m' table from any accidental errors.
# at any point, we can delete this recoded copy of the data table using the command..
# dbRemoveTable( db , "recoded_acs2011_1yr_m" )
# ..and start fresh by re-copying the pristine file from acs2011_1yr_m



############################################
# step 2: make all of your recodes at once #

# from this point forward, all commands will only touch the
# 'recoded_acs2011_1yr_m' table.  the 'acs2011_1yr_m' is now off-limits.

# add a new column.  call it, oh i don't know, agecat?
# since it's actually a categorical variable, make it VARCHAR( 255 )
dbSendQuery( db , "ALTER TABLE recoded_acs2011_1yr_m ADD COLUMN agecat VARCHAR( 255 )" )

# if you wanted to create a numeric variable, substitute VARCHAR( 255 ) with DOUBLE PRECISION like this:
# dbSendQuery( db , "ALTER TABLE recoded_acs2011_1yr_m ADD COLUMN agecatx DOUBLE PRECISION" )
# ..but then agecat would have to be be numbers (1 - 13) instead of the strings shown below ('01' - '13')


# by hand, you could set the values of the agecat column anywhere between '01' and '13'
dbSendQuery( db , "UPDATE recoded_acs2011_1yr_m SET agecat = '01' WHERE agep >= 0 AND agep < 5" )
dbSendQuery( db , "UPDATE recoded_acs2011_1yr_m SET agecat = '02' WHERE agep >= 5 AND agep < 10" )
dbSendQuery( db , "UPDATE recoded_acs2011_1yr_m SET agecat = '03' WHERE agep >= 10 AND agep < 15" )
dbSendQuery( db , "UPDATE recoded_acs2011_1yr_m SET agecat = '04' WHERE agep >= 15 AND agep < 20" )
dbSendQuery( db , "UPDATE recoded_acs2011_1yr_m SET agecat = '05' WHERE agep >= 20 AND agep < 25" )
dbSendQuery( db , "UPDATE recoded_acs2011_1yr_m SET agecat = '06' WHERE agep >= 25 AND agep < 35" )
dbSendQuery( db , "UPDATE recoded_acs2011_1yr_m SET agecat = '07' WHERE agep >= 35 AND agep < 45" )
dbSendQuery( db , "UPDATE recoded_acs2011_1yr_m SET agecat = '08' WHERE agep >= 45 AND agep < 55" )
dbSendQuery( db , "UPDATE recoded_acs2011_1yr_m SET agecat = '09' WHERE agep >= 55 AND agep < 60" )
dbSendQuery( db , "UPDATE recoded_acs2011_1yr_m SET agecat = '10' WHERE agep >= 60 AND agep < 65" )
dbSendQuery( db , "UPDATE recoded_acs2011_1yr_m SET agecat = '11' WHERE agep >= 65 AND agep < 75" )
dbSendQuery( db , "UPDATE recoded_acs2011_1yr_m SET agecat = '12' WHERE agep >= 75 AND agep < 85" )
dbSendQuery( db , "UPDATE recoded_acs2011_1yr_m SET agecat = '13' WHERE agep >= 85 AND agep < 101" )


# quickly check your work by running a simple SELECT COUNT(*) command with sql
dbGetQuery( db , "SELECT agecat , agep , COUNT(*) as number_of_records from recoded_acs2011_1yr_m GROUP BY agecat , agep ORDER BY agep" )
# and notice that each value of agep has been deposited in the appropriate age category


# but all of that takes a while to write out.


# since there's so much repeated text in the commands above, 
# let's create the same agecat variable (agecat2 this time)
# with code you'll be able to modify a lot faster

# remember, since it's actually a categorical variable, make the column type VARCHAR( 255 )
dbSendQuery( db , "ALTER TABLE recoded_acs2011_1yr_m ADD COLUMN agecat2 VARCHAR( 255 )" )


# to automate things, just create a vector of each age bound
agebounds <- c( 0 , 5 , 10 , 15 , 20 , 25 , 35 , 45 , 55 , 60 , 65 , 75 , 85 , 101 )
# and loop through each interval, plugging in a new agecat for each value

# start at the value '0' and end at the value '85' -- as opposed to the ceiling of 101.
for ( i in 1:( length( agebounds ) - 1 ) ){

	# build the sql string to pass to monetdb
	update.sql.string <- paste0( "UPDATE recoded_acs2011_1yr_m SET agecat2 = '" , str_pad( i , 2 , pad = '0' ) , "' WHERE agep >= " , agebounds[ i ] , " AND agep < " , agebounds[ i + 1 ] )
		
	# take a look at the update.sql.string you've just built.  familiar?  ;)
	print( update.sql.string )
	
	# now actually run the sql string
	dbSendQuery( db , update.sql.string )
}


# check your work by running a simple SELECT COUNT(*) command with sql
dbGetQuery( db , "SELECT agecat , agecat2 , COUNT(*) as number_of_records from recoded_acs2011_1yr_m GROUP BY agecat , agecat2 ORDER BY agecat" )
# and notice that there aren't any records where agecat does not equal agecat2



#############################################################################
# step 3: create a new survey design object connecting to the recoded table #

# to initiate a new complex sample survey design on the data table
# that's been recoded to include 'agecat"
# simply re-run the sqlrepsurvey() function and update the table.name =
# argument so it now points to the recoded_ table in the monet database
# and includes the character vector designating all character/factor (non-numeric) columns

# extract the character/factor variables from the previous design #

# load the desired american community survey monet database-backed complex sample design objects

# uncomment this line by removing the `#` at the front..
# load( 'C:/My Directory/ACS/acs2011_1yr.rda' )	# analyze the 2011 single-year acs

# figure out which columns in the metadata are not numeric or integer
factor.variables.in.acs.m <- 
	names( acs.m.design$zdata )[ !( sapply( acs.m.design$zdata , class ) %in% c( 'numeric' , 'integer' ) ) ]

# toss in your two age category variables,
# which should also be treated as character variables instead of numeric
factor.variables.in.acs.m <-
	c( factor.variables.in.acs.m , 'agecat' , 'agecat2' )

# end of extraction of character/factor variables #
	
# create a sqlrepsurvey complex sample design object
# using the *recoded* merged (household+person) table

acs.m.recoded.design <-
	sqlrepsurvey(
		weight = 'pwgtp' ,
		repweights = paste0( 'pwgtp' , 1:80 ) ,
		scale = 4 / 80 ,
		rscales = rep( 1 , 80 ) ,
		mse = TRUE ,
		table.name = "recoded_acs2011_1yr_m" ,		# note the solitary change here
		key = "idkey" ,
		
		# note that this line specifies the new character/factor variables in the monetdb table:
		check.factors = factor.variables.in.acs.m ,
		
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
# save( acs.m.recoded.design , file = "C:/My Directory/ACS/recoded_acs2011_1yr.rda" )


# # # # # # # # # # # # # # # # #
# you've completed your recodes #
# # # # # # # # # # # # # # # # #

# everything's peaches and cream from here on in.

# to analyze your newly-recoded year of data:

# close r

# open r back up

library(sqlsurvey)		# load sqlsurvey package (analyzes large complex design surveys)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)

# run your..
# lines of code to hold on to for all other acs monetdb analyses #
# (the same block of code i told you to hold onto at the end of the download script)

# load your new the survey object

# uncomment this line by removing the `#` at the front..
# load( "C:/My Directory/ACS/recoded_acs2011_1yr.rda" )


# connect the recoded complex sample design to the monet database #
acs.r <- open( acs.m.recoded.design , driver = MonetDB.R() , wait = TRUE )	# recoded

# ..and now you can exactly match the age categories provided by the census bureau at..
# http://www.census.gov/acs/www/Downloads/data_documentation/pums/Estimates/pums_estimates_11.lst #
# with one measly command:

svytotal( ~one , acs.r , byvar = ~agecat )


# are we done here?  yep, we're done.

# close the connection to the recoded sqlrepsurvey design object
close( acs.r )


# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other `acs` monetdb analyses #
###########################################################################


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
