# analyze survey data for free (http://asdfree.com) with the r language
# how to create de-identified replicate weights
# in less than ten steps

# anthony joseph damico
# ajdamico@gmail.com


# the institute for digital research and education at ucla
# hosts a very readable explanation of replicate weights,
# how they protect confidentiality, and why they're generally awesome
# http://www.ats.ucla.edu/stat/stata/library/replicate_weights.htm



# remove the # in order to run this install.packages line only once
# install.packages( c( "survey" , "sdcMicro" ) )


# load the r survey package
library(survey)

# load the sdcMicro package
library(sdcMicro)


# load some sample complex sample survey data
data(api)


# look at the first six records of the `apistrat` data.frame object
# so you have a sense of what you're working with in this example
# this particular example is student performance in california schools
# http://r-survey.r-forge.r-project.org/survey/html/api.html
head( apistrat )


###########################################
# # # # # # # # # # # # # # # # # # # # # #
# part one.  create the replicate weights #
# # # # # # # # # # # # # # # # # # # # # #
###########################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# step one: construct the taylor-series linearized design #
# that you use on your internal, confidential microdata   #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# there are many permutations of linearized designs.
# you can find well-documented examples of tsl design setups
# by searching for the text `svydesign` here:
# https://github.com/ajdamico/usgsd/search?q=svydesign&ref=cmdform


# does your tsl design have a strata argument? #

# this design does not have a `strata=` parameter
api.tsl.without.strata <-
	svydesign(
		id = ~dnum , 
		data = apistrat , 
		weights = ~pw
	)

# this design does have a `strata=` parameter
api.tsl.with.strata <- 
	svydesign(
		id = ~dnum , 
		strata = ~stype , 
		data = apistrat , 
		weights = ~pw ,
		nest = TRUE
	)


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# step two: convert this taylor-series linearized design  #
# to one of a few choices of replication-based designs    #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# for unstratified designs,
# use a "jackknife delete one" method
api.jk1 <- 
	as.svrepdesign( 
		api.tsl.without.strata , 
		type = "JK1" , 
		fay.rho = 0.5 ,
		mse = TRUE ,
		compress = FALSE # note: compressed replicate weights require less RAM but complicate the weight-extraction in step three
	)


# for stratified designs,
# you might first attempt to use a
# balanced repeated replication method
# with a fay's adjustment
# (this is the most common setup from the united states census bureau)
api.fay <- 
	as.svrepdesign( 
		api.tsl.with.strata , 
		type = "Fay" , 
		fay.rho = 0.5 ,
		mse = TRUE ,
		compress = FALSE # note: compressed replicate weights require less RAM but complicate the weight-extraction in step three
	)

# however, if the sampling plan contains an
# odd number of clusters within any stratum
# you will hit this error
# Error in brrweights(design$strata[, 1], design$cluster[, 1], ..., fay.rho = fay.rho,  : 
  # Can't split with odd numbers of PSUs in a stratum


# for stratified designs with an
# odd number of clusters in any stratum,
# use a "jackknife delete n" method
api.jkn <- 
	as.svrepdesign( 
		api.tsl.with.strata , 
		type = "JKn" ,
		mse = TRUE ,
		compress = FALSE # note: compressed replicate weights require less RAM but complicate the weight-extraction in step three
	)


# now you have a matrix of replicate weights
# stored in your replication-based survey-design


# the purpose of this exercise is to produce comparable
# variance estimates without compromising confidentiality

# therefore, run a few standard error calculations
# using the original linearized designs,
# compared to the newly-created jackknife design

# calculate the mean 1999 and 2000 academic performance index scores
# using the original stratified taylor-series design..
svymean( ~ api99 + api00 , api.tsl.with.strata )
# ..and the newly-created jackknife replication-based design
svymean( ~ api99 + api00 , api.jkn )
# the standard errors for these estimates are nearly identical #

# run the same commands as above, broken down by award program eligibility
svyby( ~ api99 + api00 , ~ awards , api.tsl.with.strata , svymean )
svyby( ~ api99 + api00 , ~ awards , api.jkn , svymean )

# in each case, the replication-based design
# (that we created off of the linearized design)
# produced a comparable variance estimate



# # # # # # # # # # # # # # # # # # # # # # # # #
# step three: extract the replication weights   #
# from your newly created survey design object  #
# # # # # # # # # # # # # # # # # # # # # # # # #

# note that this example shows how to extract
# the weights from the `api.jkn` survey object
# however, this method would be identical
# for the `api.jk1` and `api.fay` objects
# displayed above as well
# despite `api.fay` throwing an error,
# because of an uneven number of clusters within strata


# look at your survey design
api.jkn

# look at the contents of your replication-based survey design
names( api.jkn )
	
