# analyze survey data for free (http://asdfree.com) with the r language
# programme for the international assessment of adult competencies
# each and every available file hooray

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/PIAAC/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Programme%20for%20the%20International%20Assessment%20of%20Adult%20Competencies/download%20import%20and%20design.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# https://www.youtube.com/watch?v=JLt9JfaAxUg

# anthony joseph damico
# ajdamico@gmail.com

# if you use this script for a project, please send me a note
# it's always nice to hear about how people are using this stuff

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf



#####################################################################################
# get all programme for the international assessment of adult competencies files at #
# the organisation for economic co-operation and development's website, then import #
# each file and make a multiply-imputed complex sample svrepdesign object with r!   #
#####################################################################################


# remove the # in order to run this install.packages line only once
# install.packages( c( "survey" , "mitools" , "downloader" , "digest" ) )


# set your PIAAC data directory
# after downloading and importing
# all multiply-imputed, replicate-weighted complex-sample survey designs
# will be stored here
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PIAAC/" )


############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #



library(survey)			# load survey package (analyzes complex design surveys)
library(mitools) 		# load mitools package (analyzes multiply-imputed data)
library(downloader)			# downloads and then runs the source() function on scripts from github


# load the download_cached and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url( 
	"https://raw.githubusercontent.com/ajdamico/asdfree/master/Download%20Cache/download%20cache.R" , 
	prompt = FALSE , 
	echo = FALSE 
)


# designate the oecd public use file page
oecd.csv.website <- 'http://vs-web-fs-1.oecd.org/piaac/puf-data/CSV/'

# download the contents of that page
csv.page <- readLines( oecd.csv.website )

# figure out all lines on that page with a hyperlink
csv.links <- unlist( strsplit( csv.page , "<A HREF=\"" ) )

# further refine the links to only the ones containing the text `CSV/[something].csv`
csv.texts <- csv.links[ grep( "(.*)CSV/(.*)\\.csv\">(.*)" , csv.links ) ]

# figure out the base filename of each csv on the website
csv.fns <- gsub( "(.*)CSV/(.*)\\.csv\">(.*)" , "\\2" , csv.texts )

# initiate a temporary file on the local computer
tf <- tempfile()

# R will exactly match SUDAAN results and Stata with the MSE option results
options( survey.replicates.mse = TRUE )
# otherwise if it is commented out or set to FALSE

# specify which variables are plausible values (i.e. multiply-imputed)
pvals <- c( 'pvlit' , 'pvnum' , 'pvpsl' )

# loop through each downloadable file..
for ( i in csv.fns ){

	# create a filename object, containing the lowercase of the csv filename
	fn <- tolower( i )

	# create a design object name, still just a string.
	design.name <- paste0( fn , ".design" )
	
	# construct the full filename of the csv file
	csv.filepath <- paste0( oecd.csv.website , i , ".csv" )

	# save the current csv file to the temporary location on the local disk
	download_cached( csv.filepath , tf , mode = 'wb' )

	# import the csv file into working memory
	x <- read.csv( tf , stringsAsFactors = FALSE )

	# convert all column names to lowercase
	names( x ) <- tolower( names( x ) )
		
	# paste together all of the plausible value variables with the numbers 1 through 10
	pvars <- outer( pvals , 1:10 , paste0 ) 

	# figure out which variables in the `x` data.frame object
	# are not plausible value columns
	non.pvals <- names( x )[ !( names( x ) %in% pvars ) ]

	# loop through each of the ten plausible values..
	for ( k in 1:10 ){

		# create a new `y` data.frame object containing only the
		# _current_ plausible value variable (for example: `pvlit4` and `pvnum4` and `pvpsl4`)
		# and also all of the columns that are not plausible value columns
		y <- x[ , c( non.pvals , paste0( pvals , k ) ) ]

		# inside of that loop..
		# loop through each of the plausible value variables
		for ( j in pvals ){
			
			# within this specific `y` data.frame object
			
			# get rid of the number on the end, so
			# first copy the `pvlit4` to `pvlit` etc. etc.
			y[ , j ] <- y[ , paste0( j , k ) ]
			
			# then delete the `pvlit4` variable etc. etc.
			y[ , paste0( j , k ) ] <- NULL
			
		}
		
		# save the current `y` data.frame object as `x#` instead.
		assign( paste0( 'x' , k ) , y )
		
		# remove `y` from working memory
		rm( y )
		
		# clear up RAM
		gc()
		
	}

	# smush all ten of these data.frame objects into one big list object
	w <- list( x1 , x2 , x3 , x4 , x5 , x6 , x7 , x8 , x9 , x10 )

	# remove the originals from memory
	rm( list = paste0( "x" , 1:10 ) )
	
	# clear up RAM
	gc()
	
	# note: the piaac requires different survey designs for different countries.  quoting their technical documentation:
	# "The variable VEMETHOD denoting whether it is the JK1 or JK2 formula that is applicable to different countries must be in the dataset"

	# figure out jackknife method to use from the original `x` data.frame object
	
	# determine the unique values of the `vemethod` column in the current data.frame object
	jk.method <- unique( x$vemethod )
	
	# confirm that they are all the same value.  if there are more than one unique values, this line will crash the program.
	stopifnot( length( jk.method ) == 1 )
	
	# confirm that the jackknife method is one of these.  if it's not, again, crash the program.
	stopifnot( jk.method %in% c( 'JK1' , 'JK2' ) )
	
	# where oecd statisticians say `JK2` the survey package needs a `JKn` instead
	if ( jk.method == 'JK2' ) jk.method <- 'JKn'

	# construct the full multiply-imputed, replicate-weighted, complex-sample survey design object
	z <-
		svrepdesign( 	
			weights = ~spfwt0 , 
			repweights = "spfwt[1-9]" ,
			rscales = rep( 1 , 80 ) ,
			scale = ifelse( jk.method == 'JKn' , 1 , 79 / 80 ) ,
			type = jk.method ,
			data = imputationList( w ) ,
			mse = TRUE
		)

	# save the originally imported data.frame object `x` to a data.frame named after the original filename
	assign( fn , x )
	
	# save this new survey design object `z` to a survey design named after the original filename
	assign( design.name , z )
	
	# save both objects together into a single `.rda` file
	save( list = c( fn , design.name ) , file = paste0( fn , ".rda" ) )

	# now that you've got what you came for, remove everything else from working memory
	rm( list = c( fn , design.name , "x" , "w" , "z" ) )

	# clear up RAM
	gc()

}

# remove the temporary file - where everything's been downloaded - from the hard disk
file.remove( tf )


# the current working directory should now contain one r data file (.rda)
# for each multiply-imputed, replicate-weighted complex-sample survey design object
# that's one for each available country


# print a reminder: set the directory you just saved everything to as read-only!
message( paste0( "all done.  you should set the directory " , getwd() , " read-only so you don't accidentally alter these tables." ) )


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
