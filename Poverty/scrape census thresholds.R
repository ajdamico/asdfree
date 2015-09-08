# install.packages( c( "readxl" , "stringr" , "reshape2" , "XML" ) )

library(readxl)
library(stringr)
library(reshape2)
library(XML)

# initiate an empty data.frame object
all_thresholds <- NULL

# loop through each year with an html page showing the thresholds
for ( year in 1990:2009 ){

	# figure out the exact url
	this_html <- 
		paste0( 
			"http://www.census.gov/hhes/www/poverty/data/threshld/thresh" , 
			substr( year , 3 , 4 ) , 
			".html" 
		)
	
	# scrape the table from the web
	this_thresh <- readHTMLTable( this_html )[[ 1 ]]
	
	# remove goofy characters
	this_thresh[ , 1 ] <- iconv( this_thresh[ , 1 ] , to = "ASCII" , sub = "_" )
	
	# remove rows where the first column contains missing or just the weird A
	this_thresh <- this_thresh[ !( this_thresh[ , 1 ] %in% c( "_" , NA ) ) , ]
	
	# remove the second column, universally
	this_thresh$V2 <- NULL
	
	# remove the final row, universally
	this_thresh <- this_thresh[ -nrow( this_thresh ) , ]
	
	# name the 2nd-10th row 0-8 (number of kids)
	names( this_thresh )[ -1 ] <- 0:8 

	# remove the first and second rows, universally
	this_thresh <- this_thresh[ -1:-2 , ]
	
	# remove rows where the second column is the weird A
	this_thresh <- this_thresh[ iconv( this_thresh[ , 2 ] , to = 'ASCII' , sub = "_" ) != '_' , ]
	
	# remove weird A space text from the first column
	this_thresh$V1 <- gsub( "_" , "" , as.character( this_thresh$V1 ) , fixed = TRUE )
	
	# remove dots in the first column
	this_thresh$V1 <- str_trim( gsub( "." , "" , as.character( this_thresh$V1 ) , fixed = TRUE ) )
	
	# switch persons with people
	this_thresh$V1 <- gsub( "persons" , "people" , this_thresh$V1 )
	
	# reshape the table from wide to long
	this_thresh <- melt( this_thresh , "V1" )
	
	# appropriately name everything
	names( this_thresh ) <- c( "family_type" , "num_kids" , "threshold" )
	
	# tack on a year
	this_thresh$year <- year

	# stack it with the others
	all_thresholds <- rbind( all_thresholds , this_thresh )
	
}

# remove all commas and convert the columns to numeric
all_thresholds$threshold <- as.numeric( gsub( "," , "" , all_thresholds$threshold ) )

# find all excel files on the census poverty webpage
excel_locations <-
	grep( 
		"threshld/thresh(.*)\\.xls" , 
		xpathSApply( 
			htmlParse( 
				"http://www.census.gov/hhes/www/poverty/data/threshld/index.html" 
			) , 
			"//a//@href" 
		) , 
		value = TRUE 
	)

# figure out which years are available among the excel file strings
ya <- ( 2010:2099 )[ substr( 2010:2099 , 3 , 4 ) %in% gsub( "(.*)thresh(.*)\\.xl(.*)" , "\\2" , excel_locations ) ]

# loop through all years available
for ( year in ya ){

	# figure out the location of the excel file on the drive
	this_excel <- paste0( "http://www.census.gov" , grep( substr( year , 3 , 4 ) , excel_locations , value = TRUE ) )
	
	# name the excel file something appropriate
	fn <- paste0( tempdir() , "/" , basename( this_excel ) )
	
	# download the file to your local disk
	download.file( this_excel , fn , mode = 'wb' )
	
	# import the current excel file
	this_thresh <- read_excel( fn )
	
	# if the text `Weighted` exists in the second column, toss the second column
	if( any( grepl( "Weighted" , this_thresh[ , 2 ] ) ) ) this_thresh <- this_thresh[ , -2 ]
	
	# keep all rows where the second column is not missing
	this_thresh <- this_thresh[ !is.na( this_thresh[ , 2 ] ) , ]
	
	# remove crap at the beginning and end
	this_thresh[ , 1 ] <- str_trim( iconv( as.character( this_thresh[ , 1 ] ) , to = "ASCII" , sub = " " ) )
	this_thresh[ , 1 ] <- str_trim( gsub( "\\." , "" , as.character( this_thresh[ , 1 ] ) ) )
	
	# keep only rows where a `family_type` matches something we've already found
	this_thresh <- this_thresh[ this_thresh[ , 1 ] %in% all_thresholds$family_type , ]

	# name the 2nd-10th columns based on number of kids
	names( this_thresh ) <- c( "family_type" , 0:8 )
	
	# reshape the table from wide to long
	this_thresh <- melt( this_thresh , "family_type" )
	
	# appropriately name everything
	names( this_thresh ) <- c( 'family_type' , 'num_kids' , 'threshold' )
	
	# tack on the year
	this_thresh$year <- year
	
	# stack it with the others
	all_thresholds <- rbind( all_thresholds , this_thresh )
	
}

all_thresholds$year <- as.numeric( all_thresholds$year )
all_thresholds$threshold <- as.numeric( all_thresholds$threshold )
all_thresholds$num_kids <- as.numeric( as.character( all_thresholds$num_kids ) )

# toss the records missing thresholds
all_thresholds <- 
	subset( 
		all_thresholds , 
		!is.na( threshold )
	)

# typo on census bureau page
all_thresholds <-
	subset(
		all_thresholds ,
		!( 
			threshold == 26753 & 
			year == 2000 & 
			num_kids == 8 & 
			family_type == "Eight people" 
		)
	)

# done scraping official census poverty thresholds back to 1990