# analyze survey data for free (http://asdfree.com) with the r language
# pesquisa nacional por amostra de domicilios continua

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/PNADC/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Pesquisa%20Nacional%20por%20Amostra%20de%20Domicilios%20Continua/unemployment%20plot.R" , prompt = FALSE , echo = TRUE )
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
# prior to running this analysis script, all pnadc files must be loaded on the local machine.  running the    #
# download all microdata script will create the series of data files (.rda) in the current working directory. #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/Pesquisa%20Nacional%20por%20Amostra%20de%20Domicilios%20Continua/download%20all%20microdata.R  #
###############################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# remove the # in order to run this install.packages line only once
# install.packages( c( "survey" , "ggplot2" ) )


# set your working directory.
# the PNADC data files will be stored here
# after downloading and importing them.
# use forward slashes instead of back slashes


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PNADC/" )
# ..in order to set your current working directory

library(survey)		# load survey package (analyzes complex design surveys)
library(ggplot2)	# load ggplot2 package (plots data according to the grammar of graphics)

# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN
# SAS uses "remove" instead of "adjust" by default,
# the table target replication was generated with SAS,
# so if you want to get closer to that, use "remove"


# in the current working directory,
# list all available files
( aaf <- list.files() )


# determine the rda files of the most recent four quarters
aaf <- sort( aaf )
mrfq <- aaf[ ( length( aaf ) - 3 ):length( aaf ) ]


# initiate two empty data.frames
nationwide <- regional <- statewide <- NULL


# loop through the most recent four quarters
for ( this_rda in mrfq ){

	print( paste( "currently analyzing" , this_rda ) )

	# figure out the year and quarter
	this_year <- substr( this_rda , 7 , 10 )
	this_quarter <- substr( this_rda , 12 , 13 )
	
	# load one quarter of microdata
	load( this_rda )

	# # # # # # # # # # # # # # # # #
	# perform any necessary recodes #

	# calculate whether each person is at least fourteen years of age
	x$pia <- as.numeric( x$v2009 >= 14 )

	# determine individuals who are part of the labor force but not employed
	x[ x$pia == 1 , 'desocup30' ] <- as.numeric( x[ x$pia == 1 , 'vd4002' ] %in% 2 )

	# determine the region of each individual
	x$region <- substr( x$uf , 1 , 1 )

	# add a column of all ones
	x$one <- 1

	# end of recoding #
	# # # # # # # # # #
		

	###############################
	# survey design for the pnadc #
	###############################

	# preliminary survey design
	pre_w <-
		svydesign(
			ids = ~ upa , 
			strata = ~ estrato , 
			weights = ~ v1027 , 
			data = x ,
			nest = TRUE
		)
	# warning: do not use `pre_w` in your analyses!
	# you must use the `w` object created below.

	# post-stratification targets
	df_pos <- data.frame( posest = unique( x$posest ) , Freq = unique( x$v1029 ) )

	# final survey design object
	w <- postStratify( pre_w , ~posest , df_pos )

	# remove the `x` data.frame object and the `pre_w` design before stratification
	rm( x , pre_w )

	#################################
	# end of survey design creation #
	#################################


	##################################
	# unemployment rate calculations #
	##################################


	# nationwide unemployment rate this quarter
	nurtq <- svyby( ~ desocup30 , by = ~ one , denominator = ~ vd4001 == "1" , w , na.rm = TRUE , svyratio )

	# statewide unemployment rate this quarter
	surtq <-
		svyby(
		  ~ desocup30 ,
		  by = ~ uf ,
		  denominator = ~ vd4001 == 1 ,
		  design = w ,
		  na.rm = TRUE ,
		  svyratio
		)

	# regional unemployment rate this quarter
	rurtq <-
		svyby(
		  ~ desocup30 ,
		  by = ~ region ,
		  denominator = ~ vd4001 == 1 ,
		  design = w ,
		  na.rm = TRUE ,
		  svyratio
		)

	# coerce all three results to data.frame objects
	nurtq <- data.frame( nurtq )
	surtq <- data.frame( surtq )
	rurtq <- data.frame( rurtq )

	# remove and rename columns
	nurtq$one <- NULL
	names( nurtq )[ 1:2 ] <- c( 'unemp_rate' , 'standard_error' )
	names( surtq )[ 2:3 ] <- c( 'unemp_rate' , 'standard_error' )
	names( rurtq )[ 2:3 ] <- c( 'unemp_rate' , 'standard_error' )
	
	nurtq$year <- surtq$year <- rurtq$year <- this_year
	nurtq$quarter <- surtq$quarter <- rurtq$quarter <- this_quarter
	
	if ( is.null( nationwide ) ){
		nationwide <- nurtq
		statewide <- surtq
		regional <- rurtq
	} else {
		nationwide <- rbind( nationwide , nurtq )
		statewide <- rbind( statewide , surtq )
		regional <- rbind( regional , rurtq	)
	}

	# remove the `w` survey design object
	rm( w )
}


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

# merge on the state names,
# confirming zero record loss
before.nrow <- nrow( statewide )
statewide <- merge( statewide , uf )
stopifnot( nrow( statewide ) == before.nrow )

# same deal, but shorter, for region
before.nrow <- nrow( regional )
regional <- 
	merge( 
		regional , 
		data.frame( region = 1:5 , region_name = c("Norte","Nordeste","Sudeste","Sul","Centro-Oeste") )
	)
stopifnot( nrow( regional ) == before.nrow )


# remove pre-merge fields
statewide$uf <- regional$region <- NULL

# combine nation + state/region
statewide <- rbind( statewide , data.frame( nationwide , uf_name = "Nation" ) )
regional <- rbind( regional , data.frame( nationwide , region_name = "Nation" ) )

# create year+quarter
statewide$year_quarter <- paste( statewide$year , statewide$quarter , sep = '-' )
regional$year_quarter <- paste( regional$year , regional$quarter , sep = '-' )
statewide$year <- statewide$quarter <- regional$year <- regional$quarter <- NULL


# construct a regional ggplot2
pregion <- 
	ggplot( 
		regional , 
		aes( 
			year_quarter , 
			unemp_rate , 
			group = region_name ,
			colour = region_name 
		) 
	) + geom_line()

# print the result, with title	
pregion + ggtitle( "unemployment rate for all five regions during the previous four quarters" )


# construct a statewide ggplot2
pstate <- 
	ggplot( 
		statewide , 
		aes( 
			year_quarter , 
			unemp_rate , 
			group = uf_name ,
			colour = uf_name 
		) 
	) + geom_line()

# print the result, with title	
pstate + ggtitle( "unemployment rate for all twenty-seven states during the previous four quarters" )



# construct a subsetted ggplot2
psub <- 
	ggplot( 
		subset( statewide , uf_name %in% c( 'Nation' , 'Sao Paulo' , 'Rio de Janeiro' ) ) , 
		aes( 
			year_quarter , 
			unemp_rate , 
			group = uf_name ,
			colour = uf_name 
		) 
	) + geom_line()

# print the result, with title	
psub + ggtitle( "unemployment rate for only a few states during the previous four quarters" )


