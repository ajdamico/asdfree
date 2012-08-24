# importation and analysis of us government survey data
# current population survey 
# annual social and economic supplement
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


#############################################################################################################
# this script matches the results of the SAS, SUDAAN, and WesVar code presented in                          #  
# http://smpbff2.dsd.census.gov/pub/cps/march/Use_of_the_Public_Use_Replicate_Weight_File_final_PR_2010.doc #
#############################################################################################################



##################################################################################################
# Analyze the 2011 Current Population Survey - Annual Social and Economic Supplement file with R #
##################################################################################################


# set your working directory.
# the CPS 2011 data files will be stored here
# after downloading and importing them.
# use forward slashes instead of back slashes

setwd( "C:/My Directory/CPS/" )


# remove the # in order to run this install.packages line only once
# install.packages( c( "survey" , "SAScii" ) )


require(survey)		# load survey package (analyzes complex design surveys)
require(SAScii) 	# load the SAScii package (imports ascii data with a SAS script)



# set R to produce conservative standard errors instead of crashing
# http://faculty.washington.edu/tlumley/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN



# if this option is set to TRUE
# R will exactly match SUDAAN results and Stata with the MSE option results
options( survey.replicates.mse = TRUE )
# otherwise if it is commented out or set to FALSE
# R will exactly match Stata without the MSE option results

# Stata svyset command notes can be found here: http://www.stata.com/help.cgi?svyset



###############################################
# DATA LOADING COMPONENT - ONLY RUN THIS ONCE #
###############################################

# # # # # # # # # # # #
# load the main file  #
# # # # # # # # # # # #

# this process is slow.
# the CPS ASEC 2011 file has 204,983 person-records.

# note: this CPS March Supplement ASCII (fixed-width file) contains household-, family-, and person-level records.

# census.gov website containing the current population survey's main file
CPS.ASEC.mar11.file.location <- 
	"http://smpbff2.dsd.census.gov/pub/cps/march/asec2011_pubuse.zip"

# national bureau of economic research website containing the current population survey's SAS import instructions
CPS.ASEC.mar11.SAS.read.in.instructions <- 
	"http://www.nber.org/data/progs/cps/cpsmar11.sas"

# create a temporary file and a temporary directory..
tf <- tempfile() ; td <- tempdir()

# download the CPS repwgts zipped file to the local computer
download.file( CPS.ASEC.mar11.file.location , tf , mode = "wb" )

# unzip the file's contents and store the file name within the temporary directory
fn <- unzip( tf , exdir = td , overwrite = T )

# create three more temporary files
# to store household-, family-, and person-level records
tf.household <- tempfile()
tf.family <- tempfile()
tf.person <- tempfile()

# create four file connections.

# one read-only file connection "r" - pointing to the ASCII file
incon <- file( fn , "r") 

# three write-only file connections "w" - pointing to the household, family, and person files
outcon.household <- file( tf.household , "w") 
outcon.family <- file( tf.family , "w") 
outcon.person <- file( tf.person , "w") 

# build a merge file at the same time as distributing the main file into three other files
xwalk <- xwalk.10k <- data.frame( NULL )

# start line counter #
line.num <- 0

# store the current scientific notation option..
cur.sp <- getOption( "scipen" )

# ..and change it
options( scipen = 10 )
	
# create a while-loop that continues until every line has been examined
# cycle through every line in the downloaded CPS ASEC 2011 file..

