# analyze survey data for free (http://asdfree.com) with the r language
# health and retirement study
# replication of regression statistics published by RAND
# using the 1992 - 2010 public use file (version N)

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/HRS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Health%20and%20Retirement%20Study/replicate%202002%20regression.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# note that these statistics come very close to the example regression found on PDF page B76 of
# http://hrsonline.isr.umich.edu/sitedocs/dmgt/IntroUserGuide.pdf
# however, because those published regressions use a previous version of the RAND file, the statistics below do not match exactly.

# to confirm that the methodology below is correct, analysts at RAND provided me with the same regression output using versions E through L
# https://github.com/ajdamico/asdfree/blob/master/Health%20and%20Retirement%20Study/HRS%20stata%20output%20on%20current%20data%20from%20RAND.pdf?raw=true
# this r script will replicate the *final* regression output from that custom run of the health and retirement study (hrs) exactly

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#########################################################################################################################################
# prior to running this analysis script, the longitudinal RAND-contributed HRS files must be imported into a SQLite database on the     #
# local machine. running the import longitudinal RAND contributed files.R script to create the database automatically                   #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/Health%20and%20Retirement%20Study/import%20longitudinal%20RAND%20contributed%20files.R   #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will place the four RAND HRS files into a database "RAND.db" in the "C:/My Directory/HRS/" folder (the working directory) #
#########################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


#####################################################################################
# replicate example regression output provided by the survey administrators at RAND #
#####################################################################################


# set your working directory.
# the SQLite database file should have been stored within this folder
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/HRS/" )
# ..in order to set your current working directory


# remove the # in order to run this install.packages line only once
# install.packages( "survey" )



# choose the name of the database
db.name <- 'RAND.db'


# no need to edit anything below this line #


# # # # # # # # #
# program start #
# # # # # # # # #

library(survey)		# load survey package (analyzes complex design surveys)
library(RSQLite) 	# load RSQLite package (creates database files in R)


db <- dbConnect( SQLite() , db.name )			# connect to the SQLite database (.db)


# create a new table called 'temp' which throws out all missing values of the weight column
dbSendQuery( db , "CREATE TABLE temp AS SELECT * FROM hrs WHERE r6wthh >= 0" )


# create survey design object with HRS design information
# using the table stored in the SQLite database
hh6 <- 
	svydesign(
		~raehsamp ,
		strata = ~raestrat ,
		weights = ~r6wthh , 
		nest = TRUE ,
		data = 'temp' ,
		dbtype = 'SQLite' ,
		dbname = db.name
	)

# sum up the weighted number of observations
svytotal( ~one , hh6 )

# perform a weighted regression and store the summary statistics into a new variable
( regression <- summary( svyglm( h6icap ~ h6ahous + h6amort , hh6 ) ) )
# since the above line is contained in parentheses, the contents of the 'regression' object
# are also printed to the screen


# note that those statistics and standard errors precisely match the regression output shown on the final page of
# https://github.com/ajdamico/asdfree/blob/master/Health%20and%20Retirement%20Study/HRS%20stata%20output%20on%20current%20data%20from%20RAND.pdf?raw=true


# delete the table 'temp' from the SQLite database
dbRemoveTable( db , 'temp' )

# disconnect from the SQLite database
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
