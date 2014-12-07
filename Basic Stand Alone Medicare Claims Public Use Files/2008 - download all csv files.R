# analyze survey data for free (http://asdfree.com) with the r language
# basic stand alone medicare claims public use files
# 2008 files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/BSAPUF/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Basic%20Stand%20Alone%20Medicare%20Claims%20Public%20Use%20Files/2008%20-%20download%20all%20csv%20files.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

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


#################################################################################
# download all 2008 comma separated value files for the bsa medicare puf with R #
#################################################################################


# all 2008 BSA data files will be stored
# in a newly-created "2008" in this directory
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/BSAPUF/" )

# remove the # in order to run this install.packages line only once
# install.packages( "downloader" )

# no need to edit anything below this line #


# # # # # # # # #
# program start #
# # # # # # # # #


library(downloader)	# downloads and then runs the source() function on scripts from github


# load the download.cache and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url( 
	"https://raw.github.com/ajdamico/usgsd/master/Download%20Cache/download%20cache.R" , 
	prompt = FALSE , 
	echo = FALSE 
)


# create and set the working directory to a year-specific folder #

# find the current working directory, and add "2008" at the end
current.year.folder <- normalizePath( paste0( getwd() , "/2008" ) )

# create a "2008" folder inside the current working directory
dir.create( current.year.folder )


# set the location of the two possible ftp sites containing the public use files
ftp.d <- "http://downloads.cms.gov/BSAPUF/"
ftp.l <- "https://www.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/BSAPUFS/Downloads/"

# create a temporary file on the local disk
tf <- tempfile()

# list all 2008 basic stand alone public use files
# note that some file types require multiple downloads (pde, carrier, outpatient)

# start of files to download #

# inpatient claims
inpatient <- "2008_BSA_Inpatient_Claims_PUF.zip"

# durable medical equipment
dme <- "2008_BSA_DME_Line_Items_PUF.zip"

# prescription drug events
pde <- paste0( "2008_BSA_PartD_Events_PUF_" , 1:5 , ".zip" )

# hospice
hospice <- "2008_BSA_Hospice_Beneficiary_PUF.zip"

# physician carrier
carrier <- paste0( "2008_BSA_Carrier_Line_Items_PUF_" , 1:7 , ".zip" )

# home health agency
hha <- "2008_BSA_HHA_Beneficiary_PUF.zip"

# outpatient
outpatient <- paste0( "2008_BSA_Outpatient_Procedures_PUF_" , 1:3 , ".zip" )

# skilled nursing facility
snf <- "2008_BSA_SNF_Beneficiary_PUF.zip"

# chronic conditions
cc <- "2008_Chronic_Conditions_PUF.zip" 

# institutional provider & beneficiary summary
ipbs <- "2008_IPBS_PUF.zip"

# prescription drug profiles
rxp <- "2008_PD_Profiles_PUF.zip"

# end of files to download #

# combine all zip file names into a single character vector
all.files <- c( inpatient , dme , pde , hospice , carrier , hha , outpatient , snf , cc , ipbs , rxp )

# loop through all zip filenames
for ( zf in all.files ){

	# try the download.
	attempt <- download.cache( paste0( ftp.l , zf ) , tf , FUN = download )
	
	# if there is really nothing in the file..
	if( length( readLines( tf , n = 10 ) ) == 0 ){
	
		# switch to the other url prefix
		
		# so long as the download didn't complete, keep trying.
		while( is.logical( attempt ) && !attempt ) attempt <- download.cache( paste0( ftp.d , zf ) , tf , FUN = download )

	# but if something (an incomplete file) was downloaded..
	} else {

		# so long as the download didn't complete, keep trying.
		while( is.logical( attempt ) && !attempt ) attempt <- download.cache( paste0( ftp.l , zf ) , tf , FUN = download )
		
	}
	
	# unzip the downloaded zip file into the current working directory
	unzip( tf , exdir = current.year.folder )
	
	# and delete the temporary zip file from the local disk
	file.remove( tf )

}

# the current working directory should now contain one comma separated value (.csv) file
# for each data set specified at the top of the script


# once complete, this script does not need to be run again for this year of data.
# instead, use the monetdb importation script to import these .csv files
# into a lightning-fast database for analysis


# print a reminder: set the directory you just saved everything to as read-only!
message( paste( "all done.  you should set" , getwd() , "read-only so you don't accidentally alter these files." ) )


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
