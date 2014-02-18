setwd( "C:/My Directory/NHTS/" )

library(MonetDB.R)			# load the MonetDB.R package (connects r to a monet database)
library(downloader)			# downloads and then runs the source() function on scripts from github
library(R.utils)			# load the R.utils package (counts the number of lines in a file quickly)



tf <- tempfile() ; tf2 <- tempfile() ; td <- tempdir()

source_url( 
	"https://raw.github.com/ajdamico/usgsd/master/Download%20Cache/download%20cache.R" , 
	prompt = FALSE , 
	echo = FALSE 
)

batfile <-
	monetdb.server.setup(
					database.directory = paste0( getwd() , "/MonetDB" ) ,
					monetdb.program.path = 
						ifelse( 
							.Platform$OS.type == "windows" , 
							"C:/Program Files/MonetDB/MonetDB5" , 
							"" 
						) ,
					dbname = "nhts" ,
					dbport = 50013
	)

	
dbname <- "nhts"
dbport <- 50013

pid <- monetdb.server.start( batfile )

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )


download.cache( 
	url = "http://nhts.ornl.gov/2001/download/Ascii.zip" , 
	destfile = tf , 
	mode = 'wb' 
)

z <- unzip( tf , exdir = td )

z <- z[ !grepl( 'citation' , tolower( z ) ) ]

ldtpub.file <- z[ grep( 'ldtpub' , tolower( z ) ) ]

download.cache( 
	url = "http://nhts.ornl.gov/2001/download/replicates_ascii.zip" , 
	destfile = tf2 , 
	mode = 'wb' 
)

y <- unzip( tf2 , exdir = td )

ldtwt.file <- y[ grep( 'ldt' , tolower( y ) ) ]


monet.read.csv( 
	db , 
	ldtpub.file , 
	'ldtpub' , 
	nrows = countLines( ldtpub.file ) , 
	header = TRUE , 
	nrow.check = 250000 
)

monet.read.csv( 
	db , 
	ldtwt.file , 
	'ldtwt' , 
	nrows = countLines( ldtwt.file ) , 
	header = TRUE , 
	nrow.check = 250000 
)


dbGetQuery( db , 'select count(*) from ( select houseid , personid from ldtpub ) as a inner join ( select houseid , personid from ldtwt ) as b on a.houseid = b.houseid and a.personid = b.personid' )

dbSendUpdate( db , 'create index ldtwt_index ON ldtwt ( houseid , personid )' )

dbGetQuery( db , 'select count(*) from ( select houseid , personid from ldtpub ) as a inner join ( select houseid , personid from ldtwt ) as b on a.houseid = b.houseid and a.personid = b.personid' )

