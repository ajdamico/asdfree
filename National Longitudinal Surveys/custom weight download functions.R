# # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # #
# functions related to nlsy panel weight download #
# # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # #


library(httr)
library(XML)


# initiate a function to download all available survey-year selections for any of the nlsy studies
get.nlsy.selections <-
	function(
		study
		# study must be one of the options shown on https://www.nlsinfo.org/weights such as:
		# "nlsy97" , "nlsy79" , "nlscya" , "nlsym" , "nlsom" , "nlsyw" , "nlsmw"
	){
		
		
		# for a particular study's weights page, download the contents of the page
		z <- GET( paste0( "https://www.nlsinfo.org/weights/" , study ) )

		# de-construct the html
		doc <- htmlParse( z )
		
		# look for all `input` blocks
		opts <- getNodeSet( doc , "//input" )
		
		# look for all `name` attributes within input blocks
		all.name.values <- sapply( opts , xmlGetAttr , "name" )
		
		# find all text containing the letters `SURV`
		all.surveys <- unlist( all.name.values[ grep( "SURV" , all.name.values ) ] )

		# and here are your year choices
		all.surveys
	}

	
# initiate a function to download a specific combination of survey-year weights
# for one of the nlsy studies
	
	
# set uona = "NO" if you want to weight using
# "the respondents are in ALL of the selected years"

# set uona = "YES" if you want to weight using
# "the respondents are in ANY OR ALL of the selected years"

get.nlsy.weights <-
	function( 
		study , 
		# study must be one of the options shown on https://www.nlsinfo.org/weights such as:
		# "nlsy97" , "nlsy79" , "nlscya" , "nlsym" , "nlsom" , "nlsyw" , "nlsmw"

		uona , 
		
		selections 
	){
	
		# make contact with the weights page
		GET( paste0( "https://www.nlsinfo.org/weights/" , study ) )
		
		# initiate a `values` list containing the series of survey-year selections
		values <- as.list( rep( "1" , length( selections ) ) )
		# these are just ones.
	
		# rename each object within the list according to the survey-year
		names( values ) <- selections
	
		# add the use-or-not-and decision
		values[[ "USE_OR_NOT_AND" ]] <- uona

		# add a few form parameters that the server just expects, but never change.
		values[[ "form_id" ]] <- "weights_cohort_form"
		
		values[[ "op" ]] <- "Download"

		values[[ "accept-charset" ]] <- "UTF-8"

		
		# determine the form-build-id
		bid <- GET( paste0( "https://www.nlsinfo.org/weights/" , study ) , query = values )
		
		# de-construct the html
		doc <- htmlParse( bid )
		
		# look for `input` blocks
		opts <- getNodeSet( doc , "//input" )
		
		# find all `name` attributes within `input` blocks
		all.name.values <- sapply( opts , xmlGetAttr , "name" )
		
		# find all `value` attributes within `input` blocks
		all.values <- sapply( opts , xmlGetAttr , "value" )
		
		# determine the two form-build-id values
		form.build.id <- all.values[ all.name.values == 'form_build_id' ]
		
		# take the second form-build-id on the page
		values[[ "form_build_id" ]] <- form.build.id[ 2 ]

		# download the data
		x <- POST( paste0( "https://www.nlsinfo.org/weights/" , study ) , body = values )

		# initiate a temporary file on the local disk
		tf <- tempfile()

		# save the zipped file contents on the local drive
		writeBin( content( x , "raw" ) , tf )

		# unzip the file and store the filepath into the object `d`
		d <- unzip( tf )

		# determine the `.dat` file that's just been unzipped
		dat <- d[ grep( '.dat' , d , fixed = TRUE ) ]

		# read both columns into an R data.frame
		y <- read.table( dat , sep = " " , col.names = c( 'id' , 'weight' ) )

		# delete the temporary file from the local disk
		unlink( tf )
		
		# delete all unzipped files from the local disk
		unlink( d )
		
		# return the data.frame containing the weights
		y
	}

# view which points-in-time are available for a particular study
# get.nlsy.selections( "nlsy97" )

# download weights for respondents in 1997
# w <- get.nlsy.weights( "nlsy97" , 'YES' , 'SURV1997' )
# save those weights into an data.frame object called `w`

# download weights for respondents who were in any of the 1997, 2002, or 2007 surveys
# w <- get.nlsy.weights( "nlsy97" , 'YES' , c( 'SURV1997' , 'SURV2002' , 'SURV2007' ) )
# save those weights into an data.frame object called `w`

# download weights for respondents who were in all of the 1997, 2002, and 2007 surveys
# w <- get.nlsy.weights( "nlsy97" , 'NO' , c( 'SURV1997' , 'SURV2002' , 'SURV2007' ) )
# save those weights into an data.frame object called `w`

# download weights for respondents who are in all available surveys
# w <- get.nlsy.weights( "nlsy97" , "NO" , get.nlsy.selections( "nlsy97" ) )
# save those weights into an data.frame object called `w`

