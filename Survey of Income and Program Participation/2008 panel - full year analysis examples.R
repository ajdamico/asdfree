# analyze survey data for free (http://asdfree.com) with the r language
# survey of income and program participation
# 2008 panel 2010 calendar year

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/SIPP/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Survey%20of%20Income%20and%20Program%20Participation/2008%20panel%20-%20full%20year%20analysis%20examples.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# https://www.youtube.com/watch?v=JLt9JfaAxUg

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


# increase size at which numbers are presented in scientific notation

options( scipen = 10 )


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


#############################################
# access the appropriate core waves of data #

# which waves would you like to pull?  to pull an entire calendar year, you must pull each interview that overlaps the year you want
# to see which waves correspond with what months, see http://www.census.gov/sipp/usrguide/ch2_nov20.pdf
# pages 5, 6, 7, and 8 have sipp panels 2008, 2004, 2001, and 1996, respectively

# here's an example using the 2008 panel

# uncomment this line to pull waves necessary for 2009 calendar year
# and comment all other "waves <-" lines
# waves <- 2:5 ; year <- 2009 ; mainwgt <- 'lgtcy1wt' ; yrnum <- 1

# uncomment this line to pull waves necessary for 2010 calendar year:
# and comment all other "waves <-" lines
waves <- 5:8 ; year <- 2010 ; mainwgt <- 'lgtcy2wt' ; yrnum <- 2

# uncomment this line to pull waves necessary for 2011 calendar year:
# and comment all other "waves <-" lines
# waves <- 8:11 ; year <- 2011 ; mainwgt <- 'lgtcy3wt' ; yrnum <- 3




# make a character vector containing the variables that should be kept from the core file (core keep variables)
core.kv <- 
	c( 
		# variables you almost certainly need for every calendar year analysis:
		'ssuid' , 'epppnum' , 'srotaton' , 'tage' , 
		# note: the 'wpfinwgt' column does not need to be kept for calendar year analyses --
		# all weights will come from external files, not from inside the core files
	
		# variables specific to this analysis:
		
		# income and asset variables
		'tptotinc' , 'tpearn' ,
		
		# demographic variables
		'esex' , 'erace' , 'eorigin' , 'ems' , 'eeducate'
	)


# each core wave data file contains data at the person-month level.  in general, there are four records per respondent in each core wave data set.

# in order to create a file containing every individual's monthly observations throughout the calendar year,
# query each of the waves designated above, removing each record containing an rhcalyr (calendar year) matching the year designated above

########################################################################
# loop through all twelve months, merging each month onto the previous #

# note: this loop takes a while.  run it overnight if you can.
# and don't worry, there are save() and load() examples below so you only have to do this once
# (so long as you picked all the variables you need above)

# hey let's time how long the whole thing takes!
# create a new variable containing the current time
start.time <- Sys.time()

