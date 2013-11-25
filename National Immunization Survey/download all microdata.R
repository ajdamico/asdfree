
setwd( "C:/My Directory/NIS" )

# nis.years.to.download <- NULL
nis.years.to.download <- 1995:2011

nhfs.download <- TRUE
# nhfs.download <- FALSE


# nis.teen.years.to.download <- NULL
nis.teen.years.to.download <- 2008:2011


library(SAScii)

tf <- tempfile() ; td <- tempdir()


dir.create( "./puf" )

for ( year in nis.years.to.download ){

	print( year )

	# download all public use files #
	
	puf.savename <- paste0( './puf/NISPUF' , substr( year , 3 , 4 ) , '.DAT' )
	
	straight.dat <-
		paste0(
			"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/nis/nispuf" ,
			substr( year , 3 , 4 ) ,
			".dat"
		)
		
	if ( year %in% c( 1998 , 2006 ) ){
		
		sdat <- try( stop( 'get the zip instead of the dat these two years' ) , silent = TRUE )

	} else {
	
		sdat <- try( download.file( straight.dat , tf , mode = 'wb' ) , silent = TRUE )

	}
		
	if( class( sdat ) == 'try-error' ){
		
		zip.dat <-
			paste0(
				"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/nis/nispuf" ,
				substr( year , 3 , 4 ) ,
				".dat.zip"
			)
		
		zdat <- try( download.file( zip.dat , tf , mode = 'wb' ) , silent = TRUE )

		if( class( zdat ) == 'try-error' ){
					
			zip.dat <-
				paste0(
					"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/nis/nispuf" ,
					substr( year , 3 , 4 ) ,
					"_dat.zip"
				)
			
			zdat <- try( download.file( zip.dat , tf , mode = 'wb' ) , silent = TRUE )

			
			if( class( zdat ) == 'try-error' ){
		
				zip.dat <-
					paste0(
						"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NIS/nispuf" ,
						substr( year , 3 , 4 ) ,
						"dat.zip"
					)
				
				download.file( zip.dat , tf , mode = 'wb' )
			
			}

		}
		
		z <- unzip( tf , exdir = td )
	
	
		if( length( z ) > 1 ) stop( 'multiple files stored inside the zipped file?  dat is not allowed.' )
	
		file.rename( z , puf.savename )
	
	} else {
	
		file.rename( tf , puf.savename )
	
	}

	# end of puf downloading #

	
	# download and execute all scripts #

	# look for the R file first
	script.r <-
		paste0(
			"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/nis/nispuf" ,
			substr( year , 3 , 4 ) ,
			".r"
		)
	
	
	rs <- try( download.file( script.r , tf , mode = 'wb' ) , silent = TRUE )

	
	if( class( rs ) == 'try-error' ){	
		
		script.sas <-
			paste0(
				"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/nis/nispuf" ,
				substr( year , 3 , 4 ) ,
				".sas"
			)
		
		download.file( script.sas , tf , mode = 'wb' )

		script.txt <- readLines( tf )
		
		script.sub <- script.txt[ grep( "D. CREATES PERMANENT SAS DATASET|INFILE &flatfile LRECL=721|INFILE &flatfile LRECL=773" , script.txt ):length( script.txt ) ]

		writeLines( script.sub , tf )
		
		x <- 
			read.SAScii( 
				paste0( './puf/NISPUF' , substr( year , 3 , 4 ) , '.DAT' ) ,
				tf
			)
					
	} else {
	
		script.r <- readLines( tf )
		
		script.r <- gsub( "path-to-data" , "." , script.r )
		
		script.r <- gsub( "path-to-file" , "./puf" , script.r )
		
		writeLines( script.r , tf )
		
		source( tf , echo = TRUE )
		
		file.remove( paste0( './NISPUF' , substr( year , 3 , 4 ) , '.RData' ) )
		
		nis.df <- paste0( 'NISPUF' , substr( year , 3 , 4 ) )
		
		x <- get( nis.df )
	
		rm( list = nis.df )
		
		gc()
	
	}
	
	names( x ) <- tolower( names( x ) )
	
	save( 
		x , 
		file = 
			paste0( 
				'./nis' , 
				year , 
				'.rda' 
			)
	)
	
	rm( x )
	
	gc()

}



for ( year in nis.teen.years.to.download ){

	print( year )

	# download all public use files #
	
	puf.savename <- paste0( './puf/NISTEENPUF' , substr( year , 3 , 4 ) , '.DAT' )
	
	straight.dat <-
		paste0(
			"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/nis/nisteenpuf" ,
			substr( year , 3 , 4 ) ,
			".dat"
		)
		
	download.file( straight.dat , tf , mode = 'wb' )

	
	file.rename( tf , puf.savename )
	
	# end of puf downloading #

	
	# download and execute all scripts #

	# look for the R file first
	script.r <-
		paste0(
			"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/nis/nisteenpuf" ,
			substr( year , 3 , 4 ) ,
			".r"
		)
	
	
	download.file( script.r , tf , mode = 'wb' )

	script.r <- readLines( tf )
	
	script.r <- gsub( "path-to-data" , "." , script.r )
	
	script.r <- gsub( "path-to-file" , "./puf" , script.r )

	script.r <- gsub( "IHQSTATUSlevels=c(,M,N,V)" , "IHQSTATUSlevels=c(NA,'M','N','V')" , script.r , fixed = TRUE )
	
	script.r <- gsub( "=c(," , "=c(NA," , script.r , fixed = TRUE )

	writeLines( script.r , tf )
	
	source( tf , echo = TRUE )
	
	file.remove( paste0( './NISTEENPUF' , substr( year , 3 , 4 ) , '.RData' ) )
	
	nis.df <- paste0( 'NISTEENPUF' , substr( year , 3 , 4 ) )
	
	x <- get( nis.df )

	rm( list = nis.df )
	
	gc()
	
	names( x ) <- tolower( names( x ) )
	
	save( 
		x , 
		file = 
			paste0( 
				'./nisteen' , 
				year , 
				'.rda' 
			)
	)
	
	rm( x )
	
	gc()

}











if ( nhfs.download ){

	print( "2009 h1n1 flu survey" )

	# download all public use files #
	
	puf.savename <- './puf/NHFSPUF.DAT'
	
	straight.dat <-
		"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/nis/nhfs/nhfspuf.dat"
		
	download.file( straight.dat , tf , mode = 'wb' )

	file.rename( tf , puf.savename )

	# download and execute all scripts #

	# look for the R file first
	script.r <-
		"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/nis/nhfs/nhfspuf.r"
	
	
	download.file( script.r , tf , mode = 'wb' )

	script.r <- readLines( tf )
	
	script.r <- gsub( "path-to-data" , "." , script.r )
	
	script.r <- gsub( "path-to-file" , "./puf" , script.r )
		
	writeLines( script.r , tf )
	
	source( tf , echo = TRUE )
	
	file.remove( './NHFSPUF.RData' )
	
	x <- NHFSPUF
	
	rm( NHFSPUF )
		
	gc()
	
	names( x ) <- tolower( names( x ) )
	
	save( 
		x , 
		file = 
			'./nhfs2009.rda'
	)
	
	rm( x )
	
	gc()

}

