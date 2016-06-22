# analyze survey data for free (http://asdfree.com) with the r language
# program for international student assessment
# 2009 student questionnaire

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/PISA/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Program%20for%20International%20Student%20Assessment/replicate%20oecd%20publications.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico the first
# ajdamico@gmail.com


###########################################
# this script matches the oecd statistics #######################################################
# they've published at this url..  http://www.oecd.org/pisa/pisaproducts/4_SE_differences.pptx  #########################
# ..but just in case they decide to up and change it, i've saved a copy of the original file with all the methods here: ###############
# https://github.com/ajdamico/asdfree/blob/master/Program%20for%20International%20Student%20Assessment/4_SE_differences.pptx?raw=true #
#######################################################################################################################################


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



library(survey) 		# load survey package (analyzes complex design surveys)
library(MonetDBLite)
library(DBI)			# load the DBI package (implements the R-database coding)
library(mitools) 		# load mitools package (analyzes multiply-imputed data)
library(downloader)		# downloads and then runs the source() function on scripts from github


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PISA/" )


# load a compilation of functions that will be useful when executing actual analysis commands with this multiply-imputed, monetdb-backed behemoth
source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Program%20for%20International%20Student%20Assessment/survey%20functions.R" , prompt = FALSE )


# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )

# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite::MonetDBLite() , dbfolder )


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

# uncomment one this line by removing the `#` at the front..
load( '2009 int_stq09_dec11.rda' )	# analyze the 2009 student questionnaire


# open the survey design object's connection
pisa.imp <- svyMDBdesign( this_design )
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
MIcombine( with( pisa.imp , svyby( ~readz , ~oecd , svymean ) ) )
# boom!  matches precisely.


# subset `pisa.imp` like you'd subset any other survey object.
oecd.imp <- subset( pisa.imp , oecd == 1 )
# now you've got an `oecd.imp` object restricted to only oecd students

# re-run the mean and standard error of the reading score,
# this time using the monetdb-backed object that's been subsetted already..
MIcombine( with( oecd.imp , svymean( ~readz ) ) )
# ..and it exactly matches again, hooray!

# break out the oecd students' reading scores by gender
MIcombine( with( oecd.imp , svyby( ~readz , ~st04q01 , svymean ) ) )
# exactly match.  nice.

# let's run that same command as above, but store the results into a `oecd.boygirl` object
oecd.boygirl <- MIcombine( with( oecd.imp , svyby( ~readz , ~st04q01 , svymean ) ) )

# now the `survey` package's `svycontrast` function can be used.
# note oecd.boygirl has two levels: 1, and 2.
# boys are first, and we want to compare them to girls, so make them negative one
# and girls (the second level) a positive one.  again, that's (zero, negative one, positive one)
# put it into the diff= position inside a list in the second position of `svycontrast`
svycontrast( oecd.boygirl , list( diff = c( -1 , 1 ) ) )
# and boo-yah, you have just replicated the powerpoint slide's difference boy minus girl and also standard error.

# was that too much for you?  if you've only got two levels,
# just use this custom function i've written *just for you*
# that performs a simple t-test on monetdb-backed, multiply-imputed designs
pisa.svyttest( readz ~ st04q01 , oecd.imp )
# see?
# same difference.



#################
# quantile time #

# hey how about we run the reading score for each of those quantiles.
MIcombine( with( oecd.imp , svyby( ~readz , ~one , svyquantile , c( 0.05 , 0.1 , 0.25 , 0.75 , 0.9 , 0.95 ) ) ) )


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
MIcombine( with( oecd.imp , svyglm( readz ~ escs ) ) )

# mean and standard errors for all countries
MIcombine( with( pisa.imp , svyby( ~readz , ~cnt , svymean ) ) )


####################
# match slide nine #

MIcombine( with( subset( oecd.imp , cnt == 'USA' ) , svymean( ~readz ) ) )

MIcombine( with( subset( pisa.imp , cnt == 'USA' ) , svyglm( readz ~ escs ) ) )



######################
# match slide twenty #

# left side contrast statistics
# simply create a subset of the country you're interested in..


# # # # albania # # # #

albania <- subset( pisa.imp , cnt == 'ALB' )

alb.jr <- MIcombine( with( albania , svyby( ~joyread , ~immig , svymean , na.rm = TRUE ) ) )

alb.jr

svycontrast( alb.jr , list( diff = c( 1 , -1 , 0 ) ) )
svycontrast( alb.jr , list( diff = c( 1 , 0 , -1 ) ) )
svycontrast( alb.jr , list( diff = c( 0 , 1 , -1 ) ) )

# but really, why not make it a survey design-adjusted t-test?
# subset your design to only the groups you're comparing,
# then run the custom-built `pisa-svyttest` function.
pisa.svyttest( joyread ~ immig , subset( albania , immig %in% c( 2 , 3 ) ) )
# same result, but you get the statistical testing output done for ya.


# # # # argentina # # # #

argentina <- subset( pisa.imp , cnt == 'ARG' )

arg.jr <- MIcombine( with( argentina , svyby( ~joyread , ~immig , svymean , na.rm = TRUE ) ) )

arg.jr

svycontrast( arg.jr , list( diff = c( 1 , -1 , 0 ) ) )
svycontrast( arg.jr , list( diff = c( 1 , 0 , -1 ) ) )
svycontrast( arg.jr , list( diff = c( 0 , 1 , -1 ) ) )


# # # # australia # # # #

australia <- subset( pisa.imp , cnt == 'AUS' )

aus.jr <- MIcombine( with( australia , svyby( ~joyread , ~immig , svymean , na.rm = TRUE ) ) )

aus.jr

svycontrast( aus.jr , list( diff = c( 1 , -1 , 0 ) ) )
svycontrast( aus.jr , list( diff = c( 1 , 0 , -1 ) ) )
svycontrast( aus.jr , list( diff = c( 0 , 1 , -1 ) ) )


# right side contrasts


# # # # albania # # # #

alb.read <- MIcombine( with( albania , svyby( ~readz , ~immig , svymean , na.rm = TRUE ) ) )

svycontrast( alb.read , list( diff = c( 1 , -1 , 0 ) ) )


# # # # brazil # # # #

brazil <- subset( pisa.imp , cnt == 'BRA' )

bra.read <- MIcombine( with( brazil , svyby( ~readz , ~immig , svymean , na.rm = TRUE ) ) )

svycontrast( bra.read , list( diff = c( 1 , -1 , 0 ) ) )



################################################
# end of replication #
################################################


# disconnect from the current monet database
dbDisconnect( db , shutdown = TRUE )