for ( i in 1:12 ){

	# print the current progress to the screen
	cat( "currently working on month" , i , "of 12" , "\r" )

	# create a character vector containing each of the column names,
	# with a month number at the end, so long as it's not one of the two merge variables
	numbered.core.kv <-
		# determine column names of each variable
		paste0(
			core.kv ,
			ifelse( 
				# if the column name is either of these two..
				core.kv %in% c( "ssuid" , "epppnum" ) , 
				# ..nothing gets pasted.
				"" , 
				# otherwise, a month number gets pasted
				i 
			) 
		)

		
	# create the same character vector missing 'ssuid' and 'epppnum'
	no.se.core.kv <- numbered.core.kv[ !( numbered.core.kv %in% c( 'ssuid' , 'epppnum' ) ) ]
		
		
	# create a sql string containing the select command used to pull only a defined number of columns
	# and records containing january, looking at each of the specified waves
	sql.string <- 
		# this outermost paste0 just specifies the temporary table to create
		paste0(
			"create table sm as ( " ,
			# this paste0 combines all of the strings contained inside it,
			# separating each of them by "union all" -- actively querying multiple waves at once
			paste0( 
				paste0( 
					"( select " , 
					# this paste command collapses all of the old + new variable names together,
					# separating them by a comma
					paste( 
						# this paste command combines the old and new variable names, with an "as" in between
						paste(
							core.kv , 
							"as" ,
							numbered.core.kv 
						) ,
						collapse = "," 
					) , 
					" from w" 
				) , 
				waves , 
				paste0( 
					" where rhcalmn = " ,
					i ,
					" AND rhcalyr = " , 
					year 
				) , 
				collapse = ") union all " 
			) ,
			") ) with data"
		)

	# take a look at the full query if you like..
	sql.string
	
	# run the actual command (this takes a while)
	dbSendQuery( db , sql.string )
	
	# if it's the first month..
	if ( i == 1 ){
	
		# create the single year (sy1) table from the january table..
		dbSendQuery( db , "create table sy1 as select * from sm with data" )
		
		# check out the record count
		print( dbGetQuery( db , paste0( "SELECT COUNT(*) FROM sy" , i ) ) )
		
		# ..and drop the current month table.
		dbRemoveTable( db , "sm" )
	
	# otherwise..
	} else {
	
		# merge the current month onto the single year (sy#) table..
		dbSendQuery( 
			db , 
			paste0( 
				"create table sy" , 
				i , 
				" as select a.* , " ,
				paste0( "b." , no.se.core.kv , collapse = "," ) , 
				" from sy" ,
				i - 1 ,
				" as a left join sm as b on a.ssuid = b.ssuid AND a.epppnum = b.epppnum with data" 
			)
		)
		
		# check out the record count
		print( dbGetQuery( db , paste0( "SELECT COUNT(*) FROM sy" , i ) ) )
		
		# drop the current month table
		dbRemoveTable( db , "sm" )
	
		# check out the record count
		print( dbGetQuery( db , paste0( "SELECT COUNT(*) FROM sy" , i ) ) )
		
		# ..and drop the prior-month table
		dbRemoveTable( db , paste0( "sy" , i - 1 ) )
		
	}

}

# subtract the current time from the starting time,
# and print the total twelve-loop time to the screen
Sys.time() - start.time


# once the single year (sy) table has information from all twelve months, extract it from the monetdblite database
x <- dbGetQuery( db , "select * from sy12" )

# toss the sy12 table as well
dbRemoveTable( db , 'sy12' )

# look at the first six records of x
head( x )


#################################################
# save your data frame for quick analyses later #

# in order to bypass the above steps for future analyses,
# the data frame in its current state can be saved now
# (or, really, anytime you like).  uncomment this line:
# save( y , file = "sipp08.cy.rda" )
# or, to save to another directory, specify the entire filepath
# save( y , file = "C:/My Directory/sipp08.cy.rda" )

# at a later time, y can be re-accessed with the load() function
# (just make sure the current working directory has been set to the same place)
# load( "sipp08.cy.rda" )
# or, if you don't set the working directory, just specify the full filepath
# load( "C:/My Directory/sipp08.cy.rda" )


###########################################
# access the appropriate main weight data #

# run the sql query constructed above, save the resulting table in a new data frame called 'mw' that will now be stored in RAM
mw <- dbGetQuery( db , "select * from wgtw16" )

# dump the `spanel` variable, which might otherwise sour up your merge
mw$spanel <- NULL

# look at the first six records of mw
head( mw )


##################################################
# merge the full calendar year main weights #

# merge core and the main weights data files
x.mw <- merge( x , mw , all = TRUE )

# remove the (pre-merged) core and main weights data frames from RAM
rm( x , mw )

# clear up RAM
gc()



################################################
# access the appropriate replicate weight data #

# create a sql string containing the select command used to pull the calendar year replicate weights data file
sql.string <- paste0( "select * from cy" , yrnum )

# run the sql query constructed above, save the resulting table in a new data frame called 'rw' that will now be stored in RAM
rw <- dbGetQuery( db , sql.string )

