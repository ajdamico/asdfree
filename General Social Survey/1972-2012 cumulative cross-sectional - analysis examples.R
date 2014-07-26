# analyze survey data for free (http://asdfree.com) with the r language
# general social survey
# 1972-2012 cross-sectional cumulative data (release 1, march 2013)

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/GSS/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/General%20Social%20Survey/1972-2012%20cumulative%20cross-sectional%20-%20analysis%20examples.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

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


##################################################################################################################
# Analyze the 1972-2012 General Social Survey cross-sectional cumulative data (release 2, feb. 2012) file with R #
##################################################################################################################


# set your working directory.
# all GSS data files will be stored here
# after downloading and importing.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/GSS/" )
# ..in order to set your current working directory



# set the number of digits shown in all output

options( digits = 8 )


# remove the # in order to run this install.packages line only once
# install.packages( "survey" )


library(foreign) # load foreign package (converts data files into R)
library(survey)  # load survey package (analyzes complex design surveys)


# by default, R will crash if a primary sampling unit (psu) has a single observation
# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
# by uncommenting this line:
# options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN



###############################################
# DATA LOADING COMPONENT - ONLY RUN THIS ONCE #
###############################################

# create new character variables containing the full filepath of the file on norc's website
# that needs to be downloaded and imported into r for analysis
GSS.2012.CS.file.location <-
	"http://publicdata.norc.org/GSS/DOCUMENTS/OTHR/GSS_spss.zip"


# create a temporary file and a temporary directory
# for downloading file to the local drive
tf <- tempfile() ; td <- tempdir()


# download the file using the filepath specified
download.file( 
	# download the file stored in the location designated above
	GSS.2012.CS.file.location ,
	# save the file as the temporary file assigned above
	tf , 
	# download this as a binary file type
	mode = "wb"
)


# the variable 'tf' now contains the full file path on the local computer to the specified file

# store the file path on the local disk to the extracted file (previously inside the zipped file)
# inside a new character string object 'fn'
fn <- 
	unzip( 
		# unzip the contents of the temporary file
		tf , 
		# ..into the the temporary directory (also assigned above)
		exdir = td , 
		# overwrite the contents of the temporary directory
		# in case there's anything already in there
		overwrite = T
	)

# print the temporary location of the spss (.sav) file to the screen
print( fn[ grep( "sav$" , fn ) ] )
	

# these two steps take a while.  but once saved as a .rda, future loading becomes fast forever after #


# convert the spss (.sav) file saved on the local disk (at 'fn') into an r data frame
GSS.2012.CS.df <- 
	read.spss( 
		fn[ grep( "sav$" , fn ) ] , 
		to.data.frame = TRUE , 
		use.value.labels = FALSE 
	)

# copy to a different object
z <- GSS.2012.CS.df

# remove the original from RAM
rm( GSS.2012.CS.df )

# clear up memory
gc()

# repeat
GSS.2012.CS.df <- z

# repeat
rm( z )

# i have no idea why this works.
gc()
# but if you don't do this on a 3gb ram machine
# you will run out of memory.  go figure.


	
# save the cross-sectional cumulative gss r data frame inside an r data file (.rda)
save( GSS.2012.CS.df , file = "GSS.2012.CS.rda" )

# note that this .rda file will be stored in the local directory specified
# with the setwd command at the beginning of the script

##########################################################################
# END OF DATA LOADING COMPONENT - DO NOT RUN DATA LOADING COMMANDS AGAIN #
##########################################################################


# now the r data frame can be loaded directly
# from your local hard drive.  this is much faster.
# load( "GSS.2012.CS.rda" )
# remove the `#` on the line above to uncomment.


# display the number of rows in the cross-sectional cumulative data set
nrow( GSS.2012.CS.df )

# display the first six records in the cross-sectional cumulative data set
head( GSS.2012.CS.df )
# note that the data frame contains far too many variables to be viewed conveniently

# create a character vector that will be used to
# limit the file to only the variables needed
KeepVars <-
	c( 
		"oversamp" , 	# weights for black oversamples
		
		"formwt" , 		# weight to deal with experimental randomization

		"wtssall" ,		# weight variable
		
		"sampcode" , 	# sampling error code
		
		"sample" , 		# sampling frame and method
		
		"polviews" , 	# think of self as liberal or conservative
		
		"sex" ,	 		# respondent's sex
		
		"age" ,			# respondent's age
		
		"region"		# respondent's region of the country
	)


# limit the r data frame (GSS.2012.CS.df) containing all variables
# to a severely-restricted r data frame containing only the seven variables
# specified in character vector 'KeepVars'
x <- GSS.2012.CS.df[ , KeepVars ]

# to free up RAM, remove the full r data frame
rm( GSS.2012.CS.df )

# garbage collection: clear up RAM
gc()


# calculate the compwt and samplerc variables
# to match SDA specifications
x <- 
	transform( 
		x , 
		
		# the calculation for compwt comes from
		# http://sda.berkeley.edu/D3/GSS10/Doc/gs100195.htm#COMPWT
		compwt =  oversamp  *  formwt * wtssall , 
		
		# the calculation for samplerc comes from
		# http://sda.berkeley.edu/D3/GSS10/Doc/gs100195.htm#SAMPLERC
		samplerc = 
			# if sample is a three or a four, samplerc should be a three
			ifelse( sample %in% 3:4 , 3 , 
			# if sample is a six or a seven, samplerc should be a six
			ifelse( sample %in% 6:7 , 6 , 
			# otherwise, samplerc should just be set to sample
				sample ) )

	)


