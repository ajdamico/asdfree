# analyze survey data for free (http://asdfree.com) with the r language
# medicare current beneficiary survey
# 1997-2010

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# i.understand <- FALSE
# setwd( "C:/My Directory/MCBS/temp/" )
# input.directory <- "C:/My Directory/MCBS/"
# output.directory <- "C:/My Directory/MCBS/cau/"
# source_url( "https://raw.githubusercontent.com/ajdamico/usgsd/master/Medicare%20Current%20Beneficiary%20Survey/importation.R" , prompt = FALSE , echo = TRUE )
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


# # # # # # # # # # # # # #
# start of warning block  #

# prior to running this script, either delete this block of code,
# or simply set a variable
# i.understand <- TRUE
# so you don't have to see this warning anymore.

# if you haven't set `i.understand`, then the program is going to default to false
# and print out the annoying stop() every time!
if( !exists( 'i.understand' ) ) i.understand <- FALSE

if ( !i.understand ){
	stop( 'this block of code is _critical_.  please do not ignore it.  gr8' )
	# since the medicare current beneficiary survey is a limited data set,
	# it's important to set a temporary directory within your protected folders
	# just in case some export doesn't work to the appropriate file,
	# it still goes into _some_ protected folder
	# uncomment this next line to designate a working directory that complies with your DUA:
	
	# setwd( "C:/My Directory/MCBS/temp/" )
	
	stop( 'if you do not understand the above block of code, you should not be using this script.' )
}

# end of warning block  #
# # # # # # # # # # # # #

# okay.  let's get started.  first: what's this if( !exists( '_something_' ) ) thing?
# this is designed to let you run this script either on its own or as a separate function
# so let's say you set that _something_ variable *before* running this script,
# then you can still call the script with downloader::source_url
# and _something_ will be untouched by this script.
# .. alternatively! ..
# you can not set the _something_ object, and the script will set it for you.



# pretend this is a questionnaire. #
# ready?  set?  go!


# what are the years of cost & use data do you have to import? #

# this defaults to 1997 thru 2010, but only if you haven't defined this variable already
if( !exists( 'consolidated.files.to.create' ) ) consolidated.files.to.create <- 1997:2010

# maybe you just have 2010
# consolidated.files.to.create <- 2010

# maybe you have 2003 thru 2006 and also 2009
# consolidated.files.to.create <- c( 2003:2006 , 2009 )


# where are your files-to-be-imported stored? #

# copy the contents of every cd into a series of folders into the pattern `costYY`
# where `YY` are the last two digits of the year.  so, for example, i personally have a folder
# C:/My Directory/MCBS/
# with these subfolders
# `/cost97` `/cost98` ... `/cost09` `/cost10`

# specify the main folder for all of your cms data to import.. *without* the ending slash.
# mine would be
# input.directory <- "C:/My Directory/MCBS/"
# what is yours?  you *must* declare an `input.directory`
# (but you can create it prior to running this script)


# where do you want your final files saved? #

# specify the main folder for all of your final R-friendly data to go
# i want to put it all in a `cau` folder inside my mcbs directory, so mine would be
# output.directory <- "C:/My Directory/MCBS/cau/"
# what is yours?  you *must* declare an `output.directory`
# (but you can create it prior to running this script)




# do you want to import any individual .dat files as .rda files? #

# individual file-years to import
# this defaults to 2007 thru 2010, but only if you haven't defined this variable already
if ( !exists( 'years.to.import.all.files' ) ) years.to.import.all.files <- 2007:2010

# there are errors with the SAS importation script before 2007
# (at least 2006 didn't work for me)
# so you'll have to mess with those to get the `parse.SAScii` function working
# if you need individual files prior to 2007

# or don't import any by uncommenting (removing the `#` in front of) this line:
# years.to.import.all.files <- NULL


# should this program also save the consolidated file as a sas file in the output.directory? #

# this defaults to FALSE, but only if you haven't defined this variable already
if ( !exists( 'export.sas.file' ) ) export.sas.file <- FALSE
	
	
# remove the # in order to run this install.packages line only once
# install.packages( c( 'SAScii' , 'sas7bdat' , 'plyr' , 'stringr' , 'R.utils' , 'downloader' ) )


# no need to edit anything below this line #


