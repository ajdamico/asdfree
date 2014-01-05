# analyze survey data for free (http://asdfree.com) with the r language
# national immunization survey
# 2011 main files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NIS" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/National%20Immunization%20Survey/replication.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# http://www.screenr.com/Zpd8

# joe walsh
# j.thomas.walsh@gmail.com

# anthony joseph damico
# ajdamico@gmail.com

# if you use this script for a project, please send me a note
# it's always nice to hear about how people are using this stuff

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf


# replicate entire top row of table g.8 of the data user's guide found on pdf pages 180 and 181
# "estimated vaccination coverage with individual vaccines and selected vaccination series"
# ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/NIS/NISPUF11_DUG.PDF#page=180


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################
# prior to running this analysis script, the nis main 2011 single-year file must be loaded as an r data file (.rda) #
# on the local machine. running the download all microdata script will download and import this file nicely for ya  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/usgsd/master/National%20Immunization%20Survey/download%20all%20microdata.R        #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "nis2011.rda" in C:/My Directory/NIS or wherever the working directory was set.    #
#####################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# remove the # in order to run this install.packages line only once
# install.packages( "survey" )



library(survey) # load survey package (analyzes complex design surveys)




# set your working directory.
# all NIS data files should have been stored here
# after downloading and importing.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NIS/" )
# ..in order to set your current working directory



# set the number of digits shown in all output

options( digits = 15 )


# set R to produce conservative standard errors instead of crashing
# http://faculty.washington.edu/tlumley/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN


# load the national immunization survey's 2011 main data.frame object
load( 'nis2011.rda' )

# construct a numeric vector containing all of
# the unique values of the `estiap` variable
e.lev <-
	c( 
		0, 1, 2, 4, 5, 6, 7, 8, 10, 11, 12, 13, 14, 16, 17, 18, 19, 20, 
		22, 25, 27, 28, 29, 30, 31, 34, 35, 36, 38, 40, 41, 44, 46, 47, 
		49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 
		65, 66, 68, 69, 72, 73, 74, 75, 76, 95, 97, 102
	)
	

# construct a numeric vector containing all of
# the unique labels of the `estiap` variable
e.lab <-
	c(
		"US Total", "CT", "MA", "ME", "NH", "RI", "VT", "NJ", 
        "NY-Rest of State", "NY-City of New York", "DC", "DE", "MD ", 
        "PA-Rest of State", "PA-Philadelphia County", "VA", "WV", "AL", 
        "FL", "GA", "KY", "MS", "NC", "SC", "TN", "IL-Rest of State", 
        "IL-City of Chicago", "IN ", "MI", "MN", "OH", "WI", "AR", 
        "LA", "NM", "OK", "TX-Rest of State", "TX-Dallas County", 
        "TX-El Paso County", "TX-City of Houston", "TX-Bexar County", 
        "IA", "KS", "MO", "NE", "CO", "MT", "ND", "SD", "UT", "WY", 
        "AZ", "CA-Rest of State", "CA-Los Angeles County", "HI", "NV",
        "AK", "ID", "OR", "U.S. Virgin Islands", "WA-Eastern WA", 
        "WA-Western WA"
	)
	

# overwrite the `estiap` column with a new factor variable
# retaining the numeric values, but adding the labels specified in the block above
x$estiap <- 
	factor(
		x$estiap ,
		levels = e.lev , 
		labels = e.lab
	)
# these labels could be obtained from:
	# the codebook
	# the r import script
	# the sas import script
# hooray!
	
	
# create two new binary variables in the data.frame `x`
# `dtap.3p` is a 1 whenever any of the five variables shown below
# are >= 3 and otherwise zero.  `dtap.4p` is the same, but >= 4.

# overwrite the data.frame `x` with..
x <-
	transform(
		# the same data.frame, but..
		x ,
		
		# with a new variable `dtap.3p`
		dtap.3p =

			# with the logical test below, converted to zero/one
			as.numeric(

				( p_numdah >= 3 ) |
				( p_numdhi >= 3 ) |
				( p_numdih >= 3 ) |
				( p_numdta >= 3 ) |
				( p_numdtp >= 3 )

			) ,
		
		# and also a new variable `dtap.3p`		
		dtap.4p =

			# with the logical test below, converted to zero/one
			as.numeric(

				( p_numdah >= 4 ) |
				( p_numdhi >= 4 ) |
				( p_numdih >= 4 ) |
				( p_numdta >= 4 ) |
				( p_numdtp >= 4 )

			)

	)

	
