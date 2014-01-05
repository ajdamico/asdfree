# analyze survey data for free (http://asdfree.com) with the r language
# national health and nutrition examination survey
# replication of one figure published by the centers for disease control & prevention
# using 2005-2006 and 2007-2008 demographics and examination files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NHANES/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/National%20Health%20and%20Nutrition%20Examination%20Survey/replicate%202005-2008%20pooled%20cdc%20oral%20examination%20figure.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# the centers for disease control & prevention have published a brief on oral health at:
# http://www.cdc.gov/nchs/data/databriefs/db96.pdf

# this r script will replicate the results from figure two (seen on page 3)


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
# Analyze the 2005-2006 and 2007-2008 National Health and Nutrition Examination Survey demographics, laboratory, and examination files with R #
###############################################################################################################################################


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
# http://faculty.washington.edu/tlumley/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN



###############################################
# DATA LOADING COMPONENT - ONLY RUN THIS ONCE #
###############################################

# create new character variables containing the full ftp filepath of the files
# that need to be downloaded and imported into r for analysis
# this involves the 2005-2006 and 2007-2008 NHANES data sets,
# so two files will be downloaded for each component


# demographics, weighting, and complex design variables

NHANES.0506.demographics.file.location <-
	"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/nhanes/2005-2006/demo_d.xpt" 	# 2005-2006

NHANES.0708.demographics.file.location <-
	"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/nhanes/2007-2008/DEMO_E.xpt"	# 2007-2008


# oral health examination variables
	
NHANES.0506.OHX_D.file.location <-
	"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/nhanes/2005-2006/OHX_D.xpt"	# 2005-2006
	
NHANES.0708.OHX_E.file.location <-
	"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/nhanes/2007-2008/OHX_E.xpt"	# 2007-2008


###################################################
# download and import these four data sets into r #
# since the download and importation of all four  #
# data sets involves similar commands,            #
# create a function that automates the process    #
###################################################

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

NHANES.0506.demographics.df <-
	download.and.import.any.nhanes.file( NHANES.0506.demographics.file.location )

NHANES.0708.demographics.df <-
	download.and.import.any.nhanes.file( NHANES.0708.demographics.file.location )


# oral health examination variables

NHANES.0506.OHX_D.df <-
	download.and.import.any.nhanes.file( NHANES.0506.OHX_D.file.location )
	
NHANES.0708.OHX_E.df <-
	download.and.import.any.nhanes.file( NHANES.0708.OHX_E.file.location )


	
# save all four data frames now for instantaneous loading later.
# this stores the four NHANES 2005-2006 and 2007-2008 tables in a single R data file.
save(
	NHANES.0506.demographics.df ,
	NHANES.0708.demographics.df ,
	NHANES.0506.OHX_D.df ,
	NHANES.0708.OHX_E.df ,
	file = "NHANES.0508.data.to.replicate.cdc.figure.rda" 	# this is the output file name for the four data frames
)

# note that this .rda file will be stored in the local directory specified
# with the setwd command at the beginning of the script

##########################################################################
# END OF DATA LOADING COMPONENT - DO NOT RUN DATA LOADING COMMANDS AGAIN #
##########################################################################


# now the two data frames ending in ".df" can be loaded directly
# from your local hard drive.  this is much faster.
load( "NHANES.0508.data.to.replicate.cdc.figure.rda" )


# create a character vector that will be used to
# limit the two demographics files to only the variables needed
DemoKeepVars <-
	c( 
		"SEQN" , 		# unique person identifier (merge variable)
		
		"WTMEC2YR" , 	# the two-year interviewed + MEC examined weight
						# note that this is a special weight for only
						# individuals who took the mobile examination center (MEC) exam
						# there is one other weight available - WTINT2YR - 
						# that should be used when MEC variables are not part of the analysis
						
						# also note: for pooled data, divide this weight by the number of data sets pooled
						# in order to approximate the us civilian non-institutionalized population for the time period
		
		"INDFMPIR" ,	# ratio of family income to poverty
		
		"RIDSTATR" ,	# interviewed only or interviewed + MEC
		
		"SDMVPSU" , 	# primary sampling unit varaible, used in complex design
		
		"SDMVSTRA" , 	# strata variable, used in complex design
		
		"RIDRETH1" , 	# race / ethnicity

		"RIDAGEYR" 		# person age
	)

