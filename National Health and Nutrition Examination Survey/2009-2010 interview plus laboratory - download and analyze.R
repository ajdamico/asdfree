# analyze survey data for free (http://asdfree.com) with the r language
# national health and nutrition examination survey
# 2009-2010 demographics and laboratory files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NHANES/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Health%20and%20Nutrition%20Examination%20Survey/2009-2010%20interview%20plus%20laboratory%20-%20download%20and%20analyze.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# the centers for disease control & prevention have published a brief on high cholesterol at:
# http://www.cdc.gov/nchs/data/databriefs/db92.pdf

# this r script will replicate the results from figure one (seen on page 1)


# contact me directly for free help or for paid consulting work

# anthony joseph damico the first
# ajdamico@gmail.com

###################################################################################################################
# Analyze the 2009-2010 National Health and Nutrition Examination Survey demographics and laboratory files with R #
###################################################################################################################


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


# total cholesterol variables (from the mobile examination center / laboratory component)
	
NHANES.0910.TCHOL_F.file.location <-
	"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/nhanes/2009-2010/TCHOL_F.xpt"	# 2009-2010

	

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

	
# total cholesterol variables

NHANES.0910.TCHOL_F.df <-
	download.and.import.any.nhanes.file( NHANES.0910.TCHOL_F.file.location )
	


# save both data frames now for instantaneous loading later.
# this stores these two NHANES 2009-2010 tables in a single R data file.
save(
	NHANES.0910.demographics.df ,
	NHANES.0910.TCHOL_F.df ,
	file = "NHANES.0910.demo.and.tchol.rda" 	# this is the output file name for the two data frames
)

# note that this .rda file will be stored in the local directory specified
# with the setwd command at the beginning of the script

##########################################################################
# END OF DATA LOADING COMPONENT - DO NOT RUN DATA LOADING COMMANDS AGAIN #
##########################################################################


# now the two data frames ending in ".df" can be loaded directly
# from your local hard drive.  this is much faster.
load( "NHANES.0910.demo.and.tchol.rda" )


# create a character vector that will be used to
# limit the demographics file to only the variables needed
DemoKeepVars <-
	c( 
		"SEQN" , 		# unique person identifier (merge variable)
		
		"WTMEC2YR" , 	# the two-year mobile examination center weight
						# note that this is the weight for only analyses that require MEC variables
						
						# if none of the variables used in the analysis were from
						# individuals who took the mobile examination center (MEC) exam,
						# then the two-year interview weight (WTINT2YR) should be used instead
						
						# also note: for pooled data, divide this weight by the number of data sets pooled
						# in order to approximate the us civilian non-institutionalized population for the time period
		
		"RIDSTATR" ,	# interviewed only or interviewed + MEC
		
		"SDMVPSU" , 	# primary sampling unit varaible, used in complex design
		
		"SDMVSTRA" , 	# strata variable, used in complex design
		
		"RIDRETH1" ,	# person race / ethnicity
		
		"RIDAGEYR" ,	# person age
		
		"RIAGENDR" 		# gender
	)


# create a character vector that will be used to
# limit the laboratory file to only the variables needed
TCHOLKeepVars <-
	c( 
		"SEQN" , 		# unique person identifier (merge variable)
		
		"LBXTC" 		# laboratory total cholesterol variable, from
						# http://www.cdc.gov/nchs/nhanes/nhanes2009-2010/TCHOL_F.htm#LBXTC
	)


# display the number of rows in the demographics and total cholesterol questionnaire data sets
nrow( NHANES.0910.demographics.df )
nrow( NHANES.0910.TCHOL_F.df )

# note that since not individuals with demographic information completed the mobile examination center component
# therefore, the number of rows in both data sets should not be equal!

# display the first six records of each data set - this includes lots of unnecessary columns
head( NHANES.0910.demographics.df )
head( NHANES.0910.TCHOL_F.df )


# limit the demographics and total cholesterol data sets to only the variables needed for the analysis
# this step overwrites the data frame with itself, throwing out unnecessary columns
NHANES.0910.demographics.df <-
	NHANES.0910.demographics.df[ , DemoKeepVars ]
	
NHANES.0910.TCHOL_F.df <-
	NHANES.0910.TCHOL_F.df[ , TCHOLKeepVars ]
	

