# analyze us government survey data with the r language
# survey of income and program participation
# 2008 panel - longitudinal weight and replicate weight files

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


###################################################################################################################################
# Download All 2008 Panel Longitudinal Weight and Replicate Weight Files of the Survey of Income and Program Participation with R #
###################################################################################################################################


# set your working directory.
# all SIPP data files will be stored here
# after downloading and importing.
# use forward slashes instead of back slashes

setwd( "C:/My Directory/SIPP/" )


# remove the # in order to run this install.packages line only once
# install.packages( "SAScii" )

require(SAScii) 	# load the SAScii package (imports ascii data with a SAS script)


###############################################
# DATA LOADING COMPONENT - ONLY RUN THIS ONCE #
###############################################

# # # # # # # # # # # # # # # # #
# main longitudinal weight file #
# # # # # # # # # # # # # # # # #

# set the exact location of the sipp 2008 longitudinal weights data file on the census ftp
SIPP.w7.file.location <-
	"http://smpbff2.dsd.census.gov/pub/sipp/2008/lgtwgt2008w7.zip"

# set the exact location of the sipp 2008 longitudinal weights sas input script on the census ftp
SIPP.w7.SAS.read.in.instructions <-
	"http://smpbff2.dsd.census.gov/pub/sipp/2008/lgtwgt2008w7.sas"

# store the SIPP file as an R data frame
# note the text "INPUT" appears before the actual INPUT block of the SAS code
# so the parsing of the SAS instructions will fail without a beginline parameter specifying
# where the appropriate INPUT block occurs
SIPP.w7.df <-
	read.SAScii (
		SIPP.w7.file.location ,
		SIPP.w7.SAS.read.in.instructions ,
		beginline = 5 ,
		zipped = T 
	)

# the sas input script also defines all fields in uppercase format
# immediately convert all fields to lowercase (since R is case-sensitive)
names( SIPP.w7.df ) <- tolower( names( SIPP.w7.df ) )


# the sas input script defines the field ssuid as a text field
# immediately convert it to numeric
SIPP.w7.df$ssuid <- as.numeric( SIPP.w7.df$ssuid )

# save the data frame as an external file in the current working directory
save( SIPP.w7.df , file = "SIPP.w7.rda" )

# remove the data frame from memory
rm( SIPP.w7.df )

# clear memory
gc()



# # # # # # # # # # # # # # # # # # # # # # #
# longitudinal replicate panel weight files #
# # # # # # # # # # # # # # # # # # # # # # #

# set the exact location of the sipp 2008 longitudinal replicate panel weight sas input script on the census ftp
# this file is the same for all years, so don't include it within the loop
SIPP.lr.08.YY.SAS.read.in.instructions <-
	paste0( "http://smpbff2.dsd.census.gov/pub/sipp/2004/lrw04_xx.sas" )

# specify which longitudinal replicate panel weight years to download
lrpw.years.to.download <- c( "09" , "10" )

# loop through each of the years specified..
for ( i in lrpw.years.to.download ){

	# set the exact location of the sipp 2008 panel year replicate weight data file on the census ftp
	SIPP.08.pn.YY.file.location <-
		paste0( "http://smpbff2.dsd.census.gov/pub/sipp/2008/repwgt120_pnl" , i , ".zip" )

	# name the data frame based on the current year
	df.name <- paste0( "SIPP.08.pn." , i , ".df" )

	# store the SIPP file as an R data frame
	# note the text "INPUT" appears before the actual INPUT block of the SAS code
	# so the parsing of the SAS instructions will fail without a beginline parameter specifying
	# where the appropriate INPUT block occurs
	x <-
		read.SAScii (
			SIPP.08.pn.YY.file.location ,
			SIPP.lr.08.YY.SAS.read.in.instructions ,
			beginline = 5 ,
			zipped = T 
		)

	# the sas input script also defines all fields in uppercase format
	# immediately convert all fields to lowercase (since R is case-sensitive)
	names( x ) <- tolower( names( x ) )

	# assign the data frame x as a specific name
	# "SIPP.08.pn.##.df" -- where ## is the current year
	assign(	df.name , x )

	# save the data frame as an external file in the current working directory
	save( list = df.name , file = paste0( "SIPP.08.pn." , i , ".rda" ) )
	
	# remove the data frame from memory
	rm( list = df.name )
	
	# also remove x, the same data frame
	rm( x )
	
	# clear memory
	gc()

}


# # # # # # # # # # # # # # # # # # # # # # # # # # #
# longitudinal replicate calendar-year weight files #
# # # # # # # # # # # # # # # # # # # # # # # # # # #

# set the exact location of the sipp 2008 longitudinal replicate calendar-year weight sas input script on the census ftp
# this file is the same for all years, so don't include it within the loop
SIPP.lr.08.YY.SAS.read.in.instructions <-
	paste0( "http://smpbff2.dsd.census.gov/pub/sipp/2004/lrw04_xx.sas" )

# specify which longitudinal replicate calendar-year weight years to download
lrcyw.years.to.download <- c( "09" , "10" )

# loop through each of the years specified..
for ( i in lrcyw.years.to.download ){

	# set the exact location of the sipp 2008 calendar-year year replicate weight data file on the census ftp
	SIPP.08.cy.YY.file.location <-
		paste0( "http://smpbff2.dsd.census.gov/pub/sipp/2008/repwgt120_cy" , i , ".zip" )

	# name the data frame based on the current year
	df.name <- paste0( "SIPP.08.cy." , i , ".df" )

	# store the SIPP file as an R data frame
	# note the text "INPUT" appears before the actual INPUT block of the SAS code
	# so the parsing of the SAS instructions will fail without a beginline parameter specifying
	# where the appropriate INPUT block occurs
	x <-
		read.SAScii (
			SIPP.08.cy.YY.file.location ,
			SIPP.lr.08.YY.SAS.read.in.instructions ,
			beginline = 5 ,
			zipped = T 
		)

	# the sas input script also defines all fields in uppercase format
	# immediately convert all fields to lowercase (since R is case-sensitive)
	names( x ) <- tolower( names( x ) )

	# assign the data frame x as a specific name
	# "SIPP.08.cy.##.df" -- where ## is the current year
	assign(	df.name , x )

	# save the data frame as an external file in the current working directory
	save( list = df.name , file = paste0( "SIPP.08.cy." , i , ".rda" ) )
	
	# remove the data frame from memory
	rm( list = df.name )
	
	# also remove x, the same data frame
	rm( x )
	
	# clear memory
	gc()

}



# the current working directory should now contain R data (.rda) files
# for the overall longitudinal weights and the replicate weights for each specific year


# once complete, this script does not need to be run again.
# instead, use one of the survey of income and program participation analysis scripts
# which utilize these newly-created database (.rda) files


# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
