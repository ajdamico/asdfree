# analyze survey data for free (http://asdfree.com) with the r language
# consumer expenditure survey
# replication of the output of various macros stored in the "CE macros.sas" example program
# using 2011 public use microdata

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/CES/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Consumer%20Expenditure%20Survey/2011%20fmly%20intrvw%20-%20analysis%20examples.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# this r script will review the example analyses of both imputed and non-imputed variables
# described in the "CE macros program documentation.doc" document
# in the folder "Programs 2011\SAS\" inside the bls documentation file
# ftp://ftp.bls.gov/pub/special.requests/ce/pumd/documentation/documentation11.zip


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



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###################################################################################################################
# prior to running this replication script, all ces 2011 public use microdata files must be loaded as R data      #
# files (.rda) on the local machine. running the "2010-2011 ces - download.R" script will create these files.     #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/usgsd/blob/master/Consumer%20Expenditure%20Survey/2010-2011%20ces%20-%20download.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will save a number of .rda files in C:/My Directory/CES/2011/ (or the working directory was chosen) #
###################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# set your working directory.
# the CES 2011 R data files (.rda) should have been
# stored in a year-specific directory within this folder.
# so if the file "fmli111x.rda" exists in the directory "C:/My Directory/CES/2011/intrvw/" 
# then the working directory should be set to "C:/My Directory/CES/"
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/CES/" )
# ..in order to set your current working directory



# turn off scientific notation in most output

options( scipen = 20 )


# remove the # in order to run this install.packages line only once
# install.packages( c( "RSQLite" , "mitools" , "stringr" , "plyr" , "survey" , "downloader" ) )


library(RSQLite) 	# load RSQLite package (creates database files in R)
library(mitools)	# allows analysis of multiply-imputed survey data
library(stringr) 	# load stringr package (manipulates character strings easily)
library(plyr)		# contains the rbind.fill() function, which stacks two data frames even if they don't contain the same columns.  the rbind() function does not do this
library(survey)		# load survey package (analyzes complex design surveys)
library(downloader)	# downloads and then runs the source() function on scripts from github


# load two svyttest functions (one to conduct a df-adjusted t-test and one to conduct a multiply-imputed t-test)
source_url( "https://raw.github.com/ajdamico/usgsd/master/Consumer%20Expenditure%20Survey/ces.svyttest.R" , prompt = FALSE )
# now that these two functions have been loaded into r, you can view their source code by uncommenting the two lines below
# svyttest.df
# svyttest.mi


# set this number to the year you would like to analyze..
year <- 2011

# choose a database name to be saved in the year-specific working directory.  this defaults to 
# "ces.fmly.####.db" but can be changed by replacing the paste() function with any character string ending in '.db'
db.name <- paste( "ces.fmly" , year , "db" , sep = "." )

# r will now take the year you've selected and re-assign the current working directory
# to the year-specific folder based on what you'd set above
# so if you'd set C:/My Directory/CES/ above, it's now been changed to C:/My Directory/CES/2011/
setwd( paste( getwd() , year , sep = "/" ) )

# pull the last two digits of the year variable into a separate string
yr <- substr( year , 3 , 4 )


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# read in the five quarters of family data files (fmli)

# load all five R data files (.rda)
load( paste0( "./intrvw/fmli" , yr , "1x.rda" ) )
load( paste0( "./intrvw/fmli" , yr , "2.rda" ) )
load( paste0( "./intrvw/fmli" , yr , "3.rda" ) )
load( paste0( "./intrvw/fmli" , yr , "4.rda" ) )
load( paste0( "./intrvw/fmli" , as.numeric( yr ) + 1 , "1.rda" ) )

# save the first quarter's data frame into a new data frame called 'fmly'
fmly <- get( paste0( "fmli" , yr , "1x" ) )

# and create a new column called 'qtr' with all ones
fmly$qtr <- 1

# loop through the second, third, and fourth fmli data frames
for ( i in 2:4 ){

	# copy each quarter into a new data frame called 'x'
	x <- get( paste0( "fmli" , yr , i ) )

	# add a quarter variable (2, 3, then 4)
	x$qtr <- i
	
	# stack 'x' below what's already in the fmly data table
	# ..this stacks quarters 2, 3, and 4 below quarter 1
	fmly <- rbind.fill( fmly , x )
}

# repeat the steps above on the fifth quarter (which uses the following year's first quarter of data)
x <- get( paste0( "fmli" , as.numeric( yr ) + 1 , "1" ) )
x$qtr <- 5

# final stacking of the fifth quarter
fmly <- rbind.fill( fmly , x )
# now the 'fmly' data table contains everything needed for analyses

