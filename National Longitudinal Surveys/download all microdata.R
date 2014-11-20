# analyze survey data for free (http://asdfree.com) with the r language
# national longitudinal surveys
# nlsy97, nlsy79, nlsy79cya, older men, mature women, young men, young women

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NLS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/usgsd/master/National%20Longitudinal%20Surveys/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
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


###################################################################################
# download every file from every available national longitudinal survey study     #
# with R, saving each extract as an R data frame (.rda) for rapid future analyses #
###################################################################################


# set your working directory.
# all NLS studies will be stored here after downloading.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NLS/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( c( "httr" , "XML" , "stringr" ) )


library(httr)		# load httr package (downloads files from the web, with SSL and cookies)
library(XML)		# load XML (parses through html code to extract links)
library(stringr)	# load stringr package (manipulates character strings easily)
library(downloader)	# downloads and then runs the source() function on scripts from github


# log on to the nlsinfo investigator and pull all available studies
studies <- GET( "https://www.nlsinfo.org/investigator/servlet1?get=STUDIES" )

# extract the study names option
study.names <- xpathSApply( content( studies ) , "//option" , xmlAttrs )

# remove the negative one, which is the default but not its own study
study.names <- study.names[ study.names != '-1' ]


# available studies
print( studies )

# text names of each study available
print( study.names )


# this next section is optional
# but given the pace of the downloads from
# nlsinfo.org, you might wish to only download
# a subset of the available cohorts
# instead of all seven

# # # # # # # # # # # # # # # # # # # # # # # # # # #
# limit the download to a subset of the nls cohorts #
# # # # # # # # # # # # # # # # # # # # # # # # # # #

# note: the various cohorts shown on
# https://www.nlsinfo.org/investigator/pages/login.jsp

# to only download the 1997 cohort, remove the `#` in this next line
# only.study <- "NLSY97"

# to download the 1979 and 1979 child and young adult cohorts, remove the `#` in this next line
# only.study <- c( "NLSCYA" , "NLSY79" )

# to download the two original cohorts, remove the `#` in this next line
# only.study <- c( "NLSW" , "NLSM" )


# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #

# look for an object "only.study" and if it exists,
# limit the studies downloaded to the ones specified
if( exists( 'only.study' ) ) study.names <- study.names[ study.names %in% only.study ]


# initiate a temporary file and temporary directory
tf <- tempfile() ; td <- tempdir()