# create a character vector that will be used to
# limit the examination file to only the variables needed
ExamKeepVars <-
	c( 
		"SEQN" , 		# unique person identifier (merge variable)
		
		"OHXSEAL" 		# presence of at least one tooth with a dental preventive sealant
	)

# stack (pool) the two demographics files together using the rbind (row-bind) function
NHANES.0508.demographics.df <-
	rbind( 
		NHANES.0506.demographics.df[ , DemoKeepVars ] ,		# when stacking, limit each data set to only the necessary variables, because
		NHANES.0708.demographics.df[ , DemoKeepVars ]		# the rbind function will break if any columns in the two stacked data sets do not match
	)
	
# stack (pool) the two examination files together using the rbind (row-bind) function
NHANES.0508.OHX.df <-
	rbind( 
		NHANES.0506.OHX_D.df[ , ExamKeepVars ] ,			# when stacking, limit each data set to only the necessary variables, because
		NHANES.0708.OHX_E.df[ , ExamKeepVars ]				# the rbind function will break if any columns in the two stacked data sets do not match
	)


# display the number of rows in each of these newly-pooled data sets
nrow( NHANES.0508.demographics.df )
nrow( NHANES.0508.OHX.df )

# display the first six records of each data set
head( NHANES.0508.demographics.df )
head( NHANES.0508.OHX.df )

	
# merge the two data sets together into a new data frame
# note that a 'by' variable does not need to be specified, because
# both data frames only share one variable - SEQN - 
# which will be used as the merge variable by default
NHANES.0508.demo.and.OHX.df <- 
	merge( 
		NHANES.0508.demographics.df , 
		NHANES.0508.OHX.df ,
		all = T						# all = T instructs r to keep all records, regardless of a match
	)

# immediately subset the merged data set
# to only contain individuals who were both 
# interviewed and received the mobile examination center (MEC)
x <-
	subset( 
		NHANES.0508.demo.and.OHX.df ,			# object to subset
		RIDSTATR %in% 2							# subset definition: wherever RIDSTATR is two
	)
# note about which weight variable to use in the survey design construction below -
# this RIDSTATR line indicates that WTMEC2YR should be used
# however, any analyses that only use interview variables (and are not limited by RIDSTATR)
# should use the weight WTINT2YR

