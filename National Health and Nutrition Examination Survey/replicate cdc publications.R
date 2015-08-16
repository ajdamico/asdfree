# analyze survey data for free (http://asdfree.com) with the r language
# national health and nutrition examination survey
# replication of tables published by the centers for disease control & prevention
# using 1999-2000 and 2001-2002 demographics, laboratory, and examination files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# setInternet2( FALSE )						# # only windows users need this line
# library(downloader)
# setwd( "C:/My Directory/NHANES/" )
# source_url( "https://raw.github.com/ajdamico/asdfree/master/National%20Health%20and%20Nutrition%20Examination%20Survey/replicate%20cdc%20publications.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# the centers for disease control & prevention have published sample sas, sudaan, and stata code at:
# http://www.cdc.gov/nchs/tutorials/Nhanes/Downloads/intro_original.htm

# this r script will replicate three of the sas and sudaan syntax files on that page from scratch
# and (with one noted exception) match cdc output exactly

# # # # # # # # # # # # #
# replicated program #1 #
# # # # # # # # # # # # #
# the centers for disease control & prevention published this sas and sudaan syntax file:
# http://www.cdc.gov/nchs/tutorials/nhanes/downloads/Continuous/descriptive_means_sas.sas
# in order to generate the output found in this document:
# http://www.cdc.gov/nchs/tutorials/nhanes/downloads/Continuous/descriptive_means_sas.pdf


# # # # # # # # # # # # #
# replicated program #2 #
# # # # # # # # # # # # #
# the centers for disease control & prevention published this sas and sudaan syntax file:
# http://www.cdc.gov/nchs/tutorials/nhanes/downloads/Continuous/descriptive_proportions.sas
# in order to generate the output found in this document:
# http://www.cdc.gov/nchs/tutorials/nhanes/downloads/Continuous/descriptive_proportion.pdf

# # # # # # # # # # # # #
# replicated program #3 #
# # # # # # # # # # # # #
# the centers for disease control & prevention published this sas and sudaan syntax file:
# http://www.cdc.gov/nchs/tutorials/nhanes/downloads/Continuous/descriptive_percentile_SUDAAN.sas
# in order to generate the output found in this document:
# http://www.cdc.gov/nchs/tutorials/nhanes/downloads/Continuous/descriptive_percentile.pdf


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


###############################################################################################################################################
# Analyze the 1999-2000 and 2001-2002 National Health and Nutrition Examination Survey demographics, laboratory, and examination files with R #
###############################################################################################################################################


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
# this involves the 1999-2000 and 2001-2002 NHANES data sets,
# so two files will be downloaded for each component


# demographics, weighting, and complex design variables

NHANES.9900.demographics.file.location <-
	"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/nhanes/1999-2000/DEMO.xpt" 	# 1999-2000

NHANES.0102.demographics.file.location <-
	"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/nhanes/2001-2002/DEMO_B.xpt"	# 2001-2002


# cholesterol laboratory variables
	
NHANES.9900.Lab13.file.location <-
	"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/nhanes/1999-2000/Lab13.xpt"	# 1999-2000
	
NHANES.0102.l13_b.file.location <-
	"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/nhanes/2001-2002/l13_b.xpt"	# 2001-2002


# blood pressure laboratory variables
	
NHANES.9900.BPX.file.location <-
	"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/nhanes/1999-2000/BPX.xpt"		# 1999-2000

NHANES.0102.BPX_B.file.location <-
	"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/nhanes/2001-2002/BPX_B.xpt"	# 2001-2002

# blood pressure questionnaire variables

NHANES.9900.BPQ.file.location <-
	"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/nhanes/1999-2000/BPQ.xpt"		# 1999-2000

NHANES.0102.BPQ_B.file.location <-
	"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/nhanes/2001-2002/BPQ_B.xpt"	# 2001-2002


####################################################
# download and import these eight data sets into r #
# since the download and importation of all eight  #
# data sets involves similar commands,             #
# create a function that automates the process     #
####################################################

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

NHANES.9900.demographics.df <-
	download.and.import.any.nhanes.file( NHANES.9900.demographics.file.location )	# 1999-2000

NHANES.0102.demographics.df <-
	download.and.import.any.nhanes.file( NHANES.0102.demographics.file.location )	# 2001-2002

	
# cholesterol laboratory variables
	
