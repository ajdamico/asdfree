# analyze survey data for free (http://asdfree.com) with the r language
# health services and resources administration (hrsa)
# health professional shortage areas (hpsa) file
# most currently available data (the file on the website constantly changes)

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/HPSA/" )
# source_url( "https://raw.github.com/ajdamico/asdfree/master/Health%20Professional%20Shortage%20Areas/download%20current%20hpsa%20table.R" , prompt = FALSE , echo = TRUE )
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


###############################################################
# download the most current Health Professional Shortage Area #
# file with R, then save every file as an R data frame (.rda) #
###############################################################


# set your working directory.
# all HPSA files will be stored here
# after downloading and importing it.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/HPSA/" )
# ..in order to set your current working directory




# # # # # # # # # # # # # #
# warning: perl required! #
# # # # # # # # # # # # # #

# if you do not have perl installed, this two-minute video
# walks through how to get it (for free): http://www.screenr.com/QiN8


# remove the # in order to run this install.packages line only once
# install.packages('gdata')


# load necessary libraries
library(gdata) 		# load the gdata package (imports excel [.xls] files into R)


# create a temporary file on your local disk
tf <- tempfile()

# download the most current HRSA HPSA datafile
# save it on your local disk to the temporary file
download.file( 
	"http://datawarehouse.hrsa.gov/DataDownload/HPSA/HPSA.zip" , 
	tf , 
	mode = 'wb' 
)


# identify a download directory inside the HPSA folder on your local disk
download.dir <- paste0( getwd() , "/download" )

# create that download directory
dir.create( download.dir )

# unzip the files contained in the HPSA.zip into that download directory
files <- unzip( tf , exdir = download.dir )

# immediately delete the temporary file
file.remove( tf )

# identify the file containing the text `xls`
template.file <- files[ grepl( "xls" , files ) ]

# read in the excel (.xls) file containing the column headers
template <- read.xls( template.file )

# make all column names lowercase
names( template ) <- tolower( names( template ) )

# if the first five characters of the column name are 'hpsa.' then remove those characters
names( template ) <- gsub( 'hpsa.' , '' , names( template ) , fixed = TRUE )


# loop through the PC (primary care), DC (dental care), and MH (mental health) files
for ( fn in c( "PC" , "DC" , "MH" ) ){

	# find the file containing the two uppercase characters for the current loop
	cur.filepath <- files[ grepl( fn , files ) ]
	
	# read the current file into RAM
	x <- readLines( cur.filepath )

	# throw out blank lines
	x <- x[ !( x == "" ) ]

	# so long as any line begins with `|`..
	while ( sum( substr( x , 1 , 1 ) == "|" ) > 0 ){
	
		# figure out which is the first one
		i <- which( substr( x , 1 , 1 ) == "|" )[ 1 ]

		# replace the line above it with..
		# the line above it PLUS the line
		x[ ( i - 1 ) ] <- paste0( x[ ( i - 1 ) ] , x[ i ] )
		
		# then throw out the actual line
		x <- x[ -i ]
	}

	# write the fixed file back to a temporary file on your hard disk
	writeLines( x , tf )

	# read that temporary file into RAM, but this time as a data.frame
	y <- read.table( tf , sep = "|" , comment.char = "" , quote = "" , header = FALSE , stringsAsFactors = FALSE )

	# immediately delete the temporary file
	file.remove( tf )
	
	# overwrite the column names with the template columns' names
	names( y ) <- names( template )

	# immediately assign the current data frame to the original filename
	assign( fn , y )
	
	# and blank out both x and y
	x <- y <- NULL
	
}

# save each of the three tables to a R data file (.rda)
save( PC , file = "HPSA_PC.rda" )
save( MH , file = "HPSA_MH.rda" )
save( DC , file = "HPSA_DC.rda" )

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
