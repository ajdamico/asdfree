
library(XML)
library(httr)
library(rvest)


# thanks to the amazing respondents on stackoverflow for this algorithm
# http://stackoverflow.com/questions/34829920/how-to-authenticate-a-shibboleth-multi-hostname-website-with-httr-in-r

authenticate_ipumsi <-
	function( url , username , password ){
	
		if( !( substr( url , nchar( url ) - 6 , nchar( url ) ) == '.csv.gz' ) | !( gsub( "https://international\\.ipums\\.org/international-action/downloads/extract_files/(.*)" , "\\1" , url ) == basename( url ) ) ) stop( "download_ipumsi() requires a url= structure like\\n\\rhttps://international.ipums.org/international-action/downloads/extract_files/[projectname]_[extractnumber].csv.gz" )
	
		tf <- tempfile()
			
		set_config( config( ssl_verifypeer = 0L ) )

		# get first page
		p1 <- GET( "https://international.ipums.org/international-action/users/login" , verbose( info = TRUE ) )

		# post login credentials
		b2 <- list( "j_username" = username , "j_password" = password )
		
		c2 <- 
			c(
				JSESSIONID = p1$cookies[ p1$cookies$domain=="#HttpOnly_live.identity.popdata.org" , ]$value ,
				`_idp_authn_lc_key` = p1$cookies[ p1$cookies$domain == "live.identity.popdata.org" , ]$value 
			)

		p2 <- POST( p1$url , body = b2 , set_cookies( .cookies = c2 ) , encode = "form" )

		# parse hidden fields
		h2 <- read_html( p2$content )
		form <-  h2 %>% html_form() 

		# post hidden fields
		b3 <- 
			list( 
				"RelayState" = form[[1]]$fields[[1]]$value , 
				"SAMLResponse" = form[[1]]$fields[[2]]$value
			)
			
		c3 <- 
			c(
				JSESSIONID = p1$cookies[ p1$cookies$domain == "#HttpOnly_live.identity.popdata.org" , ]$value ,
				`_idp_session` = p2$cookies[ p2$cookies$name == "_idp_session" , ]$value ,
				`_idp_authn_lc_key` = p2$cookies[p2$cookies$name == "_idp_authn_lc_key" , ]$value 
			)
		
		p3 <- POST( form[[1]]$url , body = b3 , set_cookies( .cookies = c3 ) , encode = "form" )

		# get interesting page
		c4 <- 
			c(
				JSESSIONID = p3$cookies[p1$cookies$domain=="international.ipums.org" && p3$cookies$name == "JSESSIONID" , ]$value ,
				`_idp_session` = p3$cookies[ p3$cookies$name == "_idp_session" , ]$value ,
				`_idp_authn_lc_key` = p3$cookies[ p3$cookies$name == "_idp_authn_lc_key" , ]$value 
			)
		
		p4 <- GET( "https://international.ipums.org/international-action/menu" , set_cookies( .cookies = c4 ) )

		# return the appropriate cookies
		c4
	}


download_ipumsi <-
	function( url , username , password , file = gsub( "\\.gz" , "" , basename( url ) ) ){

		cookies <- authenticate_ipumsi( url , username , password )
	
		# download the actual file
		GET( url , write_disk( basename( url ) , overwrite = TRUE ) , set_cookies( .cookies = cookies ) )

		# store the file to the local disk
		gunzip( basename( url ) , file )
		
		# pull the structure as well
		stru <- structure_ipumsi( url , cookies )
		
		# return the filepath and the structure vector
		list( file , stru )
	}


structure_ipumsi <-
	function( url , cookies ){
	
		# pull the `xml` file from ipums
		xml_url <- gsub( "\\.csv\\.gz" , ".xml" , url )
		
		# figure out the character vs numeric structure from the xml file
		xml <- GET( xml_url , set_cookies( .cookies = cookies ) )

		stru <- unlist( xpathSApply( xmlParse( xml ) , "//*//*//*//*" , xmlGetAttr , "type" ) )
		stru <- stru[ stru != 'rectangular' ]

		stru
	}
