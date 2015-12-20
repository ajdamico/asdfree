# analyze survey data for free (http://asdfree.com) with the r language
# national longitudinal surveys
# nlsy97

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NLS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Longitudinal%20Surveys/replication.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


###########################################################################
# this script matches the nlsy complex sample survey design statistics at #####################################################
# https://www.nlsinfo.org/content/cohorts/nlsy97/other-documentation/errata/errata-nlsy97-round-15-release/calculating-design #
###############################################################################################################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#############################################################################################################################
# prior to running this analysis script, the complete NLS microdata for your study must be loaded on your local machine     #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Longitudinal%20Surveys/download%20all%20microdata.R    #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will a bunch of R data files (.rda) within the "C:/My Directory/NLS/" folder (or specified working directory) #
#############################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# set your working directory.
# the NLS files for the study you'd like to analyze
# should have been stored within this folder
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NLS/" )
# ..in order to set your current working directory


# remove the # in order to run this install.packages line only once
# install.packages( c( "downloader" , "digest" , "survey" ) )


library(downloader) # downloads and then runs the source() function on scripts from github
library(survey)		# load survey package (analyzes complex design surveys)

# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN


# specify which variables you'll need for this particular analysis.  this is important.
vfta <- c( 'T5206900' , 'R9829600' , 'R0536300' , 'Z9061800' , 'T6657200' , 'R1205300' )
# just slop all of the variables you'll need together here in a single character vector.

# load the custom weights function to easily & automatically pull
# the weights you need for your specific analysis into R
source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Longitudinal%20Surveys/custom%20weight%20download%20functions.R" , prompt = FALSE )
# you can read more about longitudinal weights here
# http://www.nlsinfo.org/weights


# the get.nlsy.weights function returns a data.frame object
# containing the unique person identifiers and also a column of weights.

# this makes it easy to choose the correct longitudinal weight for whatever analysis you're trying to do.

# view which points-in-time are available for a particular study
# get.nlsy.selections( "nlsy97" )

# download weights for respondents in 1997
w97 <- get.nlsy.weights( "nlsy97" , 'YES' , 'SURV1997' )
# save those weights into an data.frame object called `w97`

# download weights for respondents who were in **any** of the 1997, 2002, or 2007 surveys
# w970207.any <- get.nlsy.weights( "nlsy97" , 'YES' , c( 'SURV1997' , 'SURV2002' , 'SURV2007' ) )
# save those weights into an data.frame object called `w970207.any`

# download weights for respondents who were in **all** of the 1997, 2002, and 2007 surveys
# w970207.all <- get.nlsy.weights( "nlsy97" , 'NO' , c( 'SURV1997' , 'SURV2002' , 'SURV2007' ) )
# save those weights into an data.frame object called `w970207.all`

# check out the results of those two previous commands.
# table( w970207.any$weight == 0 )
# the `w970207.any` table does not have any zero-weighted records
# table( w970207.any$weight == 0 , w970207.all$weight == 0 )
# but the `w970207.all` has quite a few zeroes,
# thanks to survey attrition

# download weights for respondents who are in every single round
# w <- get.nlsy.weights( "nlsy97" , "NO" , get.nlsy.selections( "nlsy97" ) )
# save those weights into an data.frame object called `w`


# specify the name of the study you're working through
study.name <- "NLSY97 1997-2011 (rounds 1-15)"
# this is just the name of the folder within your NLS directory
# if you're unsure of the name, use
# list.files()
# to see the options ;)

# load the sampling cluster and strata variables
load( paste0( "./" , study.name , "/" , "strpsu.rda" ) )
# note: this is *only* available for the 1997 study.
# the cluster and strata variables for earlier studies
# have not been posted.  in order to obtain them, you can
# either fill out the (free!) geocoded data application at
# http://www.bls.gov/nls/geocodeapp.htm
# or you can contact `NLSYGeocode@bls.gov` and request
# that they post the strata and cluster variables publicly
# for earlier studies the way they have done for the NLSY97 study.

# if you analyze an nlsy microdata set without
# the clustering and strata variables,
# all of your measures of precision
# (standard errors, confidence intervals,
# variances, t-tests) will be wrong.

# merge the weights data.frame with the sampling cluster data.frame
x <- merge( strpsu , w97 , by.x = 'R0000100' , by.y = 'id' )

# loop through all variables needed for this analysis,
# limiting that vector to the first four characters
# (this is how the files are organized on your local disk)
for ( i in unique( substr( vfta , 1 , 4 ) ) ){

	# load an R data file (.rda) into working memory
	load( paste0( "./" , study.name , "/" , i , ".rda" ) )

	# store the number of records in your current `x` data.frame
	before.nrow <- nrow( x )
	
	# merge the R data file you've just loaded onto `x`
	x <- merge( x , get( i ) )
	
	# confirm that this has not altered the record count
	stopifnot( nrow( x ) == before.nrow )
	
	# remove the smaller file you'd just loaded from working memory..
	rm( list = i ) ; gc()
	# ..and immediately clear up RAM

}

# alright!  now you've got all of the variables you need for your analysis
# bound together into a single R data.frame object.  look at the first six records
head( x )

# blank out all missing values, everywhere.
x[ x < 0 ] <- NA
# negatives in nlsy microdata are missings.

# add a female-only asvab math score
x[ x$R0536300 %in% 2 , 'foasvab' ] <- x[ x$R0536300 %in% 2 , 'R9829600' ]

# add "never received high school diploma" by 2011
x$nohsdip <- as.numeric( x$T6657200 < 2 )

# add "received bachelor's degree or higher" by 2011
x$bachigh <- as.numeric( x$T6657200 > 2 )

# add lives with two parents and at least one biological parent
x$p2b1 <- as.numeric( x$R1205300 < 4 )

# construct a complex-sample survey design object
y <- 
	svydesign( 
		~ R1489800 , 
		strata = ~ R1489700 , 
		data = x ,
		weights = ~ weight ,
		nest = TRUE
	)
# using the sampling information plus the custom weight.

# initiate an empty object
table1 <- NULL

# specify the variables to loop through and just average.
rows <- c( 'T5206900' , 'R9829600' , 'foasvab' , 'Z9061800' , 'bachigh' , 'nohsdip' , 'p2b1' )

# loop through 'em
for ( v in rows ){

	# add a tilda to the variable and coerce it to a `formula` class of object
	a <- as.formula( paste( "~" , v ) )

	# calculate the unweighted number of records for the current variable
	ct <- unwtd.count( a , y )

	# calculate the survey-adjusted mean of the current variable
	mn <- svymean( a , y , deff = TRUE , na.rm = TRUE )
	# removing all missing values

	# extract the counts, means, and precision information
	this.table <-
		data.frame( 
			variable = v , 
			unwtd.N = coef( ct ) , 
			estimate = coef( mn ) , 
			se = SE( mn )[1] , 
			deff = deff( mn ) , 
			deft = sqrt( deff( mn ) ) 
		)
	# into a single-row data.frame object

	# stack it with the `table1` object
	table1 <- rbind( table1 , this.table )
	
}

# print the results to the screen
print( table1 )
# whoops, that's all with scientific notation

# extend the decimals shown
options( scipen = 10 )

# try printing again
print( table1 )
# hooray
