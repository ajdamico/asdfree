stop( 'replicate the entire table!' )


library(downloader)
library(survey)


source_url( "https://raw.githubusercontent.com/ajdamico/usgsd/master/National%20Longitudinal%20Surveys/custom%20weight%20download%20functions.R" , prompt = FALSE )

w9711 <- get.nlsy.weights( "nlsy97" , 'YES' , c( 'SURV1997' , 'SURV2011' ) )

w97 <- get.nlsy.weights( "nlsy97" , 'YES' , 'SURV1997' )

setwd( "C:/My Directory/NLS" )

study.name <- "NLSY97 1997-2011 (rounds 1-15)"

load( paste0( "./" , study.name , "/" , "strpsu.rda" ) )

load( paste0( "./" , study.name , "/" , "R982.rda" ) )

nlsy97.df <- merge( strpsu , w97 , by.x = 'R0000100' , by.y = 'id' )
nlsy97.df <- merge( nlsy97.df , R982 )

# stata option "scaled" .. is this the same?
options( survey.lonely.psu = "remove" )

nlsy97.design <- 
	svydesign( 
		~ R1489800 , 
		strata = ~ R1489700 , 
		data = nlsy97.df ,
		weights = ~ weight ,
		nest = TRUE
	)
	
# negatives are missings
nm <- subset( nlsy97.design , R9829600 >= 0 )

# count
unwtd.count( ~ R9829600 , nm , deff = TRUE )

# estimate, standard error, deff match.
svymean( ~ R9829600 , nm , deff = TRUE )
# deft
sqrt( deff( svymean( ~ R9829600 , nm , deff = TRUE ) ) )


# https://www.nlsinfo.org/content/cohorts/nlsy97/other-documentation/errata/errata-nlsy97-round-15-release/calculating-design

