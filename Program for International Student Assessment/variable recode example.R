# analyze survey data for free (http://asdfree.com) with the r language
# program for international student assessment
# 2012 student questionnaire

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# batfile <- "C:/My Directory/PISA/MonetDB/pisa.bat"
# setwd( "C:/My Directory/PISA/" )
# load( '2012 int_stu12_dec03.rda' )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Program%20for%20International%20Student%20Assessment/variable%20recode%20example.R" , prompt = FALSE , echo = TRUE )
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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###########################################################################################################################################
# prior to running this analysis script, the pisa 2012 multiply-imputed tables must be loaded as a monet-backed sqlsurvey object on the   #
# local machine. running the download, import, and design script will create a monetdb-backed multiply-imputed database with whatcha need #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "https://raw.github.com/ajdamico/usgsd/master/Program%20for%20International%20Student%20Assessment/download%20import%20and%20design.R"  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "2012 int_stu12_dec03.rda" in C:/My Directory/PISA or wherever the working directory was set.            #
###########################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # #
# warning: monetdb required #
# # # # # # # # # # # # # # #


# remove the # in order to run this install.packages line only once
# install.packages( "mitools" )


library(mitools) 		# load mitools package (analyzes multiply-imputed data)
library(SAScii) 		# load the SAScii package (imports ascii data with a SAS script)
library(descr) 			# load the descr package (converts fixed-width files to delimited files)
library(downloader)		# downloads and then runs the source() function on scripts from github
library(stringr)		# load stringr package (manipulates character strings easily)
library(sqlsurvey)		# load sqlsurvey package (analyzes large complex design surveys)
library(R.utils)		# load the R.utils package (counts the number of lines in a file quickly)


# load a compilation of functions that will be useful when executing actual analysis commands with this multiply-imputed, monetdb-backed behemoth
source_url( "https://raw.github.com/ajdamico/usgsd/master/Program%20for%20International%20Student%20Assessment/sqlsurvey%20functions.R" , prompt = FALSE )

# load a couple of functions that will ease the importation process
source_url( "https://raw.github.com/ajdamico/usgsd/master/Program%20for%20International%20Student%20Assessment/download%20and%20importation%20functions.R" , prompt = FALSE )


# set your working directory on your local disk.
# to perform the recodes you want in the monetdb table,
# you will not be touching the `.rda` files that the automated-download program created
# instead, you'll create and save a whole new `.rda` file.  exciting!
# setwd( "C:/My Directory/PISA/" )


# after running the r script above, users should have handy a few lines
# to initiate and connect to the monet database containing all program for international student assessment tables
# run them now.  mine look like this:


#####################################################################
# lines of code to hold on to for all other `pisa` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/PISA/MonetDB/pisa.bat"

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "pisa"
dbport <- 50007

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )


# # # # run your analysis commands # # # #


# the program for international student assessment download and importation script
# has already created a monet database-backed survey design object
# connected to the 2012 student questionnaire tables


# however, making any changes to the data table downloaded directly from the oecd
# currently requires directly accessing the table using dbSendUpdate() to run sql commands


# note: recoding (writing) variables in monetdb often takes much longer
# than querying (reading) variables in monetdb.  therefore, it might be wise to
# run all recodes at once, and leave your computer running overnight.


# variable recodes on monet database-backed survey objects might be
# more complicated than you'd expect, but it's far from impossible
# three steps:



###############################################################
# step 1: connect to the pisa data table you'd like to recode # 
# then make a copy so you don't lose the pristine original.   #

# the command above
# db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )
# has already connected the current instance of r to the monet database

# now that you're connected, take a look at the tables stored in monetdb..
dbListTables( db )
# ..and determine which table(s) you want to recode.
# if you're recoding any of the student questionnaire tables,
# you have to recode all five at once.  (that means [tablename]_imp1 - [tablename]_imp5)


# it's reasonable to write a quick for-loop to automate any recoding.

# let's say that the five tables you want to recode are..
paste0( 'int_stu12_dec03_imp' , 1:5 )


