# analyze us government survey data with the r language
# survey of income and program participation
# 2008 panel - wave-specific replicate weight files

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


#########################################################################################################################
# Download All 2008 Panel Wave-Specific Replicate Weight Files of the Survey of Income and Program Participation with R #
#########################################################################################################################


# set your working directory.
# all SIPP data files will be stored here
# after downloading and importing.
# use forward slashes instead of back slashes

setwd( "C:/My Directory/SIPP/" )


# remove the # in order to run this install.packages line only once
# install.packages( "SAScii" )

require(SAScii) 	# load the SAScii package (imports ascii data with a SAS script)

# choose which wave-specific replicate weight file waves to download
# recommended download: all available
sipp.datasets.to.download <- 1:9		# download waves 1 through 9

###############################################
# DATA LOADING COMPONENT - ONLY RUN THIS ONCE #
###############################################

# each of the wave-specific replicate weight file waves uses the same SAS input script
# so set this location only once before the loop
SIPP.rw.08w1.SAS.read.in.instructions <-
	"http://smpbff2.dsd.census.gov/pub/sipp/2008/rw08wx.sas"

# loop through each of the wave-specific replicate weight waves..
for ( i in sipp.datasets.to.download ){

	# set the exact location of the sipp 2008 data file on the census ftp
	SIPP.rw.08wX.file.location <-
		paste0( "http://smpbff2.dsd.census.gov/pub/sipp/2008/rw08w" , i , ".zip" )

	# name the data frame based on the current wave
	df.name <- paste0( "SIPP.rw.08w" , i , ".df" )

	# store the SIPP file as an R data frame
	# note the text "INPUT" appears before the actual INPUT block of the SAS code
	# so the parsing of the SAS instructions will fail without a beginline parameter specifying
	# where the appropriate INPUT block occurs
	x <-
		read.SAScii (
			SIPP.rw.08wX.file.location ,
			SIPP.rw.08w1.SAS.read.in.instructions ,
			beginline = 5 ,
			zipped = T 
		)

	# the sas input script also defines all fields in uppercase format
	# immediately convert all fields to lowercase (since R is case-sensitive)
	names( x ) <- tolower( names( x ) )

	# assign the data frame x as a specific name
	# "SIPP.rw.08w#.df" -- where # is the current wave
	assign(	df.name , x )

	# save the data frame as an external file in the current working directory
	save( list = df.name , file = paste0( "SIPP.rw.08w" , i , ".rda" ) )
	
	# remove the data frame from memory
	rm( list = df.name )
	
	# also remove x, the same data frame
	rm( x )
	
	# clear memory
	gc()

}


# the current working directory should now contain one R data (.rda) file
# for each wave specified in the "sipp.datasets.to.download" numeric vector object


# once complete, this script does not need to be run again.
# instead, use one of the survey of income and program participation analysis scripts
# which utilize these newly-created database (.rda) files


# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
