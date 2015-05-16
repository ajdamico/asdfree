# analyze survey data for free (http://asdfree.com) with the r language
# trends in international mathematics and science study
# each and every available file hooray

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/TIMSS/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Trends%20in%20International%20Mathematics%20and%20Science%20Study/download%20import%20and%20design.R" , prompt = FALSE , echo = TRUE )
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



##########################################################################
# get all trends in international mathematics and science study files at #
# the boston college timss/pirls website, then import each file and make #
# a multiply-imputed complex sample svrepdesign object with r!           #
##########################################################################


# remove the # in order to run this install.packages line only once
# install.packages( c( "survey" , "mitools" , "downloader" , "haven" , "SAScii" , "RSQLite" ) )


# set your TIMSS data directory
# after downloading and importing
# all multiply-imputed, replicate-weighted complex-sample survey designs
# will be stored here
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/TIMSS/" )


############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #

library(RSQLite) 			# load RSQLite package (creates database files in R)
library(survey)				# load survey package (analyzes complex design surveys)
library(mitools) 			# load mitools package (analyzes multiply-imputed data)
library(downloader)			# downloads and then runs the source() function on scripts from github
library(haven) 				# load the haven package (imports dta files faaaaaast)
library(SAScii) 			# load the SAScii package (imports ascii data with a SAS script)

# specify that replicate-weighted complex sample survey design objects
# should calculate their variances by using the average of the replicates.
options( "survey.replicates.mse" = TRUE )

# load the download.cache and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url( 
	"https://raw.github.com/ajdamico/usgsd/master/Download%20Cache/download%20cache.R" , 
	prompt = FALSE , 
	echo = FALSE 
)


# # # # # # # # # # # #
# download all files  #
# # # # # # # # # # # #

c99 <- c( "aus" , "bfl" , "bgr" , "can" , "chl" , "twn" , "cyp" , "cze" , "eng" , "fin" , "hkg" , "hun" , "idn" , "irn" , "isr" , "ita" , "jpn" , "jor" , "kor" , "lva" , "ltu" , "mkd" , "mys" , "mda" , "mar" , "nld" , "nzl" , "phl" , "rom" , "rus" , "sgp" , "svk" , "svn" , "zaf" , "tha" , "tun" , "tur" , "usa" )

c95_1 <- c("AUS", "AUT", "CAN", "CYP", "CSK", "GBR", "GRC", "HKG", "HUN", "ISL", "IRN", "IRL", "ISR", "JPN", "KOR", "KWT", "LVA", "NLD", "NZL", "NOR", "PRT", "SCO", "SGP", "SVN", "THA", "USA")
c95_2 <- c("AUS", "AUT", "BFL", "BFR", "BGR", "CAN", "COL", "CYP", "CSK", "DNK", "GBR", "FRA", "DEU", "GRC", "HKG", "HUN", "ISL", "IRN", "IRL", "ISR", "JPN", "KOR", "KWT", "LVA", "LTU", "NLD", "NZL", "NOR", "PHL", "PRT", "ROM", "RUS", "SCO", "SGP", "SLV", "SVN", "ZAF", "ESP", "SWE", "CHE", "THA", "USA")
c95_3 <- c("AUS", "AUT", "CAN", "CYP", "CSK", "DNK", "FRA", "DEU", "GRC", "HUN", "ISL", "ISR", "ITA", "LVA", "LTU", "NLD", "NZL", "NOR", "RUS", "SVN", "ZAF", "SWE", "CHE", "USA")

# specify the pathway to each and every spss data set to download.
ftd <-
	c(
		paste0( "http://timss.bc.edu/timss2011/downloads/T11_G4_SPSSData_pt" , 1:3 , ".zip" ) ,
		paste0( "http://timss.bc.edu/timss2011/downloads/T11_G8_SPSSData_pt" , 1:4 , ".zip" ) ,

		paste0( "http://timss.bc.edu/TIMSS2007/PDF/T07_SPSS_G4_" , 1:2 , ".zip" ) ,
		paste0( "http://timss.bc.edu/TIMSS2007/PDF/T07_SPSS_G8_" , 1:2 , ".zip" ) ,
		
		paste0( "http://timss.bc.edu/timss2003i/PDF/t03_spss_" , 1:2 , ".zip" ) ,
		
		paste0( "http://timss.bc.edu/timss1999i/data/bm2_" , c99 , ".zip" ) ,
		
		paste0( "http://timss.bc.edu/timss1995i/database/pop1/POP1_" , c95_1 , ".ZIP" ) ,
		paste0( "http://timss.bc.edu/timss1995i/database/pop2/POP2_" , c95_2 , ".ZIP" ) ,
		paste0( "http://timss.bc.edu/timss1995i/database/pop3/POP3_" , c95_3 , ".ZIP" ) 
	)

# initiate a temporary file and a temporary directory
tf <- tempfile() ; td <- tempdir()

# download the 1999 sas import scripts
download.cache( 'http://timss.bc.edu/timss1999i/data/bm2_progs.zip' , tf , mode = 'wb' )
s99 <- unzip( tf , exdir = tempdir() )

