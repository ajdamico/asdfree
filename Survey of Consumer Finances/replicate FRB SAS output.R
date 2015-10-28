# analyze survey data for free (http://asdfree.com) with the r language
# survey of consumer finances
# replication of the statistics and standard errors on pdf page 33 of "SCF PUF Net Worth SAS output from FRB.pdf"
# as outlined in the e-mail correspondence "SCF PUF Net Worth Statistics and Standard Errors from FRB.pdf"
# using 2010 public use microdata

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/SCF/" )
# source_url( "https://raw.github.com/ajdamico/asdfree/master/Survey%20of%20Consumer%20Finances/replicate%20FRB%20SAS%20output.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# note that these statistics come very close to the statistics and standard errors
# calculated using the federal reserve's 2010 internal data set,
# shown in the upper right corner of pdf page 17, table 4 of
# http://www.federalreserve.gov/pubs/bulletin/2012/pdf/scf12.pdf
# however, because those published tables use a restricted access file, the statistics generated below do not match exactly.


# to confirm that the methodology below is correct,
# analysts at the federal reserve provided me with statistics and standard errors generated using the public use file (puf)
# https://github.com/ajdamico/asdfree/blob/master/Survey%20of%20Consumer%20Finances/SCF%20PUF%20Net%20Worth%20Statistics%20and%20Standard%20Errors%20from%20FRB.pdf?raw=true
# and
# https://github.com/ajdamico/asdfree/blob/master/Survey%20of%20Consumer%20Finances/SCF%20PUF%20Net%20Worth%20SAS%20output%20from%20FRB.pdf?raw=true
# this r script will replicate each of the statistics from that custom run of the survey of consumer finances (scf) exactly


# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# https://www.youtube.com/watch?v=JLt9JfaAxUg

# anthony joseph damico
# ajdamico@gmail.com

# if you use this script for a project, please send me a note
# it's always nice to hear about how people are using this stuff

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#############################################################################################################################
# prior to running this replication script, the 2010 scf public use microdata files must be loaded as R data files (.rda)   #
# on the local machine. running the "1989-2010 download all microdata.R" script will create this file for you.              #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/asdfree/blob/master/Survey%20of%20Consumer%20Finances/1989-2010%20download%20all%20microdata.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will save a number of .rda files in C:/My Directory/SCF/ (or the working directory was chosen)                #
#############################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


###############################################################################################################
# replicate the 2010 Survey of Consumer Finances multiply-imputed mean, median and all standard errors with R #
###############################################################################################################


# set your working directory.
# the SCF 2010 R data file (scf2010.rda) should have been stored in this folder.

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/SCF/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( c( 'mitools' , 'survey' , 'Hmisc' , 'downloader' , 'digest' ) )


library(mitools)	# allows analysis of multiply-imputed survey data
library(survey)		# load survey package (analyzes complex design surveys)
library(downloader)	# downloads and then runs the source() function on scripts from github
library(foreign) 	# load foreign package (converts data files into R)
library(Hmisc) 		# load Hmisc package (loads a simple wtd.quantile function)


# load the 2010 survey of consumer finances into memory
load( "scf2010.rda" )



# memory conservation step #

# for machines with 4gb or less, it's necessary to subset the five implicate data frames to contain only
# the columns necessary for your particular analysis.  if running the code below generates a memory-related error,
# simply uncomment these lines and re-run the program:


# define which variables from the five imputed iterations to keep
vars.to.keep <- c( 'y1' , 'yy1' , 'wgt' , 'one' , 'networth' )
# note: this throws out all other variables (except the replicate weights)
# so if you need additional columns for your analysis,
# add them to the `vars.to.keep` vector above


# restrict each `imp#` data frame to only those variables
imp1 <- imp1[ , vars.to.keep ]
imp2 <- imp2[ , vars.to.keep ]
imp3 <- imp3[ , vars.to.keep ]
imp4 <- imp4[ , vars.to.keep ]
imp5 <- imp5[ , vars.to.keep ]


# clear up RAM
gc()

