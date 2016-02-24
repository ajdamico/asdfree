
path.to.7z <- normalizePath( "C:/Program Files (x86)/7-zip/7z.exe" )		# # this is probably the correct line for windows
# path.to.7z <- "7za"													# # this is probably the correct line for macintosh and *nix



options( encoding = "latin1" )		# # only macintosh and *nix users need this line

tf <- tempfile() ; tf2 <- tempfile()

library(downloader)
library(MonetDBLite)
library(MonetDB.R)
library(SAScii)
library(RCurl)
library(R.utils)
library(descr)


# load the download_cached and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url(
	"https://raw.githubusercontent.com/ajdamico/asdfree/master/Download%20Cache/download%20cache.R" ,
	prompt = FALSE ,
	echo = FALSE
)

# load the read.SAScii.monetdb function (a variant of read.SAScii that creates a database directly)
source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/MonetDB/read.SAScii.monetdb.R" , prompt = FALSE )




ranc <- 
	function( infile ){

		tf_a <- tempfile()

		outcon <- file( tf_a , "w" )

		incon <- file( infile , "r")

		line.num <- 0
			
		while( length( line <- readLines( incon , 1 ) ) > 0 ){
			
			line <- iconv( line , "" , "ASCII" , sub = " " )
			
			writeLines( line , outcon )
		}

		close( incon )

		close( outcon )

		tf_a
	}


# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite() , paste0( getwd() , "/MonetDB" ) )



w <- 
	strsplit( 
		getURL( 
			"ftp://ftp.inep.gov.br/microdados/" , 
			ftp.use.epsv = FALSE , 
			dirlistonly = TRUE 
		) , 
		"\r\n" 
	)[[1]]
	
enem_files <- grep( "enem" , w , value = TRUE )

years_to_download <- gsub( "(.*)([0-9][0-9][0-9][0-9])(.*)" , "\\2" , enem_files )

# start with the most recent year first
years_to_download <- rev( sort( years_to_download ) )

# for ( year in sample( years_to_download , 16 ) ){
for ( year in years_to_download ){
# for ( year in 2009 ){

	download_cached( 
		paste0( 
			"ftp://ftp.inep.gov.br/microdados/" , 
			grep( year , enem_files , value = TRUE ) 
		) , 
		tf , 
		mode = 'wb' 
	)

	if( !grepl( "\\.rar" , grep( year , enem_files , value = TRUE ) ) ){
	
		z <- unzip( tf , exdir = tempdir() )
		zf <- grep( "\\.zip|\\.ZIP" , z , value = TRUE )
		if( length( zf ) > 0 ) z <- c( z , unzip( zf , exdir = tempdir() ) )
		
		rfi <- grep( "\\.rar|\\.RAR" , z , value = TRUE )
	
	} else {
		z <- NULL
		rfi <- tf
	}
		
	if( length( rfi ) > 0 ) {
		
		dos.command <- paste0( '"' , path.to.7z , '" e ' , rfi , ' -o' , tempdir() )
		
		if ( .Platform$OS.type == 'windows' ){
			shell( dos.command ) 
		} else {
			system( dos.command )
		}
		
		z <- unique( c( z , list.files( tempdir() , recursive = TRUE , full.names = TRUE  ) ) )
		
	}

	# 2007 has a duplicate
	if( any( grepl( "DADOS(.*)DADOS_ENEM_2007\\.TXT" , z ) ) ) z <- z[ !grepl( "DADOS(.*)DADOS_ENEM_2007\\.TXT" , z ) ]
	
	csvfile <- grep( "\\.csv|\\.CSV" , z , value = TRUE )

	if( length( csvfile ) > 0 ){
	
		for( this_file in csvfile ){
		
			tablename <- tolower( gsub( "\\.(.*)" , "" , basename( this_file ) ) )
		
			soc <- grepl( "," , readLines( this_file , 1 ) )
		
			attempt_one <- try( monetdb.read.csv( db , this_file , tablename , lower.case.names = TRUE , delim = ifelse( soc , "," , ";" ) ) , silent = TRUE )
			
			if( class( attempt_one ) == 'try-error' ){
			
				this_file <- ranc( this_file )
				
				monetdb.read.csv( db , this_file , tablename , lower.case.names = TRUE , delim = ifelse( soc , "," , ";" ) , best.effort = tablename == "microdados_enem_2013" )
				
			}
			
			stopifnot( countLines( this_file ) %in% ( dbGetQuery( db , paste0( "SELECT COUNT(*) FROM " , tablename ) )[ 1 , 1 ] + -5:5 ) )

		}
	
	} else {
		
		sas_ri <- grep( "\\.sas|\\.SAS" , z , value = TRUE )

		if( length( sas_ri ) > 1 ) sas_ri <- sas_ri[ !grepl( "questionario|prova" , tolower( basename( sas_ri ) ) ) ]
		
		if( year %in% 1999:2000 ) options( encoding = 'native.enc' )
		sas_t <- readLines( sas_ri )
		sas_t <- gsub( "\t" , " " , sas_t )
		sas_t <- gsub( "char(.*)" , "\\1" , tolower( sas_t ) )
		sas_t <- gsub( "datetime(.*)" , "$ \\1" , tolower( sas_t ) )
		sas_t <- gsub( "\U0096" , " " , sas_t )
		sas_t <- iconv( sas_t , "" , "ASCII" , sub = " " )
		writeLines( sas_t , tf2 )
		if( year %in% 1999:2000 ) options( encoding = 'latin1' )
		
		dfile <- grep( "\\.txt|\\.TXT" , z , value = TRUE )
		
		if( length( dfile ) > 1 ) dfile <- dfile[ grep( "dados" , tolower( basename( dfile ) ) ) ]
		
		row_check <- TRUE
		
		attempt_one <- try( {
			read.SAScii.monetdb ( 
				dfile , 
				tf2 , 
				zipped = FALSE , 
				tl = TRUE ,
				tablename = paste0( 'enem' , year ) ,
				conn = db
			)
		} , silent = TRUE )
		
		if( class( attempt_one ) == 'try-error' ){
		
			dfile <- ranc( dfile )
		
			if( year == 2004 ){
			
				row_check <- FALSE
			
				read.SAScii.monetdb ( 
					dfile , 
					tf2 , 
					zipped = FALSE , 
					tl = TRUE ,
					tablename = paste0( 'enem' , year ) ,
					conn = db ,
					try_best_effort = TRUE
				)
				
			} else {
			
				read.SAScii.monetdb ( 
					dfile , 
					tf2 , 
					zipped = FALSE , 
					tl = TRUE ,
					tablename = paste0( 'enem' , year ) ,
					conn = db
				)
			
			}
		
		}
		
		
		if( row_check ) stopifnot( countLines( dfile ) %in% ( dbGetQuery( db , paste0( "SELECT COUNT(*) FROM enem" , year ) )[ 1 , 1 ] + -5:5 ) )

			
	}
	
	
	
	unlink( z )
	
}

