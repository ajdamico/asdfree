# analyze survey data for free (http://asdfree.com) with the r language
# survey of business owners
# 2007

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/SBO/" )
# source_url( "https://raw.github.com/ajdamico/asdfree/master/Survey%20of%20Business%20Owners/2007%20single-year%20-%20analysis%20examples.R" , prompt = FALSE , echo = TRUE )
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




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###########################################################################################################
# prior to running this analysis script, the sbo 2007 file must be loaded as a database (.db) on the      #
# local machine.  running the 2007 download all microdata script will create this database file.          #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/asdfree/master/Survey%20of%20Business%20Owners/download%20and%20import.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "sbo07.db" with 'y' in C:/My Directory/SBO or wherever you put it.       #
###########################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/SBO/" )
# ..in order to set your current working directory

# name the database (.db) file that should have been saved in the working directory
sbo.dbname <- "sbo07.db"

library(RSQLite) 			# load RSQLite package (creates database files in R)
library(mitools) 			# load mitools package (analyzes multiply-imputed data)
library(survey) 			# load survey package (analyzes complex design surveys)
library(downloader)			# downloads and then runs the source() function on scripts from github


# unhappy with all the scientific notation in your output?
# uncomment this line to increase the scientific notation threshold
# options( scipen = 15 )


# load sbo-specific functions (a specially-designed series of multiply-imputed, hybrid-survey-object setup to match the census bureau's tech docs)
source_url( "https://raw.github.com/ajdamico/asdfree/master/Survey%20of%20Business%20Owners/sbosvy%20functions.R" , prompt = FALSE )


# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# note regarding sql commands and alternatives: the recodes below use basic commands from sql #
# this is necessary for computers with limited resources, since none of the data requires ram #
# if you'd prefer to read the entire dataset into ram instead, use the command                #
# x <- dbReadTable( db , 'y' )                                                                #
# or, to not overload RAM and get a subset of the columns in y, with survey variables         #
# x <- dbGetQuery( db , 'select race1 , eth1 , pct1 , ... from y' )                           #
# at which point, the `?transform` function can be used to make recodes on the `x` data.frame #
# but really, why bother?  i've done all the work for you as a db-backed object.  run w it.   #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #




##############################################################
# step 1: connect to the sbo data table you'd like to recode # 
# then make a copy so you don't lose the pristine original.  #

# the command 
db <- dbConnect( SQLite() , sbo.dbname )
# connects the current instance of r to the sqlite database

# load the mathematical functions in the r package RSQLite.extfuns
initExtension(db)

# now simply copy you'd like to recode into a new table
dbSendQuery( db , "CREATE TABLE x AS SELECT * FROM y" )
# this action protects the original 'y' table from any accidental errors.
# at any point, we can delete this recoded copy of the data table using the command..
# dbRemoveTable( db , "x" )
# ..and start fresh by re-copying the pristine file from y


# whether or not you are recoding,
# it's a grrrrrrrrreat idea to keep a pristine table `y`
# and do everything on a separate `x` table that you don't
# haveta worryabout screwin' up.  nice.


############################################
# step 2: make all of your recodes at once #

# from this point forward, all commands will only touch the
# 'x' table.  the 'y' is now off-limits.

# # # # # # # # # # #
# start of recoding #
# # # # # # # # # # #

# no recodes for me this time around.
# if you need examples of how to recode,
# check out the recode 'n' replication script
# https://raw.github.com/ajdamico/asdfree/master/Survey%20of%20Business%20Owners/recode%20and%20replicate.R


# # # # # # # # # #
# end of recoding #
# # # # # # # # # #

##############################################################################
# step 3: create the random groups tables, a kinda sorta multiple imputation #


# the survey of business owners uses this weird 'random groups' variable `rg`
# that's sorta kinda basically multiply-imputation, but not really.
# if you're ultra-curious and ultra-bored and ultra-smart, you can read more here
# http://www2.census.gov/econ/sbo/07/pums/2007_sbo_pums_users_guide.pdf#page=7

# loop through each of the ten random groups..
for ( i in 1:10 ){

	# send another sql command that..
	dbSendQuery( 
		db , 
		# ..creates a table `x1`  `x2`  `x3` .. up to .. `x10`
		paste0( 
			'CREATE TABLE x' , 
			i ,
			' AS SELECT * FROM x WHERE rg = ' ,
			i
		)
		# that only contains records where the column `rg` equals the current iteration
	)

}


# note! big note!
# you can delete these ten tables you just created easily,
# with this easy, easy, easy loop:
# for ( i in 1:10 ) dbRemoveTable( db , paste0( 'x' , i ) )
# of course it didn't run if you didn't uncomment it ;)


#############################################################################
# step 4: create a new survey design object connecting to the recoded table #

#####################################################
# survey design for a hybrid database-backed object #
#####################################################

# create a survey design object with the SBO design
# to use for the coefficients: means, medians, totals, etc.
sbo.coef <-
	svydesign(
		id = ~1 ,
		weight = ~tabwgt ,
		data = 'x' ,
		dbname = sbo.dbname ,
		dbtype = "SQLite"
	)
