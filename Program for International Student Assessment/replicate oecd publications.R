# analyze survey data for free (http://asdfree.com) with the r language
# program for international student assessment
# 2009 student questionnaire

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( "monetdb.sequential" = TRUE )
# library(downloader)
# batfile <- "C:/My Directory/PISA/MonetDB/pisa.bat"
# load( 'C:/My Directory/PISA/2009 int_stq09_dec11.rda' )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Program%20for%20International%20Student%20Assessment/replicate%20oecd%20publications.R" , prompt = FALSE , echo = TRUE )
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


###########################################
# this script matches the oecd statistics #######################################################
# they've published at this url..  http://www.oecd.org/pisa/pisaproducts/4_SE_differences.pptx  #########################
# ..but just in case they decide to up and change it, i've saved a copy of the original file with all the methods here: #############
# https://github.com/ajdamico/usgsd/blob/master/Program%20for%20International%20Student%20Assessment/4_SE_differences.pptx?raw=true #
#####################################################################################################################################


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


library(sqlsurvey)		# load sqlsurvey package (analyzes large complex design surveys)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(mitools) 		# load mitools package (analyzes multiply-imputed data)
library(downloader)		# downloads and then runs the source() function on scripts from github



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

# uncomment one this line by removing the `#` at the front..
# load( 'C:/My Directory/PISA/2009 int_stq09_dec11.rda' )	# analyze the 2009 student questionnaire


# note: this r data file should contain five sqlrepdesign objects ending with `imp1` - `imp5`
# you can check 'em out by running the `ls()` function to see what's available in working memory.
ls()
# see them?
# they should be named something like this..
paste0( 'int_stq09_dec11_imp' , 1:5 )

# now use `mget` to take a character vector,
# look for objects with the same names,
# and smush 'em all together into a list
imp.list <- mget( paste0( 'int_stq09_dec11_imp' , 1:5 ) )

# now take a deep breath because this next part might scare you.

# use the custom-made `svyMDBdesign` function to put
# those five database-backed tables (already smushed into a list object)
# into a new and sexy object type - a monetdb-backed, multiply-imputed svrepdesign object.
pisa.imp <- svyMDBdesign( imp.list )
# note to database-connection buffs out there: this function does the port `open`ing for you.


# for the most part, `pisa.imp` can be used like a hybrid multiply-imputed, sqlrepsurvey object.


# print the overall reading score for all students in the entire data set.

# note that this includes non-oecd countries, so it doesn't match the oecd's powerpoint slide
MIcombine( with( pisa.imp , svymean( ~readz ) ) )


##########################################
# okay time to start replicating numbers #
##########################################


# on slide number two, take a look at the "total oecd" row's mean and standard error
# (first column with statistics)

# break out `pisa.imp` by oecd- and non-oecd students.
MIcombine( with( pisa.imp , svymean( ~readz , byvar = ~oecd ) ) )
# boom!  matches precisely.


# subset `pisa.imp` like you'd subset any other survey object.
oecd.imp <- subset( pisa.imp , oecd == 1 )
# now you've got an `oecd.imp` object restricted to only oecd students

# re-run the mean and standard error of the reading score,
# this time using the monetdb-backed object that's been subsetted already..
MIcombine( with( oecd.imp , svymean( ~readz ) ) )
# ..and it exactly matches again, hooray!

# break out the oecd students' reading scores by gender
MIcombine( with( oecd.imp , svymean( ~readz , byvar = ~st04q01 ) ) )
# exactly match.  nice.

# let's run that same command as above, but store the results into a `oecd.boygirl` object
oecd.boygirl <- MIcombine( with( oecd.imp , svymean( ~readz , byvar = ~st04q01 ) ) )

# now the `survey` package's `svycontrast` function can be used.
# note oecd.boygirl has three levels: NA, 1, and 2.
# NA is first in the list, so that's a zero.
# boys are next, and we want to compare them to girls, so make them negative one
# and girls (the third level) a positive one.  again, that's (zero, negative one, positive one)
# put it into the diff= position inside a list in the second position of `svycontrast`
svycontrast( oecd.boygirl , list( diff = c( 0 , -1 , 1 ) ) )
# and boo-yah, you have just replicated the powerpoint slide's difference boy minus girl and also standard error.

# was that too much for you?  if you've only got two levels,
# just use this custom function i've written *just for you*
# that performs a simple t-test on monetdb-backed, multiply-imputed designs
pisa.svyttest( readz ~ st04q01 , oecd.imp )
# see?
# same difference.



#################
# quantile time #


# quantiles require a bit of extra work in monetdb-backed multiply-imputed designs
# here's an example of how to calculate the median reading score
sqlquantile.MIcombine( with( oecd.imp , svyquantile( ~readz , 0.5 , se = TRUE ) ) )
# the `MIcombine` function does not work on (svyquantile x sqlrepdesign) output
# so i've written a custom function `sqlquantile.MIcombine` that does.  kewl?