NHANES.9900.Lab13.df <-
	download.and.import.any.nhanes.file( NHANES.9900.Lab13.file.location )			# 1999-2000
	
NHANES.0102.l13_b.df <-
	download.and.import.any.nhanes.file( NHANES.0102.l13_b.file.location )			# 2001-2002


# blood pressure laboratory variables
	
NHANES.9900.BPX.df <-
	download.and.import.any.nhanes.file( NHANES.9900.BPX.file.location )			# 1999-2000

NHANES.0102.BPX_B.df <-
	download.and.import.any.nhanes.file( NHANES.0102.BPX_B.file.location )			# 2001-2002

# blood pressure questionnaire variables

NHANES.9900.BPQ.df <-
	download.and.import.any.nhanes.file( NHANES.9900.BPQ.file.location )			# 1999-2000

NHANES.0102.BPQ_B.df <-
	download.and.import.any.nhanes.file( NHANES.0102.BPQ_B.file.location )			# 2001-2002


# save all eight data frames now for instantaneous loading later.
# this stores the eight NHANES 1999-2000 and 2001-2002 tables in a single R data file.
save(
	NHANES.9900.demographics.df ,
	NHANES.0102.demographics.df ,
	NHANES.9900.Lab13.df ,
	NHANES.0102.l13_b.df ,
	NHANES.9900.BPX.df ,
	NHANES.0102.BPX_B.df ,
	NHANES.9900.BPQ.df ,
	NHANES.0102.BPQ_B.df ,
	file = "NHANES.9902.data.to.replicate.cdc.tables.rda" 	# this is the output file name for the eight data frames
)

# note that this .rda file will be stored in the local directory specified
# with the setwd command at the beginning of the script

##########################################################################
# END OF DATA LOADING COMPONENT - DO NOT RUN DATA LOADING COMMANDS AGAIN #
##########################################################################


# now the eight data frames ending in ".df" can be loaded directly
# from your local hard drive.  this is much faster.
load( "NHANES.9902.data.to.replicate.cdc.tables.rda" )


#########################
# replicated program #1 #
#########################
# the centers for disease control & prevention published this sas and sudaan syntax file:
# http://www.cdc.gov/nchs/tutorials/nhanes/downloads/Continuous/descriptive_means_sas.sas
# in order to generate the output found in this document:
# http://www.cdc.gov/nchs/tutorials/nhanes/downloads/Continuous/descriptive_means_sas.pdf


# create a character vector that will be used to
# limit the two demographics files to only the variables needed
DemoKeepVars <-
	c( 
		"SEQN" , 		# unique person identifier (merge variable)
		
		"WTMEC4YR" , 	# the four-year interviewed + MEC examined weight
						# note that this is a special weight for only pooled data sets and
						# individuals who took the mobile examination center (MEC) exam
						# there are three other weights available:
						# only with vs. regardless of MEC and two-year (single) vs. four-year (pooled)
						
		"RIDSTATR" ,	# interviewed only or interviewed + MEC
		
		"SDMVPSU" , 	# primary sampling unit varaible, used in complex design
		
		"SDMVSTRA" , 	# strata variable, used in complex design
		
		"RIDAGEYR" 		# person age
	)

# create a character vector that will be used to
# limit the laboratory file to only the variables needed
LabKeepVars <-
	c( 
		"SEQN" , 		# unique person identifier (merge variable)
		
		"LBXTC" 		# laboratory total cholesterol variable
	)

# stack (pool) the two demographics files together using the rbind (row-bind) function
NHANES.9902.demographics.df <-
	rbind( 
		NHANES.9900.demographics.df[ , DemoKeepVars ] ,		# when stacking, limit each data set to only the necessary variables, because
		NHANES.0102.demographics.df[ , DemoKeepVars ]		# the rbind function will break if any columns in the two stacked data sets do not match
	)
	
# stack (pool) the two laboratory files together using the rbind (row-bind) function
NHANES.9902.lab13.df <-
	rbind( 
		NHANES.9900.Lab13.df[ , LabKeepVars ] ,				# when stacking, limit each data set to only the necessary variables, because
		NHANES.0102.l13_b.df[ , LabKeepVars ]				# the rbind function will break if any columns in the two stacked data sets do not match
	)