# delete the temporary data frame from memory
rm( x )

# also delete the data frames loaded by the five load() function calls above
rm( 
	list = 
		c( 
			paste0( "fmli" , yr , "1x" ) , 
			paste0( "fmli" , yr , 2:4 ) ,
			paste0( "fmli" , as.numeric( yr ) + 1 , "1" )
		)
)

# clear up RAM
gc()


# create a character vector containing 45 variable names (wtrep01, wtrep02, ... wtrep44 and finlwt21)
wtrep <- c( paste0( "wtrep" , str_pad( 1:44 , 2 , pad = "0" ) ) , "finlwt21" )

# immediately loop through each weight column (stored in the wtrep vector)
# and overwrite all missing values (NA) with zeroes
for ( i in wtrep ) fmly[ is.na( fmly[ , i ] ) , i ] <- 0

# create a new variable in the fmly data table called 'totalexp'
# that contains the sum of the total expenditure from the current and previous quarters
fmly$totalexp <- rowSums( fmly[ , c( "totexppq" , "totexpcq" ) ] , na.rm = TRUE )

# immediately convert missing values (NA) to zeroes
fmly[ is.na( fmly$totalexp ) , "totalexp" ] <- 0

# annualize the total expenditure by multiplying the total expenditure by four,
# creating a new variable 'annexp' in the fmly data table
fmly <- transform( fmly , annexp = totalexp * 4 )


# the "CE macros.sas" file creates estimates that match the mse = TRUE option set here.
# in order to match the sas software provided by the bureau of labor statistics, keep this set to TRUE

# if this option is set to TRUE
# R will exactly match SUDAAN results and Stata with the MSE option results
options( survey.replicates.mse = TRUE )
# otherwise if it is commented out or set to FALSE
# R will exactly match Stata without the MSE option results

# Stata svyset command notes can be found here: http://www.stata.com/help.cgi?svyset


# add a column called 'one' to the fmly data table containing 1s throughout
fmly$one <- 1


# create the survey design as a balanced repeated replication survey object, 
# with 44 replicate weights
fmly.design <- 
	svrepdesign( 
		repweights = "wtrep[0-9]+" , 
		weights = ~finlwt21 , 
		data = fmly 
	)

# after its creation, explore these attributes by typing the object into the console..
# print a basic description of the replicate design
fmly.design

# print the available attributes of this object
attributes( fmly.design )

# access one of the attributes.. hey how about the degrees of freedom?
fmly.design$degf


#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in fmly #
unwtd.count( 
	~one , 
	fmly.design 
)

# broken out by the urban/rural variable #
svyby(
	~one ,
	~bls_urbn ,
	fmly.design ,
	unwtd.count
)


# calculate the mean of a linear variable #

# average annual household expenditure - nationwide
svymean(
	~annexp ,
	design = fmly.design
)

# by urban/rural
svyby(
	~annexp ,
	~bls_urbn ,
	design = fmly.design ,
	svymean
)


# calculate the distribution of a categorical variable #

# sex_ref should be treated as a factor (categorical) variable
# instead of a numeric (linear) variable
# this update statement converts it.
# the svyby command below will not run without this
fmly.design <-
	update(
		sex_ref = factor( sex_ref ) ,
		fmly.design
	)


# percent of households headed by males vs. females - nationwide
svymean(
	~sex_ref ,
	design = fmly.design
)


# by urban/rural
svyby(
	~sex_ref ,
	~bls_urbn ,
	design = fmly.design ,
	svymean
)


# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum
# annual expenditure in the united states
svyquantile(
	~annexp ,
	design = fmly.design ,
	c( 0 , .25 , .5 , .75 , 1 )
)


# by urban/rural
svyby(
	~annexp ,
	~bls_urbn ,
	design = fmly.design ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	ci = T
)


######################
# subsetting example #
######################

# restrict the fmly.design object to
# households headed by females only
fmly.female <-
	subset(
		fmly.design ,
		sex_ref %in% 2
	)
# now any of the above commands can be re-run
# using fmly.female object
# instead of the fmly.design object
# in order to analyze households headed by females only

# calculate the mean of a linear variable #

# average household expenditure - nationwide, 
# restricted to households headed by females
svymean(
	~annexp ,
	design = fmly.female
)

# remove this subset design to clear up memory
rm( fmly.female )

# clear up RAM
gc()


######################################
# CE macros.sas replication examples #
######################################

# replicate the first macro shown in the "CE macros program documentation.doc" document

