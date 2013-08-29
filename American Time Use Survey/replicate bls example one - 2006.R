# analyze survey data for free (http://asdfree.com) with the r language
# american time use survey
# 2006

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/ATUS/2006/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/American%20Time%20Use%20Survey/replicate%20bls%20example%20one%20-%202006.R" , prompt = FALSE , echo = TRUE )
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



############################################################
# this script matches the results of example one presented #
# at http://www.bls.gov/tus/atususersguide.pdf#page=67     #
############################################################




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#############################################################################################################
# prior to running this analysis script, the atus 2006 file must be loaded onto the local machine.  running #
# the download all microdata script below will import the respondent- and activity-level files needed.      #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/usgsd/master/American%20Time%20Use%20Survey/download%20all%20microdata.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will files in the C:/My Directory/ATUS directory or wherever the working directory was set.   #
#############################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# set your working directory.
# the ATUS 2006 data files should have been stored here
# after running the program described above
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/ATUS/2006/" )
# ..in order to set your current working directory

# load the activity-level file
# (one record per respondent per activity)
load( "atusact.rda" )

# load the respondent-level file
# (one record per survey respondent)
load( "atusresp.rda" )

# limit the activity-level file to only activities coded as
# "care of household children"
# which can be found in page 3 of the 2006 lexicon
# http://www.bls.gov/tus/lexiconnoex2006.pdf#page=3
# tier1 code "care for household members" is "03"
# tier2 codes specific to children are: "01" , "02" , and "03"

# limit the activity-level table to
# only tier1 codes of 3 and
# only tier2 codes of 1, 2, or 3
childcare.activities <- 
	atusact[ atusact$tutier1code == 3 & atusact$tutier2code %in% 1:3 , ]

# since the table above contains one record per activity
# and you'll need one record per respondent,
# yooouuuuu guessssed it!  it's time to aggregate the current table


# sum up activity duration at the respondent-level
# (using tucaseid as the unique identifier)
# from the childcare activities file
respondent.level.childcare.activities <- 
	aggregate( 
		tuactdur24 ~ tucaseid , 
		data = childcare.activities , 
		sum 
	)

# merge the original respondent table `atusresp`
# with the newly-aggregated respondent childcare activity table
x <- 
	merge( 
		# from the respondent table, only keep the unique id
		# and the final survey weight
		atusresp[ , c( 'tucaseid' , 'tufinlwgt' ) ] , 
		respondent.level.childcare.activities , 
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

	
# look at the first six records of the resultant table
head( x )

# note that some of the activity duration columns
# contain missings.  these individuals simply did not
# engage in any childcare activities during their interview day
# so instead of including them as missings, their values should
# be overwritten with zeroes.

# for all records in data.frame `x` where the `tuactdur24`
# column is missing, overwrite it with a zero.
x[ is.na( x$tuactdur24 ) , 'tuactdur24' ] <- 0


# now simply use a `weighted.mean` function
weighted.mean( x$tuactdur24 , x$tufinlwgt )
# to precisely replicate the number of minutes per day
# the average american spent performing childcare activites

# as seen in this bls publication example 1 answer at #
# http://www.bls.gov/tus/atususersguide.pdf#page=71   #

# divide that result by sixty minutes in an hour
weighted.mean( x$tuactdur24 , x$tufinlwgt ) / 60
# to find the average number of hours per day
# the average american spent performing childcare activites


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
