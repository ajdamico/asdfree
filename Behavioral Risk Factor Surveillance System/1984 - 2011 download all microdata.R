
require(sqlsurvey)		# load sqlsurvey package (analyzes large complex design surveys)

setwd( "C:/My Directory/BRFSS/" )


source_https <- function(url, ...) {
  # load package
  require(RCurl)

  # parse and evaluate each .R script
  sapply(c(url, ...), function(u) {
    eval(parse(text = getURL(u, followlocation = TRUE, cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl"))), envir = .GlobalEnv)
  })
}
source_https( "https://raw.github.com/ajdamico/usgsd/master/MonetDB/windows.monetdb.configuration.R" )
source_https( "https://raw.github.com/ajdamico/usgsd/master/MonetDB/read.SAScii.monetdb.R" )


stopifnot( file.exists( paste0( getwd() , "/MonetDB" ) ) )

windows.monetdb.configuration( 
		bat.file.location = paste0( getwd() , "\\MonetDB\\monetdb.bat" ) , 
		monetdb.program.path = "C:\\Program Files\\MonetDB\\MonetDB5\\" ,
		database.directory = paste0( getwd() , "\\MonetDB\\" ) ,
		dbname = "brfss" ,
		dbport = 50003
	)

shell.exec( "C:/My Directory/BRFSS/MonetDB/monetdb.bat" )


dbname <- "brfss"
dbport <- 50003

Sys.sleep( 20 )

monetdriver <- "c:/program files/monetdb/monetdb5/monetdb-jdbc-2.7.jar"
drv <- MonetDB( classPath = monetdriver )
monet.url <- paste0( "jdbc:monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( drv , monet.url , user = "monetdb" , password = "monetdb" )

years.to.download <- 1984:2011






require(foreign) # load foreign package (converts data files into R)



tf <- tempfile() 
td <- tempdir()

for ( year in intersect( years.to.download , 1984:2001 ) ){  

	tablename <- paste0( 'b' , year )

	fn <- 
		ifelse( year < 1990 , 
			paste0( "ftp://ftp.cdc.gov/pub/data/Brfss/CDBRFS" , substr( year , 3 , 4 ) , "_XPT.zip" ) ,
			paste0( "ftp://ftp.cdc.gov/pub/data/Brfss/CDBRFS" , substr( year , 3 , 4 ) , "XPT.zip" ) 
		) 
		
	
	download.file( fn , tf , mode = 'wb' )
	local.fn <- unzip( tf , exdir = td )
	
	x <- read.xport( local.fn ) 
	names( x ) <- tolower( names( x ) )
	write.csv( x , tf , row.names = FALSE )

	# rows to check then read
	rtctr <- nrow( x )
	
	# reset all try-error objects
	first.attempt <- second.attempt <- NULL

	# first try it with NAs for NA strings
	first.attempt <- try( monet.read.csv( db , tf , tablename , nrows = rtctr , na.strings = "NA" , nrow.check = rtctr ) , silent = TRUE )
	
	# then try it with "" for NA strings
	if( class( first.attempt ) == "try-error" ) {
		write.csv( x , tf , row.names = FALSE , na = "" )
		
		try( dbRemoveTable( db , tablename ) , silent = TRUE )
		
		second.attempt <-
			try( monet.read.csv( db , tf , tablename , nrows = rtctr , na.strings = "" , nrow.check = rtctr ) , silent = TRUE )
	}

	# if that still doesn't work, import the table manually
	if( class( second.attempt ) == "try-error" ) {
	
		try( dbRemoveTable( db , tablename ) , silent = TRUE )
	
		colTypes <- 
			ifelse( 
				sapply( x , class ) == 'numeric' , 
				'DOUBLE PRECISION' , 
				'VARCHAR(255)' 
			)
		

		colDecl <- paste( names( x ) , colTypes )

		sql.create <-
			sprintf(
				paste(
					"CREATE TABLE" ,
					tablename ,
					"(%s)"
				) ,
				paste(
					colDecl ,
					collapse = ", "
				)
			)
		
		# create the table in the database
		dbSendUpdate( db , sql.create )
		
		sql.update <- 
			paste0( 
				"copy " , 
				rtctr , 
				" offset 2 records into " , 
				tablename , 
				" from '" , 
				tf , 
				"' using delimiters ',' null as ''" 
			)
			
		dbSendUpdate( db , sql.update )
			
	}
	
	
	file.remove ( local.fn )
	
	rm( x )
	
	gc()

}
			
			
for ( year in intersect( years.to.download , 2002:2011 ) ){

	file.remove( tf )
	
	if (year == 2011){
	
		fn <- "ftp://ftp.cdc.gov/pub/data/brfss/LLCP2011ASC.ZIP"
		sas_ri <- "http://www.cdc.gov/brfss/technical_infodata/surveydata/2011/SASOUT11_LLCP.SAS"
		
	} else if ( year == 2002 ){
	
		fn <- paste0( "ftp://ftp.cdc.gov/pub/data/brfss/CDBRFS" , year , "ASC.ZIP" )
		sas_ri <- paste0( "http://www.cdc.gov/brfss/technical_infodata/surveydata/" , year , "/SASOUT" , substr( year , 3 , 4 ) , ".SAS" )
	
	} else {
	
		fn <- paste0( "ftp://ftp.cdc.gov/pub/data/brfss/CDBRFS" , substr( year , 3 , 4 ) , "ASC.ZIP" )
		sas_ri <- paste0( "http://www.cdc.gov/brfss/technical_infodata/surveydata/" , year , "/SASOUT" , substr( year , 3 , 4 ) , ".SAS" )
		
	}

	
	z <- readLines( sas_ri )

	if ( year == 2009 ) z <- z[ -159:-168 ]
	if ( year == 2011 )	z <- z[ !grepl( "CHILDAGE" , z ) ]

	
	z <- gsub( "_" , "x" , z , fixed = TRUE )
	z <- z[ !grepl( "SEQNO" , z ) ]
	z <- z[ !grepl( "IDATE" , z ) ]
	z <- z[ !grepl( "PHONENUM" , z ) ]
	z <- gsub( "\t" , " " , z , fixed = TRUE )
	z <- gsub( "\f" , " " , z , fixed = TRUE )
	
	writeLines( z , tf )

	read.SAScii.monetdb (
		fn ,
		tf ,
		beginline = 70 ,
		zipped = T ,
		tl = TRUE ,
		tablename = paste0( 'b' , year ) ,
		connection = db
	)
	
}




# designate weight, psu, and stratification variables
survey.vars <-
	data.frame(
		year = 1984:2011 ,
		weight = c( rep( 'x_finalwt' , 10 ) , rep( 'xfinalwt' , 17 ) , 'xllcpwt' ) ,
		psu = c( rep( 'x_psu' , 10 ) , rep( 'xpsu' , 18 ) ) ,
		strata = c( rep( 'x_ststr' , 10 ) , rep( 'xststr' , 18 ) )
	)

# convert all columns in the survey.vars table to character strings,
# except the first
survey.vars[ , -1 ] <- sapply( survey.vars[ , -1 ] , as.character )



for ( year in years.to.download ){

	tablename <- paste0( "b" , year )
	strata <- survey.vars[ survey.vars$year == year , 'strata' ]
	psu <- survey.vars[ survey.vars$year == year , 'psu' ]
	weight <- survey.vars[ survey.vars$year == year , 'weight' ]

	dbSendUpdate( db , paste0( 'alter table ' , tablename , ' add column one int' ) )
	dbSendUpdate( db , paste0( 'UPDATE ' , tablename , ' SET one = 1' ) )
	dbSendUpdate( db , paste0( 'alter table ' , tablename , ' add column idkey int auto_increment' ) )

	brfss.design <-
		sqlsurvey(
			weight = weight ,
			nest = TRUE ,
			strata = strata ,
			id = psu ,
			table.name = tablename ,
			key = "idkey" ,
			# check.factors = 10 ,						# defaults to ten
			database = monet.url ,
			driver = drv ,
			user = "monetdb" ,
			password = "monetdb" 
		)


	save( brfss.design , file = paste( tablename , 'design.rda' ) )

}

