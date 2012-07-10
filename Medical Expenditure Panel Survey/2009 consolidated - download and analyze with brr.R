# importation and analysis of us government survey data
# medical expenditure panel survey
# 2009 consolidated

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# http://www.screenr.com/Zpd8

# anthony joseph damico
# ajdamico@gmail.com

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf


#############################################
# balanced repeated replication (brr) version #

# this script uses the brr method to calculate standard errors
# brr has the disadvantage of being computationally more difficult
# and the advantage of producing standard errors or confidence intervals
# on percentile statistics
# (for example, tsl cannot compute the confidence interval around a median)

# if you are not sure which method to use, use this brr script instead of tsl
# available in the same folder


# the statistics (means, medians, percents, and counts) from brr and tsl designs
# will match exactly.  the standard errors and confidence intervals
# will be slightly different. both methods are considered valid.


##############################################################################
# Analyze the 2009 Medical Expenditure Panel Survey consolidated file with R #
##############################################################################


# set your working directory.
# the MEPS 2009 data file will be stored here
# after downloading and importing it.
# use forward slashes instead of back slashes

setwd( "C:/My Directory/MEPS/" )


# remove the # in order to run this install.packages line only once
# install.packages( "survey" )


require(foreign) # load foreign package (converts data files into R)
require(survey)  # load survey package (analyzes complex design surveys)


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

# this process is slow.
# the MEPS 2009 file has 36,855 records.

MEPS.09.consolidated.file.location <-
	"http://meps.ahrq.gov/mepsweb/data_files/pufs/h129ssp.zip"


# the MEPS 2009 brr weight file has 241,212 records.
	
MEPS.09.brr.weight.file.location <-
	"http://meps.ahrq.gov/mepsweb/data_files/pufs/h36b09ssp.zip"

# create a temporary file and a temporary directory
# for downloading and unzipping the MEPS consolidated file
tf <- tempfile() ; td <- tempdir()
tf.brr <- tempfile() ; td.brr <- tempdir()

# download the MEPS 2009 consolidated zipped file
download.file( 
	# download the file stored in the location designated above
	MEPS.09.consolidated.file.location ,
	# save the file as the temporary file assigned above
	tf , 
	# download this as a binary file type
	mode = "wb"
)

# download the MEPS 2009 brr weights zipped file
download.file( 
	# download the file stored in the location designated above
	MEPS.09.brr.weight.file.location ,
	# save the file as the temporary file assigned above
	tf.brr , 
	# download this as a binary file type
	mode = "wb"
)

# unzip the MEPS 2009 consolidated file's contents and store the file name in the variable fn
fn <- 
	unzip( 
		# unzip the contents of the temporary file
		tf , 
		# ..into the the temporary directory (also assigned above)
		exdir = td , 
		# overwrite the contents of the temporary directory
		# in case there's anything already in there
		overwrite = T
	)


# unzip the MEPS 2009 brr weight file's contents and store the file name in the variable fn
fn.brr <- 
	unzip( 
		# unzip the contents of the temporary file
		tf.brr , 
		# ..into the the temporary directory (also assigned above)
		exdir = td.brr , 
		# overwrite the contents of the temporary directory
		# in case there's anything already in there
		overwrite = T
	)


# the variable 'fn' now contains the full file path to the h129.ssp file
# which is the MEPS 2009 consolidated file

# load the .ssp file into an R data frame
MEPS.09.consolidated.df <-
	read.xport( fn )
	

# the variable 'fn.brr' now contains the full file path to the h36b09.ssp file
# which is the MEPS 2009 consolidated file

# load the .ssp file into an R data frame
MEPS.09.brr.df <-
	read.xport( fn.brr )
	

	
# save the data frame now for instantaneous loading later.
# this stores the MEPS 2009 consolidated table as an R data file.
save( 
	list = c( 
		"MEPS.09.consolidated.df" , 
		"MEPS.09.brr.df" 
	) , 
	file = "MEPS.09.consolidated.and.brr.data.rda" 
)


##########################################################################
# END OF DATA LOADING COMPONENT - DO NOT RUN DATA LOADING COMMANDS AGAIN #
##########################################################################

# now the "MEPS.09.consolidated.df" data frame can be loaded directly
# from your local hard drive.  this is much faster.
load( "MEPS.09.consolidated.and.brr.data.rda" )
	
	

####################################
# if your computer runs out of RAM #
# if you get a memory error        #
####################################

# uncomment these lines to restrict the MEPS 09 file
# to only the columns you expect to use in the analysis

# the MEPS 2009 consolidated file has almost 2,000 different columns
# most analyses only use a small fraction of those
# by removing the columns not necessary for the analysis,
# lots of RAM gets freed up

# create a character vector containing 
# the variables you need for the analysis

# KeepVars <-
	# c( 
		# # unique identifiers
		# "DUPERSID" , "PANEL" ,
		# # cluster and strata variables used for complex survey design
		# "VARPSU" , "VARSTR" , 
		# # 2009 weight
		# "PERWT09F" , 
		# # annualized insurance coverage variable
		# "INS09X" , 
		# # total annual medical expenditure variable
		# "TOTEXP09" , 
		# # region of the country variable
		# "REGION09" , 
		# # gender variable
		# "SEX"
	# )

# restrict the consolidated data table to
# only the columns specified above

# MEPS.09.consolidated.df <-
	# MEPS.09.consolidated.df[ , KeepVars ]

# clear up RAM - garbage collection function

# gc()

############################
# end of RAM-clearing code #
############################
	

#################################################
# merge consolidated file with brr weights file #
#################################################

# remove columns DUID and PID from the brr file
# or they will create duplicate column names in the merged data frame
MEPS.09.brr.df <- 
	MEPS.09.brr.df[ , !( names( MEPS.09.brr.df ) %in% c( "DUID" , "PID" ) ) ]

	
