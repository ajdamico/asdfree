# analyze survey data for free (http://asdfree.com) with the r language
# medicare current beneficiary survey
# 1997-2010

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/MCBS/" )
# years.to.crosswalk <- 1997:2010
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Medicare%20Current%20Beneficiary%20Survey/multiyear%20variable%20crosswalk.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #


# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com



# remove the # in order to run this install.packages line only once
# install.packages( c( 'SAScii' , 'stringr' , 'downloader' , 'digest' ) )


library(SAScii) 	# load the SAScii package (imports ascii data with a SAS script)
library(stringr) 	# load stringr package (manipulates character strings easily)
library(downloader)	# downloads and then runs the source() function on scripts from github


# set the directory containing all cost & use files from cms
# that is, the cms-provided files, not the `importation.R`-created files
# setwd( "C:/My Directory/MCBS/" )

# designate which years of cost & use files to crosswalk
# years.to.crosswalk <- 1997:2010
# uncomment the line above by removing the `#`


# rics in any consolidated files
ric.in.cons <- c( 'ricx' , 'ric1' , 'ric2' , 'ric2f' , 'rick' , 'ric4' , 'ric5' , 'ricps' , 'ricss' , 'ric8' , 'rica' , 'rica2' )


# initiate an empty object
z <- NULL

# loop through every year of mcbs cost and use files available
for ( year in years.to.crosswalk ){

	# determine the directory containing all of the sas read-in instructions
	sas.input.fp <-
		paste0( 
			"./cost" , 
			substr( year , 3 , 4 ) , 
			"/Data/flat files/readme"
		)
	
	# find all files in the folder
	all.sas <- tolower( list.files( sas.input.fp ) )

	# only keep files that are in a consolidated file somewhere
	all.sas <- all.sas[ grep( paste0( ric.in.cons , collapse = "|" ) , all.sas ) ]
	
	# initiate an empty object
	y <- NULL
	
	# loop through each text file
	for ( sas in all.sas ){
	
		# specify the full path to the current sas importation script
		fn <- paste0( sas.input.fp , "/" , sas )
	
		# try to read it in with SAScii
		sascii.success <- try( ps <- parse.SAScii( fn ) , silent = TRUE )
		
		# find the block in the sas importation script containing `LABEL`
		rl <- readLines( fn )
		
		# where does the label block start
		label.start <- grep( "\\<LABEL\\>" , rl )

		# if LABEL is by itself, then add one..otherwise remove the word `LABEL`
		if ( str_trim( rl[ label.start ] ) == "LABEL" ){
			label.start <- label.start + 1 
		} else {
			rl[ label.start ] <- gsub( 'LABEL' , '' , rl[ label.start ] )
		}
		
		# if there's more than one LABEL block, there's a problem
		stopifnot( length( label.start ) == 1 )
		
		# which lines contain semicolons
		sc.lines <- grep( ";" , rl )
		
		# where does the label block end
		label.end <- min( sc.lines[ sc.lines > label.start ] )
		
		# if the semicolon is by itself, then subtract one
		if ( str_trim( rl[ label.end ] ) == ";" ){
			label.end <- label.end - 1 
		}

		# isolate the sas importation script to only the label block
		lb <- rl[ label.start:label.end ]
		
		# separate the variable names from the actual labels
		lblock <- strsplit( lb , "=" ) 
		
		# remove empty elements
		lblock <- lblock[ which( sapply( lblock , function( z ) length( z ) != 0 ) ) ]
		
		# extract the variable name
		vn <- str_trim( sapply( lblock , '[[' , 1 ) )
		
		# extract the text in the label
		lb.text <- gsub( "'|;" , '' , str_trim( sapply( lblock , '[[' , 2 ) ) )
		lb.text <- gsub( '"' , '' , lb.text )

		# construct a label data frame to merge
		ldf <- data.frame( varname = tolower( vn ) , labels = toupper( lb.text ) )
	
		# if parse.SAScii above failed..
		if ( class( sascii.success ) == 'try-error' ){ 
			
			# ..then simply use the text in the `LABELS` block
			vars <- vn
		
		} else {
		
			# otherwise, capture all variable names
			vars <- ps[ ps$width > 0 , 'varname' ]
			
		}
		
		# determine the ric's filename
		ric.fn <- gsub( '.txt' , '' , tolower( sas ) , fixed = TRUE )
		ric.fn <- gsub( '.sas' , '' , ric.fn , fixed = TRUE )
		
		# rica2 should just be ric2
		ric.fn <- gsub( 'rica2' , 'ric2' , ric.fn )
		
		# save all variable names from that consolidated file (`x` object) into a data.frame
		w <- data.frame( ric = ric.fn , varname = tolower( vars ) )
		
		# merge the labels on to the main data.frame `w`
		w <- merge( w , ldf , all.x = TRUE )
	
		# stack it with whatever's already in `y`
		y <- rbind( y , w )
		
	}
	
	# create a new column named as the current year with all TRUE values
	y[ , as.character( year ) ] <- TRUE

	# convert all factor variables to character
	fvars <- sapply( y , is.factor )
	y[ , fvars ] <- sapply( y[ , fvars ] , as.character )
	
		
	# if it's the first year of the loop, just replace `z` with `y`,
	# otherwise merge them - keeping both sides regardless of a matching `varname`
	if ( is.null( z ) ) z <- y else z <- merge( z , y , by = c( 'varname' , 'ric' ) , all = TRUE )
	
	# if there's a `labels.x` column..
	if ( 'labels.x' %in% names( z ) ){
		# ..and if it's got any missings..
		if ( any( is.na( z$labels.x ) ) ){
			# ..then replace it with whatever's in labels.y
			z[ is.na( z$labels.x ) , 'labels.x' ] <- 
				z[ is.na( z$labels.x ) , 'labels.y' ]
		}
		
		z$labels <- z$labels.x
		
		# then also delete labels.*
		z$labels.x <- z$labels.y <- NULL
	}
	
}

