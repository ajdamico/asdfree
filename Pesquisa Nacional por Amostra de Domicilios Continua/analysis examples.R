# analyze survey data for free (http://asdfree.com) with the r language
# pesquisa nacional por amostra de domicilios continua

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/PNADC/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Pesquisa%20Nacional%20por%20Amostra%20de%20Domicilios%20Continua/analysis%20examples.R" , prompt = FALSE , echo = TRUE )
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



#####################
# analysis examples #
#####################

# count the total (unweighted) number of records in pnadc #
# broken out by state #

svyby(
	~ one ,
	~ uf_name ,
	w ,
	unwtd.count
)



# count the weighted number of individuals in pnadc #

# the combined population of the nation
svytotal(
	~one ,
	w
)

# the broken-out population of each state
svyby(
	~ one ,
	~ uf_name ,
	w ,
	svytotal
)


# calculate the mean of a linear variable #

# average age
svymean(
	~ v2009 ,
	design = w
)

# by state
svyby(
	~ v2009 ,
	~ uf_name ,
	design = w ,
	svymean
)


# calculate the distribution of a categorical variable #

# percent male vs. female
svymean(
	~factor( v2007 ) ,
	design = w
)

# by state
svyby(
	~factor( v2007 ) ,
	~ uf_name ,
	design = w ,
	svymean
)

# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum ages
svyquantile(
	~ v2009 ,
	design = w ,
	c( 0 , .25 , .5 , .75 , 1 )
)

# by state
svyby(
	~ v2009 ,
	~ uf_name ,
	design = w ,
	svyquantile ,
	c( 0 , .25 , .5 , .75 , 1 ) ,
	ci = TRUE
)



# calculate a rate, the unemployed share of the total labor force
svyratio( 
	~ desocup30 , 
	~ vd4001 == "1" , 
	w , 
	na.rm = TRUE 
)


# calculate the same rate, but broken down by state
svyby( 
	formula = ~desocup30 , 
	by = ~ uf_name , 
	design = w , 
	svyratio , 
	denominator = ~ vd4001 == "1" , 
	na.rm = TRUE 
)
	


######################
# subsetting example #
######################

# restrict the w object to
# females only
w.female <-	subset( w , v2007 == 2 )
# now any of the above commands can be re-run
# using w.female object
# instead of the w object
# in order to analyze females only

# calculate the mean of a linear variable #

# average age
svymean(
	~ v2009 ,
	design = w.female
)



###################
# export examples #
###################

# calculate the distribution of a categorical variable #
# by state

# store the results into a new object

gender.by.state <-
	svyby(
		~ factor( v2007 ) ,
		~ uf_name ,
		design = w ,
		svymean
	)

# print the results to the screen
gender.by.state

# now you have the results saved into a new object of type "svyby"
class( gender.by.state )

# print only the statistics (coefficients) to the screen
coef( gender.by.state )

# print only the standard errors to the screen
SE( gender.by.state )

# print only the coefficients of variation to the screen
cv( gender.by.state )

# this object can be coerced (converted) to a data frame..
gender.by.state <- data.frame( gender.by.state )

# ..and then immediately exported as a comma-separated value file
# into your current working directory
write.csv( gender.by.state , "gender by state.csv" )

# ..or trimmed to only contain the values you need.
# here's the "percent female" by state,
# with accompanying standard errors
female.by.state <-
	gender.by.state[ , c( "uf_name" , "factor.v2007.2" , "se.factor.v2007.2" ) ]


# print the new results to the screen
female.by.state

# this can also be exported as a comma-separated value file
# into your current working directory
write.csv( female.by.state , "female by state.csv" )

# ..or directly made into a bar plot
barplot(
	female.by.state[ , 2 ] ,
	main = "Percent Female by State" ,
	ylim = c( 0 , .6 ) ,
	names.arg = female.by.state[ , 1 ] ,
	cex.names = 0.5 ,
	las = 2
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