# look at the first six replicate weight records within your survey design
head( api.jkn$repweights )
# note that these weights are not *combined* by default
# in other words, they still need to be multiplied by the original weight

# you can confirm this by looking at the flag that indicates:
# "have replicate weights been combined?"
api.jkn$combined.weights
# no.  they have not been combined


# therefore, these replication weights are `uncombined`
# and will need to be analyzed by the user as such
your.replicate.weights <- data.frame( unclass( api.jkn$repweights ) )



# # # # # # # # # # # # # # # # # # # # # # # #
# you've created the set of replicate-weights #

#############################################
# # # # # # # # # # # # # # # # # # # # # # #
# part two. mask the strata from evil users #
# # # # # # # # # # # # # # # # # # # # # # #
#############################################

# now prevent users from reidentifying strata #
# # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# step four: understand how a malicious user might easily #
# identify clustering variables on un-obfuscated data     #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# start with the replicate weights object from the script
transposed.rw <- t( your.replicate.weights )

# the first record of apistrat has dnum==401 and stype=='E'

# going back to the original microdata set,
# eleven records are in this cluster x stratum
which( apistrat$dnum == 401 & apistrat$stype == 'E' )

# without massaging your replicate weights at all,
# a malicious user could easily view the correlations
# between each record's replicate weights
# in order to determine what other records
# land in the same cluster x strata

# for example, here are all replicate-weight records that
# perfectly (after rounding) correlate with 
# the first record.
which( round( cor( transposed.rw )[ 1 , ] ) == 1 )

# same numbers!

# (wikipedia has a great definition: http://en.wikipedia.org/wiki/Obfuscation)
# if you do not obfuscate your data, a malicious user could
# identify unique clusters and strata even if only given replicate weights


# # # # # # # # # # # # # # # #
# step five: BRING THE NOISE  #
# # # # # # # # # # # # # # # #

# set a random seed.  this allows you to
# go back to this code and reproduce the
# exact same results in the future.

# the following steps include a random process
# setting a seed enforces the same random process every time
sum( utf8ToInt( "anthony is cool" ) )
# my current favorite number is 1482, so let's go with that.
set.seed( 1482 )


# figure out how much noise to add.
noisy.transposed.rw <- addNoise( transposed.rw , noise = 1 )$xm


# remember, on the original replicate weight objects,
# the correlations between the first record and
# other records within the same clusters and strata
# were perfect.
which( sapply( cor( transposed.rw )[ 1 , ] , function( z ) isTRUE( all.equal( z , 1 ) ) ) )

# run the same test on noisified weights
which( sapply( cor( noisy.transposed.rw )[ 1 , ] , function( z ) isTRUE( all.equal( z , 1 ) ) ) )
# and suddenly none of the other records are perfectly correlated


# but even moderately correlations might allow evildoers
# to identify clusters and strata
# these records have a 0.1 or higher correlation coefficient
which( cor( noisy.transposed.rw )[ 1 , ] > 0.1 )
# these records have a 0.2 or higher correlation coefficient
which( cor( noisy.transposed.rw )[ 1 , ] > 0.2 )
# whoops.  we did not add enough noise.
# records in the same cluster x strata still have
# too high of a correlation coefficient,
# relative to other records


# okay.  this will make a big difference
# on the size of the standard errors that
# your users will actually see.

# make a clutch decision:
# how much noise can you tolerate?
# hmncyt <- 1
hmncyt <- 3
# hmncyt <- 10

# you need to run this script a few times
# because the size of your standard errors
# are going to change, depending on your data set.


# essentially, choose the lowest noise value
# that does not lead you to uncomfortable levels
# of correlation within cluster/strata
# in your replicate weights columns


# crank up the random noise percentage to three
noisy.transposed.rw <- addNoise( transposed.rw , noise = hmncyt )$xm
# and suddenly..

# records 29, 73 and 158 have a correlation coefficient
# that's greater than zero point two.
which( cor( noisy.transposed.rw )[ 1 , ] > 0.2 )

# and of those, only record #29 is in the same cluster x strata
intersect(
	which( cor( noisy.transposed.rw )[ 1 , ] > 0.2 ) ,
	which( round( cor( transposed.rw )[ 1 , ] ) == 1 )
)
# that's awesome, because you have two false-positives here.
# the "73" and "158" will throw off a malicious user.


# these records have a 0.1 or higher correlation coefficient
which( cor( noisy.transposed.rw )[ 1 , ] > 0.1 )
# and that looks very good.
# because less than half of those records
# are actually in the same cluster x strata
intersect(
	which( cor( noisy.transposed.rw )[ 1 , ] > 0.1 ) ,
	which( round( cor( transposed.rw )[ 1 , ] ) == 1 )
)
# and there are lots of other records with high correlations (false positives)
# that in fact are not in the same strata.  great.  perf.  magnifique!

