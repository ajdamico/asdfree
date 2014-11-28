# analyze survey data for free (http://asdfree.com) with the r language
# pesquisa orcamentos familiares
# 2002-2003 and 2008-2009

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( encoding = "latin1" )		# # only macintosh and *nix users need this line
# library(downloader)
# setwd( "C:/My Directory/POF/" )
# years.to.download <- c( 2009 , 2003 )
# path.to.7z <- normalizePath( "C:/Program Files (x86)/7-zip/7z.exe" )		# # this is probably the correct line for windows
# path.to.7z <- "7za"													# # this is probably the correct line for macintosh and *nix
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Pesquisa%20de%20Orcamentos%20Familiares/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# http://www.screenr.com/Zpd8

# anthony joseph damico
# ajdamico@gmail.com

# if you use this script for a project, please send me a note
# it's always nice to hear about how people are using this stuff

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf


#######################################################################
# Analyze the 2008-2009 Pesquisa de Orcamentos Familiares file with R #
#######################################################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################################################
# prior to running this script, you must have the program 7-zip installed on your computer. it's a free. go to http://www.7-zip.org/download.html   #
# this code has only been tested in a microsoft windows environment, tell us what modifications are needed for other operating systems! cool thanx  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# path.to.7z <- normalizePath( "C:/Program Files (x86)/7-zip/7z.exe" )		# # this is probably the correct line for windows
# path.to.7z <- "7za"													# # this is probably the correct line for macintosh and *nix
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# the line above sets the location of the 7-zip program on your local computer. uncomment it by removing the `#` and change the directory if ya did #
#####################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# set your working directory.
# the POF microdata files will be stored here
# after downloading and importing them.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/POF/" )
# ..in order to set your current working directory


# # # are you on a non-windows system? # # #
if ( .Platform$OS.type != 'windows' ) print( 'non-windows users: read this block' )
# ibge's ftp site has a few SAS importation
# scripts in a non-standard format
# if so, before running this whole download program,
# you might need to run this line..
# options( encoding="latin1" )
# ..to turn on latin-style encoding.
# # # end of non-windows system edits.


# # # # # # # # # # # # # #
# warning: perl required! #
# # # # # # # # # # # # # #

# if you do not have perl installed, this two-minute video
# walks through how to get it (for free): http://www.screenr.com/QiN8


# remove the # in order to run this install.packages line only once
# install.packages( c( 'gdata' , "SAScii" , "downloader" ) )


# remove the `#` in order to specify which years to download
# years.to.download <- c( 2009 , 2003 )
# 2003 will download the 2002-2003 survey,
# 2009 will download the 2008-2009 survey, you get the idea.



############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #



library(SAScii) 			# load the SAScii package (imports ascii data with a SAS script)
library(gdata) 				# load the gdata package (imports excel [.xls] files into R)
library(downloader)			# downloads and then runs the source() function on scripts from github


# load the download.cache and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url( 
	"https://raw.github.com/ajdamico/usgsd/master/Download%20Cache/download%20cache.R" , 
	prompt = FALSE , 
	echo = FALSE 
)

# create two temporary files and a temporary directory..
tf <- tempfile() ; tf2 <- tempfile() ; td <- tempdir()

# # # # # # # # # # # #
# load the main file  #
# # # # # # # # # # # #

