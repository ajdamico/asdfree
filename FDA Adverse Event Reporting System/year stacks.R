# analyze survey data for free (http://asdfree.com) with the r language
# fda adverse event reporting system
# all available quarters

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/FAERS/" )
# source_url( "https://raw.github.com/ajdamico/asdfree/master/FDA%20Adverse%20Event%20Reporting%20System/year%20stacks.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# https://www.youtube.com/watch?v=JLt9JfaAxUg

# anthony joseph damico
# ajdamico@gmail.com

# if you use this script for a project, please send me a note
# it's always nice to hear about how people are using this stuff

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf


############################################################################
# load every quarterly data file of the fda adverse event reporting system #
# with R, then stack them into year files, matching the fda's yearly pubs  #
############################################################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#######################################################################################################################
# prior to running this stacking script, the faers tables must be loaded as single rda files on the local disk        #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "https://raw.github.com/ajdamico/asdfree/master/FDA%20Adverse%20Event%20Reporting%20System/download%20and%20import.R" #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will download and import rda files to C:/My Directory/FAERS or wherever the working directory was set.  #
#######################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/FAERS/" )
# ..in order to set your current working directory


############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #


# define the outersect function: take two vectors and find all components in one or the other but not both.
outersect <- function( x , y ) { sort( c( setdiff( x , y ) , setdiff( y , x ) ) ) }

# determine all files in the current working directory,
# then immediately limit those files to `.rda` files only
all.rdas <- list.files()[ grep( '\\.rda$' , list.files() ) ]

# extract the two-digit year from each rda filename
years <- gsub( "(.*)([0-9][0-9])q([0-9])\\.rda" , "\\2" , all.rdas )

# extract the one-through-four quarter from each rda filename
quarters <- gsub( "(.*)([0-9][0-9])q([0-9])\\.rda" , "\\3" , all.rdas )

# extract the text prefix from each rda filename
prefixes <- gsub( "(.*)([0-9][0-9])q([0-9])\\.rda" , "\\1" , all.rdas )

# determine which files are legacy ( 2004 - 2011 plus the first three quarters of 2012 )
legacy.files <- as.numeric( years ) %in% 0:11 | ( years %in% 12 & quarters %in% 1:3 )

# determine which files are the modern system ( 2013 and beyond plus the last quarter of 2012 )
faers.files <- years %in% 13:99 | ( years %in% 12 & quarters %in% 4 )

# create a numeric vector of all available microdata years
all.years <- unique( as.numeric( years ) ) + 2000

# create a unique character vector of all file prefixes
up <- unique( prefixes )


# loop through each unique prefix
for ( this.prefix in up ){

	# loop through all available file years
	for( this.year in unique( years ) ){

		# create a subdirectory containing the current year
		dir.create( as.character( as.numeric( this.year ) + 2000 ) , showWarnings = FALSE )
		
		# identify which of the `rda` files are for this year, and also for the modern faers system
		faers <- all.rdas[ prefixes == this.prefix & faers.files & this.year == years ]
		
		# identify which of the `rda` files are for this year, and also for the legacy system
		legacy <- all.rdas[ prefixes == this.prefix & legacy.files & this.year == years ]
		
		# loop through both `faers` and `legacy
		for ( f.l in c( 'faers' , 'legacy' ) ){
			
			# initiate a NULL `x` object
			x <- NULL
			
			# loop through all rda files specified in the `faers` or the `legacy` objects
			for ( this.rda in get( f.l ) ){
			
				# print current progress to the screen
				cat( "stacking" , this.rda , "                              \r" )
			
				# load the `.rda` file into current working memory
				load( this.rda )
				
				# remove the `rda` extension from the `this.rda` string
				dfn <- gsub( "\\.rda" , "" , this.rda )
				# that'll be the current data.frame name that's just been loaded
				
				# if `x` is still empty..
				if( is.null( x ) ){
					
					# store the just-loaded data.frame object into `x`
					x <- get( dfn )
					
					# tack on year..
					x$year <- years[ which( all.rdas == this.rda ) ]
					
					# ..and quarter columns
					x$quarter <- quarters[ which( all.rdas == this.rda ) ]
					
					# remove the originally-named data.frame from working memory
					rm( list = dfn )
					
					# clear up RAM
					gc()
				
				} else {
					
					# store the just-loaded data.frame object into `y`
					y <- get( dfn )

					# tack on year..
					y$year <- years[ which( all.rdas == this.rda ) ]
					
					# ..and quarter columns
					y$quarter <- quarters[ which( all.rdas == this.rda ) ]
									
					# if there's a `x` column name, toss it please.
					y$x <- NULL
					
					# remove the originally-named data.frame from working memory
					rm( list = dfn )
					
					# clear up RAM
					gc()
				
					# find non-matching columns between `x` and `y`
					nonmatching.columns <- outersect( names( x ) , names( y ) )
					
					# if there are any non-matching columns in `x`..
					if( !all( nmc <- ( nonmatching.columns %in% names( x ) ) ) ){
					
						# print a note to the screen
						print( paste( nonmatching.columns[ !nmc ] , "newly added in" , this.rda ) )
						
						# ..and add a column of all missings
						x[ , nonmatching.columns[ !nmc ] ] <- NA
						
					}
					
					# if there are any non-matching columns in `y`..
					if( !all( nmc <- ( nonmatching.columns %in% names( y ) ) ) ){
					
						# print a note to the screen
						print( paste( nonmatching.columns[ !nmc ] , "not available in" , this.rda ) )
						
						# ..and add a column of all missings
						y[ , nonmatching.columns[ !nmc ] ] <- NA
						
					}
				
					# now `x` (the original data.frame) and `y` (the latest quarter of data) can be stacked
					x <- rbind( x , y )
					
					# remove the data.frame `y` from working memory
					rm( y )
					
					# clear up RAM
					gc()
					
				}
				
			}
			
			# so long as anything was added to `x` at all..
			if( !is.null( x ) ){ 
				
				# copy `x` over to a more appropriately-named object
				assign( paste0( f.l , "." , this.prefix ) , x )
				# for example: `faers.demo`
				
				# remove the object `x` from working memory
				rm( x )
				
				# clear up RAM
				gc()
				
				# save the fully-stacked data.frame object to the disk
				save( 
					list = paste0( f.l , "." , this.prefix ) , 
					
					# store it in the appropriate year folder
					file = paste0( './' , as.numeric( this.year ) + 2000 , "/" , f.l , ' stacked ' , this.prefix , '.rda' ) 
				)
				
				# remove the fully-stacked object from working memory
				rm( list = paste0( f.l , "." , this.prefix ) )
				
				# clear up RAM
				gc()
			
			}
			
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
