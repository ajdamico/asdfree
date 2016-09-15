# analyze survey data for free (http://asdfree.com) with the r language
# health services and resources administration (hrsa)
# health professional shortage areas (hpsa) file
# identify (currently- or previously-designated) point-in-time geographic hpsas

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/HPSA/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Health%20Professional%20Shortage%20Areas/identify%20point-in-time%20geographic%20hpsas.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###############################################################################################################################
# prior to running this analysis script, the most current primary care physician health professional shortage area file must  #
# be loaded on the local machine. running the download current hpsa table script will create an r data file (.rda) with this. #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/asdfree/blob/master/Health%20Professional%20Shortage%20Areas/download%20current%20hpsa%20table.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create "HPSA_PC.rda" in C:/My Directory/HPSA or wherever the working directory was set for the program     #
###############################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



############################################################################
# isolate the currently- or previously-designated primary care physician   #
# Health Professional Shortage Area (HPSA), then save all geographic files #
############################################################################


# x # x # x # x #
# critical note: 
# the starting table `x` and then the final tables `county` `ctract` and `mcd` all contain one-record-per-geography
# as opposed to one-record-per-hpsa.  these tables actually contain multiple records per hpsa.

# in order to match the nationwide published statistics, use the one-record-per-hpsa tables constructed
# inside the `replicate hrsa nationwide statistics.R` script.

# however, to merge hpsa data up with specific geographies and locations, you'll need to use the one-record-per-geography tables
# because, for example, a single hpsa designation might span multiple counties or contain multiple census tracts
# thanks for playing
# end of critical note, really hope ya read it.
# x # x # x # x #


# set your working directory.
# all HPSA files will be stored here
# after downloading and importing it.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/HPSA/" )
# ..in order to set your current working directory




# remove the # in order to run this install.packages line only once
# install.packages( "stringr" )


library(stringr) # load stringr package (manipulates character strings easily)


# load the primary care physician HPSA file
# and immediately save it as a new object `x`
load( "HPSA_PC.rda" ) ; x <- PC

# note: this identification process could also be quickly run
# on the dental care or mental health hpsas by uncommenting
# one of these lines instead:
# load( "HPSA_DC.rda" ) ; x <- DC
# load( "HPSA_MH.rda" ) ; x <- MH


# define a function that simply replaces missings with FALSE values
no.na <-
	function( x , value = FALSE ){
		x[ is.na( x ) ] <- value
		x
	}


# remove hpsa records that are not designated for the time period you are interested in #

# print a table of counts of the
# currently available hpsa statuses
table( x$status.description )


# do you simply want hpsas that are *currently* designated as of the most recent file?
just.currently.designated.hpsas.please <- TRUE

# if so..
if ( just.currently.designated.hpsas.please ){

	# only keep hpsas with a *current* legal hpsa status
	x <- x[ x$status.description %in% c( 'Designated' , 'Proposed Withdrawal' , 'No Data Provided' ) , ]
	# as stated on page four, footone (1) of
	# http://ersrs.hrsa.gov/ReportServer/Pages/ReportViewer.aspx?/HGDW_Reports/BCD_HPSA/BCD_HPSA_SCR50_Smry&rs:Format=HTML4.0
		
# ..otherwise, it's a bit more work.  and also imperfect.
} else {

	# convert the designation.date field to a date field..
	x$dd <- strptime( x$designation.date , "%m/%d/%Y %H:%M:%S" )
	# ..and the date of the last update of the designation to another date field
	x$ud <- strptime( x$designation.last.update.date , "%m/%d/%Y %H:%M:%S" )

	# create a date object that contains the exact point in time you want the hpsa
	# to have been designated at.  here's july 1st, 2000
	designated.time.point <- strptime( "07/01/2000 00:00:00" , "%m/%d/%Y %H:%M:%S" )


	# now throw out records that were *not* designated as hpsas during that time.
	
	# if the hpsa was first designated *after* the user-defined time point, throw it out.
	x <- x[ !( x$dd > designated.time.point ) , ]
	
	# if the hpsa was updated to 'withdrawn' *before* the user-defined time point, throw it out
	x <- x[ !( no.na( x$ud < designated.time.point ) & x$status.description == 'Withdrawn' ) , ]

	# if the hpsa was immediately designated as 'withdrawn' before the designation date *and* has not been updated, throw it out
	x <- x[ !( no.na( x$dd < designated.time.point ) & is.na( x$ud ) & ( x$status.description == 'Withdrawn' ) ) , ]
	
	# remove the fields added to `x`
	x$ud <- x$dd <- NULL
	
}

