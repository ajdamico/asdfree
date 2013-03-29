# analyze brazilian government survey data with the r language
# pesquisa nacional por amostra de domicilios
# 2011

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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# important note about why these statistics and standard errors do not precisely match the table packages available at:   #
# ftp://ftp.ibge.gov.br/Trabalho_e_Rendimento/Pesquisa_Nacional_por_Amostra_de_Domicilios_anual/2011/Sintese_Indicadores/ #
# the brazilian institute of statistics recently modified their methodology to use post-stratification so these final     #
# results from this script will be very close but not precisely exact. however, you can view the replication script in    #
# this directory which explains how these statistics *do* precisely match some statistics, standard errors, and           #
# coefficients of variation provided to me by the friendly folks at IBGE in other words, the analysis methods described   #
# in this script are methodologically justified and can safely be viewed as the correct way of doing things.              #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################################################
# prior to running this analysis script, the pnad 2011 file must be loaded as a database (.db) on the local machine.                                #
# running the 2011 download all microdata script will create this database file                                                                     #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/usgsd/blob/master/Pesquisa%20Nacional%20por%20Amostra%20de%20Domicilios/2001-2011%20-%20download%20all%20microdata.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "pnad.db" with 'pnad2011' in C:/My Directory/PNAD or wherever the working directory was set                        #
#####################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PNAD/" )
# ..in order to set your current working directory

# name the database (.db) file that should have been saved in the working directory
pnad.dbname <- "pnad.db"

require(downloader)	# downloads and then runs the source() function on scripts from github
require(survey)		# load survey package (analyzes complex design surveys)
require(RSQLite) 	# load RSQLite package (creates database files in R)
require(stringr) 	# load stringr package (manipulates character strings easily)

# set R to produce conservative standard errors instead of crashing
# http://faculty.washington.edu/tlumley/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN

# load pnad-specific functions (to remove invalid SAS input script fields and postStratify a database-backed survey object)
source_url( "https://raw.github.com/ajdamico/usgsd/master/Pesquisa Nacional por Amostra de Domicilios/pnad.survey.R" )



###############################################################
# step 1: connect to the pnad data table you'd like to recode # 
# then make a copy so you don't lose the pristine original.   #

# the command 
db <- dbConnect( SQLite() , pnad.dbname )
# connects the current instance of r to the sqlite database

# now simply copy you'd like to recode into a new table
dbSendQuery( db , "CREATE TABLE recoded_pnad2011 AS SELECT * FROM pnad2011" )
# this action protects the original 'pnad2011' table from any accidental errors.
# at any point, we can delete this recoded copy of the data table using the command..
# dbRemoveTable( db , "recoded_pnad2011" )
# ..and start fresh by re-copying the pristine file from pnad2011



############################################
# step 2: make all of your recodes at once #

# from this point forward, all commands will only touch the
# 'recoded_pnad2011' table.  the 'pnad2011' is now off-limits.

# add a new column.  call it, oh i don't know, agecat?
# since it's actually a categorical variable, make it VARCHAR( 255 )
dbSendQuery( db , "ALTER TABLE recoded_pnad2011 ADD COLUMN agecat VARCHAR( 255 )" )

# if you wanted to create a numeric variable, substitute VARCHAR( 255 ) with DOUBLE PRECISION like this:
# dbSendQuery( db , "ALTER TABLE recoded_pnad2011 ADD COLUMN agecatx DOUBLE PRECISION" )
# ..but then agecat would have to be be numbers (1 - 8) instead of the strings shown below ('01' - '08')


