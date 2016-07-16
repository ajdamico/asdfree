# analyze survey data for free (http://asdfree.com) with the r language
# pesquisa nacional de saude

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/PNS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Pesquisa%20Nacional%20De%20Saude/download%20and%20import.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# djalma pessoa
# pessoad@gmail.com

# anthony joseph damico
# ajdamico@gmail.com


#################################################
# analyze the pesquisa nacional de saude with R #
#################################################


# set your working directory.
# the PNS data files will be stored here
# after downloading and importing them.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PNS/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( c( "SAScii" , "downloader" , "survey" , "ggplot2" ) )


library(survey) 	# load survey package (analyzes complex design surveys)
library(SAScii) 	# load the SAScii package (imports ascii data with a SAS script)
library(downloader)	# downloads and then runs the source() function on scripts from github


# load the download_cached and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url( 
	"https://raw.githubusercontent.com/ajdamico/asdfree/master/Download%20Cache/download%20cache.R" , 
	prompt = FALSE , 
	echo = FALSE 
)


# initiate a temporary file
tf <- tempfile()

# download the latest pns microdata
download_cached( "ftp://ftp.ibge.gov.br/PNS/2013/microdados/pns_2013_microdados_2016_06_30.zip" , tf , mode = 'wb' )

# extract all files to the local disk
z <- unzip( tf , exdir = tempdir() )

# identify household (domicilio) data file
dd <- grep( "Dados/DOMPNS" , z , value = TRUE )

# identify person data file
pd <- grep( "Dados/PESPNS" , z , value = TRUE )

# identify household (domicilio) sas import script
ds <- grep( "DOMPNS(.*)\\.sas" , z , value = TRUE )

# identify person sas import script
ps <- grep( "PESPNS(.*)\\.sas" , z , value = TRUE )

# create a data.frame object `dom` containing one record per household
dom <- read.SAScii( dd , ds )

# create a data.frame object `pes` containing one record per person
pes <- read.SAScii( pd , ps )

# convert all columns to lowercase
names( dom ) <- tolower( names( dom ) )
names( pes ) <- tolower( names( pes ) )

# pre-stratified pes weight
names( pes )[ names( pes ) == 'v0029' ] <- 'pre_pes_long'
names( pes )[ names( pes ) == 'v0028' ] <- 'pre_pes_full'


# merge dom and pes
x <- merge( dom , pes , by = c( "v0001" , "v0024" , "upa_pns" , "v0006_pns" ) )

stopifnot( nrow( x ) == nrow( pes ) )

rm( dom , pes ) ; gc()

# people with self evaluated health good or very good  
x <- transform( x , saude_b_mb = as.numeric( n001 %in% c( '1' , '2' ) ) )

# urban / rural
x <- transform( x , situ = factor( substr( v0024 , 7 , 7 ) , labels = c( 'urbano' , 'rural' ) ) )

# sex
x <- transform( x , c006 = factor( c006 , labels = c( 'masculino' , 'feminino' ) ) )

# state names
estado_names <- c( "Rondônia" , "Acre" , "Amazonas" , "Roraima" , "Pará" , "Amapá" , "Tocantins" , "Maranhão" , "Piauí" , "Ceará" , "Rio Grande do Norte" , "Paraíba" , "Pernambuco" , "Alagoas" , "Sergipe" , "Bahia" , "Minas Gerais" , "Espírito Santo" , "Rio de Janeiro" , "São Paulo" , "Paraná" , "Santa Catarina" , "Rio Grande do Sul" , "Mato Grosso do Sul" , "Mato Grosso" , "Goiás" , "Distrito Federal" )
x <- transform( x , uf = factor( v0001 , labels = estado_names ) )

# region
x <- transform( x , region = factor( substr( v0001 , 1 , 1 ) , labels = c( "Norte" , "Nordeste" , "Sudeste" , "Sul" , "Centro-Oeste" ) ) )

# numeric recodes
x[ , c( 'p04101' , 'p04102' , 'p04301' , 'p04302' ) ] <- sapply( x[ , c( 'p04101' , 'p04102' , 'p04301' , 'p04302' ) ] , as.numeric )


# worker recodes
x <-
	transform(
		x ,
		tempo_desl_trab = ifelse( is.na( p04101 ) , 0 , p04101 * 60 + p04102 ) ,
		tempo_desl_athab = ifelse( is.na( p04301 ) , 0 , p04301 * 60 + p04302 ) )

x <- transform( x , tempo_desl = tempo_desl_trab + tempo_desl_athab )

x <- transform( x , atfi04 = as.numeric( tempo_desl >= 30 ) )


# categorical age 
x$age_cat <- factor( 1 + findInterval( as.numeric( x$c008 ) , c( 18 , 30 , 40 , 60 ) ) , labels = c( "0-17" , "18-29" , "30-39" , "40-59" , "60+" ) )

# race
x$raca <- as.numeric( x$c009 )
x[ x$raca == 9 , 'raca' ] <- NA
x$raca <- factor( x$raca , labels = c( 'Branca' , 'Preta' , 'Amarela' , 'Parda' , 'Indígena' ) )

# education
x$educ <- factor( 1 + findInterval( as.numeric( x$vdd004 ) , c( 3 , 5 , 7 ) ) , labels = c( "SinstFundi" , "FundcMedi" , "MedcSupi" , "Supc" ) )

# number of people in the household
x$c001 <- as.numeric(x$c001)

# column of all ones
x$one <- 1                   



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# design object for people answering the long questionnaire #
pes_sel <- subset( x , m001 == "1" )

# pre-stratified design
pes_sel_des <-
	svydesign(
		id = ~ upa_pns ,
		strata = ~ v0024 ,
		data = pes_sel ,
		weights = ~ pre_pes_long ,
		nest = TRUE
	)

# figure out stratification targets
post_pop <- unique( pes_sel[ c( 'v00293.y' , 'v00292.y' ) ] )

names( post_pop ) <- c( "v00293.y" , "Freq" )

# post-stratified design
pes_sel_des_pos <- postStratify( pes_sel_des , ~v00293.y , post_pop )

# save the long questionnaire survey design
save( pes_sel_des_pos , pes_sel , file = "2013 long questionnaire survey design.rda" )

# final design object for people answering the long questionnaire #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# design object for people answering only short or long questionnaire #

# pre-stratified design object for all people

pes_all_des <-
	svydesign(
		id = ~ upa_pns ,
		strata = ~ v0024 , 
		data = x , 
		weights = ~ pre_pes_full , 
		nest = TRUE
	)

# figure out stratification targets
post_pop_all <- unique( x[ , c( 'v00283.y' , 'v00282.y' ) ] )

names( post_pop_all ) <- c( "v00283.y" , "Freq" )


# post-stratified design
pes_all_des_pos <- postStratify( pes_all_des , ~ v00283.y , post_pop_all )

# save the all-respondent questionnaire survey design
save( pes_all_des_pos , x , file = "2013 all questionnaire survey design.rda" )

# final design object for people answering only short or long questionnaire #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# print a reminder: set the directory you just saved everything to as read-only!
message( paste0( "all done.  you should set the file " , getwd() , " read-only so you don't accidentally alter these tables." ) )
