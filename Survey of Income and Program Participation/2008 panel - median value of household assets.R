# analyze survey data for free (http://asdfree.com) with the r language
# survey of income and program participation
# 2008 panel wave 7

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/SIPP/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Survey%20of%20Income%20and%20Program%20Participation/2008%20panel%20-%20median%20value%20of%20household%20assets.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#############################################################################################################################################################
# prior to running this analysis script, the survey of income and program participation 2008 panel must be loaded as a database (.db) on the local machine. #
# running the "2008 panel - download and create database" script will create this database file                                                             #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/Survey%20of%20Income%20and%20Program%20Participation/2008%20panel%20-%20download%20and%20create%20database.R #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "SIPP08.db" in C:/My Directory/SIPP or wherever the working directory was set for the program                              #
#############################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# set your working directory.
# this directory must contain the SIPP 2008 database (.db) file 
# "SIPP08.db" created by the R program specified above
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/SIPP/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( "survey" )


library(survey)				# load survey package (analyzes complex design surveys)
library(MonetDB.R)			# load the MonetDB.R package (connects r to a monet database)
library(MonetDBLite)		# load MonetDBLite package (creates database files in R)



# if this option is set to TRUE
# R will exactly match SUDAAN results and Stata with the MSE option results
options( survey.replicates.mse = TRUE )
# otherwise if it is commented out or set to FALSE
# R will exactly match Stata without the MSE option results

# Stata svyset command notes can be found here: http://www.stata.com/help.cgi?svyset


# name the database files in the "SIPP08" folder of the current working directory
dbfolder <- paste0( getwd() , "/SIPP08" )

# connect to the MonetDBLite database (.db)
db <- dbConnect( MonetDBLite() , dbfolder )



#########################################
# access the appropriate core wave data #

# which wave would you like to pull?
# to see which waves correspond with what months, see http://www.census.gov/sipp/usrguide/ch2_nov20.pdf
# pages 5, 6, 7, and 8 have sipp panels 2008, 2004, 2001, and 1996, respectively
wave <- 7	
# wave 7 was conducted june 2010 - december 2010 and contains data for may 2010 - november 2010.
# remember that most months occur in multiple waves (see calendar month alternative below for more detail)


# make a character vector containing the variables that should be kept from the core file (core keep variables)
core.kv <- 
	c( 
		# variables you almost certainly need for every point-in-time analysis
		'ssuid' , 'epppnum' , 'wpfinwgt' , 'tage' , 
	
		# variables specific to this analysis
		'errp' , 'etenure' , 'whfnwgt'
	)
	
# each core wave data file contains data at the person-month level.  in general, there are four records per respondent in each core wave data set.
# for most point-in-time analyses, use the fourth (most current) month,
# specifically isolated below by the 'srefmon = 4' command

# create a sql string containing the select command used to pull only a defined number of columns 
# and records containing the fourth reference month from the full core data file
sql.string <- paste0( "select " , paste( core.kv , collapse = "," ) , " from w" , wave , " where srefmon = 4" )
# note: this yields point-in-time data collected over a four month period.

# run the sql query constructed above, save the resulting table in a new data frame called 'x' that will now be stored in RAM
x <- dbGetQuery( db , sql.string )

# look at the first six records of x
head( x )


################################################
# access the appropriate replicate weight data #

# create a sql string containing the select command used to pull the fourth reference month from the replicate weights data file
sql.string <- paste0( "select * from rw" , wave , " where srefmon = 4" )
# note: this yields point-in-time data collected over a four month period.

# run the sql query constructed above, save the resulting table in a new data frame called 'rw' that will now be stored in RAM
rw <- dbGetQuery( db , sql.string )

# look at the first six records of rw
head( rw )


############################################
# merge the core and replicate weight data #

# merge core and the replicate weights data files
x.rw <- merge( x , rw )

# confirm no loss of records
# (in other words, each record in the core wave data file has a match in the replicate weights file)
stopifnot( nrow( x ) == nrow( x.rw ) )

# remove the (pre-merged) core and replicate weights data frames from RAM
rm( x , rw )

# clear up RAM
gc()


################################################
# optional: access desired topical module data #

# the 'wave' variable has already been defined above..
# the code below will assume the topical from the same wave should be used.

# make a character vector containing the variables that should be kept from the topical module file (topical module keep variables)
tm.kv <- 
	c( 
		# variables you almost certainly need for every analysis
		'ssuid' , 'epppnum' , 
		
		# variables specific to this analysis
		'thhtnw' , 'thhtheq'
	)


# each topical module data file contains data at the person-level.  in general, there is one record per respondent in each topical module data set.
# topical module data corresponds with the month prior to the interview, so using the 'srefmon = 4' filter on the core file will correspond with that wave's topical module

# create a sql string containing the select command used to pull only a defined number of columns 
sql.string <- paste0( "select " , paste( tm.kv , collapse = "," ) , " from tm" , wave )

# run the sql query constructed above, save the resulting table in a new data frame called 'tm' that will now be stored in RAM
tm <- dbGetQuery( db , sql.string )

# look at the first six records of tm
head( tm )


######################################
# optional: merge the topical module #

# merge the topical module to the already-merged core and the replicate weights data files
y <- merge( x.rw , tm )

# confirm no loss of records
# (in other words, each record in the core wave data file has a match in the topical module file)
stopifnot( nrow( x.rw ) == nrow( y ) )

# remove the core and replicate weight merged data frame
# as well as the (pre-merged) topical module data frames from RAM
rm( x.rw , tm )

# clear up RAM
gc()



