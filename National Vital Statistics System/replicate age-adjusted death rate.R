# analyze survey data for free (http://asdfree.com) with the r language
# national vital statistics system
# mortality files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NVSS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Vital%20Statistics%20System/replicate%20age-adjusted%20death%20rate.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


# this r script will replicate statistics found on four different
# centers for disease control and prevention (cdc) publications
# and match the output exactly


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################
# prior to running this analysis script, the national vital statistics system files must be imported into           #
# a monet database on the local machine. you must run this:                                                         #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Vital%20Statistics%20System/download%20all%20microdata.R #
#################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# remove the # in order to run this install.packages line only once
# install.packages( "sqldf" )

library(DBI)			# load the DBI package (implements the R-database coding)
library(MonetDBLite)	# load MonetDBLite package (creates database files in R)
library(sqldf)		# load the sqldf package (enables sql queries on data frames)


# setwd( "C:/My Directory/NVSS/" )
# uncomment the line above (remove the `#`) to set the working directory to C:\My Directory\NVSS


# after running the r script above, users should have handy a few lines
# to initiate and connect to the monet database containing the
# national vital statistics system files.  run them now.  mine look like this:

# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )

# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite() , dbfolder )


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


# disconnect from the current monet database
dbDisconnect( db , shutdown = TRUE )

