# analyze survey data for free (http://asdfree.com) with the r language
# pesquisa nacional por amostra de domicilios continua
# 2015

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( encoding = "windows-1252" )		# # only macintosh and *nix users need this line
# library(downloader)
# setwd( "C:/My Directory/PNADC/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Pesquisa%20Nacional%20por%20Amostra%20de%20Domicilios%20Continua/replicate%20IBGE%20estimates%20-%202015.R" , prompt = FALSE , echo = TRUE )
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


############################################################################################################################################
# this script matches the 2015 - 03 (3rd trimestre) results published by IBGE.  IBGE is the brazilian census bureau/stats agency           #
# ftp://ftp.ibge.gov.br/Trabalho_e_Rendimento/Pesquisa_Nacional_por_Amostra_de_Domicilios_continua/Trimestral/Tabelas/pnadc_201503_111.xls #
############################################################################################################################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###############################################################################################################
# prior to running this analysis script, all pnadc files must be loaded on the local machine.  running the    #
# download all microdata script will create the series of data files (.rda) in the current working directory. #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/Pesquisa%20Nacional%20por%20Amostra%20de%20Domicilios%20Continua/download%20all%20microdata.R  #
#################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


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


library(survey)		# load survey package (analyzes complex design surveys)


# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN


# in the current working directory,
# list all available files
list.files()


# load the third quarter of 2015 file
load( "pnadc 2015 03.rda" )


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

# total brazilian population in the labor force
# 1 = part of the labor force
# 2 = not part of the labor force

nationwide_pop <- svytotal( ~ pia , w , na.rm = TRUE )
nationwide_forca <- svytotal( ~ factor( vd4001 ) , w , na.rm = TRUE )
nationwide_ocupacao <- svytotal( ~ factor( vd4002 ) , w , na.rm = TRUE )
regional_pop <- svyby( ~ pia , ~ region , w , svytotal , na.rm = TRUE )
regional_forca <- svyby( ~ factor( vd4001 ) , ~ region , w , svytotal , na.rm = TRUE )
regional_ocupacao <- svyby( ~ factor( vd4002 ) , ~ region , w , svytotal , na.rm = TRUE )

# reproduce table 1.1.1
# excel tab "Tabela 1.1.1" and tab "Tabela 1.1.1_CV"
# column 2015 - "3º Trimestre"


# # # to obtain the precise rounded numbers, you might use
round( coef( nationwide_pop ) * 100 , 1 )
round( cv( nationwide_pop ) * 100 , 1 )
# # # however all of the numbers below also match the table precisely,
# # # they are simply pre-rounded numbers.


# Brasil
nationwide_pop
cv( nationwide_pop )

# Na força de trabalho
# Fora da força de trabalho
nationwide_forca
cv( nationwide_forca )

# Ocupadas
# Desocupadas
nationwide_ocupacao
cv( nationwide_ocupacao )

# Norte
# Nordeste
# Sudeste
# Sul
# Centro-Oeste
regional_pop
cv( regional_pop )

# Na força de trabalho
# Fora da força de trabalho
regional_forca
cv( regional_forca )

# Ocupadas
# Desocupadas
regional_ocupacao
cv( regional_ocupacao )


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
