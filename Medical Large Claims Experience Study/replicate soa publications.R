# analyze survey data for free (http://asdfree.com) with the r language
# medical large claims experience study
# replication of tables published by the society of actuaries
# using 1997, 1998, and 1998 claims files

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


#######################################################################################
# analyze the 1997, 1998, and 1999 Medical Large Claims Experience Study files with R #
#######################################################################################


# set your working directory.
# all MLCES data files will be stored here
# after downloading and importing.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/MLCES/" )
# ..in order to set your current working directory



# set the number of digits shown in all output

options( digits = 15 )


# print the counts and sum of expenditures shown on pdf page 2 of
# http://www.soa.org/Files/Research/Exp-Study/Claim-Database-Documentation_pdf.pdf

# loop through each year available and..
for ( year in 1997:1999 ){

	# load the current data set
	load( paste0( "mcles" , year , ".rda" ) )
	
	# print the number of records (claimants) to the screen
	print( nrow( x ) )
	
	# print the sum of paid charges to the screen
	print( sum( x$totpdchg ) )
	
	# remove the current data set from memory
	rm( x )
	
	# clear up RAM
	gc()
}


# replicate the 1997 statistics shown in table IV-A of
# http://www.soa.org/Files/Research/tables.zip

# load the 1997 data set
load( "mcles1997.rda" )

# create a numeric vector containing the values in the
# "maximum paid charges per claimant" column (excel column b)
max.charges <-
	c( 
		seq( 1000 , 4000 , 1000 ) ,
		seq( 5000 , 95000 , 5000 ) ,
		seq( 100000 , 190000 , 10000 ) ,
		seq( 200000 , 475000 , 25000 ) ,
		seq( 500000 , 1000000 , 100000 ) ,
		9999999
	) + 0.01
# note that one penny has been added to each value
	
	
# take a look at it, if it strikes your fancy
max.charges

# create a numeric vector containing the values in the
# "minimum paid charges per claimant" column (excel column a)
# which is just the combination of..	
min.charges <- 
	c( 
		# zero and
		0 , 
		# the `max.charges` vector, except the largest amount,
		# with one penny subtracted from each value
		max.charges[ -length( max.charges ) ] - 0.01 
	)

# create the fifty-two charge categories
x$charge.category <- 
	findInterval( 
		x$totpdchg , 
		max.charges  
	)

	
# claimants in range column #

# simple table of the number of records in each charge.category
table( x$charge.category )


# paid charges in range #

# simple aggregation of the sum of total paid charges
# within each charge.category
tapply( x$totpdchg , x$charge.category , sum )


# claimants exceeding minimum #

# reversed table, with the cumulative sum then reversed again
rev( cumsum( rev( table( x$charge.category ) ) ) )
# note: to understand how this works, try exploring this from the inside out:
# table( x$charge.category )
# rev( table( x$charge.category ) )
# cumsum( rev( table( x$charge.category ) ) )
# rev( cumsum( rev( table( x$charge.category ) ) ) )


# paid charges given charge exceeds minimum #

# simple aggregation of the sum of total paid charges
# within each charge.category, but cumulative this time.
rev( cumsum( rev( tapply( x$totpdchg , x$charge.category , sum ) ) ) )


# excess charges above minimum as deductible #

# first create a function with two required inputs: our data.frame `x` and some value `y`
afun <- function( y , x ) { sum( x[ x$totpdchg > y , 'totpdchg' ] - y ) }
# this function takes the sum of the difference between all paid charges above a certain value and `y`
# so, for example, the command `afun( 50000 , x )` will return the value in excel cell g26 -- 190,578,943 
# however, we want to run this function on lots of different `y` values instead of just one.  this sounds like a job for `lapply`
# the command `lapply( min.charges , afun , x )` runs each of the values in `min.charges` through the `afun` function and returns a list
# and that final list can be coerced into a numeric vector with the ?unlist function
unlist( lapply( min.charges , afun , x ) )


# excess charges per claimant above minimum as deductible #

# create a function similar to `afun` only this time divide by the total number of claimants,
# in order to get a "per claimant" value
a2fun <- function( y , x ) { sum( x[ x$totpdchg > y , 'totpdchg' ] - y ) / nrow( x[ x$totpdchg > y , ] ) }
# run the same happy `lapply` command that again whizzes all values in `min.charges` through the `a2fun` function
unlist( lapply( min.charges , a2fun , x ) )


# claimants in range #

# just divide the counts in each category by the total number of records in the `x` data.frame
# to create an on-the-fly table of proportions
table( x$charge.category ) / nrow( x )


# paid charges in range

# just divide the sums within each category by the sum of all paid charges in the `x` data.frame
# to create an on-the-fly table of proportions
tapply( x$totpdchg , x$charge.category , sum ) / sum( x$totpdchg )


# claimants exceeding minimum

# create another on-the-fly table of proportions that cumulatively sums the number of claimants
rev( cumsum( rev( table( x$charge.category ) / nrow( x ) ) ) )


# paid charges given charge exceeds minimum

# create another on-the-fly table of proportions that cumulatively sums the share of paid charges
rev( cumsum( rev( tapply( x$totpdchg , x$charge.category , sum ) / sum( x$totpdchg ) ) ) )


# excess charges above minimum as deductible

# create another on-the-fly table of proportions that cumulatively sums the share of paid charges,
# subtracting the deductibles (just the min.category values)
unlist( lapply( min.charges , afun , x ) ) / sum( x$totpdchg )

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
