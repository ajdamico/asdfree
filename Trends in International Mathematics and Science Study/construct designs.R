# analyze survey data for free (http://asdfree.com) with the r language
# trends in international mathematics and science study
# each and every available possible survey design hooray

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/TIMSS/" )
# source_url( "https://raw.github.com/ajdamico/asdfree/master/Trends%20in%20International%20Mathematics%20and%20Science%20Study/construct%20designs.R" , prompt = FALSE , echo = TRUE )
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



######################################################################
#  make a multiply-imputed complex sample svrepdesign object with r! #
######################################################################


# remove the # in order to run this install.packages line only once
# install.packages( c( "survey" , "mitools" ) )


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


# specify that replicate-weighted complex sample survey design objects
# should calculate their variances by using the average of the replicates.
options( "survey.replicates.mse" = TRUE )


# figure out which years are available by creating the `years` vector with only numbers in the directory
years <- list.files()[ as.character( as.numeric( list.files() ) ) == list.files() ]


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# create multiply-imputed, replicate-weighted database-backed complex survey designs  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# loop through each year of data
for ( this.year in rev( years ) ){
	
	db.name <- paste0( './TIMSS' , this.year , '.db' )
	
	# open the connection to a new sqlite database
	db <- dbConnect( SQLite() , db.name )

	for ( rdas in rev( list.files( paste0( './' , this.year ) , full.names = TRUE ) ) ){
	
		print( paste( "currently designing" , rdas ) )
	
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
				
				rm( y ) ; gc()
				
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
