# analyze survey data for free (http://asdfree.com) with the r language
# pesquisa nacional por amostra de domicilios continua

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/PNADC/" )
# source_url( "https://raw.github.com/ajdamico/asdfree/master/Pesquisa%20Nacional%20por%20Amostra%20de%20Domicilios%20Continua/unemployment%20rate.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# http://www.screenr.com/Zpd8

# djalma pessoa
# pessoad@gmail.com

# anthony joseph damico
# ajdamico@gmail.com

# if you use this script for a project, please send me a note
# it's always nice to hear about how people are using this stuff

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###############################################################################################################
# prior to running this analysis script, all pnadc files must be loaded on the local machine.  running the    #
# download all microdata script will create the series of data files (.rda) in the current working directory. #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/asdfree/master/Pesquisa%20Nacional%20por%20Amostra%20de%20Domicilios%20Continua/download%20all%20microdata.R  #
###############################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# remove the # in order to run this install.packages line only once
# install.packages( "survey" )


# set your working directory.
# the PNADC data files will be stored here
# after downloading and importing them.
# use forward slashes instead of back slashes


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PNADC/" )
# ..in order to set your current working directory

library(survey)		# load survey package (analyzes complex design surveys)


# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN
# SAS uses "remove" instead of "adjust" by default,
# the table target replication was generated with SAS,
# so if you want to get closer to that, use "remove"


# in the current working directory,
# list all available files
list.files()


# load the first quarter of 2015 file
load( "pnadc 2015 01.rda" )

# # # # # # # # # # # # # # # # #
# perform any necessary recodes #

# calculate whether each person is at least fourteen years of age
x$pia <- as.numeric( x$v2009 >= 14 )

# determine individuals who are employed
x[ x$pia == 1 , 'ocup_c' ] <- as.numeric( x[ x$pia == 1 , 'vd4002' ] %in% 1 )

# determine individuals who are part of the labor force but not employed
x[ x$pia == 1 , 'desocup30' ] <- as.numeric( x[ x$pia == 1 , 'vd4002' ] %in% 2 )

# define valid domain of workers (recode rows)
rr <- x$pia %in% 1 & x$vd4015 %in% 1

# calculate usual income from main job (rendimento habitual do trabalho principal)
x[ rr , 'vd4016n' ] <- x[ rr , 'vd4016' ]

# calculate effective income from main job (rendimento efetivo do trabalho principal) 
x[ rr , 'vd4017n' ] <- x[ rr , 'vd4017' ]

# calculate usual income from all jobs (variavel rendimento habitual de todos os trabalhos)
x[ rr , 'vd4019n' ] <- x[ rr , 'vd4019' ]

# calculate effective income from all jobs (rendimento efetivo do todos os trabalhos) 
x[ rr , 'vd4020n' ] <- x[ rr , 'vd4020' ]

# determine individuals who are either working or not working
# (that is, the potential labor force)
x$pea_c <- as.numeric( x$ocup_c == 1 | x$desocup30 == 1 )

# determine the region of each individual
x$region <- substr( x$uf , 1 , 1 )

# add a column of all ones
x$one <- 1

# end of recoding #
# # # # # # # # # #

# # # # # # # # # # # #
# tack on state names #

# construct a data.frame object with all state names.
uf <-
	structure(list(V1 = c(11L, 12L, 13L, 14L, 15L, 16L, 17L, 21L, 
	22L, 23L, 24L, 25L, 26L, 27L, 28L, 29L, 31L, 32L, 33L, 35L, 41L, 
	42L, 43L, 50L, 51L, 52L, 53L), V2 = structure(c(22L, 1L, 4L, 
	23L, 14L, 3L, 27L, 10L, 18L, 6L, 20L, 15L, 17L, 2L, 26L, 5L, 
	13L, 8L, 19L, 25L, 16L, 24L, 21L, 12L, 11L, 9L, 7L), .Label = c("Acre", 
	"Alagoas", "Amapa", "Amazonas", "Bahia", "Ceara", "Distrito Federal", 
	"Espirito Santo", "Goias", "Maranhao", "Mato Grosso", "Mato Grosso do Sul", 
	"Minas Gerais", "Para", "Paraiba", "Parana", "Pernambuco", "Piaui", 
	"Rio de Janeiro", "Rio Grande do Norte", "Rio Grande do Sul", 
	"Rondonia", "Roraima", "Santa Catarina", "Sao Paulo", "Sergipe", 
	"Tocantins"), class = "factor")), .Names = c("uf", "uf_name"), class = "data.frame", row.names = c(NA, 
	-27L))

# merge this data.frame onto the main `x` data.frame
# using `uf` as the merge field, keeping all non-matches.
x <- merge( x , uf , all.x = TRUE )

# double-check the result by printing the unweighted counts.
table( x[ , c( 'uf' , 'uf_name' ) ] , useNA = 'always' )

	

###############################
# survey design for the pnadc #
###############################

warning( "ibge has not yet released information to calculate a confidence interval" )
warning( "this survey design will produce incorrect standard errors, variances, coefficients of variation" )

