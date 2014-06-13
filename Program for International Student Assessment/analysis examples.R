# analyze survey data for free (http://asdfree.com) with the r language
# program for international student assessment
# 2012 student questionnaire

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( "monetdb.sequential" = TRUE )
# library(downloader)
# batfile <- "C:/My Directory/PISA/MonetDB/pisa.bat"
# load( 'C:/My Directory/PISA/2012 int_stu12_dec03.rda' )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Program%20for%20International%20Student%20Assessment/analysis%20examples.R" , prompt = FALSE , echo = TRUE )
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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###########################################################################################################################################
# prior to running this analysis script, the pisa 2012 multiply-imputed tables must be loaded as a monet-backed sqlsurvey object on the   #
# local machine. running the download, import, and design script will create a monetdb-backed multiply-imputed database with whatcha need #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "https://raw.github.com/ajdamico/usgsd/master/Program%20for%20International%20Student%20Assessment/download%20import%20and%20design.R"  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "2012 int_stu12_dec03.rda" in C:/My Directory/PISA or wherever the working directory was set.            #
###########################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # #
# warning: monetdb required #
# # # # # # # # # # # # # # #


# windows machines and also machines without access
# to large amounts of ram will often benefit from
# the following option, available as of MonetDB.R 0.9.2 --
# remove the `#` in the line below to turn this option on.
# options( "monetdb.sequential" = TRUE )
# -- whenever connecting to a monetdb server,
# this option triggers sequential server processing
# in other words: single-threading.
# if you would prefer to turn this on or off immediately
# (that is, without a server connect or disconnect), use
# turn on single-threading only
# dbSendQuery( db , "set optimizer = 'sequential_pipe';" )
# restore default behavior -- or just restart instead
# dbSendQuery(db,"set optimizer = 'default_pipe';")


# remove the # in order to run this install.packages line only once
# install.packages( "mitools" )


library(downloader)		# downloads and then runs the source() function on scripts from github
library(sqlsurvey)		# load sqlsurvey package (analyzes large complex design surveys)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(mitools) 		# load mitools package (analyzes multiply-imputed data)


# load a compilation of functions that will be useful when executing actual analysis commands with this multiply-imputed, monetdb-backed behemoth
source_url( "https://raw.github.com/ajdamico/usgsd/master/Program%20for%20International%20Student%20Assessment/sqlsurvey%20functions.R" , prompt = FALSE )


# after running the r script above, users should have handy a few lines
# to initiate and connect to the monet database containing all program for international student assessment tables
# run them now.  mine look like this:


#####################################################################
# lines of code to hold on to for all other `pisa` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/PISA/MonetDB/pisa.bat"

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "pisa"
dbport <- 50007

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )


# # # # run your analysis commands # # # #


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
# load( 'C:/My Directory/PISA/2012 int_stu12_dec03.rda' )	# analyze the 2012 student questionnaire


# note: this r data file should contain five sqlrepdesign objects ending with `imp1` - `imp5`
# you can check 'em out by running the `ls()` function to see what's available in working memory.
ls()
# see them?
# they should be named something like this..
paste0( 'int_stu12_dec03_imp' , 1:5 )

# now use `mget` to take a character vector,
# look for objects with the same names,
# and smush 'em all together into a list
imp.list <- mget( paste0( 'int_stu12_dec03_imp' , 1:5 ) )

# now take a deep breath because this next part might scare you.

# use the custom-made `svyMDBdesign` function to put
# those five database-backed tables (already smushed into a list object)
# into a new and sexy object type - a monetdb-backed, multiply-imputed svrepdesign object.
pisa.imp <- svyMDBdesign( imp.list )
# note to database-connection buffs out there: this function does the port `open`ing for you.


# for the most part, `pisa.imp` can be used like a hybrid multiply-imputed, sqlrepsurvey object.


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
MIcombine( with( pisa.imp , svytotal( ~one ) ) )

# note that this is exactly equivalent to summing up the weight variable
# from the original database (.db) file connection
dbGetQuery( db , "SELECT SUM( one ) AS sum_weights FROM int_stu12_dec03_imp1" )
# but only because `one` has the same value across all five implicates


# weighted country population, for all countries in the data set
# by country
MIcombine( with( pisa.imp , svytotal( ~one , byvar = ~cnt ) ) )
# note: the above command is one example of how the r survey package differs from the r sqlsurvey package


# calculate the mean of a linear variable #

# average science score - across all individuals in the data set
MIcombine( with( pisa.imp , svymean( ~scie ) ) )

# by country
MIcombine( with( pisa.imp , svymean( ~scie , byvar = ~cnt ) ) )


# create a categorical variable #

numeric.variable.to.make.categorical <- 'ic01q04'

for ( i in 1:5 ){

	pisa.imp$designs[[ i ]]$zdata[ , numeric.variable.to.make.categorical ] <- 
		as.character( pisa.imp$designs[[ i ]]$zdata[ , numeric.variable.to.make.categorical ] )

}

# calculate the distribution of a categorical variable #

# percent with an internet connection:
# 1) yes, and i use it
# 2) yes, but i don't use it
# 3) no

MIcombine( with( pisa.imp , svymean( ~ic01q04 ) ) )

# by country
MIcombine( with( pisa.imp , svymean( ~ic01q04 , byvar = ~cnt ) ) )

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

# quantiles require a bit of extra work in monetdb-backed multiply-imputed designs
# here's an example of how to calculate the median science score
sqlquantile.MIcombine( with( pisa.imp , svyquantile( ~scie , 0.5 , se = TRUE ) ) )
# the `MIcombine` function does not work on (svyquantile x sqlrepdesign) output
# so i've written a custom function `sqlquantile.MIcombine` that does.  kewl?


# hey how about we loop through the six quantiles?  would you like that?
for ( qtile in c( 0.05 , 0.1 , 0.25 , 0.75 , 0.9 , 0.95 ) ){

	# ..and run the science score for each of those quantiles.
	print( sqlquantile.MIcombine( with( pisa.imp , svyquantile( ~scie , qtile , se = TRUE ) ) ) )
	
}


# ..sqlrepsurvey designs do not allow byvar arguments, meaning the only way to 
# calculate quantiles by country would be by creating subsets for each subpopulation
# and calculating the quantiles for them independently:

######################
# subsetting example #
######################

# restrict the pisa.imp object to females only
pisa.imp.female <- subset( pisa.imp , st04q01 == 2 )

# now any of the above commands can be re-run
# using the pisa.imp.female object
# instead of the pisa.imp object
# in order to analyze females only
	
# calculate the mean of a linear variable #

# average science score - nationwide, restricted to females
MIcombine( with( pisa.imp.female , svymean( ~scie ) ) )

# median science score - restricted to females
sqlquantile.MIcombine( with( pisa.imp.female , svyquantile( ~scie , qtile , se = TRUE ) ) )



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by oecd membership

# store the results into a new object

internet.by.oecd <- MIcombine( with( pisa.imp , svymean( ~ic01q04 , byvar = ~oecd ) ) )

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

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other `pisa` monetdb analyses #
############################################################################


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