# hey how about we loop through the six quantiles shown on the powerpoint's slide two..
for ( qtile in c( 0.05 , 0.1 , 0.25 , 0.75 , 0.9 , 0.95 ) ){

	# ..and run the reading score for each of those quantiles.
	print( sqlquantile.MIcombine( with( oecd.imp , svyquantile( ~readz , qtile , se = TRUE ) ) ) )
	# compared to the powerpoint, the coefficients match exactly..however the standard errors are not exactly the same
	# why not?  because there's an element of randomness in quantile calculations using big big big data.
	
}

# # # # # # # # # # # # # # # # # # # # # # # # # #
# quantile standard error difference explanation  #
# # # # # # # # # # # # # # # # # # # # # # # # # #

# standard error computation for quantiles of very large data sets requires an element of randomness
# therefore, these SEs will not precisely match the official recommendations.  but there's no theoretical basis
# that one answer is better than another.

# from the oecd's recommended sas scripts - http://www.oecd.org/pisa/pisaproducts/pisa2006/42628103.zip
# notice the random numbers used in their quantile calculations?  the normal() function in sas injects some randomness in the result.

# DATA QUARTILE_TEMP1 (KEEP=&BYVAR &REPLI_ROOT.0-&REPLI_ROOT.80 &PV_ROOT.1-&PV_ROOT.5 INDEX1-INDEX5 &ID_SCHOOL &INDEX NB_MISS) ;
	# SET &INFILE;
	# NB_MISS=0;
	# ARRAY A (6) &INDEX &PV_ROOT.1-&PV_ROOT.5;
	# DO I=1 TO 6;
		# IF (A(I) IN (.,.M,.N,.I)) THEN NB_MISS=NB_MISS+1;
	# END;
	# INDEX1=&INDEX + (0.01*normal(-01));
	# INDEX2=&INDEX + (0.01*normal(-23));
	# INDEX3=&INDEX + (0.01*normal(-45));
	# INDEX4=&INDEX + (0.01*normal(-67));
	# INDEX5=&INDEX + (0.01*normal(-89));
# RUN;

# so yeah, there's no way that r + monetdb can precisely match sas.  but who cares.  both results are defensible.

# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# end of quantile standard error difference explanation #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# alright.  let's move a little faster now.



###################
# match slide six #

# overall mean and standard error
MIcombine( with( oecd.imp , svymean( ~readz ) ) )

# regression with the `escs` column
MIcombine( with( oecd.imp , svylm( readz ~ escs ) ) )

# mean and standard errors for all countries
MIcombine( with( pisa.imp , svymean( ~readz , byvar = ~cnt ) ) )


####################
# match slide nine #

MIcombine( with( subset( oecd.imp , cnt == 'USA' ) , svymean( ~readz ) ) )

MIcombine( with( subset( pisa.imp , cnt == 'USA' ) , svylm( readz ~ escs ) ) )



######################
# match slide twenty #

# left side contrast statistics
# simply create a subset of the country you're interested in..


# # # # albania # # # #

albania <- subset( pisa.imp , cnt == 'ALB' )

alb.jr <- MIcombine( with( albania , svymean( ~joyread , byvar = ~immig ) ) )

alb.jr

svycontrast( alb.jr , list( diff = c( 0 , 1 , -1 , 0 ) ) )
svycontrast( alb.jr , list( diff = c( 0 , 1 , 0 , -1 ) ) )
svycontrast( alb.jr , list( diff = c( 0 , 0 , 1 , -1 ) ) )

# but really, why not make it a survey design-adjusted t-test?
# subset your design to only the groups you're comparing,
# then run the custom-built `pisa-svyttest` function.
pisa.svyttest( joyread ~ immig , subset( albania , immig %in% c( 2 , 3 ) ) )
# same result, but you get the statistical testing output done for ya.


# # # # argentina # # # #

argentina <- subset( pisa.imp , cnt == 'ARG' )

arg.jr <- MIcombine( with( argentina , svymean( ~joyread , byvar = ~immig ) ) )

arg.jr

svycontrast( arg.jr , list( diff = c( 0 , 1 , -1 , 0 ) ) )
svycontrast( arg.jr , list( diff = c( 0 , 1 , 0 , -1 ) ) )
svycontrast( arg.jr , list( diff = c( 0 , 0 , 1 , -1 ) ) )


# # # # australia # # # #

australia <- subset( pisa.imp , cnt == 'AUS' )

aus.jr <- MIcombine( with( australia , svymean( ~joyread , byvar = ~immig ) ) )

aus.jr

svycontrast( aus.jr , list( diff = c( 0 , 1 , -1 , 0 ) ) )
svycontrast( aus.jr , list( diff = c( 0 , 1 , 0 , -1 ) ) )
svycontrast( aus.jr , list( diff = c( 0 , 0 , 1 , -1 ) ) )


# right side contrasts


# # # # albania # # # #

alb.read <- MIcombine( with( albania , svymean( ~readz , byvar = ~immig ) ) )

svycontrast( alb.read , list( diff = c( 0 , 1 , -1 , 0 ) ) )


# # # # brazil # # # #

brazil <- subset( pisa.imp , cnt == 'BRA' )

bra.read <- MIcombine( with( brazil , svymean( ~readz , byvar = ~immig ) ) )

svycontrast( bra.read , list( diff = c( 0 , 1 , -1 , 0 ) ) )



################################################
# end of replication #
################################################


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
