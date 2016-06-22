# analyze survey data for free (http://asdfree.com) with the r language
# national health interview survey
# 2000 personsx and incmimp

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NHIS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Health%20Interview%20Survey/replicate%20cdc%20tecdoc%20-%202000%20multiple%20imputation.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico the first
# ajdamico@gmail.com


#####################################################
# this script matches the statistics on page 60 of  #
# http://www.cdc.gov/nchs/data/nhis/tecdoc_2010.pdf #
#####################################################


######################################################
# analyze the 2000 National Health Interview Survey  #
# personsx file and multiple imputation with R       #
######################################################


# set your working directory.
# the NHIS 2000 personsx and incmimp data files
# will be stored here after downloading and importing them.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NHIS/" )
# ..in order to set your current working directory


# remove the # in order to run this install.packages line only once
# install.packages( c( "survey" , "SAScii" , "mitools" , "RCurl" ) )


library(survey)		# load survey package (analyzes complex design surveys)
library(SAScii)		# load the SAScii package (imports ascii data with a SAS script)
library(mitools)	# load mitools package (analyzes multiply-imputed data)
library(RCurl)		# load RCurl package (downloads https files)

# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
# options( survey.lonely.psu = "adjust" )

#############################################
#DATA LOADING COMPONENT - ONLY RUN THIS ONCE#
#############################################

# this process is slow.
# note the record counter while waiting for these commands to run.
# the NHIS 2000 personsx file has 100,618 records.

NHIS.00.personsx.SAS.read.in.instructions <-
	"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Program_Code/NHIS/2000/personsx.sas"
	
NHIS.00.personsx.file.location <-
	"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/2000/personsx.exe"

# store the NHIS file as an R data frame
NHIS.00.personsx.df <-
	read.SAScii (
		NHIS.00.personsx.file.location ,
		NHIS.00.personsx.SAS.read.in.instructions ,
		zipped = T 
	)

# the read.SAScii function produces column names with all capital letters
# convert them all to lowercase
names( NHIS.00.personsx.df ) <- tolower( names( NHIS.00.personsx.df ) )


# this process is also slow.
# note the record counter while waiting for these commands to run.
# each of the five incmimp files have 100,618 records.

# location of incmimp sas import file - no longer hosted on the cdc's ftp site
incmimp.sas <- 
	"https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Health%20Interview%20Survey/INCMIMP2000.sas"

# location of incmimp ascii data files
incmimp.exe <- 
	"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/2000_Imputed_Income/INCMIMP.EXE"

# create temporary files to store the INCMIMP.EXE and INCMIMP.SAS files on your local computer
tf <- tempfile()
tf.sas <- tempfile()

# create a file connection to the tf.sas location
outcon.sas <- file(tf.sas, "w") 

# create a temporary directory to store the five unzipped incmimp files
td <- tempdir()

# download INCMIMP.EXE to a temporary file
download.file( incmimp.exe , tf , mode = "wb" )

# download INCMIMP.SAS using https, then store it through the file connection
sas.instructions <- getURL( incmimp.sas , ssl.verifypeer = FALSE )
writeLines( sas.instructions , outcon.sas )


# unpack the incmimp.exe file to the temporary directory
# store the file names of the five incmimp files
# into the object "income.file.names"
income.file.names <- sort( unzip( tf , exdir = td ) )

# loop through all five imputed income files
for ( i in 1:5 ){

	# print current progress to the screen
	print( paste( "currently working on imputed income file" , i , "of 5" ) )

	# read the ascii dat file directly into R
	incmimp <- 
		read.SAScii( 
			income.file.names[ i ] , 
			tf.sas ,
			beginline = 108
		)

	# the read.SAScii function produces column names with all capital letters
	# convert them all to lowercase
	names( incmimp ) <- tolower( names( incmimp ) )

	# dump rectype variable from the incmimp- it is already on the personsx file
	incmimp$rectype <- NULL
	
	# store the imputed income data table into variables incmimp1 - incmimp5
	assign( 
		paste0( "incmimp" , i ) , 
		incmimp
	)
	
	# delete incmimp (since it's also saved as incmimp1 - incmimp5)
	incmimp <- NULL
	
	# garbage collection - free up RAM from recently-deleted data tables
	gc()
	
}

# save six data frames now for instantaneous loading later.
# this stores the NHIS 2000 personsx table
# as well as the five incmimp1 - incmimp5 data files
# into a single R data file

save( 
	list = 
		c( 
			"NHIS.00.personsx.df" , 
			paste0( "incmimp" , 1:5 ) 
		) , 
	file = "NHIS.00.personsx.data.rda"
)

########################################################################
#END OF DATA LOADING COMPONENT - DO NOT RUN DATA LOADING COMMANDS AGAIN#
########################################################################

# now the "NHIS.00.personsx.df" and five incmimp data frames can be loaded directly
# from your local hard drive.  this is much faster.
load( "NHIS.00.personsx.data.rda" )


