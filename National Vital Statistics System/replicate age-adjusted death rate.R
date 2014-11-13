# analyze survey data for free (http://asdfree.com) with the r language
# national vital statistics system
# mortality files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( "monetdb.sequential" = TRUE )
# library(downloader)
# batfile <- "C:/My Directory/NVSS/MonetDB/nvss.bat"
# source_url( "https://raw.github.com/ajdamico/usgsd/master/National%20Vital%20Statistics%20System/replicate%20age-adjusted%20death%20rate.R" , prompt = FALSE , echo = TRUE )
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


# remove the # in order to run this install.packages line only once
# install.packages( "sqldf" )

library(MonetDB.R)	# load the MonetDB.R package (connects r to a monet database)
library(sqldf)		# load the sqldf package (enables sql queries on data frames)

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

# table b on pdf page 59 of this cdc publication:
# http://www.cdc.gov/nchs/data/nvsr/nvsr61/nvsr61_04.pdf#page=59
# number of deaths due to all causes, diseases of the heart, and malignant neoplasms
# 2010 crude death rate
# 2010 age-adjusted death rate


# create a data.frame object with the united states 2000 census bureau
# population totals (by age) to standardize to.
# these age-stratified counts come from pdf page 111 table IX of
# http://www.cdc.gov/nchs/data/nvsr/nvsr60/nvsr60_03.pdf#page=111
pop2k <- 
	data.frame(
		ager12 = 1:11 ,
		pop2k = c( 3794901 , 15191619 , 39976619 , 38076743 , 37233437 , 44659185 , 37030152 , 23961506 , 18135514 , 12314793 , 4259173 )
	)

# immediately calculate the proportion of each age-strata
pop2k$wgt <- pop2k$pop2k / sum( pop2k$pop2k )


# initiate a temporary file and a temporary directory
tf <- tempfile() ; td <- tempdir()


# download the census bureau's 2010 bridged population estimates
download.file( "ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/datasets/nvss/bridgepop/census_0401_2010.txt.zip" , tf , mode = 'wb' )
# this will be a data.frame with one record per age per race per county

# unzip that temporary file into the temporary directory..
census.estimates <- unzip( tf , exdir = td )
# ..and also store the location of that file into a character string `census.estimates`

# use the bridge file's ascii layout as found on pdf page 8 of this cdc publication
# ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/datasets/nvss/bridgepop/DocumentationBridgedApril1_2010.pdf#page=8
x <- 
	read.fwf(
		census.estimates ,
		widths = c( 2 , 3 , 2 , 1 , 1 , 8 ) ,
		header = FALSE ,
		col.names = c( "st_fips" , "co_fips" , "age" , "racesex" , "hisp" , "pop2010" )
	)

# remove the temporary file and the unzipped temporary file
file.remove( census.estimates , tf )


# since `x` contains one record per age, recode those ages into groups.
# reproduce the `age recode 12` found on pdf page 8 of this cdc publication
# http://www.cdc.gov/nchs/data/dvs/Record_Layout_2010.pdf#page=8
x$ager12 <-
	findInterval(
		x$age ,
		c( 0 , 1 , seq( 5 , 85 , 10 ) )
	)
# this is the recode that the cdc uses for age-adjusted rates	

# sum up the population in 2010 according to those newly-constructed age categories
pbac <- sqldf( "select ager12 , sum( pop2010 ) as pop from x group by ager12" )

# begin reproducing table b on pdf page 59 of this cdc publication:
# http://www.cdc.gov/nchs/data/nvsr/nvsr61/nvsr61_04.pdf#page=59

# deaths from all causes, excluding non-residents
( deaths.from.all.causes <- dbGetQuery( db , 'select count(*) as count from mortality_us_2010 where not ( restatus = 4 )' ) )
# note: by putting the entire expression in parentheses, this both creates the object `deaths.from.all.causes` and prints it to the screen

# pull the specific cause categorizations from the national bureau of economic research
# table with causes of death labels: http://www.nber.org/mortality/1999/docs/39cause.txt

# deaths from diseases of the heart, excluding non-residents
dbGetQuery( db , 'select count(*) as count from mortality_us_2010 where not ( restatus = 4 ) and ucr39 IN ( 20 , 21 , 22 )' )

# deaths from malignant neoplasms, excluding non-residents
dbGetQuery( db , 'select count(*) as count from mortality_us_2010 where not ( restatus = 4 ) and ucr39 >= 5 and ucr39 <= 15 ' )

# and here's your crude death rate
deaths.from.all.causes / sum( pbac$pop )


# # # # # # # # # # # # #
# diversionary sidenote #

# for *linear* age computations, you must use the "detailed age" column
# http://www.cdc.gov/nchs/data/dvs/Record_Layout_2010.pdf#page=8
# which has four digits: the first digit is whether the age is stored in years/months/days
# the last three digits are the actually age (in years/months/days)

# so after excluding all of the `9999` values, "age in years" can be computed with
# dbSendQuery( db , "ALTER TABLE mortality_us_2010 ADD COLUMN age_in_years DOUBLE PRECISION" )
# according to the 2010 codebook, anyone with a first digit between 2 and 8 died before age 1
# dbSendQuery( db , "UPDATE mortality_us_2010 SET age_in_years = 0 WHERE age >= 2000 & age < 9000" )
# everyone with a "1" starting digit just has the age designated in the 2nd, 3rd, and 4th position.
# dbSendQuery( db , "UPDATE mortality_us_2010 SET age_in_years = ( age - 1000 ) WHERE age < 2000" )

# end of diversionary sidenote  #
# # # # # # # # # # # # # # # # #


# go back to the monet database one more time

# pull a table of counts of deaths, broken out by the 12-level age category variable
dbac <- dbGetQuery( db , 'select ager12 , count(*) as count from mortality_us_2010 where not ( restatus = 4 ) group by ager12 order by ager12' )

# merge the population by age category with the deaths by age category
y <- merge( pbac , dbac )

# then merge _that_ with the census 2000 population weights
z <- merge( y , pop2k )

# divide the number of deaths by the total population within each age strata
z$rate.within.age <- z$count / z$pop
# which essentially gives a crude death rate within each age strata

# finally, multiply the rate within each age by the census 2000-based weight
sum( z$rate.within.age * z$wgt )
# that statistic matches the cdc's age-adjusted published death rate for 2010


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
