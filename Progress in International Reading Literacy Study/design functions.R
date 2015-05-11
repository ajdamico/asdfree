
# initiate a replicate weights creation function to quickly compute weights wherever necessary
rwcf <- 
	function( z , wgt ){
		for ( i in 1:75 ){
			z[ z$jkzone != i , paste0( 'rw' , i ) ] <- z[ z$jkzone != i , wgt ]
			z[ z$jkzone == i & z$jkrep == 1 , paste0( 'rw' , i ) ] <- z[ z$jkzone == i & z$jkrep == 1 , wgt ] * 2
			z[ z$jkzone == i & z$jkrep == 0 , paste0( 'rw' , i ) ] <- 0
		}
		z[ , paste0( 'rw' , 1:75 ) ]
}


# initiate a plausible valued survey design object creation function
pvsd <-
	function( x , wgt , rw ){
	
		# search for plausible values variables.
		# plausible values variables are named _varname_01 thru _varname_05
		ppv <- grep( "(.*)0[1-5]$" , names( x ) , value = TRUE )
		
		ppv <- unique( gsub( "0[1-5]$" , "" , ppv ) )
		
		# actual plausible values
		pv <- NULL
		
		# confirm '01' thru '05' are in the data set.
		for ( i in ppv ) if ( all( paste0( i , '0' , 1:5 ) %in% names( x ) ) ) pv <- c( pv , i )
		
		
		# if there are any plausible values variables,
		# the survey design needs to be both multiply-imputed and replicate-weighted.
		if( length( pv ) > 0 ){
		
			# loop through all five iterations of the plausible value
			for ( i in 1:5 ){
					
				y <- x
		
				# loop through each plausible value variable
				for ( vn in pv ){
				
					# copy over the correct iteration into the main variable
					y[ , vn ] <- y[ , paste0( vn , '0' , i ) ]
					
					# erase all five originals
					y <- y[ , !( names( y ) %in% paste0( vn , '0' , 1:5 ) ) ]

				}
				
				# save the implicate
				assign( paste0( 'x' , i ) , y )
			}
			
			rm( x , y )
			
			z <-
				svrepdesign( 	
					weights = as.formula( paste( "~" , wgt ) ) , 
					repweights = rw ,
					rscales = rep( 1 , 75 ) ,
					scale = 1 ,
					type = 'other' ,
					data = imputationList( list( x1 , x2 , x3 , x4 , x5 ) ) ,
					mse = TRUE
				)
				
		# otherwise, it's simply replicate-weighted.
		} else {
		
			z <-
				svrepdesign( 	
					weights = as.formula( paste( "~" , wgt ) ) , 
					repweights = rw ,
					rscales = rep( 1 , 75 ) ,
					scale = 1 ,
					type = 'other' ,
					data = x ,
					mse = TRUE
				)
				
			rm( x )
		
		}
	
		z
	}



