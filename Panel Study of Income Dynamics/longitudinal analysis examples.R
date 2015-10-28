# analyze survey data for free (http://asdfree.com) with the r language
# panel study of income dynamics
# individual cross-year and two family files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/PSID/" )
# source_url( "https://raw.github.com/ajdamico/asdfree/master/Panel%20Study%20of%20Income%20Dynamics/longitudinal%20analysis%20examples.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# note that the tutorials posted on the panel study of income dynamics website are out-of-date.
# the analysis examples below use tutorial #3 as a guide, but to not match those published numbers exactly,
# because since that tutorial was posted, they added a bunch of records and modified a bunch of values.
# even if you limit the data set to the 1,633 matching records (as they suggest), you can see that they've made changes
# in the actual values for some of the records of those remaining 1,633, so your answers still will not match.
# in short: you'll have to trust that my modern version of their tutorials is accurate.
# tutorial #3 - http://psidonline.isr.umich.edu/Guide/tutorials/tutorial3/balanced_panel.pdf
# psid e-mail - https://raw.github.com/ajdamico/asdfree/master/Panel%20Study%20of%20Income%20Dynamics/different%20record%20counts%20in%20tutorial%203.pdf?raw=TRUE
# hope that works for you. if it doesn't, e-mail psidhelp@umich.edu and ask for their tutorials to be updated. ;)
# and yes, tutorial #1 is more current, but it doesn't use the panel.  using the panel is the whole point of this survey.


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



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################
# prior to running this analysis script, the umich individual cross-year file must be downloaded to your local disk #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/asdfree/master/Panel%20Study%20of%20Income%20Dynamics/download%20all%20microdata.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will place all necessary psid files whever you specified, probably the "C:/My Directory/PSID/" folder #
#####################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# set your working directory.
# the R data file (.rda) should have been stored within this folder
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PSID/" )
# ..in order to set your current working directory


# remove the # in order to run this install.packages line only once
# install.packages( "survey" )


library(survey)		# load survey package (analyzes complex design surveys)

# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN


# load the individual cross-year file
load( "ind.rda" )

# limit the file to only the variables needed
ind.KeepVars <-
	c( 
		'one' ,			# column with all ones
		'er30001' , 	# 1968 interview number
		'er30002' , 	# 1968 person number
		'er31997' ,		# primary sampling unit variable
		'er31996' ,		# stratification variable
		'er33201' ,		# sequence number, 1995
		'er33501' , 	# sequence number, 1999
		'er33202' ,		# household head, 1995
		'er33502' , 	# household head, 1999
		'er32000' ,		# sex
		'er33211' ,		# employment status in 1995
		'er33504' ,		# age in 19999
		'er33203' ,		# household relationship status, 1995
		'er33503' ,		# household relationship status, 1999
		'er33222' ,		# current school level
		'er33227' ,		# highest school level completed
		'er33275' ,		# 1995 longitudinal weight
		'er33546'		# 1999 longitudinal weight
	)

	
# create a "skinny"	data.frame object that only contains the
# columns you need for this analysis,
# specified in the KeepVars character vector
w <- ind[ , ind.KeepVars ]

# remove the original data.frame object then free up memory
rm( ind ) ; gc()

# repeat this with the 1995 file
f95.KeepVars <-
	c( 
		'er5002' , 		# interview number
		'er6980' ,		# labor income of head
		'er6984' ,		# labor income of wife
		'er5067' ,		# employment status of head
		'er5561'		# employment status of wife
		
	)

load( "fam1995.rda" )
f95 <- fam1995[ , f95.KeepVars ]
rm( fam1995 ) ; gc()

# repeat this with the 1999 file
f99.KeepVars <-
	c( 
		'er13002' , 	# interview number
		'er16463' ,		# labor income of head
		'er16465'		# labor income of wife
	)

load( "fam1999.rda" )
f99 <- fam1999[ , f99.KeepVars ]
rm( fam1999 ) ; gc()


# merge the 1995 family and individual-level files,
# using the 1995 interview number field available in both tables
z95 <- merge( f95 , w , by.x = 'er5002' , by.y = 'er33201')

# merge the 1999 family and individual-level files,
# using the 1999 interview number field available in both tables
z99 <- merge( f99 , w , by.x = 'er13002' , by.y = 'er33501' )