# # # # # # # # #
# program start #
# # # # # # # # # 

library(SAScii) 	# load the SAScii package (imports ascii data with a SAS script)
library(sas7bdat)	# imports native sas files directly into R
library(plyr)		# contains the reshape() function, which makes transforming the data a cinch
library(stringr) 	# load stringr package (manipulates character strings easily)
library(R.utils)	# load the R.utils package (counts the number of lines in a file quickly)
library(foreign) 	# load foreign package (converts data files into R)
library(downloader)	# downloads and then runs the source() function on scripts from github


# confirm `years.to.import.all.files` is a subset of `consolidated.files.to.create`
if( any( !( years.to.import.all.files %in% consolidated.files.to.create ) ) ) stop( "in order to import individual files for a year, you must also create a consolidated file" )



# aside from `rica` and `rica2`, here's a list of all the RIC files
# that should be combined into a single consolidated file at the beneficiary-level
rics <- c( 'ricx' , 'ric1' , 'ric2' , 'ric2f' , 'rick' , 'ric4' , 'ric5' , 'ricps' , 'ricss' , 'ric8' )

# load an R file containing mcbs-specific functions
source_url( "https://raw.githubusercontent.com/ajdamico/usgsd/master/Medicare%20Current%20Beneficiary%20Survey/ric.R" , prompt = FALSE , echo = FALSE )


