setwd( "C:/My Directory/SCF/" )

require(mitools)
require(survey)
require(foreign)
require(Hmisc)
require(RCurl)

load( "scf2010.rda" )


#######################################################
# function to download scripts directly from github.com
# http://tonybreyal.wordpress.com/2011/11/24/source_https-sourcing-an-r-script-from-github/
source_https <- function(url, ...) {
  # load package
  require(RCurl)

  # parse and evaluate each .R script
  sapply(c(url, ...), function(u) {
    eval(parse(text = getURL(u, followlocation = TRUE, cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl"))), envir = .GlobalEnv)
  })
}
#######################################################


# load two svyttest functions (one to conduct a df-adjusted t-test and one to conduct a multiply-imputed t-test)
source_https( "https://raw.github.com/ajdamico/usgsd/master/Survey%20of%20Consumer%20Finances/scf.MIcombine.R" )
# now that this function has been loaded into r, you can view its source code by uncommenting the line below
# scf.MIcombine



# # # # # # # # # # # # # # # # # # # # # #
# part one: replicate statistics          #
# provided by the federal reserve board   #
# using just some simple base r functions #
# to prove you understand this data       #
# # # # # # # # # # # # # # # # # # # # # #


stacked.networths <- c( imp1$networth , imp2$networth , imp3$networth , imp4$networth , imp5$networth )

stacked.weights <- c( imp1$wgt , imp2$wgt , imp3$wgt , imp4$wgt , imp5$wgt )

# replicate the mean and median #

# reproduced number: #
# mean net worth
wm.nw <- weighted.mean( stacked.networths , stacked.weights )

# reproduced number: #
# median net worth
wq.nw <- wtd.quantile( stacked.networths , stacked.weights , 0.5 )

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
# way as all the other data sets on usgsd #
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

# the coefficient is wrong..
coef( m.nw.justone )
# ..but the SE due to sampling matches..
SE( m.nw.justone )
# ..the standard error due to sampling
s.m

# am i right?
all.equal( SE( m.nw.justone ) , s.m )


# for quantiles #

# run a svyquantile() command on just the first design..
q.nw.justone <- svyquantile( ~networth , scf.design$designs[[1]] , 0.5 )

# the coefficient is wrong..
coef( q.nw.justone )
# ..but the SE due to sampling is still just a dollar off..
SE( q.nw.justone )
# ..the standard error due to sampling
s.q


# prove you've got the combined standard error correct #

# run a svymean() command on the entire five implicates..
m.nw <- scf.MIcombine( with( scf.design , svymean( ~networth ) ) )

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
q.nw <- scf.MIcombine( with( scf.design , svyquantile( ~networth , 0.5 ) ) )

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