# dump the `spanel` variable, which might otherwise sour up your merge
rw$spanel <- NULL

# look at the first six records of rw
head( rw )


##################################################
# merge the full calendar year replicate weights #

# merge core and the replicate weights data files
y <- merge( x.mw , rw , all = TRUE )

# remove the (pre-merged) core and replicate weights data frames from RAM
rm( x.mw , rw )

# clear up RAM
gc()


####################
# recode variables #

# annualize a variable, as a mean, then a sum

# create a new annualized average monthly income variable
y[ , 'moninc' ] <- 
	rowMeans( 
		y[ , paste0( 'tptotinc' , 1:12 ) ] , 
		# set na.rm = TRUE if you want to take the mean of all non-missing variables
		# set na.rm = FALSE if you want records with *any* missing months to have a missing as their annualized variable
		na.rm = TRUE 
	)

# create a new annual income variable
y[ , 'anninc' ] <- 
	rowSums( 
		y[ , paste0( 'tptotinc' , 1:12 ) ] , 
		# set na.rm = TRUE if you want to take the mean of all non-missing variables
		# set na.rm = FALSE if you want records with *any* missing months to have a missing as their annualized variable
		na.rm = TRUE
	)

# create a new first-quarter income variable
y[ , 'q1inc' ] <- 
	rowSums( 
		y[ , paste0( 'tptotinc' , 1:3 ) ] , 
		# set na.rm = TRUE if you want to take the mean of all non-missing variables
		# set na.rm = FALSE if you want records with *any* missing months to have a missing as their annualized variable
		na.rm = TRUE
	)
	
# create a new annual earnings variable
y[ , 'annearn' ] <- 
	rowSums( 
		y[ , paste0( 'tpearn' , 1:12 ) ] , 
		# set na.rm = TRUE if you want to take the mean of all non-missing variables
		# set na.rm = FALSE if you want records with *any* missing months to have a missing as their annualized variable
		na.rm = TRUE
	)

# create a new first-quarter earnings variable
y[ , 'q1earn' ] <- 
	rowSums( 
		y[ , paste0( 'tpearn' , 1:3 ) ] , 
		# set na.rm = TRUE if you want to take the mean of all non-missing variables
		# set na.rm = FALSE if you want records with *any* missing months to have a missing as their annualized variable
		na.rm = TRUE
	)
	

# double-check the codebook to determine if any demographic variables
# should be re-categorized using a different method.  here's the 2008 panel's core codebook:
# http://smpbff2.dsd.census.gov/pub/sipp/2008/l08puw1d.txt
	
# recode demographics into categories
y <-
	transform(
		y ,
		
		# race/ethnicity categories:
		# if hispanic origin, add a new category
		# otherwise, use the race variable
		raceeth = ifelse( eorigin1 == 1 , 5 , erace1 ) ,

		
		# age categories:
		# the cut() function requires two parameters - the variable to categorize and the points to draw the lines.
		# cut() defaults at using everything greater than the lower bound, up-to-and-including the upper bound
		# so this example creates categories:
		# 0-14; 15-24; 25-34; 35-44; 45-54; 55-64; 65+
		agecat = cut( tage1 , c( -1 , seq( 14 , 64 , 10 ) , Inf ) ) ,
		# note: the cut() function's entire second parameter is
		# c( -1 , seq( 14 , 64 , 10 ) , Inf )
		# try running that line alone in your console -- it's a numeric vector with a length() of eight
		
		
		# education categories
		# this example creates six categories:
		# less than high school; high school graduate; some college, no degree; aa degree, vocational certificate; college grad; post graduate
		educat = cut( eeducate1 , c( 30 , 38 , 39 , 40 , 42 , 43 , Inf ) )
)


# you can quickly and easily check your work with ftable()
# the following three commands print all of the 'before' and 'after' variables to the screen
# using r's flat table function.  neat.