w <-
	svydesign(
		ids = ~ upa , 
		strata = ~ uf , 
		weights = ~ v1028 , 
		data = x ,
		nest = TRUE
	)

#################################
# end of survey design creation #
#################################


##################################
# unemployment rate calculations #
##################################


# these numbers match the numbers shown in the text
# http://saladeimprensa.ibge.gov.br/noticias?view=noticia&id=1&busca=1&idnoticia=2881


# total brazilian population in the labor force
forca.total <- svytotal( ~ factor( vd4001 ) , w , na.rm = TRUE )

# print the coefficient to the screen
coef( forca.total )
# 1 = part of the labor force
# 2 = not part of the labor force


# labor force participation rate among everyone older than 13
part.rate <- svyratio( ~ vd4001 == 1 , ~ pia , w , na.rm = TRUE )

# print the coefficient to the screen
coef( part.rate )
# 1 = individuals in the labor force (pessoas na forca de trabalho)
# 2 = individuals not in the labor force (pessoas fora da forca de trabalho)


# occupation status
ocupacao.total <- svytotal( ~ factor( vd4002 ) , w , na.rm = TRUE )

# print the coefficient to the screen
coef( ocupacao.total )
# 1 = workers (pessoas ocupadas)
# 2 = non-workers (pessoas desocupadas)


# unemployment rate (among those in the labor force)
unemp.rate <- svyratio( ~ desocup30 , ~ vd4001 == "1" , w , na.rm = TRUE )

# print the coefficient to the screen
coef( unemp.rate )


# employment rate (among those in the labor force)
emp.rate <- svyratio( ~ ocup_c , ~ vd4001 == "1" , w , na.rm = TRUE )

# print the coefficient to the screen
coef( emp.rate )


# employment participation rate (among everyone 14 or older)
p.rate <- svyratio( ~ ocup_c , ~ pia , w , na.rm = TRUE )

# print the coefficient to the screen
coef( p.rate )


# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# mean (medio) and median (mediano) income calculations #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# usual, from main job
hab.mj.mean <- svymean( ~ vd4016n , w , na.rm = TRUE )
hab.mj.median <- svyquantile( ~ vd4016n , w , 0.5 , na.rm = TRUE , keep.var = TRUE )

# print both results to the screen
coef( hab.mj.mean )
hab.mj.median


# effective, from main job
eff.mj.mean <- svymean( ~ vd4017n , w , na.rm = TRUE )
eff.mj.median <- svyquantile( ~ vd4017n , w , 0.5 , na.rm = TRUE )

# print both results to the screen
coef( eff.mj.mean )
eff.mj.median


# usual, from all jobs
hab.aj.mean <- svymean( ~ vd4019n , w , na.rm = TRUE )
hab.aj.median <- svyquantile( ~ vd4019n , w , 0.5 , na.rm = TRUE )

# print both results to the screen
coef( hab.aj.mean )
hab.aj.median


# effective, from all jobs
eff.aj.mean <- svymean( ~ vd4020n , w , na.rm = TRUE )
eff.aj.median <- svyquantile( ~ vd4020n , w , 0.5 , na.rm = TRUE )

# print both results to the screen
coef( eff.aj.mean )
eff.aj.median


################################
# # # # # # by state # # # # # #

# average regular income from all jobs
hab.aj.uf <- 
	svyby( 
		~ vd4019n , 
		~ uf_name ,
		w , 
		svymean , 
		na.rm = TRUE ,
		keep.var = FALSE
	)

# print the result to the screen
hab.aj.uf

# perfectly matches the state income graphic
# http://saladeimprensa.ibge.gov.br/noticias?view=noticia&id=1&busca=1&idnoticia=2881


#################################################
# share of population 14+ not working, by state #
#################################################

nw.uf <-
	svyby(
		~ desocup30 ,
		by = ~ uf_name ,
		denominator = ~ pia ,
		design = w ,
		na.rm = TRUE ,
		svyratio
	)

# print the rounded results to the screen,
# by state.
round( coef( nw.uf ) * 100 , 1 )


##############################
# unemployment rate by state #
##############################

unemp.uf <-
	svyby(
		~ desocup30 ,
		by = ~ uf_name ,
		denominator = ~ vd4001 == 1 ,
		design = w ,
		na.rm = TRUE ,
		svyratio
	)

# print the rounded results to the screen,
# by state.
round( coef( unemp.uf ) * 100 , 1 )


###############################
# unemployment rate by region #
###############################

unemp.r <-
	svyby(
		~ desocup30 ,
		by = ~ region ,
		denominator = ~ vd4001 == 1 ,
		design = w ,
		na.rm = TRUE ,
		svyratio
	)

# save the rounded results by region
result <- cbind( round( coef( unemp.r ) * 100 , 1 ) , c( "norte" , "nordeste" , "sudeste" , "sul" , "centro-oeste" ) )

# compare these results to the ibge publication
# http://saladeimprensa.ibge.gov.br/noticias?view=noticia&id=1&busca=1&idnoticia=2881
result


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
