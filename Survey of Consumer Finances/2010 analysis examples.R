# analyze us government survey data with the r language
# survey of consumer finances
# 2010 public use microdata

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



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#############################################################################################################################
# prior to running this replication script, the 2010 scf public use microdata files must be loaded as R data files (.rda)   #
# on the local machine. running the "1989-2010 download all microdata.R" script will create this file for you.              #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/usgsd/blob/master/Survey%20of%20Consumer%20Finances/1989-2010%20download%20all%20microdata.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will save a number of .rda files in C:/My Directory/SCF/ (or the working directory was chosen)                #
#############################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# set your working directory.
# the SCF 2010 R data file (scf2010.rda) should have been stored in this folder.

setwd( "C:/My Directory/SCF/" )


# remove the # in order to run this install.packages line only once
# install.packages( c( 'mitools' , 'survey' , 'RCurl' ) )


require(mitools)	# allows analysis of multiply-imputed survey data
require(survey)		# load survey package (analyzes complex design surveys)
require(RCurl)		# load RCurl package (downloads files from the web)
require(foreign) 	# load foreign package (converts data files into R)


# load the 2010 survey of consumer finances into memory
load( "scf2010.rda" )


# memory conservation step #

# for machines with 4gb or less, it's necessary to subset the five implicate data frames to contain only
# the columns necessary for your particular analysis.  if running the code below generates a memory-related error,
# simply uncomment these lines and re-run the program:


# define which variables from the five imputed iterations to keep
vars.to.keep <- c( 'y1' , 'yy1' , 'wgt' , 'one' , 'networth' , 'checking' , 'hdebt' , 'agecl' , 'hhsex' )
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
source_https( "https://raw.github.com/ajdamico/usgsd/master/Survey%20of%20Consumer%20Finances/scf.survey.R" )
# now that this function has been loaded into r, you can view its source code by uncommenting the line below
# scf.MIcombine
# scf.svyttest


# construct an imputed replicate-weighted survey design object
# build a new replicate-weighted survey design object,
# but unlike most replicate-weighted designs, this object includes the
# five multiply-imputed data tables - imp1 through imp5
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

# this is the methodologically-correct way to analyze the survey of consumer finances
# main disadvantage: requires code that's less intuitive for analysts familiar with 
# the r survey package's svymean( ~formula , design ) layout


# this object can also be examined by typing the name into the console..
scf.design

# ..or querying attributes directly.  not much yet.
attributes( scf.design )


# `scf.design` is a weird critter.  it's actually five survey designs, mushed into one thing.
# when you run an analysis on the scf.design object, you're actually running the same analysis
# on all five survey designs contained in the object -
# and then the scf.MIcombine() function will lumps them all together
# to give you the correct statistics and error terms


# oh hey look at the first (of five) survey designs..
scf.design$designs[[1]]

# ..and here's the first design's attributes,
# which look more like a standard svrepdesign() object
attributes( scf.design$designs[[1]] )

# examine the degrees of freedom of that first survey design
scf.design$designs[[1]]$degf

# look at the attributes of the fifth (of five) data frames
attributes( scf.design$designs[[5]] )
# examine the degrees of freedom
scf.design$designs[[5]]$degf



#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in scf.design #
scf.MIcombine( with( scf.design , unwtd.count( ~one ) ) )
# note that the scf.MIcombine() function above does not come with dr. lumley's mitools package
# this function was specifically written for the survey of consumer finances and downloaded near the top of this here script
# for more detail about the regular MIcombine function, load the mitools package and type ?MIcombine into the console


# broken out by the age of the head of the household variable #
scf.MIcombine( with( scf.design , svyby( ~one , ~agecl , unwtd.count ) ) )
# according to http://www.federalreserve.gov/econresdata/scf/files/bulletin.macro.txt
# (search for the text 'agecl') age categories are:
# under 35; 35-44; 45-54; 55-64; 65-74; 75+


# calculate the mean of a linear variable #

# average checking account size (other than money markets) - nationwide
( ch <- scf.MIcombine( with( scf.design , svymean( ~checking ) ) ) )
# the command `ch <-` stores the results into a new object called `ch`
# that can be accessed later.  also, 
# surrounding the entire command with ( )
# prints whatever's being stored to the screen

# mean and standard error
ch

# variance
SE( ch )^2

# rse (relative standard error)
( SE( ch ) / coef( ch ) ) * 100

# confidence intervals
confint( ch , level = 0.95 )
confint( ch , level = 0.99 )


# average checking account size (other than money markets)
# by the age of the head of the household
scf.MIcombine( with( scf.design , svyby( ~checking , ~agecl , svymean ) ) )


# calculate the distribution of a categorical variable #

