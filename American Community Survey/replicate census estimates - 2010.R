# importation and analysis of us government survey data
# american community survey
# 2010 persons and household files

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


#####################################################
# this script matches the nationwide statistics at  ###############################################
# http://www.census.gov/acs/www/Downloads/data_documentation/pums/Estimates/pums_estimates_10.lst #
###################################################################################################



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################################################
# prior to running this analysis script, the acs 2010 single-year file must be loaded as a database (.db) on the local machine.                     #
# running the 2010 download and create database script will create this database file                                                               #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/usgsd/master/American%20Community%20Survey/2010%201-3-5%20year%20files%20-%20download%20and%20create%20database.R #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "acs2010_1yr.db" in C:/My Directory/ACS or wherever the working directory was set during execution of the program  #
#####################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# set your working directory.
# this directory must contain the ACS 2010 database (.db) file 
# "acs2010_1yr.db" created by the R program specified above
# use forward slashes instead of back slashes

setwd( "C:/My Directory/ACS/" )


# remove the # in order to run this install.packages line only once
# install.packages( c( "survey" , "RSQLite" ) )


require(survey)		# load survey package (analyzes complex design surveys)
require(RSQLite) 	# load RSQLite package (creates database files in R)


# set R to produce conservative standard errors instead of crashing
# http://faculty.washington.edu/tlumley/survey/exmample-lonely.html
# options( survey.lonely.psu = "adjust" )


# if this option is set to TRUE
# R will exactly match SUDAAN results and Stata with the MSE option results
options( survey.replicates.mse = TRUE )
# otherwise if it is commented out or set to FALSE
# R will exactly match Stata without the MSE option results

# Stata svyset command notes can be found here: http://www.stata.com/help.cgi?svyset



# choose which file to analyze: one-year, three-year, or five-year file
# this script replicates 2010 single-year estimates,
# so leave that line uncommented and the other two choices commented out

fn <- 'acs2010_1yr' 		# analyze the 2010 single-year acs
# fn <- 'acs2010_3yr'		# analyze the 2008-2010 acs
# fn <- 'acs2010_5yr'		# analyze the 2006-2010 acs



# using a database-backed survey object
# (described here: http://faculty.washington.edu/tlumley/survey/svy-dbi.html )
# create the american community survey 2010 single-year design


# choose between the RAM-intensive survey object (with correct standard errors)
# or the RAM-minimizing survey object (with incorrect standard errors)

#######################################################################
# this svrepdesign() call uses RAM-hogging code (requires about 11GB) #
# and includes the correct standard error computations in the output  #
# if using a less-powerful computer, skip this next block and         #
# uncomment the following one to compute statistics only (no errors)  #
#######################################################################


acs.10.m.design <- 									# name the survey object
	svrepdesign(									# svrepdesign function call.. type ?svrepdesign for more detail
		weights = ~pwgtp, 							# person-level weights are stored in column "pwgtp"
		repweights = "pwgtp[0-9]" ,					# the acs contains 80 replicate weights, pwgtp1 - pwgtp80.  this [0-9] format captures all numeric values
		type = "Fay", 								# use a fay's adjustment of four..  
		rho = ( 1 - 1 / sqrt( 4 ) ),				# ..note that these two lines are the SUDAAN equivalent of using adjfay = 4;
		data = paste0( fn , '_m' ) , 				# use the person-household-merge data table
		dbname = paste0( './' , fn , '.db' ) , 		# stored inside the database (acs2010_1yr.db)
		dbtype="SQLite"								# use SQLite as the SQL engine
	)

# end of database-backed survey object creation #
	

###########################################################################
# this svydesign() call minimizes RAM usage but will produce incorrect    #
# standard errors (SEs) for all subsequent analyses.                      #
# if you think buying 11GB of RAM is expensive, try buying a SAS license. #
###########################################################################


# acs.10.m.design <- 									# name the survey object
	# svydesign(										# svydesign function call.. type ?svydesign for more detail
		# ~1 ,											# specify non-existent PSUs (responsible for incorrect SE calculation)
		# weights = ~pwgtp, 							# person-level weights are stored in column "pwgtp"
		# data = paste0( fn , '_m' ) , 					# use the person-household-merge data table
		# dbname = paste0( './' , fn , '.db' ) , 		# stored inside the database (acs2010_1yr.db)
		# dbtype="SQLite"								# use SQLite as the SQL engine
	# )

# end of low-RAM, incorrect-SE database-backed survey object creation #	

	
# exclude puerto rico to match the published tables #

acs.10.51.m.design <-
	subset( 
		acs.10.m.design , 								# subset the survey object created above..
		!( st %in% 72 ) 								# ..to exclude state fips code 72 (puerto rico)
	)
	
#############################################################################
# ..and immediately start printing each row matching the replication target #
#############################################################################

# http://www.census.gov/acs/www/Downloads/data_documentation/pums/Estimates/pums_estimates_10.lst #


#####################################################
# census code replication of person-level estimates #
#####################################################

	
svytotal( ~as.numeric( relp %in% 0:17 ) , acs.10.51.m.design )					# total population
svytotal( ~as.numeric( relp %in% 0:15 ) , acs.10.51.m.design )					# housing unit population
svytotal( ~as.numeric( relp %in% 16:17 ) , acs.10.51.m.design )					# gq population
svytotal( ~as.numeric( relp %in% 16 ) , acs.10.51.m.design )					# gq institutional population
svytotal( ~as.numeric( relp %in% 17 ) , acs.10.51.m.design )					# gq noninstitutional population
svyby( ~as.numeric( relp %in% 0:17 ) , ~sex , acs.10.51.m.design , svytotal )	# total males & females


# all age categories #

