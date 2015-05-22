# analyze survey data for free (http://asdfree.com) with the r language
# pesquisa mensal de emprego

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/PME/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Pesquisa%20Mensal%20de%20Emprego/unemployment%20rate.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# http://www.screenr.com/Zpd8

# djalma pessoa
# djalma.pessoa@ibge.gov.br

# anthony joseph damico
# ajdamico@gmail.com

# if you use this script for a project, please send me a note
# it's always nice to hear about how people are using this stuff

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf


########################################################################################################
# this script comes close to matching the IBGE-produced stats and coefficients of variation in here:   #
# ftp://ftp.ibge.gov.br/Trabalho_e_Rendimento/Pesquisa_Mensal_de_Emprego/Tabelas/2013/tab177112013.xls #
# for a discussion of the (tiny, negligible, irrelevant) differences, take a look at the replication.R #
########################################################################################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###############################################################################################################
# prior to running this analysis script, all pme files must be loaded on the local machine.  running the      #
# download all microdata script will create the series of data files (.rda) in the current working directory. #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/usgsd/blob/master/Pesquisa%20Mensal%20de%20Emprego/download%20all%20microdata.R #
###############################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# remove the # in order to run this install.packages line only once
# install.packages( c( "survey" , "reshape2" , "ggplot2" ) )


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PME/" )
# ..in order to set your current working directory

library(survey)		# load survey package (analyzes complex design surveys)
library(reshape2)	# load reshape2 package (transposes data frames quickly)
library(ggplot2)	# load ggplot2 package (plots data according to the grammar of graphics)


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
all.pme.files <- list.files()


# since the alphabetical order of the pme files
# matches their chronological order, extracting the final..
most.recent.months <- 12
# ..months (change that number s'il vous plait)
# should be straightforward.

recent.pme.files <- 
	all.pme.files[ 
		length( all.pme.files ):( length( all.pme.files ) - most.recent.months + 1 ) 
	]

	
# create a `coefs` and `cvs` data.frame object
# to store the unemployment rate for every available file
coefs <- cvs <- empty <-
		data.frame( 
			year = numeric() ,
			month = numeric() ,
			overall = numeric() ,
			recife = numeric() ,
			salvador = numeric() ,
			belo.horizonte = numeric() ,
			rio.de.janeiro = numeric() ,
			sao.paulo = numeric() ,
			porto.alegre = numeric() 
		)
# this object <- other.object <- another.object syntax
# simply creates all of them at once.  so efficient!
		
# use the `rev` function to reverse the order,
# so the first row of the table is the oldest month
# (just like the table this script attempts to replicate)

# loop through only the recent pme files
for ( i in rev( recent.pme.files ) ){
# if you like, you could comment the line above and uncomment the line below .. and compute the unemployment rate for all available months.
# for ( i in rev( all.pme.files ) ){
	
	# print the current `.rda` file
	print( i )

	# load the current `.rda` file
	load( i )
	
	# extract the file year from the filename
	this.year <- substr( i , 5 , 8 )
	
	# extract the file month from the filename
	this.month <- substr( i , 10 , 11 )
	
	# calculate whether each person is at least ten years of age
	x$pia <- as.numeric( x$v234 >= 10 )

	# determine individuals who are employed
	x$ocup_c <- as.numeric( x$v401 == 1 | x$v402 == 1 | x$v403 == 1 )
	
	# determine individuals who are unemployed
	x$desocup30 <- as.numeric( x$ocup_c == 0 & !is.na( x$v461 ) & x$v465 == 1 )
	
	# determine individuals who are either working or not working
	# (that is, the potential labor force)
	x$pea_c <- as.numeric( x$ocup_c == 1 | x$desocup30 == 1 )
 
	
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

	
	# take the `empty` table and create
	# two more copies of it.
	empty.coef <- empty.cv <- empty
	
	# calculate the unemployment rate, as a share of the total labor force
	overall <- svyratio( ~desocup30 , ~pea_c , w , na.rm = TRUE )
  	# store the result in an `overall` object
	
	# calculate the same unemployment rate, but broken down by region of the country
	region <- svyby( ~desocup30 , ~v035 , w , svyratio , denominator = ~pea_c , na.rm= TRUE )
	# store the result in a `region` object
	
	# combine the overall and regional counts into
	# the 1st row and 3rd thru 9th column of the coefficient data.frame
	empty.coef[ 1 , 3:9 ] <- c( coef( overall ) , coef( region ) )
	
	
	# combine the overall and regional coefficients of variation into
	# the 1st row and 3rd thru 9th column of the coefficient data.frame
	empty.cv[ 1 , 3:9 ] <- c( cv( overall ) , cv( region ) )

	# store the current year and month in the first and second column of the same objects
	empty.coef[ 1 , 1:2 ] <- empty.cv[ 1 , 1:2 ] <- c( this.year , this.month )
	
	# stack the current month below any previously-run months
	coefs <- rbind( coefs , empty.coef )
	
	# see above.  same deal.
	cvs <- rbind( cvs , empty.cv )
	
	# remove all four objects from working memory
	rm( w , x , y , z )
	
	# clear up RAM
	gc()
	
}

# round all of the totals to the nearest thousand
coefs[ , 3:9 ] <- round( coefs[ , 3:9 ] * 100 , 1 )

# multiply all coefficients of variation by one hundred,
# then round to one decimal place
cvs[ , 3:9 ] <- round( cvs[ , 3:9 ] * 100 , 1 )

# # # # # # # # # # # # # # # # # #
# come close to tab177112013.xls  #
# # # # # # # # # # # # # # # # # #

# print the coefficients table to the screen
coefs

# print the cv table to the screen
cvs



# # # # #
# bonus #
# # # # #


# plot the overall and regional unemployment rate for the last 12 months #

# compress the `coefs` table down to
# a new table with four columns: year, month, region of the country, and the data point
desocup.rate.long <-
	melt( 
		coefs ,
		id = c( "year" , "month" ) , 
		variable.name = "region" , 
		value.name = "desocup.rate"
	)

# compress the year and month columns into a single variable
desocup.rate.long$year.month <-
	paste(
		substr( desocup.rate.long$year , 3 , 4 ) , 
		desocup.rate.long$month ,
		sep = "/"
	)

# construct a plot with this newly-rehshaped data
desocup.plot <- 
	ggplot(
		desocup.rate.long , 
		aes( year.month , desocup.rate , group = region , colour = region ) 
	) + 
	ylim( 0 , max( desocup.rate.long$desocup.rate ) ) +
	geom_line() + 
	labs( title = "out of work rate over the last 12 months" )

# print the plot to the screen
desocup.plot

# happy?


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
