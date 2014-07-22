# analyze survey data for free (http://asdfree.com) with the r language
# fda adverse event reporting system
# all available quarters

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/FAERS/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/FDA%20Adverse%20Event%20Reporting%20System/download%20and%20import.R" , prompt = FALSE , echo = TRUE )
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


##############################################################################
# download every available quarter of the fda adverse event reporting system #
# with R, then unzip every file into the current working directory.          #
##############################################################################


# set your working directory.
# all faers files will be stored here
# after downloading and importing it.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/FAERS/" )
# ..in order to set your current working directory


# remove the # in order to run this install.packages line only once
# install.packages( c( "downloader" , "XML" ) )


############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #


library(XML)		# load XML (parses through html code to extract links)
library(downloader)	# downloads and then runs the source() function on scripts from github


# load the download.cache and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url(
	"https://raw.github.com/ajdamico/usgsd/master/Download%20Cache/download%20cache.R" ,
	prompt = FALSE ,
	echo = FALSE
)



# # # # # # # #
# downloading #
# # # # # # # #


# specify the homepage of the legacy fda quarterly data sets
legacy.url <- "http://www.fda.gov/Drugs/GuidanceComplianceRegulatoryInformation/Surveillance/AdverseDrugEffects/ucm083765.htm"

# specify the homepage of the faers quarterly data sets
faers.url <- "http://www.fda.gov/Drugs/GuidanceComplianceRegulatoryInformation/Surveillance/AdverseDrugEffects/ucm082193.htm"

# create a `downloads` folder in the current working directory
dir.create( "downloads/" , showWarnings = FALSE )

# create an `unzips` folder in the current working directory
dir.create( "unzips/" , showWarnings = FALSE )

# loop through two text strings: `faers` and `legacy`
for ( f.l in c( "faers" , "legacy" ) ){

	# for both, download the contents of the homepages
	doc <- htmlParse( get( paste0( f.l , ".url" ) ) )

	# extract all possible link blocks from the current document
	possible.links <- xpathSApply( doc , "//a" , xmlAttrs )
	
	# for each of those links, extract the text contained inside the possible-link block
	possible.href.names <- xpathSApply( doc , "//a" , xmlValue )

	# isolate only the links that lead to a `.zip` file
	zip.locations <- unlist( lapply( possible.links , function( z ) grepl( '\\.zip$' , tolower( z["href"] ) ) ) )

	# subset the `possible.links` list to only zipped files
	links <- possible.links[ zip.locations ]

	# repeat that subset on the list of names
	link.names <- possible.href.names[ zip.locations ]

	# confirm that these two results have the same length
	stopifnot( length( links ) == length( link.names ) )

	# identify which of the link-names have the word `ascii` in them
	names.with.ascii <- unlist( lapply( link.names , function( z ) grepl( 'ascii' , tolower( z ) ) ) )

	# identify which of the link-names-with-ascii have a `href` tag in them, indicating an actual hyperlink
	ascii.links <- lapply( links[ names.with.ascii ] , function( z ) z[ "href" ] )

	# further limit the `link.names` object to only those with the text `ascii`
	ascii.names <- link.names[ names.with.ascii ]

	# extract the four-digit year from the remaining filenames
	ascii.years <- gsub( "(.*)ASCII_([0-9]*)q(.*)" , "\\2" , ascii.names )

	# extract the one-digit quarter from the remaining filenames
	ascii.quarter <- gsub( "(.*)([0-9]*)q([0-9])(.*)" , "\\3" , ascii.names )

	# confirm all years are 2004 or later
	stopifnot( ascii.years %in% 2004:3000 )

	# confirm all quarters are one through four
	stopifnot( ascii.quarter %in% 1:4 )

	# begin looping through each of the available ascii.links..
	for ( i in seq_along( ascii.links ) ){

		# create a character string containing "year (q)quarter"
		fp <- paste0( ascii.years[ i ] , " q" , ascii.quarter[ i ] )
		
		# slap `downloads/` in front and `.zip` on the back
		fn <- paste0( "downloads/" , fp , '.zip' )
	
		# attempt to download the current link, save it within the `downloads` folder
		download.cache( 
			paste0( "http://www.fda.gov" , ascii.links[[ i ]] ) , 
			fn
		)
		
		# unzip that downloaded file to the `unzips/` folder,
		# also within the current working directory
		unzip( fn , exdir = paste0( "./unzips/" , fp ) )
		
	}

}


# # # # # # #
# importing #
# # # # # # #

# identify all files - yes all of them - in the current working directory
all.files.in.working.directory <- list.files( recursive = TRUE )