# end of hpsa designation date-based elimination #


# territory elimination #

# print the current count of records by state
table( x$state.abbreviation )

# remove puerto rico, other territories, and all records missing state fips codes
x <- x[ as.numeric( x$state.fips.code ) %in% 1:56 , ]
# comment this line out to leave those records in the data.

# re-print the current count of records by state
table( x$state.abbreviation )

# end of territory elimination #


# hpsa type elimination #

# print the current count of records by state
table( x$type.description )

# remove hpsa records that are *points* (like health centers, clinics, correctional facilities, etc)
# and keep only geographic areas
x <- x[ x$type.description %in% c( 'Hpsa Geographic' , 'Hpsa Geographic High Needs' , 'Hpsa Population' ) , ]

# re-print the current count of records by state
table( x$type.description )

# end of territory elimination #




# do you simply want hpsas that are only *population groups* (as opposed to geographic area hpsas) thrown out?
throw.out.pop.group.hpsas.please <- FALSE

# if so..
if ( throw.out.pop.group.hpsas.please ){

	# only keep single county and geographical area hpsa types
	x <- x[ x$type.description %in% c( 'Hpsa Geographic' , 'Hpsa Geographic High Needs' ) , ]

# ..otherwise, it's a bit more work.  and also imperfect.
} else {

	###################################
	# population group identification #

	# look at the first fifty rows' `name` field
	head( x$name , 50 )

	# create a number of character vectors used to match this field to identify population groups
	
	spanish.text.matches <-
		c( 
			'span.spkng' , 'mono hispanic' , 'non-english speaking' , 'non-engl spk' ,
			'hisp. population' , 'hispanic pop' , 'spanish population' ,
			'span sp' , 'spanish sp'
		)
		
	poverty.text.matches <-
		c( 'pov. pop' , 'pov pop' , 'poverty' )
		
	li.text.matches <-
		c( 
			'low icome' , 'lwo inc' , 'low  inc' , 'low inc/' ,
			'low inc' , 'low-inc' , 'li-' , 'li -' , 'low in' , 'li/homeless' ,
			'li/mfw/homeless' , 'li/mfw' , 'low - inc/mfw'
		)
		
	medicaid.text.matches <-
		c( 'medicaid' , 'med elig.' , 'medi-cal' )
		
	indigent.text.matches <-
		c( 'indigent' , 'med ind' , 'med. ind.' , 'medically indigent' , 'ind. population' , 'medical ind' )
		
	amerind.text.matches <-
		c(
			'nat am' , 'tribe' , 'indian' , 'huron potawatomi' , 'am ind -' , 'navajo ind' , 'reservation' ,
			'native alaskan' , 'indian community' , 'amercian indian' , 'american indian' , 'nat amer' ,
			'am indian' , 'indian nation' , 'indian population' , 'umpqua indians' , 'am ind -' , 'nat amer' , 
			'indian colony' , 'indian res' , 'indian tribe' , 'native am' , 'paiute indian' , 'am. ind.' ,
			'am in -' , 'amer ind' , 'nam amer' , 'dent ind -' , 'dent. ind'
		)


	# create a new function to identify population groups
	pop.group.id <-
		function( text.matches , hpsa.names ){
		
			# take the character vector of text strings to match in the list of hpsa names..
			z <- sapply( text.matches , grepl , hpsa.names , ignore.case = TRUE )
			# ..and if a record in the 'hpsa.names' object matches *any* of strings in the text.matches vector

			# ..then return true.  otherwise, return false..
			
			# ..and return a logical vector of the same length as hpsa.names
			apply( z , 1 , any )
		}

		
	# identify the records in `x` that are population groups
	pg.recs <- ( x$type.description == 'Hpsa Population' )

	# create new TRUE/FALSE variables for each 
	x[ pg.recs , 'spanish' ] <- pop.group.id( spanish.text.matches , x[ pg.recs , 'name' ] )
	x[ pg.recs , 'poverty' ] <- pop.group.id( poverty.text.matches , x[ pg.recs , 'name' ] )
	x[ pg.recs , 'li' ] <- pop.group.id( li.text.matches , x[ pg.recs , 'name' ] )
	x[ pg.recs , 'medicaid' ] <- pop.group.id( medicaid.text.matches , x[ pg.recs , 'name' ] )
	x[ pg.recs , 'indigent' ] <- pop.group.id( indigent.text.matches , x[ pg.recs , 'name' ] )
	x[ pg.recs , 'amerind' ] <- pop.group.id( amerind.text.matches , x[ pg.recs , 'name' ] )
	x[ pg.recs , 'migrant' ] <- pop.group.id( 'migrant' , x[ pg.recs , 'name' ] )
	x[ pg.recs , 'inmate' ] <- pop.group.id( c( 'correctional' , 'inmate' ) , x[ pg.recs , 'name' ] )
	x[ pg.recs , 'homeless' ] <- pop.group.id( 'homeless' , x[ pg.recs , 'name' ] )
	x[ pg.recs , 'mental' ] <- pop.group.id( 'mental' , x[ pg.recs , 'name' ] )	

	# now all population group hpsas have flags for each of these categories.
	# note:
	# geographic area (non-population group) hpsas have NA for each flag
	
	# some population group hpsas do not have any flags..
	pg.hpsas.wo.flags <- 
		subset( 
			x , 
			!spanish & !poverty & !li & !medicaid & !indigent & !amerind & !migrant & !inmate & !homeless & !mental & 
			type.description == 'Hpsa Population' 
		)
	
	# ..here's the first six
	head( pg.hpsas.wo.flags )

	# ..and here's their `name` field,
	# which either doesn't specify a population group
	# or specifies a very small share of the population
	table( pg.hpsas.wo.flags$name )
	
	# end of population group identification #
	##########################################
}


