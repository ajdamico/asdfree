# analyze survey data for free (http://asdfree.com) with the r language
# national vital statistics system
# natality, period-linked deaths, cohort-linked deaths, and fetal death files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( "monetdb.sequential" = TRUE )
# library(downloader)
# setwd( "C:/My Directory/NVSS/" )
# batfile <- "C:/My Directory/NVSS/MonetDB/nvss.bat"
# source_url( "https://raw.github.com/ajdamico/usgsd/master/National%20Vital%20Statistics%20System/replicate%20cdc%20tabulations.R" , prompt = FALSE , echo = TRUE )
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


# this r script will replicate statistics found on four different
# centers for disease control and prevention (cdc) publications
# and match the output exactly


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################
# prior to running this analysis script, the national vital statistics system files must be imported into           #
# a monet database on the local machine. you must run this:                                                         #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/usgsd/master/National%20Vital%20Statistics%20System/download%20all%20microdata.R  #
#####################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


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


library(MonetDB.R)	# load the MonetDB.R package (connects r to a monet database)


# in most monetdb scripts, specifying the .bat file (to launch the server) suffices
# however, since the fetal death files are stored in R data files (.rda) on the local disk,
# any usage of those files also requires that the working directory be specified.
# setwd( "C:/My Directory/NVSS/" )
# uncomment the line above (remove the `#`) to set the working directory to C:\My Directory\NVSS


# after running the r script above, users should have handy a few lines
# to initiate and connect to the monet database containing the
# national vital statistics system files.  run them now.  mine look like this:


#####################################################################
# lines of code to hold on to for all other `nvss` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/NVSS/MonetDB/nvss.bat"

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "nvss"
dbport <- 50012

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

# end of lines of code to hold on to for all other nvss monetdb analyses #
##########################################################################


# # # # # # # # # # # # #
# replicated statistics #
# # # # # # # # # # # # #

# the centers for disease control and prevention (cdc) published control counts of the 2010 nationwide and territory tables
# on pdf page 11 - ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/DVS/natality/UserGuide2010.pdf#11

# reproduce the control counts of the nationwide file
dbGetQuery( db , 'select count(*) , ( restatus = 4 ) as foreign_resident from natality_us_2010 group by foreign_resident' )

# reproduce the control counts of the territory file
dbGetQuery( db , 'select count(*) , ( restatus = 4 ) as foreign_resident from natality_ps_2010 group by foreign_resident' )


# on pdf page two of this document, the cdc published birth (natality) counts by month
# http://www.cdc.gov/nchs/data/nvsr/nvsr62/nvsr62_01_tables.pdf#page=2

dbGetQuery( db , 'select count(*) , dob_mm from natality_us_2011 where not ( restatus = 4 ) group by dob_mm' )


# at the bottom of pdf page three of this document,
# the cdc published period-linked deaths by race/ethnicity
# http://www.cdc.gov/nchs/data/nvsr/nvsr61/nvsr61_08.pdf#page=3

# table A
# infant deaths column

# total infant deaths
dbGetQuery( db , 'select sum( recwt ) as wt , count(*) from periodlinked_us_num2009 where not ( restatus = 4 )' )

# non-hispanic white
# non-hispanic black
dbGetQuery( db , 'select mracehisp , sum( recwt ) as wt , count(*) from periodlinked_us_num2009 where not ( restatus = 4 ) AND mracehisp IN ( 6 , 7 ) group by mracehisp order by mracehisp' )

# american indian or alaska native
# asian or pacific islander
dbGetQuery( db , 'select mracerec , sum( recwt ) as wt , count(*) from periodlinked_us_num2009 where not ( restatus = 4 ) AND mracerec IN ( 3 , 4 ) group by mracerec order by mracerec' )

# hispanic
dbGetQuery( db , 'select sum( recwt ) as wt , count(*) from periodlinked_us_num2009 where not ( restatus = 4 ) AND umhisp IN ( 1 , 2 , 3 , 4 , 5 )' )

# mexican
# puerto rican
# cuban
# central and south american
dbGetQuery( db , 'select mracehisp , sum( recwt ) as wt , count(*) from periodlinked_us_num2009 where not ( restatus = 4 ) AND mracehisp IN ( 1 , 2 , 3 , 4 ) group by mracehisp order by mracehisp' )


# on pdf page 5, the cdc broke out fetal deaths by 20-27 weeks versus 28+ weeks
# http://www.cdc.gov/nchs/data/nvsr/nvsr60/nvsr60_08.pdf#page=5

# begin with an empty data.frame object
table.b <- data.frame( NULL )

# loop through years 2005, 2006, and 2007
for ( year in 2005:2007 ){

	# load the current nationwide fetal death file for this year
	load( paste0( "fetal death " , year , ".rda" ) )
	
	# throw out records that are not united states residents or under 20 months
	x <- subset( us , tabflg == 2 & restatus != 4 )
	
	# for 2005 and 2006, use the `gest12` variable instead of `gestrec12`
	gestvar <- ifelse( year %in% 2005:2006 , 'gest12' , 'gestrec12' )
	
	# create a zero/one (binary) variable that's only 1 when
	# the gestation weeks are a three or a four
	x$weeks.20.27 <- as.numeric( x[ , gestvar ] %in% 3:4 )
	# same for five through eleven
	x$weeks.28.plus <- as.numeric( x[ , gestvar ] %in% 5:11 )
	# note that these gestation recodes are based on pdf page 31 of the 2006 layout file.
	# have a look at the levels of `gestrec5` and `gestrec12`
	# ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/DVS/fetaldeath/2006FetalUserGuide.pdf#page=31
	
	
	# proportional distribution of the unknowns with tabflg == 2
	num.to.distribute <- sum( x[ , gestvar ] %in% 12 )
	
	# create a single-row data.frame, with..
	current.year <- 
		data.frame( 
			# the current year
			year = year ,
			# the current total number of fetal deaths
			total = nrow( x ) ,
			# the 20-27 week old fetuses plus the distributed unknowns
			twenty.to.twentyseven = sum( x$weeks.20.27 ) + ( num.to.distribute * ( sum( x$weeks.20.27 ) / ( nrow( x ) - num.to.distribute ) ) ) ,
			# the 28+ week old fetuses plus the distributed unknowns
			twentyeight.plus = sum( x$weeks.28.plus ) + ( num.to.distribute * ( sum( x$weeks.28.plus ) / ( nrow( x ) - num.to.distribute ) ) )
		)
	
	# stack this new table below what's already been run for table b
	table.b <- rbind( table.b , current.year )
}

# # # # # # # # # # # # # # # # #
# end of replicated statistics  #
# # # # # # # # # # # # # # # # #


##############################################################################
# lines of code to hold on to for the end of all other nvss monetdb analyses #

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other nvss monetdb analyses #
##########################################################################

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