# display the number of rows in each of these newly-pooled data sets
nrow( NHANES.9902.demographics.df )
nrow( NHANES.9902.lab13.df )

# display the first six records of each data set
head( NHANES.9902.demographics.df )
head( NHANES.9902.lab13.df )

# merge the two data sets together into a new data frame
# note that a 'by' variable does not need to be specified, because
# both data frames only share one variable - SEQN - 
# which will be used as the merge variable by default
NHANES.9902.demo.and.lab13.df <- 
	merge( 
		NHANES.9902.demographics.df , 
		NHANES.9902.lab13.df ,
		all = T						# all = T instructs r to keep all records, regardless of a match
	)

# immediately subset the merged data set
# to only contain individuals who were both 
# interviewed and received the mobile examination center (MEC)
NHANES.9902.demo.and.lab13.df <-
	subset( 
		NHANES.9902.demo.and.lab13.df ,			# object to subset
		RIDSTATR %in% 2							# subset definition: wherever RIDSTATR is two
	)
# note about which weight variable to use in the survey design construction below -
# this RIDSTATR line indicates that WTMEC2YR or WTMEC4YR should be used
# however, any analyses that only use interview variables (and are not limited by RIDSTATR)
# should use the weights WTINT2YR or WTINT4YR

# display the number of rows in the final merged data set
nrow( NHANES.9902.demo.and.lab13.df )

# display the first six records in the final merged data set
head( NHANES.9902.demo.and.lab13.df )

	
#################################################
# survey design for taylor-series linearization #
#################################################

# create survey design object with NHANES design information
# using the pooled, merged data frame of NHANES data
nhanes.tsl.design <- 
	svydesign(
		id = ~SDMVPSU , 
		strata = ~SDMVSTRA ,
		nest = TRUE ,
		weights = ~WTMEC4YR ,
		data = NHANES.9902.demo.and.lab13.df
	)


#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in this pooled, merged nhanes #

# simply use the nrow function
nrow( nhanes.tsl.design )

# the nrow function which works on both data frame objects..
class( NHANES.9902.demo.and.lab13.df )
# ..and survey design objects
class( nhanes.tsl.design )


# count the weighted number of individuals in the pooled data file #

# add a new variable 'one' that simply has the number 1 for each record #

nhanes.tsl.design <-
	update( 
		one = 1 ,
		nhanes.tsl.design
	)

# this approximately generalizes to the civilian, # 
# non-institutionalized population of the united states #
svytotal( 
	~one , 
	nhanes.tsl.design 
)


# note that this is exactly equivalent to summing up the weight variable
# from the original NHANES data frame

sum( NHANES.9902.demo.and.lab13.df$WTMEC4YR )


##############################################################
# print the exact contents of the cdc document to the screen #
##############################################################

# http://www.cdc.gov/nchs/tutorials/nhanes/downloads/Continuous/descriptive_means_sas.pdf #

# calculate the unweighted count of the pooled data set #
unwtd.count( ~LBXTC , nhanes.tsl.design )

# calculate the mean and SE nationwide total cholesterol (mg/dL) #
svymean( ~LBXTC , nhanes.tsl.design , na.rm = T )

# broken out by individuals below 20 versus at or above 20 years old #

# calculate the unweighted count of the pooled data set #
svyby( ~LBXTC , ~( RIDAGEYR < 20 ) , nhanes.tsl.design , unwtd.count , na.rm = T )

# calculate the mean and SE total cholesterol (mg/dL) #
svyby( ~LBXTC , ~( RIDAGEYR < 20 ) , nhanes.tsl.design , svymean , na.rm = T )

################################
# end of replicated program #1 #
################################


# remove all objects in memory..
rm( list = ls( all = TRUE ) )

# ..and re-load the eight data frames.
load( "NHANES.9902.data.to.replicate.cdc.tables.rda" )


# # # # # # # # # # # # #
# replicated program #2 #
# # # # # # # # # # # # #
# the centers for disease control & prevention published this sas and sudaan syntax file:
# http://www.cdc.gov/nchs/tutorials/nhanes/downloads/Continuous/descriptive_proportions.sas
# in order to generate the output found in this document:
# http://www.cdc.gov/nchs/tutorials/nhanes/downloads/Continuous/descriptive_proportion.pdf