while( length( line <- readLines( incon , 1 ) ) > 0 ){

	# ..and if the first character is a 1, add it to the new household-only CPS file.
	if ( substr( line , 1 , 1 ) == "1" ){
		
		# write the line to the household file
		writeLines( line , outcon.household )
		
		# store the current unique household id
		curHH <- substr( line , 2 , 6 )
	
	}
	
	# ..and if the first character is a 2, add it to the new family-only CPS file.
	if ( substr( line , 1 , 1 ) == "2" ){
	
		# write the line to the family file
		writeLines( line , outcon.family )
		
		# store the current unique family id
		curFM <- substr( line , 7 , 8 )
	
	}
	
	# ..and if the first character is a 3, add it to the new person-only CPS file.
	if ( substr( line , 1 , 1 ) == "3" ){
		
		# write the line to the person file
		writeLines( line , outcon.person )
		
		# store the current unique person id
		curPN <- substr( line , 7 , 8 )
		
		# merge file creation #
		
		# ..and add the current unique household x family x person identifier values to the merge file
		xwalk.temp <- data.frame( h_seq = curHH , ffpos = curFM , pppos = curPN )
		
		# ..and also stack it at the bottom of the current xwalk.10k
		xwalk.10k <- rbind( xwalk.10k , xwalk.temp )
		
	}

	# add to the line counter #
	line.num <- line.num + 1

	# every 10k records..
	if ( line.num %% 10000 == 0 ) {
		
		# add the current xwalk.10k to the bottom of the total xwalk #
		xwalk <- rbind( xwalk , xwalk.10k )
		
		# blank out xwalk.10k #
		xwalk.10k <- NULL
		
		# clear up RAM
		gc()
		
		# print current progress to the screen #
		cat( "   " , prettyNum( line.num  , big.mark = "," ) , "of approximately 400,000 cps asec lines processed" , "\r" )
		
	}
}


# add the remaining xwalk.10k to the bottom of the total xwalk #
xwalk <- rbind( xwalk , xwalk.10k )

# blank out xwalk.10k #
xwalk.10k <- NULL

# clear up RAM
gc()

# convert all three xwalk columns to numeric
for ( i in 1:ncol( xwalk ) ) xwalk[ , i ] <- as.numeric( xwalk[ , i ] )

# restore the original scientific notation option
options( scipen = cur.sp )

# close all four file connections
close( outcon.household )
close( outcon.family )
close( outcon.person )
close( incon , add = T )

# the SAS file produced by the National Bureau of Economic Research (NBER)
# begins each INPUT block after lines 988, 1121, and 1209, 
# so skip SAS import instruction lines before that.
# NOTE that this 'beginline' parameters of 988, 1121, and 1209 will change for different years.

# store CPS ASEC march 2011 household records as an R data frame
cps.asec.mar11.household.df <- 
	read.SAScii ( 
		tf.household , 
		CPS.ASEC.mar11.SAS.read.in.instructions , 
		beginline = 988 , 
		zipped = F )

# store CPS ASEC march 2011 family records as an R data frame
cps.asec.mar11.family.df <- 
	read.SAScii ( 
		tf.family , 
		CPS.ASEC.mar11.SAS.read.in.instructions , 
		beginline = 1121 , 
		zipped = F )

# store CPS ASEC march 2011 person records as an R data frame
cps.asec.mar11.person.df <- 
	read.SAScii ( 
		tf.person , 
		CPS.ASEC.mar11.SAS.read.in.instructions , 
		beginline = 1209 , 
		zipped = F )


# convert all column names to lowercase #

names( cps.asec.mar11.household.df ) <-
	tolower( names( cps.asec.mar11.household.df ) )
	
names( cps.asec.mar11.family.df ) <-
	tolower( names( cps.asec.mar11.family.df ) ) 
	
names( cps.asec.mar11.person.df ) <-
	tolower( names( cps.asec.mar11.person.df ) ) 
	

# merge the crosswalk file with the household file

h.xwalk <- 
	merge(
		xwalk ,
		cps.asec.mar11.household.df 
	)

	
# merge the crosswalk + household file with the family file

h.f.xwalk <- 
	merge(
		h.xwalk ,
		cps.asec.mar11.family.df ,
		by.x = c( 'h_seq' , 'ffpos' ) ,
		by.y = c( 'fh_seq' , 'ffpos' )
	)

	
# merge the crosswalk + household + family file with the person file - this contains all three files #

cps.asec.2011.df <- 
	merge(
		h.f.xwalk ,
		cps.asec.mar11.person.df ,
		by.x = c( 'h_seq' , 'pppos' ) ,
		by.y = c( 'ph_seq' , 'pppos' )
	)
	

# confirm that the number of records in the 2011 cps asec merged file
# matches the number of records in the person file

