# analyze survey data for free (http://asdfree.com) with the r language
# american time use survey
# 2007

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/ATUS/2007/" )
# source_url( "https://raw.github.com/ajdamico/asdfree/master/American%20Time%20Use%20Survey/replicate%20bls%20standard%20error%20-%202007.R" , prompt = FALSE , echo = TRUE )
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



###################################################################
# this script matches the bls statistics and standard error shown #
# starting at http://www.bls.gov/tus/atususersguide.pdf#page=32   #
# up until at http://www.bls.gov/tus/atususersguide.pdf#page=40   #
###################################################################




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#############################################################################################################
# prior to running this analysis script, the atus 2007 file must be loaded onto the local machine.  running #
# the download all microdata script below will import the respondent- and activity-level files needed.      #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/asdfree/master/American%20Time%20Use%20Survey/download%20all%20microdata.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will files in the C:/My Directory/ATUS directory or wherever the working directory was set.   #
#############################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# set your working directory.
# the ATUS 2007 data files should have been stored here
# after running the program described above
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/ATUS/2007/" )
# ..in order to set your current working directory


# remove the # in order to run this install.packages line only once
# install.packages( "survey" )


library(survey)		# load survey package (analyzes complex design surveys)

# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN



# if this option is set to TRUE
# R will exactly match SUDAAN results and Stata with the MSE option results
options( survey.replicates.mse = TRUE )
# otherwise if it is commented out or set to FALSE
# R will exactly match Stata without the MSE option results

# Stata svyset command notes can be found here: http://www.stata.com/help.cgi?svyset


# users have two options for calculating activity durations #

# either..

# load the activity-level file
# (one record per respondent per activity)
load( "atusact.rda" )

# ..or..

# load the activity-summary file
# (one record per respondent,
# with one column per activity code)
load( "atussum.rda" )

# both of the above files will be used to calculate activity duration per person #


# load the respondent-level file
# (one record per survey respondent)
load( "atusresp.rda" )


# load the respondent-level file
# (one record per survey respondent,
# with columns containing replicate weights)
load( 'atuswgts.rda' )


# # # # # # # # # # # # # # # # # # # # # # # # # # # #
# television codes can be found from the 2007 lexicon #
# http://www.bls.gov/tus/lexiconnoex2007.pdf#page=12  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # #


# option 1 - start with the activity summary file #

# calculate television watching activities per person
# using the activity summary file
television.per.person <- 
	# construct a new data.frame object
	data.frame(
		# ..with the first column containing the atus unique id..
		tucaseid = atussum$tucaseid ,
		# ..and the second column containing the sum of the two
		# television activity code columns, stored into an
		# activity duration over 24 hours column
		tuactdur24 = rowSums( atussum[ , c( 't120303' , 't120304' ) ] )
	)

# remove all records where the activity duration was zero.
television.per.person <- 
	television.per.person[ television.per.person$tuactdur24 > 0 , ]


# option 2 - start with the activity file #

# create a new `television` activity data.frame by
television <- 
	# subsetting the activity-level file
	subset( 
		atusact , 
		# keeping only records matching the television
		# tier codes found in the atus 2007 lexicon
		tutier1code == 12 &
		tutier2code == 3 &
		tutier3code %in% 3:4
	)

# sum up activity duration at the respondent-level
# (using tucaseid as the unique identifier)
# from the television activities file
television.per.respondent <-
		aggregate(
			tuactdur24 ~ tucaseid ,
			data = television ,
			sum
		)

# now you've got two basically identical data tables #
# television.per.person
# television.per.respondent

# take a look at the first and last six records of both tables
head( television.per.person )
head( television.per.respondent )

tail( television.per.person )
tail( television.per.respondent )
# same results.  fantabulous.



# merge the original respondent table `atusresp`
# with the newly-aggregated television activity table
x <- 
	merge( 
		# from the respondent table, only keep the unique id
		# and the final survey weight
		atusresp[ , c( 'tucaseid' , 'tufinlwgt' ) ] , 
		television.per.person , 
		# keep all records from the left table
		# regardless of a match
		all.x = TRUE 
		# this is called a `left join` - need help?
		# merge in 2 minutes: http://www.screenr.com/Znd8
	)

# confirm that the table created by the merge above `x`
# contains the same nuber of records as the original
# respondent-level table
stopifnot( nrow( x ) == nrow( atusresp ) )

	
# look at the first and last six records of the resultant table
head( x )

tail( x )

# note that some records in the activity duration column
# contain missings.  these individuals simply did not
# watch television during their interview day
# so instead of including them as missings, their values should
# be overwritten with zeroes.

# for all records in data.frame `x` where the `tuactdur24`
# column is missing, overwrite it with a zero.
x[ is.na( x$tuactdur24 ) , 'tuactdur24' ] <- 0


# once the minute variable `tuactdur24` is finished,
# divide it by sixty minutes per hour to create a new
# variable containing the number of hours of television activity
x$tuactdur24.hour <- x$tuactdur24 / 60


# now simply use a `weighted.mean` function
weighted.mean( x$tuactdur24 , x$tufinlwgt )
# to precisely replicate the number of minutes per day, and

weighted.mean( x$tuactdur24.hour , x$tufinlwgt )
# to find the average number of hours per day
# the average american spent watching television in 2007

# shown at the bottom of section 7.4 of the user guide #
# http://www.bls.gov/tus/atususersguide.pdf#page=39    #


# ..but that just provides us with the statistic,
# not the standard error.  in order to properly calculate error terms
# merge the table `x` with the replicate weights table

y <- merge( x , atuswgts )

# again, confirm that the table created by the merge above `y`
# contains the same nuber of records as the original respondent-level table
stopifnot( nrow( y ) == nrow( atusresp ) )


# finally, construct a replicate weighted survey design object
# with a fay's adjustment called `z`..
z <- 
	svrepdesign(
		weights = ~tufinlwgt ,
		repweights = "finlwgt[1-9]" ,
		type = "Fay" ,
		rho = ( 1 - 1 / sqrt( 4 ) ) ,
		data = y
	)

# ..to perform a final analysis command
# that will precisely match the standard error

# shown in section 7.5 of the user guide            #
# http://www.bls.gov/tus/atususersguide.pdf#page=39 #

# statistic and standard error of number of minutes daily
# that the average american (older than 14) spends watching tv
svymean( ~tuactdur24 , z )

# statistic and standard error of number of hours daily
# that the average american (older than 14) spends watching tv
svymean( ~tuactdur24.hour , z )


#################################################
# end of bureau of labor statistics replication #
#################################################

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