# this object `noisy.transposed.rw` is the set of replicate weights
# that you might now feel comfortable disclosing to your users.

# bee tee dubs

# you should un-transpose the weights rightaboutnow
noisy.rw <- t( noisy.transposed.rw )


# # # # # # # # # # # # # # # # # # # # #
# step six: check with your legal dept. #
# # # # # # # # # # # # # # # # # # # # #

# brilliant malicious users might still be able to identify certain records
# if they work really really really hard and have access to other information
# included in your survey microdata set.

# for example:
# if your technical documentation says that memphis was one of your sampled clusters, and
# if your microdata does have a state identifier, and
# if the content of your survey was about barbeque consumption

# it's possible that no amount of masking, obfuscating, massaging, noising, whathaveyouing
# will prevent malicious users from determining the geography of some of the records
# included in your public use file.  so don't mindlessly follow this example.

# consider exactly what you're disclosing, consider how someone might use it improperly.


# # # # # # # # # # # # # # # # # # # # # # #
# you've protected cluster confidentiality  #

#############################################
# # # # # # # # # # # # # # # # # # # # # # #
# part three. share these replicate weights #
# # # # # # # # # # # # # # # # # # # # # # #
#############################################

# now share these weights with your users.  #
# # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# step seven: remove the confidential fields from your data #
# and tack on the replicate weight columns created above.   #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# go back to our original data.frame object `apistrat`
# and store that entire table into `x`
x <- apistrat
# remove the columns that were deemed too confidential to release
x$dnum <- x$stype <- NULL
# in other words, delete the cluster and strata variables
# from this data.frame object so you have a "safe-for-the-public" data set


# look at the first six records
# to confirm they have been removed
head( x )

# merge on the replicate weight data.frame
# that we just created, which contains
# obfuscated-confidential information for users
y <- cbind( x , noisy.rw )

# look at the first six records
# to confirm the weights have been tacked on
head( y )
# the replicate weights are now stored
# as `X1` through `X162`

# this data.frame object `y`
# contains all of the information that
# a user needs to correctly calculate a
# variance, standard error, confidence interval

# uncomment this line to
# export `y` to a csv file
# write.csv( y , "C:/My Directory/your microdata.csv" )
# this csv file contains your full microdata set,
# except for the cluster and strata variables
# that you had determined to be confidential information


# in other words, now you've got a public-use file (puf)
# that no longer contains identifiable geographic information


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# step eight: determine the `svrepdesign` specification to  #
# match the survey object above, but without cluster info   #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# once users have a copy of this de-identified
# microdata file, they will need the
# replication-based complex sample design


# there are many permutations of replication-based designs.
# you can find well-documented examples of replicate weighted design setups
# by searching for the text `svrepdesign` here:
# https://github.com/ajdamico/usgsd/search?q=svrepdesign&type=Code


# for the object `y` built above,
# construct the replication-based
# "jackknife delete n" method
# complex sample survey design object
z <-
	svrepdesign(
		data = y ,
		type = "JKn" ,
		repweights = "X[1-9]+" ,
		weights = ~pw ,
		scale = 1 ,
		combined.weights = FALSE ,
		mse = TRUE
	)
# is it giving you a warning about calculating the rscales by itself?
# good.  then you're doing right by me.


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# step nine: confirm this new replication survey object   #
# matches the standard errors derived from as.svrepdesign #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# this `z` object can now be analyzed
# and the statistics but not the standard errors
# will match the `api.jkn` shown above.
svymean( ~ api99 + api00 , z )
svymean( ~ api99 + api00 , api.jkn )

svyby( ~ api99 + api00 , ~ awards , z , svymean )
svyby( ~ api99 + api00 , ~ awards , api.jkn , svymean )
# see how the standard errors have a-little-more-than-doubled?
# that's because we had to BRING THE NOISE to the replicate weights

# if you re-run this script but lower the value of `hmncyt`
# your standard errors will *decrease* and get closer to
# what they actually are when you have the confidential information.

# that's the trade-off.  re-run this entire script but set `hmncyt <- 0`
# and you'll see some almost-perfect standard errors..
# but doing that would allow malicious users to identify clusters easily

# then re-run it again and set `hmncyt <- 10` and suddenly
# no way in hell can a malicious user identify clustering information
# but your standard errors (and subsequent confidence intervals) are ginormous

# obfuscating your replicate weights is going to make it harder for users
# to detect statistically significant differences when analyzing your microdata.
# no way around that.
# just do your best to minimize the amount of obfuscation.

# dooooo it.  public use microdata are an indisputable good.
