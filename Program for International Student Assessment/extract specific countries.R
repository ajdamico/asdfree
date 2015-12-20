# analyze survey data for free (http://asdfree.com) with the r language
# program for international student assessment
# 2009 student questionnaire

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/PISA/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Program%20for%20International%20Student%20Assessment/extract%20specific%20countries.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#######################################################################################################################################################
# prior to running this analysis script, the pisa 2009 multiply-imputed tables must be loaded as a monet-backed survey object on the                  #
# local machine. running the download, import, and design script will create a monetdb-backed multiply-imputed database with whatcha need             #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "https://raw.githubusercontent.com/ajdamico/asdfree/master/Program%20for%20International%20Student%20Assessment/download%20import%20and%20design.R" #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "2009 int_stq09_dec11.rda" in C:/My Directory/PISA or wherever the working directory was set.                        #
#######################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


library(downloader)		# downloads and then runs the source() function on scripts from github
library(survey) 		# load survey package (analyzes complex design surveys)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(MonetDBLite)	# load MonetDBLite package (creates database files in R)
library(mitools) 		# load mitools package (analyzes multiply-imputed data)


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PISA/" )

# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )

# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite() , dbfolder )


# the program for international student assessment download and importation script
# has already created a monet database-backed survey design object
# connected to the 2009 student questionnaire tables

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


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PISA/" )
# ..in order to set your current working directory


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
# https://github.com/ajdamico/asdfree/blob/master/Program%20for%20International%20Student%20Assessment/4_SE_differences.pptx?raw=true


# `brazil.2009.design` is a multiply-imputed (but no longer monetdb-backed) replicate-weighted survey design object
# that you can analyze using syntax similar to the national health interview survey's multiply-imputed survey objects (found here)
# https://github.com/ajdamico/asdfree/blob/master/National%20Health%20Interview%20Survey/2011%20personsx%20plus%20samadult%20with%20multiple%20imputation%20-%20analyze.R
# or the consumer expenditure survey's multiply-imputed survey objects (found here)
# https://github.com/ajdamico/asdfree/blob/master/Consumer%20Expenditure%20Survey/2011%20fmly%20intrvw%20-%20analysis%20examples.R

# this pisa extraction script does not contain a full set of analysis examples for this non-monetdb-backed object
# but you can review syntax examples for multiply-imputed objects in those other scripts.  please and thank you.