#################################################
# survey design for taylor-series linearization #
#################################################

# create a survey design object (gss.design) with GSS design information
gss.design <- 
	svydesign( 
		~sampcode , 
		strata = ~samplerc , 
		data = subset( x , !is.na( sampcode ) ) , 
		weights = ~compwt , 
		nest = TRUE 
	)
	
# notice the 'gss.design' object used in all subsequent analysis commands


#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in gss #

# the nrow function which works on both data frame objects..
class( x )
# ..and survey design objects
class( gss.design )


# notice that the original data frame contains 1,613 records more than..
nrow( x )

# ..the survey object because those cases have a missing (NA) sampcode variable
nrow( gss.design )


# count the total (unweighted) number of records in gss #
# broken out by region of the country #

svyby(
	~age ,
	~region ,
	gss.design ,
	unwtd.count
)



# count the weighted number of individuals in gss #

# add a new variable 'one' that simply has the number 1 for each record #

gss.design <-
	update( 
		one = 1 ,
		gss.design
	)

# the civilian, non-institutionalized population of the united states #
svytotal( 
	~one , 
	gss.design 
)


# note that this is exactly equivalent to summing up the weight variable
# from the original GSS data frame, throwing out records with missing sampcodes

sum( subset( x , !is.na( sampcode ) )$compwt )

# the civilian, non-institutionalized population of the united states #
# by region of the country
svyby(
	~one ,
	~region ,
	gss.design ,
	svytotal
)


# calculate the mean of a linear variable #

# average age - nationwide
svymean( 
	~age , 
	design = gss.design ,
	na.rm = TRUE
)

# by region of the country
svyby( 
	~age , 
	~region ,
	design = gss.design ,
	svymean ,
	na.rm = TRUE
)


# calculate the distribution of a categorical variable #

# polviews should be treated as a factor (categorical) variable
# instead of a numeric (linear) variable
# this update statement converts it.
# the svyby command below will not run without this
gss.design <-
	update( 
		polviews = factor( polviews ) ,
		gss.design
	)


# political views distribution - nationwide
svymean( 
	~polviews , 
	design = gss.design ,
	na.rm = TRUE
)

# by region of the country
svyby( 
	~polviews , 
	~region ,
	design = gss.design ,
	svymean , 
	na.rm = TRUE
)

# calculate the median and other percentiles #

# note that a taylor-series survey design
# does not allow calculation of standard errors

# minimum, 25th, 50th, 75th, maximum 
# age in the united states
svyquantile( 
	~age , 
	design = gss.design ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	na.rm = TRUE
)

# by region of the country
svyby( 
	~age , 
	~region ,
	design = gss.design ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	keep.var = F ,
	na.rm = TRUE
)

######################
# subsetting example #
######################

# restrict the gss.design object to
# females only
gss.design.female <-
	subset(
		gss.design ,
		sex %in% 2
	)
# now any of the above commands can be re-run
# using the gss.design.female object
# instead of the gss.design object
# in order to analyze females only
	
# calculate the mean of a linear variable #

# average age - nationwide, restricted to females
svymean( 
	~age , 
	design = gss.design.female ,
	na.rm = TRUE
)



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by region of the country

# store the results into a new object

polviews.by.region <-
	svyby( 
		~polviews , 
		~region ,
		design = gss.design ,
		svymean ,
		na.rm = TRUE
	)

# print the results to the screen 
polviews.by.region

# now you have the results saved into a new object of type "svyby"
class( polviews.by.region )

# print only the statistics (coefficients) to the screen 
coef( polviews.by.region )

# print only the standard errors to the screen 
SE( polviews.by.region )

# this object can be coerced (converted) to a data frame.. 
polviews.by.region <- data.frame( polviews.by.region )

# ..and then immediately exported as a comma-separated value file 
# into your current working directory 
write.csv( polviews.by.region , "polviews by region.csv" )

# ..or trimmed to only contain the values you need.
# here's the percent of the country who self-identify as
# moderate by region, with accompanying standard errors
moderate.rate.by.region <-
	polviews.by.region[ , c( "region" , "polviews4" , "se.polviews4" ) ]

# that's all rows, and the three specified columns


# print the new results to the screen
moderate.rate.by.region

# this can also be exported as a comma-separated value file 
# into your current working directory 
write.csv( moderate.rate.by.region , "moderate rate by region.csv" )

# ..or directly made into a bar plot
barplot(
	moderate.rate.by.region[ , 2 ] ,					# the second column of the data frame contains the main data
	main = "Moderate Rate by Region of the Country" ,	# title the barplot
	names.arg = moderate.rate.by.region[ , 1 ] ,		# the first column of the data frame contains the names of each bar
	ylim = c( .35 , .45 ) , 							# set the lower and upper bound of the y axis
	cex.names = .5										# shrink the column labels so they all fit
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