# additional recodes in the final data frame
x <-
	transform( 
		x ,

		# add a 'one' variable to the data frame to quickly total weighted counts in the survey design object
		one = 1 ,

		# make a new weight variable by dividing the current weight by the number of pooled data sets used in the analysis
		# the 2005-2006 data set and the 2007-2008 data set are pooled in this example,
		# so failing to divide by two will produce total population estimates that sum to 
		# approximately 600,000,000 americans instead of the appropriate number: approximately 300,000,000
		WTMEC4YR = WTMEC2YR / 2 ,
		
		# in the same step, throw out the two-year (single data set) weight to avoid confusion
		WTMEC2YR = NULL ,
		
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
				
		# recode the OHXSEAL variable
		ANYSEAL =
		
			ifelse( OHXSEAL %in% 9 , NA ,	# if the NHANES variable was "could not assess"
											# then assign the ANYSEAL variable to missing
											
			ifelse( OHXSEAL %in% 2 , 0 ,	# if the NHANES variable was two, change it to zero
			
				OHXSEAL ) ) ,				# otherwise, if it was a one or a missing, don't change it.
				
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

# create a subset of the survey design that only includes children aged 5 - 19
nhanes.tsl.design.kids <- 
	subset( 
		nhanes.tsl.design , 	# object to subset
		RIDAGEYR %in% 5:19		# subset definition: individuals aged 5 through 19
	)

# create four more very specific subsets that will be used for t-testing
nhanes.tsl.design.kids.white.and.black <-
	subset(
		nhanes.tsl.design.kids ,	# object to subset
		race %in% 1:2 				# subset definition: 
										# white non-hispanic and 
										# black non-hispanic
	)
	
nhanes.tsl.design.kids.white.and.hispanic <-
	subset(
		nhanes.tsl.design.kids ,	# object to subset
		race %in% c( 1 , 3 )		# subset definition: 
										# white non-hispanic and 
										# mexican american
	)
	
nhanes.tsl.design.kids.povcats.1.and.3 <-
	subset(
		nhanes.tsl.design.kids ,	# object to subset
		race %in% 1:2 				# subset definition: 
										# below poverty and 
										# at or above 200% of poverty
	)
	
nhanes.tsl.design.kids.povcats.2.and.3 <-
	subset(
		nhanes.tsl.design.kids ,	# object to subset
		race %in% c( 1 , 3 )		# subset definition: 
										# between 100 - 199% of poverty and 
										# at or above 200% of poverty
	)
			
	
#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in this pooled, merged nhanes #

# simply use the nrow function
nrow( nhanes.tsl.design )
nrow( nhanes.tsl.design.kids )

# the nrow function which works on both data frame objects..
class( x )
# ..and survey design objects
class( nhanes.tsl.design )


# count the weighted number of individuals in the pooled data file #

# this approximately generalizes to the civilian, # 
# non-institutionalized population of the united states #
svytotal( 
	~one , 
	nhanes.tsl.design 
)

# note that this is exactly equivalent to summing up the weight variable
# from the original NHANES data frame

sum( x$WTMEC4YR )

# ..and using the child-only subset
svytotal( 
	~one , 
	nhanes.tsl.design.kids 
)


############################################################
# print the exact contents of the cdc figure to the screen #
############################################################

# http://www.cdc.gov/nchs/data/databriefs/db96.pdf #

# calculate the overall percent of 5 - 19 year olds with any sealant
# ..and print overall results to the screen - parentheses outside a command prints that object
( overall <- svymean( ~ANYSEAL , nhanes.tsl.design.kids , na.rm = T ) )


# broken out by race/ethnicity categories #
# ..and print by race results to the screen - parentheses outside a command prints that object
( by.race <- svyby( ~ANYSEAL , ~race , nhanes.tsl.design.kids , svymean , na.rm = T ) )


# broken out by poverty categories #
# ..and print by poverty results to the screen - parentheses outside a command prints that object
( by.poverty <- svyby( ~ANYSEAL , ~POVCAT , nhanes.tsl.design.kids , svymean , na.rm = T ) )

###########
# t tests #
###########

# each of these tests answer the question:
# is there a statistically significant different rate of having a dental sealant between the two groups tested?

# compare white vs. black #
svyttest( ANYSEAL ~ race , nhanes.tsl.design.kids.white.and.black )

# compare white vs. mexican #
svyttest( ANYSEAL ~ race , nhanes.tsl.design.kids.white.and.hispanic )

# compare below poverty to at or above 200% of poverty #
svyttest( ANYSEAL ~ POVCAT , nhanes.tsl.design.kids.povcats.1.and.3 )

# compare 100 - 199% of poverty to at or above 200% of poverty #
svyttest( ANYSEAL ~ POVCAT , nhanes.tsl.design.kids.povcats.2.and.3 )


##########################################
# create a barplot that matches figure 2 #
##########################################

# store the final seven values into a single numeric vector
final.values <-
	c( 
		coef( overall ) ,			# extract the overall statistic
		coef( by.race )[ 1:3 ] ,	# extract only the first three (of four) race categories
		coef( by.poverty ) 			# extract all three poverty statistics
	)

# store the seven colors that each of the statistics' bars should be
vector.of.colors <-
	c( 
		"gray" ,
		"blue" , "blue" , "blue" , 
		"green" , "green" , "green" 
	) 

# store the labels for each statistics - note that the \n creates a return character
vector.of.labels <-
	c( 
		"overall" ,
		"white\nnon-hispanic" , "black\nnon-hispanic" , "mexican" , 
		"below poverty" , "100 - 199%\nof poverty" , "at or above\n200% of poverty" 
	) 
	
# initiate the bar plot object
barplot( 
	rev( final.values ) , 					# the first parameter contains the data (in reverse order)
	names.arg = rev( vector.of.labels ) ,	# names.arg contains the labels (also in reverse order)
	col = rev( vector.of.colors ) , 		# col contains the bar colors (also in reverse order)
	horiz = TRUE , 							# display the barplot horizontally instead of vertically (the default)
	xlim = c( 0 , .35 ) , 					# have the x axis span from zero to 0.35
	axes = FALSE ,							# to not initiate the axes when creating the barplot
	xlab = 'Percents' ,						# label the x axis
	cex.names = .6							# choose a size for the text
)

# add an axis to the current bar plot
axis( 
	1 , 									# this first parameter - 1 - specifies which side to add the axis on.  1 indicates 'below'
	at = seq( 0 , .35 , by = .05 ) , 		# place tick-marks at 0 through 0.35, counting upward by 0.05
	labels = seq( 0 , 35 , by = 5 ) 		# label those tick-marks 0 through 35, counting upward by 5
)

################################
# end of replication of figure #
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
