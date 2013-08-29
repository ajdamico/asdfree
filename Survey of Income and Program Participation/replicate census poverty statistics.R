# analyze survey data for free (http://asdfree.com) with the r language
# survey of income and program participation
# 2008 panel single calendar month august 2008

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/SIPP/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Survey%20of%20Income%20and%20Program%20Participation/replicate%20census%20poverty%20statistics.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# note that these statistics do not match the census bureau's published statistics
# because their table packages - available from http://www.census.gov/sipp/tables/index.html -
# get run off of an internal, non-topcoded data set.  to read more about topcoding, visit pdf page 19
# of this document.  http://www.census.gov/sipp/usrguide/chap4rev2009.pdf


# to confirm that the methodology below is correct, analysts at the census bureau
# provided me with statistics and standard errors generated using the public use file (puf)
# https://github.com/ajdamico/usgsd/blob/master/Survey%20of%20Income%20and%20Program%20Participation/SIPP%20PUF%20Poverty%20Statistics%20from%20Census.pdf?raw=true
# this r script will replicate each of the statistics from that custom run
# of the survey of income and program participation (sipp) exactly


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


# increase size at which numbers are presented in scientific notation

options( scipen = 10 )


# if this option is set to TRUE
# R will exactly match SUDAAN results and Stata with the MSE option results
options( survey.replicates.mse = TRUE )
# otherwise if it is commented out or set to FALSE
# R will exactly match Stata without the MSE option results

# Stata svyset command notes can be found here: http://www.stata.com/help.cgi?svyset


# immediately connect to the SQLite database
# this connection will be stored in the object 'db'
db <- dbConnect( SQLite() , "SIPP08.db" )



# make a character vector containing the variables that should be kept from the core file (core keep variables)
core.kv <- 
	c( 
		# variables you almost certainly need for every calendar year analysis:
		'ssuid' , 'epppnum' , 'srotaton' , 'tage' , 'srefmon' , 'wpfinwgt' ,
		# note: the 'wpfinwgt' column does not need to be kept for calendar year analyses --
		# all weights will come from external files, not from inside the core files
	
		# variables specific to this analysis:
		
		# income and poverty variables
		'thtotinc' , 'rhpov' , 'tptotinc' , 'tpearn' ,
		
		# household and family reference person variables
		'ehrefper' , 'efrefper'
	)


# # # # # # # # # # # # #
# calendar month access #
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

	# to replicate the poverty statistics run by the census bureau,
	# simply pull the august 2008 records from a single wave
	
	sql.string <- 
		paste( 
			"select" , 
			paste( core.kv , collapse = "," ) , 
			"from w1 where rhcalyr == 2008 AND rhcalmn == 8" 
		)
		
	# and make your tablename variable something else, since it's no longer just w2 or w3.
	tablename <- 'aug08'

# end of calendar month #
# # # # # # # # # # # # #

# run the sql query constructed above, save the resulting table in a new data frame called 'x' that will now be stored in RAM
x <- dbGetQuery( db , sql.string )

# look at the first six records of x
head( x )


################################################
# access the appropriate replicate weight data #

# only the first wave of the core data file was needed above,
# so only the first wave's replicate weight file is needed here
rw <- dbReadTable( db , 'rw1' )

# look at the first six records of rw
head( rw )


############################################
# merge the core and replicate weight data #

# merge core and the replicate weights data files
y <- merge( x , rw )

# remove the (pre-merged) core and replicate weights data frames from RAM
rm( x , rw )

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

# # # # # # # # # #
# rapidly create a binary (zero or one) variable
# this little gem does two things:
	# 1) test whether the `thtotinc` column (household income) is below
	# the `rhpov` column (household census poverty threshold for each record in `y` ..
	# and return a logical vector of TRUEs and FALSEs
	# 2) convert TRUEs to 1s and FALSEs to 0s, by sending the
	# whole logical vector through the as.numeric function
y$pov <- as.numeric( y$thtotinc < y$rhpov )
# you could watch http://www.screenr.com/kVN8
# for a two-minute explanation of how this works.
# end of rapidbinary (zero or one) variable creation
# # # # # # # # # #


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

z <- update( one = 1 , z )


#################################################################
# print the exact contents of the census document to the screen #
#################################################################

# calculate the unweighted number of records
nrow( z )
# calculate the sum of weights
svytotal( ~one , z )

# run the mean of the (binary) `pov` column
person.poverty <- svymean( ~pov , z )

# print the coefficient and standard error,
# formatting the number of digits shown
# to exactly match the census-provided PDF
options( digits = 6 )
coef( person.poverty )
options( digits = 4 )
SE( person.poverty )


# subset the survey design object to only records where
# the individual *is* the household reference person
hh <- subset( z , ehrefper == epppnum )

# calculate the unweighted number of records
nrow( hh )
# calculate the sum of weights
svytotal( ~one , hh )

# run the mean of the (binary) `pov` column
household.poverty <- svymean( ~pov , hh )

# print the coefficient and standard error,
# formatting the number of digits shown
# to exactly match the census-provided PDF
options( digits = 6 )
coef( household.poverty )
options( digits = 4 )
SE( household.poverty )


# subset the survey design object to only records where
# the individual *is* the family reference person
fam <- subset( z , efrefper == epppnum )

# calculate the unweighted number of records
nrow( fam )
# calculate the sum of weights
svytotal( ~one , fam )

# run the mean of the (binary) `pov` column
family.poverty <- svymean( ~pov , fam )

# print the coefficient and standard error,
# formatting the number of digits shown
# to exactly match the census-provided PDF
options( digits = 6 )
coef( family.poverty )
options( digits = 4 )
SE( family.poverty )

###########################################################################
# end of printing the exact contents of the census document to the screen #
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
