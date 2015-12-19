# analyze survey data for free (http://asdfree.com) with the r language
# program for international student assessment
# 2012 student questionnaire

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( 'C:/My Directory/PISA/' )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/pisalite/Program%20for%20International%20Student%20Assessment/analysis%20examples.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#######################################################################################################################################################
# prior to running this analysis script, the pisa 2012 multiply-imputed tables must be loaded as a monet-backed sqlsurvey object on the               #
# local machine. running the download, import, and design script will create a monetdb-backed multiply-imputed database with whatcha need             #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "https://raw.githubusercontent.com/ajdamico/asdfree/pisalite/Program%20for%20International%20Student%20Assessment/download%20import%20and%20design.R" #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "2012 int_stu12_dec03.rda" in C:/My Directory/PISA or wherever the working directory was set.                        #
#######################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


library(downloader)		# downloads and then runs the source() function on scripts from github
library(survey) 		# load survey package (analyzes complex design surveys)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(MonetDBLite)	# load MonetDBLite package (creates database files in R)
library(mitools) 		# load mitools package (analyzes multiply-imputed data)


# load a compilation of functions that will be useful when executing actual analysis commands with this multiply-imputed, monetdb-backed behemoth
source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/pisalite/Program%20for%20International%20Student%20Assessment/sqlsurvey%20functions.R" , prompt = FALSE )


# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )

# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite() , dbfolder )


# the program for international student assessment download and importation script
# has already created a monet database-backed survey design object
# connected to the 2012 student questionnaire tables

# sqlite database-backed survey objects are described here: 
# http://r-survey.r-forge.r-project.org/survey/svy-dbi.html
# monet database-backed survey objects are similar, but:
# the database engine is, well, blazingly faster
# the setup is kinda more complicated (but all done for you)

# since this script only loads one file off of the local drive,
# there's no need to set the working directory.
# instead, simply use the full filepath to the r data file (.rda)
# as shown in the load() examples below.

# load the desired program for international student assessment monet database-backed complex sample design objects

# uncomment one this line by removing the `#` at the front..
load( '2012 int_stu12_dec03.rda' )	# analyze the 2012 student questionnaire

# connect the complex sample designs to the monet database #
this_design <- svyMDBdesign( this_design )


# for the most part, `this_design` can be used like a hybrid multiply-imputed, database-backed svrepdesign object.


###########################
# variable recode example #
###########################


# construct a new category variable in the dataset
this_design <- update( this_design , progcat = ifelse( st49q07 %in% 1:2 , 'always, almost always, or often' , ifelse( st49q07 %in% 3:4 , 'sometimes, rarely, or never' , NA ) ) )

# print the distribution of that category
MIcombine( with( this_design , svymean( ~ progcat , na.rm = TRUE ) ) )


################################################
# ..and immediately start the example analyses #
################################################

# count the total (unweighted) number of records in pisa #

# since the pisa gets loaded as a monet database-backed survey object instead of a data frame,
# the number of unweighted records cannot be calculated by running the nrow() function on a data frame.

# running the nrow() function on the database connection object
# simply produces an error..
# nrow( db )

# because the monet database might contain multiple data tables
class( db )


# instead, perform the same unweighted count directly from one of the sql tables
# stored inside the monet database on your hard disk (as opposed to RAM)
dbGetQuery( db , "SELECT COUNT(*) AS num_records FROM int_stu12_dec03_imp1" )

	

# count the total (unweighted) number of records in pisa #
# broken out by country #

# note: this is easiest by simply running a sql query on the monet database directly
dbGetQuery( db , "SELECT cnt , COUNT(*) as num_records FROM int_stu12_dec03_imp1 GROUP BY cnt" )



# count the weighted number of students *worldwide* that pisa data represents #
MIcombine( with( this_design , svytotal( ~one ) ) )

# note that this is exactly equivalent to summing up the weight variable
# from the original database (.db) file connection
dbGetQuery( db , "SELECT SUM( one ) AS sum_weights FROM int_stu12_dec03_imp1" )
# but only because `one` has the same value across all five implicates


