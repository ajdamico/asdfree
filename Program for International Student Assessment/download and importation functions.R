# # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # #
# # functions related to downloads and imporation # #
# # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # #

# some of the year 2000 pisa files do not start at column position 1
# which SAScii cannot handle, so manually add a single-digit toss
add.sdt <-
	function( sas_ri ){
		tf <- tempfile()
		z <- readLines( sas_ri )
		z <- gsub( "country " , "toss_0 $ 1-1 country " , z , fixed = TRUE )
		writeLines( z , tf )
		tf
	}
		

# stupid recodes for one stupid sas importation file stupid sas
# http://pisa2000.acer.edu.au/downloads/intstud_math.sas
stupid.sas <-
	function( sas_ri ){
		tf <- tempfile()
		z <- readLines( sas_ri )
		
		z[ 1252:1261 ] <-
			c( 
				"pv1math1 1568-1574" , 
				"pv2math1 1575-1581" , 
				"pv3math1 1582-1588" , 
				"pv4math1 1589-1595" , 
				"pv5math1 1596-1602" , 
				"pv1math2 1603-1609" , 
				"pv2math2 1610-1616" , 
				"pv3math2 1617-1623" , 
				"pv4math2 1624-1630" , 
				"pv5math2 1631-1637" 
			)
		
		writeLines( z , tf )
		
		tf
	}
	

# another sas import script is uppercase one place 
# and lowercase elsewhere, and it's cramping my style
sas.is.evil <-
	function( sas_ri ){
		
		tf <- tempfile()
		z <- readLines( sas_ri )
		
		z <- gsub( "S304Q03a" , "S304Q03A" , z )
		z <- gsub( "S304Q03b" , "S304Q03B" , z )
		
		writeLines( z , tf )
		
		tf
	}

# yet another silly specific hardcoded recode
# because sas is a trainwreck of a language
sas.is.quite.evil <-
	function( sas_ri ){
		
		tf <- tempfile()
		z <- readLines( sas_ri )
		
		z <- gsub( "cnt   1555-1557" , "cnt $  1555-1557" , z )
	
		writeLines( z , tf )
		
		tf
	}

		
# remove tabs and other illegal things
remove.tabs <-
	function( sas_ri ){
		tf <- tempfile()
		z <- readLines( sas_ri )
		z <- gsub( "\t" , " " , z )
		z <- gsub( "SELECT" , "SELECT_" , z , fixed = TRUE )
		z <- gsub( "@1559 (read_waf) (1*7.5)" , "read_waf 1559-1565" , z , fixed = TRUE )
		z <- gsub( "VER_COGN   506-519;" , "VER_COGN   506-518;" , z , fixed = TRUE )

		writeLines( z , tf )
		tf
	}



add.decimals <-
	function( sas_ri , precise = FALSE ){
	
		tf <- tempfile()
		
		z <- readLines( sas_ri )
		
		z <- str_trim( z )

		# find strings that end with number dot number #

		# lines needing decimals
		lnd <- strsplit( z[ grep( "*[1-9]\\.[1-9]$" , z ) ] , " " )

		# if there aren't any matches, this function has no purpose.
		if ( length( lnd ) == 0 ) return( sas_ri )
		
		# remove blanks
		lnd <- lapply( lnd , function( z ) z[ z != "" ] )

		# variables needing decimals
		vnd <- unlist( lapply( lnd , "[[" , 1 ) )

		# variables need a following space otherwise the match does not work
		vnd <- paste0( vnd , " " )
		
		# decimals to paste
		dtp <- unlist( lapply( lnd , "[[" , 2 ) )

		# if the precision flag is marked..
		if ( precise ){
		
			# loop through every variable needing decimals
			for ( i in seq( length( vnd ) ) ){

				# search for strings beginning with the *exact* string
				begins.with.length <- nchar( vnd[ i ] )
				
				lines.to.replace <- substr( z , 1 , begins.with.length ) == vnd[ i ]
		
				z[ lines.to.replace ] <- paste( z[ lines.to.replace ] , dtp[ i ] )
		
			}
		
		} else {
		
			# loop through every variable needing decimals
			# and replace the variable text with the variable plus the number dot number
			for ( i in seq( length( vnd ) ) ) z[ grep( vnd[ i ] , z ) ] <- paste( z[ grep( vnd[ i ] , z ) ] , dtp[ i ] )
			
		}
			
		writeLines( z , tf )
		
		tf
	}


	
find.chars <-
	function( sas_ri ){
		
		# test if this is necessary
		z <- parse.SAScii( sas_ri )
		
		# if there are ZERO character fields (that's not possible)
		# they need to be pulled from the "length" segment
		if ( any( z$char , na.rm = TRUE ) ){
		
			# so if that's not the case,
			# just stop right here.
			return( sas_ri )
			
		} else {

			# create a temporary file
			tf <- tempfile()
		
			# take the original input file..
			
			# read it in
			z <- readLines( sas_ri )
					
			# find the word `length` and replace it..
			z <- gsub( "length" , "input" , z )
			
			# also spread out the $s
			z <- gsub( "$" , " $ " , z , fixed = TRUE )
			
			# then write it back to the temporary file..
			writeLines( z , tf )
			
			# for a special-read in of those fields
			z <- parse.SAScii( tf )
			

			# but just do that to take note of the character fields
			char.fields <- z[ z$char , 'varname' ]
			
			# now read it in for real
			z <- readLines( sas_ri )
			
			# and add dollar signs to the appropriate lines..
			# (note - add a space in the search to assure right-hand-side whole-word-only
			for ( i in char.fields ) z <- gsub( paste0( i , " " ) , paste( i , "$" ) , z , fixed = TRUE )
			
			# ..then write them to the temporary file
			writeLines( z , tf )

			# and return the result of that dollar sign pull
			return( tf )
		} 

	}
	