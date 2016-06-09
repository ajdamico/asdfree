library(convey)

library(downloader)
library(survey)             # load survey package (analyzes complex design surveys)
library(DBI)                # load the DBI package (implements the R-database coding)
library(MonetDBLite)        # load MonetDBLite package (creates database files in R)


setwd( "C:/My Directory/" )

cps.years.to.download <- 2015
source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Current%20Population%20Survey/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )

options( survey.replicates.mse = TRUE )

dbfolder <- paste0( getwd() , "/MonetDB" )

db <- dbConnect( MonetDBLite() , dbfolder )

y <- 
	svrepdesign(
		weights = ~marsupwt, 
		repweights = "pwwgt[1-9]", 
		type = "Fay", 
		rho = (1-1/sqrt(4)),
		data = "asec15" ,
		combined.weights = T ,
		dbtype = "MonetDBLite" ,
		dbname = dbfolder
	)

y <- convey_prep( y )

# https://www.census.gov/hhes/www/income/data/historical/inequality/Table%20IE-1.pdf
svygini( ~ htotval , subset( y , a_exprrp %in% 1:2 ) )

