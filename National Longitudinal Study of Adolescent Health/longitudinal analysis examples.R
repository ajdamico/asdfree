# analyze survey data for free (http://asdfree.com) with the r language
# national longitudinal study of adolescent health
# waves 1 and 3 public use file longitudinal analysis example

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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###########################################################################################################################################
# prior to running this replication script, at least wave 1 of the addhealth public use microdata files must be loaded as R data          #
# files (.rda) on the local machine. running the "download and consolidate.R" script will create these files.                             #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/usgsd/master/National%20Longitudinal%20Study%20of%20Adolescent%20Health/download%20and%20consolidate.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will save a number of .rda files in C:/My Directory/AddHealth/ (or the working directory chosen)                            #
###########################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


#######################################################################
# Analyze the National Longitudinal Study of Adolescent Health with R #
#######################################################################


# set your working directory.
# the waves 1 and 3 AddHealth consolidated file should have been stored within this folder
# so if "wave 1 consolidated.rda" and "wave 3 consolidated.rda" exist in the directory "C:/My Directory/AddHealth/"
# then the working directory should be set to "C:/My Directory/AddHealth/"  easy.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/AddHealth/" )
# ..in order to set your current working directory


# remove the # in order to run this install.packages line only once
# install.packages( "survey" )

# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #


require(survey)  # load survey package (analyzes complex design surveys)


# by default, R will crash if a primary sampling unit (psu) has a single observation
# set R to produce conservative standard errors instead of crashing
# http://faculty.washington.edu/tlumley/survey/exmample-lonely.html
# by keeping this line uncommented:
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN


# the r data frame can be loaded directly from your local hard drive
load( "wave 1 consolidated.rda" )

# copy the wave 1 consolidated file over to `w1`
w1 <- cons

load( "wave 3 consolidated.rda" )

# copy the wave 3 consolidated file over to `w3`
w3 <- cons

# remove that `cons` object from memory just so there's no confusion
rm( cons )

# clear up RAM
gc()

# display the number of rows in both consolidated data sets
nrow( w1 )
nrow( w3 )

# display the first six records in the wave 1 data set
head( w1 )
# note that the data frame contains far too many variables to be viewed conveniently



# create a character vector that will be used to
# limit the first wave consolidated file
# to only the variables needed
w1.KeepVars <-
	c( 
		"aid" , 		# addhealth longitudinal unique id
		
		"bio_sex" ,		# sex
		
		"h1gh51"	,	# how many hours of sleep do you usually get
		
		"h1ed12"		# what was your grade in mathematics?
	)
	
# create a character vector that will be used to
# limit the third wave consolidated file
# to only the variables needed
w3.KeepVars <-
	c( 
		"aid" , 		# addhealth longitudinal unique id
		
		"gswgt3_2" , 	# wave 1 and 3 longitudinal analytic weight
		
		"cluster2" , 	# primary sampling units
		
		"h3gm1"			# ever bought lottery tickets like a scratch-off
	)


# limit the r data frame (cons) containing all variables
# to a severely-restricted r data frame containing only the variables
# specified in character vector w1.KeepVars and w3.KeepVars
x1 <- w1[ , w1.KeepVars ]
x3 <- w3[ , w3.KeepVars ]


# # # # # # # # # # # # #
# merge these two waves #

x <- merge( x1 , x3 )

# woah. done. awesome.  #
# # # # # # # # # # # # #

# check that the merge went through
nrow( x1 )
nrow( x3 )
nrow( x )
# the merged data frame `x` should be
# the same length as the smaller of `x1` and `x3`

# look at the first six records of
# the merged data.frame object
head( x )


# recode some stuff #

# the wave 1 section 5 codebook
# http://www.cpc.unc.edu/projects/addhealth/codebooks/wave1/inhome05.zip
# says the "what was your math grade" variable is
# 1=a, 2=b, 3=c, 4=d or lower, 5=didn't take, 6=wasn't graded, 96-99=NA
# so let's recode everything but 1-4 as missing
x[ !( x$h1ed12 %in% 1:4 ) , 'h1ed12' ] <- NA


# the wave 1 section 3 codebook
# http://www.cpc.unc.edu/projects/addhealth/codebooks/wave1/inhome03.zip
# says the "how many hours of sleep do you usually get" variable is
# has missings for 96, 98, and 99
# so let's recode those to missing
x[ ( x$h1gh51 %in% c( 96 , 98 , 99 ) ) , 'h1gh51' ] <- NA


