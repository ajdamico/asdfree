
library(XML)
library(httr)

download_ipumsi <-
	function( url , username , password , file = gsub( "\\.gz" , "" , basename( url ) ) ){

		if( !( substr( url , nchar( url ) - 6 , nchar( url ) ) == '.csv.gz' ) | !( gsub( "https://international\\.ipums\\.org/international-action/downloads/extract_files/(.*)" , "\\1" , url ) == basename( url ) ) ) stop( "download_ipumsi() requires a url= structure like\\n\\rhttps://international.ipums.org/international-action/downloads/extract_files/[projectname]_[extractnumber].csv.gz" )
	
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

		# download the actual file
		
		GET( url , write_disk( basename( url ) , overwrite = TRUE ) )

		# store the file to the local disk
		gunzip( basename( url ) , file )
		
		file
	}
	


structure_ipumsi <-
	function( url , username , password ){

		if( !( substr( url , nchar( url ) - 6 , nchar( url ) ) == '.csv.gz' ) | !( gsub( "https://international\\.ipums\\.org/international-action/downloads/extract_files/(.*)" , "\\1" , url ) == basename( url ) ) ) stop( "download_ipumsi() requires a url= structure like\\n\\rhttps://international.ipums.org/international-action/downloads/extract_files/[projectname]_[extractnumber].csv.gz" )
	
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

		# pull the `xml` file from ipums
		xml_url <- gsub( "\\.csv\\.gz" , ".xml" , url )
		
		# figure out the character vs numeric structure from the xml file
		xml <- GET( xml_url )
		stru <- unlist( xpathSApply( xmlParse( xml ) , "//*//*//*//*" , xmlGetAttr , "type" ) )
		stru <- stru[ stru != 'rectangular' ]

		stru
	}
	


decimals_ipumsi <-
	function( url , username , password ){

		if( !( substr( url , nchar( url ) - 6 , nchar( url ) ) == '.csv.gz' ) | !( gsub( "https://international\\.ipums\\.org/international-action/downloads/extract_files/(.*)" , "\\1" , url ) == basename( url ) ) ) stop( "download_ipumsi() requires a url= structure like\\n\\rhttps://international.ipums.org/international-action/downloads/extract_files/[projectname]_[extractnumber].csv.gz" )
	
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

		# pull the `xml` file from ipums
		xml_url <- gsub( "\\.csv\\.gz" , ".xml" , url )
		
		# figure out the implied decimals from the xml file
		xml <- GET( xml_url )
		
		dcml <- as.numeric( unlist( xpathSApply( xmlParse( xml ) , "//*//*//*" , xmlGetAttr , "dcml" ) ) )
		
		if( any( is.na( dcml ) ) ) stop( "xml parsing problem" )
		
		dcml
		
	}
