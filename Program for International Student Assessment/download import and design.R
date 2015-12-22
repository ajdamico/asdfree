# analyze survey data for free (http://asdfree.com) with the r language
# program for international student assessment
# 2000, 2003, 2006, 2009, 2012
# each and every available file hooray

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( encoding = "windows-1252" )		# # only macintosh and *nix users need this line
# library(downloader)
# setwd( "C:/My Directory/PISA/" )
# years.to.download <- c( 2000 , 2003 , 2006 , 2009 , 2012 )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Program%20for%20International%20Student%20Assessment/download%20import%20and%20design.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com



#####################################################################################
# download all available program for international student assessment files from    #
# the organisation for economic co-operation and development's website, then import #
# each file into a monet database, make corrections so the files are beeeeeeautiful #
# create a multiply-imputed, monetdb-backed complex sample survey design with r!    #
#####################################################################################


# # # # # # # # # # # # # # # #
# warning: this takes a while #
# # # # # # # # # # # # # # # #

# even if you're only downloading a single year of data and you've got a fast internet connection,
# you'll be better off leaving this script to run overnight.  if you wanna download all available files and years,
# leave it running on friday afternoon (or even better: before you leave for a weeklong vacation).
# depending on your internet and processor speeds, the entire script should take between two and ten days.
# it's running.  don't believe me?  check the working directory (set below) for a new r data file (.rda) every few hours.


# remove the # in order to run this install.packages line only once
# install.packages( c("MonetDB.R", "MonetDBLite" , "survey" , "SAScii" , "descr" , "ff" , "downloader" , "digest" , "R.utils" , "stringr" , "mitools" ) , repos=c("http://dev.monetdb.org/Assets/R/", "http://cran.rstudio.com/"))


library(SAScii) 		# load the SAScii package (imports ascii data with a SAS script)
library(descr) 			# load the descr package (converts fixed-width files to delimited files)
library(downloader)		# downloads and then runs the source() function on scripts from github
library(stringr)		# load stringr package (manipulates character strings easily)
library(survey) 		# load survey package (analyzes complex design surveys)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(MonetDBLite)	# load MonetDBLite package (creates database files in R)
library(R.utils)		# load the R.utils package (counts the number of lines in a file quickly)
library(mitools) 		# load mitools package (analyzes multiply-imputed data)


# load a compilation of functions that will be useful when executing actual analysis commands with this multiply-imputed, monetdb-backed behemoth
source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Program%20for%20International%20Student%20Assessment/survey%20functions.R" , prompt = FALSE )

# load a couple of functions that will ease the importation process
source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Program%20for%20International%20Student%20Assessment/download%20and%20importation%20functions.R" , prompt = FALSE )

# load a few functions that will correct missing data in the raw files
source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Program%20for%20International%20Student%20Assessment/missing%20overwrite%20functions.R" , prompt = FALSE )

# load the read.SAScii.monetdb function (a variant of read.SAScii that creates a database directly)
source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/MonetDB/read.SAScii.monetdb.R" , prompt = FALSE )


# set your PISA data directory
# after downloading and importing
# all monet database-backed complex survey designs will be stored here
# and the monet database will be stored in the MonetDB folder within
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PISA/" )

# # # are you on a non-windows system? # # #
if ( .Platform$OS.type != 'windows' ) print( 'non-windows users: read this block' )
# acer's ftp site has a few SAS importation
# scripts in a non-standard format
# if so, before running this whole download program,
# you might need to run this line..
# options( encoding="windows-1252" )
# ..to turn on windows-style encoding.
# # # end of non-windows system edits.


# configure a monetdb database for the pisa on windows #

# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )

# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite() , dbfolder )



# choose which pisa data sets to download: 2000, 2003, 2006, 2009, or 2012
# if you have a big hard drive, hey why not download them all?

# uncomment this line to download all available data sets
# uncomment this line by removing the `#` at the front
# years.to.download <- c( 2000 , 2003 , 2006 , 2009 , 2012 )

# # # # # # # # # # # # # #
# other download examples #
# # # # # # # # # # # # # #

# uncomment this line to only download 2009
# years.to.download <- 2009

# uncomment these lines to only download 2000 and 2006
# years.to.download <- c( 2000 , 2006 )


###############################################
# DATA LOADING COMPONENT - ONLY RUN THIS ONCE #
###############################################


##########################################
# this entire script is for data-loading #
# and only needs to be run once  #
# for whichever year(s) you need #
##################################


# set the prefix of all websites for downloading
http.pre <- "http://pisa"
# set the middle portion of the website used for downloading
http.mid <- ".acer.edu.au/downloads/"