# this one just uses the original table `x`

# create a survey design object with the SBO design
# to use for the variance and standard error
sbo.var <-
	svydesign(
		id = ~1 ,
		weight = ~newwgt ,
		data = imputationList( datasets = as.list( paste0( 'x' , 1:10 ) ) ) ,
		dbname = sbo.dbname ,
		dbtype = "SQLite"
	)
# this one uses the ten `x1` thru `x10` tables you just made.


# slap 'em together into a single list object..
sbo.svy <- list( coef = sbo.coef , var = sbo.var )

# ..and name that list object a `sbosvyimputationList`
# so the correct survey methods (in sbosvy functions.R) get used.
class( sbo.svy ) <- 'sbosvyimputationList'

########################################################
# end of hybrid database-backed survey object creation #
########################################################


##############################################
# step 5: time for fun.  here's the analysis #

# count the total (unweighted) number of records in sbo #
# broken out by state #

# note big note-
# when using the `unwtd.count` function,
# simply use the `coef` object *within*
# the `sbo.svy` object.

# overall unweighted number of records
nrow( sbo.svy$coef )

# by state
svyby( ~one , ~fipst , sbo.svy$coef , unwtd.count )

# there's no need to run variances or standard errors
# on your unweighted counts of the data set.



# count the weighted number of businesses in sbo #

# the total number of non-publicly-owned establishments x industries x geographies
MIcombine( with( sbo.svy , svytotal( ~one ) ) )
# this matches "firms (number)" in the "all classifiable firms" row of
# http://www2.census.gov/econ/sbo/07/pums/2007_sbo_pums_users_guide.pdf#15

# by employer/non-employer
MIcombine( with( sbo.svy , svyby( ~one , ~n07_employer , svytotal ) ) )


# calculate the total of a linear variable #

# receipts
MIcombine( with( sbo.svy , svytotal( ~receipts_noisy ) ) )

# by employer/non-employer
MIcombine( with( sbo.svy , svyby( ~receipts_noisy , ~n07_employer , svytotal ) ) )


# calculate the distribution of a categorical variable #

# offer health insurance
MIcombine( with( sbo.svy , svymean( ~factor( healthins ) ) ) )

# by state
MIcombine( with( sbo.svy , svyby( ~factor( healthins ) , ~fipst , svymean ) ) )


# calculate the median and other percentiles #

# note for `svyquantile` calls within `MIcombine`
# you gotta use `svyby` with a `one` variable instead.

# minimum, 25th, 50th, 75th, maximum receipts
MIcombine( 
	with( 
		sbo.svy , 
		svyby( 
			~receipts_noisy , 
			~one ,
			svyquantile ,
			c( 0 , .25 , .5 , .75 , 1 ) ,
			ci = TRUE
		)
	)
)

# by number of business owners
MIcombine( 
	with( 
		sbo.svy , 
		svyby( 
			~receipts_noisy , 
			~numowners ,
			svyquantile ,
			c( 0 , .25 , .5 , .75 , 1 ) ,
			ci = TRUE
		)
	)
)

######################
# subsetting example #
######################

# restrict the y object to
# businesses established before the year 2000
sbo.pre.y2k <- subset( sbo.svy , established %in% c( 1 , 2 , 3 ) )
# now any of the above commands can be re-run
# using sbo.pre.y2k object
# instead of the sbo.svy object
# in order to analyze establishments x industries x geographies
# that were founded before 2000 AD

# calculate the mean of a linear variable #

# average payroll
MIcombine( with( sbo.pre.y2k , svymean( ~payroll_noisy ) ) )


###################
# export examples #
###################

# calculate the mean of a linear variable #
# by husband/wife operation

# store the results into a new object

receipts.by.husbwife <-
	MIcombine( 
		with( 
			sbo.svy , 
			svyby( 
				~receipts_noisy , 
				~husbwife , 
				svymean 
			) 
		) 
	)
	
# print the results to the screen
receipts.by.husbwife

# now you have the results saved into a new object of type "MIresult"
class( receipts.by.husbwife )

# print only the statistics (coefficients) to the screen
coef( receipts.by.husbwife )

# print only the standard errors to the screen
SE( receipts.by.husbwife )

# print only the coefficients of variation to the screen
cv( receipts.by.husbwife )

# this object can be coerced (converted) to a data frame..
receipts.by.husbwife <- 
	data.frame( 
		coef = coef( receipts.by.husbwife ) , 
		SE = SE( receipts.by.husbwife ) 
	)
# ..and then immediately exported as a comma-separated value file
# into your current working directory
write.csv( receipts.by.husbwife , "receipts by husband-wife run businesses.csv" )


# make 'em directly into a barplot
barplot(
	receipts.by.husbwife[ , 1 ] ,
	main = "Business Receipts by Husband-Wife Operation" ,
	names.arg = c( "Not Reported" , "Joint Husband-Wife" , "Primarily Husband" , "Primarily Wife" , "Not Husband-Wife" ) ,
	ylim = c( 0 , 700 )
)


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