# the example macro (seen on page 7) looks like this, without the comments (#)
	# %MEAN_VARIANCE(DSN = FMLY, 
		# FORMAT = BLS_URBN $URBN.,
		# USE_WEIGHTS = YES,
		# BYVARS = BLS_URBN, 
		# ANALVARS = ANNEXP FINCBTXM, 
		# IMPUTED_VARS = FINCBTX1-FINCBTX5,
		# CL = 99, 
		# DF = RUBIN87,
		# TITLE1 = COMPUTING MEANS AND VARIANCES,
		# TITLE2 = VARIABLES FROM THE FAMILY FILE,
		# TITLE3 = ,
		# XOUTPUT = 
	# ); 

# instead of exporting all of these results into a large text output (like sas does)
# the following steps will produce each of the components, one at a time


# count the total (unweighted) number of records in fmly #
# broken out by the urban/rural variable, as specified in the sas macro call above
svyby( ~one , ~bls_urbn , fmly.design , unwtd.count )


# calculate means and standard errors, and save the results into a new object
# but also print the results to the screen.

# r hint: when assigning ( <- ) an object to another object, you can print the object to the screen
# at the same time as assigning ( <- ) it by encasing it in parentheses

# note that the following commands use svyby() outside of a svymean call
# as opposed to svymean() alone, because the results need to be broken out by
# the bls_urbn variable, as specified in the sas macro call above

# print and save the mean and standard error
( ae <- svyby( ~annexp , ~bls_urbn , fmly.design , svymean , na.rm = TRUE ) )
( fi <- svyby( ~fincbtxm , ~bls_urbn , fmly.design , svymean , na.rm = TRUE ) )

# the mean and standard error can now be accessed by typing the objects directly..
ae		# annualized expenditure (from the 'annexp' created by this script)
fi		# consumer unit income before taxes in the past twelve months (seen on pdf page 27 of the "Interview Data Dictionary.pdf")

# use the SE() function to access only the standard errors of both objects
# the variance is simply the standard error squared
SE( ae )^2
SE( fi )^2


# the relative standard error is the standard error divided by the statistic itself
# which can be accessed using the coef() function on the survey object
( SE( ae ) / coef( ae ) ) * 100
( SE( fi ) / coef( fi ) ) * 100


# compute the confidence intervals around each of these statistics
# note these are the 99% confidence intervals, as specified by the sas macro call above
# confidence intervals
confint( ae , level = 0.99 , df = degf( fmly.design ) + 1 )
confint( fi , level = 0.99 , df = degf( fmly.design ) + 1 )



# replicate the second macro shown in the "CE macros program documentation.doc" document

# the example macro (seen on page 8) looks like this, without the comments (#)

	# /* COMPARE MEANS BY VARIABLE BLS_URBN */
	# %COMPARE_GROUPS(GPS = 1 2,
		# TITLE1 = ,
		# TITLE2 = ,
		# TITLE3 = 
	# );

# this macro simply runs a two-sided t-test on a linear variable across any other binary variable
# so, for example, these two svyttest.df() calls answer the questions:

# is the difference in annual household expenditure between urban and rural homes statistically significant?
svyttest.df( annexp ~ factor( bls_urbn ) , fmly.design , df = 45 )		# yes

# is the difference in before-tax income between urban and rural homes statistically significant?
svyttest.df( fincbtxm ~ factor( bls_urbn ) , fmly.design , df = 45 )	# yes again
# note: this fincbtxm is not the multiply-imputed version, so
# this test will not have the correct standard errors and confidence intervals.
# to do it right, use the example in the multiple imputation section below


# note that the svyttest.df() function above does not come with the dr. lumley's survey package
# this function was specifically written for the consumer expenditure survey and downloaded near the top of this here script
# for more detail about the regular svyttest function, load the survey package and type ?svyttest into the console


# # # # # # # # # # # # # # # # # #
# multiple imputation preparation #
# # # # # # # # # # # # # # # # # #

# note that %MEAN_VARIANCE macro above also contains a line "IMPUTED_VARS = FINCBTX1-FINCBTX5" denoting an analysis of these five multiply-imputed variables
# in order to analyze all multiply-imputed variables efficiently, this code will break the 'fmly' data table into five separate tables -- not to be confused with the five quarters.
# in table 1, the variable fincbtx1 will be saved as fincbtxmi.  
# in table 2, the variable fincbtx2 will be saved as fincbtxmi again...
# in table 5, the variable fincbtx5 will be saved as fincbtxmi
# this pattern (of variables ending with 'mi') will be repeated for each of the multiply-imputed columns in the fmly data table

