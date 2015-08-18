# analyze survey data for free (http://asdfree.com) with the r language
# progress in international reading literacy study
# each and every available file hooray

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/PIRLS/" )
# source_url( "https://raw.github.com/ajdamico/asdfree/master/Progress%20in%20International%20Reading%20Literacy%20Study/download%20import%20and%20design.R" , prompt = FALSE , echo = TRUE )
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



#####################################################################
# get all progress in international reading literacy study files at #
# the boston college timss/pirls website, then import each file and #
# make a multiply-imputed complex sample svrepdesign object with r! #
#####################################################################


# remove the # in order to run this install.packages line only once
# install.packages( c( "survey" , "mitools" , "downloader" , "haven" ) )


# set your PIRLS data directory
# after downloading and importing
# all multiply-imputed, replicate-weighted complex-sample survey designs
# will be stored here
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PIRLS/" )


############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #

library(survey)				# load survey package (analyzes complex design surveys)
library(mitools) 			# load mitools package (analyzes multiply-imputed data)
library(downloader)			# downloads and then runs the source() function on scripts from github
library(haven) 				# load the haven package (imports dta files faaaaaast)

# specify that replicate-weighted complex sample survey design objects
# should calculate their variances by using the average of the replicates.
options( "survey.replicates.mse" = TRUE )

# load the download_cached and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url( 
	"https://raw.github.com/ajdamico/asdfree/master/Download%20Cache/download%20cache.R" , 
	prompt = FALSE , 
	echo = FALSE 
)

# load two pirls-specific replicate weighted survey design construction functions.
source_url( "https://raw.github.com/ajdamico/asdfree/master/Progress%20in%20International%20Reading%20Literacy%20Study/design%20functions.R" , prompt = FALSE )


# # # # # # # # # # # #
# download all files  #
# # # # # # # # # # # #

# specify the pathway to each and every spss data set to download.
ftd <-
	c(
		"http://timssandpirls.bc.edu/pirls2011/downloads/P11_SPSSData_pt1.zip" ,
		"http://timssandpirls.bc.edu/pirls2011/downloads/P11_SPSSData_pt2.zip" ,
		"http://timssandpirls.bc.edu/PDF/PIRLS2006_SPSSData.zip" ,
		"http://timssandpirls.bc.edu/pirls2001i/Pirls2001Database/pirls_2001_spssdata.zip"
	)

# initiate a temporary file
tf <- tempfile()

# set an empty year vector
years <- NULL

# for each file to download..
for ( i in ftd ){
	
	# figure out which year is this year
	this.year <- gsub( "(.*)(2[0-9][0-9][0-9])(.*)" , "\\2" , i )
	
	# confirm it's a realistic year
	stopifnot( this.year %in% 2000:2999 )
	
	# add a directory for that year
	dir.create( this.year , showWarnings = FALSE )
	
	# download the damn file
	download_cached( i , tf , mode = 'wb' )
	
	# unzip the damn file
	z <- unzip( tf , exdir = tempdir() )
	
	# copy all unzipped files into the year-appropriate directory
	stopifnot( all( file.copy( z , paste0( "./" , this.year , "/" , tolower( basename( z ) ) ) ) ) )
	
	# add this year to the `years` vector in case it isn't already there.
	years <- unique( c( years , this.year ) )
	
}


# # # # # # # # # # #
# import all files  #
# # # # # # # # # # #

