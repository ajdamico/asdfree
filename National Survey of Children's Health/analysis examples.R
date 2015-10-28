# analyze survey data for free (http://asdfree.com) with the r language
# national survey of children's health
# 2011-2012 public use microdata

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NSCH/" )
# source_url( "https://raw.github.com/ajdamico/asdfree/master/National%20Survey%20of%20Children%27s%20Health/analysis%20examples.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# https://www.youtube.com/watch?v=JLt9JfaAxUg

# emily rowe
# eprowe@gmail.com

# anthony joseph damico
# ajdamico@gmail.com

# if you use this script for a project, please send me a note
# it's always nice to hear about how people are using this stuff

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#############################################################################################################################
# prior to running this replication script, the 2011-2012 public use microdata files must be loaded as R data files (.rda)  #
# on the local machine. running the "download all microdata.R" script will create this file for you.                        #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/asdfree/master/National%20Survey%20of%20Children%27s%20Health/download%20and%20import.R     #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will save a number of .rda files in C:/My Directory/NSCH/ (or the working directory was chosen)               #
#############################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# set your working directory.
# the NSCH 2011-2012 R data file (nsch 2012.rda) should have been stored in this folder.

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NSCH/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( c( 'mitools' , 'survey' ) )


library(mitools)	# allows analysis of multiply-imputed survey data
library(survey)		# load survey package (analyzes complex design surveys)


# load the 2011-2012 national survey of children's health into memory
load( "nsch 2012.rda" )


# memory conservation step #

# for machines with 4gb or less, it's necessary to subset the five implicate data frames to contain only
# the columns necessary for your particular analysis.  if running the code below generates a memory-related error,
# simply uncomment these lines and re-run the program:


# define which variables from the five imputed iterations to keep
vars.to.keep <- c( 'one' , 'povlevel_i' , 'state' , 'sample' , 'nschwt' , 'ageyr_child' , 'sex' , 'agepos4' )
# note: this throws out all other variables
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


# construct a multiply-imputed survey design object
# that includes the five data tables - imp1 through imp5
nsch.design <- 
	svydesign( 
		
		# do not use a clustering variable
		id = ~ 1 , 
		
		# use both `state` and `sample` columns as the stratification variables
		strata = ~ state + sample , 
		
		# use the main weight within each of the imp# objects
		weights = ~nschwt , 
		
		# read the data directly from the five implicates
		data = imputationList( list( imp1 , imp2 , imp3 , imp4 , imp5 ) )
		
	)

# this is the methodologically-correct way to analyze the national survey of children's health
# main disadvantage: requires code that's less intuitive for analysts familiar with 
# the r survey package's svymean( ~formula , design ) layout


# this object can also be examined by typing the name into the console..
nsch.design

# ..or querying attributes directly.  not much yet.
attributes( nsch.design )


# `nsch.design` is a weird critter.  it's actually five survey designs, mushed into one thing.
# when you run an analysis on the nsch.design object, you're actually running the same analysis
# on all five survey designs contained in the object -
# and then the MIcombine() function will lumps them all together
# to give you the correct statistics and error terms


# oh hey look at the first (of five) survey designs..
nsch.design$designs[[1]]

# ..and here's the first design's attributes,
# which look more like a standard svydesign() object
attributes( nsch.design$designs[[1]] )

# examine the degrees of freedom of that first survey design
degf( nsch.design$designs[[1]] )

# look at the attributes of the fifth (of five) data frames
attributes( nsch.design$designs[[5]] )

# examine the degrees of freedom
degf( nsch.design$designs[[5]] )

#####################
# required recoding #
#####################

# the `update` function does for complex sample survey designs
# (including multiply-imputed ones) what the `transform` function
# does for data.frame objects in the base R language.

# additional recoding examples are available in the `replication.R` script

nsch.design <-
	update(
		nsch.design ,
		
		# create an `only child` flag
		only.child = as.numeric( agepos4 == 1 ) ,
		# i'm an only child.  you already knew that, huh?
	
		# blank out missing responses in the `sex` variable
		sex = ifelse( sex %in% 1:2 , sex , NA ) ,
		# only 1 and 2 are valid responses,
		# everything else should be missing.
	
		# create a poverty category variable
		# that precisely matches the crosstabs shown by the table creator
		povcat = findInterval( povlevel_i , c( 1 , 2 , 6 , 8 ) )
		
	)


#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in nsch.design #
MIcombine( with( nsch.design , unwtd.count( ~one ) ) )

# broken out by state #
MIcombine( with( nsch.design , svyby( ~one , ~state , unwtd.count ) ) )