# in order to conserve memory, these five tables will be stored in a sqlite database (.db) file on the local disk
# the storage location can be specified by the user near the top of this script.  the current storage location is:
paste( getwd() , db.name , sep = "/" )


# once these five distinct data tables have been saved within the sqlite database (.db),
# a new object class (an imputationList - type ?imputationList to read about it)
# will be used to analyze anything involving multiply-imputed variables quickly


# open the connection to a new sqlite database
db <- dbConnect( SQLite() , db.name )

# create a vector containing all of the multiply-imputed variables (leaving the numbers off the end)
mi.vars <- 
	c( 
		"pension" , "intearn" , "finincx" , "inclosa" , "inclosb" , 
		"unemplx" , "compens" , "welfare" , "chdothx" , "aliothx" , 
		"othrinc" , "foodsmp" , "fincbtx" , "fincatx" , "fsalary" ,
		"fnonfrm" , "ffrminc" , "frretir" , "fssix"
	)



# loop through each of the five variables..
for ( i in 1:5 ){

	# copy the 'fmly' table over to a new temporary data frame 'x'
	x <- fmly

	# loop through each of the multiply-imputed variables..
	for ( j in mi.vars ){
	
		# copy the contents of the current column (for example 'pension1')
		# over to a new column ending in 'mi' (for example 'pensionmi')
		x[ , paste0( j , 'mi' ) ] <- x[ , paste0( j , i ) ]
		
		# delete the all five of the imputed variable columns
		x <- x[ , !( names( x ) %in% paste0( j , 1:5 ) ) ]

	}
	
	# save the current table in the sqlite database as 'imp1' 'imp2' etc.
	dbWriteTable( db , paste0( 'imp' , i ) , x )

	# remove the temporary table
	rm( x )
	
	# clear up RAM
	gc()
}


# build a new balanced repeated replication survey design object,
# but unlike the 'fmly.design' object, this object pulls data from the sqlite database (.db)
# containing the five multiply-imputed data tables - imp1 through imp5
fmly.imp <- 
	svrepdesign( 
		weights = ~finlwt21 , 
		repweights = "wtrep[0-9]+" , 
		data = imputationList( datasets = as.list( paste0( 'imp' , 1:5 ) ) , dbtype = "SQLite" ) , 
		type = "BRR" ,
		combined.weights = TRUE , 
		dbname = db.name
	)

# this new fmly.imp can be used to do many of the same things as the fmly.design object
# main advantage: allows analysis of multiply-imputed variables (like these:)
mi.vars
# main disadvantage: requires code that's less intuitive for analysts familiar with the svymean( ~formula , design ) layout


# this object can also be examined by typing the name into the console..
fmly.imp

# ..or querying attributes directly
attributes( fmly.imp )


# fmly.imp is a weird critter.  it's actually five survey designs, mushed into one thing.
# when you run an analysis on the fmly.imp, you're actually running the same analysis
# on all five survey designs contained in the object -
# and then the MIcombine() function lumps them all together to give you the correct statistics and error terms


# oh hey look at the attributes of the first (of five) survey designs
attributes( fmly.imp[[1]][[1]] )
# examine the degrees of freedom of that first survey design
fmly.imp[[1]][[1]]$degf

# look at the attributes of the fifth (of five) data frames
attributes( fmly.imp[[1]][[5]] )
# examine the degrees of freedom
fmly.imp[[1]][[5]]$degf


# two analysis examples from the original fmly.design, replicated on fmly.imp --

# calculate the mean of a linear variable #

# average annual household expenditure - nationwide
MIcombine( 
	with( 
		fmly.imp , 
		svymean( ~annexp ) 
	) 
)

# minimum, 25th, 50th, 75th, maximum
# annual expenditure in the united states
# by urban/rural
MIcombine( 
	with( 
		fmly.imp , 
		svyby( 
			~annexp , 
			~bls_urbn , 
			svyquantile , 
			c( 0 , .25 , .5 , .75 , 1 ) , 
			ci = TRUE 
		) 
	) 
)


# note that the statistics and standard errors from both of these analysis commands exactly match
# the analysis commands run on the fmly.design earlier in the script.
# since they don't involve any multiply-imputed variables, they should match exactly.


# now actually analyze the multiply-imputed variable from the sas macro
# remember that fincbtx1 - fincbtx5 have all been renamed fincbtxmi,
# intentionally ending in 'mi' (multiply-imputed)

# calculate survey results
( fi <- MIcombine( with( fmly.imp , svyby( ~fincbtxmi , ~bls_urbn , svymean , na.rm = TRUE ) ) ) )

# mean and standard error
fi