# create a character vector that will be used to
# limit the two demographics files to only the variables needed
DemoKeepVars <-
	c( 
		"SEQN" , 		# unique person identifier (merge variable)
		
		"WTMEC4YR" , 	# the four-year interviewed + MEC examined weight
						# note that this is a special weight for only pooled data sets and
						# individuals who took the mobile examination center (MEC) exam
						# there are three other weights available:
						# only with vs. regardless of MEC and two-year (single) vs. four-year (pooled)
						
		"RIDSTATR" ,	# interviewed only or interviewed + MEC
		
		"SDMVPSU" , 	# primary sampling unit varaible, used in complex design
		
		"SDMVSTRA" , 	# strata variable, used in complex design
		
		"RIDAGEYR" ,	# person age
		
		"RIDRETH1" , 	# race / ethnicity
		
		"RIAGENDR" 		# gender
	)

# create two character vectors containing the four systolic and diastolic variables
Systolic.Variables <- paste0( "BPXSY" , 1:4 )		# BPXSY1-4
Diastolic.Variables <- paste0( "BPXDI" , 1:4 )		# BPXDI1-4


# create a character vector that will be used to
# limit the laboratory file to only the variables needed
BPXKeepVars <-
	c( 
		"SEQN" , 				# unique person identifier (merge variable)
		
		 Systolic.Variables , 	# four systolic variables, defined in the character vector above
		 
		 Diastolic.Variables	# four diastolic variables, defined in the character vector above
	)

# create a character vector that will be used to
# limit the questionnaire file to only the variables needed
BPQKeepVars <-
	c( 
		"SEQN" , 				# unique person identifier (merge variable)
		
		"BPQ050A" , 			# taking prescribed medicine for controlling HBP
								# http://www.cdc.gov/nchs/nhanes/nhanes2001-2002/BPQ_B.htm#BPQ050A
		
		"BPQ020" 				# ever been told you have HBP (gate question for BPQ050)
								# http://www.cdc.gov/nchs/nhanes/nhanes2001-2002/BPQ_B.htm#BPQ020
	)


	
# stack (pool) the two demographics files together using the rbind (row-bind) function
NHANES.9902.demographics.df <-
	rbind( 
		NHANES.9900.demographics.df[ , DemoKeepVars ] ,		# when stacking, limit each data set to only the necessary variables, because
		NHANES.0102.demographics.df[ , DemoKeepVars ]		# the rbind function will break if any columns in the two stacked data sets do not match
	)

# stack (pool) the two questionnaire files together using the rbind (row-bind) function
NHANES.9902.BPQ.df <-
	rbind( 
		NHANES.9900.BPQ.df[ , BPQKeepVars ] ,				# when stacking, limit each data set to only the necessary variables, because
		NHANES.0102.BPQ_B.df[ , BPQKeepVars ]				# the rbind function will break if any columns in the two stacked data sets do not match
	)

# stack (pool) the two laboratory files together using the rbind (row-bind) function
NHANES.9902.BPX.df <-
	rbind( 
		NHANES.9900.BPX.df[ , BPXKeepVars ] ,				# when stacking, limit each data set to only the necessary variables, because
		NHANES.0102.BPX_B.df[ , BPXKeepVars ]				# the rbind function will break if any columns in the two stacked data sets do not match
	)


# display the number of rows in each of these newly-pooled data sets
nrow( NHANES.9902.demographics.df )
nrow( NHANES.9902.BPQ.df )
nrow( NHANES.9902.BPX.df )


# display the first six records of each data set
head( NHANES.9902.demographics.df )
head( NHANES.9902.BPQ.df )
head( NHANES.9902.BPX.df )


# merge the first two data sets together into a new data frame
# note that a 'by' variable does not need to be specified, because
# both data frames only share one variable - SEQN - 
# which will be used as the merge variable by default
NHANES.9902.demo.and.BPQ.df <- 
	merge( 
		NHANES.9902.demographics.df , 
		NHANES.9902.BPQ.df ,
		all = T						# all = T instructs r to keep all records, regardless of a match
	)

# now merge the BPX data set with the first two data set
# creating a merge file with all three data sets together
NHANES.9902.demo.BPQ.and.BPX.df <- 
	merge( 
		NHANES.9902.demo.and.BPQ.df , 
		NHANES.9902.BPX.df ,
		all = T						# all = T instructs r to keep all records, regardless of a match
	)

	
