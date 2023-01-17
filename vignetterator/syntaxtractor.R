
#' rmarkdown syntax extractor
#'
#' parses asdfree textbook for runnable code.  probably not useful for anything else.
#'
#' @param data_name a character vector with a microdata abbreviation
#'
#' @return filepath with runnable code
#'
#' @examples
#'
#' \dontrun{
#'
#' runnable_code <- syntaxtractor( "yrbss" )
#' source( runnable_code , echo = TRUE )
#'
#' }
#'
#' @export
syntaxtractor <-
	function( data_name ){

		this_rmd <- grep( paste0( "/" , data_name , "\\.Rmd$" ) , list.files( "C:/Users/anthonyd/Documents/GitHub/asdfree/" , full.names = TRUE ) , value = TRUE )
		
		rmd_page <- readLines( this_rmd )
	
		v <- grep( "```" , rmd_page )
		
		lines_to_eval <- unlist( mapply( `:` , v[ seq( 1 , length( v ) - 1 , 2 ) ] + 1 , v[ seq( 2 , length( v ) + 1 , 2 ) ] - 1 ) )
		
		rmd_page <- rmd_page[ lines_to_eval ]
	
		temp_script <- tempfile()

		rmd_page
	}


readLines_retry <-
	function( ... , attempts = 10 , sleep_length = 60 * sample( 1:5 , 1 ) ){
	
		for( i in seq( attempts ) ){
		
			this_warning <- tryCatch( { result <- readLines( ... ) ; return( result ) } , warning = print )
			
			if( grepl( "404" , paste( as.character( this_warning ) , collapse = " " ) ) ) stop( as.character( this_warning ) ) 
			
			Sys.sleep( sleep_length )
		
		}
		
		stop( this_warning )
		
	}
	
