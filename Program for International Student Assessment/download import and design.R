

require(SAScii) 		# load the SAScii package (imports ascii data with a SAS script)
require(descr) 			# load the descr package (converts fixed-width files to delimited files)
require(downloader)		# downloads and then runs the source() function on scripts from github
require(stringr)		# load stringr package (manipulates character strings easily)
require(sqlsurvey)		# load sqlsurvey package (analyzes large complex design surveys)
require(R.utils)		# load the R.utils package (counts the number of lines in a file quickly)


source_url( "https://raw.github.com/ajdamico/usgsd/master/Program%20for%20International%20Student%20Assessment/sqlsurvey%20functions.R" , prompt = FALSE )
source_url( "https://raw.github.com/ajdamico/usgsd/master/Program%20for%20International%20Student%20Assessment/download%20and%20importation%20functions.R" , prompt = FALSE )
source_url( "https://raw.github.com/ajdamico/usgsd/master/Program%20for%20International%20Student%20Assessment/missing%20overwrite%20functions.R" , prompt = FALSE )

# load the read.SAScii.monetdb function (a variant of read.SAScii that creates a database directly)
source_url( "https://raw.github.com/ajdamico/usgsd/master/MonetDB/read.SAScii.monetdb.R" , prompt = FALSE )


# setwd( "C:/My Directory/PISA/" )

batfile <-
	monetdb.server.setup(
					database.directory = paste0( getwd() , "/MonetDB" ) ,
					monetdb.program.path = "C:/Program Files/MonetDB/MonetDB5" ,
					dbname = "pisa" ,
					dbport = 50007
	)

# ( batfile <- "C:/My Directory/PISA/MonetDB/pisa.bat" )
dbname <- "pisa"
dbport <- 50007


monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )


years.to.download <- c( 2000 , 2003 , 2006 , 2009 )

# years.to.download <- 2000







http.pre <- "http://pisa"
http.mid <- ".acer.edu.au/downloads/"



if ( 2009 %in% years.to.download ){

	pid <- monetdb.server.start( batfile )
	db <- dbConnect( MonetDB.R() , monet.url )

	files.to.import <- c( "int_stq09_dec11" , "int_scq09_dec11" , "int_par09_dec11" , "int_cog09_td_dec11" , "int_cog09_s_dec11" )
	
	for ( curFile in files.to.import ){

		fp <- paste0( http.pre , 2009 , http.mid , curFile , ".zip" )
	
		sri <- paste0( http.pre , 2009 , http.mid , gsub( "_d" , "_sas_d" , curFile ) , ".sas" )
		
		read.SAScii.monetdb ( 
			fp ,
			sas_ri = find.chars( add.decimals( remove.tabs( sri ) ) ) , 
			zipped = TRUE ,
			tl = TRUE ,
			tablename = curFile ,
			connection = db
		)
		
	}
	
	
	# missing recodes #
	
	# int_stq09_dec11
	int_stq09_dec11.missings( db )
	
	# int_scq09_dec11
	int_scq09_dec11.missings( db )
	
	# int_par09_dec11
	miss1.txt <- 
		"PA01Q01 PA01Q02 PA01Q03 PA02Q01 PA03Q01 PA03Q02 PA03Q03 PA03Q04 PA03Q05 PA03Q06 PA03Q07 PA03Q08 PA03Q09 PA04Q01 
		PA05Q01 PA06Q01 PA06Q02 PA06Q03 PA06Q04 PA07Q01 PA07Q02 PA07Q03 PA07Q04 PA07Q05 PA07Q06 PA08Q01 PA08Q02 PA08Q03 
		PA08Q04 PA08Q05 PA08Q06 PA08Q07 PA08Q08 PA09Q01 PA09Q02 PA09Q03 PA09Q04 PA10Q01 PA10Q02 PA10Q03 PA10Q04 PA11Q01 
		PA12Q01 PA13Q01 PA14Q01 PA14Q02 PA14Q03 PA14Q04 PA14Q05 PA14Q06 PA14Q07 PA15Q01 PA15Q02 PA15Q03 PA15Q04 PA15Q05 
		PA15Q06 PA15Q07 PA15Q08 PA16Q01 PA17Q01 PA17Q02 PA17Q03 PA17Q04 PA17Q05 PA17Q06 PA17Q07 PA17Q08 PA17Q09 PA17Q10 
		PA17Q11  PQMISCED PQFISCED PQHISCED"

	missing.updates( 
		db , 
		'INT_PAR09_DEC11' , 
		split.n.clean( miss1.txt ) ,
		7:9 
	)

	missing.updates( 
		db , 
		'INT_PAR09_DEC11' , 
		c( "PRESUPP" , "MOTREAD" , "READRES" , "CURSUPP" , "PQSCHOOL" , "PARINVOL" ) ,
		9997:9999 
	)
	
	# note: no missing recodes for `int_cog09_s_dec11` or `int_cog09_td_dec11`
	
	# end of missing recodes #
	
	
	construct.pisa.sqlsurvey.designs(
		monet.url , 
		year = 2009 ,
		table.name = 'int_stq09_dec11' ,
		pv.vars = c( 'math' , 'read' , 'scie' , 'read1' , 'read2' , 'read3' , 'read4' , 'read5' ) ,
		sas_ri = find.chars( add.decimals( remove.tabs( "http://pisa2009.acer.edu.au/downloads/int_stq09_sas_dec11.sas" ) ) )
	)
	
	dbDisconnect( db )
	monetdb.server.stop( pid )

}

