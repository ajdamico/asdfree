# analyze survey data for free (http://asdfree.com) with the r language
# surveillance epidemiology and end results
# 1973 through 2011

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/SEER/" )
# source_url( "https://raw.github.com/ajdamico/asdfree/master/Surveillance%20Epidemiology%20and%20End%20Results/import%20all%20tables%20into%20rda.R" , prompt = FALSE , echo = TRUE )
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


################################################
# load each data table in the seer data set    #
# into an R data file (.rda) on the local disk #
################################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###############################################################################################################
# prior to running this importation script, the seer text file must be loaded on the local machine with:      #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/asdfree/blob/master/Surveillance%20Epidemiology%20and%20End%20Results/download.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a 'SEER_1973_2011_TEXTDATA' directory in C:/My Directory/SEER (or the cw directory) #
###############################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# set your working directory.
# all SEER data files will be stored here
# after downloading.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/SEER/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( "SAScii" )

# no need to edit anything below this line #


# # # # # # # # #
# program start #
# # # # # # # # #


library(SAScii) 		# load the SAScii package (imports ascii data with a SAS script)


# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# identify all files to import into r data files (.rda) #

# first, look in the downloaded zipped file's main directory,
# and store a character vector `all.files` containing the filepaths
# to each of the files inside that directory
all.files <- list.files( "./SEER_1973_2011_TEXTDATA" , full.names = TRUE , recursive = TRUE )

# create a character vector matching the different cancer file name identifiers
words.to.match <- c( "BREAST" , "COLRECT" , "DIGOTHR" , "FEMGEN" , "LYMYLEUK" , "MALEGEN" , "RESPIR" , "URINARY" , "OTHER" )

# subset the `all.files` character vector to only retain files containing *any* of the words in the `words.to.match` vector
( ind.file.matches <- all.files[ grep( paste0( words.to.match , collapse = "|" ) , all.files ) ] )
# by encasing the above statement in parentheses, the `ind.file.matches` object will also be printed to the screen

# subset the `all.files` character vector to only retain files containing *either* the string '19agegroups' or the string 'singleages'
( pop.file.matches <- all.files[ grep( "19agegroups|singleages" , all.files ) ] )
# by encasing the above statement in parentheses, the `pop.file.matches` object will also be printed to the screen


# end of file identification  #
# # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # # # # # #
# import all individual-level files #

# create a temporary file on the local disk
edited.sas.instructions <- tempfile()

# read the sas importation script into memory
z <- readLines( "./SEER_1973_2011_TEXTDATA/incidence/read.seer.research.nov13.sas" )

# get rid of the first through fourth lines (the -1:-4 part)
# and at the same time get rid of the word `char` (the gsub part)
z <- gsub( "char" , "" , z[-1:-4] )
# since SAScii cannot handle char# formats

# remove the leading space in front of the at signs,
z <- gsub( "@ " , "@" , z , fixed = TRUE )
# since SAScii does not expect that either

# write the result back to a temporary file on the local disk
writeLines( z , edited.sas.instructions )


# loop through each of the individual-level files matched above
for ( fp in ind.file.matches ){

	# print current progress to the screen
	print( paste( "currently working on" , fp ) )

	
	# use the revised sas importation instructions
	# to read the current ascii file directly into an r data.frame
	x <- 
		read.SAScii(
			fp ,
			edited.sas.instructions
		)
	# this simply reads the text file into the object `x`
	
	
	# calculate the save-file-location
	# by removing the downloaded zipped file's folderpath
	# and substituting `txt` with `rda`
	# and converting the file location to lowercase
	sfl <- 
		gsub( 
			"seer_1973_2011_textdata/" , 
			"" , 
			gsub(
				".txt" ,
				".rda" ,
				tolower( fp ) , 
				fixed = TRUE
			)
		)
	
	
	# convert all column names to lowercase
	# in the current data.frame object `x`
	names( x ) <- tolower( names( x ) )
	
	
	# (if it doesn't already exist)
	# create the directory of the save-file-location
	dir.create( 
		dirname( sfl ) , 
		showWarnings = FALSE ,
		recursive = TRUE
	)

	
	# save the data.frame to the save-file-location
	save( x , file = sfl )

	
	# remove `x` from working memory
	rm( x )

	# clear up RAM
	gc()

}

# end of individual-level file importation  #
# # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # # # # # #
# import all population-level files #

# use the population file's data dictionary, available at
# http://seer.cancer.gov/manuals/Text.Data.popdic.html
# to construct a function that will define the names and widths
# for a read.fwf call.  (for more detail about read.fwf, type ?read.fwf)

# initiate a function #
pop.read.in <-
	# that only requires the filepath
	function( fp ){

		# define the population file's widths
		pop.widths <- c( 4 , 2 , 2 , 3 , 2 , 1 , 1 , 1 , 2 , 10 )

		# define the population file's column (variable) names
		pop.names <- c( 'year' , 'stateab' , 'statefips' , 'countyfips' , 'registry' , 'race' , 'origin' , 'sex' , 'age' , 'population' )

		# actually read the text data into working memory
		pop <- read.fwf( fp , pop.widths , col.names = pop.names )

		# divide the population column by ten, as specified by the data dictionary
		pop$population <- pop$population / 10
	
		# since this is the last line of the function
		# return the population data.frame
		pop
	}
# end of function initiation


# loop through each of the population-level files matched above
for ( fp in pop.file.matches ){

	# print current progress to the screen
	print( paste( "currently working on" , fp ) )

	# use that `pop.read.in` function defined above
	# to create a data.frame object `x` that read in the current file
	x <- pop.read.in( fp )
		
	# calculate the save-file-location
	# by removing the downloaded zipped file's folderpath
	# and substituting `txt` with `rda`
	# and converting the file location to lowercase
	sfl <- 
		gsub( 
			"seer_1973_2011_textdata/" , 
			"" , 
			gsub(
				".txt" ,
				".rda" ,
				tolower( fp ) , 
				fixed = TRUE
			)
		)
		
		
	# convert all column names to lowercase
	# in the current data.frame object `x`
	names( x ) <- tolower( names( x ) )
	
	
	# (if it doesn't already exist)
	# create the directory of the save-file-location
	dir.create( 
		dirname( sfl ) , 
		showWarnings = FALSE ,
		recursive = TRUE
	)

	
	# save the data.frame to the save-file-location
	save( x , file = sfl )

	
	# remove `x` from working memory
	rm( x )

	# clear up RAM
	gc()

}

# end of population-level file importation  #
# # # # # # # # # # # # # # # # # # # # # # #


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