# display the first six records of each data set - this now shows only the columns needed for the analysis
head( NHANES.0910.demographics.df )
head( NHANES.0910.TCHOL_F.df )


# merge the two data sets together into a new data frame
# note that a 'by' variable does not need to be specified, because
# both data frames only share one variable - SEQN - 
# which will be used as the merge variable by default
NHANES.0910.demo.and.TCHOL_F.df <- 
	merge( 
		NHANES.0910.demographics.df , 
		NHANES.0910.TCHOL_F.df ,
		all = T						# all = T instructs r to keep all records, regardless of a match
									# all = F instructs r to throw out records on both sides if there is no match
									# all = T should be used for this merge, because not all records in the
									# demographics file have a match in the total cholesterol (laboratory) file
	)

# notice that the number of rows of the merged data set
# exactly equals the number of rows in the demographics data set - as it should!
nrow( NHANES.0910.demo.and.TCHOL_F.df )

# copy the merged data frame over to a new object - x - just for ease of typing
x <- NHANES.0910.demo.and.TCHOL_F.df

# remove the merged data frame from memory, and start using the data frame x from now on
rm( NHANES.0910.demo.and.TCHOL_F.df )


# subset the data frame to only respondents with both interview + MEC data

# keep only individuals who took the "mobile examination center" component as defined by RIDSTATR, from
# http://www.cdc.gov/nchs/nhanes/nhanes2009-2010/DEMO_F.htm#RIDSTATR
x <- subset( x , RIDSTATR %in% 2 )


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

		# define high total cholesterol as 1 if mg/dL is at or above 240 and zero otherwise.
		HI_TCHOL = ifelse( LBXTC >= 240 , 1 , 0 ) ,
		
		# recode the RIDRETH1 variable as:
		# mexican american and other hispanic -> 3
		# non-hispanic white -> 1
		# non-hispanic black -> 2
		# other race including multi-racial -> 4
		race = c( 3 , 3 , 1 , 2 , 4 )[ RIDRETH1 ] ,
		# for more details, see
		# http://www.cdc.gov/nchs/nhanes/nhanes2009-2010/DEMO_F.htm#RIDRETH1
		
		# create a new variable 'agecat' with four values:
		# 0-19 becomes a 1
		# 20-39 becomes a 2
		# 40-59 becomes a 3
		# 60 and above becomes a 4
		agecat = cut( RIDAGEYR , c( 0 , 19 , 39 , 59 , Inf ) , labels = 1:4 )
		
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
		weights = ~WTMEC2YR ,
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
# broken out by race/ethnicity category #

