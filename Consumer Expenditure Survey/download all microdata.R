# analyze survey data for free (http://asdfree.com) with the r language
# consumer expenditure survey
# 1998-2013

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/CES/" )
# years.to.download <- 2013:1998
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Consumer%20Expenditure%20Survey/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# http://www.screenr.com/Zpd8

# anthony joseph damico
# ajdamico@gmail.com

# if you use this script for a project, please send me a note
# it's always nice to hear about how people are using this stuff

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf


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



library(foreign) 	# load foreign package (converts data files into R)


# uncomment this line to download all available data sets
# uncomment this line by removing the `#` at the front
# years.to.download <- 2013:1998

# uncomment to only download the most current available year
# years.to.download <- 2013
# but why not just download them all?  ;)



# conversion options #

# it's recommended you keep a version of the .rda files,
# since they work with all subsequent scripts

# do you want to save an R data file (.rda) to the working directory?
rda <- TRUE

# do you want to save a stata-readable file (.dta) to the working directory?
dta <- FALSE

# do you want to save a comma-separated values file (.csv) to the working directory?
csv <- FALSE

# end of conversion options #




############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #


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
	expn.ftp <- paste0( "http://www.bls.gov/cex/pumd/data/stata/expn" , substr( year , 3 , 4 ) , ".zip" )
	diary.ftp <- paste0( "http://www.bls.gov/cex/pumd/data/stata/diary" , substr( year , 3 , 4 ) , ".zip" )
	docs.ftp <- paste0( "http://www.bls.gov/cex/pumd/documentation/documentation" , substr( year , 3 , 4 ) , ".zip" )
	
	# loop through the interview, expenditure, diary, and documentation files and..
	# download each to a temporary file
	# unzip each to a directory within the current working directory
	# save in each of the requested formats
	for ( fn in c( "intrvw" , "expn" , "diary" , "docs" ) ){
	
		# filetype-specific output directory
		output.directory <- paste0( getwd() , "/" , year , "/" , fn )
		
		# if the filetype-specific output directory doesn't exist, create it
		try( dir.create( output.directory ) , silent = T )

		# copy over the filetype-specific ftp path
		ftp <- get( paste( fn , "ftp" , sep = "." ) )
	
		# download the filetype-specific zipped file
		# and save it as the temporary file
		download.file( ftp , tf , mode = 'wb' )

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

			# if the user requests that the file be converted to an R data file (.rda) or comma separated value file (.csv)
			# then the file must be read into r
			if ( rda | csv ){
				
				# read the current stata-readable (.dta) file into R
				# save it to an object named by what's contained in the df.name character string
				assign( df.name , read.dta( i ) )
		
				# if the user requests saving the file as an R data file (.rda), save it immediately
				if ( rda ) save( list = df.name , file = paste0( output.directory , "/" , df.name , ".rda" ) )
				
				# if the user requests saving the file as a comma separated value file (.csv), save it immediately
				if ( csv ) write.csv( get( df.name ) , , file = paste0( output.directory , "/" , df.name , ".csv" ) )

				# since the file has been read into RAM, it should be deleted as well
				rm( list = df.name )
				
				# clear up RAM
				gc()
				
			}
			
			# if the user did not request that the file be stored as a stata-readable file (.dta),
			# then delete the original file from the local disk
			if ( !dta ) file.remove( i )
			
		}
	}
}


# print a reminder: set the directory you just saved everything to as read-only!
message( paste( "all done.  you should set" , getwd() , "read-only so you don't accidentally alter these files." ) )

# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/

# dear everyone: please contribute your script.
# have you written syntax that precisely matches an official publication?
message( "if others might benefit, send your code to ajdamico@gmail.com" )
# http://asdfree.com needs more user contributions

# let's play the which one of these things doesn't belong game:
# "only you can prevent forest fires" -smokey bear
# "take a bite out of crime" -mcgruff the crime pooch
# "plz gimme your statistical programming" -anthony damico
