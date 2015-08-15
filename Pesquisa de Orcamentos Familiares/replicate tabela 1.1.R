# analyze survey data for free (http://asdfree.com) with the r language
# pesquisa orcamentos familiares

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( encoding = "latin1" )		# # only macintosh and *nix users need this line
# library(downloader)
# setwd( "C:/My Directory/POF/2009/" )
# source_url( "https://raw.github.com/ajdamico/asdfree/master/Pesquisa%20de%20Orcamentos%20Familiares/replicate%20tabela%201.1.R" , prompt = FALSE , echo = TRUE )
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


#############################################################################################################################################################################################
# this script matches the IBGE tabela 1.1 statistics and coefficients of variation (coeficientes de variação).  IBGE is the brazilian census bureau/stats agency.                           #
# http://www.ibge.gov.br/home/estatistica/populacao/condicaodevida/pof/2008_2009_encaa/tabelas_pdf/tab1_1.pdf                                                                               #
# ftp://ftp.ibge.gov.br/Orcamentos_Familiares/Pesquisa_de_Orcamentos_Familiares_2008_2009/Antropometria_e_estado_nutricional_de_criancas_adolescentes_e_adultos_no_Brasil/POF_CV_brasil.zip #
#############################################################################################################################################################################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################
# prior to running this analysis script, the 2008-2009 pof files must be loaded on the local machine.               #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/asdfree/master/Pesquisa%20de%20Orcamentos%20Familiares/download%20all%20microdata.R #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# running the download all microdata script for 2009 will place the files you need into a 2009-specific directory   #
#####################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/POF/2009/" )
# ..in order to set your current working directory


# # # are you on a non-windows system? # # #
if ( .Platform$OS.type != 'windows' ) print( 'non-windows users: read this block' )
# ibge's ftp site has a few SAS importation
# scripts in a non-standard format
# if so, before running this whole download program,
# you might need to run this line..
# options( encoding="latin1" )
# ..to turn on latin-style encoding.
# # # end of non-windows system edits.


# remove the `#` in order to run this install.packages line only once
# install.packages( c( "reshape2" , "survey" ) )

library(survey)		# load survey package (analyzes complex design surveys)
library(reshape2)	# load reshape2 package (transposes data frames quickly)

# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN


# load the person-level data file
load("t_morador_s.rda")

# load the post-stratification table
load("poststr.rda")


# construct a `control` column in the person-level data file
# that will be used to merge with the post-stratification table
t_morador_s <-
	transform(
		t_morador_s , 
		control = paste0( cod_uf , num_seq , num_dv ) 
	)

# merge these two data files..
x <- merge( t_morador_s , poststr )

# ..and note the number of records does not change.
stopifnot( nrow( x ) == nrow( t_morador_s ) )

# remove those two tables from memory
rm( t_morador_s , poststr )

# clear up RAM
gc()


# # # # # # # # # # # # #
# perform a few recodes #

# construct age categories based on months, not years
idade.cats <- 
	c(
		# one-year breaks up to age twenty
		seq( 0 , 240 , by = 12 ) , 
		# five-year breaks up to age thirty-five
		seq( 300 , 420 , by = 60 ) , 
		# ten-year breaks up to age seventy-five
		seq( 540 , 900 , by = 120 ) ,
		Inf
	)
	
# construct corresponding labels
idade.labels <-
	c(
		"menos de 1 ano" , 
		"1 ano" , 
		paste0( 2:19 , " anos" ) , 
		"20 a 24 anos" , 
		"25 a 29 anos" ,
		"30 a 34 anos" , 
		"35 a 44 anos" , 
		"45 a 54 anos" , 
		"55 a 64 anos" , 
		"65 a 74 anos" , 
		"75 e mais"
	)

# define age groups,
# using the categorizations created above
x$idade.cat <-
	cut(
		x$idade_mes , 
		breaks = idade.cats , 
		labels = idade.labels , 
		include.lowest = TRUE , 
		right = FALSE
	)


# create an urban/rural variable
estrato.cats <- c( 7 , 3 , 9 , 3 , 9 , 4 , 6 , 13 , 10 , 24 , 9 , 10 , 16 , 9 , 8 , 22 , 28 , 10 , 31 , 31 , 19 , 14 , 19 , 9 , 11 , 18 , 8 )
names( estrato.cats ) <- unique( x$cod_uf )

# any record with an `estrato` variable greater than or equal to the corresponding `estrato.cats` variable
# is designated as rural.  all other records are urban residents.
x$situ <- ifelse( x$estrato >= estrato.cats[ x$cod_uf ] , "RUR" , "URB" )

# for individuals under two years old,
# use the `comprimento_imputado` variable for their height
# for all other respondents, use the `altura_imputado` variable
x <- 
	transform(
		x , 
		compalt = 
			ifelse( 
				idade_mes >= 0 & idade_mes <= 23 ,
				comprimento_imputado ,
				altura_imputado
			)
	)