if ( 2006 %in% years.to.download ){

	pid <- monetdb.server.start( batfile )
	db <- dbConnect( MonetDB.R() , monet.url )

	files.to.import <- c( "int_stu06_dec07" , "int_sch06_dec07" , "int_par06_dec07" , "int_cogn06_t_dec07" , "int_cogn06_s_dec07" )

	for ( curFile in files.to.import ){

		fp <- paste0( http.pre , 2006 , http.mid , curFile , ".zip" )
	
		sri <- paste0( http.pre , 2006 , http.mid , gsub( "_d" , "_sas_d" , curFile ) , ".sas" )
	
		read.SAScii.monetdb ( 
			fp ,
			sas_ri = find.chars( add.decimals( remove.tabs( sri ) ) ) , 
			zipped = TRUE ,
			tl = TRUE ,
			tablename = curFile ,
			connection = db
		)
		
	}
	
	# missing recodes #
	
	# int_stu06_dec07
	int_stu06_dec07.missings( db )
	
	# int_sch06_dec07
	int_sch06_dec07.missings( db )
	
	# int_par06_dec07
	int_par06_dec07.missings( db )
	
	# int_cogn06_t_dec07
	int_cogn06_t_dec07.missings( db )
	
	# int_cogn06_s_dec07
	int_cogn06_s_dec07.missings( db )
	
	# end of missing recodes #
	
	construct.pisa.sqlsurvey.designs(
		monet.url , 
		year = 2006 ,
		table.name = 'int_stu06_dec07' ,
		pv.vars = c( 'math' , 'read' , 'scie' , 'intr' , 'supp' , 'eps' , 'isi' , 'use' ) ,
		sas_ri = find.chars( add.decimals( remove.tabs( "http://pisa2006.acer.edu.au/downloads/int_stu06_sas_dec07.sas" ) ) )
	)
	
	dbDisconnect( db )
	monetdb.server.stop( pid )

}

  
if ( 2003 %in% years.to.download ){

	pid <- monetdb.server.start( batfile )
	db <- dbConnect( MonetDB.R() , monet.url )

	files.to.import <- c( "int_cogn_2003" , "int_stui_2003_v2" , "int_schi_2003" )
	
	for ( curFile in files.to.import ){

		zipped <- TRUE
	
		fp <- paste0( http.pre , 2003 , http.mid , curFile , ".zip" )
	
		sri <- paste0( http.pre , 2003 , http.mid , gsub( "int" , "read" , curFile ) , ".sas" )
	
		# get rid of some goofy `n` values in this ascii data
		if ( curFile == "int_cogn_2003" ){
		
			zipped <- FALSE
			
			tf <- tempfile() ; tf2 <- tempfile() ; td <- tempdir()
			
			download.file( fp , tf , mode = 'wb' )
			
			tf3 <- unzip( tf , exdir = td )
			
			# read-only file connection "r" - pointing to the ASCII file
			incon <- file( tf3 , "r")

			# write-only file connections "w"
			outcon <- file( tf2 , "w" )
			
			while( length( line <- readLines( incon , 10000 ) ) > 0 ){
				line <- gsub( "n" , " " , line , fixed = TRUE )
				writeLines( line , outcon )
			}

			close( outcon )
			close( incon , add = T )
			
			fp <- tf2
			
			# the sas importation script is screwey too.
			sri <- sas.is.evil( sri )
			# fix it.
		}
	

		read.SAScii.monetdb ( 
			fp ,
			sas_ri = find.chars( add.decimals( remove.tabs( sri ) ) ) , 
			zipped = zipped ,
			tl = TRUE ,
			tablename = curFile ,
			connection = db
		)
			
	}

	# missing recodes #
	
	# int_cogn_2003
	missing.updates( db , 'int_cogn_2003'  , c( "CLCUSE3a" , "CLCUSE3b" ) , 997:999 )
	
	# int_stui_2003_v2
	int_stui_2003_v2.missings( db )
	
	# int_schi_2003
	int_schi_2003.missings( db )
	
	# end of missing recodes #
	
	construct.pisa.sqlsurvey.designs(
		monet.url , 
		year = 2003 ,
		table.name = 'int_stui_2003_v2' ,
		pv.vars = c( 'math' , 'math1' , 'math2' , 'math3' , 'math4' , 'read' , 'scie' , 'prob' ) ,
		sas_ri = find.chars( add.decimals( remove.tabs( "http://pisa2003.acer.edu.au/downloads/read_stui_2003_v2.sas" ) ) )
	)
	
	dbDisconnect( db )
	monetdb.server.stop( pid )

}

