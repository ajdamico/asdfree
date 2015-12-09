setwd( "C:/My Directory/PNS/" )


library(SAScii)
tf <- tempfile()
download.file( "ftp://ftp.ibge.gov.br/PNS/2013/microdados/pns_2013_microdados.zip" , tf , mode = 'wb' )
z <- unzip( tf , exdir = tempdir() )

# files
z

dd <- grep( "Dados/DOMPNS" , z , value = TRUE )
pd <- grep( "Dados/PESPNS" , z , value = TRUE )
ds <- grep( "DOMPNS(.*)\\.sas" , z , value = TRUE )
ps <- grep( "PESPNS(.*)\\.sas" , z , value = TRUE )

dom <- read.SAScii( dd , ds )
pes <- read.SAScii( pd , ps )
