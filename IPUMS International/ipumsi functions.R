library(httr)
library(R.utils)

download_ipumsi <-
	function( url , username , password , file = gsub( "\\.gz" , "" , basename( url ) ) ){

		tf <- tempfile()
	
		writeBin( GET( "https://international.ipums.org/international-action/users/login" )$content , tf )

		at <- gsub( "(.*)value=\"(.*)\"(.*)" , "\\2" , grep( "new_login(.*)authenticity_token" , readLines( tf ) , value = TRUE ) )

		values <- 
			list( 
				"login[email]" = username , 
				"login[password]" = password ,
				"utf8" = "&#x2713;" ,
				"authenticity_token" = at ,
				"login[is_for_login]" = "1"
			)

		POST( "https://international.ipums.org/international-action/users/validate_login" , body = values )

		GET( url , write_disk( basename( url ) , overwrite = TRUE ) )

		gunzip( basename( url ) , file )

		countLines( file )
	}