#############################################################
# fix integer columns - these should be numeric and divided #

# identify all integer columns
ic <- sapply( y , is.integer )

# convert all 'integer' types to 'numeric'
y[ic] <- lapply( y[ ic ] , as.numeric )

# divide all weights by ten thousand
# (the four implied decimal points are not included in the SAS input scripts)

# identify weight columns
wc <- names( y )[ grep( 'wgt' , names( y ) ) ]

# create a new divide-by-ten-thousand function
dbtt <- function( x ){ x / 10000 }

# apply that new dbtt() function to every single column specified in the 'wc' character variable
y[ wc ] <- lapply( y[ wc ] , dbtt )


#################################################
# save your data frame for quick analyses later #

# in order to bypass the above steps for future analyses,
# the data frame in its current state can be saved now
# (or, really, anytime you like).  uncomment this line:
# save( y , file = "sipp08.point.in.time.rda" )
# or, to save to another directory, specify the entire filepath
# save( y , file = "C:/My Directory/sipp08.point.in.time.rda" )

# at a later time, y can be re-accessed with the load() function
# (just make sure the current working directory has been set to the same place)
# load( "sipp08.point.in.time.rda" )
# or, if you don't set the working directory, just specify the full filepath
# load( "C:/My Directory/sipp08.point.in.time.rda" )


#############################################################
# survey design for replicate weights with fay's adjustment #

# create a survey design object with SIPP design information
z <- 
	svrepdesign ( 
		data = y ,
		repweights = "repwgt[1-9]" , 
		type = "Fay" , 
		combined.weights = T , 
		rho = ( 1 - 1 / sqrt( 4 ) ) ,
		weights = ~wpfinwgt
	)

# workaround for a bug in survey::svrepdesign.character
z$mse <- TRUE

	

# add a new variable 'one' that simply has the number 1 for each record #
# and can be used to calculate unweighted and weighted population sizes #

z <-
	update( 
		one = 1 ,
		z
	)


####################################################
# save your survey design for quick analyses later #

# in order to bypass the above steps for future analyses,
# the survey object in its current state can be saved now
# (or, really, anytime you like).  uncomment this line:
# save( z , file = "sipp08.point.in.time.design.rda" )
# or, to save to another directory, specify the entire filepath
# save( z , file = "C:/My Directory/sipp08.point.in.time.design.rda" )

# at a later time, z can be re-accessed with the load() function
# (just make sure the current working directory has been set to the same place)
# load( "sipp08.point.in.time.design.rda" )
# or, if you don't set the working directory, just specify the full filepath
# load( "C:/My Directory/sipp08.point.in.time.design.rda" )


# also note: multiple objects can be saved inside a single R data file (.rda)
# save( y , z , file = "sipp08.point.in.time.df.and.design.rda" )

# at this point, if you close R, open it again, reset the working directory,
# load( "sipp08.point.in.time.df.and.design.rda" )
# will bring back both y and z objects
	

#####################
# analysis examples #

# reproduce census published statistics as closely as possible, using the public use files
# http://www.census.gov/people/wealth/files/Wealth_Tables_2010.xls

# note: these results do not match the published results exactly because
# census bureau publications of sipp data use a different file than the publicly-available one,
# which is topcoded, edited, and contains slightly different weights


# the survey design still contains 85,397 records
nrow( z )

# keep only records where the person is the reference person
w <- subset( z , errp %in% 1:2 )

# but now only contains 33,795 records
nrow( w )


# confirm that everyone in this new merged, restricted file has
# tage > 14
svytable( ~tage , w )
# -- yes, every record is of a person aged 15 or older.
# in fact, 17 or older.


# calculate the mean total household net worth three different ways:

# calculate the mean total household net worth
svymean( ~thhtnw , w )
# much lower than the published


# calculate the mean total household net worth, restricted to only
# households that thhtnw is not equal zero
svymean( ~thhtnw , subset( w , thhtnw != 0 ) )
# lower than the published $322,352


# calculate the mean total household net worth, restricted to only
# households that thhtnw is greater than zero
svymean( ~thhtnw , subset( w , thhtnw > 0 ) )
# still much lower than the published $322,352



# calculate the median total household net worth three different ways:


# this statistic was confirmed as the correct result using the public data by the census bureau #
# calculate the median total household net worth
svyquantile( ~thhtnw , w , 0.5 )
# quite close to the published $66,740 number
# again, the statistic above was confirmed as the correct result using the public data by the census bureau #


# calculate the median equity in own home variable,
# using only households with etenure == 1
svyquantile( ~thhtheq , subset( w , etenure == 1 ) , 0.5 )
# this matches the published number exactly

# calculate the mean equity in own home variable..
svymean( ~thhtheq , subset( w , etenure == 1 ) )
# lower than the published $135,850
# again, because the topcoding removed important outliers



# calculate the median net worth (excluding equity in own home)
svyquantile( ~as.numeric( thhtnw - thhtheq ) , w , 0.5 )
# $15,102 -- this is almost the same as the published number of $15,000
# and is possibly the result of a different quantile calculation between software
# all nine quantile calculation types are listed on
# http://stat.ethz.ch/R-manual/R-patched/library/stats/html/quantile.html


# note: these analysis examples are intentionally sparse
# (to focus attention on the data manipulation part, which is much harder in sipp)
# once the replicate-weighted survey design object has been created,
# any of the features described on http://r-survey.r-forge.r-project.org/survey/ can be used.
# all of the analysis examples shown for other survey data sets can be used on a sipp survey design too,
# so be sure to check out other data sets on http://asdfree.com/ for more thorough examples