# put those five character strings into a for loop
for ( i in 1:5 ){

	# now simply copy you'd like to recode into a new table
	dbSendUpdate( db , paste0( "CREATE TABLE recoded_int_stu12_dec03_imp" , i , " AS SELECT * FROM int_stu12_dec03_imp" , i , " WITH DATA" ) )
	# this action protects the original 'int_stu12_dec03_imp[1-5]' tables from any accidental errors.
	
	# at any point, we can delete these recoded copies of the data tables using the command..
	# for ( i in 1:5 ) dbRemoveTable( db , paste0( "recoded_int_stu12_dec03_imp" , i ) )
	# ..and start fresh by re-copying the pristine files from int_stu12_dec03_imp[1-5]
}


############################################
# step 2: make all of your recodes at once #

# from this point forward, all commands will only touch the
# 'recoded_int_stu12_dec03_imp[1-5]' tables.  the 'int_stu12_dec03_imp[1-5]' tables are now off-limits.

# let's recode the variable `st49q07` 
# according to the "compressed compendium" - http://pisa2012.acer.edu.au/downloads/M_comp_STU_DEC03.zip
# the question text is "how often do you do the following things at school and outside of school? - i program computers"

# btw, compressed compendia for other data sets are also available on the data download page
# http://pisa2012.acer.edu.au/downloads.php - or substitute YYYY with whatcha want - http://pisaYYYY.acer.edu.au/downloads.php 

# and according to the 2012 sas script - http://pisa2012.acer.edu.au/downloads/int_stu12_sas.sas
# the possible values are -

# value st49q07f	
	# 1 = "Always or almost always"
	# 2 = "Often"
	# 3 = "Sometimes"
	# 4 = "Never or rarely"
	# 7 = "N/A"
	# 8 = "Invalid"
	# 9 = "Missing"

# - but remember, 7, 8, and 9 were all set to NULL earlier in the program.
# so you've just got 1234 to deal with.

# add a new column.  call it, oh i don't know, progcat?
# since it's actually a categorical variable, make it VARCHAR( 255 )
for ( i in 1:5 ) dbSendUpdate( db , paste0( "ALTER TABLE recoded_int_stu12_dec03_imp" , i , " ADD COLUMN progcat VARCHAR( 255 )" ) )

# if you wanted to create a numeric variable, substitute VARCHAR( 255 ) with DOUBLE PRECISION like this:
# for ( i in 1:5 ) dbSendUpdate( db , paste0( "ALTER TABLE recoded_int_stu12_dec03_imp" , i , " ADD COLUMN progcat DOUBLE PRECISION" ) )
# ..but then progcat would have to be be numbers (maybe zero and one) instead of the strings shown below ('always, almost always, or often' - 'sometimes, rarely, or never')


# loop through the five tables again
for ( i in 1:5 ){

	# wherever `st49q07` is a 1 or a 2, code `progcat` as 'always, almost always, or often'
	dbSendUpdate( db , paste0( "UPDATE recoded_int_stu12_dec03_imp" , i , " SET progcat = 'always, almost always, or often' WHERE st49q07 IN ( 1 , 2 )" ) )

	# wherever `st49q07` is a 1 or a 2, code `progcat` as 'always, almost always, or often'
	dbSendUpdate( db , paste0( "UPDATE recoded_int_stu12_dec03_imp" , i , " SET progcat = 'sometimes, rarely, or never' WHERE st49q07 IN ( 3 , 4 )" ) )

}

# quickly check your work by running a simple SELECT COUNT(*) command with sql
# but only on one of the tables, no reason to check all five!
dbGetQuery( db , "SELECT progcat , st49q07 , COUNT(*) as number_of_records from recoded_int_stu12_dec03_imp1 GROUP BY progcat , st49q07 ORDER BY st49q07" )
# notice that each value of progcat has been deposited in the appropriate programming category


# disconnect from the database for a quick second.
dbDisconnect( db )


#############################################################################
# step 3: create a new survey design object connecting to the recoded table #

# to initiate a new complex sample survey design on the data table
# that's been recoded to include `progcat`, run the `reconstruct.pisa.sqlsurvey.designs` function
	