# by hand, you could set the values of the agecat column anywhere between '01' and '13'
dbSendQuery( db , "UPDATE recoded_pnad2011 SET agecat = '01' WHERE v8005 >= 0 AND v8005 < 5" )
dbSendQuery( db , "UPDATE recoded_pnad2011 SET agecat = '02' WHERE v8005 >= 5 AND v8005 < 10" )
dbSendQuery( db , "UPDATE recoded_pnad2011 SET agecat = '03' WHERE v8005 >= 10 AND v8005 < 15" )
dbSendQuery( db , "UPDATE recoded_pnad2011 SET agecat = '04' WHERE v8005 >= 15 AND v8005 < 20" )
dbSendQuery( db , "UPDATE recoded_pnad2011 SET agecat = '05' WHERE v8005 >= 20 AND v8005 < 25" )
dbSendQuery( db , "UPDATE recoded_pnad2011 SET agecat = '06' WHERE v8005 >= 25 AND v8005 < 40" )
dbSendQuery( db , "UPDATE recoded_pnad2011 SET agecat = '07' WHERE v8005 >= 40 AND v8005 < 60" )
dbSendQuery( db , "UPDATE recoded_pnad2011 SET agecat = '08' WHERE v8005 >= 60" )


# quickly check your work by running a simple SELECT COUNT(*) command with sql
dbGetQuery( db , "SELECT agecat , v8005 , COUNT(*) as number_of_records from recoded_pnad2011 GROUP BY agecat , v8005 ORDER BY v8005" )
# and notice that each value of v8005 has been deposited in the appropriate age category


# but all of that takes a while to write out.


# since there's so much repeated text in the commands above, 
# let's create the same agecat variable (agecat2 this time)
# with code you'll be able to modify a lot faster

# remember, since it's actually a categorical variable, make the column type VARCHAR( 255 )
dbSendQuery( db , "ALTER TABLE recoded_pnad2011 ADD COLUMN agecat2 VARCHAR( 255 )" )


# to automate things, just create a vector of each age bound
agebounds <- c( 0 , 5 , 10 , 15 , 20 , 25 , 40 , 60 , 200 )
# and loop through each interval, plugging in a new agecat for each value

# start at the value '0' and end at the value '200'.
for ( i in 1:( length( agebounds ) - 1 ) ){

	# build the sql string to pass to monetdb
	update.sql.string <- paste0( "UPDATE recoded_pnad2011 SET agecat2 = '" , str_pad( i , 2 , pad = '0' ) , "' WHERE v8005 >= " , agebounds[ i ] , " AND v8005 < " , agebounds[ i + 1 ] )
		
	# take a look at the update.sql.string you've just built.  familiar?  ;)
	print( update.sql.string )
	
	# now actually run the sql string
	dbSendQuery( db , update.sql.string )
}


# check your work by running a simple SELECT COUNT(*) command with sql
dbGetQuery( db , "SELECT agecat , agecat2 , COUNT(*) as number_of_records from recoded_pnad2011 GROUP BY agecat , agecat2 ORDER BY agecat" )
# and notice that there aren't any records where agecat does not equal agecat2



#############################################################################
# step 3: create a new survey design object connecting to the recoded table #

# to initiate a new complex sample survey design on the data table
# that's been recoded to include 'agecat"
# simply re-run the svydesign() and pnad.postStratify() functions and update the table.name =
# argument so it now points to the recoded_ table in the sqlite database

##############################################
# survey design for a database-backed object #
##############################################

# create survey design object with PNAD design information
# using existing data frame of PNAD data
unstratified.pnad <-
	svydesign(
		id = ~v4618 ,
		strata = ~v4617 ,
		data = "recoded_pnad2011" ,		# notice that this line now points to the recoded_pnad2011
		weights = ~v4610 ,
		nest = TRUE ,
		dbtype = "SQLite" ,
		dbname = "pnad.db"
	)
# note that the above object has been given the unwieldy name of `unstratified.pnad`
# so that it's not accidentally used in analysis commands.
# this object has not yet been appropriately post-stratified, as necessitated by IBGE
# in order to accurately match the brazilian 2010 census
	
# this block conducts a post-stratification on the un-post-stratified design
# and since the R `survey` package's ?postStratify currently does not work on database-backed survey objects,
# this uses a function custom-built for the PNAD.
y <- 
	pnad.postStratify( 
		design = unstratified.pnad ,
		strata.col = 'v4609' ,
		oldwgt = 'v4610'
	)

	
####################################################################
# two simple analysis examples to confirm the categories now exist #
####################################################################

# weighted count of individuals in each age category
svytotal( ~factor( agecat ) , y )

# weighted count of individuals of each gender, broken down by age category
svyby( ~factor( v0302 ) , ~agecat , y , svytotal )


# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