# immediately subset the merged data set
# to only contain individuals who were both 
# interviewed and received the mobile examination center (MEC)

# instead of overwriting NHANES.9902.demo.BPQ.and.BPX.df with a subset of itself (like the previous example)
# this creates a new data frame - x - for ease of typing
x <-
	subset( 
		NHANES.9902.demo.BPQ.and.BPX.df ,		# object to subset
		RIDSTATR %in% 2							# subset definition: wherever RIDSTATR is two
	)
# note about which weight variable to use in the survey design construction below -
# this RIDSTATR line indicates that WTMEC2YR or WTMEC4YR should be used
# however, any analyses that only use interview variables (and are not limited by RIDSTATR)
# should use the weights WTINT2YR or WTINT4YR
	
# display the number of rows in the final merged data set
nrow( x )

# display the first six records in the final merged data set
head( x )

######################################################################
# perform recodes to the merged, pooled, subsetted (final) data frame #
######################################################################

# create two new columns in the data frame - SYS and DIA
# each individual had as many as four systolic and diastolic measurements,
# these now contain the average measurement for each individual
x$SYS <- rowMeans( x[ , Systolic.Variables ] , na.rm = T )		# note the na.rm = T removes NA (missing) values from the average
x$DIA <- rowMeans( x[ , Diastolic.Variables ] , na.rm = T )		# so if an individual only had three non-missing measurements, 
																# those three values would be averaged (instead of that individual having a missing)

# additional recodes in the final data frame
x <-
	transform( 
		x ,
		
		# add a 'one' variable to the data frame to quickly total weighted counts in the survey design object
		one = 1 ,
		
		# create the high blood pressure variable..
		HBP = 
		
			# IF an individual had..
			ifelse( 
				# at least one systolic measurement AND
				!is.na( SYS ) & 

				# at least one diastolic measurement AND
				!is.na( DIA ) & 
				
				# gave a valid response (either yes or no) to the 'ever been told you have HBP?' question AND
				BPQ020 %in% 1:2 & 
				
				# (if asked) did not refuse to answer the 'are you currently taking prescribed medication for HBP?' question
				!( BPQ050A %in% c( 7 , 9 ) ) , 
			
				# THEN..
				ifelse( 
					# IF their average systolic was above 140
					SYS >= 140 | 
					
					# OR their average diastolic was above 90
					DIA >= 90 | 
					
					# OR they are taking prescribed medication for HBP
					BPQ050A %in% 1 , 
					
					# THEN they have high blood pressure
					1 , 
					
					# OTHERWISE they do not have high blood pressure
					0 
				) ,
				
				# OTHERWISE they are considered NA (missing) for the analysis
				NA ) ,
				
		# create three age categories
		age = 
			
			# age 20 - 39
			ifelse( RIDAGEYR %in% 20:39 , 1 ,
			
			# age 40 - 59
			ifelse( RIDAGEYR %in% 40:59 , 2 ,
			
			# age 60 or above
			ifelse( RIDAGEYR >= 60 , 3 , 
			
			# OTHERWISE they are considered NA (missing) for the analysis
			# note that this includes all children (individuals younger than 20)
			
				NA ) ) ) ,
				
		# create four race/ethnicity categories
		race = 
		
			# white non-hispanic
			ifelse( RIDRETH1 %in% 3 , 1 ,
			
			# black non-hispanic
			ifelse( RIDRETH1 %in% 4 , 2 , 
			
			# mexican
			ifelse( RIDRETH1 %in% 1 , 3 , 
			
			# other race (including non-mexican hispanic)
			ifelse( RIDRETH1 %in% c( 2 , 5 ) , 4 , 
			
				NA ) ) ) )
	)
	
######################################################################
# end of recodes to the merged, pooled, subsetted (final) data frame #
######################################################################

	
	
#################################################
# survey design for taylor-series linearization #
#################################################

# create survey design object with NHANES design information
# using the pooled, merged data frame of NHANES data
nhanes.tsl.design <- 
	svydesign(
		id = ~SDMVPSU , 
		strata = ~SDMVSTRA ,
		nest = TRUE ,
		weights = ~WTMEC4YR ,
		data = x
	)


