# analyze survey data for free (http://asdfree.com) with the r language
# national health and nutrition examination survey
# 2009-2010 demographics and questionnaire files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# setInternet2( FALSE )						# # only windows users need this line
# library(downloader)
# setwd( "C:/My Directory/NHANES/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Health%20and%20Nutrition%20Examination%20Survey/2009-2010%20interview%20only%20-%20download%20and%20analyze.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com

######################################################################################################################
# Analyze the 2009-2010 National Health and Nutrition Examination Survey demographics and questionnaire files with R #
######################################################################################################################


# # # are you on a windows system? # # #
if ( .Platform$OS.type == 'windows' ) print( 'windows users: read this block' )
# you might need to change your internet connectivity settings
# using this next line -
# setInternet2( FALSE )
# - will change the download method of your R console
# however, if you have already downloaded anything
# in the same console, the `setInternet2( TRUE )`
# setting will be unchangeable in that R session
# so make sure you are using a fresh instance
# of your windows R console before designating
# setInternet2( FALSE )


# set your working directory.
# all NHANES data files will be stored here
# after downloading and importing.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NHANES/" )
# ..in order to set your current working directory



# set the number of digits shown in all output

options( digits = 15 )


# remove the # in order to run this install.packages line only once
# install.packages( "survey" )


library(foreign) # load foreign package (converts data files into R)
library(survey)  # load survey package (analyzes complex design surveys)


# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN



###############################################
# DATA LOADING COMPONENT - ONLY RUN THIS ONCE #
###############################################

# create new character variables containing the full ftp filepath of the files
# that need to be downloaded and imported into r for analysis
# this involves only the 2009-2010 NHANES data set,
# so one file will be downloaded for each component


# demographics, weighting, and complex design variables

NHANES.0910.demographics.file.location <-
	"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/nhanes/2009-2010/demo_f.xpt"	# 2009-2010


# health insurance variables (from the questionnaire component)
	
NHANES.0910.HIQ_F.file.location <-
	"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/nhanes/2009-2010/HIQ_F.xpt"	# 2009-2010
	

##################################################
# download and import these two data sets into r #
# since the download and importation of all      #
# data sets involves similar commands,           #
# create a function that automates the process   #
##################################################

# download and importation function
download.and.import.any.nhanes.file <-		# this line gives the function a name
	function( ftp.filepath ){ 		# this line specifies the input values for the function
	
				
		# create a temporary file
		# for downloading file to the local drive
		tf <- tempfile()


		# download the file using the ftp.filepath specified
		download.file( 
			# download the file stored in the location designated above
			ftp.filepath ,
			# save the file as the temporary file assigned above
			tf , 
			# download this as a binary file type
			mode = "wb"
		)
		
		# the variable 'tf' now contains the full file path on the local computer to the specified file
		
		read.xport( tf )			# the last line of a function contains what it *returns*
									# so by putting read.xport as the final line,
									# this function will return an r data frame
}


# demographics, weighting, and complex design variables

NHANES.0910.demographics.df <-
	download.and.import.any.nhanes.file( NHANES.0910.demographics.file.location )

	
# health insurance questionnaire variables

NHANES.0910.HIQ_F.df <-
	download.and.import.any.nhanes.file( NHANES.0910.HIQ_F.file.location )
	

	
# save both data frames now for instantaneous loading later.
# this stores these two NHANES 2009-2010 tables in a single R data file.
save(
	NHANES.0910.demographics.df ,
	NHANES.0910.HIQ_F.df ,
	file = "NHANES.0910.demo.and.hiq.rda" 	# this is the output file name for the two data frames
)

# note that this .rda file will be stored in the local directory specified
# with the setwd command at the beginning of the script

##########################################################################
# END OF DATA LOADING COMPONENT - DO NOT RUN DATA LOADING COMMANDS AGAIN #
##########################################################################


# now the two data frames ending in ".df" can be loaded directly
# from your local hard drive.  this is much faster.
load( "NHANES.0910.demo.and.hiq.rda" )


# create a character vector that will be used to
# limit the demographics file to only the variables needed
DemoKeepVars <-
	c( 
		"SEQN" , 		# unique person identifier (merge variable)
		
		"WTINT2YR" , 	# the two-year interview weight
						# note that this is the weight for only analyses that do not require MEC variables
						
						# if any of the variables used in the analysis were from
						# individuals who took the mobile examination center (MEC) exam,
						# then the two-year interviewed + MEC examined weight (WTMEC2YR) should be used instead
						
						# also note: for pooled data, divide this weight by the number of data sets pooled
						# in order to approximate the us civilian non-institutionalized population for the time period
		
		"INDFMPIR" ,	# ratio of family income to poverty

		"SDMVPSU" , 	# primary sampling unit varaible, used in complex design
		
		"SDMVSTRA" , 	# strata variable, used in complex design
		
		"RIDAGEYR" ,	# person age
		
		"RIAGENDR" 		# gender
	)

