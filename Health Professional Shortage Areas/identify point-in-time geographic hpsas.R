# analyze us government survey data with the r language
# health services and resources administration (hrsa)
# health professional shortage areas (hpsa) file
# most currently available data (the file on the website constantly changes)

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


############################################################################
# isolate the currently- or previously-designated primary care physician   #
# Health Professional Shortage Area (HPSA), then save all geographic files #
############################################################################


# set your working directory.
# all HPSA files will be stored here
# after downloading and importing it.
# use forward slashes instead of back slashes

setwd( "C:/My Directory/HPSA/" )



# remove the # in order to run this install.packages line only once
# install.packages( "stringr" )


require(stringr) # load stringr package (manipulates character strings easily)


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
	
	
	# x # x # x # x #
	# critical note: 
	# the `unique.designations` and `y` objects below are data tables with one-record-per-hpsa
	# as opposed to the table `x` - which contains one-record-per-geography
	# in order to match the nationwide published statistics, simply use these one-record-per-hpsa tables
	# however, to merge hpsa data up with specific geographies and locations, you'll need to use the one-record-per-geography tables
	# because, for example, a single hpsa designation might span multiple counties or contain multiple census tracts
	# thanks for playing
	# end of critical note, really hope ya read it.
	# x # x # x # x #
	
	
	# # # # # # # # # #
	# # replication # #
	
	
	# the number of currently-designated hpsas should exactly match this page:
	# http://ersrs.hrsa.gov/ReportServer/Pages/ReportViewer.aspx?/HGDW_Reports/BCD_HPSA/BCD_HPSA_SCR50_Smry&rs:Format=HTML4.0
	
	# find the unique source id x type description combos
	unique.designations <- unique( x[ , c( 'source.id' , 'type.description' , 'designation.population' , 'fte' , 'shortage' ) ] )
	
	
	# total the number of hpsas
	nrow( unique.designations )
	
	# print a table containing counts of the different hpsa types:
	table( unique.designations$type.description )
	
	# the single county + geographical area categories from the table
	# should sum to the 'service area' total on the web page
	
	# the population group total should match on its own
	
	# the unknown category should match on its own
	
	# the remaining categories from the table
	# should sum to the facility total
	
	
	# the total designation population does not match table 1..
	sum( unique.designations$designation.population , na.rm = T )
	
	# ..because non-institutional facilities must be excluded.
	# in other words, only geographic areas and facilities where people live contribute to that total count.
	# community health centers that simply serve a local population
	# do not contribute to the total
	
	y <- 
		subset( 
			unique.designations ,
			type.description %in% 
				c(
					"Single County" ,
					"Geographical Area" ,
					"Population Group" ,
					"Correctional Facility" ,
					"Other Facility"
				)
		)
	
	# ..and now the total matches table 1..
	sum( y$designation.population , na.rm = T )
	
	# ..and the components do as well.
	tapply( 
		# run the function stated below..
		y$designation.population ,
		
		# ..but broken down by this column
		y$type.description ,
		
		# here's the function:
		sum ,
		
		# and also pass in this argument
		na.rm = TRUE
	)
	# for more details about the tapply function,
	# watch the two-minute video
	# http://www.screenr.com/JQS8
	
	# NOTE: the populations shown in the hpsa data often overlap or contain outdated statistics.
	# i recommend that you merge populations on from another source
	# (like the missouri census data center's census 2010 geomapper)
	# http://mcdc.missouri.edu/websas/geocorr12.html


	# match the hrsa-published 'practitioners needed to remove designations' column
	
	# the quants at the health services and resources administration threw a curveball here:
	# every hpsa with a shortage ending with 0.5 should round *up*
	# r does not round up by default, it rounds to the nearest even number.
	# if you'd like a nerdlaugh, check out this discussion:
	# https://stat.ethz.ch/pipermail/r-help/2009-March/190119.html
	# best line: "IEC 60559 is an international standard: Excel is not."
	
	# initiate a rounding function that always rounds *up* when the number ends with 0.5
	excel_round <- function( x , digits ) round( x * ( 1 + 1e-15 ) , digits )
	# just like microsoft excel.
	
	# round the `shortage` column to the nearest integer..
	y$rnd_shortage <- excel_round( y$shortage )

	# the number of practitioners needed to remove the designation
	# exactly matches table 1
	sum( y$rnd_shortage , na.rm = TRUE )
	
	# ..and the components almost match as well.
	tapply( 
		# run the function stated below..
		y$rnd_shortage ,
		
		# ..but broken down by this column
		y$type.description ,
		
		# here's the function:
		sum ,
		
		# and also pass in this argument
		na.rm = TRUE
	)
	# for more details about the tapply function,
	# watch the two-minute video
	# http://www.screenr.com/JQS8
	
	
	# match the hrsa-published 'estimated underserved population' column
	
	# if the full time equivalents column (FTE) is missing, set it to zero
	y[ is.na( y$fte ) , 'fte' ] <- 0

	# calculate the number of underserved individuals in each hpsa
	# modify the current `y` data table
	y <- 
		transform( 
			y , 
			
			# add a new column `underserved`
			underserved = 
				# if the number of full time equivalents x 2000 is greater than the population..
				ifelse( 
					fte * 2000 > designation.population , 
					# ..then nobody is underserved
					0 , 
					# ..otherwise set it to the total population minus
					# the `floor` of the number of full time equivalents x 2000,
					# where `floor` is the largest integer below the number given (essentially lopping off any decimals)
					designation.population - floor( fte * 2000 ) 
				) 
		)

	# estimated underserved population
	# exactly matches table 1
	sum( y$underserved , na.rm = TRUE )
	
	
	# match the hrsa-published 'practitioners needed to achieve target ratios' column
	
	# calculate the number of practitioners needed in each hpsa
	# modify the current `y` data table
	y <- 
		transform( 
			y , 
			# add a new column `practitioners.needed`
			# that simply contains the `floor` of the number underserved divided by 2000
			practitioners.needed = floor( underserved / 2000 )
		)
	
	# practitioners needed to achieve target ratios
	# exactly matches table 1
	sum( y$practitioners.needed , na.rm=TRUE )
	
	# # replication completed # #
	# # # # # # # # # # # # # # #
	
	
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

	# remove the fields added to `x`
	x$ud <- x$dd <- NULL
	
}

# end of hpsa designation date-based elimination #


# territory elimination #

# print the current count of records by state
table( x$state.abbreviation )

# remove puerto rico and other territories
x <- x[ as.numeric( x$state.fips.code ) %in% 1:56 , ]
# comment this line out to leave territories in the data.

# re-print the current count of records by state
table( x$state.abbreviation )

# end of territory elimination #


# hpsa type elimination #

# print the current count of records by state
table( x$type.description )

# remove hpsa records that are *points* (like health centers, clinics, correctional facilities, etc)
# and keep only geographic areas
x <- x[ x$type.description %in% c( 'Single County' , 'Geographical Area' , 'Population Group' ) , ]

# re-print the current count of records by state
table( x$type.description )

# end of territory elimination #




# do you simply want hpsas that are only *population groups* (as opposed to geographic area hpsas) thrown out?
throw.out.pop.group.hpsas.please <- FALSE

# if so..
if ( throw.out.pop.group.hpsas.please ){

	# only keep single county and geographical area hpsa types
	x <- x[ x$type.description %in% c( 'Single County' , 'Geographical Area' ) , ]

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
	pg.recs <- ( x$type.description == 'Population Group' )

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
			type.description == 'Population Group' 
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


# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
