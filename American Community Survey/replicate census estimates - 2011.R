# analyze survey data for free (http://asdfree.com) with the r language
# american community survey
# 2011 person and household files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( "monetdb.sequential" = TRUE )		# # only windows users need this line
# library(downloader)
# batfile <- "C:/My Directory/ACS/MonetDB/acs.bat"		# # note for mac and *nix users: `acs.bat` might be `acs.sh` instead
# load( 'C:/My Directory/ACS/acs2011_1yr.rda' )
# source_url( "https://raw.github.com/ajdamico/asdfree/master/American%20Community%20Survey/replicate%20census%20estimates%20-%202011.R" , prompt = FALSE , echo = TRUE )
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


#####################################################
# this script matches the nationwide statistics at  ###############################################
# http://www.census.gov/acs/www/Downloads/data_documentation/pums/Estimates/pums_estimates_11.lst #
###################################################################################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################################
# prior to running this analysis script, the acs 2011 single-year file must be loaded as a monet database-backed sqlsurvey object   #
# on the local machine. running the 2005-2011 download and create database script will create a monet database containing this file #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/asdfree/blob/master/American%20Community%20Survey/download%20all%20microdata.R                          #
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

# sqlite database-backed survey objects are described here: 
# http://r-survey.r-forge.r-project.org/survey/svy-dbi.html
# monet database-backed survey objects are similar, but:
# the database engine is, well, blazingly faster
# the setup is kinda more complicated (but all done for you)

# since this script only loads one file off of the local drive,
# there's no need to set the working directory.
# instead, simply use the full filepath to the r data file (.rda)
# as shown in the load() examples below.

# choose which file in your ACS directory to analyze:
# one-year, three-year, or five-year file from any of the available years.
# this script replicates the 2011 single-year estimates,
# so leave that line uncommented and the other three choices commented out.

# load the desired american community survey monet database-backed complex sample design objects

# uncomment one of these lines by removing the `#` at the front..
# load( 'C:/My Directory/ACS/acs2011_1yr.rda' )	# analyze the 2011 single-year acs
# load( 'C:/My Directory/ACS/acs2010_1yr.rda' )	# analyze the 2010 single-year acs
# load( 'C:/My Directory/ACS/acs2010_3yr.rda' )	# analyze the 2008-2010 three-year acs
# load( 'C:/My Directory/ACS/acs2010_5yr.rda' )	# analyze the 2006-2010 five-year acs

# note: this r data file should already contain both the merged (person + household) and household-only designs


# connect the complex sample designs to the monet database #
acs.m <- open( acs.m.design , driver = MonetDB.R() , wait = TRUE )	# merged design
acs.h <- open( acs.h.design , driver = MonetDB.R() , wait = TRUE )	# household-only design



#############################################################################
# ..and immediately start printing each row matching the replication target #
#############################################################################

# http://www.census.gov/acs/www/Downloads/data_documentation/pums/Estimates/pums_estimates_11.lst #


#####################################################
# census code replication of person-level estimates #
#####################################################

	
svytotal( ~I( relp %in% 0:17 ) , acs.m )				# total population
svytotal( ~I( relp %in% 0:15 ) , acs.m )				# housing unit population
svytotal( ~I( relp %in% 16:17 ) , acs.m )				# gq population
svytotal( ~I( relp == 16 ) , acs.m )					# gq institutional population
svytotal( ~I( relp == 17 ) , acs.m )					# gq noninstitutional population
svytotal( ~I( relp %in% 0:17 ) , acs.m , byvar = ~sex )	# total males & females


# all age categories at once #

svytotal( 
	~I( agep %in% 0:4 ) +
	I( agep %in% 5:9 )   +
	I( agep %in% 10:14 ) +
	I( agep %in% 15:19 ) +
	I( agep %in% 20:24 ) +
	I( agep %in% 25:34 ) +
	I( agep %in% 35:44 ) +
	I( agep %in% 45:54 ) +
	I( agep %in% 55:59 ) +
	I( agep %in% 60:64 ) +
	I( agep %in% 65:74 ) +
	I( agep %in% 75:84 ) +
	I( agep %in% 85:100 ) , 
	acs.m 
)


# note: the MOE (margin of error) column can be calculated as the standard error x 1.645 #


###############################################
# end of person-level census code replication #
###############################################


######################################################
# census code replication of housing-level estimates #
######################################################
	

svytotal( ~I( type_ == 1 ) , acs.h )							# total housing units
svytotal( ~I( ten %in% 1:4 ) , acs.h )						# occupied units
svytotal( ~I( ten %in% 1:2 ) , acs.h )						# owner-occupied units
svytotal( ~I( ten %in% 3:4 ) , acs.h )						# renter-occupied units
svytotal( ~I( ten == 1 ) , acs.h )							# owned with mortgage
svytotal( ~I( ten == 2 ) , acs.h )							# owned free and clear
svytotal( ~I( ten == 3 ) , acs.h )							# rented for cash
svytotal( ~I( ten == 4 ) , acs.h )							# no cash rent
svytotal( ~I( vacs %in% 1:7 ) , acs.h )						# total vacant units
svytotal( ~I( vacs == 1 ) , acs.h )							# for rent
svytotal( ~I( vacs == 3 ) , acs.h )							# for sale only
svytotal( ~I( vacs %in% c( 2, 4 , 5 , 6 , 7 ) ) , acs.h )	# all other vacant


# note: the MOE (margin of error) column can be calculated as the standard error x 1.645 #


################################################
# end of housing-level census code replication #
################################################


# close the connection to the two sqlrepsurvey design objects
close( acs.m )
close( acs.h )


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