# loop through every year to import
for ( year in consolidated.files.to.create ){

	# set the flat-file directory path (dynamic across years)
	ff.directory <- 
		paste0( input.directory , "/cost" , substr( year , 3 , 4 ) , "/Data/flat files/" )

	# set the sas7bdat file directory path (dynamic across years)
	sas.directory <- 
		paste0( input.directory , "/cost" , substr( year , 3 , 4 ) , "/Data/sas files/" )

		
	# rica2 is just an extended version of rica, so use rica2 where available
	# identical( rica[ , names( rica )  ] , rica2[ , names( rica ) ] )
	# [1] TRUE

	if ( year < 2000 ) rics_a <- c( rics , 'rica2' ) else rics_a <- c( rics , 'rica' )

	
	# at this point, determine whether to move on to importing all available files in the flat file directory
	if( year %in% years.to.import.all.files ){
		
		# determine all files in the flat file directory
		arics <- list.files( ff.directory )
		
		# keep only files with `.dat` and not already in `rics_a`
		remaining.ric.dat.to.import <-
			arics[ grepl( '.dat' , arics , fixed = TRUE ) & !( gsub( '.dat' , '' , arics , fixed = TRUE ) %in% rics_a ) ]
	
		# chop the `.dat` off of these character strings
		remaining.ric.names.to.import <- 
			gsub( '.dat' , '' , remaining.ric.dat.to.import , fixed = TRUE )
		
		# always throw out `ricn` and `ricn2` files..
		# these will never be imported by this program
		remaining.ric.names.to.import <-
			remaining.ric.names.to.import[ !( remaining.ric.names.to.import %in% c( 'ricn' , 'ricn2' ) ) ]
		
		# add them into the `rics_a` vector to be imported into RAM
		rics_a <- c( remaining.ric.names.to.import , rics_a )
		# note they're actually imported _first_ to conserve RAM
		# (since the data.frame objects in rics_a stay in RAM until the consolidated file is finished)
	} else {
	
		# otherwise, this variable needs to be empty so the if() statement below works properly
		remaining.ric.names.to.import <- NULL
	}

	
	# loop through all RIC files to import into RAM
	for ( i in rics_a ){

		# determine the exact filepath of the sas7bdat file for the current RIC
		sas.fp <-
			paste0( 
				sas.directory ,
				i ,
				'.sas7bdat'
			)
		
		# determine the exact filepath of the ascii (flat) file for the current RIC		
		ascii.fp <-
			paste0( 
				ff.directory ,
				i ,
				'.dat'
			)

		# determine the exact filepath of the sas read-in instructions for the current RIC
		sas.input.instructions <-
			paste0( 
				ff.directory ,
				'readme/' ,
				i ,
				'.txt'
			)
			
		
		# fix the 2010 ric2 sas input instructions manually
		if ( year == 2010 & i == 'ric2' ){
			tf <- tempfile()
			sii <- readLines( sas.input.instructions )
			sii <- gsub( "@145 OCCBACK   2." , "@169 OCCBACK   2." , sii )
			writeLines( sii , tf )
			sas.input.instructions <- tf
		}
				

		# for these files, something is corrupted in the flat files, so just use the sas7bdat importation function
		# ..but don't use this method for all files, because it's a lot slower
		if (
			( year == 1999 & i == 'ricss' ) |
			( year %in% c( 2001 , 2008 ) & i == 'ricx' ) | 
			( year == 2005 & i == 'ric4' ) |
			( year == 2007 & i == 'ric5' ) |
			( year == 2007 & i == 'ric1' ) |
			( year == 2010 & i == 'ric2' ) |
			
			# ricn files do not have SAS importation scripts across the board.
			# just import these files with `read.sas7bdat`
			( i %in% c( 'ricn' , 'ricn2' ) )
		){
		
			# import the .sas7bdat file directly into R
			x <- read.sas7bdat( sas.fp )

			# convert factor variables to character, to match the importation via read.SAScii
			fvars <- sapply( x , is.factor )
			x[ , fvars ] <- sapply( x[ , fvars ] , as.character )
			
			# remove any NaN values created by `read.sas7bdat`
			x <- data.frame( sapply( x , function( z ) { z[ is.nan( z ) ] <- NA ; z } ) )
		
			# convert factor variables to character *again* to match the importation via read.SAScii
			fvars <- sapply( x , is.factor )
			x[ , fvars ] <- sapply( x[ , fvars ] , as.character )
			
			# the 2001 RICX file doesn't have column headers, so..
			if ( year == 2001 & i == 'ricx' ) {
			
				# pull them from the sas importation script
				z <- parse.SAScii( sas.input.instructions )$varname
				
				# throw out the `VERSION` column
				z <- z[ z != 'VERSION' ]
				
				# and put them on the `x` data.frame
				names( x ) <- z
				rm( z )
				
				# the `version` field is stored in the first character of this SAS file for some reason
				x$VERSION <- substr( x$BASEID , 1 , 1 )
				x$BASEID <- substr( x$BASEID , 2 , nchar( x$BASEID ) )
			}

		} else {
	
			# for all other files, simply import with the R SAScii package
			x <-
				read.SAScii(
					
					# flat file location
					ascii.fp ,
					
					# sas commands
					sas.input.instructions ,
					
					# decimals are already everywhere..never divide.
					skip.decimal.division = TRUE
				)
				
		}

		# attempt to convert the appropriate columns to numeric.
		# no big deal if you can't.
		try({
			# figure out which variables should be stored as numeric
			allvars <- parse.SAScii( sas.input.instructions )
			numvars <- allvars[ no.na( !allvars$char ) , 'varname' ]
			
			# convert them to numeric types
			x[ , numvars ] <- sapply( x[ , numvars ] , as.numeric )
		} , silent = TRUE )
		
		
		# convert all column names to lowercase
		names( x ) <- tolower( names( x ) )
		
		# save the current object `x` to the actual RIC, such as `ricx`
		assign( i , x )

		# remove the current object `x` from memory
		rm( x )

		# clear up RAM
		gc()
		
		# save each and every ric file no matter what
		
		# initiate a year-specific folder for the individual RIC files
		year.folder <- paste0( output.directory , year , "/" )
		
		# try creating the directory (within the `output.directory`)
		# but don't bother warning if it's already there
		dir.create( year.folder , showWarnings = FALSE )
	
		# determine the full filepath of this particular RIC file's output .rda
		ric.fp <- paste0( year.folder , i , '.rda' )
		
		# save the file (referred to in the character string `i`) to the full filepath
		save( list = i , file = ric.fp )
	
		# and now, if the current RIC is not needed in the consolidated file, 
		# just save it and remove it from memory to prevent overloading
		if( ( year %in% years.to.import.all.files ) & !( i %in% rics_a ) ){

			# remove the file from memory (referred to in the character string `i`)
			rm( list = i )
			
			# clear up RAM
			gc()
		}
		
	}

	# # # # # # # # # # # # # # # # # # # # #
	# consolidated file creation starts now #

	# start with ricx
	x <- ricx
	
	# toss three fields that occur in multiple RICS and are generally useless
	# (keeping these would screw up the merge)
	x <- x[ , !( names( x ) %in% c( 'ric' , 'fileyr' , 'version' ) ) ]

	# # # # # # # # # # # # # # # # # # # # #
	# if pre-2001, change the weight names  #
	if ( year < 2001 ){
	
		# identify the prefix, for example: `c97`
		prefix <- paste0( 'c' , substr( year , 3 , 4 ) )
		
		# then substitute all variables with the 101 weight names used starting in 2001
		names( x )[ grep( prefix , names( x ) ) ] <- c( 'cs1yrwgt' , paste0( 'cs1yr' , str_pad( 1:100 , 3 , pad = '0' ) ) )
	}
	# # # # # # # # # # # # # # # # # # # # #
	
	# merge on all other `ric` files #
	
	x <- ric.merge( x , ric1 )

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	# create a ric2_ric2f file using the community and facility interview #
	
	# ric2 + ric2f need to be merged and then stacked,
	# to deal with earlier years where an individual might have had both interviews
	
	# remove extraneous columns at the get-go
	ric2 <- ric2[ , !( names( ric2 ) %in% c( 'ric' , 'fileyr' , 'version' ) ) ]
	ric2f <- ric2f[ , !( names( ric2f ) %in% c( 'ric' , 'fileyr' , 'version' ) ) ] 
	
	# baseid can be the only overlapping field #
	stopifnot( identical( 'baseid' , intersect( names( ric2 ) , names( ric2f ) ) ) )
	
	
	# merge these files, keeping only records where the baseid is in both files.
	if ( length( intersect( ric2$baseid , ric2f$baseid ) ) > 0 ) warning( paste( year , 'ric2 and 2f have overlapping benes, only keeping fac interviews' ) )
	
	# throw out overlappers from ric2
	ric2 <- ric2[ !( ric2$baseid %in% intersect( ric2$baseid , ric2f$baseid ) ) , ]
	
	# create a community vs. facility variable immediately
	ric2$community <- 1
	ric2f$community <- 0
	
	# stack these files one on top of the other,
	# even though their only shared column is baseid..
	ric2_ric2f <- rbind.fill( ric2 , ric2f )

	# end of ric2_ric2f file creation #
	# # # # # # # # # # # # # # # # # #

		
	x <- ric.merge( x , ric2_ric2f )
	
	
	# if `community` is missing, print a warning..
	if( any( is.na( x$community ) ) ) warning( "some records were not available in ric2 or ric2f for some reason?" )
	
	# ..and overwrite with community
	x[ is.na( x$community ) , 'community' ] <- 1
	
	
	# starting in 2001, the cost & use was released with a complete `RICA` file
	# however, before then, the `RICA` file was complete
	# and data users needed to wait for a later `RICA2` release
	if ( year < 2000 ) x <- ric.merge( x , rica2 ) else x <- ric.merge( x , rica )

	x <- ric.merge( x , rick )
	
	x <- ric.merge( x , ric4 )
	
	x <- ric.merge( x , ric5 )
	
	x <- ric.merge( x , ricps )

	# reshape ricss to be one record per person, instead of one record per event-type #
	
	# keep only valid event types #
	z <- ricss[ ricss$evnttype %in% c( 'DU' , 'FA' , 'HH' , 'HP' , 'IP' , 'IU' , 'MP' , 'OP' , 'PM' ) , ]
	# note: this does remove some expenditures without a valid `evnttype`
	
	# toss the useless fields, as usual.
	# unlike other RIC files, this must occur before `ric.merge` due to the `reshape` command
	z$ric <- z$fileyr <- NULL
	
	# the data.frame `z` had one record per `baseid` per `evnttype`
	# instead, create a file with one record per `baseid`
	y <- 
		reshape( 
			z , 
			idvar = 'baseid' , 
			timevar = 'evnttype' , 
			direction = 'wide' 
		)

	# rename the fields to the format [fieldname]_[eventtype]
	yn <- strsplit( names( y ) , '.' , fixed = TRUE )
	yn <- lapply( yn , rev )
	yn <- lapply( yn , paste , collapse = '_' )
	yn <- tolower( unlist( yn ) )
	names( y ) <- yn

	# merge the reshaped ss file onto the consolidated file
	x <- ric.merge( x , y )

	
	#########################
	# latest interview date #

	# if the interview date is stored as numeric,
	# it must be converted using the SAS start date
	if ( class( ric8$int_date ) == 'numeric' ){

		# find the maximum (latest) interview date
		z <- 
			with( 
				ric8 , 
				tapply( 
					int_date , 
					baseid , 
					max , 
					na.rm = TRUE 
				) 
			)
			
		# create a data.frame with one column of baseids
		# and a second column of everyone's latest interview date,
		# using the SAS origin day
		y <- 
			data.frame( 
			
				# tapply puts the `baseid` column in the names of that resultant list
				baseid = names( z ) ,
				
				# sas dates start on january 1st, 1960
				last_int_date = as.Date( z , origin = '1960-01-01' )
			)
			
	} else {

		# confirm all int_date fields are 8 digits.  otherwise there's a problem.
		stopifnot ( unique( nchar( ric8$int_date ) ) == 8 )

		# create a data.frame with one column of baseids
		# and a second column that just parses through the `int_date` character string
		# and instantly converts it to a date class
		ids.and.dates <-
			data.frame(
			
				baseid = ric8$baseid ,
			
				# ric8$int_date was structured YYYYMMDD
				# this int_date will be structured YYYY-MM-DD
				int_date = 
					as.Date(
						paste( 
							substr( ric8$int_date , 1 , 4 ) ,
							substr( ric8$int_date , 5 , 6 ) ,
							substr( ric8$int_date , 7 , 8 ) ,
							sep = "-"
						)
					)
					
			)
						
		# find the maximum, same as above
		z <- 
			with( 
				ids.and.dates , 
				tapply( 
					int_date , 
					baseid , 
					max , 
					na.rm = TRUE 
				) 
			)
		
		# create a final date data.frame, same as above
		y <- 
			data.frame( 
			
				# tapply puts the `baseid` column in the names of that resultant list
				baseid = names( z ) ,
				
				# these are now R-converted dates, so use 1970 as the origin
				last_int_date = as.Date( z , origin = '1970-01-01' )
			)

	}
		

	# tack on all final interview dates
	x <- ric.merge( x , y )

	# if the interview date is missing
	# (note: it will actually be `-Inf` when the `max` function was applied to only NA values) OR
	# if the interview date is after the end of the year..
	recode.rows <-
		( is.na( x$last_int_date ) ) |
		( x$last_int_date > as.Date( paste0( year , '-12-31' ) ) )
		
	# ..then make it december 31st of the data year
	x[ recode.rows , 'last_int_date' ] <- as.Date( paste0( year , '-12-31' ) )


	# end interview date #
	######################
	

	
	# # # # # # #
	# row check #
	
	# the ricx file should have the same number of records
	# as the final `x` object
	ricx.fn <- paste0( ff.directory , '/ricx.dat' )
	
	stopifnot( nrow( x ) == countLines( ricx.fn ) )
	
	# end of row check  #
	# # # # # # # # # # #
	
	# determine the full filepath of the .rda file to export
	output.fn <- 
		paste0( 
			output.directory , 
			'/cons' , 
			year , 
			'.rda' 
		)

	# add a column of all ones
	x$one <- 1
	
	# save the consolidated cost & use file for easy loading later
	save( x , file = output.fn )

	# if indicated by the user above,
	# also save the data.frame as a file that's easily imported into SAS
	# using the technique described in twotorials.com #052
	# http://www.screenr.com/DXd8
	if ( export.sas.file ){ 

		# determine the full filepath of the `.dat` and `.sas` files to export
		dfile <- paste0( output.directory , '/cons' , year , '.dat' )
		cfile <- paste0( output.directory , '/cons' , year , '.sas' )
		dname <- paste0( 'cons' , year )

		# save an SAS-readable ASCII file along with a SAS importation script
		# that will create a `.sas7bdat` file once you open it up in SAS
		write.foreign( x , datafile = dfile , codefile = cfile , package = 'SAS' , dataname = dname )
	}

	
	# remove the consolidated cost & use file from memory
	rm( x )
	
	# end of consolidated file creation #
	# # # # # # # # # # # # # # # # # # #

	
	# remove all individual RIC files from memory
	rm( list = rics_a )
	
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
