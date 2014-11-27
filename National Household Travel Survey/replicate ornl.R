# analyze survey data for free (http://asdfree.com) with the r language
# national household travel survey
# 2009 day, person, and household files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( "monetdb.sequential" = TRUE )		# # only windows users need this line
# library(downloader)
# batfile <- "C:/My Directory/NHTS/MonetDB/nhts.bat"	# # note for mac and *nix users: `nhts.bat` might be `nhts.sh` instead"
# load( 'C:/My Directory/NHTS/2009 designs.rda' )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/National%20Household%20Travel%20Survey/replicate%20ornl.R" , prompt = FALSE , echo = TRUE )
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


############################################################################################
# this script matches the statistics in "Table1" of http://nhts.ornl.gov/2009/pub/stt.xlsx #
############################################################################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#########################################################################################################################
# prior to running this analysis script, the nhts 2009 file must be loaded as a monet database-backed sqlsurvey object  #
# on the local machine. running the download and import script will create a monet database containing this file.       #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw2.github.com/ajdamico/usgsd/master/National%20Household%20Travel%20Survey/download%20and%20import.R        #
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

nhts.day.design <- open( nhts.day.design , driver = MonetDB.R() , wait = TRUE )	# day-level design
nhts.hh.design <- open( nhts.hh.design , driver = MonetDB.R() , wait = TRUE )	# household-only design
nhts.per.design <- open( nhts.per.design , driver = MonetDB.R() , wait = TRUE )	# person-level design


# construct a handy function to calculate the margin of error for any formula
nhts.moe <-
	function( formula , design , FUN = svytotal ){
		
		( coef( FUN( formula , design ) ) - confint( FUN( formula , design ) , df = degf( design ) + 1 ) )[ 1 ]
		
	}
# end of function creation


############################################
# replication of household-level estimates #
############################################

# excel cell H6
svytotal( ~one , nhts.hh.design )

# excel cells H7 - H10
svytotal( ~I( hhsize == 1 ) , nhts.hh.design )
svytotal( ~I( hhsize == 2 ) , nhts.hh.design )
svytotal( ~I( hhsize == 3 ) , nhts.hh.design )
svytotal( ~I( hhsize > 3 ) , nhts.hh.design )

# excel cells I7 - I10
nhts.moe( ~I( hhsize == 1 ) , nhts.hh.design )
nhts.moe( ~I( hhsize == 2 ) , nhts.hh.design )
nhts.moe( ~I( hhsize == 3 ) , nhts.hh.design )
nhts.moe( ~I( hhsize > 3 ) , nhts.hh.design )


# excel cell H35
svytotal( ~I( hhvehcnt ) , nhts.hh.design )

# excel cell I35
nhts.moe( ~I( hhvehcnt ) , nhts.hh.design )


#########################################
# replication of person-level estimates #
#########################################

# excel cell H24
svytotal( ~I( r_sex == 1 ) , nhts.per.design )

# excel cell I24
nhts.moe( ~I( r_sex == 1 ) , nhts.per.design )

# excel cell H25
svytotal( ~I( r_sex == 2 ) , nhts.per.design )

# excel cell I25
nhts.moe( ~I( r_sex == 2 ) , nhts.per.design )

# excel cell H13
svytotal( ~I( r_age < 16 ) , nhts.per.design )

# excel cell I13
nhts.moe( ~I( r_age < 16 ) , nhts.per.design )

# excel cell H27
svytotal( ~I( driver == 1 ) , nhts.per.design )

# excel cell I27
nhts.moe( ~I( driver == 1 ) , nhts.per.design )

# excel cell H28
svytotal( ~I( r_sex == 1 & driver == 1 ) , nhts.per.design )

# excel cell I28
nhts.moe( ~I( r_sex == 1 & driver == 1 ) , nhts.per.design )

# excel cell H29
svytotal( ~I( r_sex == 2 & driver == 1 ) , nhts.per.design )

# excel cell I29
nhts.moe( ~I( r_sex == 2 & driver == 1 ) , nhts.per.design )

# excel cell H31
svytotal( ~I( worker == 1 ) , nhts.per.design )

# excel cell I31
nhts.moe( ~I( worker == 1 ) , nhts.per.design )



#######################################
# replication of trip-level estimates #
#######################################

# excel cell H41
svytotal( ~one , nhts.day.design )

# excel cell I41
nhts.moe( ~one , nhts.day.design )

# excel cell H43
svytotal( ~trpmiles , nhts.day.design )

# excel cell I43
nhts.moe( ~trpmiles , nhts.day.design )


######################
# end of replication #
######################


# close the connection to the three sqlrepsurvey design objects
close( nhts.hh.design )
close( nhts.per.design )
close( nhts.day.design )


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