# create a subset of the survey design that only includes adults
# (the variable age was constructed to be missing for children)
nhanes.tsl.design.adults <- 
	subset( 
		nhanes.tsl.design , 	# object to subset
		!is.na( age ) 			# subset definition: wherever age is not missing
	)


# note about the factor( ) function used in the following examples:
# this function converts a linear variable (HBP contains ones and zeroes)
# into a categorical variable on the fly.
# this results in an output of proportions instead of a mean value.

# instead of using factor( HBP ) for every function call in the examples below,
# a variable can be permanently changed to a categorical variable with this code:

#	nhanes.tsl.design.adults <-
#		update(
#			nhanes.tsl.design.adults ,
#			HBP = factor( HBP )
#		 )

# # after this has been run, all commands using nhanes.tsl.design.adults will treat HBP as a categorical variable

# svymean( ~HBP , nhanes.tsl.design.adults , na.rm = T )

	
##############################################################
# print the exact contents of the cdc document to the screen #
##############################################################

# http://www.cdc.gov/nchs/tutorials/nhanes/downloads/Continuous/descriptive_proportion.pdf #

# calculate the sum of the weights in the pooled data set..
svytotal( 
	~one , 
	nhanes.tsl.design 
)

# ..and using the adult-only subset
svytotal( 
	~one , 
	nhanes.tsl.design.adults 
)


# calculate unweighted counts in the pooled data set..
unwtd.count( 
	~one , 
	nhanes.tsl.design 
)

# ..and using the adult-only subset
unwtd.count( 
	~one , 
	nhanes.tsl.design.adults 
)


# calculate the unweighted count of HBP in the pooled data set #
# note that (unlike the unwtd.count above) this includes only records that are not missing #
unwtd.count( ~factor( HBP ) , nhanes.tsl.design.adults , na.rm = T ) 

# calculate the mean and SE of the percent of adults with high blood pressure #
svymean( ~factor( HBP ) , nhanes.tsl.design.adults , na.rm = T ) 


# broken out by age categories #
svyby( ~factor( HBP ) , ~age , nhanes.tsl.design.adults , unwtd.count , na.rm = T )
svyby( ~factor( HBP ) , ~age , nhanes.tsl.design.adults , svymean , na.rm = T )

# broken out by race/ethnicity categories #
svyby( ~factor( HBP ) , ~race , nhanes.tsl.design.adults , unwtd.count , na.rm = T )
svyby( ~factor( HBP ) , ~race , nhanes.tsl.design.adults , svymean , na.rm = T )

# broken out by gender #
svyby( ~factor( HBP ) , ~RIAGENDR , nhanes.tsl.design.adults , unwtd.count , na.rm = T )
svyby( ~factor( HBP ) , ~RIAGENDR , nhanes.tsl.design.adults , svymean , na.rm = T )

# broken out by age + race/ethnicity categories #
svyby( ~factor( HBP ) , ~age + race , nhanes.tsl.design.adults , unwtd.count , na.rm = T )
svyby( ~factor( HBP ) , ~age + race , nhanes.tsl.design.adults , svymean , na.rm = T )

# broken out by gender + age categories #
svyby( ~factor( HBP ) , ~age + RIAGENDR , nhanes.tsl.design.adults , unwtd.count , na.rm = T )
svyby( ~factor( HBP ) , ~age + RIAGENDR , nhanes.tsl.design.adults , svymean , na.rm = T )

# broken out by race/ethnicity + age categories #
svyby( ~factor( HBP ) , ~race + RIAGENDR , nhanes.tsl.design.adults , unwtd.count , na.rm = T )
svyby( ~factor( HBP ) , ~race + RIAGENDR , nhanes.tsl.design.adults , svymean , na.rm = T )

# broken out by all three #
svyby( ~factor( HBP ) , ~age + race + RIAGENDR , nhanes.tsl.design.adults , unwtd.count , na.rm = T )
svyby( ~factor( HBP ) , ~age + race + RIAGENDR , nhanes.tsl.design.adults , svymean , na.rm = T )

################################
# end of replicated program #2 #
################################


# remove all objects in memory..
rm( list = ls( all = TRUE ) )

# ..and re-load the eight data frames.
load( "NHANES.9902.data.to.replicate.cdc.tables.rda" )


