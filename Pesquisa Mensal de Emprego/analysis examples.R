# analyze survey data for free (http://asdfree.com) with the r language
# pesquisa mensal de emprego

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/PME/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Pesquisa%20Mensal%20de%20Emprego/analysis%20examples.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# djalma pessoa
# pessoad@gmail.com

# anthony joseph damico
# ajdamico@gmail.com


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###############################################################################################################
# prior to running this analysis script, all pme files must be loaded on the local machine.  running the      #
# download all microdata script will create the series of data files (.rda) in the current working directory. #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/asdfree/blob/master/Pesquisa%20Mensal%20de%20Emprego/download%20all%20microdata.R #
###############################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# remove the # in order to run this install.packages line only once
# install.packages( "survey" )


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PME/" )
# ..in order to set your current working directory

library(survey)		# load survey package (analyzes complex design surveys)


# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN
# SAS uses "remove" instead of "adjust" by default,
# the table target replication was generated with SAS,
# so if you want to get closer to that, use "remove"
# remember: you will not hit the IBGE excel file exactly,
# because the public use file rounds the weights.  sorry 'bout that


# in the current working directory,
# list all available files
list.files()


# load the march 2013 file
load( "pme 2013 03.rda" )
	
# # # # # # # # # # # # # # # # #
# perform any necessary recodes #

# calculate whether each person is at least ten years of age
x$pia <- as.numeric( x$v234 >= 10 )

# determine individuals who are employed
x$ocup_c <- as.numeric( x$v401 == 1 | x$v402 == 1 | x$v403 == 1 )

# determine individuals who are unemployed
x$desocup30 <- as.numeric( x$ocup_c == 0 & !is.na( x$v461 ) & x$v465 == 1 )

# determine individuals who are either working or not working
# (that is, the potential labor force)
x$pea_c <- as.numeric( x$ocup_c == 1 | x$desocup30 == 1 )

# add a column of all ones
x$one <- 1

# end of recoding #
# # # # # # # # # #


# throw out records missing their cluster variable
z <- subset( x , !is.na( v113 ) )
# these are simply discarded.  hooray!


# the `v035` and `v114` columns contain the six numbers
# (and merge variables) needed for population post-stratification
pop.totals <- unique( z[ , c( 'v035' , 'v114' ) ] )
# you really just gotta grab the unique values, not one-per-record. ;)
	

#############################
# survey design for the pme #
#############################

# step number one #
y <- 
	svydesign( 
		~v113 , 
		strata = ~v112 , 
		data = z ,
		weights = ~v211 , 
		nest = TRUE
	)

# step number two #
w <- 
	postStratify( 
		y , 
		~v035 ,
		pop.totals
	)

# the object `w` will be your object to analyze.  not `y`
	
#################################
# end of survey design creation #
#################################


#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in pme #
# broken out by metro area #

svyby(
	~one ,
	~v035 ,
	w ,
	unwtd.count
)



# count the weighted number of individuals in pme #

# the combined population of the metropolitan areas of
# recife, salvador, belo horizonte, rio de janeiro, sao paulo and porto alegre
svytotal(
	~one ,
	w
)

# the broken-out population of the metropolitan areas of
# recife, salvador, belo horizonte, rio de janeiro, sao paulo and porto alegre
svyby(
	~one ,
	~v035 ,
	w ,
	svytotal
)


# calculate the mean of a linear variable #

# average age
svymean(
	~v234 ,
	design = w
)

# by metro area
svyby(
	~v234 ,
	~v035 ,
	design = w ,
	svymean
)


# calculate the distribution of a categorical variable #

# percent male vs. female - among only the six metro areas
svymean(
	~factor( v203 ) ,
	design = w
)

# by metro area
svyby(
	~factor( v203 ) ,
	~v035 ,
	design = w ,
	svymean
)

# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum ages
svyquantile(
	~v234 ,
	design = w ,
	c( 0 , .25 , .5 , .75 , 1 )
)

# by metro area
svyby(
	~v234 ,
	~v035 ,
	design = w ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	ci = TRUE
)



# calculate a rate, the unemployed share of the total labor force
svyratio( 
	~desocup30 , 
	~pea_c , 
	w , 
	na.rm = TRUE 
)


# calculate the same rate, but broken down by metro area of the country
svyby( 
	formula = ~desocup30 , 
	by = ~v035 , 
	design = w , 
	svyratio , 
	denominator = ~pea_c , 
	na.rm = TRUE 
)
	


######################
# subsetting example #
######################

# restrict the w object to
# females only
w.female <-	subset( w , v203 == 2 )
# now any of the above commands can be re-run
# using w.female object
# instead of the w object
# in order to analyze females only

# calculate the mean of a linear variable #

# average age
svymean(
	~v234 ,
	design = w.female
)



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by metro area

# store the results into a new object

gender.by.metro.area <-
	svyby(
		~factor( v203 ) ,
		~v035 ,
		design = w ,
		svymean
	)

# print the results to the screen
gender.by.metro.area

# now you have the results saved into a new object of type "svyby"
class( gender.by.metro.area )

# print only the statistics (coefficients) to the screen
coef( gender.by.metro.area )

# print only the standard errors to the screen
SE( gender.by.metro.area )

# print only the coefficients of variation to the screen
cv( gender.by.metro.area )

# this object can be coerced (converted) to a data frame..
gender.by.metro.area <- data.frame( gender.by.metro.area )

# ..and then immediately exported as a comma-separated value file
# into your current working directory
write.csv( gender.by.metro.area , "gender by metro area.csv" )

# ..or trimmed to only contain the values you need.
# here's the "percent female" by metro area,
# with accompanying standard errors
female.by.metro.area <-
	gender.by.metro.area[ , c( "v035" , "factor.v203.2" , "se.factor.v203.2" ) ]


# print the new results to the screen
female.by.metro.area

# this can also be exported as a comma-separated value file
# into your current working directory
write.csv( female.by.metro.area , "female by metro area.csv" )

# ..or directly made into a bar plot
barplot(
	female.by.metro.area[ , 2 ] ,
	main = "Percent Female by Metro Area" ,
	names.arg = c( "Recife" , "Salvador" , "Belo Horizonte" , "Rio de Janeiro" , "Sao Paulo" , "Porto Alegre" ) ,
	ylim = c( .45 , .6 ) ,
	cex.names = 0.7
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