# end of memory conservation step #


# turn off scientific notation in most output
options( scipen = 20 )


# load two svyttest functions (one to conduct a df-adjusted t-test and one to conduct a multiply-imputed t-test)
source_url( "https://raw.github.com/ajdamico/asdfree/master/Survey%20of%20Consumer%20Finances/scf.survey.R" , prompt = FALSE )
# now that this function has been loaded into r, you can view its source code by uncommenting the line below
# scf.MIcombine
# scf.svyttest


# # # # # # # # # # # # # # # # # # # # # #
# part one: replicate statistics          #
# provided by the federal reserve board   #
# using just some simple base r functions #
# to prove you understand this data       #
# # # # # # # # # # # # # # # # # # # # # #


# replicate the mean and median #


# calculate five weighted mean net worths,
# one for each implicate number
wm <- 
	c( 
		weighted.mean( imp1$networth , imp1$wgt ) ,
		weighted.mean( imp2$networth , imp2$wgt ) ,
		weighted.mean( imp3$networth , imp3$wgt ) ,
		weighted.mean( imp4$networth , imp4$wgt ) ,
		weighted.mean( imp5$networth , imp5$wgt )
	)

# reproduced number: #
# mean net worth
( wm.nw <- mean( wm ) )


# calculate five weighted mean net worths,
# one for each implicate number
wq <- 
	c( 
		wtd.quantile( imp1$networth , imp1$wgt , 0.5 ) ,
		wtd.quantile( imp2$networth , imp2$wgt , 0.5 ) ,
		wtd.quantile( imp3$networth , imp3$wgt , 0.5 ) ,
		wtd.quantile( imp4$networth , imp4$wgt , 0.5 ) ,
		wtd.quantile( imp5$networth , imp5$wgt , 0.5 )
	)


# reproduced number: #
# median net worth
( wq.nw <- mean( wq ) )

	
	
# reproduced number: #
# imputation-based standard error of the mean #
( i.m <- sqrt( sum( ( mean( wm ) - wm )^2 ) / 4 ) )
# within a dollar of the FRB SAS output #

# initiate an sapply weighted mean function
# that uses the first implicate's networth value..
# ..and calculates the weighted mean for every replicate weight
swm <- function( wgt ) weighted.mean( imp1$networth , wgt )

# the -1 in the column parameter position throws out the first column,
# which is a unique identifier and therefore
# shouldn't be treated like the other weight variables
rwm <- sapply( rw[ , -1 ] , swm ) 

# reproduced number: #
# sampling-based standard error of the mean #
( s.m <- sqrt( sum( ( mean( rwm ) - rwm )^2 ) / 998 ) )
# within a dollar of the FRB SAS output #

# reproduced number: #
# combined standard error of the mean #
( cse.m <- sqrt( 6 / 5 * i.m^2 + s.m^2 ) )
# within a dollar of the FRB SAS output #


# calculate five weighted mean net worths,
# one for each implicate number
wd <- 
	c( 
		wtd.quantile( imp1$networth , imp1$wgt , 0.5 ) ,
		wtd.quantile( imp2$networth , imp2$wgt , 0.5 ) ,
		wtd.quantile( imp3$networth , imp3$wgt , 0.5 ) ,
		wtd.quantile( imp4$networth , imp4$wgt , 0.5 ) ,
		wtd.quantile( imp5$networth , imp5$wgt , 0.5 )
	)



# reproduced number: #
# imputation-based standard error of the median #
( i.q <- sqrt( sum( ( mean( wd ) - wd )^2 ) / 4 ) )
# within a dollar of the FRB SAS output #

# initiate an sapply weighted quantile function
# that uses the first implicate's networth value..
# ..and calculates the weighted quantile for every replicate weight
swd <- function( wgt ) wtd.quantile( imp1$networth , wgt , 0.5 )

# the -1 in the column parameter position throws out the first column,
# which is a unique identifier and therefore
# shouldn't be treated like the other weight variables
rwd <- sapply( rw[ , -1 ] , swd ) 