# merge these two timepoints together,
# regardless of a match between the two timepoints
x <- merge( z95 , z99 , all = TRUE )

# count the unweighted number of records
nrow( x )

# now you've got all necessary information merged on
# from both points-in-time.  at this point, choose
# what you want the data set to generalize to.
# how about "noninstitutionalized americans in 1995?"
# if that's the case, use only records with a 1995 weight:
x <- subset( x , er33275 > 0 )


# perform all recodes on the `x` table #

# create a new female income variable for 1995 and 1999
# labor income of head (if female head) or head's wife
x$fem_inc_95 <- ifelse( x$er33203 == 10 , x$er6980 , x$er6984 )
x$fem_inc_99 <- ifelse( x$er33503 == 10 , x$er16463 , x$er16465 )

# create a work status in 1995 variable
x$worker <-
	ifelse( x$er33211 %in% c( 0 , 9 ) , NA ,
	ifelse( x$er33211 %in% 1 , 1 , 0 ) )

# end of all recodes #

# create survey design object with PSID design information
y <- 
	svydesign( 
		~er31997 , 
		strata = ~er31996 , 
		data = x , 
		weights = ~er33275 , 
		nest = TRUE 
	)


# since the power of the panel study of income dynamics is its longitudinal design,
# the above survey objects will be used throughout these analysis commands..




# start of cheating detour #

# # only use the commands inside this cheating detour if you're interested in getting closer to the 1,633 records described in
# # https://raw.github.com/ajdamico/asdfree/master/Panel%20Study%20of%20Income%20Dynamics/different%20record%20counts%20in%20tutorial%203.pdf?raw=TRUE

# # pull the excel file

# # if you need help installing or loading the `gdata` package,
# # check out this two-minute video: http://www.screenr.com/QiN8

# install.packages( "gdata" )
# library(gdata)
# xl <- 
	# read.xls( 
		# "http://psidonline.isr.umich.edu/Guide/tutorials/tutorial3/balancedpanel.xls" ,
		# sheet = 2
	# )

# # keep only the first two columns,
# # which contain the 1968 interview and person numbers
# ids.to.keep <- xl[ , 1:2 ]
# ids.to.keep <- apply( ids.to.keep , 1 , paste , collapse = " " )

# # create a matching field in the main data file
# y <- update( y , idper = paste( er30001 , er30002 ) )

# # throw out all records not contained in that excel file's first two columns.
# y <- subset( y , idper %in% ids.to.keep )

# end of cheating detour #


# hold on tight. #

##############################
# longitudinal data analysis #


# construct a subset of your original survey design object
# using all of the criteria discussed in the tutorial #3 document
# http://psidonline.isr.umich.edu/Guide/tutorials/tutorial3/balanced_panel.pdf
z <-
	subset(
		y ,
	
		# females only
		er32000 == 2 &
		
		# household head husband or wife head only
		er33502 < 21 &
		
		# age under 62 as of 1999
		er33504 < 62 &
		
		# age over 27 as of 1999
		er33504 > 27 &
		
		# head of household, legal wife, or wife in 1995
		er33203 %in% c( 10 , 20 , 22 ) &
		
		# head of household, legal wife, or wife in 1999
		er33503 %in% c( 10 , 20 , 22 ) &
		
		# household head not housekeeping in 1995
		er5067 != 6 &
		
		# household wife not housekeeping in 1995
		er5561 != 6  &
		
		# answered the education section in 1995
		er33222 < 93 & er33227 < 93 &
		
		# non-zero 1995 longitudinal weight
		er33275 > 0 &
		
		# non-zero 1999 longitudinal weight
		er33546 > 0

	)

	
# among nonzero records (hence the subset),
# what are the income quintiles for this cohort of females in 1995?
cutpoints.95 <- 
	svyquantile( 
		~fem_inc_95 , 
		subset( z , fem_inc_95 > 0 ) , 
		seq( 0 , 0.8 , .2 ) ,
		method = 'constant'
	)
	