# even though there's currently only one year to download (the 2008-2009 file)
# loop through everything to make future-year automation a cinch.
for ( year in years.to.download ){


	# create a year-specific folder
	# within the current working directory
	dir.create( 
		normalizePath( paste( getwd() , year , sep = "/" ) ) , 
		showWarnings = FALSE 
	)
	

	# microdata filepath on the IBGE FTP site
	ftp.path <-
		paste0(
			"ftp://ftp.ibge.gov.br/Orcamentos_Familiares/Pesquisa_de_Orcamentos_Familiares_" ,
			year - 1 ,
			"_" ,
			year , 
			"/Microdados/"
		)

	# data file location inside the FTP directory
	data.file <- paste0( ftp.path , "Dados.zip" )

	# sas importation instructions location inside the FTP directory
	if ( year < 2009 ){
		sas.input.instructions <- paste0( ftp.path , "Documentacao.zip" )
	} else {
		sas.input.instructions <- paste0( ftp.path , "documentacao.zip" )
	}
	
	# download the household and person ascii data files to the local computer..
	download.cache( data.file , tf , mode = "wb" )

	# ..then unzip them into the temporary directory
	files <- unzip( tf , exdir = td )

	# download the sas importation instructions inside the same FTP directory..
	download.cache( sas.input.instructions , tf , mode = "wb" )

	# ..then also unzip them into the temporary directory
	files <- c( files , unzip( tf , exdir = td ) )

	
	# starting in 2009, the food codes (codigos de alimentacao) were available in an excel file
	if ( year >= 2009 ){
		alimentacao.file <- paste0( ftp.path , "tradutores.zip" )
		
		# download the alimentacao file inside the same FTP directory..
		download.cache( alimentacao.file , tf , mode = 'wb' )
		
		# ..then also unzip them into the temporary directory
		files <- c( files , unzip( tf , exdir = td ) )
	}
		
	# some lines need to be manually encoded	
	Encoding( files ) <- 'latin1'
		
	# starting in 2009, the post-stratification and food codes (codigos de alimentacao) were available in excel files
	# so save both to the local disk
	if ( year >= 2009 ){
		
		# # # # # # # # # # # # # #
		# tables with food codes  #
		
		# figure out which is the alimentacao file
		cda <- files[ grep( 'codigos_de_alimentacao' , tolower( files ) ) ]
	
		# extract both tabs from the excel file
		componentes <- read.xls( cda , sheet = 1 , skip = 1 , colClasses = 'character' )
		estrutura <- read.xls( cda , sheet = 2 , skip = 1  , colClasses = 'character' )
				
		# reset the column names to be easily-readable
		names( componentes ) <-
			c( 'codigo' , 'nivel.1' , 'desc.1' , 'nivel.2' , 'desc.2' , 'nivel.3' , 'desc.3' )
		
		# the `estrutura` table should have the same column names,
		# except the first from `componentes`
		names( estrutura ) <-
			names( componentes )[ -1 ]
		
		
		# componentes table has a footnote, so throw it out
		# by removing all records with a missing
		# or empty `nivel.1` field
		componentes <- componentes[ !is.na( componentes$nivel.1 ) , ]
		componentes <- componentes[ componentes$nivel.1 != "" , ]
		
		
		# save both of these data frames to the local disk
		save( 
			componentes , estrutura , 
			file = paste0( './' , year , "/codigos de alimentacao.rda" ) 
		)
		
		# # # # # # # # # # # # # # # # #
		# table for post-stratification #
		
		# figure out which is the post-stratification table
		pos <- files[ grep( 'pos_estratos_totais' , tolower( files ) ) ]
	
		# extract the post-stratification table
		# from the excel file
		poststr <- read.xls( pos , sheet = 1 )
		# imported!  cool?  cool.
		
		# convert all column names to lowercase
		names( poststr ) <- tolower( names( poststr ) )
		
		# save this data frame to the local disk
		save( 
			poststr ,
			file = paste0( './' , year , "/poststr.rda" ) 
		)
		
		# remove all three of these tables from memory
		rm( componentes , estrutura , poststr )
		
		# clear up RAM
		gc()
	}
		
		
	
	
	# # # # # # # # # # # # # #
	# sas import organization #
	
	# before you worry about the data files,
	# get the sas import scripts under control.
	
	# extract the leitura file containing the sas importation instructions
	leitura <- files[ grep( 'leitura' , tolower( files ) ) ]

	# read the whole thing into memory
	z <- readLines( leitura )

	# remove all those goofy tab characters (which will screw up SAScii)
	z <- gsub( "\t" , " " , z )

	# remove lines containing the `if reg=__ then do;` pattern
	z <- z[ !grepl( 'if reg=.* then do;' , z ) ]
	
	# remove goofy @;
	z <- gsub( "@;" , "" , z )
	
	# remove lines containing solely `input`
	z <- z[ !( tolower( z ) == 'input' ) ]
	
	# remove the (SAScii-breaking) overlapping `controle` columns
	z <- z[ !grepl( "@3 controle 6." , z , fixed = TRUE ) ]
	
	# write the file back to your second temporary file
	writeLines( z , tf2 )

	# find each of your beginline parameters

	# find each line containing the string `INFILE` or `infile`
	all.beginlines <- grep( 'INFILE|infile' , z )
	
	# find line start positions
	start.pos <-
		unlist( 
			lapply(
				gregexpr( 
					"\\" , 
					z[ all.beginlines ] ,
					fixed = TRUE
				) ,
				max 
			) 
		) + 1
		
	# find line end positions
	end.pos <-
		unlist( 
				gregexpr( 
					".txt" , 
					z[ all.beginlines ] 
				) 
			) - 1 
		
	# isolate the names of all data files to be imported..
	data.files.to.import <-
		# pull the 14th character until `.txt` in the `INFILE` lines of the sas import script
		substr( 
			z[ all.beginlines ] , 
			start.pos , 
			end.pos
		)
	
	# now you've got an object containing the names of all data files that need to be imported.
	data.files.to.import
	
	# isolate the base filename before the period
	# for all downloaded files..
	all.file.basenames <-
		unlist( 
			lapply( 
				strsplit( 
					basename( files ) , 
					'.' , 
					fixed = TRUE 
				) , 
				'[[' , 
				1 
			) 
		)
	
	# for each data file name in `data.files.to.import`..
	for ( dfn in data.files.to.import ){

		# identify which .7z file contains the data	
		if ( tolower( dfn ) == 't_rendimentos' ) {
			data.file <- files[ which( 't_rendimentos1' == tolower( all.file.basenames ) ) ] 
		} else {
			data.file <- files[ which( tolower( dfn ) == tolower( all.file.basenames ) ) ]
		}
	
	
		# if `data.file` contains multiple files..
		if ( length( data.file ) > 1 ){
		
			# pick the zipped file..
			data.file <- data.file[ grep( '.zip' , tolower( data.file ) , fixed = TRUE ) ]
			
			# ..unzip it, and overwrite `data.file` with the new filepath
			data.file <- unzip( data.file , exdir = td )
		}
		
	
		# and now, if the data.file is just a text file..
		if ( grepl( "txt$" , tolower( data.file ) ) ){

			# then no unzipping is necessary
			curfile <- data.file
			
		# otherwise, the file must be unzipped with 7-zip
		} else {
		
			# build the string to send to DOS
			dos.command <- paste0( '"' , path.to.7z , '" x ' , data.file )

			# extract the file, platform-specific
			if ( .Platform$OS.type != 'windows' ) system( dos.command ) else shell( dos.command )

			# find the name of the final ASCII data file to be imported
			curfile <- gsub( ".7z" , ".txt" , basename( data.file ) )

		}
		
		# figure out which beginline position to use
		cur.beginline <- which( tolower( dfn ) == tolower( data.files.to.import ) )
		
		# import the data file into R
		x <- 
			read.SAScii( 
				curfile , 
				tf2 , 
				beginline = all.beginlines[ cur.beginline ] ,
				skip.decimal.division = TRUE
			)
		
		# convert all column names to lowercase
		names( x ) <- tolower( names( x ) )
		
		# rename the data table appropriately
		assign( tolower( dfn ) , x )
		
		# save the current data.frame
		# to the appropriate year folder
		# within the current working directory
		save( 
			list = tolower( dfn ) , 
			file = tolower( paste0( './' , year , "/" , dfn , ".rda" ) )
		)

	
		# remove both the `x` object and the newly-named object from memory
		rm( list = c( 'x' , 'dfn' ) )
		
		# clear up RAM
		gc()
		
		# delete the current file from the current working directory
		file.remove( curfile )
				
	}
	
	# revert the encoding for more effective deletion.
	Encoding( files ) <- ''
	
	# remove the temporary files from the local disk
	file.remove( tf , tf2 , files )
	
}

# print a reminder: set the directory you just saved everything to as read-only!
message( paste0( "all done.  you should set " , getwd() , " read-only so you don't accidentally alter these files." ) )


# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/

# dear everyone: please contribute your script.
# have you written syntax that precisely matches an official publication?
message( "if others might benefit, send your code to ajdamico@gmail.com" )
# http://asdfree.com needs more user contributions

# let's play the which one of these things doesn't belong game:
# "only you can prevent forest fires" -smokey bear
# "take a bite out of crime" -mcgruff the crime pooch
# "plz gimme your statistical programming" -anthony damico
