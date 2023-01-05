
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
	function( data_name , repo = "ajdamico/asdfree" , ref = "master" , replacements = NULL , setup_rmd = TRUE , test_rmd = TRUE , sample_setup_breaks = NULL , broken_sample_test_condition = NULL ){

		this_rmd <- grep( paste0( "-" , data_name , "\\.Rmd$" ) , list.files( "C:/Users/anthonyd/Documents/GitHub/asdfree/" , full.names = TRUE ) , value = TRUE )
		
		rmd_page <- readLines( this_rmd )
	
		v <- grep( "```" , rmd_page )
		
		lines_to_eval <- unlist( mapply( `:` , v[ seq( 1 , length( v ) - 1 , 2 ) ] + 1 , v[ seq( 2 , length( v ) + 1 , 2 ) ] - 1 ) )
		
		rmd_page <- rmd_page[ lines_to_eval ]
	
		# find the second `library(lodown)` line
		second_library_lodown_line <- grep( "^library\\(lodown\\)$" , rmd_page )[ 2 ]
		
		# if that line does not exist, simply use the first two lines of code
		if( is.na( second_library_lodown_line ) ){
			second_library_lodown_line <- 3
		}
	
		if( is.null( sample_setup_breaks ) & setup_rmd ){

			setup_rmd_page <- rmd_page[ seq_along( rmd_page ) < second_library_lodown_line ]
			
		} else setup_rmd_page <- NULL
	
		test_rmd_page <- rmd_page[ seq_along( rmd_page ) >= second_library_lodown_line ]
		
		if( !is.null( sample_setup_breaks ) & setup_rmd ){
		
			sample_break_block <-				
				c(
					"library(lodown)" ,
					"this_sample_break <- Sys.getenv( \"this_sample_break\" )" , 
					"chapter_tag_cat <- get_catalog( \"chapter_tag\" , output_dir = file.path( getwd() ) )" ,
					paste0( "record_categories <- ceiling( seq( nrow( chapter_tag_cat ) ) / ceiling( nrow( chapter_tag_cat ) / " , sample_setup_breaks , " ) )" ) ,
					"chapter_tag_cat <- chapter_tag_cat[ record_categories == this_sample_break , ]" ,
					"chapter_tag_cat <- lodown( \"chapter_tag\" , chapter_tag_cat )"
				)

			sample_break_block <- gsub( "chapter_tag" , data_name , sample_break_block )
			
			setup_rmd_page <- c( setup_rmd_page , sample_break_block )
		}
		
		if( !is.null( broken_sample_test_condition ) ) test_rmd_page <- c( paste0( "if( " , broken_sample_test_condition , " ){" ) , test_rmd_page , "}" )
		
		if( test_rmd ){

			lodown_command_line <- grep( paste0( "^" , data_name , "_cat <\\- lodown\\(" ) , test_rmd_page )

			if( length( lodown_command_line ) > 0 ){

				# skip the second `get_catalog` for broken samples, since sometimes `chapter_tag_cat <- lodown(...)` stores needed file information
				if( !is.null( broken_sample_test_condition ) ) test_rmd_page[ seq( 2 , lodown_command_line ) ] <- "" else test_rmd_page[ lodown_command_line ] <- ""
				
				# following few lines might include usernames/passwords
				if( grepl( "your_" , test_rmd_page[ lodown_command_line + 1 ] ) ) test_rmd_page[ lodown_command_line + 1 ] <- ""
				if( grepl( "your_" , test_rmd_page[ lodown_command_line + 2 ] ) ) test_rmd_page[ lodown_command_line + 2 ] <- ""
				if( grepl( "your_" , test_rmd_page[ lodown_command_line + 3 ] ) ) test_rmd_page[ lodown_command_line + 3 ] <- ""
				
			}
			
		}
		
		rmd_page <- c( setup_rmd_page , test_rmd_page )
				
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
	