# create a character vector that will be used to
# limit the health insurance questionnaire file to only the variables needed
QuestionnaireKeepVars <-
	c( 
		"SEQN" , 		# unique person identifier (merge variable)
		
		"HIQ011" 		# Covered by health insurance, from
						# http://www.cdc.gov/nchs/nhanes/nhanes2009-2010/HIQ_F.htm#HIQ011
	)


# display the number of rows in the demographics and health insurance questionnaire data sets
nrow( NHANES.0910.demographics.df )
nrow( NHANES.0910.HIQ_F.df )

# note that since all individuals with demographic information should also have completed the health insurance questionnaire
# therefore, the number of rows in both data sets should be equal!

# display the first six records of each data set - this includes lots of unnecessary columns
head( NHANES.0910.demographics.df )
head( NHANES.0910.HIQ_F.df )


# limit the demographics and health insurance data sets to only the variables needed for the analysis
# this step overwrites the data frame with itself, throwing out unnecessary columns
NHANES.0910.demographics.df <-
	NHANES.0910.demographics.df[ , DemoKeepVars ]
	
NHANES.0910.HIQ_F.df <-
	NHANES.0910.HIQ_F.df[ , QuestionnaireKeepVars ]


# display the first six records of each data set - this now shows only the columns needed for the analysis
head( NHANES.0910.demographics.df )
head( NHANES.0910.HIQ_F.df )


# merge the two data sets together into a new data frame
# note that a 'by' variable does not need to be specified, because
# both data frames only share one variable - SEQN - 
# which will be used as the merge variable by default
NHANES.0910.demo.and.HIQ_F.df <- 
	merge( 
		NHANES.0910.demographics.df , 
		NHANES.0910.HIQ_F.df ,
		all = F						# all = T instructs r to keep all records, regardless of a match
									# all = F instructs r to throw out records on both sides if there is no match
									# using all = F for this merge serves as a good data check,
									# since all records should have a matching SEQN between the two data sets
	)

# notice that the number of rows of the merged data set
# exactly equals the number of rows in the two pre-merged data sets - as it should!
nrow( NHANES.0910.demo.and.HIQ_F.df )

# copy the merged data frame over to a new object - x - just for ease of typing
x <- NHANES.0910.demo.and.HIQ_F.df

# remove the merged data frame from memory, and start using the data frame x from now on
rm( NHANES.0910.demo.and.HIQ_F.df )


#####################################################
# start of recodes to the merged (final) data frame #
#####################################################

# conduct all variable recodes after the final (in this case merged) data set has been created
# but before the survey object get initialized

x <-
	transform( 
		x ,

		# add a 'one' variable to the data frame to quickly total weighted counts in the survey design object
		one = 1 ,

		# replicate the poverty categories presented in the cdc figure
		POVCAT =
		
			ifelse( INDFMPIR < 1 , 1 ,		# individuals in families below the poverty line
			
			ifelse( INDFMPIR < 2 , 2 ,		# individuals in families between 100% and 199% of poverty
			
			ifelse( INDFMPIR >= 2 , 3 , 	# individuals in families at or above 200% of poverty - 
											# - note that poverty ratios are capped at 500% of poverty,
											# so poverty groups cannot be larger than that.
											
				NA ) ) ) ,					# if none of the above statements are true
											# make the POVCAT variable missing
											# (about 5% of respondents do not have a poverty category)
											
		HIQ011 = 							# recode the HIQ011 (any health insurance coverage) variable
		
			ifelse( 						# if..
				HIQ011 %in% 1:2 , 			# this variable is a 1 or a 2 (a yes or a no)
				HIQ011 , 					# then do not change it.
				NA 							# otherwise, make it missing.
			)								# this sets don't know and refusal responses to missing
											# so they are not included in the categorical output during analysis commands
	)


###################################################
# end of recodes to the merged (final) data frame #
###################################################

	
	
#################################################
# survey design for taylor-series linearization #
#################################################

# create survey design object with NHANES design information
# using the final data frame of NHANES data
nhanes.tsl.design <- 
	svydesign(
		id = ~SDMVPSU , 
		strata = ~SDMVSTRA ,
		nest = TRUE ,
		weights = ~WTINT2YR ,
		data = x
	)


# notice the 'nhanes.tsl.design' object used in all subsequent analysis commands


#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in nhanes #

# simply use the nrow function
nrow( nhanes.tsl.design )

# the nrow function which works on both data frame objects..
class( x )
# ..and survey design objects
class( nhanes.tsl.design )

