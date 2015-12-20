# analyze survey data for free (http://asdfree.com) with the r language
# health services and resources administration (hrsa)
# health professional shortage areas (hpsa) file
# replicate hrsa nationwide statistics

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/HPSA/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Health%20Professional%20Shortage%20Areas/replicate%20hrsa%20nationwide%20statistics.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


###############################################################
# this script matches the nationwide statistics at the top of #############################################################
# http://ersrs.hrsa.gov/ReportServer/Pages/ReportViewer.aspx?/HGDW_Reports/BCD_HPSA/BCD_HPSA_SCR50_Smry&rs:Format=HTML4.0 #
###########################################################################################################################


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



#################################################################
# replicate the currently-designated primary care physician     #
# Health Professional Shortage Area (HPSA) published statistics #
#################################################################


# set your working directory.
# all HPSA files will be stored here
# after downloading and importing it.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/HPSA/" )
# ..in order to set your current working directory



# load the primary care physician HPSA file
# and immediately save it as a new object `x`
load( "HPSA_PC.rda" ) ; x <- PC

# note: this identification process could also be quickly run
# on the dental care or mental health hpsas by uncommenting
# one of these lines instead:
# load( "HPSA_DC.rda" ) ; x <- DC
# load( "HPSA_MH.rda" ) ; x <- MH


# remove hpsa records that are not designated for the time period you are interested in #

# print a table of counts of the
# currently available hpsa statuses
table( x$status.description )


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
# in other words, only geographic areas and facilities where people actually **live** contribute to that total count.
# community health centers that simply serve a local population do not contribute to the published totals

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

###########################################
# end of published statistics replication #
###########################################


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
