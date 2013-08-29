# analyze survey data for free (http://asdfree.com) with the r language
# national longitudinal study of adolescent health
# waves 1 through 4, interviews 1994 - 2008

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/AddHealth/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/National%20Longitudinal%20Study%20of%20Adolescent%20Health/download%20and%20consolidate.R" , prompt = FALSE , echo = TRUE )
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


###########################################################################################################
# download every file from every year of the National Longitudinal Study on Adolescent Health with R then #
# create a consolidated file and save everything as an R data frame (.rda) for rapid  future analyses.    #
###########################################################################################################


# # # # # # # # # # # # # #
# important user warning! #
# # # # # # # # # # # # # #

# you *must* visit this university of michigan
# website and create a username and password
# before running this massive download automation program

# this is to protect both yourself and the respondents of the study
# http://www.icpsr.umich.edu/cgi-bin/bob/terms2?study=21600
# as a verification that you have actually read this document, you must uncomment
# (meaning remove the # in front of) the next line.  by uncommenting this line, you affirm you have read and agree with the document:

# terms <- "http://www.icpsr.umich.edu/cgi-bin/terms"

# this massive ftp download automation script will not work without the above line uncommented.
# if the 'terms' line above is still uncommented, the script is going to break.
# to repeat.  read the important user warning.  then uncomment that line to affirm you have read and agree with the document.
# finally, place your username and password in the new variables here:

# you're going to want to uncomment these as well.
# login <- "your@email.com"
# pw <- "password_here"
# just remove the `#` in front of those two lines,
# after you've entered your username and password, uhcourse.

# # # # # # # # # # # # # # # # # 
# end of important user warning #
# # # # # # # # # # # # # # # # #


# set your working directory.
# each year of the AddHealth will be stored in a year-specific folder here
# after downloading and importing it.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/AddHealth/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( "RCurl" )

# no need to edit anything below this line #


# # # # # # # # #
# program start #
# # # # # # # # #


require(foreign) 		# load foreign package (converts data files into R)
require(RCurl)			# load RCurl package (downloads https files)

# create a few vectors (one numeric, one list, one character) containing all of the data set information
# on the icpsr website.  each of these numbers correspond to a certain data set on the university of michigan's page.
# i got 'em from http://www.cpc.unc.edu/projects/addhealth/data/publicdata/public-use-dataset-descriptions

# wave of each data file
wave = c( 1 , 1 , 1 , 1 , 1 , 2 , 2 , 2 , 3 , 3 , 3 , 3 , 3 , 4 , 4 , 4 , 4 )

# data set number of each data file(s)
# note that this is a `list` class because multiple data set numbers need to be combined into a single data set
ds.number = list( 1 , 2 , 19 , 17 , 18 , 3 , 21 , 20 , 4:12 , 22 , 14 , 15 , 16 , 23:28 , 29 , 30 , 31 )

# data set names
filename = c( "Main" , "Grand Sample Weights" , "Contextual" , "School Weights" , "Network" , "Main" , "Grand Sample Weights" , "Contextual" , "In-Home Questionnaire" , "Grand Sample Weights" , "Education" , "Graduation" , "Education" , "Main" , "Grand Sample Weights" , "Biomarkers" , "Biomarkers" )


# webscraping setup #

# start a curl handle
curl = getCurlHandle()

# set a few preferences for that curl handle
curlSetOpt(
	cookiejar = 'cookies.txt' , 
	followlocation = TRUE , 
	autoreferer = TRUE , 
	curl = curl
)

# login to the icpsr umich website,
# using the login and password that you should've
# provided at the start of this script
login.page <- 
	postForm(
		"http://www.icpsr.umich.edu/ticketlogin" , 
		email = login ,
		password = pw ,
		path = "ICPSR" ,
		request_uri = "http://www.icpsr.umich.edu/cgi-bin/bob/terms2?study=21600&amp;ds=1&amp;bundle=stata&amp;path=ICPSR" ,
		style = "POST" ,
		curl = curl 
	)

# automatically agree to the university of michigan's
# terms and conditions for using this data.
# did you read the agreement?  great thanx
terms.of.use.page <- 
	postForm(
		terms , 
		agree = 'yes' ,
		path = "ICPSR" , 
		study = "21600" , 
		ds = "1" , 
		bundle = "stata" , 
		dups = "yes" ,
		style = "POST" ,
		curl = curl 
	)
# end of webscraping setup #
	
# create a temporary file
tf <- tempfile()

# initiate an empty object that will be filled later
all.downloaded.rdas <- NULL

# create a directory inside your current working directory
# that will contain the individual data sets for all of the files
# that you're about to download.
dir.create( "individual tables" )