# hhsex should be treated as a factor (categorical) variable
# instead of a numeric (linear) variable
# this update statement converts it.
# the svyby command below will not run without this
scf.design <- update( hhsex = factor( hhsex ) , scf.design )


# percent of households headed by males vs. females - nationwide
scf.MIcombine( with( scf.design , svymean( ~hhsex ) ) )

# by the age of the head of the household
scf.MIcombine( with( scf.design , svyby( ~hhsex , ~agecl , svymean ) ) )


# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum
# average checking account size (other than money markets) in the united states
scf.MIcombine( 
	with( 
		scf.design , 
		svyby( 
			~checking , 
			~one , 
			svyquantile , 
			c( 0 , .25 , .5 , .75 , 1 ) , 
			ci = TRUE , 
			method = 'constant' 
		) 
	) 
)

# by the age of the head of the household
scf.MIcombine( 
	with( 
		scf.design , 
		svyby( 
			~checking , 
			~agecl , 
			svyquantile , 
			c( 0 , .25 , .5 , .75 , 1 ) , 
			ci = TRUE , 
			method = 'constant' 
		) 
	) 
)


####################
# recoding example #
####################

# create a new column `senior` containing
# 1 if the age of the head of household is 65+ (if agecl is five or six) and
# 0 if the age of the head of household is under 65
scf.design <-
	update( 
		scf.design , 
		hhsenior = 
			ifelse( agecl %in% 5:6 , 1 , 0 ) 
		)

######################
# subsetting example #
######################

# restrict the scf.design object to
# households headed by seniors only
scf.senior <- subset( scf.design ,	hhsenior %in% 1 )
# now any of the above commands can be re-run
# using scf.senior object
# instead of the scf.design object
# in order to analyze households headed by seniors only

# calculate the mean of a linear variable #

# average household expenditure - nationwide, 
# restricted to households headed by seniors
scf.MIcombine( with( scf.senior , svymean( ~checking ) ) )

# remove this subset design to clear up memory
rm( scf.senior )

# clear up RAM
gc()


# # # # # # # # # # # # # # # # # # # # # # # # # 
# simple t-test on multiply-imputed survey data #
# # # # # # # # # # # # # # # # # # # # # # # # #

# is the difference in checking accounts between male- and female-headed households statistically significant?
scf.svyttest( checking ~ factor( hhsex ) , scf.design )		# yes
# note that the scf.svyttest() function above does not come with dr. lumley's survey package
# this function was specifically written for the survey of consumer finances and downloaded near the top of this here script
# for more detail about the regular svyttest function, load the survey package and type ?svyttest into the console


# # # # # # # # # # # # # # # # # # # #
# regression and logistic regression  #
# # # # # # # # # # # # # # # # # # # #

# the relationship between (checking account amount + the gender of the head of household) and net worth
summary( 
	MIcombine( 
		with( 
			scf.design , 
			svyglm( networth ~ checking + hhsex ) 
		) 
	) 
)


# the relationship between (net worth + checking account amount) and the household having any debt
summary( 
	MIcombine( 
		with( 
			scf.design , 
			svyglm( hdebt ~ networth + checking , family = quasibinomial() ) 
		) 
	)
)


##################
# export example #
##################

# calculate the percent of households with any debt

# broken out by age of the head of household

# store the results into a new object, `debt.by.age`
debt.by.age <-
	scf.MIcombine( 
		with( 
			scf.design , 
			svyby( 
				~hdebt , 
				~agecl , 
				svymean 
			) 
		) 
	)

# print the results to the screen 
debt.by.age

# now you have the results saved into a new object of type "MIresult"
class( debt.by.age )

# print only the statistics (coefficients) to the screen
# and save them into the object `dba.c`
( dba.c <- coef( debt.by.age ) )

# print only the standard errors to the screen
# and save them into the object `dba.se`
( dba.se <- SE( debt.by.age ) )

# this object cannot be coerced (converted) to a data frame.. 
# debt.by.age <- data.frame( debt.by.age ) # this command will throw an error
# instead, manually place the coefficients and standard errors into a data frame side-by-side
# note that the row numbers match the `agecl` values in this case..
dba <- data.frame( coef = dba.c , se = dba.se )

# (look at dba)
dba

# ..however, if they didn't, it might be useful to add a column containing those values.
dba <- 
	data.frame( 
		agecl = names( dba.c ) ,
		coef = dba.c ,
		se = dba.se
	)
	
# (look at dba again)
dba


# immediately export the results as a comma-separated value file
# into your current working directory..
write.csv( dba , "any debt by household head age.csv" )

# ..or directly into a bar plot
barplot(
	dba[ , 2 ] ,
	main = "Debt Rate by Household Head Age" ,
	names.arg = c( "Under 35" , "35-44" , "45-54" , "55-64" , "65-74" , "75+" ) ,
	ylim = c( 0 , 1 )
)


# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
