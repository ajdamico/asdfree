# analyze survey data for free (http://asdfree.com) with the r language
# pesquisa nacional por amostra de domicilios
# 2012

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( encoding = "windows-1252" )		# # only macintosh and *nix users need this line
# library(downloader)
# setwd( "C:/My Directory/PNAD/" )
# year.to.analyze <- 2012
# source_url( "https://raw.github.com/ajdamico/asdfree/master/Pesquisa%20Nacional%20por%20Amostra%20de%20Domicilios/single-year%20-%20analysis%20examples.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# https://www.youtube.com/watch?v=JLt9JfaAxUg

# djalma pessoa
# pessoad@gmail.com

# anthony joseph damico
# ajdamico@gmail.com

# if you use this script for a project, please send me a note
# it's always nice to hear about how people are using this stuff

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# important note about why these statistics and standard errors do not precisely match the table packages available at:   #
# ftp://ftp.ibge.gov.br/Trabalho_e_Rendimento/Pesquisa_Nacional_por_Amostra_de_Domicilios_anual/2011/Sintese_Indicadores/ #
# the brazilian institute of statistics round the post-stratifed weights, which has no theoretical effect. so these final #
# results from this script will be very close but not precisely exact. however, you can view the replication script in    #
# this directory which explains how these statistics *do* precisely match some statistics, standard errors, and           #
# coefficients of variation provided to me by the friendly folks at IBGE in other words, the analysis methods described   #
# in this script are methodologically justified and can safely be viewed as the correct way of doing things.              #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################################
# prior to running this analysis script, the pnad file must be loaded as a database (.db) on the local machine.                     #
# running the download all microdata script will create this database file                                                          #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/asdfree/blob/master/Pesquisa%20Nacional%20por%20Amostra%20de%20Domicilios/download%20all%20microdata.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "pnad.db" with 'pnad2012' in C:/My Directory/PNAD or wherever the working directory was set        #
#####################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# uncomment these two lines by removing the `#` at the front..
# setwd( "C:/My Directory/PNAD/" )
# year.to.analyze <- 2012
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
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(MonetDBLite)	# load MonetDBLite package (creates database files in R)


# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN

# load pnad-specific functions (to remove invalid SAS input script fields and postStratify a database-backed survey object)
source_url( "https://raw.github.com/ajdamico/asdfree/master/Pesquisa Nacional por Amostra de Domicilios/pnad.survey.R" , prompt = FALSE )


##############################################
# survey design for a database-backed object #
##############################################

# create survey design object with PNAD design information
# using existing table of PNAD data
sample.pnad <-
	svydesign(
		id = ~v4618 ,
		strata = ~v4617 ,
		data = paste0( "pnad" , year.to.analyze ) ,
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
	
	
###########################
# variable recode example #
###########################


# construct a new age category variable in the dataset: 0-4, 5-9, 10-14...55-59, 60+
y <- update( y , agecat = 1 + findInterval( v8005 , seq( 5 , 60 , 5 ) ) )

# print the distribution of that age category
svymean( ~ factor( agecat ) , y )

	
#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in pnad #
# broken out by region #

svyby(
	~one ,
	~region ,
	y ,
	unwtd.count
)



# count the weighted number of individuals in pnad #

# the population of brazil #
svytotal(
	~one ,
	y
)

# the population of brazil #
# by region
svyby(
	~one ,
	~region ,
	y ,
	svytotal
)


# calculate the mean of a linear variable #

# average age
svymean(
	~v8005 ,
	design = y
)

# by region
svyby(
	~v8005 ,
	~region ,
	design = y ,
	svymean
)


# calculate the distribution of a categorical variable #

# percent male vs. female - nationwide
svymean(
	~factor( v0302 ) ,
	design = y
)

# by region
svyby(
	~factor( v0302 ) ,
	~region ,
	design = y ,
	svymean
)

# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum ages
svyquantile(
	~v8005 ,
	design = y ,
	c( 0 , .25 , .5 , .75 , 1 )
)

# by region
svyby(
	~v8005 ,
	~region ,
	design = y ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	ci = TRUE
)

######################
# subsetting example #
######################

# restrict the y object to
# females only
y.female <-	subset( y , v0302 == 4 )
# now any of the above commands can be re-run
# using y.female object
# instead of the y object
# in order to analyze females only

# calculate the mean of a linear variable #

# average age
svymean(
	~v8005 ,
	design = y.female
)



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by region

# store the results into a new object

gender.by.region <-
	svyby(
		~factor( v0302 ) ,
		~region ,
		design = y ,
		svymean
	)

# print the results to the screen
gender.by.region

# now you have the results saved into a new object of type "svyby"
class( gender.by.region )

# print only the statistics (coefficients) to the screen
coef( gender.by.region )

# print only the standard errors to the screen
SE( gender.by.region )

# print only the coefficients of variation to the screen
cv( gender.by.region )

# this object can be coerced (converted) to a data frame..
gender.by.region <- data.frame( gender.by.region )

# ..and then immediately exported as a comma-separated value file
# into your current working directory
write.csv( gender.by.region , "gender by region.csv" )

# ..or trimmed to only contain the values you need.
# here's the "percent female" by region,
# with accompanying standard errors
female.by.region <-
	gender.by.region[ , c( "region" , "factor.v0302.4" , "se.factor.v0302.4" ) ]


# print the new results to the screen
female.by.region

# this can also be exported as a comma-separated value file
# into your current working directory
write.csv( female.by.region , "female by region.csv" )

# ..or directly made into a bar plot
barplot(
	female.by.region[ , 2 ] ,
	main = "Female by Region" ,
	names.arg = c( "North" , "Northeast" , "Southeast" , "South" , "Center-West" ) ,
	ylim = c( 0 , .52 )
)

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