# eorigin1 and erace1 were recoded into raceeth:
ftable( y[ , c( 'eorigin1' , 'erace1' , 'raceeth' ) ] , exclude = NULL )

# tage1 was recoded into agecat:
ftable( y[ , c( 'tage1' , 'agecat' ) ] , exclude = NULL )

# eeducate1 was recoded into educat:
ftable( y[ , c( 'eeducate1' , 'educat' ) ] , exclude = NULL )

	
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


# in 2010, the 'lgtcy2wt' variable was numeric but had not previously been divided by 10,000
# so run the dbtt() function on that column as well
y[ , mainwgt ] <- dbtt( y[ , mainwgt ] )


# look at the first six records
head( y )


#############################################################
# survey design for replicate weights with fay's adjustment #

# print the number of rows
nrow( y )

# subset the data table to exclude individuals with missing weights
y <- y[ !is.na( y[ , mainwgt ] ) , ]

# print the number of rows
nrow( y )

# subset the data table to exclude individuals with zero weights
y <- y[ y[ , mainwgt ] > 0 , ]

# print the number of rows
nrow( y )


# create a survey design object with SIPP design information
z <- 
	svrepdesign ( 
		data = y ,
		repweights = "repwgt[1-9]" , 
		type = "Fay" , 
		combined.weights = T , 
		rho = ( 1 - 1 / sqrt( 4 ) ) ,
		weights = y[ , mainwgt ]
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
# save( z , file = "sipp08.calendar.year.design.rda" )
# or, to save to another directory, specify the entire filepath
# save( z , file = "C:/My Directory/sipp08.calendar.year.design.rda" )

# at a later time, z can be re-accessed with the load() function
# (just make sure the current working directory has been set to the same place)
# load( "sipp08.calendar.year.design.rda" )
# or, if you don't set the working directory, just specify the full filepath
# load( "C:/My Directory/sipp08.calendar.year.design.rda" )


# also note: multiple objects can be saved inside a single R data file (.rda)
# save( y , z , file = "sipp08.calendar.year.df.and.design.rda" )

# at this point, if you close R, open it again, reset the working directory,
# load( "sipp08.calendar.year.df.and.design.rda" )
# will bring back both y and z objects
	

#####################
# analysis examples #

# note: these results do not match the published results exactly because of topcoding:
# census bureau publications of sipp data use a different file than the
# publicly-available one, contains topcoded income and assets variables.
# for more detail about the topcoding process, see the 'confidentiality' section on
# pdf page 19 of http://www.census.gov/sipp/usrguide/chap4rev2009.pdf

# note: topcoding heavily affects mean income and asset variables,
# but only marginally affects median income and asset variables.
# therefore, only median income and earnings values are presented below


# create a subset of the original survey design
# that only includes individuals aged 15+ in *january* of the current year
z.15p <- subset( z , tage1 > 14 )
# note: this differs slightly from setting the subset as:
# z.15p <- subset( z , tage12 > 14 )
# which only excludes individuals who were still 14 in december
# (as opposed to january) of the current analysis year.


# subset the current design even further, throwing out all records with nonpositive annual income
z.15p.winc <- subset( z.15p , anninc > 0 )

# subset the current design even further, throwing out all records with nonpositive first quarter earnings
z.15p.wearn <- subset( z.15p , q1earn > 0 )



# closely replicate excel columns d & e of the annual 2010 income table:
# http://www.census.gov/sipp/tables/quarterly-est/income/2010/annual/table1A.xls

# calculate the total number of individuals aged 15+ with positive annual income
svytotal( ~one , z.15p.winc )

# overall median with standard error
svyquantile( 
	~anninc , 
	design = z.15p.winc ,
	quantiles = 0.5 ,
	na.rm = TRUE
)

# to run multiple analyses over and over again,
# analysts could either run each 'by' variable alone, like this:

# by sex
svyby( 
	~anninc , 
	# choose the grouping variable
	by = ~esex1 ,
	# specify the same survey design
	design = z.15p.winc ,
	# run the svyquantile() function across groups
	FUN = svyquantile ,
	# calculate the median (the 50th percentile)
	quantiles = 0.5 ,
	# remove missing values
	na.rm = TRUE
)


# ..or create a function..

# this line initiates a function called sipp.median.by()
sipp.median.by <-
	# which requires two inputs: the variable to calculate the median of, and the variable to group by
	function( xvar , byvar , design ){
	
		# this function just does one thing: run the same svyby() command above,
		# keeping the design, the quantiles, and the na.rm parameter constant
		# while allowing the user to vary the actual analysis variable and the grouping variable
	
		# some variable by some other grouping variable
		svyby( 
			xvar , 
			# choose the grouping variable
			by = byvar ,
			# specify the same survey design
			design ,
			# run the svyquantile() function across groups
			FUN = svyquantile ,
			# calculate the median (the 50th percentile)
			quantiles = 0.5 ,
			# remove missing values
			na.rm = TRUE
		)
	}

# now that the sipp.median.by() function has been initiated,
# re-run annual income by sex
sipp.median.by( ~anninc , ~esex1 , z.15p.winc )
# same result!

# re-run the function by race/ethnicity (note: this calculates white non-hispanic)
sipp.median.by( ~anninc , ~raceeth , z.15p.winc )
# to calculate white (including hispanic), use:
sipp.median.by( ~anninc , ~( erace1 == 1 ) , z.15p.winc )

# age category
sipp.median.by( ~anninc , ~agecat , z.15p.winc )

# marital status
sipp.median.by( ~anninc , ~ems1 , z.15p.winc )

# educational attainment
sipp.median.by( ~anninc , ~educat , z.15p.winc )

# since the 'one' variable has been created (and has a value of '1' for every record),
# the sipp.median.by() function can also calculate the overall median income - ignoring groups
sipp.median.by( ~anninc , ~one , z.15p.winc )


# closely replicate excel columns d & e of the monthly 2010 income table:
# http://www.census.gov/sipp/tables/quarterly-est/income/2010/annual/table1B.xls

sipp.median.by( ~moninc , ~one , z.15p.winc )
sipp.median.by( ~moninc , ~esex1 , z.15p.winc )
sipp.median.by( ~anninc , ~( erace1 == 1 ) , z.15p.winc )
sipp.median.by( ~moninc , ~raceeth , z.15p.winc )
sipp.median.by( ~moninc , ~agecat , z.15p.winc )
sipp.median.by( ~moninc , ~ems1 , z.15p.winc )
sipp.median.by( ~moninc , ~educat , z.15p.winc )


# closely replicate excel columns d & e of the first quarter of 2010 earnings table:
# http://www.census.gov/sipp/tables/quarterly-est/earnings/2010/1-qtr/table2A.xls

# calculate the total number of individuals aged 15+ with positive first quarter earnings
svytotal( ~one , z.15p.wearn )

sipp.median.by( ~q1earn , ~one , z.15p.wearn )
sipp.median.by( ~q1earn , ~esex1 , z.15p.wearn )
sipp.median.by( ~q1earn , ~( erace1 == 1 ) , z.15p.wearn )
sipp.median.by( ~q1earn , ~raceeth , z.15p.wearn )
sipp.median.by( ~q1earn , ~agecat , z.15p.wearn )
sipp.median.by( ~q1earn , ~ems1 , z.15p.wearn )
sipp.median.by( ~q1earn , ~educat , z.15p.wearn )


# 95% confidence interval for first quarter earnings
confint( sipp.median.by( ~q1earn , ~one , z.15p.wearn ) )

# 90% confidence interval for never-married
confint( sipp.median.by( ~q1earn , ~one , z.15p.wearn ) , level = 0.9 )


# note: these analysis examples are intentionally sparse
# (to focus attention on the data manipulation part, which is much harder in sipp)
# once the replicate-weighted survey design object has been created,
# any of the features described on http://r-survey.r-forge.r-project.org/survey/ can be used.
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
