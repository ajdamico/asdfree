
#' rmarkdown syntax extractor
#'
#' parses asdfree textbook for runnable code.  probably not useful for anything else.
#'
#' @param data_name a character vector with a microdata abbreviation
#' @param repo github repository containing textbook
#' @param ref github branch containing textbook
#' @param replacements list containing text to swap out and in, using regular expressions
#' @param setup_test either "setup" for dataname-setup.R or "test" for dataname-test.R or NULL for everything
#'
#' @return filepath with runnable code
#'
#' @examples
#'
#' \dontrun{
#'
#' replacements_list <- list( c( "C:/My Directory" , tempdir() ) )
#' runnable_code <- syntaxtractor( "yrbss" , replacements = replacements_list )
#' source( runnable_code , echo = TRUE )
#'
#' 
#' # usage examples
#' source( syntaxtractor( "prerequisites" ) , echo = TRUE )
#' source( syntaxtractor( "ahrf" , replacements = NULL ) , echo = TRUE )
#' source( syntaxtractor( "nppes" , replacements = NULL ) , echo = TRUE )
#' source( syntaxtractor( "pisa" , replacements = NULL ) , echo = TRUE )
#' source( syntaxtractor( "pnad" , replacements = NULL ) , echo = TRUE )
#' source( syntaxtractor( "scf" , replacements = NULL ) , echo = TRUE )
#' source( syntaxtractor( "yrbss" , replacements = NULL ) , echo = TRUE )
#'
#' some_info <- list( "email@address\\.com" , "ajdamico@gmail.com" )
#' source( syntaxtractor( "lavaan" , replacements = some_info ) , echo = TRUE )
#'
#' }
#'
#' @export
syntaxtractor <-
	function( data_name , replacements = NULL ){

		this_rmd <- grep( paste0( "/" , data_name , "\\.Rmd$" ) , list.files( "C:/Users/anthonyd/Documents/GitHub/asdfree/" , full.names = TRUE ) , value = TRUE )
		
		rmd_page <- readLines( this_rmd )
	
		v <- grep( "```" , rmd_page )
		
		lines_to_eval <- unlist( mapply( `:` , v[ seq( 1 , length( v ) - 1 , 2 ) ] + 1 , v[ seq( 2 , length( v ) + 1 , 2 ) ] - 1 ) )
		
		rmd_page <- rmd_page[ lines_to_eval ]
	
		temp_script <- tempfile()

		for ( this_replacement in replacements ) rmd_page <- gsub( this_replacement[ 1 ] , this_replacement[ 2 ] , rmd_page , fixed = TRUE )

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
	