if ( nrow( cps.asec.2011.df ) != nrow( cps.asec.mar11.person.df ) ) stop( "problem with merge - merged file should have the same number of records as the original person file" )

# remove unnecessary data frames from memory #
rm( cps.asec.mar11.household.df , cps.asec.mar11.family.df , cps.asec.mar11.person.df , h.xwalk , h.f.xwalk , xwalk )

# clear up RAM
gc()

# # # # # # # # # # # # # # # # # #
# load the replicate weight file  #
# # # # # # # # # # # # # # # # # #
		
# this process is also slow.
# the CPS ASEC 2011 replicate weight file has 204,983 person-records.

# census.gov website containing the current population survey's replicate weights file
CPS.replicate.weight.file.location <- 
	"http://smpbff2.dsd.census.gov/pub/cps/march/CPS_ASEC_ASCII_REPWGT_2011.zip"
	
# census.gov website containing the current population survey's SAS import instructions
CPS.replicate.weight.SAS.read.in.instructions <- 
	"http://smpbff2.dsd.census.gov/pub/cps/march/CPS_ASEC_ASCII_REPWGT_2011.SAS"

# store the CPS ASEC march 2011 replicate weight file as an R data frame
cps.repwgt.mar11.df <- 
	read.SAScii ( 
		CPS.replicate.weight.file.location , 
		CPS.replicate.weight.SAS.read.in.instructions , 
		zipped = T )

		
# convert all column names to lowercase #
		
names( cps.repwgt.mar11.df ) <-
	tolower( names( cps.repwgt.mar11.df ) ) 

	
# # # # # # # # # #
# save both files #
# # # # # # # # # #

# save both final data frames in a single ".rda" file #

save(
	cps.asec.2011.df ,
	cps.repwgt.mar11.df ,
	file = "CPS.asec.mar11.rda"
)

		
##########################################################################
# END OF DATA LOADING COMPONENT - DO NOT RUN DATA LOADING COMMANDS AGAIN #
##########################################################################

# now all four data frames can be loaded directly
# from your local hard drive. this is much faster.
load( "CPS.asec.mar11.rda" )



##################################################
# merge cps asec file with replicate weights file #
##################################################

x <-
	merge( 
		cps.asec.2011.df , 
		cps.repwgt.mar11.df 
	)

# confirm that the number of records in the 2011 person file
# matches the number of records in the merged file

if ( nrow( x ) != nrow( cps.asec.2011.df ) ) stop( "problem with merge - merged file should have the same number of records as the original consolidated file" )



# add a new column "one" that simply contains the number 1 for every record in the data set
x$one <- 1



#######################################
# survey design for replicate weights #
#######################################

# create survey design object with CPS design information
# using existing data frame of CPS data
y <- 
	svrepdesign(
		weights=~marsupwt, 
		repweights="pwwgt[1-9]", 
		type="Fay", 
		rho=(1-1/sqrt(4)),
		data=x ,
		combined.weights=T
	)


# notice the 'y' object used in all subsequent analysis commands

# count the total (unweighted) number of records in cps #

# simply use the nrow function
nrow( y )

# the nrow function which works on both data frame objects..
class( x )

# ..and survey design objects
class( y )

#############################################################################################################
# these commands replicate the results of the SAS, SUDAAN, and WesVar code presented in                     #  
# http://smpbff2.dsd.census.gov/pub/cps/march/Use_of_the_Public_Use_Replicate_Weight_File_final_PR_2010.doc #
#############################################################################################################

# restrict the y object to..
males.above15.inpoverty <-
	subset( 
		y ,
		a_age > 15 &		# age 16+
		a_sex %in% 1 &		# males
		perlis %in% 1		# in poverty
	)

# count the weighted number of individuals
# and also calculate the standard error,
# using the newly-created survey design subset
svytotal( ~one , males.above15.inpoverty )

# note that this exactly matches the SAS-produced file
# march 2011 asec replicate weight sas output.png


##################################
# end of census code replication #
##################################


################################
# additional analysis examples #
################################

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

sum( x$marsupwt )

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
