# analyze survey data for free (http://asdfree.com) with the r language
# national survey on drug use and health
# 1979 through 2011
# all available files (including documentation)

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


############################################################################################
# download every file from every year of the National Survey on Drug Use and Health with R #
# then save every file as an R data frame (.rda) so future analyses can be rapid           #
############################################################################################


# # # # # # # # # # # # # #
# important user warning! #
# # # # # # # # # # # # # #

# you *must* visit this us government
# substance abuse and mental health services administration (samhsa)
# website and click 'agree' before running this massive download automation program

# this is to protect both yourself and the respondents of the study
# http://www.icpsr.umich.edu/cgi-bin/bob/zipcart2?path=SAMHDA&study=32722
# as a verification that you have actually read this document, you must uncomment
# (meaning remove the # in front of) the next line.  by uncommenting this line, you affirm you have read and agree with the document:

# terms <- "http://www.icpsr.umich.edu/cgi-bin/terms"

# this massive ftp download automation script will not work without the above line uncommented.
# if the 'terms' line above is still uncommented, the script is going to break.
# to repeat.  read the important user warning.  then uncomment that line to affirm you have read and agree with the document.


# # # # # # # # # # # # # # # # # 
# end of important user warning #
# # # # # # # # # # # # # # # # #


# set your working directory.
# each year of the NSDUH will be stored in a year-specific folder here
# after downloading and importing it.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NSDUH/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( c( "SAScii" , "httr" , "stringr" ) )

# no need to edit anything below this line #


# # # # # # # # #
# program start #
# # # # # # # # #


require(httr)		# load httr package (downloads files from the web, with SSL and cookies)
require(SAScii) 	# load the SAScii package (imports ascii data with a SAS script)
require(foreign) 	# load foreign package (converts data files into R)
require(stringr) 	# load stringr package (manipulates character strings easily)


# create a temporary file
tf <- tempfile()


# initiate the no.na() function
# this function replaces NA (missing) observations with whatever's in the 'value' parameter
no.na <-
    function( x , value = FALSE ){
        x[ is.na( x ) ] <- value
        x
    }

# create a studies.by.year data frame that contains all of the years of data available,
# as well as the substance abuse and mental health data (samhda) identification number (used in the downloading pattern)
studies.by.year <-
	data.frame(
	
		# the first column in this new data frame contains each available year
		# (notice some years are not available)
		year = c( 1979 , 1982 , 1985 , 1988, 1990:2011 ) ,
		
		# the second column contains the samhda id
		id = c( 
			# 1979 - 1992
			6843 , 6845 , 6844 , 9522 , 9833 , 6128 , 6887 ,
			# 1993 - 1999
			6852 , 6949 , 6950 , 2391 , 2755 , 2934 , 3239 ,
			# 2000 - 2006
			3262 , 3580 , 3903 , 4138 , 4373 , 4596 , 21240 ,
			# 2007 - 2011
			23782 , 26701 , 29621 , 32722 , 34481
		)
	)

# set the filepath of the actual web/cgi program to download
download <- "http://www.icpsr.umich.edu/cgi-bin/bob/zipcart2"

