# analyze survey data for free (http://asdfree.com) with the r language
# consumer expenditure survey
# all available years

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/CES/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Consumer%20Expenditure%20Survey/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


############################################################
# download all available Consumer Expenditure Survey files #
# with R then save every file as an R data frame (.rda)    #
############################################################


# set your working directory.
# all CES files will be stored here
# after downloading and importing it.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/CES/" )
# ..in order to set your current working directory


# remove the # in order to run this install.packages line only once
# install.packages( c( "MonetDBLite" , "sqldf" , "survey" , "SAScii" , "descr" , "mitools" , "plyr" , "downloader" , "digest" , "readxl" , "stringr" , "reshape2" , "R.utils" , "rvest" ) )


library(foreign) 	# load foreign package (converts data files into R)
library(downloader)	# downloads and then runs the source() function on scripts from github


# load the census bureau's poverty thresholds
source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Poverty/scrape%20census%20thresholds.R" , prompt = FALSE )

# load the download_cached and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url("https://raw.githubusercontent.com/ajdamico/asdfree/master/Download%20Cache/download%20cache.R", prompt = FALSE, echo = FALSE)

# now you have an object `all_thresholds` that goes back as far as 1990
names( all_thresholds ) <- gsub( "year" , "this_year" , names( all_thresholds ) )

# figure out which years are available to download
years.to.download <-
	as.numeric(
		unique( 
			gsub( 
				"(.*)/pumd/data/stata/intrvw([0-9][0-9]).zip(.*)" , 
				"\\2" , 
				grep(
					"(.*)/pumd/data/stata/intrvw([0-9][0-9]).zip(.*)" ,
					readLines( "http://www.bls.gov/cex/pumd_data.htm#stata" ) ,
					value = TRUE
				)
			) 
		)
	)

# add centuries
years.to.download <- ifelse( years.to.download >= 96 , 1900 + years.to.download , 2000 + years.to.download )
	

############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #

# this script's download files should be incorporated in download_cached's hash list
options( "download_cached.hashwarn" = TRUE )
# warn the user if the hash does not yet exist

# create the temporary file location to download all files
tf <- tempfile()

# loop through each year requested by the user
for ( year in years.to.download ){

	# year-specific output directory
	output.directory <- paste0( getwd() , "/" , year , "/" )
	
	# if the year-specific output directory doesn't exist, create it
	try( dir.create( output.directory ) , silent = T )

	# determine the exact path to the current year of microdata on the bureau of labor statistics ftp site
	# for each of the four main consumer expenditure public use microdata files
	intrvw.ftp <- paste0( "http://www.bls.gov/cex/pumd/data/stata/intrvw" , substr( year , 3 , 4 ) , ".zip" )
	diary.ftp <- paste0( "http://www.bls.gov/cex/pumd/data/stata/diary" , substr( year , 3 , 4 ) , ".zip" )
	docs.ftp <- paste0( "http://www.bls.gov/cex/pumd/documentation/documentation" , substr( year , 3 , 4 ) , ".zip" )
	
	
	# all three file types to download
	ttd <- c( "intrvw" , "diary" , "docs" )
	
	
	# loop through the interview, expenditure, diary, and documentation files and..
	# download each to a temporary file
	# unzip each to a directory within the current working directory
	# save in each of the requested formats
	for ( fn in ttd ){
	
		# filetype-specific output directory
		output.directory <- paste0( getwd() , "/" , year , "/" , fn )
		
		# if the filetype-specific output directory doesn't exist, create it
		try( dir.create( output.directory ) , silent = T )

		# copy over the filetype-specific ftp path
		ftp <- get( paste( fn , "ftp" , sep = "." ) )
	
		# download the filetype-specific zipped file
		# and save it as the temporary file
		download_cached( ftp , tf , mode = 'wb' )


		# unzip all of the files in the downloaded .zip file into the current working directory
		# then save all of their unzipped locations into a character vector called 'files'
		files <- unzip( tf , exdir = output.directory )
		# note that this saves *all* of the files contained in the .zip

		# loop through each of the dta files and (depending on the conversion options set above) save files in necessary formats
		
		# identify dta files
		dta.files <- files[ grep( '\\.dta' , files ) ]

		# loop through a character vector containing the complete filepath
		# of each of the dta files downloaded to the local disk..
		for ( i in dta.files ){

			# figure out where the final '/' lies in the string
			sl <- max( gregexpr( "\\/" , i )[[1]] )		
			
			# use that to figure out the filename (without the directory)
			dta.fn <- substr( i , sl + 1 , nchar( i ) ) 
			
			# figure out where the last '.' lies in the string
			dp <- max( gregexpr( "\\." , i )[[ 1 ]] )
			
			# use that to figure out the filename (without the directory or the extension)
			df.name <- substr( i , sl + 1 , dp - 1 )

			# read the current stata-readable (.dta) file into R
			x <- read.dta( i )
			
			# if the data.frame is a family file, tack on poverty thresholds
			if( grepl( "fmli" , df.name ) ){
			
				# subset the complete threshold data down to only the current year
				thresh_merge <- subset( all_thresholds , this_year == year )
				
				# remove the `year` column
				thresh_merge$this_year <- NULL
				
				# rename fields so they merge cleanly
				names( thresh_merge ) <- c( 'family_type' , 'num_kids' , 'poverty_threshold' )
			
				x$num_kids <- ifelse( x$perslt18 > 8 , 8 , x$perslt18 )
				x$num_kids <- ifelse( x$num_kids == x$fam_size , x$fam_size - 1 , x$num_kids )
				
				# re-categorize family sizes to match census groups
				x$family_type <-
					ifelse( x$fam_size == 1 & x$age_ref < 65 , "Under 65 years" ,
					ifelse( x$fam_size == 1 & x$age_ref >= 65 , "65 years and over" ,
					ifelse( x$fam_size == 2 & x$age_ref < 65 , "Householder under 65 years" ,
					ifelse( x$fam_size == 2 & x$age_ref >= 65 , "Householder 65 years and over" ,
					ifelse( x$fam_size == 3 , "Three people" , 
					ifelse( x$fam_size == 4 , "Four people" , 
					ifelse( x$fam_size == 5 , "Five people" , 
					ifelse( x$fam_size == 6 , "Six people" , 
					ifelse( x$fam_size == 7 , "Seven people" , 
					ifelse( x$fam_size == 8 , "Eight people" , 
					ifelse( x$fam_size >= 9 , "Nine people or more" , NA ) ) ) ) ) ) ) ) ) ) )
				
				# merge on the `poverty_threshold` variable while
				# confirming no records were tossed
				before_nrow <- nrow( x )
				
				x <- merge( x , thresh_merge )
				
				stopifnot( nrow( x ) == before_nrow )
			
			}
			
			# save it to an object named by what's contained in the df.name character string
			assign( df.name , x )
		
			# save the file as an R data file (.rda) immediately
			save( list = df.name , file = paste0( output.directory , "/" , df.name , ".rda" ) )
				
			# since the file has been read into RAM, it should be deleted as well
			rm( list = df.name ) ; rm( x )
			
			# clear up RAM
			gc()
			
			# then delete the original file from the local disk
			file.remove( i )
			
		}
	}
}
