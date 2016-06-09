# analyze survey data for free (http://asdfree.com) with the r language
# national plan and provider enumeration system files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( encoding = "windows-1252" )			# # only macintosh and *nix users need this line
# library(downloader)
# setwd( "C:/My Directory/NPPES/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Plan%20and%20Provider%20Enumeration%20System/merge%20taxonomy%20ids.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


# this r script will merge the taxonomy id (specialty code) table available at:
# https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Plan%20and%20Provider%20Enumeration%20System/taxonomy%20id%20table.txt


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################################
# prior to running this analysis script, the national plan and provider enumeration system must be imported into a monet database   #
# on the local machine. you must run this:                                                                                          #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Plan%20and%20Provider%20Enumeration%20System/download%20and%20import.R  #
#####################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # are you on a non-windows system? # # #
if ( .Platform$OS.type != 'windows' ) print( 'non-windows users: read this block' )
# ibge's ftp site has a few SAS importation
# scripts in a non-standard format
# if so, before running this whole download program,
# you might need to run this line..
# options( encoding="windows-1252" )
# ..to turn on windows-style encoding.
# # # end of non-windows system edits.


# remove the # in order to run this install.packages line only once
# install.packages( "stringr" )


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NPPES/" )
# ..in order to set your current working directory


library(DBI)			# load the DBI package (implements the R-database coding)
library(stringr)		# load stringr package (manipulates character strings easily)
library(downloader)		# downloads and then runs the source() function on scripts from github


# create a temporary file on the local disk
tf <- tempfile()

# write the taxonomy id table to that temporary file
download( 
	"https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Plan%20and%20Provider%20Enumeration%20System/taxonomy%20id%20table.txt" ,
	tf
)

# read that taxonomy id table into R
z <- readLines( tf )

# search for tab characters on each line
hmt <- gregexpr( "\t" , z )
# since the gregexpr() function returns `-1` for non-matches..

# ..construct an in-line function that only counts non-negative hits

# for each line, count the number of '\t' matches
l <- 
	unlist( 
		lapply( 
			hmt , 
			function( x ) length( x[ x > 0 ] ) 
		) 
	)

# remove all tabs from the object `z`
z <- gsub( '\t' , '' , z )
	

# find the last dash in each string
ld <- lapply( gregexpr( "-" , z ) , max )

# replace all strings without dashes with their last character
ld[ ld < 0 ] <- nchar( z[ ld < 0 ] )

# coerce this list object of last-dash positions to a numeric vector
ld <- unlist( ld )

# for all lines in `z`, take the first character thru the last dash
pre <- substr( z , 1 , ld )

# if `pre` ends with a dash, trim it.
# first, determine elements where the last character is a dash..
ewd <- substr( pre , nchar( pre ) , nchar( pre ) ) == "-"

# ..then, for those records, take a substring up to the character before the last.
pre[ ewd ] <- 
	substr( 
		pre[ ewd ] , 
		1 , 
		nchar( pre[ ewd ] ) - 1 
	)

# remove whitespace on both sides of the string
pre <- str_trim( pre )
	
# for the post-dash portion of our show,
# just take the last dash plus one to the end of the string.
post <- substr( z , ld + 1 , nchar( z ) )

# remove whitespace here too
post <- str_trim( post )

# replace missing data ("") with NA
post[ post == "" ] <- NA

# create a data.frame object with three columns.
# the level (1, 2, or 3)
# the taxonomy id title
# the actual taxonomy id or code
w <-
	data.frame(
		level = l ,
		title = pre ,
		taxonomy.id = post
	)


# remove the top level (level zero)
w <- w[ w$level != 0 , ]


# set two current level variables to missing
curLevel.1 <- curLevel.2 <- NA


# cycle through every record in the taxonomy id table..
for ( i in seq( nrow( w ) ) ){

	# if the record is level one, store that in the curLevel.1 variable
	if ( w[ i , 'level' ] == 1 ) curLevel.1 <- w[ i , 'title' ]

	# if the record is level two, store that in the curLevel.2 variable
	# and also record the current level one
	if ( w[ i , 'level' ] == 2 ) {
		w[ i , 'level.one' ] <- curLevel.1
		curLevel.2 <- w[ i , 'title' ]
	}
	
	# if the record is level three, record both current levels one and two
	if ( w[ i , 'level' ] == 3 ) {
		w[ i , 'level.one' ] <- curLevel.1
		w[ i , 'level.two' ] <- curLevel.2
	}
	
}

# throw out missing taxonomy ids
w <- w[ !is.na( w$taxonomy.id ) , ]

# now the object `w` contains all taxonomy ids
# take a look at the top and bottom of this data.frame
head( w ) ; tail( w )


# after running the r script above, users should have handy a few lines
# to initiate and connect to the monet database containing the latest
# national plan and provider enumeration system table.  run them now.  mine look like this:


# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )

# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite::MonetDBLite() , dbfolder )
# from now on, the 'db' object will be used for r to connect with the monetdb server


# now R has connected to the MonetDB
# seen in the command below stored as the `db` object


# perform a simple count directly from the sql table
# stored inside the monet database on your hard disk
# (as opposed to RAM)
dbGetQuery( db , 'select count(*) from npi' )


# look at all tables in the monet database
dbListTables( db )
# note: `npi` is the only table that's not administrative
# all other tables shown here come standard with MonetDB

# look at all of the field names of the `npi` table
dbListFields( db , 'npi' )
# note: this is similar to running the names()
# function on an R data.frame object


# run a more complex sql SELECT query
# that extracts practice location state and
# the first (of many!) taxonomy id codes

# the results are saved into a new data.frame object `ftcbs`..

# define which columns to keep
vars.to.keep <-
	c(
		"healthcare_provider_taxonomy_code_1" ,
		"provider_business_practice_location_address_state_name"
	)

# pull an R data.frame object from the monet database
ftcbs <-
	dbGetQuery( 
		db , 
		paste( 
			'select' , 
			paste( vars.to.keep , collapse = "," ) ,
			'from npi'
		)
	)

# remove records missing their first taxonomy code
ftcbs <- ftcbs[ !( ftcbs$healthcare_provider_taxonomy_code_1 %in% '' ) & !is.na( ftcbs$healthcare_provider_taxonomy_code_1 ) , ]

# merge this first taxonomy code by state table
# with the `w` taxonomy code table
# into a new `v` data.frame object
v <- 
	merge( 
		ftcbs , 
		w , 
		by.x = 'healthcare_provider_taxonomy_code_1' , 
		by.y = 'taxonomy.id' ,
		all.x = TRUE
	)
	
# count..
nrow( subset( v , is.na( title ) ) )

# ..and then look at non-matching records (there are a few)
table( subset( v , is.na( title ) )$healthcare_provider_taxonomy_code_1 )


# look at the first six records
head( v )

# look at the last six records
tail( v )

# and hey, look at currently active providers in california
table( v[ v$provider_business_practice_location_address_state_name == 'CA' , 'title' ] , useNA = 'always' )
# neato.


# disconnect from the current monet database
dbDisconnect( db , shutdown = TRUE )