# add a column of only ones to the data frame
x$one <- 1

#################################
# post-stratified survey design #
#################################

# create survey design object with POF design information
# using existing table of POF data
sample.pof <- 
	svydesign(
		id = ~control , 
		strata = ~estrato_unico ,
		weights = ~fator_expansao1 ,
		data = x ,
		nest = TRUE
	)

# note that the above object has been given the unwieldy name of `sample.pof`
# so that it's not accidentally used in analysis commands.
# this object has not yet been appropriately post-stratified, as necessitated by IBGE
# in order to accurately match the brazilian 2010 census projections


# this block determines what post-stratification targets should be used
pop.totals <- 
	data.frame(
		pos_estrato = unique( x$pos_estrato ) , 
		Freq = unique( x$tot_pop )
	)

# this block conducts the actual post-stratification
# on the un-post-stratified design
pof.design.pos <-
	postStratify(
		sample.pof , 
		~pos_estrato , 
		pop.totals
	)

	
#######################################################
# construct a big function to do all the work for you #
#######################################################


# initiate a function that will generate
# all of the statistics in table 1.1
tabela_1.1 <-
	function( 
		# variable(s) to analyze
		x , 
		# breakout variable row in the final table
		# - only one variable allowed
		row.variable , 
		# breakout variable column(s) in the final table
		# - multiple variables allowed
		column.variables , 
		# the post-stratified pof survey design object
		design 
	){

		# construct the statistic variables formula
		statvars <- 
			as.formula(
				paste(
					"~" ,
					paste(
						x ,
						collapse = " + "
					)		
				)
			)
	
		# construct the breakout (by) variables formula
		byvars <- 
			as.formula(
				paste(
					"~" ,
					paste(
						c( row.variable , column.variables ) ,
						collapse = " + "
					)		
				)
			)
	
		# calculate the unweighted N
		unwtd <-
			svyby( 
				~ one, 
				byvars , 
				design ,
				unwtd.count
			)

		# calculate the weighted N
		wtd <-
			svyby( 
				~ one, 
				byvars , 
				design ,
				svytotal
			)

		# calculate the actual median statistics and standard errors
		stats <-
			svyby( 
				statvars , 
				byvars , 
				design ,
				svyquantile ,
				0.5 ,
				interval.type = 'betaWald' ,
				ci = TRUE
			)

		# attach the coefficient of variation
		stats$cv <- cv( stats )

		# bind all three tables together
		y <- cbind( unwtd , wtd , stats )

		# remove non-unique columns
		z <- y[ , unique( names( y ) ) ]
		
		# also remove the `se` column, which contains nothing
		z$se <- NULL
		
		# if there's just one column variable, make that the `column`
		# otherwise, collapse all the column variables together.
		if ( length( column.variables ) == 1 ){
			z$col <- z[ , column.variables ]
		} else z$col <- apply( z[ , column.variables ] , 1 , paste , collapse = " " )
		
		# remove the column variables from the `z` data.frame,
		# since they're now all stuffed into the `col` column
		z <- z[ , !( names( z ) %in% column.variables ) ]
		
		# reshape the data frame so it has
		# one record per [row.variable] and
		# includes distinct columns for each [column.variable] 
		reshape( 
			z , 
			idvar = row.variable ,
			timevar = 'col' ,
			direction = 'wide'
		)
		# since the result of this `reshape` is the last line of this function
		# the function will return that result.
	}

####################################
# end of big function construction #
####################################


# calculate the median weight (peso_imputado) and height (compalt) values #
# with one row per age category and one column per sex category           #

by.sex <-
	tabela_1.1( 
		# variable(s) to analyze
		c( "peso_imputado" , "compalt" ) , 
		# breakout variable row in the final table
		# - only one variable allowed
		"idade.cat" , 
		# breakout variable column(s) in the final table
		# - multiple variables allowed
		"cod_sexo" , 
		# the post-stratified pof survey design object
		pof.design.pos
	)

# print the results to the screen..
by.sex
# ..or export them using one of the techniques discussed on http://twotorials.com

# clear up RAM
gc()


# calculate the median weight (peso_imputado) and height (compalt) values       #
# with one row per age category and one column per sex category AND urban/rural #

by.sex.by.urban.rural <-
	tabela_1.1( 
		# variable(s) to analyze
		c( "peso_imputado" , "compalt" ) , 
		# breakout variable row in the final table
		# - only one variable allowed
		"idade.cat" , 
		# breakout variable column(s) in the final table
		# - multiple variables allowed
		c( "cod_sexo" , "situ" ) , 
		# the post-stratified pof survey design object
		pof.design.pos
	)
	
# print the results to the screen..
by.sex.by.urban.rural
# ..or export them using one of the techniques discussed on http://twotorials.com

# clear up RAM
gc()


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