#################################################
# survey design for taylor-series linearization #
#################################################

# create survey design object with NIS design information
y <-
	svydesign(
		id = ~seqnumhh , 
		strata = ~stratum_d , 
		weights = ~provwt_d , 
		data = subset( x , provwt_d > 0 ) 
	)  
# matching the specifications laid out in the analysis portion of our user guide:
# ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/NIS/NISPUF11_DUG.PDF#page=82


# okay, time to start matching table g.8, again found on pdf page 180 of the 2011 nis data user's guide:
# ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/NIS/NISPUF11_DUG.PDF#page=180


# run a simple survey-weighted mean of the binary variable constructed above,
# both store the result into the object `dtap.pct` and (since the statement is encapsulated in parentheses)
# also print the result to the screen so the user can see what's cooking.
( dtap.pct <- svymean( ~dtap.3p , y ) )

# extract the coefficient (in this case, the mean.) from the `dtap.pct` object
# then multiply it by one hundred, then round it to the tenths place.
round( coef( dtap.pct ) * 100 , 1 )
# this precisely matches the first number in table g.8

# extract the standard error from the same object
# then multiply it by approximately 1.96 and also by one hundred,
# then again round to the tenths place.
round( 
	SE( dtap.pct ) * 
	qnorm( 0.975 ) * 
	100 , 
	1 
)
# this precisely matches the length of the confidence interval shown
# next to the very first number on table g.8


# in addition to the united states national average top row,
# table g.8 contains many different geographic breakouts.

# here's how to extract most of them in a single command.

# again, store a simple survey-weighted mean of the `dtap.3p` column,
# but this time broken out by the `estiap` geographic column
# both store the result into the object `dtap.pct.by` and (since the statement is encapsulated in parentheses)
# also print the result to the screen so the user can see what's cooking.
( dtap.pct.by <- svyby( ~dtap.3p , ~estiap , y , svymean ) )

# take a look at the geography names
rownames( dtap.pct.by )

# extract all of the coefficients from the `dtap.pct.by` object
# then multiply them all by one hundred, then round everything to the tenths place.
round( coef( dtap.pct.by ) * 100 , 1 )

# extract the standard errors from the same object
# then multiply them all by approximately 1.96 and also by one hundred,
# then again round to the tenths place.
dtap.se <-
	round( 
		SE( dtap.pct.by ) * 
		qnorm(0.975) * 
		100 , 
		1 
	)

# tack the geography names onto the confidence interval sizes
names( dtap.se ) <- rownames( dtap.pct.by )

# take a look at your resultant confidence interval sizes.
# these should match the number after the plus-or-minus,
# all the way down the first column
dtap.se


# there sure are a lot of columns shown in table g.8
# here's a list of the variables used to construct the table
# stored inside a single, long formula object.
g8.columns <-
	~ 
		dtap.3p + 
		dtap.4p + 
		p_utdpol + 
		p_utdmmx +
		p_utdhib + 
		p_utdhib_short_s +
		p_utdhib_rout_s + 
		p_utdhep + 
		u3d_hep +
		p_u12vrc + 
		p_utdpc3 +
		p_utdpcv + 
		p_utdhepa1 + 
		p_utdhepa2 + 
		p_utdrot_s + 
		p_utd431 + 
		putd4313 + 
		putd4313 + 
		p_utd431h_rout_s + 
		pu431331 +
		pu431_31 +
		pu431331 +
		p_utd431h31_rout_s +
		pu4313314 +
		pu431_314 +
		pu4313314 +
		pu431_314 +
		p_utd431h314_rout_s
		
# put that formula object inside the `svymean` function,
# and create an object `table.g8.first.row` just like above
( table.g8.first.row <- svymean( g8.columns , y ) )

# then, just like above, extract both the rounded statistics..
round( coef( table.g8.first.row ) * 100 , 1 )

# ..and confidence interval lengths for each column
# of the first row of table g.8
round( 
	SE( table.g8.first.row ) * 
	qnorm(0.975) * 
	100 , 
	1 
)
# cool?


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
