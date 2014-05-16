# function to remove NA values from TRUE/FALSE tests, defaulting to FALSE
no.na <- function( x , value = FALSE ){ x[ is.na( x ) ] <- value ; x }



# function to merge ric2 and ric2f #
ric.bind <-
	function( z ){
		
		if( any( !is.na( z[ , 1 ] ) & !is.na( z[ , 2 ] ) ) ) stop( "record exists where neither are NA" )
		
		ifelse( is.na( z[ , 1 ] ) , z[ , 2 ] , z[ , 1 ] )
	}
# end of function #



# custom function to merge `ricx` to all other MCBS person-level RIC files #
ric.merge <-
	function( mcbs , ric.df ){
		
		# throw out the fields `ric` and `fileyr`
		ric.df <- ric.df[ , !( names( ric.df ) %in% c( 'ric' , 'fileyr' , 'version' ) ) ]
		
		# confirm `baseid` is the only merge field
		if ( !identical( intersect( names( ric.df ) , names( mcbs ) ) , 'baseid' ) ) stop( print( paste( 'irregular merge fields:' , intersect( names( ric.df ) , names( mcbs ) ) ) ) )
		
		# print records without as many baseids as ricx
		if ( nrow( mcbs ) != length( unique( ric.df$baseid ) ) ) print( paste( '`ric.df` has' , length( unique( ric.df$baseid ) ) , 'unique baseids' ) )

		# confirm ric.df has <= unique baseids
		if ( nrow( mcbs ) < length( unique( ric.df$baseid ) ) ) stop( "at least one baseid in `ric.df` not in the consolidated file" )
		
		# perform the merge, confirming that the number of records in the consolidated file does not change
		before.nrow <- nrow( mcbs )
		mcbs <- merge( mcbs , ric.df , all.x = TRUE )
		stopifnot( nrow( mcbs ) == before.nrow )
		
		# return the post-merge data.frame object
		mcbs
	}