# loop through each year of nsduh data available, starting with the most current first
# the rev() function reverses the order, so instead of starting with the 1979 and finishing with 2010,
# the program downloads 2010 first and then works backward.
for ( i in rev( seq( nrow( studies.by.year ) ) ) ){
	
	# create a new object storing an atomic character string with only the study id
	id <- as.character( studies.by.year[ i , "id" ] )
	# create a new object containing the current year
	year <- studies.by.year[ i , 'year' ]

	# the file names use five digits, so add a leading zero when id has four digits
	id5 <- str_pad( id , 5 , pad = '0' )
	
	# print the current file year to the screen
	cat( "  current progress: preparing the nsduh" , year , "file                    " , "\r" )
	
	# create a list object containing all components necessary to inform the web/cgi program
	# what file to actually download at any given query.  notice only the 'id' object varies between loops
	values <- 
		list(
			agree = "yes" , 
			path = "SAMHDA" , 
			study = id , 
			ds = "" , 
			bundle = "stata" , 
			dups = "yes"
		)

	# accept the terms on the form, 
	# generating the appropriate cookies
	POST(terms, body = values)

	# set up guest credentials OR download the file,
	# if GET() has already been run during this instance of R,
	# this line will download the file straight away.
	# otherwise, it will simply log in and need to be run again
	resp <- GET(download, query = values)

	# if the above GET() only logged in but did not download the file
	if ( length( resp ) == 8 ){

		# actually download the file (this will take a while)
		resp <- GET(download, query = values)

	}

	# write the content of the download to a binary temporary file
	writeBin( content( resp , "raw" ) , tf )

	# unzip the contents of the stata file into the current working directory
	unzip( tf )

	# remove the temporary file
	file.remove( tf )

	# current unzip directory
	unzip.dir <- paste0( getwd() , "/ICPSR_" , id5 )

	# current year directory
	year.dir <- paste0( getwd() , "/" , year )

	# rename the file directory to the current year
	file.rename( unzip.dir , year.dir )

	# set the path to stata file
	path.to.dta <- paste0( getwd() , "/" , year , "/DS0001/" , id5 , "-0001-Data.dta" )

	# read in the stata file
	x <- read.dta( path.to.dta , convert.factors = FALSE )

	# path to the supplemental recodes file
	path.to.supp <- paste0( getwd() , "/" , year , "/DS0001/" , id5 , "-0001-Supplemental_syntax.do" )

	# read the supplemental recodes lines into R
	commented.supp.syntax <- readLines( path.to.supp )

	# and remove any stata comments
	uncommented.supp.syntax <- SAS.uncomment( commented.supp.syntax , "/*" , "*/" )

	# remove blank lines
	supp.syntax <- uncommented.supp.syntax[ uncommented.supp.syntax != "" ]

	# confirm all remaining recode lines contain the word 'replace'
	# right now, the supplemental recodes are relatively straightforward.
	# should any of them contain non-'replace' syntax, this part of this
	# R script will require more flexibility
	stopifnot( 
		length( supp.syntax ) == 
		sum( unlist( lapply( "replace" , grepl , supp.syntax ) ) )
	)

	# figure out exactly how many recodes will need to be processed
	# (this variable will be used for the progress monitor that prints to the screen)
	how.many.recodes <- length( supp.syntax )
	
	# loop through the entire stata supplemental recodes file
	for ( j in seq( supp.syntax ) ){

		# add a screen counter to show how many supplemental recodes have been performed so far
		cat( "  current progress: supplemental recode" , j , "of" , how.many.recodes , "on the nsduh" , year , "file                " , "\r" )

		# isolate the current stata "replace .. if .." command
		current.replacement <- supp.syntax[ j ]
		
		# locate the name of the current variable to be overwritten
		space.positions <- 
			gregexpr( 
				" " , 
				current.replacement 
			)[[1]]
		
		variable <- substr( current.replacement , space.positions[1] + 1 , space.positions[2] - 1 )
		
		# figure out the logical test contained after the stata 'if' parameter
		condition.to.blank <- unlist( strsplit( current.replacement , " if " ) )[2]
		
		# add an x$ to indicate which data frame to alter in R
		condition.test <- gsub( variable , paste0( "x$" , variable ) , condition.to.blank )
		
		# build the entire recode line, with a "<- NA" to overwrite
		# each of these codes with missing values
		recode.line <- 
			paste0( 
				"x[ no.na( " , 
				condition.test ,
				") , '" ,
				variable ,
				"' ] <- NA"
			)
			
		# uncomment this to print the current recode to the screen
		# print( recode.line )
		
		# execute the actual recode
		eval( parse( text = recode.line ) )
		
	}


	# convert all column names to lowercase
	names( x ) <- tolower( names( x ) )

	# determine the name of the R object (data.frame) to save the final table as..
	# NSDUH.YY.df
	df.name <- paste( "NSDUH" , substr( year , 3 , 4 ) , "df" , sep = "." )

	# save the R data frame to that file-specific name
	assign( df.name , x )
		
	# save the R data frame to a .rda file on the local computer
	save( list = df.name , file = paste0( getwd() , "/" , year , "/" , gsub( "df" , "rda" , df.name ) ) )

	# remove both x and the renamed, saved data frame
	rm( x )
	rm( list = df.name )

	# clear up RAM
	gc()

}


# the current working directory should now contain one folder per year of data,
# each with an R data file (.rda) in the main directory,
# as well as the original files downloaded from samhsa (including the survey documentation)


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