# loop through every number in the `wave` object (created above)
for ( i in seq( length( wave ) ) ){

	# loop through every object in the current position in
	# the`ds.number` list (also created above).
	# note that *most but not all* of the elements of this list are singular
	# but a few of 'em have multiple objects, all of which need to be downloaded.
	for ( ds in ds.number[[i]] ){

		# print the current progress to the screen
		print( paste( "currently working on w" , wave[i] , '-' , filename[ i ] , '-' , ds ) )
	
		# design the full filepath of the stata data set to download
		fp <- paste0( "http://www.icpsr.umich.edu/cgi-bin/bob/zipcart2?path=ICPSR&study=21600&bundle=stata&ds=" , ds , "&dups=yes" )
	
		# download the current stata file into working memory
		file <- getBinaryURL( fp , curl = curl )

		# save the current downloaded file to the temporary file on the hard disk
		writeBin( file , tf )

		# unzip that file..
		all.files <- unzip( tf )
		
		# find the `.dta` within the zip
		stata.file <- all.files[ grep( ".dta" , all.files , fixed = TRUE ) ]

		# double-check that there's only one `.dta`
		if ( length( stata.file ) > 1 ) stop( "should only be one dta per zip" )
		
		# read the stata file into an R data.frame
		x <- read.dta( stata.file , convert.factors = FALSE )

		# convert all column names to lowercase
		names( x ) <- tolower( names( x ) )
		
		# identify the `.do` file from among the unzipped files
		do.file <- all.files[ grep( ".do" , all.files , fixed = TRUE ) ]

		# double-check yet again
		if ( length( do.file ) > 1 ) stop( "should only be one do file per zip" )
		
		# if and only if there's one `.do` file..
		if ( length( do.file ) == 1 ){
			
			# convert all characters to lowercase
			do.lines <- tolower( readLines( do.file ) )
			
			# identify all `replace` lines (a stata command)
			replace.lines <- do.lines[ substr( do.lines , 1 , 7 ) == "replace" ]
			
			# split each of those lines at the text `if `
			both.if.sides <- strsplit( replace.lines , "if " )
			
			# extract the text *after* (2) the `if `
			missing.conditions <- lapply( both.if.sides , "[[" , 2 )
			
			# extract the text *before* (1) the `if `
			vars.to.replace <- lapply( both.if.sides , "[[" , 1 )
			
			# remove the word `replace `
			vars.to.replace <- gsub( "replace " , "" , vars.to.replace )
			
			# remove the stata *set equal to missing* text
			vars.to.replace <- gsub( " = . " , "" , vars.to.replace , fixed = TRUE )
			
			# loop through each variable to replace..
			for ( j in seq( length( vars.to.replace ) ) ){
			
				# find the logical conditions that merit conversion to missings
				replacement.condition <- missing.conditions[[j]]
				
				# extract the current variable (column) name
				curvar <- vars.to.replace[j]
				
				# extract the stata rows that ought to be replaced into a new object `z`
				z <- rownames( subset( x , eval( parse( text = replacement.condition ) ) ) )
				
				# and wherever the `x` data.frame matches one of those values,
				# set the current variable to missing.
				x[ rownames( x ) %in% z , curvar ] <- NA
				
			}
		}
			
		
		# figure out the appropriate name for the R data file (.rda) on the local disk
		savename <- paste0( './individual tables/wave ' , wave[i] , ' - ' , filename[ i ] , ' - ' , ds , '.rda' )
		
		# save the object `x`
		save( x , file = savename )

		# add that `.rda` to the character vector of all downloaded rda files
		all.downloaded.rdas <- c( all.downloaded.rdas , savename )
		
		# remove the objects `x` and `file` from working memory
		rm( x , file )
		
		# clear up RAM
		gc()
		
		# remove all unzipped files from the local disk
		unlink( all.files , recursive = TRUE )
		
	}
}


# loop through each of the available interview waves..
for ( curWave in unique( wave ) ){

	# extract the `.rda` files available for that wave
	rda.files.to.merge.this.wave <- all.downloaded.rdas[ grepl( paste( 'wave' , curWave ), all.downloaded.rdas ) ]

	# create an empty `cons` object
	cons <- NULL	
	
	# loop through each of the appropriate `.rda` files
	for ( cur.rda in rda.files.to.merge.this.wave ){
	
		# load it into RAM
		load( cur.rda )
		
		# confirm the file must be one-record-per-unique ID
		if ( length( unique( x$aid ) ) == nrow( x ) ){
		
			# print current progress to the screen
			print( paste( "currently merging" , cur.rda , "from wave" , curWave ) )
	
			# if it's the Main file, throw out the cluster2 variable
			# since the weights file has it with the appropriate number of decimals
			if ( grepl( 'Main' , cur.rda ) ) x$cluster2 <- NULL
	
			# if the `cons` object is missing..
			if ( is.null( cons ) ){
				
				# it's the first data.frame to be included in the consolidated file
				cons <- x
			
			# otherwise
			} else {
			
				# copy over what's already in the `cons` object
				pre.cons <- cons
				
				# if the unique identifier is available,
				# don't also merge on caseid.
				if ( 'aid' %in% names( cons ) ) cons$caseid <- NULL
				
				# print what you're doing, just to keep everyone abreast of current inner-workings.
				print( paste( "merging with" , intersect( names( x ) , names( cons ) ) , collapse = " and " ) )
				
				# merge the current .rda with what's already in `cons`,
				# keeping matching records in *either* data set
				cons <- merge( cons , x , all = TRUE )
				
			}
			
			# make sure the many-to-one merge hasn't gone apeshit.
			# none of these should have more than ten thousand records ever
			stopifnot( nrow( cons ) < 10000 )
			
		} else {
		
			# otherwise no merge..
			print( paste( "did not merge" , cur.rda , " -- copying to working directory" ) )
			
			# just save the data.frame object into the main output folder
			save( x , file = gsub( "/individual tables" , "" , cur.rda ) )
		}
		
		# remove the current data.frame from working memory
		rm( x )
		
		# clear up RAM
		gc()
	}
	
	# once you've merged as many files as you can,
	# save the final `cons` object to the local disk
	save( cons , file = paste0( 'wave ' , curWave , ' consolidated.rda' ) )
	
	# remove the `cons` object from working memory
	rm( cons )
	
	# once again, clear up RAM
	gc()
}

# the current working directory should now contain one consolidated file
# *plus* all tables that were not one-record-per-id for each wave


# once complete, this script does not need to be run again.
# instead, use one of the analysis scripts,
# which utilize these newly-created R data files (.rda)


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