# variance
SE( fi )^2

# rse (relative standard error)
( SE( fi ) / coef( fi ) ) * 100

# confidence intervals
confint( fi , level = 0.99 , df = degf( fi ) + 1 )


# replicate the second macro shown in the "CE macros program documentation.doc" document

# the example macro (seen on page 8) looks like this, without the comments (#)

	# /* COMPARE MEANS BY VARIABLE BLS_URBN */
	# %COMPARE_GROUPS(GPS = 1 2,
		# TITLE1 = ,
		# TITLE2 = ,
		# TITLE3 = 
	# );

# this macro simply runs a two-sided t-test on a linear variable across any other binary variable
# so, for example, this svyttest.mi() call answers the question:

# is the difference in before-tax income between urban and rural homes statistically significant?
svyttest.mi( fincbtxmi ~ factor( bls_urbn ) , fmly.imp )	# yes
# note: this fincbtxmi *is* the multiply-imputed version.
# this test now has the correct standard errors and confidence intervals
# use the svyttest.mi function and the fmly.imp survey design to test
# whether multiply-imputed variables differ across groups

# note that the svyttest.mi() function above does not come with the dr. lumley's survey package
# this function was specifically written for the consumer expenditure survey and downloaded near the top of this script
# for more detail about the regular svyttest function, load the survey package and type ?svyttest into the console



# # # # # # # # # # # # # # # # # # # # #
# regressions and logistic regressions  #
# # # # # # # # # # # # # # # # # # # # #


# from this point forward, analyses requiring multiply-imputed variables will use the "fmly.imp" design and all others will use the "fmly.design" design


# replicate example two on page ten of the "CE macros program documentation.doc" document

# the example macro looks like this, without the comments (#)

	# %PROC_REG(DSN = ALL, 
		# USE_WEIGHTS = yes,
		# DEP_VARS = X, 
		# IND_VARS = Y1 Y2
	# );

# here's the exact example:
# summary( svyglm( x ~ y1 + y2 , fmly.design ) )

# here's the relationship between (previous quarter + current quarter expenditure) and unimputed before-tax income
summary( svyglm( fincbtxm ~ totexppq + totexpcq , fmly.design ) )


# replicate example four on page ten of the "CE macros program documentation.doc" document

# the example macro looks like this, without the comments (#)

	# %PROC_REG(DSN = ALL, 
		# USE_WEIGHTS = Yes,
		# DEP_VARS = X, 
		# IND_VARS = Y1, 
		# IMPUTED_VARS = W1-W5 Z1-Z5
	# );

# here's the exact example:
# summary( MIcombine( with( fmly.imp , svyglm( x ~ y1 + wmi + zmi ) ) ) )

# here's the relationship between (current quarter expenditure + before-tax income) and previous quarter expenditure
# notice that before-tax income is a multiply-imputed variable in this analysis command
summary( MIcombine( with( fmly.imp , svyglm( totexppq ~ totexpcq + fincbtxmi ) ) ) )


# replicate example two on page twelve of the "CE macros program documentation.doc" document

# the example macro looks like this, without the comments (#)

	# %PROC_LOGISTIC(DSN = ALL, 
		# USE_WEIGHTS = YES,
		# DEP_VARS = X, 
		# IND_VARS = Y1 Y2 Y3
	# );

# here's the exact example:
# summary( svyglm( factor( x ) ~ y1 + y2 + y3 , fmly.design , family = quasibinomial()  ) )

# here's the relationship between (previous quarter + current quarter expenditure) and urban/rural status
summary( svyglm( factor( bls_urbn ) ~ totexppq + totexpcq , fmly.design , family = quasibinomial()  ) )


# replicate example four on page ten of the "CE macros program documentation.doc" document

# the example macro looks like this, without the comments (#)

	# %PROC_LOGISTIC(DSN = ALL, 
		# USE_WEIGHTS = yes,
		# DEP_VARS = X, 
		# IND_VARS = Y1 Y2 Y3,
		# IMPUTED_VARS = W1-W5 Z1 Z2 Z3 Z4 Z5
	# );

# here's the exact example:
# summary( MIcombine( with( fmly.imp , svyglm( x ~ y1 + y2 + y3 + wmi + zmi , family = quasibinomial() ) ) ) )

# here's the relationship between (current quarter expenditure + before-tax income) and urban/rural status
# notice that before-tax income is a multiply-imputed variable in this analysis command
summary( MIcombine( with( fmly.imp , svyglm( factor( bls_urbn ) ~ fincbtxmi + totexpcq , family = quasibinomial()  ) ) ) )


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
