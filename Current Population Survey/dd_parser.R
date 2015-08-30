# data dictionary parser
dd_parser <-
	function( url ){

		# read in the data dictionary
		lines <- readLines ( url )
		
		# find the record positions
		hh_start <- grep( "HOUSEHOLD RECORD" , lines )
		
		fm_start <- grep( "FAMILY RECORD" , lines )
		
		pn_start <- grep( "PERSON RECORD" , lines )
		
		# segment the data dictionary into three parts
		hh_lines <- lines[ hh_start:(fm_start - 1 ) ]
		
		fm_lines <- lines[ fm_start:( pn_start - 1 ) ]
		
		pn_lines <- lines[ pn_start:length(lines) ]
		
		# loop through all three parts		
		for ( i in c( "hh_lines" , "fm_lines" , "pn_lines" ) ){
		
			# pull the lines into a temporary variable
			k <- j <- get( i )
		
			# remove any goofy tab characters
			j <- gsub( "\t" , " " , j )
			
			# look for lines indicating divisor
			idp <- grep( "2 implied" , j )
			
			# confirm you've captured all decimal lines
			stopifnot( all( grep( "implied" , j ) == idp ) )
			
			# keep only the variable lines
			j <- grep( "^D " , j , value = TRUE )
			
			# remove all multiple-whitespaces
			while( any( grepl( "  " , j ) ) ) j <- gsub( "  " , " " , j )
			while( any( grepl( "  " , k ) ) ) k <- gsub( "  " , " " , k )
		
			# get rid of the prefix "D "
			j <- gsub( "^D " , "" , j )
			
			# get rid of any spaces at the end of each line
			j <- gsub( " $" , "" , j )
			
			# keep only the first three items in the line
			j <- gsub( "(.*) (.*) (.*) (.*)" , "\\1 \\2 \\3" , j )
		
			# break the lines apart by spacing
			j <- strsplit( j , " " )
			
			# store the variable name, width, and position into a data.frame
			j <-
				data.frame( 
					varname = sapply( j , '[[' , 1 ) ,
					width = as.numeric( sapply( j , '[[' , 2 ) ) ,
					position = as.numeric( sapply( j , '[[' , 3 ) ) , 
					divisor = 1
				)
		
			# confirm the cumulative sum of the widths equals the final position
			stopifnot( cumsum( j$width )[ nrow( j ) - 1 ] == j[ nrow( j ) , 'position' ] - 1 )

			# confirm that the last variable is filler and can be tossed
			stopifnot( j[ nrow( j ) , 'varname' ] == 'FILLER' )
			
			# toss it.
			j <- j[ -nrow( j ) , ]
			
			# find the position of each variable name in the original file
			pos <- lapply( paste0( "^D " , j[ , 'varname' ] , " " ) , grep , k )
			
			# confirm all multiply-named columns are `FILLER`
			stopifnot( all( j[ lapply( pos , length ) != 1 , 'varname' ] == 'FILLER' ) )

			# add on the positions from the original file
			j$location_in_original_file <- unlist( lapply( pos , min ) )

			# everywhere with divisor, find the associated variable
			for ( l in idp ){
			
				which_dec <- max( j[ j$location_in_original_file < l , 'location_in_original_file' ] ) 
			
				j[ which_dec == j$location_in_original_file , 'divisor' ] <- 0.01

			}

			# remove that column you no longer need
			j$location_in_original_file <- NULL
		
			# overwrite - with _
			j$varname <- gsub( "-" , "_" , j$varname )

			# fillers should be missings not 
			j[ j$varname == 'FILLER' , 'width' ] <- -( j[ j$varname == 'FILLER' , 'width' ] )
			j[ j$varname == 'FILLER' , 'varname' ] <- NA
			
			
			# treat cps fields as exclusively numeric
			j$char <- FALSE
			
			assign( gsub( "_lines" , "_stru" , i ) , j )
			
		}
		
		
		list( hh_stru , fm_stru , pn_stru )
		
	}
	
# examples
# dd_parser( "http://thedataweb.rm.census.gov/pub/cps/march/asec20141_pubuse.txt" )
# dd_parser( "http://thedataweb.rm.census.gov/pub/cps/march/asec2014early_pubuse.dd.txt" )
# dd_parser( "http://thedataweb.rm.census.gov/pub/cps/march/asec2013early_pubuse.dd.txt" )
# dd_parser( "http://thedataweb.rm.census.gov/pub/cps/march/asec2012early_pubuse.dd.txt" )
# dd_parser( "http://thedataweb.rm.census.gov/pub/cps/march/asec2011_pubuse.dd.txt" )
