# analyze survey data for free (http://asdfree.com) with the r language
# pesquisa nacional por amostra de domicilios
# 2011

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( encoding = "windows-1252" )		# # only macintosh and *nix users need this line
# library(downloader)
# setwd( "C:/My Directory/PNAD/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Pesquisa%20Nacional%20por%20Amostra%20de%20Domicilios/replicate%20IBGE%20estimates%20-%202011.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# djalma pessoa
# pessoad@gmail.com

# anthony joseph damico
# ajdamico@gmail.com


####################################################################################################################################################################
# this script matches the results of the SAS-SUDAAN code sent to me by Marcos Paulo Soares de Freitas at IBGE.  IBGE is the brazilian census bureau/stats agency   #
# email: https://github.com/ajdamico/asdfree/blob/master/Pesquisa%20Nacional%20por%20Amostra%20de%20Domicilios/2011%20PNAD%20SAS-SUDAAN%20e-mail%20from%20IBGE.pdf #
# excel: https://github.com/ajdamico/asdfree/blob/master/Pesquisa%20Nacional%20por%20Amostra%20de%20Domicilios/ESTIMATES%20from%20IBGE.XLS                         #
#  code: https://github.com/ajdamico/asdfree/blob/master/Pesquisa%20Nacional%20por%20Amostra%20de%20Domicilios/SAS-SUDAAN%20code%20from%20IBGE.sas                 #
####################################################################################################################################################################



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#######################################################################################################################################
# prior to running this analysis script, the pnad 2011 file must be loaded as a database (.db) on the local machine.                  #
# running the 2011 download all microdata script will create this database file                                                       #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/asdfree/blob/master/Pesquisa%20Nacional%20por%20Amostra%20de%20Domicilios/download%20all%20microdata.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "pnad.db" with 'pnad2011' in C:/My Directory/PNAD or wherever the working directory was set          #
#######################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PNAD/" )
# ..in order to set your current working directory


# # # are you on a non-windows system? # # #
if ( .Platform$OS.type != 'windows' ) print( 'non-windows users: read this block' )
# ibge's ftp site has a few SAS importation
# scripts in a non-standard format
# if so, before running this whole download program,
# you might need to run this line..
# options( encoding="windows-1252" )
# ..to turn on windows-style encoding.
# # # end of non-windows system edits.


# name the database files in the "MonetDB" folder of the current working directory
pnad.dbfolder <- paste0( getwd() , "/MonetDB" )


library(downloader)		# downloads and then runs the source() function on scripts from github
library(survey)			# load survey package (analyzes complex design surveys)
library(DBI)			# load the DBI package (implements the R-database coding)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(MonetDBLite)	# load MonetDBLite package (creates database files in R)


# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN

# load pnad-specific functions (to remove invalid SAS input script fields and postStratify a database-backed survey object)
source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Pesquisa%20Nacional%20por%20Amostra%20de%20Domicilios/pnad.survey.R" , prompt = FALSE )


##############################################
# survey design for a database-backed object #
##############################################

# create survey design object with PNAD design information
# using existing table of PNAD data
sample.pnad <-
	svydesign(
		id = ~v4618 ,
		strata = ~v4617 ,
		data = "pnad2011" ,
		weights = ~pre_wgt ,
		nest = TRUE ,
		dbtype = "MonetDBLite" ,
		dbname = pnad.dbfolder
	)
# note that the above object has been given the unwieldy name of `sample.pnad`
# so that it's not accidentally used in analysis commands.
# this object has not yet been appropriately post-stratified, as necessitated by IBGE
# in order to accurately match the brazilian 2010 census projections
	
# this block conducts a post-stratification on the un-post-stratified design
# and since the R `survey` package's ?postStratify currently does not work on database-backed survey objects,
# this uses a function custom-built for the PNAD.
y <- 
	pnad.postStratify( 
		design = sample.pnad ,
		strata.col = 'v4609' ,
		oldwgt = 'pre_wgt'
	)

# count the weighted number of individuals, then broken down by gender,
# and also calculate the standard error and coefficient of variation
# using the newly-created post-stratified survey design object
svytotal( ~one , y )
svytotal( ~factor( v0302 ) , y )
cv( svytotal( ~factor( v0302 ) , y ) )

# note that this exactly matches the SAS-SUDAAN-produced file
# ESTIMATES from IBGE.XLS

################################
# end of IBGE code replication #
################################