svytotal( ~as.numeric( agep %in% 0:4 ) , acs.10.51.m.design )
svytotal( ~as.numeric( agep %in% 5:9 ) , acs.10.51.m.design )
svytotal( ~as.numeric( agep %in% 10:14 ) , acs.10.51.m.design )
svytotal( ~as.numeric( agep %in% 15:19 ) , acs.10.51.m.design )
svytotal( ~as.numeric( agep %in% 20:24 ) , acs.10.51.m.design )
svytotal( ~as.numeric( agep %in% 25:34 ) , acs.10.51.m.design )
svytotal( ~as.numeric( agep %in% 35:44 ) , acs.10.51.m.design )
svytotal( ~as.numeric( agep %in% 45:54 ) , acs.10.51.m.design )
svytotal( ~as.numeric( agep %in% 55:59 ) , acs.10.51.m.design )
svytotal( ~as.numeric( agep %in% 60:64 ) , acs.10.51.m.design )
svytotal( ~as.numeric( agep %in% 65:74 ) , acs.10.51.m.design )
svytotal( ~as.numeric( agep %in% 75:84 ) , acs.10.51.m.design )
svytotal( ~as.numeric( agep %in% 85:200 ) , acs.10.51.m.design )
svytotal( ~as.numeric( agep %in% 85 ) , acs.10.51.m.design )


# note: the MOE (margin of error) column can be calculated as the standard error x 1.645 #


###############################################
# end of person-level census code replication #
###############################################


# now in order to conserve RAM..

# remove both the merged design and the subset from memory
rm( acs.10.51.m.design , acs.10.m.design )

# ..and then clear up RAM
gc()


#################################################################################
# load the household table to produce the second half of the national estimates #
#################################################################################

# notice the _m becomes _h inside the svrepdesign() function call #

# once again, pick RAM-hogging or incorrect standard errors #


# choose between the RAM-intensive survey object (with correct standard errors)
# or the RAM-minimizing survey object (with incorrect standard errors)

#######################################################################
# this svrepdesign() call uses RAM-hogging code (requires about 11GB) #
# and includes the correct standard error computations in the output  #
# if using a less-powerful computer, skip this next block and         #
# uncomment the following one to compute statistics only (no errors)  #
#######################################################################


acs.10.hh.design <- 							
	svrepdesign(									
		weights = ~wgtp, 							# # # # this differs from the person-household-merge: use the household-weights, wgtp # # # #
		repweights = "wgtp[0-9]" ,					# # # # this differs from the person-household-merge: use the household-replicate weights, wgtp1-wgtp80 # # # #
		type = "Fay", 								
		rho = ( 1 - 1 / sqrt( 4 ) ),				
		data = paste0( fn , '_h' ) , 				# # # # this differs from the person-household-merge: use the household-only data table # # # #
		dbname = paste0( './' , fn , '.db' ) , 		
		dbtype="SQLite"								
	)

# end of database-backed survey object creation #
	

###########################################################################
# this svydesign() call minimizes RAM usage but will produce incorrect    #
# standard errors (SEs) for all subsequent analyses.                      #
# if you think buying 11GB of RAM is expensive, try buying a SAS license. #
###########################################################################


# acs.10.hh.design <- 								
	# svydesign(										
		# ~1 ,											
		# weights = ~wgtp, 								# # # # this differs from the person-household-merge: use the household-weights, wgtp # # # #
		# data = paste0( fn , '_h' ) , 					# # # # this differs from the person-household-merge: use the household-only data table, _h not _m # # # #
		# dbname = paste0( './' , fn , '.db' ) , 		
		# dbtype="SQLite"								
	# )

# end of low-RAM, incorrect-SE database-backed survey object creation #	


# exclude puerto rico to match the published tables #

acs.10.51.hh.design <-
	subset( 
		acs.10.hh.design , 								# subset the survey object created above..
		!( st %in% 72 ) 								# ..to exclude state fips code 72 (puerto rico)
	)
	
#############################################################################
# ..and immediately start printing each row matching the replication target #
#############################################################################

# http://www.census.gov/acs/www/Downloads/data_documentation/pums/Estimates/pums_estimates_10.lst #


######################################################
# census code replication of housing-level estimates #
######################################################
	

svytotal( ~as.numeric( type %in% 1 ) , acs10.51.hh.design )							# total housing units
svytotal( ~as.numeric( ten %in% 1:4 ) , acs10.51.hh.design )						# occupied units
svytotal( ~as.numeric( ten %in% 1:2 ) , acs10.51.hh.design )						# owner-occupied units
svytotal( ~as.numeric( ten %in% 3:4 ) , acs10.51.hh.design )						# renter-occupied units
svytotal( ~as.numeric( ten %in% 1 ) , acs10.51.hh.design )							# owned with mortgage
svytotal( ~as.numeric( ten %in% 2 ) , acs10.51.hh.design )							# owned free and clear
svytotal( ~as.numeric( ten %in% 3 ) , acs10.51.hh.design )							# rented for cash
svytotal( ~as.numeric( ten %in% 4 ) , acs10.51.hh.design )							# no cash rent
svytotal( ~as.numeric( vacs %in% 1:7 ) , acs10.51.hh.design )						# total vacant units
svytotal( ~as.numeric( vacs %in% 1 ) , acs10.51.hh.design )							# for rent
svytotal( ~as.numeric( vacs %in% 3 ) , acs10.51.hh.design )							# for sale only
svytotal( ~as.numeric( vacs %in% c( 2, 4 , 5 , 6 , 7 ) ) , acs10.51.hh.design )		# all other vacant


# note: the MOE (margin of error) column can be calculated as the standard error x 1.645 #


################################################
# end of housing-level census code replication #
################################################
