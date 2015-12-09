setwd( "C:/My Directory/SHARE" )

library(foreign)
library(XML)
library(httr)

your.id <- "your_userid"
your.password <- "your_password"

# set the username and password
values <-
	list(
		"data[User][id]" = your.id ,
		"data[User][password]" = your.password
	)

	
GET( "http://cdata28.uvt.nl/sharedatadissemination/users/login" , query = values )
POST( "http://cdata28.uvt.nl/sharedatadissemination/users/login" , body = values )

z <- htmlParse( GET( "http://cdata28.uvt.nl/sharedatadissemination/" ) )

all.links <- xpathSApply( z , "//a", function(u) xmlAttrs(u)["href"] )

releases.to.download <- all.links[ grep( 'releases' , all.links ) ]

releases.already.downloaded <- NULL

# continue spidering through the /releases/ links until you've downloaded everything.
while( length( releases.to.download ) > 0 ){

	# start with the first element in the releases-links object
	current.download <- releases.to.download[ 1 ]

	# download the current link.
	this.download <- GET( paste0( "http://cdata28.uvt.nl" , current.download ) )
	
	# if it's a file that's been downloaded..
	if( !is.null( this.download$headers$`content-disposition` ) ){

		# decide on the folder-path to save the current file.
		# all share data sets are in the /releases/ folder followed by either download/ or show/
		# followed by *the correct save path*  (this needs to be not-greedy, in regular-expression-speak)
		# followed by whatever who cares toss it.
		folder.name <- gsub( "(.*)(/releases/)(download|show)/(.*?)/(.*)" , "\\4" , current.download )
	
		# create the folder if it's not already there.
		dir.create( folder.name , showWarnings = FALSE )
	
		# decipher the local file name
		lfn <- basename( gsub( "(.*)filename=" , "" , this.download$headers$`content-disposition` ) )
	
		# remove starting and ending quotes
		lfn <- paste0( folder.name , "/" , gsub( '\"' , "" , lfn ) )
	
		# save the file to the current working directory.
		writeBin( content( this.download , "raw" ) , lfn )
	
		# the file no longer needs to be stored in RAM
		rm( this.download )
		
		# clear up working memory
		gc()

		# if it's not a zipped file, nothing more needs to be done.  it's already saved to the disk.
		# but if it iz i mean is a zipped file, then..
		if ( grepl( "\\.zip$" , lfn ) ){
		
			# unzip the file to a folder of the same name
			w <- unzip( lfn , exdir = paste0( "./" , gsub( "\\.zip$" , "" , lfn ) ) )
		
			# if it contains a stata file
			for ( i in grep( "\\.dta$" , w ) ){
		
				x <- read.dta( w[ i ] , convert.factors = FALSE )
			
				save( x , file = paste0( "./" , gsub( "\\.dta$" , "_dta.rda" , w[ i ] ) ) )
			
				rm( x )
			
				gc()
				
			}
			
			# if it contains an spss file
			for ( i in grep( "\\.sav$" , w ) ){
			
				x <- read.spss( w[ i ] , use.value.labels = FALSE , to.data.frame = TRUE )
			
				save( x , file = paste0( "./" , gsub( "\\.sav$" , "_spss.rda" , w[ i ] ) ) )
			
				rm( x )
			
				gc()
			
			}
			
			# if it contains neither
			if ( !any( grepl( "\\.sav$|\\.dta$" , w ) ) ) print( paste( w , "weird zipped file, worth lookin at" ) )
		
			# delete the zipped file
			file.remove( lfn )
		
		}
		
	
	# otherwise..
	} else {
	
		# find all links on the current page
		these.links <- xpathSApply( htmlParse( this.download ) , "//a" , function(u) xmlAttrs( u )[ "href" ] )
		
		# add the ones in the /releases/ folder to what needs to be downloaded.
		releases.to.download <- c( releases.to.download , these.links[ grep( 'releases' , these.links ) ] )
	
	}
	
	# add the current.download to what's already been downloaded.
	releases.already.downloaded <- c( current.download , releases.already.downloaded )
	
	# anything that's already been downloaded doesn't have to be downloaded again.
	releases.to.download <- releases.to.download[ !( releases.to.download %in% releases.already.downloaded ) ]
	
	# continue the while() loop.
}


