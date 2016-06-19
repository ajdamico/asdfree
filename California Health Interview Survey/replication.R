# analyze survey data for free (http://asdfree.com) with the r language
# california health interview survey
# replication of askchis tables published by the ucla center for health policy research
# using the 2014 public use file

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/CHIS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/California%20Health%20Interview%20Survey/replication.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #


# carl ganz
# carlganz@ucla.edu



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#################################################################################################################################################
# prior to running this replication script, all chis 2014 public use microdata files must be loaded as R data                                   #
# files (.rda) on the local machine. running the "download all microdata.R" script will create these files.                                     #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/California%20Health%20Interview%20Survey/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will save a number of .rda files in C:/My Directory/CHIS/2014/ (or the working directory chosen)                                  #
#################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


#########################################################
# Analyze the California Health Interview Survey with R #
#########################################################


# set your working directory.
# the CHIS 2014 R data files (.rda) should have been
# stored in a year-specific directory within this folder.
# so if the file "adult.rda" exists in the directory "C:/My Directory/CHIS/2014/" 
# then the working directory should be set to "C:/My Directory/CHIS/"
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/CHIS/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( "survey" )


# no need to edit anything below this line #


# # # # # # # # #
# program start #
# # # # # # # # #


library(survey)  # load survey package (analyzes complex design surveys)


# if this option is set to TRUE
# R will exactly match SUDAAN results and Stata with the MSE option results
options( survey.replicates.mse = TRUE )
# otherwise if it is commented out or set to FALSE
# R will exactly match Stata without the MSE option results


# the r data frames can be loaded directly from your local hard drive

# load children ages 0-11
load( "./2014/child.rda" )

# copy the stored `x` data.frame to a `child` table
child <- x

# add an age category variable (useful after stacking)
child$agecat <- "1 - child"

# rename the four-category (excellent / very good / good / fair+poor) variable over to `hlthcat`
child$hlthcat <- child$ca6_p1

# load adolescents ages 12-17
load( "./2014/teen.rda" )

# copy the stored `x` data.frame to a `child` table
teen <- x

# add an age category variable (useful after stacking)
teen$agecat <- "2 - adolescent"

# rename the four-category (excellent / very good / good / fair+poor) variable over to `hlthcat`
teen$hlthcat <- teen$tb1_p1

# load adults ages 18+
load( "./2014/adult.rda" )

# copy the stored `x` data.frame to a `child` table
adult <- x

# add an age category variable (useful after stacking)
adult$agecat <- ifelse( adult$srage_p1 >= 65 , "4 - senior" , "3 - adult" )

# recode the five-category variable into four categories (condensing fair+poor)
adult$hlthcat <- c( 1 , 2 , 3 , 4 , 4 )[ adult$ab1 ]

# construct a character vector with only the variables needed for the analysis
vars_to_keep <- c( grep( "rakedw" , names( adult ) , value = TRUE ) , 'hlthcat' , 'agecat' )

# stack the child, teen, and adult data.frame objects into a single `x` data.frame
x <- 
	rbind( 
		child[ vars_to_keep ] , 
		teen[ vars_to_keep ] , 
		adult[ vars_to_keep ] 
	)

# initiate a column of all ones
x$one <- 1

# store `hlthcat` as a factor variable
x$hlthcat <- factor( x$hlthcat , labels = c( 'excellent' , 'very good' , 'good' , 'fair or poor' ) )


####################################
# replicate-weighted survey design #
####################################

# create a survey design object (y) with CHIS design information
# http://healthpolicy.ucla.edu/chis/analyze/Documents/2012MAY02-CHIS-PUF-Weighting-and-Variance-2Frequency.pdf
# consistent with Complex Surveys: a Guide to Analysis in R by Thomas Lumley Chapter #2
y <- 
	svrepdesign( 
		data = x , 
		weights = ~ rakedw0 , 
		repweights = "rakedw[1-9]" , 
		type = "other" , 
		scale = 1 , 
		rscales = 1  , 
		mse = TRUE 
	)



#####################################
# replication of AskCHIS statistics #
#####################################

# the PDF file stored at
# https://github.com/ajdamico/asdfree/raw/master/California%20Health%20Interview%20Survey/2014%20AskCHIS%20Health%20Status%20by%20Age.pdf
# was created using UCLA's official http://ask.chis.ucla.edu website
# therefore, matching the confidence intervals presented in this document should serve as proof of accurate `svrepdesign` construction


# match the lower right corner, the 37,582,000
round( coef( svytotal( ~ one , y ) ) , -3 )
# this is the population of california in 2014

# match the bottom row, the four age categories
round( coef( svytotal( ~ agecat , y ) ) , -3 )

# match the excellent, very good, and good weighted Ns
# broken out by the four age categories
round( coef( svyby( ~ hlthcat , ~ agecat , y , svytotal ) ) , -3 )

# match the right column's excellent, very good, and good percents
# and also match the confidence intervals.
all_column <- svymean( ~ hlthcat , y )

# 23.2%, 31.4%, 28.4%, and then 13.5%+3.5%
round( coef( all_column ) , 3 )

# confidence intervals for those statistics
round( confint( all_column , df = degf( y ) ) , 3 )

# note: since fair and poor are not broken out in the adolescent health status variable,
# these two rows cannot be matched using the public use file
# and are skipped for this exercise.  a user could calculate the child, adult, and senior
# fair versus poor breakout by re-creating the design above with the
# five-level health status variable instead of the four-level one used here.

# match the right column's excellent, very good, and good percents
# and also match the confidence intervals.
agecat_columns <- svyby( ~ hlthcat , ~ agecat , y , svymean )

# store the coefficients and confidence intervals side by side
agecat_results <-
	cbind(
		estimate = round( coef( agecat_columns ) , 3 ) ,

		round( confint( agecat_columns , df = degf( y ) ) , 3 )
	)

# print these results to the screen
print( agecat_results )