# note note note #
# the function below will automatically save its result
# as a monetdb-backed `.rda` file into your current working directory
# so make sure you set it first.  ;)


# load the file containing the designs you want to update
load( '2012 int_stu12_dec03.rda' )

# now use `mget` to take a character vector,
# look for objects with the same names,
# and smush 'em all together into a list
imp.list <- mget( paste0( 'int_stu12_dec03_imp' , 1:5 ) )

# use the table (already imported into monetdb) to spawn five different tables (one for each plausible [imputed] value)
# then _re_-construct a multiply-imputed, monetdb-backed, replicated-weighted complex-sample survey-design object-object.
reconstruct.pisa.sqlsurvey.designs(
	monet.url , 
	year = 2012 ,
	table.name = 'recoded_int_stu12_dec03' ,
	previous.list = imp.list ,
	# here's a new parameter.
	additional.factors = "progcat"
	# if you only added numeric columns, `#` comment out the line above
	# and uncomment this line:
	# additional.factors = NULL

	# the `additional.factors` parameter will accept multiple new factor and/or character columns
	# so if you added five new character columns, you would use a structure likeee...
	# additional.factors = c( 'newvar1' , 'newvar2' , 'newvar3' , 'newvar4' , 'newvar5' )
	
)


# # # # # # # # # # # # # # # # #
# you've completed your recodes #
# # # # # # # # # # # # # # # # #

# everything's peaches and cream from here on in.

# to analyze your newly-recoded data:

# close r and monetdb
monetdb.server.stop( pid )

# q()


# open r back up

library(sqlsurvey)		# load sqlsurvey package (analyzes large complex design surveys)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(downloader)		# downloads and then runs the source() function on scripts from github
library(mitools) 		# load mitools package (analyzes multiply-imputed data)


# load a compilation of functions that will be useful when executing actual analysis commands with this multiply-imputed, monetdb-backed behemoth
source_url( "https://raw.github.com/ajdamico/usgsd/master/Program%20for%20International%20Student%20Assessment/sqlsurvey%20functions.R" , prompt = FALSE )


# set your working directory on your local disk.
# setwd( "C:/My Directory/PISA/" )


# run your..
# lines of code to hold on to for all other acs monetdb analyses #
# (the same block of code i told you to hold onto at the end of the download script)

#####################################################################
# lines of code to hold on to for all other `pisa` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/PISA/MonetDB/pisa.bat"

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "pisa"
dbport <- 50007

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )


# # # # run your analysis commands # # # #


# since this script only loads one file off of the local drive,
# there's no need to set the working directory.
# instead, simply use the full filepath to the r data file (.rda)
# as shown in the load() examples below.

# load the desired program for international student assessment monet database-backed complex sample design objects

# uncomment one this line by removing the `#` at the front..
load( '2012 recoded_int_stu12_dec03.rda' )	# analyze the recoded 2012 student questionnaire


# note: this r data file should contain five sqlrepdesign objects ending with `imp1` - `imp5`
# you can check 'em out by running the `ls()` function to see what's available in working memory.
ls()
# see them?
# they should be named something like this..
paste0( 'recoded_int_stu12_dec03_imp' , 1:5 )

# now use `mget` to take a character vector,
# look for objects with the same names,
# and smush 'em all together into a list
imp.list <- mget( paste0( 'recoded_int_stu12_dec03_imp' , 1:5 ) )

# now take a deep breath because this next part might scare you.

# use the custom-made `svyMDBdesign` function to put
# those five database-backed tables (already smushed into a list object)
# into a new and sexy object type - a monetdb-backed, multiply-imputed svrepdesign object.
pisa.imp <- svyMDBdesign( imp.list )
# note to database-connection buffs out there: this function does the port `open`ing for you.


# for the most part, `pisa.imp` can be used like a hybrid multiply-imputed, sqlrepsurvey object.


# print the distribution of the `progcat` variable for all students in the entire data set.

MIcombine( with( pisa.imp , svymean( ~progcat ) ) )


# are we done here?  yep, we're done.

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other `pisa` monetdb analyses #
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
