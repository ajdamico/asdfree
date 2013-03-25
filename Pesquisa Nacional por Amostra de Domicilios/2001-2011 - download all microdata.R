remove.uf <-
	function( sasfile ){

		sas_lines <- readLines( sasfile )

		sas_lines <- gsub( "\t" , "  " , sas_lines )
		
		sas_lines <- sas_lines[ !grepl( "@00005[ ]+UF[ ]" , sas_lines ) ]

		sas_lines <- 
			gsub(
				"@00840  V2913  $1 ./* LOCAL ÚLTIMO FURTO    */" ,
				"@00840  V2913  $1. /* LOCAL ÚLTIMO FURTO    */" ,
				sas_lines ,
				fixed = TRUE
			)
		
		# create a temporary file
		tf <- tempfile()

		# write the updated sas input file to the temporary file
		writeLines( sas_lines , tf )

		# return the filepath to the temporary file containing the updated sas input script
		tf
}

setwd( "C:/My Directory/PNAD" )


require(RSQLite) 	# load RSQLite package (creates database files in R)
require(SAScii) 	# load the SAScii package (imports ascii data with a SAS script)
require(descr) 		# load the descr package (converts fixed-width files to delimited files)
require(downloader)	# downloads and then runs the source() function on scripts from github

source_url( "https://raw.github.com/ajdamico/usgsd/master/SQLite/read.SAScii.sqlite.R" )

years.to.download <- c( 2001:2009 , 2011 )

pnad.dbname <- "pnad.db"

tf <- tempfile() ; td <- tempdir()

# open the connection to the sqlite database
db <- dbConnect( SQLite() , pnad.dbname )

		
for ( year in years.to.download ){


	if ( year > 2010 ){

		ftp.path <-
			paste0(
				"ftp://ftp.ibge.gov.br/Trabalho_e_Rendimento/Pesquisa_Nacional_por_Amostra_de_Domicilios_anual/microdados/" ,
				year ,
				"/"
			)
			
		data.file <- paste0( ftp.path , "/Dados.zip" )
		
		sas.input.instructions <- paste0( ftp.path , "/Dicionarios.zip" )

		download.file( data.file , tf , mode = "wb" )

		files <- unzip( tf , exdir = td )

		download.file( sas.input.instructions , tf , mode = "wb" )

		files <- c( files , unzip( tf , exdir = td ) )

	} else {
	
		ftp.path <-
			paste0(
				"ftp://ftp.ibge.gov.br/Trabalho_e_Rendimento/Pesquisa_Nacional_por_Amostra_de_Domicilios_anual/microdados/reponderacao_2001_2009/PNAD_reponderado_" ,
				year ,
				".zip"
			)
	
		download.file( ftp.path , tf , mode = "wb" )
		
		files <- unzip( tf , exdir = td )
		
	}

	files <- tolower( files )
	
	dom.sas <- remove.uf( files[ grepl( paste0( 'input[^?]dom' , year , '.txt' ) , files ) ] )
	pes.sas <- remove.uf( files[ grepl( paste0( 'input[^?]pes' , year , '.txt' ) , files ) ] )
	
	dom.fn <- files[ grepl( paste0( 'dados/dom' , year ) , files ) ]
	pes.fn <- files[ grepl( paste0( 'dados/pes' , year ) , files ) ]


	read.SAScii.sqlite ( 
		dom.fn , 
		dom.sas , 
		zipped = F , 
		tl = TRUE ,
		tablename = paste0( 'dom' , year ) ,
		db = db
	)
	
	read.SAScii.sqlite ( 
		pes.fn , 
		pes.sas , 
		zipped = F , 
		tl = TRUE ,
		tablename = paste0( 'pes' , year ) ,
		db = db
	)

	dbSendQuery( db , paste0( "CREATE INDEX pes_index" , year , " ON pes" , year , " ( v0101 , v0102 , v0103 )" ) )
	dbSendQuery( db , paste0( "CREATE INDEX dom_index" , year , " ON dom" , year , " ( v0101 , v0102 , v0103 )" ) )

	dbSendQuery( db , paste0( "create table pnad" , year , " as select * from pes" , year , " as a inner join dom" , year , " as b on a.v0101 = b.v0101 AND a.v0102 = b.v0102 AND a.v0103 = b.v0103" ) )

	print( year )
	print( dbGetQuery( db , paste0( "select count(*) from pes" , year ) ) )
	print( dbGetQuery( db , paste0( "select count(*) from dom" , year ) ) )
	print( dbGetQuery( db , paste0( "select count(*) from pnad" , year ) ) )
	
	gc()
	
	x <- dbReadTable( db , paste0( 'pnad' , year ) )
	
	x$one <- 1
	
	save( x , file = paste0( 'pnad' , year , '.rda' ) )
	
	rm( x )
	
	gc()
	
	
}

dbListTables( db )

dbDisconnect( db )

file.remove( pnad.dbname )