# merge the consolidated file 
# with the brr file
MEPS.09.consolidated.with.brr.df <-
	merge( 
		MEPS.09.consolidated.df ,
		MEPS.09.brr.df ,
		by = c( "DUPERSID" , "PANEL" ) 
	)

	
# confirm that the number of records in the 2009 consolidated file
# matches the number of records in the merged file

if ( nrow( MEPS.09.consolidated.with.brr.df ) != nrow( MEPS.09.consolidated.df ) ) 
	stop( "problem with merge - merged file should have the same number of records as the original consolidated file" )
	
	

	
###################################################
# survey design for balanced repeated replication #
###################################################

# create survey design object with MEPS design information
# using existing data frame of MEPS data
meps.brr.design <- 
	svrepdesign(
		data = MEPS.09.consolidated.with.brr.df ,
		weights = ~PERWT09F ,
		type = "BRR" , 
		combined.weights = F ,
		repweights = "BRR[1-9]+"
	)

# notice the 'meps.brr.design' object used in all subsequent analysis commands


# if you are low on RAM, you can remove the data frame
# by uncommenting these four lines:

# rm( MEPS.09.consolidated.df )
# rm( MEPS.09.consolidated.with.brr.df )
# rm( MEPS.09.brr.df )

# gc()

	
#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in meps #

# simply use the nrow function
nrow( meps.brr.design )

# the nrow function which works on both data frame objects..
class( MEPS.09.consolidated.df )
# ..and survey design objects
class( meps.brr.design )

# count the total (unweighted) number of records in meps #
# broken out by region of the country #

svyby(
	~TOTEXP09 ,
	~REGION09 ,
	meps.brr.design ,
	unwtd.count
)



# count the weighted number of individuals in meps #

# add a new variable 'one' that simply has the number 1 for each record #

meps.brr.design <-
	update( 
		one = 1 ,
		meps.brr.design
	)

# the civilian, non-institutionalized population of the united states #
svytotal( 
	~one , 
	meps.brr.design 
)


# note that this is exactly equivalent to summing up the weight variable
# from the original MEPS data frame
# (assuming this data frame was not cleared out of RAM above)

sum( MEPS.09.consolidated.df$PERWT09F )

# the civilian, non-institutionalized population of the united states #
# by region of the country
svyby(
	~one ,
	~REGION09 ,
	meps.brr.design ,
	svytotal
)


# calculate the mean of a linear variable #

# average medical expenditure - nationwide
svymean( 
	~TOTEXP09 , 
	design = meps.brr.design
)

# by region of the country
svyby( 
	~TOTEXP09 , 
	~REGION09 ,
	design = meps.brr.design ,
	svymean
)


# calculate the distribution of a categorical variable #

# INS09X should be treated as a factor (categorical) variable
# instead of a numeric (linear) variable
# this update statement converts it.
# the svyby command below will not run without this
meps.brr.design <-
	update( 
		INS09X = factor( INS09X ) ,
		meps.brr.design
	)


# percent uninsured - nationwide
svymean( 
	~INS09X , 
	design = meps.brr.design
)

# by region of the country
svyby( 
	~INS09X , 
	~REGION09 ,
	design = meps.brr.design ,
	svymean
)

# calculate the median and other percentiles #

# note that unlike a taylor-series survey design
# the brr design does allow for
# calculation of standard errors

# minimum, 25th, 50th, 75th, maximum 
# medical expenditure in the united states
svyquantile( 
	~TOTEXP09 , 
	design = meps.brr.design ,
	c( 0 , .25 , .5 , .75 , 1 )
)

# by region of the country
svyby( 
	~TOTEXP09 , 
	~REGION09 ,
	design = meps.brr.design ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) , 
	ci = T
)

######################
# subsetting example #
######################

# restrict the meps.brr.design object to
# females only
meps.brr.design.female <-
	subset(
		meps.brr.design ,
		SEX %in% 2
	)
# now any of the above commands can be re-run
# using the meps.brr.design.female object
# instead of the meps.brr.design object
# in order to analyze females only
	
# calculate the mean of a linear variable #

# average medical expenditure - nationwide, restricted to females
svymean( 
	~TOTEXP09 , 
	design = meps.brr.design.female
)



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by region of the country

# store the results into a new object

coverage.by.region <-
	svyby( 
		~INS09X , 
		~REGION09 ,
		design = meps.brr.design ,
		svymean
	)

# print the results to the screen 
coverage.by.region

# now you have the results saved into a new object of type "svyby"
class( coverage.by.region )

# print only the statistics (coefficients) to the screen 
coef( coverage.by.region )

# print only the standard errors to the screen 
SE( coverage.by.region )

# this object can be coerced (converted) to a data frame.. 
coverage.by.region <- data.frame( coverage.by.region )

# ..and then immediately exported as a comma-separated value file 
# into your current working directory 
write.csv( coverage.by.region , "coverage by region.csv" )

# ..or trimmed to only contain the values you need.
# here's the uninsured percentage by region, 
# with accompanying standard errors
uninsured.rate.by.region <-
	coverage.by.region[ 2:5 , c( "REGION09" , "INS09X2" , "se3" ) ]

# that's rows 2 through 5, and the three specified columns


# print the new results to the screen
uninsured.rate.by.region

# this can also be exported as a comma-separated value file 
# into your current working directory 
write.csv( uninsured.rate.by.region , "uninsured rate by region.csv" )

# ..or directly made into a bar plot
barplot(
	uninsured.rate.by.region[ , 2 ] ,
	main = "Uninsured Rate by Region of the Country" ,
	names.arg = c( "Northeast" , "Midwest" , "South" , "West" ) ,
	ylim = c( 0 , .25 )
)

# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