if ( 2000 %in% years.to.download ){

	pid <- monetdb.server.start( batfile )
	db <- dbConnect( MonetDB.R() , monet.url )

	files.to.import <- c( "intcogn_v3" , "intscho" , "intstud_math" , "intstud_read" , "intstud_scie" )

	for ( curFile in files.to.import ){

		fp <- paste0( http.pre , 2000 , http.mid , curFile , ".zip" )
	
		sri <- paste0( http.pre , 2000 , http.mid , curFile , ".sas" )
	
		if ( curFile == "intstud_math" ) {
			sri <- find.chars( add.decimals( add.sdt( remove.tabs( stupid.sas( sri ) ) ) ) )
			
			# this one is annoying.
			# just read it into RAM (it fits under 4GB)
			# then save to MonetDB
			ism <- read.SAScii( fp , sri , zipped = TRUE )
			names( ism ) <- tolower( names( ism ) )
			# dbWriteTable( db , curFile , ism )
			ism$toss_0 <- NULL
			tf <- tempfile()
			write.csv( ism , tf , row.names = FALSE )
			monet.read.csv( db , tf , curFile , countLines( tf ) , nrow.check = 20000 , na.strings = "NA" )

			rm( ism )
			gc()
			
		} else {
	
			sri <- find.chars( add.decimals( add.sdt( remove.tabs( sri ) ) ) )
			
			if ( curFile %in% c( "intstud_read" , "intstud_scie" ) ) sri <- sas.is.quite.evil( sri )
			
			read.SAScii.monetdb ( 
				fp ,
				sas_ri = sri , 
				zipped = TRUE ,
				tl = TRUE ,
				tablename = curFile ,
				connection = db
			)
		
		}
		
	}

	
	# missing recodes #
	
	# note: no missing recodes for `intcogn_v3`
	
	# intscho
	intscho.missings( db )

	# intstud_math
	intstud.missings( db , 'intstud_math' )
		
	miss6.math <-
		c(
			"wlemath" , "wleread" , "wleread1" , "wleread2" , "wleread3" , "pv1math" , "pv2math" , "pv3math" , "pv4math" , "pv5math" , "pv1math1" , "pv2math1" , "pv3math1" , "pv4math1" , "pv5math1" , "pv1math2" , "pv2math2" , "pv3math2" , "pv4math2" , "pv5math2" , "pv1read" , "pv2read" , "pv3read" , "pv4read" , "pv5read" , "pv1read1" , "pv2read1" , "pv3read1" , "pv4read1" , "pv5read1" , "pv1read2" , "pv2read2" , "pv3read2" , "pv4read2" , "pv5read2" , "pv1read3" , "pv2read3" , "pv3read3" , "pv4read3" , "pv5read3" , "wlerr_m" , "wlerr_r" , "wlerr_r1" , "wlerr_r2" , "wlerr_r3"
		)
		
	missing.updates( db , 'intstud_math' , miss6.math , 9997 )
	
	# intstud_read
	intstud.missings( db , 'intstud_read' )
		
	miss6.read <-
		c(
			"wleread" , "wleread1" , "wleread2" , "wleread3" , "pv1read" , "pv2read" , "pv3read" , "pv4read" , "pv5read" , "pv1read1" , "pv2read1" , "pv3read1" , "pv4read1" , "pv5read1" , "pv1read2" , "pv2read2" , "pv3read2" , "pv4read2" , "pv5read2" , "pv1read3" , "pv2read3" , "pv3read3" , "pv4read3" , "pv5read3" , "wlerr_r" , "wlerr_r1" , "wlerr_r2" , "wlerr_r3"
		)
	
	missing.updates( db , 'intstud_read'  , miss6.read , 9997 )
	
	# intstud_scie
	intstud.missings( db , 'intstud_scie' )
	
	miss6.scie <-
		c( 
			"wleread" , "wleread1" , "wleread2" , "wleread3" , "wlescie" , "pv1read" , "pv2read" , "pv3read" , "pv4read" , "pv5read" , "pv1read1" , "pv2read1" , "pv3read1" , "pv4read1" , "pv5read1" , "pv1read2" , "pv2read2" , "pv3read2" , "pv4read2" , "pv5read2" , "pv1read3" , "pv2read3" , "pv3read3" , "pv4read3" , "pv5read3" , "pv1scie" , "pv2scie" , "pv3scie" , "pv4scie" , "pv5scie" , "wlerr_r" , "wlerr_r1" , "wlerr_r2" , "wlerr_r3" , "wlerr_s"
		)
	
	missing.updates( db , 'intstud_scie'  , miss6.scie , 9997 )
	
	# end of missing recodes #
	
	
	construct.pisa.sqlsurvey.designs(
		monet.url , 
		year = 2000 ,
		table.name = 'intstud_math' ,
		pv.vars = c( 'math' , 'math1' , 'math2' , 'read' , 'read1' , 'read2' , 'read3' ) ,
		sas_ri = find.chars( add.decimals( add.sdt( remove.tabs( stupid.sas( "http://pisa2000.acer.edu.au/downloads/intstud_math.sas" ) ) ) ) )
	)
	
	construct.pisa.sqlsurvey.designs(
		monet.url , 
		year = 2000 ,
		table.name = 'intstud_read' ,
		pv.vars = c( 'read' , 'read1' , 'read2' , 'read3' ) ,
		sas_ri = sas.is.quite.evil( find.chars( add.decimals( add.sdt( remove.tabs( "http://pisa2000.acer.edu.au/downloads/intstud_read.sas" ) ) ) ) )
	)
	
	construct.pisa.sqlsurvey.designs(
		monet.url , 
		year = 2000 ,
		table.name = 'intstud_scie' ,
		pv.vars = c( 'read' , 'read1' , 'read2' , 'read3' , 'scie' ) ,
		sas_ri = sas.is.quite.evil( find.chars( add.decimals( add.sdt( remove.tabs( "http://pisa2000.acer.edu.au/downloads/intstud_scie.sas" ) ) ) ) )
	)
	
	dbDisconnect( db )
	monetdb.server.stop( pid )
	
}



