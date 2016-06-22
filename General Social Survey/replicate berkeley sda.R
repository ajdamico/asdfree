# analyze survey data for free (http://asdfree.com) with the r language
# general social survey
# replication of tables published by the berkeley survey documentation and analysis
# using 1972-2010 cross-sectional cumulative data (release 2, feb. 2012)

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/GSS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/General%20Social%20Survey/replicate%20berkeley%20sda.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# the main norc gss website - http://norc.org/gss+website - directs analysts wishing to generate statistics to
# the berkeley survey documentation and analysis project at http://sda.berkeley.edu
# since quick tables currently available on their website use the release #1 version of the gss data,
# analysts at sda created release #2-specific tables to be matched, available as a pdf here:
# https://github.com/ajdamico/asdfree/blob/master/General%20Social%20Survey/GSS%201972-2010%20Polviews%20by%20Sex%20from%20Berkeley%20SDA.pdf?raw=true

# note that these statistics come very close to the quick table results available at
# http://sda.berkeley.edu/quicktables/quicksetoptions.do?reportKey=gss10%3A0
# however, because berkeley sda currently defaults to release #1 (outdated data)
# sda cannot currently compute the latest statistics


# this r script will replicate each of the statistics from the custom gss run exactly
# https://github.com/ajdamico/asdfree/blob/master/General%20Social%20Survey/GSS%201972-2010%20Polviews%20by%20Sex%20from%20Berkeley%20SDA.pdf?raw=true


# contact me directly for free help or for paid consulting work

# anthony joseph damico the first
# ajdamico@gmail.com


##################################################################################################################
# Analyze the 1972-2010 General Social Survey cross-sectional cumulative data (release 2, feb. 2012) file with R #
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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# warning: old versions of the survey package will not work.  #
# this script depends on version 3.29 of the survey package.  #
# if typing the command                                       #
# sessionInfo()
# reveals you are using a version of survey lower than 3.29   #
# simply re-install the survey package by running the         #
# install.packages line below.                                #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# remove the # in order to run this install.packages line only once
# install.packages( "survey" , "downloader" , "digest" )


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

# create new character variables containing the full filepath of the file (stored locally)
# that needs to be downloaded and imported into r for analysis
GSS.2010.CS.file.location <-
	"https://github.com/ajdamico/asdfree/blob/master/General%20Social%20Survey/gss7210_r2b_stata.zip?raw=true"
	

# create a temporary file and a temporary directory
# for downloading file to the local drive
tf <- tempfile() ; td <- tempdir()


# download the file using the filepath specified
download.file( 
	# download the file stored in the location designated above
	GSS.2010.CS.file.location ,
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

# print the temporary location of the stata (.dta) file to the screen
print( fn )
	

# these two steps take a while.  but once saved as a .rda, future loading becomes fast forever after #


# convert the stata (.dta) file saved on the local disk (at 'fn') into an r data frame
GSS.2010.CS.df <- read.dta( fn )

	
# save the cross-sectional cumulative gss r data frame inside an r data file (.rda)
save( GSS.2010.CS.df , file = "GSS.2010.CS.rda" )

# note that this .rda file will be stored in the local directory specified
# with the setwd command at the beginning of the script

##########################################################################
# END OF DATA LOADING COMPONENT - DO NOT RUN DATA LOADING COMMANDS AGAIN #
##########################################################################


# now the r data frame can be loaded directly
# from your local hard drive.  this is much faster.
load( "GSS.2010.CS.rda" )


# display the number of rows in the cross-sectional cumulative data set
nrow( GSS.2010.CS.df )

# display the first six records in the cross-sectional cumulative data set
head( GSS.2010.CS.df )
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
		
		"sex" 	 		# respondent's sex
	)


# limit the r data frame (GSS.2010.CS.df) containing all variables
# to a severely-restricted r data frame containing only the seven variables
# specified in character vector 'KeepVars'
x <- GSS.2010.CS.df[ , KeepVars ]

# to free up RAM, remove the full r data frame
rm( GSS.2010.CS.df )

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

# create a character vector containing the unique values of political views
# this will be needed to calculate the confidence intervals later..
pvv <- as.character( unique( x$polviews ) )
# ..and immediately throw out missing values
pvv <- pvv[ !is.na( pvv ) ]

# create a character vector containing the unique values of political views
# this will be needed to calculate the confidence intervals later
sv <- as.character( unique( x$sex ) )


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
	

