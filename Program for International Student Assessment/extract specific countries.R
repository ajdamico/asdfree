# analyze survey data for free (http://asdfree.com) with the r language
# program for international student assessment
# 2009 student questionnaire

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# batfile <- "C:/My Directory/PISA/MonetDB/pisa.bat"
# setwd( "C:/My Directory/PISA/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Program%20for%20International%20Student%20Assessment/extract%20specific%20countries.R" , prompt = FALSE , echo = TRUE )
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
# prior to running this analysis script, the pisa 2009 multiply-imputed tables must be loaded as a monet-backed sqlsurvey object on the   #
# local machine. running the download, import, and design script will create a monetdb-backed multiply-imputed database with whatcha need #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "https://raw.github.com/ajdamico/usgsd/master/Program%20for%20International%20Student%20Assessment/download%20import%20and%20design.R"  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "2009 int_stq09_dec11.rda" in C:/My Directory/PISA or wherever the working directory was set.            #
###########################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # #
# warning: monetdb required #
# # # # # # # # # # # # # # #


# remove the # in order to run this install.packages line only once
# install.packages( "mitools" )


library(downloader)		# downloads and then runs the source() function on scripts from github
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(mitools) 		# load mitools package (analyzes multiply-imputed data)
library(survey)			# load survey package (analyzes complex design surveys)



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
# connected to the 2009 student questionnaire tables

# sqlite database-backed survey objects are described here: 
# http://faculty.washington.edu/tlumley/survey/svy-dbi.html
# monet database-backed survey objects are similar, but:
# the database engine is, well, blazingly faster
# the setup is kinda more complicated (but all done for you)

# since this script only loads one file off of the local drive,
# there's no need to set the working directory.
# instead, simply use the full filepath to the r data file (.rda)
# as shown in the load() examples below.

# load the desired program for international student assessment monet database-backed complex sample design objects


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PISA/" )
# ..in order to set your current working directory



# uncomment one this line by removing the `#` at the front..
load( '2009 int_stq09_dec11.rda' )	# analyze the 2009 student questionnaire


# create a character vector with all five of the tablenames
five.imps <- paste0( 'int_stq09_dec11_imp' , 1:5 )

# extract only the brazilian records from the monet database..
for ( i in 1:5 ){
	# ..and save those records as data.frame objects called `imp1` `imp2` .. `imp5`
	assign( 
		paste0( 'imp' , i ) , 
		dbGetQuery( db , paste( "select * from" , five.imps[ i ] , "where cnt = 'BRA'" ) )
	)
}

# # # end of monetdb # # #
# from this point forward, you finished with monetdb.
# so, if you like, disconnect from the server and kill it.
# # # end of monetdb # # #

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other `pisa` monetdb analyses #
############################################################################


# R will exactly match SUDAAN results and Stata with the MSE option results
options( survey.replicates.mse = TRUE )
# otherwise if it is commented out or set to FALSE


# build a new survey design object with the five multiply-imputed 
# a.k.a. plausible values data tables - imp1 through imp5
brazil.2009.design <-
	svrepdesign(
		weights = ~w_fstuwt ,
		repweights = "w_fstr[1-9]" ,
		scale = 4 / 80 ,
		rscales = rep( 1 , 80 ) ,
		data = imputationList( list( imp1 , imp2 , imp3 , imp4 , imp5 ) ) ,
		mse = TRUE ,
		type = "other"
	)


# immediately save this multiply-imputed survey design object..
save( brazil.2009.design , file = "brazil pisa 2009.rda" )
# ..into the local working directory

#  close R  #
# re-open R #

# load your necessary libraries

library(mitools) 		# load mitools package (analyzes multiply-imputed data)
library(survey)			# load survey package (analyzes complex design surveys)


# setwd( "C:/My Directory/PISA/" )

# load the multiply-imputed survey design object you'd created with monetdb
load( "brazil pisa 2009.rda" )


# run a `svyby` command on the multiply-imputed design
bra.read <-
	MIcombine( 
		with( 
			brazil.2009.design , 
			svyby( 
				~readz , 
				~immig ,
				svymean ,
				covmat = TRUE
			) 
		) 
	)
	
# run the `svycontrast` command that..
svycontrast( 
	bra.read , 
	list( diff = c( 1 , -1 , 0 ) ) 
)
# ..precisely matches the statistics and standard errors for `BRA` (brazil)
# shown in the lower lower right corner of powerpoint slide 20 in the oecd-produced 2009
# technical documentation, saved here:
# https://github.com/ajdamico/usgsd/blob/master/Program%20for%20International%20Student%20Assessment/4_SE_differences.pptx?raw=true


# `brazil.2009.design` is a multiply-imputed (but no longer monetdb-backed) replicate-weighted survey design object
# that you can analyze using syntax similar to the national health interview survey's multiply-imputed survey objects (found here)
# https://github.com/ajdamico/usgsd/blob/master/National%20Health%20Interview%20Survey/2011%20personsx%20plus%20samadult%20with%20multiple%20imputation%20-%20analyze.R
# or the consumer expenditure survey's multiply-imputed survey objects (found here)
# https://github.com/ajdamico/usgsd/blob/master/Consumer%20Expenditure%20Survey/2011%20fmly%20intrvw%20-%20analysis%20examples.R

# this pisa extraction script does not contain a full set of analysis examples for this non-monetdb-backed object
# but you can review syntax examples for multiply-imputed objects in those other scripts.  please and thank you.


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