# the wave 3 section 32 codebook
# http://www.cpc.unc.edu/projects/addhealth/codebooks/wave3/sect32.zip
# says that the "ever bought lottery tickets" is zero/one
# but there are 6s, 8s, and 9s that are refused/dk/na
x[ !( x$h3gm1 %in% 0:1 ) , 'h3gm1' ] <- NA


# end of recodes #


#################################################
# survey design for taylor-series linearization #
#################################################

# create a survey design object (z) with AddHealth design information
y <- 
	svydesign( 
		id = ~cluster2 , 
		data = x , 
		weights = ~gswgt3_2 , 
		nest = TRUE 
	)
	

#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in the wave 1 national longitudinal study of adolescent health data set #

# the nrow function which works on both data frame objects..
class( x )
# ..and survey design objects
class( y )


# notice that the original data frame contains the same number of records as..
nrow( x )

# ..the survey object
nrow( y )


# add a new variable 'one' that simply has the number 1 for each record #
# and can be used to calculate unweighted and weighted population sizes #

y <-
	update( 
		one = 1 ,
		y
	)

	
#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in atus #
# broken out by sex #

svyby(
	~one ,
	~bio_sex ,
	y ,
	unwtd.count
)



# count the weighted number of middle-and-high-school-students-in-1995 in addhealth #

# the number of kids enrolled in 7th-12 grade
# in the united states in 1995
svytotal(
	~one ,
	y
)


# by sex
svyby(
	~one ,
	~bio_sex ,
	y ,
	svytotal
)


# calculate the mean of a linear variable #

# average hours of sleep per night
svymean(
	~h1gh51 ,
	design = y ,
	na.rm = TRUE
)

# ..and here's the same calculation, but broken down by sex
svyby(
	~h1gh51 ,
	~bio_sex ,
	design = y ,
	svymean ,
	na.rm = TRUE
)


# calculate the distribution of a categorical variable #

# the column h1ed12 (grade in mathematics class)
# should be treated as a factor (categorical) variable
# instead of a numeric (linear) variable
# this update statement converts it.
y <-
	update(
		h1ed12 = factor( h1ed12 ) ,
		y
	)


# percent earning a's, b's, c's, or d's or lower
# in their mathematics class during wave 1
svymean(
	~h1ed12 ,
	design = y ,
	na.rm = TRUE
)

# ..and here's the same calculation, but broken down by sex
svyby(
	~h1ed12 ,
	~bio_sex ,
	design = y ,
	svymean ,
	na.rm = TRUE
)

# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum
# average sleep hours per night
svyquantile(
	~h1gh51 ,
	design = y ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	na.rm = TRUE
)

# by sex
svyby(
	~h1gh51 ,
	~bio_sex ,
	design = y ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	ci = T ,
	na.rm = TRUE
)

######################
# subsetting example #
######################

# restrict the y object to
# only individuals who had ever gambled
# at the point of the third wave
# (about eight years later)
y.gambler <-
	subset(
		y ,
		h3gm1 %in% 1
	)
# now any of the above commands can be re-run
# using y.gambler object
# instead of the y object
# in order to analyze future gamblers only

# calculate the mean of a linear variable #

# among respondents who gambled at least once
# in their early adulthood,
# average hours of sleep per night
svymean(
	~h1gh51 ,
	design = y.gambler ,
	na.rm = TRUE
)

# ..and here's the same calculation, but broken down by sex
svyby(
	~h1gh51 ,
	~bio_sex ,
	design = y.gambler ,
	svymean ,
	na.rm = TRUE
)

###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by sex

# store the results into a new object

any.future.gambling.by.prior.math.grade <-
	svyby(
		~h3gm1 ,
		~h1ed12 ,
		design = y ,
		svymean ,
		na.rm = TRUE
	)

# print the results to the screen
any.future.gambling.by.prior.math.grade

# now you have the results saved into a new object of type "svyby"
class( any.future.gambling.by.prior.math.grade )

# print only the statistics (coefficients) to the screen
coef( any.future.gambling.by.prior.math.grade )

# print only the standard errors to the screen
SE( any.future.gambling.by.prior.math.grade )

# this object can be coerced (converted) to a data frame..
any.future.gambling.by.prior.math.grade <- data.frame( any.future.gambling.by.prior.math.grade )

# ..and then immediately exported as a comma-separated value file
# into your current working directory..
write.csv( 
	any.future.gambling.by.prior.math.grade , 
	"any future gambling by prior math grade.csv" 
)

# ..or directly made into a bar plot
barplot(
	any.future.gambling.by.prior.math.grade[ , 2 ] ,
	main = "Percent Ever Gambled By Grade in Math About Eight Years Ago" ,
	names.arg = c( "A" , "B" , "C" , "D or Lower") ,
	ylim = c( 0 , .7 )
)

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
