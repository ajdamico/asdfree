
#######################################################
# function to download scripts directly from github.com
# http://tonybreyal.wordpress.com/2011/11/24/source_https-sourcing-an-r-script-from-github/
source_https <- function(url, ...) {
  # load package
  require(RCurl)

  # parse and evaluate each .R script
  sapply(c(url, ...), function(u) {
    eval(parse(text = getURL(u, followlocation = TRUE, cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl"))), envir = .GlobalEnv)
  })
}
#######################################################

require(stringr) # trim whitespace off of both sides of character strings
require(RSQLite) # load RSQLite package (creates database files in R)
require(survey)	# load survey package (analyzes complex design surveys)
require(SAScii) # load the SAScii package (imports ascii data with a SAS script)
require(descr) # load the descr package (converts fixed-width files to delimited files)
require(RCurl)	# load RCurl package (downloads files from the web)
require(foreign) # load foreign package (converts data files into R)


# load the read.SAScii.sqlite function (a variant of read.SAScii that creates a database directly)
source_https( "https://raw.github.com/ajdamico/usgsd/master/SQLite/read.SAScii.sqlite.R" )

file.remove( "s:/temp/temp.db" )
db <- dbConnect( SQLite() , "s:/temp/temp.db" )
tf <- tempfile() 
td <- tempdir()

for ( year in 1984:2004 ){  

	fn <- 
		ifelse( year < 1990 , 
			paste0( "ftp://ftp.cdc.gov/pub/data/Brfss/CDBRFS" , substr( year , 3 , 4 ) , "_XPT.zip" ) ,
			paste0( "ftp://ftp.cdc.gov/pub/data/Brfss/CDBRFS" , substr( year , 3 , 4 ) , "XPT.zip" ) 
		) 
		
	
	download.file( fn , tf , mode = 'wb' )
	local.fn <- unzip( tf , exdir = td )
	
	dbWriteTable( 
		db , 
		paste0( 'b' , substr( year , 3 , 4 ) ) , 
		read.xport( local.fn ) 
	)
	
	file.remove ( local.fn )
	
	gc()

}

##################################


			
			
for ( year in 2005:2011 ){

	file.remove( tf )

	if ( year == 2011 ){
		fn <- "ftp://ftp.cdc.gov/pub/data/brfss/LLCP2011ASC.ZIP"
		sas_ri <- "http://www.cdc.gov/brfss/technical_infodata/surveydata/2011/SASOUT11_LLCP.SAS"
	} else {
		fn <- paste0( "ftp://ftp.cdc.gov/pub/data/brfss/CDBRFS" , substr( year , 3 , 4 ) , "ASC.ZIP" )
		sas_ri <- paste0( "http://www.cdc.gov/brfss/technical_infodata/surveydata/" , year , "/SASOUT" , substr( year , 3 , 4 ) , ".SAS" )
	}

	z <- readLines( sas_ri )

	if ( year == 2005 ) {
		z <- 
			gsub( 
				"SIPVSKP       394" , 
				"SIPVSKP       394 TOSS_99 395-494 TOSS_98 495-594 TOSS_97 595-694 TOSS_96 695-740" , 
				z , 
				fixed = TRUE 
			)
	}

	if ( year == 2006 ) {
		z <- 
			gsub( 
				"GPEMRINF      373" , 
				"GPEMRINF      373 TOSS_99 374-473 TOSS_98 474-573 TOSS_97 574-673 TOSS_96 674-740" , 
				z , 
				fixed = TRUE 
			)
	}

	if ( year == 2007 ) {
		z <- 
			gsub( 
				"GPEMRINF      399" , 
				"GPEMRINF      399 TOSS_99 400-499 TOSS_98 500-599 TOSS_97 600-699 TOSS_96 700-740" , 
				z , 
				fixed = TRUE 
			)
	}
	
	if ( year == 2008 ) {
		z <- 
			gsub( 
				"HPVCHSHT      385-386" , 
				"HPVCHSHT      385-386 TOSS_99 387-486 TOSS_98 487-586 TOSS_97 587-686 TOSS_96 687-740" , 
				z , 
				fixed = TRUE 
			)
	}
	
	if ( year == 2009 ) {
		z <- 
			gsub( 
				"TNSCSHOT      495" , 
				"TNSCSHOT      495 TOSS_99 496-595 TOSS_98 596-695 TOSS_97 696-795 TOSS_96 796-859" , 
				z , 
				fixed = TRUE 
			)
			
		# remove PF09Q01--PF09Q10
		z <- z[ -159:-168 ]
	}
		
	if ( year == 2010 ) {
		z <- 
			gsub( 
				"ADLTCHLD      498" , 
				"ADLTCHLD      498 TOSS_99 499-598 TOSS_98 599-698 TOSS_97 699-798 TOSS_96 799-859" , 
				z , 
				fixed = TRUE 
			)
	}
	
	if ( year == 2011 ) {
		z <- 
			gsub( 
				"PCTCELL       539-541" , 
				"PCTCELL       539-541  TOSS_99 542-641 TOSS_98 642-741 TOSS_97 742-841 TOSS_96 842-890" , 
				z , 
				fixed = TRUE 
			)
	}

	z <- gsub( "_" , "x" , z , fixed = TRUE )
	z <- z[ !grepl( "SEQNO" , z ) ]
	# z <- z[ !grepl( "STSTR" , z ) ]
	z <- z[ !grepl( "IDATE" , z ) ]
	z <- z[ !grepl( "PHONENUM" , z ) ]
	z <- gsub( "\t" , " " , z , fixed = TRUE )
	z <- gsub( "\f" , " " , z , fixed = TRUE )
	
	writeLines( z , tf )

	# writeLines( brfss.sas.fix( sas_ri , beginline = bl ) , tf )

	read.SAScii.sqlite (
		fn ,
		tf ,
		beginline = 70 ,
		zipped = T ,
		tl = TRUE ,
		tablename = paste0( 'b' , substr( year , 3 , 4 ) ) ,
		db = db
	)
	
}



# try this and review each table!

for ( i in 1984:2011 ) dbGetQuery( db , paste0( "select * from b" , substr( i , 3 , 4 ) , " limit 1" ) )
