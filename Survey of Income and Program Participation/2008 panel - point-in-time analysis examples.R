# analyze survey data for free (http://asdfree.com) with the r language
# survey of income and program participation
# 2008 panel wave 2

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



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#############################################################################################################################################################
# prior to running this analysis script, the survey of income and program participation 2008 panel must be loaded as a database (.db) on the local machine. #
# running the "2008 panel - download and create database" script will create this database file                                                             #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/usgsd/master/Survey%20of%20Income%20and%20Program%20Participation/2008%20panel%20-%20download%20and%20create%20database.R #
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
# install.packages( c( "survey" , "RSQLite" ) )


require(survey)		# load survey package (analyzes complex design surveys)
require(RSQLite) 	# load RSQLite package (creates database files in R)



# if this option is set to TRUE
# R will exactly match SUDAAN results and Stata with the MSE option results
options( survey.replicates.mse = TRUE )
# otherwise if it is commented out or set to FALSE
# R will exactly match Stata without the MSE option results

# Stata svyset command notes can be found here: http://www.stata.com/help.cgi?svyset


# immediately connect to the SQLite database
# this connection will be stored in the object 'db'
db <- dbConnect( SQLite() , "SIPP08.db" )


#########################################
# access the appropriate core wave data #

# which wave would you like to pull?
# to see which waves correspond with what months, see http://www.census.gov/sipp/usrguide/ch2_nov20.pdf
# pages 5, 6, 7, and 8 have sipp panels 2008, 2004, 2001, and 1996, respectively
wave <- 2	
# wave 2 was conducted january 2009 - april 2009 and contains data for september 2008 - march 2009.
# remember that most months occur in multiple waves (see calendar month alternative below for more detail)


# make a character vector containing the variables that should be kept from the core file (core keep variables)
core.kv <- 
	c( 
		# variables you almost certainly need for every point-in-time analysis
		'ssuid' , 'epppnum' , 'wpfinwgt' , 'tage' , 
	
		# variables specific to this analysis
		'esex' , 'ems'
	)


# each core wave data file contains data at the person-month level.  in general, there are four records per respondent in each core wave data set.
# for most point-in-time analyses, use the fourth (most current) month,
# specifically isolated below by the 'srefmon == 4' command

# create a sql string containing the select command used to pull only a defined number of columns 
# and records containing the fourth reference month from the full core data file
sql.string <- paste0( "select " , paste( core.kv , collapse = "," ) , " from w" , wave , " where srefmon == 4" )
# note: this yields point-in-time data collected over a four month period.

# # # # # # # # # # # # # # # #
# calendar month alternative: #
# if an analysis requires specific a specific month on the calendar, instead of 'srefmon == 4' use 'rhcalmn == #' where # is 1 through 12
# this alternative is not as desirable, however, because:
	# a) only one of the four rotation groups will have been interviewed in the month of the calendar (the other three will be more prone to memory-bias)
	# b) questions and variables available only in the topical modules (not the core files) reflect the month prior to the interview, and will not be available at other time periods
	# c) the odds are 75% that you must stack multiple waves.  to figure out which two waves to stack, look at pdf page 5 of http://www.census.gov/sipp/usrguide/ch2_nov20.pdf
		# for example, point in time for 'february 2009' would require stacking waves 2 and 3.  so use this sql string:

		# sql.string <- 
			# paste( 
				# "select" , 
				# paste( core.kv , collapse = "," ) , 
				# "from w2 where rhcalyr == 2009 AND rhcalmn == 2" ,
				# "union select" , 
				# paste( core.kv , collapse = "," ) , 
				# "from w3 where rhcalyr == 2009 AND rhcalmn == 2" 
			# )
			
		# and make your tablename variable something else, since it's no longer just w2 or w3.
		# tablename <- 'feb09'

# end of calendar month alternative #
# # # # # # # # # # # # # # # # # # #

# run the sql query constructed above, save the resulting table in a new data frame called 'x' that will now be stored in RAM
x <- dbGetQuery( db , sql.string )

# look at the first six records of x
head( x )


################################################
# access the appropriate replicate weight data #