# count the weighted number of children in nsch.design #
MIcombine( with( nsch.design , svytotal( ~one ) ) )

# count the weighted number of children, broken out by state #
MIcombine( with( nsch.design , svyby( ~one , ~state , svytotal ) ) )



# calculate the mean of a linear variable #

# mean age of all children in the sample - nationwide
( mean.age <- MIcombine( with( nsch.design , svymean( ~ageyr_child ) ) ) )
# the command `mean.age <-` stores the results into a new object called `mean.age`
# that can be accessed later.  also, 
# surrounding the entire command with ( )
# prints whatever's being stored to the screen

# mean and standard error
mean.age

# variance
SE( mean.age )^2

# rse (relative standard error)
( SE( mean.age ) / coef( mean.age ) ) * 100

# confidence intervals
confint( mean.age , level = 0.95 )
confint( mean.age , level = 0.99 )


# average age
# by state
MIcombine( with( nsch.design , svyby( ~ageyr_child , ~state , svymean , na.rm = TRUE ) ) )


# calculate the distribution of a categorical variable #

# sex should be treated as a factor (categorical) variable
# instead of a numeric (linear) variable
# this update statement converts it.
# the svyby command below will not run without this
nsch.design <- update( sex = factor( sex ) , nsch.design )


# percent of children who are males vs. females - nationwide
MIcombine( with( nsch.design , svymean( ~sex , na.rm = TRUE ) ) )

# by state
MIcombine( with( nsch.design , svyby( ~sex , ~state , svymean , na.rm = TRUE ) ) )


# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum
# child age in the united states
MIcombine( 
	with( 
		nsch.design , 
		svyby( 
			~ageyr_child , 
			~one , 
			svyquantile , 
			c( 0 , .25 , .5 , .75 , 1 ) , 
			ci = TRUE 
		) 
	) 
)

# by state
MIcombine( 
	with( 
		nsch.design , 
		svyby( 
			~ageyr_child , 
			~state , 
			svyquantile , 
			c( 0 , .25 , .5 , .75 , 1 ) , 
			ci = TRUE 
		) 
	) 
)


######################
# subsetting example #
######################

# restrict the nsch.design object to
# only children only
nsch.brats <- subset( nsch.design , only.child %in% 1 )
# now any of the above commands can be re-run
# using nsch.brats object
# instead of the nsch.design object
# in order to analyze only children

# calculate the mean of a linear variable #

# average age - nationwide, 
# restricted to only children
MIcombine( with( nsch.brats , svymean( ~ageyr_child ) ) )

# remove this subset design to clear up memory
rm( nsch.brats )

# clear up RAM
gc()



##################
# export example #
##################

# calculate the percent of only children by state

# store the results into a new object, `only.children.by.state`
only.children.by.state <-
	MIcombine( 
		with( 
			nsch.design , 
			svyby( 
				~only.child , 
				~state , 
				svymean 
			) 
		) 
	)

# print the results to the screen 
only.children.by.state

# now you have the results saved into a new object of type "MIresult"
class( only.children.by.state )

# print only the statistics (coefficients) to the screen
# and save them into the object `ocbs.c`
( ocbs.c <- coef( only.children.by.state ) )

# print only the standard errors to the screen
# and save them into the object `ocbs.se`
( ocbs.se <- SE( only.children.by.state ) )

# this object cannot be coerced (converted) to a data frame.. 
# only.children.by.state <- data.frame( only.children.by.state ) # this command will throw an error
# instead, manually place the coefficients and standard errors into a data frame side-by-side
# note that the row numbers match the `state` values in this case..
ocbs <- data.frame( coef = ocbs.c , se = ocbs.se )

# (look at ocbs)
ocbs

# ..however, if they didn't, it might be useful to add a column containing those values.
ocbs <- 
	data.frame( 
		state = names( ocbs.c ) ,
		coef = ocbs.c ,
		se = ocbs.se
	)
	
# (look at ocbs again)
ocbs


# immediately export the results as a comma-separated value file
# into your current working directory..
write.csv( ocbs , "only children by state.csv" )

# ..or directly into a bar plot
barplot(
	ocbs[ , 2 ] ,
	main = "Percent Only Children by State" ,
	# manually label the the two highest numbers..
	names.arg = c( rep( NA , 7 ) , "DC" , rep( NA , 12 ) , 'MD' , rep( NA , 10 ) , 'NJ' , rep( NA , 17 ) , 'WV' , NA ) ,
	# ..and a few others, but really just for inside joking
	ylim = c( 0 , 0.4 )
)
# so, dc has the most only children.
# no surprise there.


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