# loop through all designated studies
for ( this.study in study.names ){

	# determine all available substudies within the selected studies
	substudies <- 
		GET( 
			paste0( 
				"https://www.nlsinfo.org/investigator/servlet1?get=SUBSTUDIES&study=" , 
				this.study 
			) 
		)
	
	# extract the option tags from the substudies page
	substudy.numbers <- xpathSApply( content( substudies ) , "//option" , xmlAttrs )
	
	# also extract the values contained within those tags
	substudy.names <- xpathSApply( content( substudies ) , "//option" , xmlValue )
	
	# convert that list into a vector
	substudy.numbers <- unlist( substudy.numbers )
	
	# limit the substudies to only actual values, not dropdown list identifiers
	substudy.numbers <- substudy.numbers[ names( substudy.numbers ) == 'value' ]
	
	# just like the overall study names, remove the default negative one selection
	# from both names..
	substudy.names <- substudy.names[ substudy.numbers != "-1" ]
	# ..and numbers
	substudy.numbers <- substudy.numbers[ substudy.numbers != "-1" ]
	
	# remove leading and trailing spaces from the substudy names
	substudy.names <- str_trim( substudy.names )
	
	# loop through each available substudy
	for ( study.id in substudy.numbers ){
	
		# identify a substudy-specific working directory..
		this.dir <- paste0( getwd() , "/" , substudy.names[ study.id == substudy.numbers ] )
		
		# ..and actually create it.  this is where all data extracts will be stored
		dir.create( this.dir , showWarnings = FALSE , recursive = TRUE )


		# download the strata and psu for studies where they're available
		if( study.id == "1.6" ){
		
			# download the nlsy 1997 cohort's sampling information
			download( "https://www.nlsinfo.org/sites/nlsinfo.org/files/attachments/140618/nlsy97stratumpsu.zip" , tf , mode = 'wb' )
			
			# unzip to the local disk
			z <- unzip( tf , exdir = td )

			strpsu <- read.csv( z[ grep( '\\.csv' , z ) ] )
			
			# store the complex sample variables on the local disk
			save( strpsu , file = paste0( this.dir , "/strpsu.rda" ) )
			
			# clear up all the bigger objects from working memory
			rm( strpsu )
			
			# clear up RAM
			gc()
		
		}


		# set the nls investigator to allow downloads for this substudy
		GET( paste0( "https://www.nlsinfo.org/investigator/servlet1?set=STUDY&id=" , study.id ) )

		# identify all possible extract files for downloading
		z <- GET( "https://www.nlsinfo.org/investigator/servlet1?get=SEARCHVALUES&type=RNUM" )

		# convert this rnum html result into an xml-readable object
		doc <- htmlParse( z )
		
		# extract all options from this xml text
		opts <- getNodeSet( doc , "//select/option" )
		
		# extract all rnum values from within the xml
		all.option.values <- sapply( opts , xmlGetAttr , "value" )
		
		# remove any negative ones, since those are not rnums themselves
		all.option.values <- all.option.values[ all.option.values != "-1" ]

		# loop through each available rnum extract
		for ( option.value in all.option.values ){

			# initiate a counter
			attempt.count <- 0
			
			# start off the `attempt` object as an error.
			attempt <- try( stop() , silent = TRUE )
			# this is only useful at the start of this next `while` command
			
			# so long as the `attempt` object is an error..
			while( class( attempt ) == 'try-error' ){
				
				# add one to the counter
				attempt.count <- attempt.count + 1
			
				# display any actual errors for the user
				if ( attempt.count > 1 ) print( attempt )
			
				# after the fifth attempt, shut down the program.
				if ( attempt.count > 5 ) stop( "tried five times with no luck.  peace out." )
			
				# overwrite the `attempt` object with the result of..
				attempt <-
					try( {
						
						# re-set the nls investigator to download only the default-included variables
						GET( paste0( "https://www.nlsinfo.org/investigator/servlet1?set=STUDY&id=" , study.id , "&reset=true" ) )

						# print current progress to the screen
						print( 
							paste( 
								"currently downloading extract" , 
								which( option.value == all.option.values ) ,
								"of" ,
								length( all.option.values ) ,
								"extract" ,
								option.value , 
								"attempt" , 
								attempt.count 
							) 
						)

						# initiate the server for downloads
						GET( "https://www.nlsinfo.org/investigator/servlet1?set=preference&pref=all" )

						# specify the rnum extract to download
						GET( paste0( "https://www.nlsinfo.org/investigator/servlet1?get=Results&xml=true&criteria=RNUM%7CSW%7C" , option.value , "&sortKey=RNUM&sortOrder=ascending&&PUBID=noid&limit=all" ) )

						# rather than downloading only recommended variables, download all of 'em
						GET( "https://www.nlsinfo.org/investigator/servlet1?set=tagset&select=all&value=true" )

						# specify that only the csv file should be downloaded
						job.char <- GET( "https://www.nlsinfo.org/investigator/servlet1?collection=on&sas=off&spss=off&stata=off&codebook=on&csv=on&event=start&cmd=extract&desc=default" )

						# extract the specific job id from the above result
						job.id <- gsub( 'job:' , '' , as.character( job.char ) )

						# trigger the creation of the extract
						GET( "https://www.nlsinfo.org/investigator/servlet1?get=downloads&study=current" )

						# start out with a blank string
						v <- ""
						
						# so long as the `v` string does not contain this response text..
						while( !( grepl( "{\"status_response\":{\"message\":\"\",\"name\"" , as.character( v ) , fixed = TRUE ) ) ){
							
							# ping the server to determine the current progress of the creation of the current extract
							v <- GET( paste0( "https://www.nlsinfo.org/investigator/servlet1?job=" , job.id , "&event=progress&cmd=extract&_=" , as.numeric( Sys.time() ) * 1000 ) )
						
							# if the download hits an error, break out of the current loop.
							ep <- FALSE
							
							# see if the current page contains an error page text, instead of actual data.
							try( ep <- xpathSApply( htmlParse( v , asText = TRUE ) , '//title' , xmlValue ) == 'Error Page' , silent = TRUE )
							
							# if it does contain an error page, break the program inside this current try loop
							if( ( length( ep ) > 0 ) && ( ep ) ) stop( "Error Page" )
							# first successful usage of `&&` operator.  pat on the back.
						
							# extract the current contents of the `v` object to determine the current progress
							msg <- strsplit( strsplit( as.character(v) , 'message\":\"' )[[1]][2] , '\",\"name' )[[1]][1]
							
							# print that progress to the screen
							cat( "    " , msg , "\r" )
							
							# give the progress bar fifteen seconds before it
							# refreshes so it's not overloading the website
							Sys.sleep( 15 )
							
						}
						# once the extract creation has been completed
						
						# initiate an empty `u` object..
						u <- NULL
						
						# ..with a failed-error code
						u$headers$status <- 500

						# initiate a timer
						start.time <- Sys.time()
						
						# so long as the status code returns unfinished
						while( !is.null( u$headers$status ) && u$headers$status == 500 ){

							# if you've been waiting more than two minutes, just stop.
							if ( Sys.time() - start.time > 120 ) stop( 'waited two minutes after extract created, still no download' )
						
							# download the zipped file for this specific job id
							u <- GET( paste0( "https://www.nlsinfo.org/investigator/downloads/" , job.id , "/default.zip" ) )
							
						}

						# save that result zipped file into the temporary file on your local disk
						writeBin( content( u , "raw" ) , tf )
						
						# unzip that temporary file into the temporary directory on your local disk
						d <- unzip( tf , exdir = td )

						# determine the location of the `.csv` file within the zipped file you've just unarchived
						csv <- d[ grep( '.csv' , d , fixed = TRUE ) ]

						# save that zipped file as a data.frame named as the current `option.value`
						assign( option.value , read.csv( csv ) )

						# store that `option.value` in the current save-location
						save( list = option.value , file = paste0( this.dir , "/" , option.value , ".rda" ) )
						
						# clear up all the bigger objects from working memory
						rm( list = c( 'u' , option.value ) )
						
						# clear up RAM
						gc()
						
					} , 
					silent = TRUE 
				)
				
				# wait the same number of minutes as you have attempted-counted,
				# but after the last attempt, don't wait at all.
				if( class( attempt ) == 'try-error' ) Sys.sleep( 60 * ifelse( attempt.count >= 5 , 0 , attempt.count ) ) else Sys.sleep( 15 )
					
			}
				
		}

	}
}

# remove the temporary file..
file.remove( tf )

# ..and temporary directory from your hard drive
unlink( d , recursive = TRUE )


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