# check if 2012 is one of the years slated for download and import
if ( 2012 %in% years.to.download ){

	# figure out which table names to loop through for downloading, importing, survey designing
	files.to.import <- c( "INT_STU12_DEC03", "INT_SCQ12_DEC03" ,  "INT_PAQ12_DEC03" , "INT_COG12_DEC03" , "INT_COG12_S_DEC03" )
	
	# loop through them all
	for ( curFile in files.to.import ){

		# construct the full path to the file..
		fp <- paste0( http.pre , 2012 , http.mid , curFile , ".zip" )
	
		# ..as well as the path to the sas importation script
		sri <- paste0( http.pre , 2012 , http.mid , gsub( "DEC03" , "SAS" , curFile ) , ".sas" )

		# download the file specified at the address constructed above,
		# then immediately import it into the monetdb server
		read.SAScii.monetdb ( 
			fp ,
			sas_ri = remove.fakecnt.lines( find.chars( add.decimals( sri , precise = TRUE ) ) ) , 
			zipped = TRUE ,
			tl = TRUE ,
			tablename = curFile ,
			skip.decimal.division = TRUE ,
			connection = db
		)
	
		# missing recodes #
	
		spss.script <- paste0( http.pre , 2012 , http.mid , gsub( "DEC03" , "SPSS" , curFile ) , ".sps" )
	
		spss.based.missing.blankouts( db , curFile , spss.script )
	
		# end of missing recodes #
	
	}
	
	
	# use the table (already imported into monetdb) to spawn five different tables (one for each plausible [imputed] value)
	# then construct a multiply-imputed, monetdb-backed, replicated-weighted complex-sample survey-design object-object.
	construct.pisa.survey.designs(
		db , 
		year = 2012 ,
		table.name = 'int_stu12_dec03' ,
		pv.vars = c( 'math' , 'macc' , 'macq' , 'macs' , 'macu' , 'mape' , 'mapf' , 'mapi' , 'read' , 'scie' )
	)

}