# download the 1995 sas import scripts
download.cache( 'http://timss.bc.edu/timss1995i/database/pop1/POP1PGRM.ZIP' , tf , mode = 'wb' )
s95_1 <- unzip( tf , exdir = tempdir() )
download.cache( 'http://timss.bc.edu/timss1995i/database/pop2/POP2PGRM.ZIP' , tf , mode = 'wb' )
s95_2 <- unzip( tf , exdir = tempdir() )
download.cache( 'http://timss.bc.edu/timss1995i/database/pop3/POP3PGRM.ZIP' , tf , mode = 'wb' )
s95_3 <- unzip( tf , exdir = tempdir() )
s95 <- c( s95_1 , s95_2 , s95_3 )

# set an empty year vector
years <- NULL

# for each file to download..
for ( i in ftd ){
	
	# figure out which year is this year
	this.year <- gsub( "(.*)([0-9][0-9][0-9][0-9])(.*)" , "\\2" , i )
	
	# confirm it's a realistic year
	stopifnot( this.year %in% 1995:2999 )
	
	# add a directory for that year
	dir.create( this.year , showWarnings = FALSE )
	
	# download the damn file
	download.cache( i , tf , mode = 'wb' )
	
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

# loop through each year of timss data available
for ( this.year in years ){

	# construct a vector with all downloaded files
	files <- list.files( this.year , full.names = TRUE )
	
	# figure out the unique three-character prefixes of each file
	prefixes <- unique( substr( basename( files ) , 1 , 3 ) )

	if( this.year >= 2003 ){
					
		# loop through each prefix
		for ( p in prefixes ){
		
			# confirm no overwriting
			if( file.exists( paste0( './' , this.year , '/' , p , '.rda' ) ) ) stop( "rda file already exists. delete your working directory and try again." )

			# initiate an empty object
			y <- NULL
		
			# loop through each saved file matching the prefix pattern
			for ( this.file in files[ substr( basename( files ) , 1 , 3 ) == p ] ){
		
				# read the file into RAM
				x <- read_spss( this.file )
				
				# coerce the file into a data.frame object
				x <- as.data.frame.matrix( x )
				
				if ( !is.null( y ) & this.year == 2003 & any( !( names( x ) %in% names( y ) ) ) ) for ( i in names( x )[ !( names( x ) %in% names( y ) ) ] ) y[ , i ] <- NA
				if ( !is.null( y ) & this.year == 2003 & any( !( names( y ) %in% names( x ) ) ) ) for ( i in names( y )[ !( names( y ) %in% names( x ) ) ] ) x[ , i ] <- NA
		
				# clear up space just in case you're close to the RAM limit.
				if( object.size( y ) > 1000000000 ){
					save( x , y , file = 'temp.rda' )
					rm( x , y )
					gc()
					load( 'temp.rda' )
					unlink( 'temp.rda' )
				}
										
				# stack it
				y <- rbind( y , x ) ; rm( x )
				
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
		
	} else {
	
		if ( this.year == 1999 ){
			suf <- c( 'm1' , 'm2' )
			sasf <- s99
			se <- 8
		} else {
			suf <- 1
			sasf <- s95
			se <- 7
		}
		
		# loop through both suffixes
		for ( s in suf ){
					
			# loop through each prefix
			for ( p in prefixes ){
			
				# confirm no overwriting
				if( file.exists( paste0( './' , this.year , '/' , p , s , '.rda' ) ) ) stop( "rda file already exists. delete your working directory and try again." )

				if( this.year == 1995 ){
				
					this.sas <- sasf[ grep( toupper( paste0( p , "(.*)\\.sas" ) ) , toupper( basename( sasf ) ) ) ]
				
					if( length( this.sas ) > 1 ) this.sas <- this.sas[ !grepl( "score" , tolower( this.sas ) ) ]
				
				} else {
				
					this.sas <- sasf[ grep( toupper( paste0( p , "(.*)" , s , "\\.sas" ) ) , toupper( basename( sasf ) ) ) ]
			
					if( length( this.sas ) > 1 ) this.sas <- this.sas[ grep( "ctrm" , tolower( this.sas ) ) ]
					
				}
					
				# initiate an empty object
				y <- NULL
			
				# loop through each saved file matching the prefix and suffix pattern
				for ( this.file in files[ substr( basename( files ) , 1 , 3 ) == p & substr( basename( files ) , 7 , se ) == s ] ){
			
					# read the file into RAM
					x <- read.SAScii( this.file , this.sas )
					
					# coerce the file into a data.frame object
					x <- as.data.frame.matrix( x )
					
					# stack it
					y <- rbind( y , x ) ; rm( x )
					
					# remove the original file from the disk
					unlink( this.file )
					
				}
				
				if( !is.null( y ) ){
					
					# make all column names lowercase
					names( y ) <- tolower( names( y ) )
					
					# some earlier files have `jkindic` instead of `jkrep`.  fix that.
					if( 'jkindic' %in% names( y ) & !( 'jkrep' %in% names( y ) ) ) names( y ) <- gsub( 'jkindic' , 'jkrep' , names( y ) )
					
					# save the stacked file as the prefix
					assign( paste0( p , s ) , y )
					
					# save that single all-country stack-a-mole
					save( list = paste0( p , s ) , file = paste0( './' , this.year , '/' , p , s , '.rda' ) )
					
					# remove all those now-unnecessary objects from RAM
					rm( list = c( paste0( p , s ) , "y" ) )
				}
			}
		}
	}	
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# create multiply-imputed, replicate-weighted database-backed complex survey designs  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# loop through each year of data
for ( this.year in years ){
	
	db.name <- paste0( './TIMSS' , this.year , '.db' )
	
	# open the connection to a new sqlite database
	db <- dbConnect( SQLite() , db.name )

	for ( rdas in rev( list.files( paste0( './' , this.year ) , full.names = TRUE ) ) ){
	
		print( paste( "current designing" , rdas ) )
	
		df <- load( rdas )
		
		ppv <- grep( "(.*)0[1-5]$" , names( get( df ) ) , value = TRUE )
		
		ppv <- unique( gsub( "0[1-5]$" , "" , ppv ) )
		
		# actual plausible values
		pv <- NULL
		
		# confirm '01' thru '05' are in the data set.
		for ( i in ppv ) if ( all( paste0( i , '0' , 1:5 ) %in% names( get( df ) ) ) ) pv <- c( pv , i )
		
		# if there are any plausible values variables,
		# the survey design needs to be both multiply-imputed and replicate-weighted.
		if( length( pv ) > 0 ){
		
			# loop through all five iterations of the plausible value
			for ( i in 1:5 ){
					
				y <- get( df )
		
				# loop through each plausible value variable
				for ( vn in pv ){
				
					# copy over the correct iteration into the main variable
					y[ , vn ] <- y[ , paste0( vn , '0' , i ) ]
					
					# erase all five originals
					y <- y[ , !( names( y ) %in% paste0( vn , '0' , 1:5 ) ) ]

				}
				
				# save the implicate
				dbWriteTable( db , paste0( df , i ) , y )
				
				rm( y ) ; gc
				
			}
			
		} else {	
		
			dbWriteTable( db , df , get( df ) )
		
		}
		
		# make the replicate weights table, make the survey design
		if( 'totwgt' %in% names( get( df ) ) | 'tchwgt' %in% names( get( df ) ) ){
			
			if( 'totwgt' %in% names( get( df ) ) ) wgt <- 'totwgt' else wgt <- 'tchwgt'
		
			z <- get( df )[ , c( wgt , 'jkrep' , 'jkzone' ) ]

			rm( list = df ) ; gc()

			for ( i in 1:75 ){
				z[ z$jkzone != i , paste0( 'rw' , i ) ] <- z[ z$jkzone != i , wgt ]
				z[ z$jkzone == i & z$jkrep == 1 , paste0( 'rw' , i ) ] <- z[ z$jkzone == i & z$jkrep == 1 , wgt ] * 2
				z[ z$jkzone == i & z$jkrep == 0 , paste0( 'rw' , i ) ] <- 0
			}

			z <- z[ , paste0( 'rw' , 1:75 ) ]
		
			# clear up space just in case you're close to the RAM limit.
			if( object.size( z ) > 100000000 ){
				save( z , file = 'temp.rda' )
				rm( z )
				gc()
				load( 'temp.rda' )
				unlink( 'temp.rda' )
			}
				
			# where there any imputed variables?
			if( length( pv ) > 0 ){
			
				# if so, construct a multiply-imputed,
				# database-backed, replicate-weighted
				# complex sample survey design.
				design <- 
					svrepdesign( 
						weights = as.formula( paste( "~" , wgt ) )  , 
						repweights = z , 
						data = imputationList( datasets = as.list( paste0( df , 1:5 ) ) , dbtype = "SQLite" ) , 
						type = "other" ,
						combined.weights = TRUE , 
						dbname = db.name
					)
					
			} else {
			
				# otherwise, construct a
				# database-backed, replicate-weighted
				# complex sample survey design
				# without the multiple imputation.
				design <- 
					svrepdesign( 
						weights = as.formula( paste( "~" , wgt ) )  , 
						repweights = z , 
						data = df , 
						dbtype = "SQLite" ,
						type = "other" ,
						combined.weights = TRUE , 
						dbname = db.name
					)
					
			}
				
			rm( z ) ; gc()
			
			assign( paste0( df , "_design" ) , design )
			
			save( list = paste0( df , "_design" ) , file = paste0( './' , this.year , '/' , df , '_design.rda' ) )
			
			rm( list = c( 'design' , paste0( df , "_design" ) ) ) ; gc()
			
		} else {
		
			rm( list = df ) ; gc()
			
		}
		
	}	

	# close the connection to the sqlite database
	dbDisconnect( db )

}

# the current working directory should now contain one r data file (.rda)
# for each database-backed, multiply-imputed, replicate-weighted complex-sample survey design object
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
