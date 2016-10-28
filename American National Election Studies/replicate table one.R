# analyze survey data for free (http://asdfree.com) with the r language
# american national election studies
# 2004 + 2006
# time series + pilot

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/ANES/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/American%20National%20Election%20Studies/replicate%20table%20one.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# this r script will replicate each of the statistics from the anes publication
# http://www.electionstudies.org/resources/papers/nes012492.pdf#page=25
# column labeled "design-consistent with published strata"

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################
# prior to running this replication script, all anes public use microdata files must be loaded as R data            #
# files (.rda) on the local machine. running the "download and import.R" script will create these files.            #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/asdfree/blob/master/American%20National%20Election%20Studies/download%20and%20import.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will save a number of .rda files in C:/My Directory/ANES/ (or the working directory was chosen)       #
#####################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



#####################################################################################
# Analyze the 2004 TS and 2006 Pilot American National Election Studies file with R #
#####################################################################################


# set your working directory.
# all ANES data files will be stored here
# after downloading and importing.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/ANES/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( "survey" )


library(survey)  # load survey package (analyzes complex design surveys)


# by default, R will crash if a primary sampling unit (psu) has a single observation
# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
# by uncommenting this line:
# options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN


# the two r data.frame objects can be loaded directly
# from your local hard drive, since the download script has already run

# load the 2006 pilot file
load( "./2006pilot/anes2006pilot.rda" )
# immediately rename the pilot data.frame to `p06`
p06 <- x

# remove the object `x` from memory
rm( x )

# load the 2004 time series file
load( "./2004 Time Series Study/anes2004TS.rda" )

# immediately rename the time series data.frame to `ts04`
ts04 <- x

# remove the object `x` from memory
rm( x )

# merge these two data.frame objects together,
# using two different column names in the files
# that just happen to contain the same information
x <- 
	merge( 
		p06 , 
		ts04 , 
		by.x = 'v06p001' , 
		by.y = "v040001" 
	)
# now your object `x` contains all matching records


# display the number of rows in the merged data set
nrow( x )

# display the first six records in the merged data set
head( x )

#########################
# perform a few recodes #

# construct an age category variable,
# using categories 18-29/30-39/40-49/50-59/60-69/70+
x$agecat <- findInterval( x$v043250 , seq( 30 , 70 , 10 ) )

# recode the (more specific) education category variable
# into four broader categories--
# less than hs, hs, some college, bachelor's or above
x$educat <- cut( x$v043254 , c( 0 , 2 , 3 , 5 , 7 ) , labels = 1:4 )

# recode the variable that's currently voter, nonvoter (registered), nonvoter (nonregistered)
# to a variable that's simply voter, nonvoter
x$votecat <- c( 1 , 2 , 2 )[ x$v045018x ]

# recode the household income categories into what's specified in the target output table
x$inccat <- findInterval( x$v043293x , c( 1 , 10 , 15 , 18 , 20 , 23 , 24 ) )

# zeroes, 88s, and 89s all belong in the zero category
x[ x$inccat %in% c( 0 , 7 ) , 'inccat' ] <- 0


# note that `v045026` will not match unless you
# throw the 9's out of the denominator
# here's how to match those statistics precisely..
x[ x$v045026 %in% 9 , 'v045026' ] <- NA
# ..and throw nines out yourself.

# end of recoding #
###################


#################################################
# survey design for taylor-series linearization #
#################################################

# create a survey design object (gss.design) with GSS design information
y <- 
	svydesign( 
		id = ~v06p007b , 
		strata = ~v06p007a , 
		data = x , 
		weights = ~v06p002 , 
		nest = TRUE 
	)

#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in the 2004 time series + 2006 pilot merged data set #

# the nrow function which works on both data frame objects..
class( x )
nrow( x )

# ..and survey design objects
class( y )
nrow( y )

# for starters, simply print the first distribution (with standard errors)
svymean( ~factor( agecat ) , y , na.rm = TRUE )
# that matches the "age recodes" rows and "design-consistent with published strata" column
# on the target replication table:
# http://www.electionstudies.org/resources/papers/nes012492.pdf#page=25

#############################################################
# print the exact contents of the full column to the screen #
#############################################################

# create a vector called `z` and fill it with a bunch of formulas
# of all of the variables to run the `svymean` function on
z <-
	c( 
		~factor( agecat ) , 
		~factor( v041109a ) ,
		~factor( v043299a ) ,
		~factor( educat ) ,
		~factor( inccat ) ,
		~factor( v06p775x ) ,
		~factor( votecat ) ,
		~factor( v045026 ) ,
		~factor( v06p680 ) ,
		~factor( v06p790 ) ,
		~factor( v06p656 ) ,
		~factor( v06p653 ) ,
		~factor( v06p630 ) ,
		~factor( v06p519 ) ,
		~factor( v06p552 )
	)

# loop through each of the elements in the vector `z`..
# and print the weighted distributions of each respective variable to the screen
for ( i in z ) print( svymean( i , y , na.rm = TRUE ) )	


##################################################################
# end of printing the exact contents of the column to the screen #
##################################################################

