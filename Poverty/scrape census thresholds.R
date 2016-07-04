# install.packages( c( "xml2" , "rvest" , "readxl" , "stringr" , "reshape2" , "XML" , "downloader" ) )


library(xml2)
library(rvest)
library(readxl)
library(stringr)
library(reshape2)
library(XML)
library(downloader)


# load the download_cached and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url("https://raw.githubusercontent.com/ajdamico/asdfree/master/Download%20Cache/download%20cache.R", prompt = FALSE, echo = FALSE)

# initiate an empty data.frame object
all_thresholds <- NULL

cpov <- "https://www.census.gov/data/tables/time-series/demo/income-poverty/historical-poverty-thresholds.html" 

pgdl <- try( pg <- read_html(cpov) , silent = TRUE )
if( class( pgdl ) == 'try-error' ) pg <- read_html(cpov, method='wininet')

all_links <- html_attr(html_nodes(pg, "a"), "href")

# find all excel files on the census poverty webpage
excel_locations <- grep( "thresholds/thresh(.*)\\.(.*)" , all_links , value = TRUE )

# figure out which years are available among the excel file strings
ya <- ( 1990:2058 )[ substr( 1990:2058 , 3 , 4 ) %in% gsub( "(.*)thresh(.*)\\.(.*)" , "\\2" , excel_locations ) ]

# loop through all years available
for ( year in rev(ya) ){

	# figure out the location of the excel file on the drive
	this_excel <- paste0( "https:" , grep( substr( year , 3 , 4 ) , excel_locations , value = TRUE ) )
	
	# name the excel file something appropriate
	fn <- paste0( tempdir() , "/" , basename( this_excel ) )
	
	# download the file to your local disk
	download_cached( this_excel , fn , mode = 'wb' )
	
	# import the current table
	if( grepl( "\\.csv$" , fn ) ){

		skipsix <- try( this_thresh <- read.csv( fn , skip = 6 , stringsAsFactors = FALSE ) , silent = TRUE )
		
		if( class( skipsix ) == 'try-error' ) skipfive <- try( this_thresh <- read.csv( fn , skip = 7 , stringsAsFactors = FALSE ) , silent = TRUE ) else skipfive <- NULL
		
		if( class( skipfive ) == 'try-error' ) this_thresh <- read.csv( fn , skip = 5 , stringsAsFactors = FALSE )
		
	} else {
		this_thresh <- read_excel( fn )
	}
	
	# if the text `Weighted` exists in the second column, toss the second column
	if( any( grepl( "Weighted" , c( names( this_thresh )[2] , this_thresh[ , 2 ] ) ) ) ) this_thresh <- this_thresh[ , -2 ]
	
	# keep all rows where the second column is not missing
	this_thresh <- this_thresh[ !is.na( this_thresh[ , 2 ] ) & !( str_trim( this_thresh[ , 2 ] ) == "" ) , ]
	
	# remove crap at the beginning and end
	this_thresh[ , 1 ] <- str_trim( iconv( as.character( this_thresh[ , 1 ] ) , to = "ASCII" , sub = " " ) )
	this_thresh[ , 1 ] <- str_trim( gsub( "\\." , "" , as.character( this_thresh[ , 1 ] ) ) )
	this_thresh <- this_thresh[ !is.na( this_thresh[ , 1 ] ) & !( this_thresh[ , 1 ] %in% "" ) ,  ]
	
	this_thresh[ -1 ] <- sapply( this_thresh[ -1 ] , function( z ) as.numeric( gsub( ",|\\$" , "" , z ) ) )
	
	
	# keep only rows where a `family_type` matches something we've already found
	# this_thresh <- this_thresh[ this_thresh[ , 1 ] %in% all_thresholds$family_type , ]

	# name the 2nd-10th columns based on number of kids
	names( this_thresh ) <- c( "family_type" , 0:8 )
	
	# reshape the table from wide to long
	this_thresh <- melt( this_thresh , "family_type" )
	
	# appropriately name everything
	names( this_thresh ) <- c( 'family_type' , 'num_kids' , 'threshold' )
	
	# tack on the year
	this_thresh$year <- year
	
	this_thresh <- subset( this_thresh , !is.na( family_type ) & !is.na( threshold ) )
		
	# typo on census bureau page
	this_thresh <-
		subset(
			this_thresh ,
			!( 
				threshold == 26753 & 
				year == 2000 & 
				num_kids == 8 & 
				family_type == "Eight persons" 
			)
		)

	stopifnot( nrow( this_thresh ) == 48 )
	
	# stack it with the others
	all_thresholds <- rbind( all_thresholds , this_thresh )
	
}

all_thresholds$family_type <- gsub( "persons" , "people" , all_thresholds$family_type )
all_thresholds$num_kids <- as.numeric( as.character( all_thresholds$num_kids ) )


# done scraping official census poverty thresholds back to 1990