# clean up the file.. trim the geographic ids
x$geography.id <- str_trim( x$geography.id )


# # # # # # # # # # # # # # # # #
# isolate whole county matches! #

# any geographic id with exactly five characters is a whole-county hpsa
county <- subset( x , nchar( geography.id ) == 5 )


# NOTE: this `county` table can now be merged onto other county-level data sets
# by using the `state.county.fips.code` column by itself.


# remove those records from `x`
x <- subset( x , nchar( geography.id ) != 5 )

# end of whole county isolation #


# # # # # # # # # # # # # # # # #
# isolate census tract matches! #

# any geographic id with exactly eleven characters is a census tract hpsa
ctract <- subset( x , nchar( geography.id ) == 11 )

# create a new `census.tract` column containing the census id
ctract$census.tract <- substr( ctract$geography.id , 6 , 11 )


# NOTE: this `ctract` table can now be merged onto other census tract-level data sets
# by using the `state.county.fips.code` and `census.tract` columns together


# remove those records from `x`
x <- subset( x , nchar( geography.id ) != 11 )

# end of census tract isolation #


# # # # # # # # # # # # # # # # # # # # #
# isolate minor civil division matches! #

# any geographic id with exactly eleven characters is a census tract hpsa
mcd <- subset( x , nchar( geography.id ) == 10 )

# create a new `census.tract` column containing the census id
mcd$mcd <- substr( mcd$geography.id , 6 , 10 )


# NOTE: this `mcd` table can now be merged onto other minor civil division-level data sets
# by using the `state.county.fips.code` and `mcd` columns together


# for a mapping between minor civil divisions and other geographies,
# check out the missouri census data center's geocorr12
# http://mcdc.missouri.edu/websas/geocorr12.html


# remove those records from `x`
x <- subset( x , nchar( geography.id ) != 10 )

# end of minor civil division isolation #

# # # # # # # # # # # # #
# examine the leftovers #

# count the number of..


# countywide hpsas
nrow( county )

# census tract-specific hpsas
nrow( ctract )

# minor civil division hpsas
nrow( mcd )

# leftover hpsas
nrow( x )

# look at any leftover hpsas..
head( x )
# ..these will get tossed.



# # # # # # # # # # # # # # # # # # # # # # # # # #
# save the three different geographic-level files #

# this save command will save all three data tables into a single R data file (.rda)
save( county , ctract , mcd , file = 'geographic hpsa.rda' )
# in the future, these three data tables can be re-loaded by setting the same working directory and then..
# load( 'geographic hpsa.rda' )