# check if 2009 is one of the years slated for download and import
if ( 2009 %in% years.to.download ){

	# figure out which table names to loop through for downloading, importing, survey designing
	files.to.import <- c( "INT_STQ09_DEC11" , "INT_SCQ09_Dec11" , "INT_PAR09_DEC11" , "INT_COG09_TD_DEC11" , "INT_COG09_S_DEC11" )
	
	# loop through them all
	for ( curFile in files.to.import ){

		# construct the full path to the file..
		fp <- paste0( http.pre , 2009 , http.mid , curFile , ".zip" )
	
		# ..as well as the path to the sas importation script
		sri <- paste0( http.pre , 2009 , http.mid , gsub( "_D(ec|EC)" , "_SAS_DEC" , curFile ) , ".sas" )

		# download the file specified at the address constructed above,
		# then immediately import it into the monetdb server
		read.SAScii.monetdb ( 
			fp ,
			sas_ri = find.chars( add.decimals( remove.tabs( sri ) ) ) , 
			zipped = TRUE ,
			tl = TRUE ,
			tablename = curFile ,
			skip.decimal.division = TRUE ,
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

	# in this table..these columns..with these values..should be converted to NA
	missing.updates( 
		db , 
		'INT_PAR09_DEC11' , 
		split.n.clean( miss1.txt ) ,
		7:9 
	)

	# in this table..these columns..with these values..should be converted to NA
	missing.updates( 
		db , 
		'INT_PAR09_DEC11' , 
		c( "PRESUPP" , "MOTREAD" , "READRES" , "CURSUPP" , "PQSCHOOL" , "PARINVOL" ) ,
		9997:9999 
	)
	
	# note: no missing recodes for `int_cog09_s_dec11` or `int_cog09_td_dec11`
	
	# end of missing recodes #
	
	
	# use the table (already imported into monetdb) to spawn five different tables (one for each plausible [imputed] value)
	# then construct a multiply-imputed, monetdb-backed, replicated-weighted complex-sample survey-design object-object.
	construct.pisa.survey.designs(
		db , 
		year = 2009 ,
		table.name = 'int_stq09_dec11' ,
		pv.vars = c( 'math' , 'read' , 'scie' , 'read1' , 'read2' , 'read3' , 'read4' , 'read5' )
	)
	
}


# check if 2006 is one of the years slated for download and import
if ( 2006 %in% years.to.download ){

	# figure out which table names to loop through for downloading, importing, survey designing
	files.to.import <- c( "INT_Stu06_Dec07" , "INT_Sch06_Dec07" , "INT_Par06_Dec07" , "INT_Cogn06_T_Dec07" , "INT_Cogn06_S_Dec07" )

	# loop through them all
	for ( curFile in files.to.import ){

		# construct the full path to the file..
		fp <- paste0( http.pre , 2006 , http.mid , curFile , ".zip" )
	
		# ..as well as the path to the sas importation script
		sri <- paste0( http.pre , 2006 , http.mid , gsub( "_D" , "_SAS_D" , curFile ) , ".sas" )
	
		# download the file specified at the address constructed above,
		# then immediately import it into the monetdb server
		read.SAScii.monetdb ( 
			fp ,
			sas_ri = find.chars( add.decimals( remove.tabs( sri ) ) ) , 
			zipped = TRUE ,
			tl = TRUE ,
			tablename = curFile ,
			skip.decimal.division = TRUE ,
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
	
	
	# use the table (already imported into monetdb) to spawn five different tables (one for each plausible [imputed] value)
	# then construct a multiply-imputed, monetdb-backed, replicated-weighted complex-sample survey-design object-object.
	construct.pisa.survey.designs(
		db , 
		year = 2006 ,
		table.name = 'int_stu06_dec07' ,
		pv.vars = c( 'math' , 'read' , 'scie' , 'intr' , 'supp' , 'eps' , 'isi' , 'use' )
	)
	
}

  
# check if 2003 is one of the years slated for download and import
if ( 2003 %in% years.to.download ){

	# figure out which table names to loop through for downloading, importing, survey designing
	files.to.import <- c( "INT_cogn_2003" , "INT_stui_2003_v2" , "INT_schi_2003" )
	
	# loop through them all
	for ( curFile in files.to.import ){

		zipped <- TRUE
	
		# construct the full path to the file..
		fp <- paste0( http.pre , 2003 , http.mid , curFile , ".zip" )
	
		# ..as well as the path to the sas importation script
		sri <- paste0( http.pre , 2003 , http.mid , gsub( "INT" , "Read" , curFile ) , ".sas" )
		sri <- gsub( "i_2003", "I_2003", sri )
	
		# get rid of some goofy `n` values in this ascii data
		if ( curFile == "INT_cogn_2003" ){
		
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
	

		# download the file specified at the address constructed above,
		# then immediately import it into the monetdb server
		read.SAScii.monetdb ( 
			fp ,
			sas_ri = find.chars( add.decimals( remove.tabs( sri ) ) ) , 
			zipped = zipped ,
			tl = TRUE ,
			tablename = curFile ,
			skip.decimal.division = TRUE ,
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
	
	
	# use the table (already imported into monetdb) to spawn five different tables (one for each plausible [imputed] value)
	# then construct a multiply-imputed, monetdb-backed, replicated-weighted complex-sample survey-design object-object.
	construct.pisa.survey.designs(
		db , 
		year = 2003 ,
		table.name = 'int_stui_2003_v2' ,
		pv.vars = c( 'math' , 'math1' , 'math2' , 'math3' , 'math4' , 'read' , 'scie' , 'prob' )
	)

}


# check if 2000 is one of the years slated for download and import
if ( 2000 %in% years.to.download ){

	# figure out which table names to loop through for downloading, importing, survey designing
	files.to.import <- c( "intcogn_v3" , "intscho" , "intstud_math" , "intstud_read" , "intstud_scie" )

	# loop through them all
	for ( curFile in files.to.import ){

		# construct the full path to the file..
		fp <- paste0( http.pre , 2000 , http.mid , curFile , ".zip" )
	
		# ..as well as the path to the sas importation script
		sri <- paste0( http.pre , 2000 , http.mid , curFile , ".sas" )
	
		# well aren't you a pain in the ass as usual, mathematics?
		if ( curFile == "intstud_math" ) {
		
			# run some special cleanup functions to get the intstud_math sas script SAScii-compatible
			sri <- find.chars( add.decimals( add.sdt( remove.tabs( stupid.sas( sri ) ) ) ) )
			
			# this one is annoying.
			# just read it into RAM (it fits under 4GB)
			# then save to MonetDB
			ism <- read.SAScii( fp , sri , zipped = TRUE )
			
			# convert all column names to lowercase
			names( ism ) <- tolower( names( ism ) )
			
			# throw out the toss_0 column
			ism$toss_0 <- NULL
			
			# initiate a temporary file on the local disk
			tf <- tempfile()
			
			# write the `ism` data.frame object to the temporary file
			write.csv( ism , tf , row.names = FALSE )
			
			# read that csv file directly into monetdb
			monet.read.csv( db , tf , curFile , nrow.check = 20000 , na.strings = "NA" , lower.case.names = TRUE )

			# remove the `ism` object from working memory
			rm( ism )
			
			# clear up RAM
			gc()
			
			# delete the temporary file from the local disk
			file.remove( tf )
			
		} else {
	
			# clean up some of the sas import scripts
			sri <- find.chars( add.decimals( add.sdt( remove.tabs( sri ) ) ) )
			
			# woah clean up even more.
			if ( curFile %in% c( "intstud_read" , "intstud_scie" ) ) sri <- sas.is.quite.evil( sri )
			
			# download the file specified at the address constructed above,
			# then immediately import it into the monetdb server
			read.SAScii.monetdb ( 
				fp ,
				sas_ri = sri , 
				zipped = TRUE ,
				tl = TRUE ,
				tablename = curFile ,
				skip.decimal.division = TRUE ,
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
	
	# in this table..these columns..with these values..should be converted to NA
	missing.updates( db , 'intstud_math' , miss6.math , 9997 )
	
	# intstud_read
	intstud.missings( db , 'intstud_read' )
		
	miss6.read <-
		c(
			"wleread" , "wleread1" , "wleread2" , "wleread3" , "pv1read" , "pv2read" , "pv3read" , "pv4read" , "pv5read" , "pv1read1" , "pv2read1" , "pv3read1" , "pv4read1" , "pv5read1" , "pv1read2" , "pv2read2" , "pv3read2" , "pv4read2" , "pv5read2" , "pv1read3" , "pv2read3" , "pv3read3" , "pv4read3" , "pv5read3" , "wlerr_r" , "wlerr_r1" , "wlerr_r2" , "wlerr_r3"
		)
	
	# in this table..these columns..with these values..should be converted to NA
	missing.updates( db , 'intstud_read'  , miss6.read , 9997 )
	
	# intstud_scie
	intstud.missings( db , 'intstud_scie' )
	
	miss6.scie <-
		c( 
			"wleread" , "wleread1" , "wleread2" , "wleread3" , "wlescie" , "pv1read" , "pv2read" , "pv3read" , "pv4read" , "pv5read" , "pv1read1" , "pv2read1" , "pv3read1" , "pv4read1" , "pv5read1" , "pv1read2" , "pv2read2" , "pv3read2" , "pv4read2" , "pv5read2" , "pv1read3" , "pv2read3" , "pv3read3" , "pv4read3" , "pv5read3" , "pv1scie" , "pv2scie" , "pv3scie" , "pv4scie" , "pv5scie" , "wlerr_r" , "wlerr_r1" , "wlerr_r2" , "wlerr_r3" , "wlerr_s"
		)
	
	# in this table..these columns..with these values..should be converted to NA
	missing.updates( db , 'intstud_scie'  , miss6.scie , 9997 )
	
	# end of missing recodes #
	
	
	# use the table (already imported into monetdb) to spawn five different tables (one for each plausible [imputed] value)
	# then construct a multiply-imputed, monetdb-backed, replicated-weighted complex-sample survey-design object-object.
	construct.pisa.survey.designs(
		db , 
		year = 2000 ,
		table.name = 'intstud_math' ,
		pv.vars = c( 'math' , 'math1' , 'math2' , 'read' , 'read1' , 'read2' , 'read3' )
	)

	# use the table (already imported into monetdb) to spawn five different tables (one for each plausible [imputed] value)
	# then construct a multiply-imputed, monetdb-backed, replicated-weighted complex-sample survey-design object-object.	
	construct.pisa.survey.designs(
		db , 
		year = 2000 ,
		table.name = 'intstud_read' ,
		pv.vars = c( 'read' , 'read1' , 'read2' , 'read3' )
	)
	
	# use the table (already imported into monetdb) to spawn five different tables (one for each plausible [imputed] value)
	# then construct a multiply-imputed, monetdb-backed, replicated-weighted complex-sample survey-design object-object.
	construct.pisa.survey.designs(
		db , 
		year = 2000 ,
		table.name = 'intstud_scie' ,
		pv.vars = c( 'read' , 'read1' , 'read2' , 'read3' , 'scie' )
	)
	
}


# the current working directory should now contain one r data file (.rda)
# for each multiply-imputed, monet database-backed complex sample survey design object


# set every table you've just created as read-only inside the database.
for ( this_table in dbListTables( db ) ) dbSendQuery( db , paste( "ALTER TABLE" , this_table , "SET READ ONLY" ) )

# disconnect from the current monet database
dbDisconnect( db )

