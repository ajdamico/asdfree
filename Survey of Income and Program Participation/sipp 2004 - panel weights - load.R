library(SAScii)

setwd("C:/Users/user/Desktop")

fn <- "lrw04_pnl4.dat"

sas_ri <- "http://smpbff2.dsd.census.gov/pub/sipp/2004/lrw04_xx.sas"

sas_lines <- readLines( sas_ri )

#add.dollars <- grepl( "CTL_DATE|LGTWTTYP"  , sas_lines )

#sas_lines[ add.dollars ] <- paste( sas_lines[ add.dollars ] , "$" )

sas_lines <- gsub( "CTL_DATE" , "CTL_DATE $" , sas_lines )
sas_lines <- gsub( "LGTWTTYP" , "LGTWTTYP $" , sas_lines )

tf <- tempfile()

writeLines( sas_lines , tf )

x <- read.SAScii( fn , tf , beginline = 5 , n = -1 , lrecl = 1232 )