# reproduced number: #
# sampling-based standard error of the median #
( s.q <- sqrt( sum( ( mean( rwd ) - rwd )^2 ) / 998 ) )
# within a dollar of the FRB SAS output #

# reproduced number: #
# combined standard error of the median #
( cse.q <- sqrt( 6 / 5 * i.q^2 + s.q^2 ) )
# within a dollar of the FRB SAS output #


# # # # # # # # # # # # # # # # # # # # # #
# part two: replicate the same statistics #
# produced above, but this time use the   #
# r survey package to show that other     #
# analysis commands can be run the same   #
# way as all the other data sets on asdfree #
# # # # # # # # # # # # # # # # # # # # # #


# construct an imputed replicate-weighted survey design object
scf.design <- 
	svrepdesign( 
		
		# use the main weight within each of the imp# objects
		weights = ~wgt , 
		
		# use the 999 replicate weights stored in the separate replicate weights file
		repweights = rw[ , -1 ] , 
		
		# read the data directly from the five implicates
		data = imputationList( list( imp1 , imp2 , imp3 , imp4 , imp5 ) ) , 

		scale = 1 ,

		rscales = rep( 1 / 998 , 999 ) ,

		# use the mean of the replicate statistics as the center
		# when calculating the variance, as opposed to the main weight's statistic
		mse = TRUE ,
		
		type = "other" ,

		combined.weights = TRUE
	)



# prove you've got the standard error due to sampling correct #

# for means #

# run a svymean() command on just the first design..
m.nw.justone <- svymean( ~networth , scf.design$designs[[1]] )

# the coefficient is for only the first of five implicates..
coef( m.nw.justone )
# ..and so matches this..
weighted.mean( imp1$networth , imp1$wgt )

# ..but the SE due to sampling matches..
SE( m.nw.justone )
# ..the standard error due to sampling
s.m

# am i right?
all.equal( SE( m.nw.justone ) , s.m )


# for quantiles #

# run a svyquantile() command on just the first design..
q.nw.justone <- svyquantile( ~networth , scf.design$designs[[1]] , 0.5 , method = 'constant' , interval.type = 'quantile' )

# the coefficient is for only the first of five implicates..
coef( q.nw.justone )
# ..and so matches this..
wtd.quantile( imp1$networth , imp1$wgt , 0.5 )

# ..but the SE due to sampling is still just a dollar off..
SE( q.nw.justone )
# ..the standard error due to sampling
s.q


# prove you've got the combined standard error correct #

# run a svymean() command on the entire five implicates..
m.nw <- scf.MIcombine( with( scf.design , svymean( ~networth ) ) )
# note that the scf.MIcombine() function above does not come with dr. lumley's mitools package
# this function was specifically written for the survey of consumer finances and downloaded near the top of this here script
# for more detail about the regular MIcombine function, load the mitools package and type ?MIcombine into the console

# the main statistic (the coefficient)..
coef( m.nw )
# ..matches the overall mean shown at the top
all.equal( as.numeric( coef( m.nw ) ) , wm.nw )

# the standard error..
SE( m.nw )
# ..also matches
all.equal( as.numeric( SE( m.nw ) ) , cse.m )


# quantiles do not match precisely,
# but that's because there's at least nine ways to calculate them..
# (see ?quantile for a listing of the nine)
# ..and even more if they're weighted
# ..and even more if they're multiply-imputed

# so these statistics will be very close but not exact

# there is no theoretical basis for choosing one method over another.
# both the SAS methods (presented by FRB) and the r methods (presented here)
# are equally valid results.  except the r methods are reproducible and free ;)

# run a svyquantile() command on the entire five implicates..
q.nw <- scf.MIcombine( with( scf.design , svyquantile( ~networth , 0.5 , method = 'constant' , interval.type = 'quantile' ) ) )

# the main statistic (the coefficient)
coef( q.nw )
# ..versus the number provided by FRB
wq.nw

# the standard error..
SE( q.nw )
# ..versus the number provided by FRB
cse.q

# not bad, eh?


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