# count the total (unweighted) number of records in nhanes #
# broken out by poverty category #

svyby(
	~RIDAGEYR ,
	~POVCAT ,
	nhanes.tsl.design ,
	unwtd.count
)



# count the weighted number of individuals in nhanes #

# the civilian, non-institutionalized population of the united states #
svytotal( 
	~one , 
	nhanes.tsl.design 
)


# note that this is exactly equivalent to summing up the weight variable
# from the original nhanes data frame

sum( x$WTINT2YR )

# the civilian, non-institutionalized population of the united states #
# by poverty category
svyby(
	~one ,
	~POVCAT ,
	nhanes.tsl.design ,
	svytotal
)


# calculate the mean of a linear variable #

# average age - nationwide
svymean( 
	~RIDAGEYR , 
	design = nhanes.tsl.design
)

# by poverty category
svyby( 
	~RIDAGEYR , 
	~POVCAT ,
	design = nhanes.tsl.design ,
	svymean
)


# calculate the distribution of a categorical variable #

# HIQ011 should be treated as a factor (categorical) variable
# instead of a numeric (linear) variable
# this update statement converts it.
# the svyby command below will not run without this
nhanes.tsl.design <-
	update( 
		HIQ011 = factor( HIQ011 ) ,
		nhanes.tsl.design
	)


# percent uninsured - nationwide
svymean( 
	~HIQ011 , 
	design = nhanes.tsl.design ,
	na.rm = TRUE					# note this new na.rm = TRUE parameter
)									# this instructs r to throw out NA (missing) records
									# this hadn't been needed for prior analyses, because 
									# none of the previous variables used had any missing records


# by poverty category
svyby( 
	~HIQ011 , 
	~POVCAT ,
	design = nhanes.tsl.design ,
	svymean ,
	na.rm = TRUE
)

# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum 
# age in the united states
# notice that age has been top-coded at 80 in this data set #
svyquantile( 
	~RIDAGEYR , 
	design = nhanes.tsl.design ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	ci = TRUE							# force r to output a confidence interval
)										# by setting this parameter to true
										# if confidence intervals are not desired,
										# use keep.var = FALSE in its place


# by poverty category
svyby( 
	~RIDAGEYR , 
	~POVCAT ,
	design = nhanes.tsl.design ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,		
	ci = TRUE							# force r to output a confidence interval
)										# by setting this parameter to true
										# if confidence intervals are not desired,
										# use keep.var = FALSE in its place

######################
# subsetting example #
######################

# restrict the nhanes.tsl.design object to
# females only
nhanes.tsl.design.female <-
	subset(
		nhanes.tsl.design ,
		RIAGENDR %in% 2
	)
# now any of the above commands can be re-run
# using the nhanes.tsl.design.female object
# instead of the nhanes.tsl.design object
# in order to analyze females only
	
# calculate the mean of a linear variable #

# average age - nationwide, restricted to females
svymean( 
	~RIDAGEYR , 
	design = nhanes.tsl.design.female ,
	na.rm = T
)



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by poverty category

# store the results into a new object

coverage.by.poverty <-
	svyby( 
		~HIQ011 , 
		~POVCAT ,
		design = nhanes.tsl.design ,
		svymean  ,
		na.rm = T 
	)

# print the results to the screen 
coverage.by.poverty

# now you have the results saved into a new object of type "svyby"
class( coverage.by.poverty )

# print only the statistics (coefficients) to the screen 
coef( coverage.by.poverty )

# print only the standard errors to the screen 
SE( coverage.by.poverty )

# this object can be coerced (converted) to a data frame.. 
coverage.by.poverty <- data.frame( coverage.by.poverty )

# ..and then immediately exported as a comma-separated value file 
# into your current working directory 
write.csv( coverage.by.poverty , "coverage by poverty.csv" )

# ..or trimmed to only contain the values you need.
# here's the uninsured percentage by poverty, 
# with accompanying standard errors
uninsured.rate.by.poverty <-
	coverage.by.poverty[  , c( "POVCAT" , "HIQ0112" , "se.HIQ0112" ) ]

# that's only the three specified columns, and all rows


# print the new results to the screen
uninsured.rate.by.poverty

# this can also be exported as a comma-separated value file 
# into your current working directory 
write.csv( uninsured.rate.by.poverty , "uninsured rate by poverty.csv" )

# ..or directly made into a bar plot
barplot(
	uninsured.rate.by.poverty[ , 2 ] ,
	main = "Uninsured Rate by Poverty Category" ,
	names.arg = c( "Below Poverty" , "100 - 199%" , "At or Above 200%" ) ,
	ylim = c( 0 , .4 )
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