# only keep the variables you need
# (to conserve RAM)
KeepVars <-
	c(
		"srvy_yr" , "hhx" , "fmx" , "px" , 
		"psu" , "stratum" , "wtfa" , "notcov" 
	)

NHIS.00.personsx.df <- 
	NHIS.00.personsx.df[ , KeepVars ]


# loop through all five imputed income files
for ( i in 1:5 ){

	# merge the personsx file with each of the five imputed income files
	y <- 
		merge( 
			NHIS.00.personsx.df , 				# 2000 personsx data frame
			get( paste0( "incmimp" , i ) ) , 	# incmimp1 - incmimp5
			by.x = c( "srvy_yr" , "hhx" , "fmx" , "px" ) , 
			by.y = c( "srvy_yr" , "hhx" , "fmx" , "fpx" ) 
		)

		
	##############################
	# START OF VARIABLE RECODING #
	# any new variables that the user would like to create should be constructed here #

	# create the notcov variable
	# shown on page 47 (PDF page 51) of 
	# http://www.cdc.gov/nchs/data/nhis/tecdoc_2010.pdf
	y <- 
		transform( 
			y , 
			notcov = 
				ifelse( 
					notcov %in% 7:9 , 
					NA , 
					notcov 
				)
		)
	
	# create the povertyi variable
	# shown on page 48 (PDF page 52) of 
	# http://www.cdc.gov/nchs/data/nhis/tecdoc_2010.pdf
	y <- 
		transform( 
			y , 
			povertyi =
				cut( 
					rat_cati , 
					c( 0 , 3 , 7 , 11 , 15 ) ,
					labels = c( "<100%" , "100-199%" , "200-399%" , "400%+" )
				)
		)

	# END OF VARIABLE RECODING #
	############################
		
	# save the data frames as objects x1 - x5, depending on the iteration in the loop
	assign( paste0( 'x' , i ) , y )

	# delete the y and incmimp data frames
	y <- NULL
	assign( paste0( "incmimp" , i ) , NULL )
	
	# garbage collection - free up RAM from recently-deleted data tables
	gc()
}

# delete the main personsx data frame
NHIS.00.personsx.df <- NULL

# garbage collection - free up RAM from recently-deleted data tables
gc()


# when the loop has terminated, data frames x1 through x5 exist
# each are the personsx file merged with one of the five imputed income files
# and each include all recoded variables.

# using all five merged personsx-MI files,
# create the multiple imputation survey object
nhissvy <-
	svydesign( 
		id = ~psu , 
		strata = ~stratum , 
		weight = ~wtfa , 
		data = 
			imputationList( 
				list( x1 , x2 , x3 , x4 , x5 ) 
			) , 
		nest=T
	)

# if you run out of RAM, uncomment this line to
# delete the personsx and x1 - x5 data frame objects

# personsx <- x1 <- x2 <- x3 <- x4 <- x5 <- NULL

#garbage collection - free up RAM from recently-deleted data tables
gc()

##################################################################
# now that the R survey object (nhissvy) has been constructed,
# analyses can be run.

# the following output matches PDF page 60 on http://www.cdc.gov/nchs/data/nhis/tecdoc_2010.pdf

# this displays the crosstab statistics..

	# not broken out by the notcov variable

# print the unweighted N
MIcombine( with( subset( nhissvy , !is.na( povertyi ) ), unwtd.count( ~factor(notcov) , na.rm=T ) ) )

# print the weighted N
MIcombine( with( subset( nhissvy , !is.na( povertyi ) ) , svytotal( ~factor(notcov) , na.rm=T ) ) )

# print the overall percents
MIcombine( with( subset( nhissvy , !is.na( povertyi ) ) , svymean( ~factor(notcov) , na.rm=T ) ) )

	# not broken out by the povertyi variable

# print the unweighted N
MIcombine( with( subset( nhissvy , !is.na( notcov ) ), unwtd.count( ~factor(povertyi) , na.rm=T ) ) )

# print the weighted N
MIcombine( with( subset( nhissvy , !is.na( notcov ) ) , svytotal( ~factor(povertyi) , na.rm=T ) ) )

# print the overall percents
MIcombine( with( subset( nhissvy , !is.na( notcov ) ) , svymean( ~factor(povertyi) , na.rm=T ) ) )

	# broken out by the notcov and povertyi variables

# print the unweighted N
MIcombine( with( nhissvy , svyby(~factor(notcov) , ~factor(povertyi) , unwtd.count , na.rm=T ) ) )

# print the weighted N
MIcombine( with( nhissvy , svyby(~factor(notcov) , ~factor(povertyi) , svytotal , na.rm=T ) ) )

# print the row percents
MIcombine( with( nhissvy , svyby(~factor(notcov) , ~factor(povertyi) , svymean , na.rm=T ) ) )


