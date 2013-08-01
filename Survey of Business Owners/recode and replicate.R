# analyze survey data for free (http://asdfree.com) with the r language
# survey of business owners
# 2007

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




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###########################################################################################################
# prior to running this analysis script, the sbo 2007 file must be loaded as a database (.db) on the      #
# local machine.  running the 2007 download all microdata script will create this database file.          #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/usgsd/master/Survey%20of%20Business%20Owners/download%20and%20import.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "sbo07.db" with 'y' in C:/My Directory/SBO or wherever you put it.       #
###########################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


#############################################################################################################################################
# this script matches the results of the SAS code sent to me by the superstar Annie Leung at the united states census bureau.  thanx a zil. #
# email: https://github.com/ajdamico/usgsd/blob/master/Survey%20of%20Business%20Owners/census%20emails%20regarding%20SBO%20PUMS.pdf         #
#   csv: https://github.com/ajdamico/usgsd/blob/master/Survey%20of%20Business%20Owners/PUMS_MIN_FINAL.CSV                                   #
#  code: https://github.com/ajdamico/usgsd/blob/master/Survey%20of%20Business%20Owners/pums%20code.sas                                      #
#############################################################################################################################################


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/SBO/" )
# ..in order to set your current working directory

# name the database (.db) file that should have been saved in the working directory
sbo.dbname <- "sbo07.db"

require(RSQLite) 			# load RSQLite package (creates database files in R)
require(RSQLite.extfuns) 	# load RSQLite package (allows mathematical functions, like SQRT)
require(mitools) 			# load mitools package (analyzes multiply-imputed data)
require(survey) 			# load survey package (analyzes complex design surveys)
require(downloader)			# downloads and then runs the source() function on scripts from github


# load pnad-specific functions (a specially-designed series of multiply-imputed, hybrid-survey-object setup to match the census bureau's tech docs)
source_url( "https://raw.github.com/ajdamico/usgsd/master/Survey%20of%20Business%20Owners/sbosvy%20functions.R" , prompt = FALSE )


# set R to produce conservative standard errors instead of crashing
# http://faculty.washington.edu/tlumley/survey/exmample-lonely.html
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




###############################################################
# step 1: connect to the pnad data table you'd like to recode # 
# then make a copy so you don't lose the pristine original.   #

# the command 
db <- dbConnect( SQLite() , sbo.dbname )
# connects the current instance of r to the sqlite database

# load the mathematical functions in the r package RSQLite.extfuns
init_extensions(db)

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

# add a new numeric column to the data table `x` called `pct_minority`
dbSendQuery( db , 'ALTER TABLE x ADD COLUMN pct_minority DOUBLE PRECISION' )

# fill it full of zeroes
dbSendQuery( db , 'UPDATE x SET pct_minority = 0' )

# loop through the numbers 1 - 4
for ( i in 1:4 ){

	# build a character string, storing it in an object called `where.clause`
	where.clause <-
		# paste together..
		paste0(
			# paste together..
			paste0( 
					# CHARINDEX with B thru S.
					"CHARINDEX( " , 
					c( "'B'" , "'A'" , "'I'" , "'P'" , "'S'" ) ,
					" , race" ,
					i ,
					" )" ,
					# collapsed by OR statements
					collapse = " OR "
				) ,
			# appended with a separate OR CHARINDEX command..
			" OR CHARINDEX( 'H' , eth" ,
			i ,
			" )"
		)
	
	# look at what you've done!
	print( where.clause )
	
	# send a sql command to your database that..
	dbSendQuery( 
		db ,
		paste0(
			# ..updates all rows where the `where.clause` is true,
			# adding pct_minority to the current `pct#` column
			"UPDATE x SET pct_minority = pct_minority + pct" ,
			i , 
			" WHERE " , 
			where.clause
		)
	)

	# end uh dah loop.
}

# add a new character column called `tab` to the `x` data table
dbSendQuery( db , 'ALTER TABLE x ADD COLUMN tab VARCHAR(255)' )

# any business owned by less than half minorities is an `N`
dbSendQuery( db , "UPDATE x SET tab = 'N' WHERE pct_minority < 50" )

# any business exactly half-owned by minorities is an `E`
dbSendQuery( db , "UPDATE x SET tab = 'E' WHERE pct_minority = 50" )

# majority-minority-owned businesses are coded as `M` in the `tab` column.
dbSendQuery( db , "UPDATE x SET tab = 'M' WHERE pct_minority > 50" )


# boom.  done recoding.

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


# run a single MIcombine() function
# outside a single with() function
# outside a single svyby() function
b <- MIcombine( with( sbo.svy , svyby( ~tab , ~fipst , svytotal ) ) )
# that counts the number of minority-owned businesses, by state

# print the result of the call..
b

# extract the statistics..
coef( b )

# ..or the standard errors..
SE( b )

# ..or even the relative standard errors
cv( b )

# ..or hey, merge 'em all together into a single data.frame
out <-
	data.frame(
		TABWGT = coef( b ) ,
		UNADJ_VAR = diag( vcov( b ) ) / 1.992065 ,
		ADJ_VAR = diag( vcov( b ) ) ,
		RSE = round( cv( b ) * 100 )
	)

# extract the state code, and instantly convert it to a number
out$fipst <- as.numeric( lapply( strsplit( rownames( out ) , ':' ) , "[[" , 1 ) )

# extract the `tab` variable
out$tab <- lapply( strsplit( rownames( out ) , ':' ) , "[[" , 2 )

# delete the rownames, since they're annoying and no longer helpful
rownames( out ) <- NULL

# sort the tabs by state
out <- out[ order( out$fipst ) , ]
	
# that matches the `PUMS_MIN_FINAL.CSV` file precisely.

# and that is a beautiful thing.

	
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
