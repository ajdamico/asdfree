# analyze us government survey data with the r language
# area resource file
# 2011-2012

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



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#########################################################################################################
# prior to running this analysis script, the arf 2011-2012 file must be loaded as an R data file (.rda) #
# on the local machine.  running the 2011-2012 arf - download script will create this R data file       #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/usgsd/blob/master/Area%20Resource%20File/2011-2012%20arf%20-%20download.R #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "arf2011.rda" with 'arf' in C:/My Directory/ARF                        #
#########################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# set your working directory.
# the ARF 2011-2012 data files should have been stored here
# after running the program described above
# use forward slashes instead of back slashes

setwd( "C:/My Directory/ARF/" )


# load the 2011-2012 ARF data file
load( "arf2011.rda" )


# now the 'arf' data frame is available in memory..
# ..but has far too many variables to browse through
ncol( arf )


# the "ARF 2011 Tech Doc.xls" file in the current working directory contains field labels
# so create a smaller data table with only a few columns of interest
# first, create a character vector containing only the columns you'll need:
variables.to.keep <-
	c(
		"f00002" ,			# fips state + county code
		"f00008" , 			# state name
		"f12424" , 			# state abbreviation
		"f00010" , 			# county name
		"f13156" , 			# ssa beneficiary county code
		"f1389209" ,		# metro/micro statistical area name
		"f0453010" ,		# 2010 census population
		"f1212910"	 		# total active m.d.s non-federal & federal
	)

	
# now create a new data frame 'x' containing only those specified columns from the 'arf' data frame
x <- arf[ , variables.to.keep ]


# finally, look at the first six records to browse what the new (manageable) data frame looks like
head( x )


# rename the variables something more user-friendly
names( x ) <- c( "fips" , "state" , "stateab" , "county" , "ssa" , "mmsa" , "pop2010" , "md2010" )

# and re-examine the first six records
head( x )


# run some simple summary statistics

# in 2010, the census recorded a total us population of..
sum( x$pop2010 )

# in 2010, the american medical association masterfile recorded this many active doctors..
sum( x$md2010 )


# when merging the arf to another data set,
# be cautious about using fips vs. ssa county codes

# the entire arf contains...records
nrow( x )

# there are...unique fips county codes (so one unique fips per record)
length( unique( x$fips ) )

# but there are fewer unique ssa county codes
length( unique( x$ssa ) )

# because many counties with fips codes do not have ssa county codes
# here's a few records where the ssa county code equals zero (missing)
head( x[ x$ssa == 0 , ] )


# you could print all of them to the screen
x[ x$ssa == 0 , ]
# ..and find they're mostly the us territories.
# because territories have fips but not ssa county codes


# # # # # # # # # # # # # #
# county analysis example #
# # # # # # # # # # # # # #

# goal: look at the ten most populous counties in the united states #

# order the condensed arf by population
x <- x[ order( x$pop2010 , decreasing = TRUE ) , ]
# view http://www.screenr.com/0a28 to learn why the above statement works

# print the first ten records of the newly-ordered data frame
x[ 1:10 , ]


# # # # # # # # #
# merge example #
# # # # # # # # #

# goal: merge the arf onto another R data frame #

# note: you must load another R data frame (presented here as 'yourdata')
# with either a 'fips' or 'ssa' identifier in order for this merge to work

# to merge the arf onto yourdata using the county fips code,
# a simple merge should suffice, so long as every fips code has a match
# count the number of records in yourdata
nrow( yourdata )
# perform the merge
yourdata <- merge( yourdata , x , by = "fips" )
# confirm the number of records in yourdata hasn't changed
nrow( yourdata )


# to merge the arf onto yourdata using the county ssa code,
# try limiting the arf to only records with a non-zero ssa code
arf.with.ssa <- subset( x , ssa != 0 )
# count the number of records in yourdata
nrow( yourdata )
# perform the merge
yourdata <- merge( yourdata , arf.with.ssa , by = "ssa" )
# confirm the number of records in yourdata hasn't changed
nrow( yourdata )


# # # # # # # # # #
# mapping example #
# # # # # # # # # #

# goal: create a county-level chloropleth map with r #

# follow the code presented at http://www.thisisthegreenroom.com/2009/choropleths-in-r/

# install the maps package if you don't already have it
install.packages( "maps" )

# load the maps package
require(maps)

# load county fips codes data (included with the maps package)
data(county.fips)

# define color buckets
colors = c("#F1EEF6", "#D4B9DA", "#C994C7", "#DF65B0", "#DD1C77", "#980043")


# create a new column in the arf: active doctors per person
# if the county population is greater than zero,
# then divide the number of active doctors by the county population
x <- transform( x , dpp = ifelse( pop2010 > 0 , md2010 / pop2010 , NA ) )
# the county-level statistic 'dpp' will be mapped

# calculate cutpoints for the six different color buckets
# for more detail on the quantile() function, view: http://www.screenr.com/hP28
cut.points <- quantile( x$dpp , seq( 0 , 1 , 1/6 ) , na.rm = TRUE )

# ..then use the cut function to create a 'colorBuckets' variable
# for more detail on the cut() function, view: http://www.screenr.com/LGd8
x$colorBuckets <- as.numeric( cut( x$dpp , cut.points , include.lowest = TRUE ) )

# align data with map definitions by matching FIPS codes
# works much better than trying to match the state, county names
# which also include multiple polygons for some counties
colorsmatched <- x$colorBuckets[ match( county.fips$fips , x$fips ) ]

# create the legend's text
# print the number of doctors per ten thousand people to the screen
cut.points * 10000
leg.txt <- c( "< 3" , "3 - 5.5" , "5.5 - 8.3" , "8.3 - 12.3" , "12.3 - 20.3" , "> 2.03" )

#draw county chloropleth map
map( 
	"county" , 
	col = colors[ colorsmatched ] ,
    fill = TRUE , 
	resolution = 0 , 
	lty = 0 , 
	projection = "polyconic"
)

# add white state boundaries
map(
	"state" , 
	col = "white" , 
	fill = FALSE , 
	add = TRUE , 
	lty = 1 , 
	lwd = 1 , 
	projection = "polyconic"
)

# add title and legend
title( "doctors per ten thousand people, 2010" )
legend("topright", leg.txt, horiz = TRUE, fill = colors , cex = 0.75 )


# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
