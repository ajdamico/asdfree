# analyze brazilian government survey data with the r language
# pesquisa orcamentos familiares

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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################
# prior to running this analysis script, the 2008-2009 pof files must be loaded on the local machine.               #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/usgsd/master/Pesquisa%20de%20Orcamentos%20Familiares/download%20all%20microdata.R #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# running the download all microdata script for 2009 will place the files you need into a 2009-specific directory   #
#####################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/POF/2009/" )
# ..in order to set your current working directory

# remove the `#` in order to run this install.packages line only once
# install.packages( "survey" )

require(survey)		# load survey package (analyzes complex design surveys)

# set R to produce conservative standard errors instead of crashing
# http://faculty.washington.edu/tlumley/survey/exmample-lonely.html
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

# # # # # # # # # # # # #
# perform a few recodes #

# transform height to centimeters
x <-
	transform(
		x , 
		altura_imputado = altura_imputado / 100
	)

x <-
	transform(
		x , 
		
		# define age groups
		idade.cat =
			cut(
				idade_anos , 
				c( 20 , 25 , 30 , 35 , 45 , 55 , 65 , 75 , Inf ) ,
				include.lowest = TRUE , 
				right = FALSE
			) ,

		## create a body mass index (bmi) variable, excluding babies (who have altura_imputado==0)			
		bmi = 
			ifelse( altura_imputado == 0 , 0 , peso_imputado / ( altura_imputado ^ 2 ) )
	)

