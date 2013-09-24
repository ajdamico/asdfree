# analyze survey data for free (http://asdfree.com) with the r language
# national plan and provider enumeration system files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# batfile <- "C:/My Directory/NPPES/nppes.bat"
# source_url( "https://raw.github.com/ajdamico/usgsd/master/National%20Plan%20and%20Provider%20Enumeration%20System/merge%20taxonomy%20ids.R" , prompt = FALSE , echo = TRUE )
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


# this r script will merge the taxonomy id (specialty code) table available at:
# https://raw.github.com/ajdamico/usgsd/master/National%20Plan%20and%20Provider%20Enumeration%20System/taxonomy%20id%20table.txt


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###################################################################################################################################
# prior to running this analysis script, the national plan and provider enumeration system must be imported into a monet database #
# on the local machine. you must run this:                                                                                        #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/usgsd/master/National%20Plan%20and%20Provider%20Enumeration%20System/download%20and%20import.R  #
###################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # #
# warning: monetdb required #
# # # # # # # # # # # # # # #


# remove the # in order to run this install.packages line only once
# install.packages( c( "stringr" , "downloader" ) )


require(MonetDB.R)	# load the MonetDB.R package (connects r to a monet database)
require(stringr)	# load stringr package (manipulates character strings easily)
require(downloader)	# downloads and then runs the source() function on scripts from github


# create a temporary file on the local disk
tf <- tempfile()

# write the taxonomy id table to that temporary file
download( 
	"https://raw.github.com/ajdamico/usgsd/master/National%20Plan%20and%20Provider%20Enumeration%20System/taxonomy%20id%20table.txt" ,
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



####################################################################
# lines of code to hold on to for all other nppes monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/NPPES/nppes.bat"

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "nppes"
dbport <- 50006

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

# end of lines of code to hold on to for all other nppes monetdb analyses #
###########################################################################



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
ftcbs <- ftcbs[ ftcbs$healthcare_provider_taxonomy_code_1 != '' , ]

# merge this first taxonomy code by state table
# with the `w` taxonomy code table
# into a new `v` data.frame object
v <- 
	merge( 
		ftcbs , 
		w , 
		by.x = 'healthcare_provider_taxonomy_code_1' , 
		by.y = 'taxonomy.id' 
	)
	
# confirm that every record has exactly one match
stopifnot( nrow( ftcbs ) == nrow( v ) )


# look at the first six records
head( v )

# look at the last six records
tail( v )

# and hey, look at currently active providers in california
table( v[ v$provider_business_practice_location_address_state_name == 'CA' , 'title' ] , useNA = 'always' )
# neato.


###########################################################################
# end of lines of code to hold on to for all other nppes monetdb analyses #

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other nppes monetdb analyses #
###########################################################################

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