# limit the character vector containing all files to only the ones ending in `.txt`
text.files <- all.files.in.working.directory[ grep( "\\.txt$" , tolower( all.files.in.working.directory ) ) ]

# stat and size files contain control counts, not actual microdata, throw them out
text.files <- text.files[ !( substr( tolower( basename( text.files ) ) , 1 , 4 ) %in% c( 'size' , 'stat' ) ) ]

# loop through each of the text files to import..
for ( i in text.files ){

	# determine the tablename (the filename sans extension)
	tablename <- gsub( "\\.txt$" , "" , tolower( basename( i ) ) )

	# create another character string appending `.rda` to the end
	rda.filename <- paste0( tablename , ".rda" )
	
	# print current progress to the screen
	cat( paste( "saving" , i , "to" , rda.filename , "           \r" ) )
	
	# check for missing dollar signs at the end of the first column
	first.100 <- unlist( lapply( gregexpr( "\\$" , readLines( i , n = 100 ) ) , length ) )
	
	# check if there are different numbers of columns in the first hundred lines of the text file
	if( length( unique( first.100 ) ) > 1 ){

		# load in the entire text file
		lines <- readLines( i )
		
		# tack a `$` onto the end of the first line
		lines[ 1 ] <- paste0( lines[ 1 ] , "$" )
		
		# overwrite the text file with the extra $ on the first line
		writeLines( lines , i )
	
	}
	
	# attempt to read the text file into the object `x` using `$` separators.
	# if the read-in fails, do not break the loop.  instead, store that error in a `wrap.failure` object
	wrap.failure <- try( x <- read.table( i , sep = "$" , header = TRUE , comment.char = "" , quote = "" ) , silent = TRUE )
	# if the read-in works, you'll have the data.frame object `x` to work with.  hooray!
	
	# so long as the `wrap.failure` object contains an error..
	while( class( wrap.failure ) == 'try-error' ){
	
		# record the wrap failure's location
		wfl <- as.numeric( gsub( "(.*)line ([0-9]*) did not have(.*)" , "\\2" , wrap.failure[1] ) )
	
		# if the wrap failure location doesn't contain a problem-line, break the whole program.
		if( is.na( wfl ) ) stop( "one.  not a wrap failure.  something else is wrong." ) else {

			# doubly-confirm that a wrap failure is happening.  check whether the number of $'s (the delimiter) varies on any lines.
			if ( length( unique( unlist( lapply( gregexpr( "\\$" , a <- readLines( i ) ) , length ) ) ) ) == 1 ){
				
				stop( "two.  not a wrap failure.  something else is wrong." )
				
			} else {
			
				# paste the line of the wrap failure and the line after together.
				a <- c( a[ seq( wfl ) ] , paste0( a[ wfl + 1 ] , a[ wfl + 2 ] ) , a[ seq( wfl + 3 , length( a ) ) ] )
			
				# overwrite the file on the disk
				writeLines( a , i )
				
				# now the `read.table` command should work properly.
				wrap.failure <- try( x <- read.table( i , sep = "$" , header = TRUE , comment.char = "" , quote = "" ) , silent = TRUE )
				# if this ever works, you'll have `x` read in as a data.frame object.  hooray!
			
				# remove the lines read-in at the top of this innermost `if` block
				rm( a )
				
				# clear up RAM
				gc()
				
			}
			
		}
		
	}
	
	
	# determine which columns (if any) are 100% missings
	columns.100pct.missing <- names( which( sapply( x , function( z ) all( is.na( z ) ) ) ) )
	
	# just throw them out of the data.frame object
	x <- x[ , !( names( x ) %in% columns.100pct.missing ) ]
	
	# convert all column names to lowercase
	names( x ) <- tolower( names( x ) )
	
	# a primaryid column has extra characters in front that it shouldn't
	names( x )[ grepl( 'primaryid' , names( x ) ) ] <- 'primaryid'
	
	# a outc_code column occasionally is missing its final `e`
	names( x )[ names( x ) == 'outc_cod' ] <- 'outc_code'
	
	# `lot_num` and `lot_nbr` switch back and forth a lot.  pick one
	names( x )[ names( x ) == 'lot_num' ] <- 'lot_nbr'
	
	# copy `x` over to the table's actual name
	assign( tablename , x )
	
	# remove `x` from working memory
	rm( x )
	
	# clear up RAM
	gc()
	
	# save the data.frame object to the rda filename on the local disk
	save( list = tablename , file = rda.filename )
	
	# remove the tablename from working memory
	rm( list = tablename )
	
	# clear up RAM
	gc()
	
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