# weighted country population, for all countries in the data set
# by country
MIcombine( with( this_design , svyby( ~one , ~cnt , svytotal ) ) )


# calculate the mean of a linear variable #

# average science score - across all individuals in the data set
MIcombine( with( this_design , svymean( ~scie ) ) )

# by country
MIcombine( with( this_design , svyby( ~scie , ~cnt , svymean ) ) )


# calculate the distribution of a categorical variable #

# force it to be categorical first
this_design <- update( this_design , ic01q04 = factor( ic01q04 ) )
this_design <- update( this_design , cnt = factor( cnt ) )

# percent with an internet connection:
# 1) yes, and i use it
# 2) yes, but i don't use it
# 3) no

MIcombine( with( this_design , svymean( ~ ic01q04 , na.rm = TRUE ) ) )

# by country
MIcombine( with( this_design , svyby( ~ ic01q04 , ~cnt , svymean , na.rm.by = TRUE , na.rm.all = TRUE , na.rm = TRUE ) ) )

# oh!  and fun fact.  do you know why..
# in compendium file..
	# http://pisa2012.acer.edu.au/downloads/M_comp_ICT_DEC03.zip
# in excel file
	# IC01Q04.xls
# on excel tab
	# Perc
# cells E4, G4, and I4 do not match the first three rows in the output you've just produced?

# because!  and this is real.  because!  oecd includes missings in their sums to 100%

# check this out:
# they say cells:
# E4 = 93.9614367187289
# G4 = 1.70799077487675
# I4 = 2.41842206642846

# well try this on for size

# E4 + G4 + I4 = 98.0878495600341

# divide each of those three numbers by their sum,
# new E4 = ( 93.9614367187289 / 98.0878495600341 ) = 
# the very very first number that you've just beauuutifully created with R.


# calculate the median and other percentiles #
MIcombine( with( this_design , svyby( ~scie , ~one , svyquantile , c( 0.05 , 0.1 , 0.25 , 0.75 , 0.9 , 0.95 ) ) ) )
	

######################
# subsetting example #
######################

# restrict the this_design object to females only
this_design.female <- subset( this_design , st04q01 == 2 )

# now any of the above commands can be re-run
# using the this_design.female object
# instead of the this_design object
# in order to analyze females only
	
# calculate the mean of a linear variable #

# average science score - nationwide, restricted to females
MIcombine( with( this_design.female , svymean( ~scie ) ) )

# median science score - restricted to females
MIcombine( with( this_design.female , svyquantile( ~scie , 0.5 ) ) )



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by oecd membership

# store the results into a new object

internet.by.oecd <- MIcombine( with( this_design , svyby( ~ic01q04 , ~oecd , svymean ) ) )

# print the results to the screen 
internet.by.oecd

# now you have the results saved into a new MIresult object..
class( internet.by.oecd )

# print only the statistics (coefficients) to the screen 
coef( internet.by.oecd )

# print only the standard errors to the screen 
SE( internet.by.oecd )

# this object can be coerced (converted) to a data frame.. 
internet.by.oecd <- data.frame( coef( internet.by.oecd ) )


# ..and then immediately exported as a comma-separated value file 
# into your current working directory 
write.csv( internet.by.oecd , "internet by oecd membership.csv" )

# ..or trimmed to only contain the values you need.
# here's the percentage without internet access at home, by oecd nation vs. all others in the data
no.internet.access.by.oecd <-
	internet.by.oecd[ substr( rownames( internet.by.oecd ) , 1 , 2 ) == "3:" , ]


# print the new results to the screen
no.internet.access.by.oecd

# this can also be exported as a comma-separated value file 
# into your current working directory 
write.csv( no.internet.access.by.oecd , "no internet access by oecd.csv" )

# ..or directly made into a bar plot
barplot(
	no.internet.access.by.oecd ,
	main = "Lacking Internet Access by OECD Membership" ,
	names.arg = c( "Non-OECD" , "OECD" ) ,
	ylim = c( 0 , .20 )
)


############################
# end of analysis examples #
############################


# disconnect from the current monet database
dbDisconnect( db )


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
