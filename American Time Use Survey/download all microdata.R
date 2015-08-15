# analyze survey data for free (http://asdfree.com) with the r language
# american time use survey
# 2003 - 2013

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/ATUS/" )
# years.to.download <- c( 2003:2013 , "0312" , "0313" )
# source_url( "https://raw.github.com/ajdamico/asdfree/master/American%20Time%20Use%20Survey/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
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


################################################################
# Analyze the 2003 - 2013 American Time Use Survey file with R #
################################################################


# set your working directory.
# the ATUS 2003 - 2013 data files will be stored here
# after downloading and importing them.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/ATUS/" )
# ..in order to set your current working directory



# define which years to download #

# uncomment this line to download all available data sets
# uncomment this line by removing the `#` at the front
# years.to.download <- c( 2003:2013 , "0312" , "0313" )

# uncomment this line to only download 2010
# years.to.download <- 2010

# uncomment this line to download, for example,
# 2005 and 2009-2011 and the '03-'12 multi-year file
# years.to.download <- c( 2005 , 2009:2011 , "0312" )


# remove the # in order to run this install.packages line only once
# install.packages( "downloader" , "digest" )


############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #

library(downloader)			# downloads and then runs the source() function on scripts from github

# specify the http path to the american time use survey on
# the bureau of labor statistics' website
http.dir <- "http://www.bls.gov/tus/special.requests/"

# create a temporary file
tf <- tempfile()


# load the download_cached and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url( 
	"https://raw.github.com/ajdamico/asdfree/master/Download%20Cache/download%20cache.R" , 
	prompt = FALSE , 
	echo = FALSE 
)


# begin looping through every atus year
# specified at the beginning of this program..
for ( year in years.to.download ){

	# create a year-specific directory
	# within your current working directory
	dir.create( paste0( "./" , year ) , showWarnings = FALSE )

	# figure out the website listing all available zipped files
	http.page <- 
		paste0( 
			"http://www.bls.gov/tus/datafiles_" ,
			year ,
			".htm" 
		)

	# download the contents of the website
	# to the temporary file
	download_cached( http.page , tf )

	# read the contents of that temporary file
	# into working memory (a character object called `txt`)
	txt <- readLines( tf )
	# if the object `txt` contains the page's contents,
	# you're cool.  otherwise, maybe look at this discussion
	# http://stackoverflow.com/questions/5227444/recursively-ftp-download-then-extract-gz-files
	# ..and tell me what you find.

	# keep only lines with a link to data files
	txt <- txt[ grep( ".zip" , txt , fixed = TRUE ) ]

	# isolate the zip filename #

	# first, remove everything before the `special.requests/tus/`..
	txt <- sapply( strsplit( txt , "/tus/special.requests/" ) , "[[" , 2 )

	# ..second, remove everything after the `.zip`
	all.files.on.page <- sapply( strsplit( txt , '.zip\">' ) , "[[" , 1 )

	# now you've got all the basenames
	# in the object `all.files.on.page`

	# remove all `lexicon` files.
	# you can download a specific year
	# for yourself if ya want.
	all.files.on.page <-
		all.files.on.page[ !grepl( 'lexiconwex' , all.files.on.page ) ]

	# loop through each of those year-specific files..
	for ( curFile in all.files.on.page ){

		# build a character string containing the
		# full filepath to the current zipped file
		fn <- paste0( http.dir , curFile , ".zip" )
		
		# download the file
		download_cached( fn , tf , mode = 'wb' )
		
		# extract the contents of the zipped file
		# into the current year-specific directory
		# and (at the same time) create an object called
		# `files.in.zip` that contains the paths on
		# your local computer to each of the unzipped files
		files.in.zip <- 
			unzip( tf , exdir = paste0( "./" , year ) )
		
		# find the data file
		csv.file <- 
			files.in.zip[ grep( ".dat" , files.in.zip , fixed = TRUE ) ]
		
		# read the data file in as a csv
		x <- read.csv( csv.file )
		
		# convert all column names to lowercase
		names( x ) <- tolower( names( x ) )
		
		# remove the _YYYY from the string containing the filename
		savename <- gsub( paste0( "_" , year ) , "" , curFile )

		# copy the object `x` over to another object
		# called whatever's in savename
		assign( savename , x )
		
		# delete the object `x` from working memory
		rm( x )
		
		# save the object named within savename
		# into an R data file (.rda) for easy loading later
		save( 
			list = savename , 
			file = paste0( "./" , year , "/" , savename , ".rda" ) 
		)
		
		# delete the savename object from working memory
		rm( list = savename )
		
		# clear up RAM
		gc()
		
		# delete the files that were unzipped
		# at the start of this loop,
		# including any directories
		unlink( files.in.zip , recursive = TRUE )
		
		# delete the temporary file
		# (which stored the zipped file)
		file.remove( tf )
		
	}
	
}

# print a reminder: set the directory you just saved everything to as read-only!
message( paste0( "all done.  you should set the file " , file.path( getwd() ) , " read-only so you don't accidentally alter these tables." ) )


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