# loop through each year of pirls data available
for ( this.year in years ){

	# construct a vector with all downloaded files
	files <- list.files( this.year , full.names = TRUE )
	
	# figure out the unique three-character prefixes of each file
	prefixes <- unique( substr( basename( files ) , 1 , 3 ) )

	# loop through each prefix
	for ( p in prefixes ){
	
		# initiate an empty object
		y <- NULL
		
		# loop through each saved file matching the prefix pattern
		for ( this.file in files[ substr( basename( files ) , 1 , 3 ) == p ] ){
		
			# read the file into RAM
			x <- read_spss( this.file )
			
			# coerce the file into a data.frame object
			x <- as.data.frame.matrix( x )
			
			# stack it
			y <- rbind( y , x )
			
			# remove the original file from the disk
			unlink( this.file )
			
		}
		
		# make all column names lowercase
		names( y ) <- tolower( names( y ) )
		
		# save the stacked file as the prefix
		assign( p , y )
		
		# save that single all-country stack-a-mole
		save( list = p , file = paste0( './' , this.year , '/' , p , '.rda' ) )
		
		# remove all those now-unnecessary objects from RAM
		rm( list = c( p , "y" ) )
		
	}
	
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# create multiply-imputed, replicate-weighted complex survey designs  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# loop through each year of data
for ( this.year in years ){

	# here are the combinations to create #
	
	# asa alone #
	load( paste0( './' , this.year , '/asa.rda' ) )
	asa_design <- pvsd( asa , 'totwgt' , rwcf( asa , 'totwgt' ) )
	save( asa_design , file = paste0( './' , this.year , '/asa_design.rda' ) )
	rm( asa , asa_design )
	
	# asg alone #
	load( paste0( './' , this.year , '/asg.rda' ) )
	asg_design <- pvsd( asg , 'totwgt' , rwcf( asg , 'totwgt' ) )
	save( asg_design , file = paste0( './' , this.year , '/asg_design.rda' ) )
	rm( asg , asg_design )
	
	# asg + ash
	load( paste0( './' , this.year , '/asg.rda' ) )
	load( paste0( './' , this.year , '/ash.rda' ) )
	# note: these two files are too big to merge in a smaller computer's RAM
	# so only keep the weighting/jackknife variables from the `asg` table for this iteration.
	asg_ash <- merge( asg[ , c( 'idcntry' , 'idstud' , 'totwgt' , 'jkzone' , 'jkrep' ) ] , ash , by = c( 'idcntry' , 'idstud' ) )
	stopifnot( nrow( asg_ash ) == nrow( ash ) & nrow( ash ) == nrow( asg ) )
	rm( asg , ash )
	asg_ash_design <- pvsd( asg_ash , 'totwgt' , rwcf( asg_ash , 'totwgt' ) )
	save( asg_ash_design , file = paste0( './' , this.year , '/asg_ash_design.rda' ) )
	rm( asg_ash_design , asg_ash )
	
	# asg + acg
	load( paste0( './' , this.year , '/asg.rda' ) )
	load( paste0( './' , this.year , '/acg.rda' ) )
	asg_acg <- merge( asg , acg , by = c( 'idcntry' , 'idschool' ) )
	stopifnot( nrow( asg_acg ) == nrow( asg ) )
	rm( asg , acg )
	asg_acg_design <- pvsd( asg_acg , 'totwgt' , rwcf( asg_acg , 'totwgt' ) )
	save( asg_acg_design , file = paste0( './' , this.year , '/asg_acg_design.rda' ) )
	rm( asg_acg_design , asg_acg )
	
	# ast alone #
	load( paste0( './' , this.year , '/ast.rda' ) )
	ast_design <- pvsd( ast , 'tchwgt' , rwcf( ast , 'tchwgt' ) )
	save( ast_design , file = paste0( './' , this.year , '/ast_design.rda' ) )
	rm( ast , ast_design )
	
	# ast + atg
	load( paste0( './' , this.year , '/ast.rda' ) )
	load( paste0( './' , this.year , '/atg.rda' ) )
	ast_atg <- merge( ast , atg , by = c( 'idcntry' , 'idteach' , 'idlink' ) )
	stopifnot( nrow( ast_atg ) == nrow( ast ) )
	rm( ast , atg )
	ast_atg_design <- pvsd( ast_atg , 'tchwgt' , rwcf( ast_atg , 'tchwgt' ) )
	save( ast_atg_design , file = paste0( './' , this.year , '/ast_atg_design.rda' ) )
	rm( ast_atg_design , ast_atg )
	
}

# the current working directory should now contain one r data file (.rda)
# for each multiply-imputed, replicate-weighted complex-sample survey design object
# plus the original prefixed data.frame objects, all separated by year-specific folders.


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