# replace all missing values with FALSE
z[ is.na( z ) ] <- FALSE

# remove duplicates
z <- unique( z )

# make `labels` column number three
z <- z[ , c( 1 , 2 , ncol( z ) , 3:( ncol( z ) - 1 ) ) ]

# now your object `z` contains one record per variable name that was *ever*
# in the mcbs consolidated file over the period you've specified.
# hey, why not take a look at the first..
head( z )
# ..and last six records of your new data.frame
tail( z )


# do you want to sort the final table based on
# which variables were in the _most_ years available?
# if so, use this line by removing the `#` to uncomment
# and also commenting out the `order` command below this one..
# z <- z[ order( rowSums( z[ , -1 ] ) , decreasing = TRUE ) , ]

# ..or do you want to sort the final table based on
# which variables were in the _final_ year available,
# then the _second from final_ year, then the _third from final_ year
# and so on? if so, use this crazy crazy line.
z <- z[ do.call( order , data.frame( !z[ , as.character( rev( years.to.crosswalk ) ) ] ) ) , ]



# do you want to throw out variables that were available in _all_ years?
# if so, uncomment this line by removing the `#` in front:
# z <- z[ rowSums( z[ , -1 ] ) != ( ncol( z ) - 1 ) , ]
# rowSums( z[ , -1 ] ) sums up all the TRUE values as 1 and FALSE as 0
# across rows, but excluding the first column.  if all of those rows are TRUE,
# then that sum should match [the number of columns of z minus one].
# so simply keep all the records in `z` where this is _not_ the case.


# how 'bout subsetting `z` in other fancy ways?  you could exclusively look at variables
# that _were_ available in some years but _not_ in others, over a specific period of time.
# so, for example, here's how to look at variables in the mcbs consolidated file
# over the three-year period from 1999 to 2001 that occurred
# _at least once_ but _did not occur_ three times:
# z <- z[ !( rowSums( z[ , as.character( 1999:2001 ) ] ) %in% c( 0 , 3 ) ) , ]


# save this `z` object as a less vaguely-named (but harder-to-type) data.frame
multiyear.variable.crosswalk <- z


# export the data.frame object to a csv in the current working directory
write.csv( multiyear.variable.crosswalk , "multiyear variable crosswalk.csv" , row.names = FALSE )

# handy little reference document, eh?


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