# # # # # # # # # # # # #
# replicated program #3 #
# # # # # # # # # # # # #
# the centers for disease control & prevention published this sas and sudaan syntax file:
# http://www.cdc.gov/nchs/tutorials/nhanes/downloads/Continuous/descriptive_percentile_SUDAAN.sas
# in order to generate the output found in this document:
# http://www.cdc.gov/nchs/tutorials/nhanes/downloads/Continuous/descriptive_percentile.pdf


# create a character vector that will be used to
# limit the two demographics files to only the variables needed
DemoKeepVars <-
	c( 
		"SEQN" , 		# unique person identifier (merge variable)
		
		"WTMEC4YR" , 	# the four-year interviewed + MEC examined weight
						# note that this is a special weight for only pooled data sets and
						# individuals who took the mobile examination center (MEC) exam
						# there are three other weights available:
						# only with vs. regardless of MEC and two-year (single) vs. four-year (pooled)
						
		"RIDSTATR" ,	# interviewed only or interviewed + MEC
		
		"SDMVPSU" , 	# primary sampling unit varaible, used in complex design
		
		"SDMVSTRA" , 	# strata variable, used in complex design
		
		"RIDAGEYR" ,	# person age
		
		"RIAGENDR" 		# gender
	)

# create a character vector that will be used to
# limit the laboratory file to only the variables needed
LabKeepVars <-
	c( 
		"SEQN" , 		# unique person identifier (merge variable)
		
		"LBXTC" 		# laboratory total cholesterol variable
	)

# stack (pool) the two demographics files together using the rbind (row-bind) function
NHANES.9902.demographics.df <-
	rbind( 
		NHANES.9900.demographics.df[ , DemoKeepVars ] ,		# when stacking, limit each data set to only the necessary variables, because
		NHANES.0102.demographics.df[ , DemoKeepVars ]		# the rbind function will break if any columns in the two stacked data sets do not match
	)
	
# stack (pool) the two laboratory files together using the rbind (row-bind) function
NHANES.9902.lab13.df <-
	rbind( 
		NHANES.9900.Lab13.df[ , LabKeepVars ] ,				# when stacking, limit each data set to only the necessary variables, because
		NHANES.0102.l13_b.df[ , LabKeepVars ]				# the rbind function will break if any columns in the two stacked data sets do not match
	)

# display the number of rows in each of these newly-pooled data sets
nrow( NHANES.9902.demographics.df )
nrow( NHANES.9902.lab13.df )

# display the first six records of each data set
head( NHANES.9902.demographics.df )
head( NHANES.9902.lab13.df )

# merge the two data sets together into a new data frame
# note that a 'by' variable does not need to be specified, because
# both data frames only share one variable - SEQN - 
# which will be used as the merge variable by default
NHANES.9902.demo.and.lab13.df <- 
	merge( 
		NHANES.9902.demographics.df , 
		NHANES.9902.lab13.df ,
		all = T						# all = T instructs r to keep all records, regardless of a match
	)

# immediately subset the merged data set
# to only contain individuals who were both 
# interviewed and received the mobile examination center (MEC)
NHANES.9902.demo.and.lab13.df <-
	subset( 
		NHANES.9902.demo.and.lab13.df ,			# object to subset
		RIDSTATR %in% 2							# subset definition: wherever RIDSTATR is two
	)
# note about which weight variable to use in the survey design construction below -
# this RIDSTATR line indicates that WTMEC2YR or WTMEC4YR should be used
# however, any analyses that only use interview variables (and are not limited by RIDSTATR)
# should use the weights WTINT2YR or WTINT4YR

# display the number of rows in the final merged data set
nrow( NHANES.9902.demo.and.lab13.df )

# display the first six records in the final merged data set
head( NHANES.9902.demo.and.lab13.df )


#######################################################################
# perform recodes to the merged, pooled, subsetted (final) data frame #
#######################################################################

NHANES.9902.demo.and.lab13.df <-

	transform( 
	
		NHANES.9902.demo.and.lab13.df ,
		
		# add a 'one' variable to the data frame to quickly total weighted counts in the survey design object
		one = 1 ,
		
		# create three age categories
		age = 
			
			# age 20 - 39
			ifelse( RIDAGEYR %in% 20:39 , 1 ,
			
			# age 40 - 59
			ifelse( RIDAGEYR %in% 40:59 , 2 ,
			
			# age 60 or above
			ifelse( RIDAGEYR >= 60 , 3 , 
			
			# OTHERWISE they are considered NA (missing) for the analysis
			# note that this includes all children (individuals younger than 20)

				NA ) ) ) 

	)
	