#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in the 1972-2010 cross-sectional cumulative gss data set #

# the nrow function which works on both data frame objects..
class( x )
# ..and survey design objects
class( gss.design )


# notice that the original data frame contains 1,613 records more than..
nrow( x )

# ..the survey object because those cases have a missing (NA) sampcode variable
nrow( gss.design )


# add a new variable 'one' that simply has the number 1 for each record #

gss.design <-
	update( 
		one = 1 ,
		gss.design
	)


# the sda quick table includes only records with a non-missing polviews variable,
# so create a subset of the gss.design containing only records with polviews information
y <- subset( gss.design , !is.na( polviews ) )


##############################################################
# print the exact contents of the sda document to the screen #
##############################################################

# https://github.com/ajdamico/asdfree/blob/master/General%20Social%20Survey/GSS%201972-2010%20Polviews%20by%20Sex%20from%20Berkeley%20SDA.pdf?raw=true #

# print the total number of cases in the original data set
nrow( x )

# print the number of valid cases in the subsetted data set
nrow( y )


# unweighted counts #
# (second to last number in each box) #

unwtd.count( ~one , y )							# total valid cases
svyby( ~one , ~sex , y , unwtd.count )			# column total
svyby( ~one , ~polviews , y , unwtd.count )		# row total


# weighted counts #
# (last number in each box) #

svytotal( ~one , y )							# total valid cases
svyby( ~one , ~sex , y , svytotal )				# column total
svyby( ~one , ~polviews , y , svytotal )		# row total


# column total percents: proportions, standard errors

# (first and third number in each box along the right) #
svymean( ~factor( polviews ) , y )


# if you just want the mean or the SE but not both
# place the svymean() inside the coef() or SE() function
coef( svymean( ~factor( polviews ) , y ) )
SE( svymean( ~factor( polviews ) , y ) )


# column total confidence intervals

# stata uses the logit method and non-infinite degrees of freedom
# stata also uses single-precision floating points,
# so CI numbers only match down to approximately the fourth decimal
# http://www.stata.com/statalist/archive/2006-10/msg01127.html
# this discussion thread contains more detail on CI matching
# http://r.789695.n4.nabble.com/Exactly-Replicating-Stata-s-Survey-Data-Confidence-Intervals-in-R-td4643850.html

# (second numbers in each box along the right) #

# loop through each political view
for ( i in pvv ){

	# dynamically create the equation to evaluate
	e2e <- paste0( "svyciprop( ~I( polviews == '" , i , "' ) , y , method = 'logit' , df = degf( y ) )" )
	
	# print the current level
	print( i )
	
	# print the specific command that's about to be run
	print( e2e )
	
	# print the asymmetric confidence intervals
	print(  eval( parse( text = e2e ) ) )
}


# percents by sex: proportions, standard errors

# (first and third number in each box under male and female) #
svyby( ~factor( polviews ) , ~sex , y , svymean )

# if you just want the mean or the SE but not both
# place the svyby() inside the coef() or SE() function
coef( svyby( ~factor( polviews ) , ~sex , y , svymean ) )
SE( svyby( ~factor( polviews ) , ~sex , y , svymean ) )


# confidence intervals by gender

# stata uses the logit method and non-infinite degrees of freedom
# stata also uses single-precision floating points,
# so CI numbers only match down to approximately the fourth decimal
# http://www.stata.com/statalist/archive/2006-10/msg01127.html
# this discussion thread contains more detail on CI matching
# http://r.789695.n4.nabble.com/Exactly-Replicating-Stata-s-Survey-Data-Confidence-Intervals-in-R-td4643850.html

# (second numbers in each box under male and female) #

# loop through each political view
for ( i in pvv ){

	# loop through both genders
	for ( j in sv ){
	
		# dynamically create the equation to evaluate
		e2e <- paste0( "svyciprop( ~I( polviews == '" , i , "' ) , subset( y , sex == '" , j , "' ) , method = 'logit' , df = degf( y ) )" )
		
		# print the current level
		print( paste( i , j ) )
		
		# print the specific command that's about to be run
		print( e2e )
		
		# print the asymmetric confidence intervals
		print(  eval( parse( text = e2e ) ) )

	}
}


########################################################################
# end of printing the exact contents of the sda document to the screen #
########################################################################