svyby(
	~HI_TCHOL ,
	~race ,
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

sum( x$WTMEC2YR )

# the civilian, non-institutionalized population of the united states #
# by race/ethnicity category
svyby(
	~one ,
	~race ,
	nhanes.tsl.design ,
	svytotal
)


# calculate the mean of a linear variable #

# note that although this variable only contains the values 0 and 1,
# running a svymean function on it will calculate the appropriate percent - the nationwide prevalence

# percent with high cholesterol - nationwide
svymean( 
	~HI_TCHOL , 
	design = nhanes.tsl.design ,
	na.rm = TRUE
)

# by race/ethnicity category
svyby( 
	~HI_TCHOL , 
	~race ,
	design = nhanes.tsl.design ,
	svymean ,
	na.rm = TRUE
)


######################
# subsetting example #
######################

# restrict the nhanes.tsl.design object to
# adults only
nhanes.tsl.design.adults <-
	subset(
		nhanes.tsl.design ,
		agecat %in% 2:4			# in the recodes, agecat = 1 included all individuals under 21
								# this limits the population in the survey object 
								# to only individuals age 21 and above
	)

	
######################################
# begin analyses that match figure 1 #

# http://www.cdc.gov/nchs/data/databriefs/db96.pdf #

	
# these following four commands calculate estimates of high total cholesterol that are not age-adjusted

# nationwide, adults only
svymean( ~HI_TCHOL , nhanes.tsl.design.adults , na.rm = TRUE )
# broken out by race / ethnicity category
svyby( ~HI_TCHOL , ~race , nhanes.tsl.design.adults , svymean , na.rm = TRUE )
# broken out by gender
svyby( ~HI_TCHOL , ~RIAGENDR , nhanes.tsl.design.adults , svymean , na.rm = TRUE )
# broken out by both gender and race / ethnicity category
svyby( ~HI_TCHOL , ~RIAGENDR+race , nhanes.tsl.design.adults , svymean , na.rm = TRUE )


###################################	
# direct method of age-adjustment #
###################################

# note that the previous four commands do not match the figure exactly.
# replicating figure 1 requires age-adjusting each analysis to the 2000 census population-by-age categories
# using the direct method, described on http://www.cdc.gov/nchs/tutorials/nhanes/nhanesanalyses/agestandardization/Task1c.htm

# 2000 census populations to adjust to
# from excel file: http://www.cdc.gov/nchs/tutorials/nhanes/Downloads/Continuous/ageadjwt.xls

# create a data frame containing the four population strata

pop.by.age <- 
	data.frame( 
		agecat = 1:4 , 
		Freq = c( 55901 , 77670 , 72816 , 45364 ) 
	) 	

# print that data frame to the screen
pop.by.age

# this data frame contains the information that the year 2000 united states population was approximately
# 56 million 0-19 year olds
# 77 million 20-39 year olds
# 73 million 40-59 year olds
# 45 million 60+ year olds
	

############################################################
# print the exact contents of the cdc figure to the screen #
############################################################

# create a new survey object with the nationwide population stratified to the above census counts #
nhanes.age.adjusted <-
	postStratify( 
		subset( nhanes.tsl.design , !is.na( HI_TCHOL ) ) , 
		~agecat , 
		pop.by.age 
	)

# print the high total cholesterol prevalence for adults only #
svymean( 
	~HI_TCHOL , 
	subset( nhanes.age.adjusted , agecat %in% 2:4 ) , 					# this subset function removes individuals under 21 years old
	na.rm = TRUE
)


# create a new survey object stratified to the census counts, broken out by gender #
nhanes.by.gender <-
	svystandardize(
		nhanes.tsl.design , 
		by = ~agecat , 										# stratification variable
		over = ~RIAGENDR ,									# break out variable
		population = pop.by.age , 							# data frame containing census populations
		excluding.missing = ~HI_TCHOL 						# analysis variable of interest
	)

# print the high total cholesterol prevalence for adults only, broken out by gender #
svyby( 
	~HI_TCHOL , 
	~race , 
	design = subset( nhanes.by.gender , agecat %in% 2:4 ) , 			# this subset function removes individuals under 21 years old
	svymean , 
	na.rm=TRUE
)


# create a new survey object stratified to the census counts, broken out by race / ethnicity #
nhanes.by.race <-
	svystandardize(
		nhanes.tsl.design , 
		by = ~agecat , 										# stratification variable
		over = ~race ,										# break out variable
		population = pop.by.age , 							# data frame containing census populations
		excluding.missing = ~HI_TCHOL 						# analysis variable of interest
	)

# print the high total cholesterol prevalence for adults only, broken out by race / ethnicity #
svyby( 
	~HI_TCHOL , 
	~race , 
	design = subset( nhanes.by.race , agecat %in% 2:4 ) ,				# this subset function removes individuals under 21 years old
	svymean , 
	na.rm=TRUE
)
	

# create a new survey object stratified to the census counts, broken out by both race / ethnicity and gender #
nhanes.by.race.and.gender <-
	svystandardize(
		nhanes.tsl.design , 
		by = ~agecat , 										# stratification variable
		over = ~race + RIAGENDR ,							# break out variable
		population = pop.by.age , 							# data frame containing census populations
		excluding.missing = ~HI_TCHOL 						# analysis variable of interest
	)

# print the high total cholesterol prevalence for adults only, broken out by race / ethnicity and gender#
svyby( 
	~HI_TCHOL , 
	~race + RIAGENDR , 
	design = subset( nhanes.by.race.and.gender , agecat %in% 2:4 ) ,	# this subset function removes individuals under 21 years old
	svymean , 
	na.rm=TRUE
)
	

################################################################
# end of cdc high total cholesterol brief figure 1 replication #
################################################################

	
# # # # # # # # # # # # # # # # # # # # # #
# additional analysis and export examples #
# # # # # # # # # # # # # # # # # # # # # #

# for more examples of how to both analyze and then quickly export results,
# check out the NHANES script in this folder titled,
# 2009-2010 interview only - download and analyze.R
	
################################################################
