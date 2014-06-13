# analyze survey data for free (http://asdfree.com) with the r language
# pesquisa mensal de emprego

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/PME/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Pesquisa%20Mensal%20de%20Emprego/replication.R" , prompt = FALSE , echo = TRUE )
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


################################################################################################################################################################################
# this script matches the output sent to Djalma by Fabiane at COREN, the IBGE department responsible for the PME.  IBGE is the brazilian census bureau/stats agency.           #
# email: https://github.com/ajdamico/usgsd/blob/master/Pesquisa%20Mensal%20de%20Emprego/pme%202013%2003%20differences%20based%20on%20weight%20variable%20rounding.pdf?raw=true #
################################################################################################################################################################################
# beyond that specific example, the full table created by this replication script comes very close to the IBGE-produced statistics and coefficients of variation in this file: #
# ftp://ftp.ibge.gov.br/Trabalho_e_Rendimento/Pesquisa_Mensal_de_Emprego/Tabelas/2013/tab001112013.xls                                                                         #
# the differences (as mentioned in the e-mailed pdf) between this IBGE-published table and the output of this replication script stem entirely from the rounding of the weight #
# variables in the PME microdata.  in other words, IBGE constructs this table using weight variables that go out eight decimal places.  the downloadable data rounds after one #
################################################################################################################################################################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###############################################################################################################
# prior to running this analysis script, all pme files must be loaded on the local machine.  running the      #
# download all microdata script will create the series of data files (.rda) in the current working directory. #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/usgsd/blob/master/Pesquisa%20Mensal%20de%20Emprego/download%20all%20microdata.R #
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
all.pme.files <- list.files() 


# from that character vector containing
# all file names in the current working directory,
# determine all available years of data
all.years <- 
	unique( 
		substr( 
			all.pme.files , 
			5 , 
			8 
		) 
	)

	
# create a `coefs` and `cvs` data.frame object
# to store the `pia` for every available file
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
		

# loop through all available pme files
for ( i in all.pme.files ){
	
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

	# throw out records missing their cluster variable
	z <- subset( x , !is.na( v113 ) )
	# these are simply discarded.  hooray!  more detail:

	# those are the people that for any reason did not answer
	# the questions about education characteristics and/or
	# working characteristics of the survey.
	# they are excluded both in the process of editing and imputation
	# and in the computation of expansion weights.
	# in other words, any person with age greater than 10 years,
	# not having information in sections 3 and 4 of the questionnaire
	# is not treated in the survey processing,
	# but the information on general characteristics is kept in the microdata
	# these people are identified by the code 0 in the variables V301 and V401


	
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
	
	# sum up the number of brazilians ten or older
	overall <- svytotal( ~pia , w , na.rm = TRUE )
	# store the result in an `overall` object
	
	# sum up the number of brazilians ten or older, by region
	region <- svyby( ~pia , ~v035 , w , svytotal , na.rm = TRUE )
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


# # # # # # # # # # # # # # # # # # # # # # # # # # # #
# hit the numbers in column one of the pdf precisely  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

subset( coefs , year == '2013' & month == '03' )
# voila!

# # # # # make a few more edits # # # # #

# round all of the totals to the nearest thousand
coefs[ , 3:9 ] <- round( coefs[ , 3:9 ] / 1000 )

# multiply all coefficients of variation by one hundred,
# then round to one decimal place
cvs[ , 3:9 ] <- round( cvs[ , 3:9 ] * 100 , 1 )

# # # # # # # # # # # # # # # # # #
# come close to tab001112013.xls  #
# # # # # # # # # # # # # # # # # #

# print the coefficients table to the screen
coefs

# print the cv table to the screen
cvs


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
