
# the institute for digital research and education at ucla
# hosts a very readable explanation of replicate weights,
# how they protect confidentiality, and why they're generally awesome
# http://www.ats.ucla.edu/stat/stata/library/replicate_weights.htm


# load the r survey package
library(survey)


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

###########################################
# # # # # # # # # # # # # # # # # # # # # #
# part two. share these replicate weights #
# # # # # # # # # # # # # # # # # # # # # #
###########################################

# now share these weights with your users.    #
# # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# step one: remove the confidential fields from your data #
# and tack on the replicate weight columns created above. #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


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
# no confidential information for users
y <- cbind( x , your.replicate.weights )

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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# step two: determine the `svrepdesign` specification to  #
# match the survey object above, but without cluster info #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


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



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# step three: confirm this new replication survey object  #
# matches the standard errors derived from as.svrepdesign #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	
# this `z` object can now be analyzed
# and will match the `api.jkn` shown above
svymean( ~ api99 + api00 , z )
svymean( ~ api99 + api00 , api.jkn )

svyby( ~ api99 + api00 , ~ awards , z , svymean )
svyby( ~ api99 + api00 , ~ awards , api.jkn , svymean )