######################################################################
# end of recodes to the merged, pooled, subsetted (final) data frame #
######################################################################

#################################################
# survey design for taylor-series linearization #
#################################################

# create survey design object with NHANES design information
# using the pooled, merged data frame of NHANES data
nhanes.tsl.design <- 
	svydesign(
		id = ~SDMVPSU , 
		strata = ~SDMVSTRA ,
		nest = TRUE ,
		weights = ~WTMEC4YR ,
		data = NHANES.9902.demo.and.lab13.df
	)


#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in this pooled, merged nhanes #

# simply use the nrow function
nrow( nhanes.tsl.design )

# the nrow function which works on both data frame objects..
class( NHANES.9902.demo.and.lab13.df )
# ..and survey design objects
class( nhanes.tsl.design )

# create a subset of the survey design that only includes adults
# (the variable age was constructed to be missing for children)
nhanes.tsl.design.adults <- 
	subset( 
		nhanes.tsl.design , 	# object to subset
		!is.na( age ) 			# subset definition: wherever age is not missing
	)


##############################################################
# print the exact contents of the cdc document to the screen #
##############################################################

# NOTE the difference between the published cdc document and the output for percentile statistics:
# while all percentiles match the published numbers precisely, the confidence intervals of those statistics do not
# this is because SUDAAN changed their methodology for calculating SEs for quantiles after the cdc published this document
# see page 15 of this document for more detail
# http://www.rti.org/sudaan/pdf_files/SUDAAN_Example_Manual_Addendum_903.pdf
# current versions of sudaan do not match the SE values in that publication either


# calculate the sum of the weights in the pooled data set..
svytotal( 
	~one , 
	nhanes.tsl.design 
)

# ..and using the adult-only subset
svytotal( 
	~one , 
	nhanes.tsl.design.adults 
)


# calculate unweighted counts in the pooled data set..
unwtd.count( 
	~one , 
	nhanes.tsl.design 
)

# ..and using the adult-only subset
unwtd.count( 
	~one , 
	nhanes.tsl.design.adults 
)


# calculate the unweighted count of the adult-only pooled data set #
# who have a non-missing value for total cholesterol (mg/dL) #
unwtd.count( ~LBXTC , nhanes.tsl.design.adults )

# calculate the 5th, 25th, median, 75th, and 95th percentiles #
# and all associated confidence intervals #
# for nationwide total cholesterol (mg/dL) #
# among adults aged 20 and over #
svyquantile( 
	~LBXTC , 
	nhanes.tsl.design.adults , 
	c( .05 , .25 , .5 , .75 , .95 ) , 
	interval = 'betaWald' ,
	ties = "rounded" ,
	ci = T ,
	na.rm = T 
)

# broken out by age categories #
svyby( ~LBXTC , ~age , nhanes.tsl.design.adults , unwtd.count , na.rm = T )

svyby( 
	~LBXTC , 
	~age , 
	nhanes.tsl.design.adults , 
	svyquantile , 
	c( .05 , .25 , .5 , .75 , .95 ) , 
	interval = 'betaWald' ,
	ties = "rounded" ,
	ci = T , 
	na.rm = T
)
	
# broken out by gender #
svyby( ~LBXTC , ~RIAGENDR , nhanes.tsl.design.adults , unwtd.count , na.rm = T )

svyby( 
	~LBXTC , 
	~RIAGENDR , 
	nhanes.tsl.design.adults , 
	svyquantile , 
	c( .05 , .25 , .5 , .75 , .95 ) , 
	interval = 'betaWald' ,
	ties = "rounded" ,
	ci = T , 
	na.rm = T
)
	
# broken out by gender + age categories #
svyby( ~LBXTC , ~age + RIAGENDR , nhanes.tsl.design.adults , unwtd.count , na.rm = T )

svyby( 
	~LBXTC , 
	~age + RIAGENDR , 
	nhanes.tsl.design.adults , 
	svyquantile , 
	c( .05 , .25 , .5 , .75 , .95 ) , 
	interval = 'betaWald' ,
	ties = "rounded" ,
	ci = T , 
	na.rm = T
)

################################
# end of replicated program #3 #
################################


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
