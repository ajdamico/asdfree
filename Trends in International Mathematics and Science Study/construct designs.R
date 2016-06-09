# analyze survey data for free (http://asdfree.com) with the r language
# trends in international mathematics and science study
# each and every available possible survey design hooray

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/TIMSS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Trends%20in%20International%20Mathematics%20and%20Science%20Study/construct%20designs.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com



######################################################################
#  make a multiply-imputed complex sample svrepdesign object with r! #
######################################################################


# remove the # in order to run this install.packages line only once
# install.packages( c( "MonetDBLite" , "survey" , "SAScii" , "descr" , "downloader" , "digest" , "mitools" , "R.utils" ) )


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

library(survey) 		# load survey package (analyzes complex design surveys)
library(DBI)			# load the DBI package (implements the R-database coding)
library(MonetDBLite)	# load MonetDBLite package (creates database files in R)
library(mitools) 		# load mitools package (analyzes multiply-imputed data)


# specify that replicate-weighted complex sample survey design objects
# should calculate their variances by using the average of the replicates.
options( "survey.replicates.mse" = TRUE )

# this script's download files should be incorporated in download_cached's hash list
options( "download_cached.hashwarn" = TRUE )
# warn the user if the hash does not yet exist


# figure out which years are available by creating the `years` vector with only numbers in the directory
years <- list.files()[ as.character( as.numeric( list.files() ) ) %in% list.files() ]


# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )

# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite() , dbfolder )


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# create multiply-imputed, replicate-weighted database-backed complex survey designs  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# loop through each year of data
for ( this.year in rev( years ) ){
	
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
				dbWriteTable( db , paste0( df , this.year , i ) , y )
				
				rm( y ) ; gc()
				
			}
			
		} else {	
		
			dbWriteTable( db , paste0( df , this.year ) , get( df ) )
		
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
						data = imputationList( datasets = as.list( paste0( df , this.year , 1:5 ) ) , dbtype = "MonetDBLite" ) , 
						type = "other" ,
						combined.weights = TRUE , 
						dbtype = "MonetDBLite" ,
						dbname = dbfolder
					)


				# workaround for a bug in survey::svrepdesign.character
				design$mse <- TRUE
									

			} else {
			
				# otherwise, construct a
				# database-backed, replicate-weighted
				# complex sample survey design
				# without the multiple imputation.
				design <- 
					svrepdesign( 
						weights = as.formula( paste( "~" , wgt ) )  , 
						repweights = z , 
						data = paste0( df , this.year ) , 
						type = "other" ,
						combined.weights = TRUE ,
						dbtype = "MonetDBLite" ,
						dbname = dbfolder
					)
					
				# workaround for a bug in survey::svrepdesign.character
				design$mse <- TRUE

			}
				
			rm( z ) ; gc()
			
			assign( paste0( df , "_design" ) , design )
			
			save( list = paste0( df , "_design" ) , file = paste0( './' , this.year , '/' , df , '_design.rda' ) )
			
			rm( list = c( 'design' , paste0( df , "_design" ) ) ) ; gc()
			
		} else {
		
			rm( list = df ) ; gc()
			
		}
		
	}	

}

# the current working directory should now contain one r data file (.rda)
# for each database-backed, multiply-imputed, replicate-weighted complex-sample survey design object
# plus the original prefixed data.frame objects, all separated by year-specific folders.


# close the connection to the monetdblite database
dbDisconnect( db , shutdown = TRUE )
