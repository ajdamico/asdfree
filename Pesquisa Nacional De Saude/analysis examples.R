# analyze survey data for free (http://asdfree.com) with the r language
# pesquisa nacional de saude

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/PNS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Pesquisa%20Nacional%20De%20Saude/analysis%20examples.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# djalma pessoa
# pessoad@gmail.com

# anthony joseph damico
# ajdamico@gmail.com


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#########################################################################################################################
# prior to running this analysis script, the pns 2013 file must be loaded on the local machine with this script:        #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/Pesquisa%20Nacional%20De%20Saude/download%20and%20import.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "2013 long questionnaire survey design.rda" in the working directory                   #
#########################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PNS/" )
# ..in order to set your current working directory


library(survey) 	# load survey package (analyzes complex design surveys)


# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN
# SAS uses "remove" instead of "adjust" by default,
# the table target replication was generated with SAS,
# so if you want to get closer to that, use "remove"
# remember: you will not hit the IBGE excel file exactly,
# because the public use file rounds the weights.  sorry 'bout that


load( "2013 long questionnaire survey design.rda" )
	

#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in pns #
# broken out by urban/rural
svyby( ~ one , ~ situ , pes_sel_des_pos , unwtd.count )

# count the weighted number of individuals in pns #
svytotal( ~one , pes_sel_des_pos )

# the broken-out population by urban/rural
svyby( ~ one , ~ situ , pes_sel_des_pos , svytotal )


# calculate the mean of a linear variable #

# average age
svymean(
	~ as.numeric( c008 ) ,
	design = pes_sel_des_pos
)

# by urban/rural
svyby(
	~ as.numeric( c008 ) ,
	~ situ ,
	design = pes_sel_des_pos ,
	svymean
)


# calculate the distribution of a categorical variable #

# percent male vs. female - among only the six metro areas
svymean(
	~ c006 ,
	design = pes_sel_des_pos
)

# by urban/rural
svyby(
	~ c006 ,
	~ situ ,
	design = pes_sel_des_pos ,
	svymean
)

# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum ages
svyquantile(
	~ c008 ,
	design = pes_sel_des_pos ,
	c( 0 , .25 , .5 , .75 , 1 )
)

# by urban/rural
svyby(
	~ c008 ,
	~ situ ,
	design = pes_sel_des_pos ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	ci = TRUE
)


######################
# subsetting example #
######################

# restrict the pes_sel_des_pos object to
# females only
pes_sel_des_pos.female <- subset( pes_sel_des_pos , c006 == 2 )
# now any of the above commands can be re-run
# using pes_sel_des_pos.female object
# instead of the pes_sel_des_pos object
# in order to analyze females only

# calculate the mean of a linear variable #

# average age
svymean(
	~ c008 ,
	design = pes_sel_des_pos.female
)



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by urban/rural

# store the results into a new object

gender.by.urban.rural <-
	svyby(
		~ c006 ,
		~ situ ,
		design = pes_sel_des_pos ,
		svymean
	)

# print the results to the screen
gender.by.urban.rural

# now you have the results saved into a new object of type "svyby"
class( gender.by.urban.rural )

# print only the statistics (coefficients) to the screen
coef( gender.by.urban.rural )

# print only the standard errors to the screen
SE( gender.by.urban.rural )

# print only the coefficients of variation to the screen
cv( gender.by.urban.rural )

# this object can be coerced (converted) to a data frame..
gender.by.urban.rural <- data.frame( gender.by.urban.rural )

# ..and then immediately exported as a comma-separated value file
# into your current working directory
write.csv( gender.by.urban.rural , "gender by urban rural.csv" )

# ..or trimmed to only contain the values you need.
# here's the "percent female" by urban/rural,
# with accompanying standard errors
female.by.urban.rural <-
	gender.by.urban.rural[ , c( "situ" , "c006feminino" , "se.c006feminino" ) ]


# print the new results to the screen
female.by.urban.rural

# this can also be exported as a comma-separated value file
# into your current working directory
write.csv( female.by.urban.rural , "female by urban rural.csv" )

# ..or directly made into a bar plot
barplot(
	female.by.urban.rural[ , 2 ] ,
	main = "Percent Female by Urban/Rural" ,
	names.arg = c( "Urban" , "Rural" ) ,
	ylim = c( .40 , .6 ) ,
	cex.names = 0.7
)