# create a sql string containing the select command used to pull the fourth reference month from the replicate weights data file
sql.string <- paste0( "select * from rw" , wave , " where srefmon == 4" )
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
		'exmar'
	)


# each topical module data file contains data at the person-level.  in general, there is one record per respondent in each topical module data set.
# topical module data corresponds with the month prior to the interview, so using the 'srefmon == 4' filter on the core file will correspond with that wave's topical module

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


####################
# recode variables #


# overwrite the fully-merged data frame..
y <-
	transform(
		# with itself
		y ,
		
		# newly-created variables:
		
		# never married
		nm = ifelse( ems %in% 6 , 1 , 0 ) ,
		
		# ever married
		em = ifelse( ems %in% 1:5 , 1 , 0 ) ,
		
		# married once
		m1 = ifelse( exmar %in% 1 , 1 , 0 ) ,
		
		# married once, and currently married
		sm1 = ifelse( exmar %in% 1 & ems %in% c( 1 , 2 ) , 1 , 0 ) ,
		
		# married twice
		m2 = ifelse( exmar %in% 2 , 1 , 0 ) ,
		
		# married twice, and currently married
		sm2 = ifelse( exmar %in% 2 & ems %in% c( 1 , 2 ) , 1 , 0 ) ,
		
		# married three or more times
		m3 = ifelse( exmar %in% 3:4 , 1 , 0 ) ,
		
		# married three or more times, and currently married
		sm3 = ifelse( exmar %in% 3:4 & ems %in% c( 1 , 2 ) , 1 , 0 ) 
		
	)
	

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

# note: these results do not match the published results exactly for two reasons:
	# 1) census bureau publications of sipp data use a different
	# file than the publicly-available one, which is topcoded, edited, and contains slightly different weights
	# 2) census bureau analysts often use the generalized variance formula (gvf)
	# to calculate the margin of error.  (i confirmed that gvf was used with the author)
	# to read about the gvf, see pdf page 4 of
	# https://www.census.gov/sipp/usrguide/chap7rev2008.pdf
		# this code calculates the standard error using fay's method automatically
		# (pdf page 3 recommends using fay's method whenever possible)
		# the generalized variance formula is an imperfect methodological shortcut,
		# but r makes it easy to calculate the error terms with the recommended methodology

# create a subset of the original survey design
# that only includes individuals aged 15+
z.15p <- subset( z , tage > 14 )

# calculate the unweighted number of ever-married americans in the data
unwtd.count( ~one , subset( z.15p , em ) )
# this number matches the count shown
# in the fourth paragraph of the first page of the report


# closely replicate the first column of table 6 (pdf page 16) in
# http://www.census.gov/prod/2011pubs/p70-125.pdf

# the total number of americans aged 15+
svyby( ~one , ~esex , z.15p , svytotal )	# close to the total row

# print percents, broken out by sex

# never-married
svyby( ~nm , ~esex , z.15p , svymean )

# ever-married
svyby( ~em , ~esex , z.15p , svymean )

# married once
svyby( ~m1 , ~esex , z.15p , svymean )

# still in first marriage (excludes separated)
svyby( ~sm1 , ~esex , z.15p , svymean )

# married twice
svyby( ~m2 , ~esex , z.15p , svymean )

# still in second marriage (excludes separated)
svyby( ~sm2 , ~esex , z.15p , svymean )

# married three or more times
svyby( ~m3 , ~esex , z.15p , svymean )

# still in third or later marriage (excludes separated)
svyby( ~sm3 , ~esex , z.15p , svymean )


# 95% confidence interval for never-married
confint( svyby( ~nm , ~esex , z.15p , svymean ) )

# 90% confidence interval for never-married
confint( svyby( ~nm , ~esex , z.15p , svymean ) , level = .9 )

# note: these analysis examples are intentionally sparse
# (to focus attention on the data manipulation part, which is much harder in sipp)
# once the replicate-weighted survey design object has been created,
# any of the features described on http://faculty.washington.edu/tlumley/survey/ can be used.
# all of the analysis examples shown for other survey data sets can be used on a sipp survey design too,
# so be sure to check out other data sets on http://asdfree.com/ for more thorough examples

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