# among nonzero records (hence the subset),
# what are the income quintiles for the same cohort of females in 1999?
cutpoints.99 <- 
	svyquantile( 
		~fem_inc_99 , 
		subset( z , fem_inc_99 > 0 ) , 
		seq( 0 , 0.8 , .2 ) ,
		method = 'constant'
	)

# update the svydesign object `z` with, essentially, two more recodes.
# this simply creates two new columns in the data set, broken at the .95 and .99 cutpoints
z <-
	update(
		z ,
		incqt_95 = findInterval( fem_inc_95 , cutpoints.95 ) ,
		incqt_99 = findInterval( fem_inc_99 , cutpoints.99 )
	)
	

# finally, finally, reproduce this table:
# http://psidonline.isr.umich.edu/Guide/tutorials/tutorial3/balancedpanel.xls#table
svyby( ~factor( incqt_99 ) , ~incqt_95 , z , svymean )
# the distribution of 1999 income quintiles, broken down by 1995 income quintiles.
# note: since the survey was actually collected one year after the income year,
# these income quintiles are actually for 1994 and 1998.

	
# end of longitudinal data analysis #
#####################################


#####################
# analysis examples #
#####################

# quickly convert two numeric variables to factors
y <- 
	update( 
		y , 
		er32000 = factor( er32000 ) ,
		worker = factor( worker )
	)

# now go back to the pre-subsetted object with the 1995 weights called `y`

# count the total (unweighted) number of records in the 1995 psid #
# broken out by sex #

svyby(
	~one ,
	~er32000 ,
	y ,
	unwtd.count
)

# calculate the mean of a linear variable #

# average income of the head of household
svymean(
	~er6980 ,
	design = y ,
	na.rm = TRUE
)

# by work status
svyby(
	~er6980 ,
	~worker ,
	design = y ,
	svymean ,
	na.rm = TRUE
)


# calculate the distribution of a categorical variable #

# percent male
svymean(
	~er32000 ,
	design = y ,
	na.rm = TRUE
)

# by work status
svyby(
	~er32000 ,
	~worker ,
	design = y ,
	svymean ,
	na.rm = TRUE 
)

# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum
# income of head of household
svyquantile(
	~er6980 ,
	design = y ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	na.rm = TRUE
)

# by work status
svyby(
	~er6980 ,
	~worker ,
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
# females only
y.female <-
	subset(
		y ,
		er32000 %in% 2
	)
# now any of the above commands can be re-run
# using y.female object
# instead of the y object
# in order to analyze females only

# calculate the mean of a linear variable #

# income of head of household
svymean(
	~er6980 ,
	design = y.female ,
	na.rm = TRUE
)
# exciting special note: the calculation above shows the head-of-household income
# subsetted to only female records..but if a female lives with a male head-of-household, it'll show that male head-of-household's income instead of her's.  so you gotta be careful about what columns of data apply to who.


###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by sex

# store the results into a new object

work.stat.by.sex <-
	svyby(
		~worker ,
		~er32000 ,
		design = subset( y , er33227 < 93 ) ,
		svymean ,
		na.rm = TRUE
	)

# print the results to the screen
work.stat.by.sex

# now you have the results saved into a new object of type "svyby"
class( work.stat.by.sex )

# print only the statistics (coefficients) to the screen
coef( work.stat.by.sex  )

# print only the standard errors to the screen
SE( work.stat.by.sex  )

# this object can be coerced (converted) to a data frame..
work.stat.by.sex <- data.frame( work.stat.by.sex )

# ..and then immediately exported as a comma-separated value file
# into your current working directory
write.csv( work.stat.by.sex , "work stat by sex.csv" )

# ..or trimmed to only contain the values you need.
# here's the "worker" rate by sex,
# with accompanying standard errors
# keeping only the first, third, and fifth columns
work.stat.by.sex <-
	work.stat.by.sex[ , c( "er32000" , "worker1" , "se.worker1" ) ]


# print the new results to the screen
work.stat.by.sex

# this can also be exported as a comma-separated value file
# into your current working directory
write.csv( work.stat.by.sex , "trimmed work stat by sex.csv" )

# ..or directly made into a bar plot
barplot(
	work.stat.by.sex[ , 2 ] ,
	main = "Percent Working in 1995" ,
	names.arg = c( "Male" , "Female" ) ,
	ylim = c( 0 , 1 )
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
