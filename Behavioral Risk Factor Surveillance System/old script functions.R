
# flip at signs
flip.ats <-
	function( problem.ats ){
		flips <- which( substr( problem.ats , 1 , 1 ) == "@" )
	
		if ( length( flips ) > 0 ){
		
			spacing <- gregexpr( " " , problem.ats[ flips ] )
		
			toflip <- problem.ats[ flips ]
		
			for ( i in 1:length( toflip ) ){
			
				partone <- substr( toflip[ i ] , 2 , spacing[[i]][1] - 1 )
				parttwo <- substr( toflip[ i ] , spacing[[i]][1] + 1 , spacing[[i]][2] - 1)
				partthree <- substr( toflip[ i ] , spacing[[i]][2] + 1 , nchar( toflip[i] ))
				
				problem.ats[ flips[ i ] ] <- paste( parttwo , partone , partthree )
				
			}
		
		}
		
		problem.ats
	}

# brfss sas fix
brfss.sas.fix <-
	function( sas_ri , beginline = 1 ){
		# remove tabs
		with.tabs <- readLines( sas_ri )
		no.tabs <- gsub( "\t" , " " , with.tabs )

		# remove sas comments
		no.tabs <- SAS.uncomment( no.tabs , "/*" , "*/" )

		
		# remove other random lines
		ltr <- 
			c( 
				"@400  STATEQUE        $CHAR200." ,
				"@415 STATEQUE $CHAR184." , 
				"@1 REC1 $CHAR200. REC2 $CHAR200. REC3 $CHAR100." , 
				"@260 STATEQUE $CHAR141." , 
				"@275 STATEQUE $CHAR176." ,
				"@373 DISABLTY $CHAR42."
			)
		
		orl <- function( x , y ) gsub( x , " " , y , fixed = TRUE )
		
		for ( i in ltr ) no.tabs <- orl( i , no.tabs )

		# ats flipped
		no.tabs <- flip.ats( no.tabs )
		
		
		# throw out lines before beginline
		no.tabs <- no.tabs[ beginline:length(no.tabs) ]
		
		# lines that end with " 2" should be " .2"
		b <- substr( no.tabs , nchar( no.tabs ) - 1 , nchar( no.tabs ) )
		d <- b == " 2"
		no.tabs[ d ] <- paste0( substr( no.tabs[ d ] , 1 , nchar( no.tabs[ d ] ) - 2 ) , " .2" )

		# completely remove underscores
		no.tabs <- gsub( "_" , "x" , no.tabs )
		
		
		# remove ststr and idate (which overlap other fields)
		no.tabs <- no.tabs[ !grepl( "SEQNO" , no.tabs ) ]
		no.tabs <- no.tabs[ !grepl( "STSTR" , no.tabs ) ]
		no.tabs <- no.tabs[ !grepl( "IDATE" , no.tabs ) ]
		no.tabs <- no.tabs[ !grepl( "PHONENUM" , no.tabs ) ]

		# isolate the correct starting and ending lines
		firstline <- grep("INPUT", no.tabs)[1]
		a <- grep(";", toupper(no.tabs))
		lastline <- min(a[a > firstline])
		slimmed <- no.tabs[ firstline:lastline ]

		# space out dashes and semicolons
		spaced <- gsub( "-" , " - " , slimmed )
		spaced <- gsub( ";" , " ;" , spaced  )

		# break apart all strings
		broken <- strsplit( spaced , " " )
		
		# remove decimal holders
		no.decimals <- 
			mapply( 
				"[" , 
				broken , 
				lapply( 
					broken , 
					function(x) !grepl( "." , x , fixed = TRUE ) 
				) 
			)
		
		
		# remove non-integer elements
		starts <- lapply( no.decimals , as.integer )

		# throw out NAs and zeroes
		for ( i in 1:length( starts ) ) starts[[i]] <- starts[[i]][ !is.na( starts[[i]] ) & starts[[i]] != 0 ]

		# keep only the minimum
		mins <- unlist( lapply( starts , min ) )

		# and this produces the order that the file should be read in..
		slimmed <- slimmed[ order( mins ) ]
		
		
		# whitespace removed
		slimmed <- str_trim( slimmed )
		
		# "INPUT" goes at the top
		slimmed <- slimmed[ order( slimmed != "INPUT" ) ]
		
		# ..without the blank lines.
		slimmed[ slimmed != "" ]
	}

	