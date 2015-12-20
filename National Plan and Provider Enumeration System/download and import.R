# analyze survey data for free (http://asdfree.com) with the r language
# national plan and provider enumeration system files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# path.to.7z <- "7za"							# # only macintosh and *nix users need this line
# library(downloader)
# setwd( "C:/My Directory/NPPES/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Plan%20and%20Provider%20Enumeration%20System/download%20and%20import.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


##########################################################################
# download the most current national provider identifier database with R #
##########################################################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################################################
# macintosh and *nix users need 7za installed:  http://superuser.com/questions/548349/how-can-i-install-7zip-so-i-can-run-it-from-terminal-on-os-x  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# path.to.7z <- "7za"														# # this is probably the correct line for macintosh and *nix
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# the line above sets the location of the 7-zip program on your local computer. uncomment it by removing the `#` and change the directory if ya did #
#####################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# remove the # in order to run this install.packages line only once
# install.packages( c( "MonetDB.R" , "MonetDBLite" , "R.utils" , "descr" , "downloader" , "digest" , "stringr" ) , repos = c( "http://dev.monetdb.org/Assets/R/" , "http://cran.rstudio.com/" ) )


library(R.utils)		# load the R.utils package (counts the number of lines in a file quickly)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(MonetDBLite)	# load MonetDBLite package (creates database files in R)
library(downloader)		# downloads and then runs the source() function on scripts from github


# load the download_cached and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url( 
	"https://raw.githubusercontent.com/ajdamico/asdfree/master/Download%20Cache/download%20cache.R" , 
	prompt = FALSE , 
	echo = FALSE 
)



# the MonetDB directory will be created within
# the current working directory
# so if you would like the NPI database stored in 
# C:\My Directory\NPPES\
# set this directory to C:/My Directory/NPPES/
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NPPES/" )


# no need to edit anything below this line #


# # # # # # # # #
# program start #
# # # # # # # # #


# the latest npi data file will be stored
# in a temporary file on the local disk

# create two temporary files and a temporary directory
# on the local disk
tf <- tempfile() ; tf2 <- tempfile() ; td <- tempdir()

# read in the whole NPI files page
npi.datapage <- readLines( "http://download.cms.gov/nppes/NPI_Files.html" )

# find the first line containing the data dissemination link
npi.dataline <- npi.datapage[ grep( "NPPES_Data_Dissemination_" , npi.datapage ) ][1]

# pull out the zipped file's name from that line
fn <- 
	paste0(
		"http://download.cms.gov/nppes/" ,
		gsub(
			"(.*)(NPPES_Data_Dissemination_.*\\.zip)(.*)$" , 
			"\\2" , 
			npi.dataline
		)
	)

# download the file to the temporary file on the local disk
download_cached( fn , tf , mode = 'wb' )

# after downloading the file successfully,
# unzip the temporary file to the temporary folder..

# extract the file, platform-specific
if ( .Platform$OS.type == 'windows' ){

	z <- unzip( tf , exdir = td )

} else {

	# build the string to send to the terminal on non-windows systems
	dos.command <- paste0( '"' , path.to.7z , '" x ' , tf , ' -o"' , tempdir() , '"' )

	system( dos.command )

	z <- list.files( tempdir() , full.names = TRUE )

}


# ..and identify the appropriate 
# comma separated value (csv) file
# within the `.zip` file
csv.file <- z[ grepl( 'csv' , z ) & !grepl( 'FileHeader' , z ) ]



# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )

# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite() , dbfolder )
# from now on, the 'db' object will be used for r to connect with the monetdb server


# note: slow. slow. slow. #
# the following commands take a while. #
# run them all together overnight if possible. #
# you'll never have to do this again.  hooray! #


# determine the number of lines
# that need to be imported into MonetDB
num.lines <- countLines( csv.file )

# read the first thousand records
# of the csv.file into R
col.check <- read.csv( csv.file , nrow = 1000 )

# determine the field names
fields <- names( col.check )

# convert the field names to lowercase
fields <- tolower( fields )

# remove all `.` characters from field names
fields <- gsub( "." , "_" , fields , fixed = TRUE )

# fields containing the word `code`
# and none of country, state, gender, taxonomy, or postal
# should be numeric types.
# all others should be character types.
colTypes <- 
	ifelse( 
		grepl( "code" , fields ) & !grepl( "country|state|gender|taxonomy|postal" , fields ) , 
		'DOUBLE PRECISION' , 
		'VARCHAR(255)' 
	)

# build a sql string..
colDecl <- paste( fields , colTypes )

# ..to initiate this table in the monet database
sql.create <-
	sprintf(
		paste(
			"CREATE TABLE npi (%s)"
		) ,
		paste(
			colDecl ,
			collapse = ", "
		)
	)

# run the actual MonetDB table creation command
dbSendQuery( db , sql.create )


# create a read-only input connection..
incon <- file( csv.file , "r" )

# ..and a write-only output connection
outcon <- file( tf2 , "w" )

# loop through every line in the input connection,
# 50,000 lines at a time
while( length( z <- readLines( incon , n = 50000 ) ) > 0 ){

	# replace all double-backslahses with nothing..
	z <- gsub( "\\\\" , "" , z )
	
	# ..and write the resultant lines
	# to the output file connection
	writeLines( z , outcon )

	# remove the `z` object
	rm( z )
	
	# clear up RAM
	gc()
}

# shut down both file connections
close( incon )
close( outcon )

# confirm that the new temporary file
# contains the same number of records as
# the original csv.file
stopifnot( countLines( tf2 ) == countLines( csv.file ) )

# build a sql COPY INTO command
# that will import the newly-created `tf2`
# into the monet database
sql.update <- 
	paste0( 
		"copy " , 
		num.lines , 
		" offset 2 records into npi from '" , 
		normalizePath( tf2 ) , 
		"' using delimiters ',','\\n','\"' NULL as ''" 
	)

# execute the COPY INTO command
dbSendQuery( db , sql.update )

# # # # # # # # #
# end of import #
# # # # # # # # #


# set every table you've just created as read-only inside the database.
for ( this_table in dbListTables( db ) ) dbSendQuery( db , paste( "ALTER TABLE" , this_table , "SET READ ONLY" ) )


# disconnect from the current monet database
dbDisconnect( db )


# once complete, this script does not need to be run again for this data.
# instead, use the example monetdb analysis scripts


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
