# analyze us government survey data with the r language
# health and retirement study
# RAND contributed files
# HRS, CAMS, and Family K and F files

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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#############################################################################################################################
# prior to running this analysis script, the longitudinal RAND-contributed HRS files must be downloaded and unzipped on the #
# local machine. running the 1992 - 2010 download HRS microdata.R script download all of the necessary files automatically  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/usgsd/master/Health%20and%20Retirement%20Study/1992-2010%20download%20HRS%20microdata.R   #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will place the HRS files "rndhrs_l.dta" and a few others in the "C:/My Directory/HRS/download" folder         #
#############################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


#################################################################
# import the four main RAND HRS files into an R SQLite database #
#################################################################


# set your working directory.
# all HRS data files should have been stored within a download/ folder here
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/HRS/" )
# ..in order to set your current working directory


# choose the name of the database
db.name <- 'RAND.db'


# remove the # in order to run this install.packages line only once
# install.packages( "SQLite" )

# no need to edit anything below this line #


# # # # # # # # #
# program start #
# # # # # # # # #


require(foreign) 	# load foreign package (converts data files into R)
require(RSQLite) 	# load RSQLite package (creates database files in R)


# create a new RAND database in the main working folder
db <- dbConnect( SQLite() , paste( getwd() , db.name , sep = "/" ) )


# figure out the locations of the four RAND longitudinal enhanced files
hrsL.file <- paste( getwd() , "download/randLstataSE/statase/rndhrs_l.dta" , sep = "/" )
famR.file <- paste( getwd() , "download/rndfamB_stata/StateSE/rndfamr_b.dta" , sep = "/" )
famK.file <- paste( getwd() , "download/rndfamB_stata/StateSE/rndfamk_b.dta" , sep = "/" )
cams.file <- paste( getwd() , "download/randcams_b/randcams_b.dta" , sep = "/" )


# create a character vector with the four table names
tn <- c( 'hrsL' , 'famR' , 'famK' , 'cams' )


# all of these files are large enough to be read into RAM on a 4GB computer
# however, they will overload memory if exported as a whole
# and therefore need to be written to a SQLite database in chunks
chunks <- 100	# start with 100 chunks.. this can be lowered if RAM overloads


# loop through all four files
for ( j in tn ){

	# find the filepath of the current file
	fn <- get( paste0( j , '.file' ) )

	# read the current file into RAM
	x <- read.dta( fn , convert.factors = FALSE )

	# determine each chunk size
	starts.stops <- floor( seq( 1 , nrow( x ) , length.out = chunks ) )

	# for each chunk..
	for ( i in 2:( length( starts.stops ) )  ){

		# if it's the first..
		if ( i == 2 ){
			# start at the first record 
			rows.to.add <- ( starts.stops[ i - 1 ] ):( starts.stops[ i ] )
		} else {
			# start at the first record of the chunk, plus one
			rows.to.add <- ( starts.stops[ i - 1 ] + 1 ):( starts.stops[ i ] )
		}

		# store the data frame in the database with dbWriteTable in chunks
		dbWriteTable( db , j , x[ rows.to.add , ] , append = TRUE )
	}

	# add a new column "one" that simply contains the number 1 for every record in the data set
	dbSendQuery( db , paste( "ALTER TABLE" , j , "ADD COLUMN one REAL" ) )
	dbSendQuery( db , paste( "UPDATE" , j , "SET one = 1" ) )
	
	# delete the current file..
	rm( x )
	
	# ..and clear up RAM
	gc()
}


# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
