# analyze brazilian government survey data with the r language
# pesquisa nacional por amostra de domicilios
# 2011

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
# important note about why these statistics and standard errors do not precisely match the table packages #
stop( "fix this link" )
# the brazilian institute of statistics recently modified their methodology to use post-stratification    #
# so the final results from this script will be very close but not precisely exact. however, you can view #
# the replication script in this directory which explains how these statistics *do* precisely match some  #
# statistics, standard errors, and coefficients of variation provided to me by the friendly folks at IBGE #
# in other words, the analysis methods described in this script are methodologically justified and can    #
# safely be viewed as the correct way of doing things.  these analysis examples are right.  IBGE said so. #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################################################
# prior to running this analysis script, the pnad 2011 file must be loaded as a database (.db) on the local machine.                                #
# running the 2011 download all microdata script will create this database file                                                                     #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/usgsd/blob/master/Pesquisa%20Nacional%20por%20Amostra%20de%20Domicilios/2001-2011%20-%20download%20all%20microdata.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "pnad.db" with 'pnad2011' in C:/My Directory/PNAD or wherever the working directory was set                        #
#####################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# set your working directory.
# the PNAD 2001 - 2011 data files will be stored here
# after downloading and importing them.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PNAD/" )
# ..in order to set your current working directory


# name the database (.db) file to be saved in the working directory
pnad.dbname <- "pnad.db"

require(downloader)	# downloads and then runs the source() function on scripts from github
require(survey)		# load survey package (analyzes complex design surveys)
require(RSQLite) 	# load RSQLite package (creates database files in R)

# set R to produce conservative standard errors instead of crashing
# http://faculty.washington.edu/tlumley/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN

# load pnad-specific functions (to remove invalid SAS input script fields and postStratify a database-backed survey object)
source_url( "https://raw.github.com/ajdamico/usgsd/master/Pesquisa Nacional por Amostra de Domicilios/pnad.survey.R" )


##############################################
# survey design for a database-backed object #
##############################################

# create survey design object with PNAD design information
# using existing data frame of PNAD data
unstratified.pnad <-
	svydesign(
		id = ~v4618 ,
		strata = ~v4617 ,
		data = "p2011" ,
		weights = ~v4610 ,
		nest = TRUE ,
		dbtype = "SQLite" ,
		dbname = "pnad.db"
	)
# note that the above object has been given the unwieldy name of `unstratified.pnad`
# so that it's not accidentally used in analysis commands.
# this object has not yet been appropriately post-stratified, as necessitated by IBGE
# in order to accurately match the brazilian 2010 census
	
# this block conducts a post-stratification on the un-post-stratified design
# and since the R `survey` package's ?postStratify currently does not work on database-backed survey objects,
# this uses a function custom-built for the PNAD.
y <- 
	pnad.postStratify( 
		design = unstratified.pnad ,
		strata.col = 'v4609' ,
		oldwgt = 'v4610'
	)


	
#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in cps #
# broken out by employment status #

svyby(
	~moop ,
	~workyn ,
	y ,
	unwtd.count
)



# count the weighted number of individuals in cps #

# the civilian, non-institutionalized population of the united states #
svytotal(
	~one ,
	y
)

# note that this is exactly equivalent to summing up the weight variable
# from the original cps data frame

db <- dbConnect( SQLite() , "cps.asec.db" )			# connect to the SQLite database (.db)
dbGetQuery( db , 'select sum( marsupwt ) from asec12' )	# run a single query, summing the person-weight
dbDisconnect( db )									# disconnect from the database


# the civilian, non-institutionalized population of the united states #
# by employment status
svyby(
	~one ,
	~workyn ,
	y ,
	svytotal
)


# calculate the mean of a linear variable #

# average out-of-pocket medical expenditure - nationwide (includes over-the-counter)
svymean(
	~moop ,
	design = y
)

# by employment status
svyby(
	~moop ,
	~workyn ,
	design = y ,
	svymean
)


# calculate the distribution of a categorical variable #

# A-MARITL should be treated as a factor (categorical) variable
# instead of a numeric (linear) variable
# this update statement converts it.
# the svyby command below will not run without this
y <-
	update(
		a_maritl = factor( a_maritl ) ,
		y
	)


# percent married - nationwide
svymean(
	~a_maritl ,
	design = y
)

# by employment status
svyby(
	~a_maritl ,
	~workyn ,
	design = y ,
	svymean
)

# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum
# out-of-pocket medical expenditure in the united states (includes over-the-counter)
svyquantile(
	~moop ,
	design = y ,
	c( 0 , .25 , .5 , .75 , 1 )
)

# by employment status
svyby(
	~moop ,
	~workyn ,
	design = y ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	ci = T
)

######################
# subsetting example #
######################

# restrict the y object to
# females only
y.female <-
	subset(
		y ,
		a_sex %in% 2
	)
# now any of the above commands can be re-run
# using y.female object
# instead of the y object
# in order to analyze females only

# calculate the mean of a linear variable #

# average out-of-pocket medical expenditure - nationwide, restricted to females
svymean(
	~moop ,
	design = y
)



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by employment status

# store the results into a new object

marital.status.by.employment <-
	svyby(
		~a_maritl ,
		~workyn ,
		design = y ,
		svymean
	)

# print the results to the screen
marital.status.by.employment

# now you have the results saved into a new object of type "svyby"
class( marital.status.by.employment )

# print only the statistics (coefficients) to the screen
coef( marital.status.by.employment )

# print only the standard errors to the screen
SE( marital.status.by.employment )

# this object can be coerced (converted) to a data frame..
marital.status.by.employment <- data.frame( marital.status.by.employment )

# ..and then immediately exported as a comma-separated value file
# into your current working directory
write.csv( marital.status.by.employment , "marital status by employment.csv" )

# ..or trimmed to only contain the values you need.
# here's the "married - spouse present" rate by employment status,
# with accompanying standard errors
# keeping only the second and third rows (since the first row contains minors)
married.sp.by.employment <-
	marital.status.by.employment[ 2:3 , c( "workyn" , "a_maritl1" , "se1" ) ]


# print the new results to the screen
married.sp.by.employment

# this can also be exported as a comma-separated value file
# into your current working directory
write.csv( married.sp.by.employment , "married sp by employment.csv" )

# ..or directly made into a bar plot
barplot(
	married.sp.by.employment[ , 2 ] ,
	main = "Married (SP) by Employment Status" ,
	names.arg = c( "Employed" , "Not Employed" ) ,
	ylim = c( 0 , .6 )
)

# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
