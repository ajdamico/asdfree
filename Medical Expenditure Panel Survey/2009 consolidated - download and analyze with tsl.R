# importation and analysis of us government survey data
# medical expenditure panel survey
# 2009 consolidated

# anthony joseph damico
# ajdamico@gmail.com

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf


#############################################
# taylor series linearization (tsl) version #

# this script uses the tsl method to calculate standard errors
# tsl has the advantage of being computationally easier
# and the disadvantage of not producing standard errors or confidence intervals
# on percentile statistics
# (for example, tsl cannot compute the confidence interval around a median)

# if you are not sure which method to use, use the brr script instead of tsl
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

#############################################
#DATA LOADING COMPONENT - ONLY RUN THIS ONCE#
#############################################

# this process is slow.
# the MEPS 2009 file has 36,855 records.

MEPS.09.consolidated.file.location <-
	"http://meps.ahrq.gov/mepsweb/data_files/pufs/h129ssp.zip"

# create a temporary file and a temporary directory
# for downloading and unzipping the MEPS consolidated file
tf <- tempfile() ; td <- tempdir()

# download the MEPS 2009 consolidated zipped file
download.file( 
	# download the file stored in the location designated above
	MEPS.09.consolidated.file.location ,
	# save the file as the temporary file assigned above
	tf , 
	# download this as a binary file type
	mode = "wb"
)

# unzip the file's contents and store the file name in the variable fn
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

# the variable 'fn' now contains the full file path to the h129.ssp file
# which is the MEPS 2009 consolidated file

# load the .ssp file into an R data frame
MEPS.09.consolidated.df <-
	read.xport( fn )
	
# save the data frame now for instantaneous loading later.
# this stores the MEPS 2009 consolidated table as an R data file.
save( MEPS.09.consolidated.df , file = "MEPS.09.consolidated.data.rda" )

########################################################################
#END OF DATA LOADING COMPONENT - DO NOT RUN DATA LOADING COMMANDS AGAIN#
########################################################################

# now the "MEPS.09.consolidated.df" data frame can be loaded directly
# from your local hard drive.  this is much faster.
load( "MEPS.09.consolidated.data.rda" )
	
	

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
# survey design for taylor-series linearization #
#################################################

# create survey design object with MEPS design information
# using existing data frame of MEPS data
meps.tsl.design <- 
	svydesign(
		id = ~VARPSU , 
		strata = ~VARSTR ,
		nest = TRUE ,
		weights = ~PERWT09F ,
		data = MEPS.09.consolidated.df
	)

# notice the 'meps.tsl.design' object used in all subsequent analysis commands


# if you are low on RAM, you can remove the data frame
# by uncommenting these two lines:

# rm( MEPS.09.consolidated.df )

# gc()

	
#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in meps #

# simply use the nrow function
nrow( meps.tsl.design )

# the nrow function which works on both data frame objects..
class( MEPS.09.consolidated.df )
# ..and survey design objects
class( meps.tsl.design )

# count the total (unweighted) number of records in meps #
# broken out by region of the country #

svyby(
	~TOTEXP09 ,
	~REGION09 ,
	meps.tsl.design ,
	unwtd.count
)



# count the weighted number of individuals in meps #

# add a new variable 'one' that simply has the number 1 for each record #

meps.tsl.design <-
	update( 
		one = 1 ,
		meps.tsl.design
	)

# the civilian, non-institutionalized population of the united states #
svytotal( 
	~one , 
	meps.tsl.design 
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
	meps.tsl.design ,
	svytotal
)


# calculate the mean of a linear variable #

# average medical expenditure - nationwide
svymean( 
	~TOTEXP09 , 
	design = meps.tsl.design
)

# by region of the country
svyby( 
	~TOTEXP09 , 
	~REGION09 ,
	design = meps.tsl.design ,
	svymean
)


# calculate the distribution of a categorical variable #

# INS09X should be treated as a factor (categorical) variable
# instead of a numeric (linear) variable
# this update statement converts it.
# the svyby command below will not run without this
meps.tsl.design <-
	update( 
		INS09X = factor( INS09X ) ,
		meps.tsl.design
	)


# percent uninsured - nationwide
svymean( 
	~INS09X , 
	design = meps.tsl.design
)

# by region of the country
svyby( 
	~INS09X , 
	~REGION09 ,
	design = meps.tsl.design ,
	svymean
)

# calculate the median and other percentiles #

# note that a taylor-series survey design
# does not allow calculation of standard errors

# minimum, 25th, 50th, 75th, maximum 
# medical expenditure in the united states
svyquantile( 
	~TOTEXP09 , 
	design = meps.tsl.design ,
	c( 0 , .25 , .5 , .75 , 1 )
)

# by region of the country
svyby( 
	~TOTEXP09 , 
	~REGION09 ,
	design = meps.tsl.design ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	keep.var = F
)

######################
# subsetting example #
######################

# restrict the meps.tsl.design object to
# females only
meps.tsl.design.female <-
	subset(
		meps.tsl.design ,
		SEX %in% 2
	)
# now any of the above commands can be re-run
# using the meps.tsl.design.female object
# instead of the meps.tsl.design object
# in order to analyze females only
	
# calculate the mean of a linear variable #

# average medical expenditure - nationwide, restricted to females
svymean( 
	~TOTEXP09 , 
	design = meps.tsl.design.female
)