# construct three binary (zeroes and ones) variables
# that will be used in the analysis
x <-
	transform(
		x ,
		
		# individuals with a low bmi - underweight
		underweight = ifelse( bmi < 18.5 , 1 , 0 ) ,
		
		# individuals with a high bmi - overweight
		overweight = ifelse( bmi >= 25 , 1 , 0 ) ,
		
		# individuals with a very high bmi - obese
		obese = ifelse( bmi >= 30 , 1 , 0 )
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


	
#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in pof #
# broken out by sex #

svyby(
	~one ,
	~cod_sexo ,
	pof.design.pos ,
	unwtd.count
)



# count the weighted number of individuals in pnad #

# the population of brazil #
svytotal(
	~one ,
	pof.design.pos
)

# the population of brazil #
# by sex
svyby(
	~one ,
	~cod_sexo ,
	pof.design.pos ,
	svytotal
)


# calculate the mean of a linear variable #

# average age
svymean(
	~idade_anos ,
	design = pof.design.pos
)

# by sex
svyby(
	~idade_anos ,
	~cod_sexo ,
	design = pof.design.pos ,
	svymean
)


# calculate the distribution of a categorical variable #

# percent in each race category - nationwide
svymean(
	~factor( cod_cor_raca ) ,
	design = pof.design.pos
)

# by sex
svyby(
	~factor( cod_cor_raca ) ,
	~cod_sexo ,
	design = pof.design.pos ,
	svymean
)

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# by the way, you can find the variable coding of the cod_cor_raca variable in pof 1.pdf in the questionnaire zip file  #
# ftp://ftp.ibge.gov.br/Orcamentos_Familiares/Pesquisa_de_Orcamentos_Familiares_2008_2009/Microdados/questionarios.zip  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum ages
svyquantile(
	~idade_anos ,
	design = pof.design.pos ,
	c( 0 , .25 , .5 , .75 , 1 )
)

# by sex
svyby(
	~idade_anos ,
	~cod_sexo ,
	design = pof.design.pos ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	ci = TRUE
)

######################
# subsetting example #
######################

# restrict the pof.design.pos object to
# non-pregnant individuals aged 20 and above
pof.design.pos.npadults <- subset( pof.design.pos , idade_anos >= 20 & cod_gravida != "01" )
# now any of the above commands can be re-run
# using pof.design.pos.npadults object
# instead of the pof.design.pos object
# in order to analyze only
# non-pregnant individuals aged 20 or older

# calculate the mean of a linear variable #

# average age
svymean(
	~idade_anos ,
	design = pof.design.pos.npadults
)


# define a formula that will be used in multiple subsequent survey commands
formulas <- ~underweight + overweight + obese

# run an overall `svyby` that stores the results into a new `total` object
# but also prints the results to the screen, because the command was encapsulated by ( )
( total <- svyby( formulas , ~one , pof.design.pos.npadults , svymean ) )

# store three more `svyby` calls into three other objects
sexo <- svyby( formulas , ~cod_sexo , pof.design.pos.npadults , svymean )
idade <- svyby( formulas , ~idade.cat , pof.design.pos.npadults , svymean )
idade.sexo <- svyby( formulas , ~idade.cat + cod_sexo , pof.design.pos.npadults , svymean )

# print some statistics and coefficients of variation from the stored objects
coef( total )
cv( total )

coef( sexo )
SE( sexo )

# combine the age-breakouts with their coefficients of variation into a single table
# but just print that resultant table to the screen instead of storing it anywhere with <-
cbind( 
	data.frame( idade ) ,
	cv( idade )
)


# store the age by sex breakout's coefficients of variation
# into a new data.frame called `cv.df`
cv.df <- data.frame( cv( idade.sexo ) )

# note use of `sub` instead of `gsub`
# because only the first instance of "se" should be 
# replaced by "cv" and not subsequent captures
names( cv.df ) <- sub( "se" , "cv" , names( cv.df ) )
# from ?sub --
# *sub functions differ only in that sub replaces only 
# the first occurrence of a pattern whereas
# gsub replaces all occurrences

# also store the age by sex main statistics and standard errors
# into a second data.frame called `idade.sexo.df`
idade.sexo.df <- data.frame( idade.sexo )

# and bind this with the `cv.df` object to create age by sex breakouts
# of underweight (deficit), overweight (excesso), and obese (obesidade)
idade.sexo.result <- cbind( idade.sexo.df , cv.df )


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# print the result to the screen
idade.sexo.result

# note that this table matches the statistics in table 15:
# ftp://ftp.ibge.gov.br/Orcamentos_Familiares/Pesquisa_de_Orcamentos_Familiares_2008_2009/Antropometria_e_estado_nutricional_de_criancas_adolescentes_e_adultos_no_Brasil/tabtexto15.zip

# as well as the coefficients of variation here:
# ftp://ftp.ibge.gov.br/Orcamentos_Familiares/Pesquisa_de_Orcamentos_Familiares_2008_2009/Antropometria_e_estado_nutricional_de_criancas_adolescentes_e_adultos_no_Brasil/POF_CV_04prevalencia.zip
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by sex

# store the results into a new object

sex.by.race <-
	svyby(
		~cod_sexo ,
		~cod_cor_raca ,
		design = pof.design.pos ,
		svymean
	)

# print the results to the screen
sex.by.race

# now you have the results saved into a new object of type "svyby"
class( sex.by.race )

# print only the statistics (coefficients) to the screen
coef( sex.by.race )

# print only the standard errors to the screen
SE( sex.by.race )

# print only the coefficients of variation to the screen
cv( sex.by.race )

# this object can be coerced (converted) to a data frame..
sex.by.race <- data.frame( sex.by.race )

# ..and then immediately exported as a comma-separated value file
# into your current working directory
write.csv( sex.by.race , "sex by race.csv" )

# ..or trimmed to only contain the values you need.
# here's the "percent male" by race,
# with accompanying standard errors
male.by.race <-
	sex.by.race[ , c( "cod_cor_raca" , "cod_sexo01" , "se.cod_sexo01" ) ]


# print the new results to the screen
male.by.race

# this can also be exported as a comma-separated value file
# into your current working directory
write.csv( male.by.race , "male by race.csv" )

# ..or directly made into a bar plot
barplot(
	male.by.race[ , 2 ] ,
	main = "Percent Male by Race" ,
	names.arg = c( "Branca" , "Preta" , "Amarela" , "Parda" , "Indigena" , "Nao Sabe" ) ,
	ylim = c( 0 , 0.6 )
)

# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
