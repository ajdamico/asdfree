library(R.utils)


library(sqlsurvey)		# load sqlsurvey package (analyzes large complex design surveys)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(foreign) 		# load foreign package (converts data files into R)
library(downloader)		# downloads and then runs the source() function on scripts from github
source_url( "https://raw.github.com/ajdamico/asdfree/master/IPUMS%20International/ipumsi%20functions.R" , prompt = FALSE , echo = TRUE )



# download the specified ipums extract to the local disk,
# then decompress it into the current working directory
csv_file_structure <- download_ipumsi( this_extract , username , password )
csv_file_location <- gsub( "\\.gz" , "" , basename( this_extract ) )
# note: use the `download_ipumsi` file= parameter in order to
# store the download resultant csv file elsewhere


# create a monetdb executable (.bat) file for the ipums international
batfile <-
	monetdb.server.setup(
					
					# set the path to the directory where the initialization batch file and all data will be stored
					database.directory = paste0( getwd() , "/MonetDB" ) ,
					# must be empty or not exist

					# find the main path to the monetdb installation program
					monetdb.program.path = 
						ifelse( 
							.Platform$OS.type == "windows" , 
							"C:/Program Files/MonetDB/MonetDB5" , 
							"" 
						) ,
					# note: for windows, monetdb usually gets stored in the program files directory
					# for other operating systems, it's usually part of the PATH and therefore can simply be left blank.
										
					# choose a database name
					dbname = "ipumsi" ,
					
					# choose a database port
					# this port should not conflict with other monetdb databases
					# on your local computer.  two databases with the same port number
					# cannot be accessed at the same time
					dbport = 50015
	)


# this next step is so very important.

# store a line of code that will make it easy to open up the monetdb server in the future.
# this should contain the same file path as the batfile created above,
# you're best bet is to actually look at your local disk to find the full filepath of the executable (.bat) file.
# if you ran this script without changes, the batfile will get stored in C:\My Directory\IPUMSI\MonetDB\ipumsi.bat

# here's the batfile location:
batfile

# note that since you only run the `monetdb.server.setup()` function the first time this script is run,
# you will need to note the location of the batfile for future MonetDB analyses!

# in future R sessions, you can create the batfile variable with a line like..
# batfile <- "C:/My Directory/IPUMSI/MonetDB/ipumsi.bat"		# # note for mac and *nix users: `ipumsi.bat` might be `ipumsi.sh` instead
# obviously, without the `#` comment character

# hold on to that line for future scripts.
# you need to run this line *every time* you access
# the ipums international files with monetdb.
# this is the monetdb server.

# two other things you need: the database name and the database port.
# store them now for later in this script, but hold on to them for other scripts as well
dbname <- "ipumsi"
dbport <- 50015

# now the local windows machine contains a new executable program at "c:\my directory\ipumsi\monetdb\ipumsi.bat"




# it's recommended that after you've _created_ the monetdb server,
# you create a block of code like the one below to _access_ the monetdb server


#######################################################################
# lines of code to hold on to for all other `ipumsi` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/IPUMSI/MonetDB/ipumsi.bat"		# # note for mac and *nix users: `ipumsi.bat` might be `ipumsi.sh` instead

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "ipumsi"
dbport <- 50015

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )


# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other `ipumsi` monetdb analyses #
##############################################################################



pid <- monetdb.server.start( batfile )

db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )


tablename <- 'this_extract'

colTypes <- ifelse( stru == 'numeric' , 'DOUBLE' , 'VARCHAR(255)' )
cn <- toupper( names( read.csv( csv_file_location , nrow = 1 ) ) )
cn[ cn %in% c( "SERIAL" , "SAMPLE" , .SQL92Keywords ) ] <- paste0( cn[ cn %in% c( "SERIAL" , "SAMPLE" , .SQL92Keywords ) ] , "_" )
colDecl <- paste( tolower( cn ) , colTypes )
sql <- sprintf( paste( "CREATE TABLE" , tablename , "(%s)" ) ,	paste( colDecl , collapse = ", " ) )

dbSendQuery( db , sql )

dbSendQuery( 
	db , 
	paste0(
		"COPY OFFSET 2 INTO this_extract FROM '" ,
		normalizePath( csv_file_location ) ,
		"' USING DELIMITERS ',','\\n','\"' NULL AS '' BEST EFFORT" 
	)
)

csv_lines <- countLines( csv_file_location )

dbtable_lines <- dbGetQuery( db , 'SELECT COUNT(*) FROM this_extract' )[ 1 , 1 ]

stopifnot( csv_lines == dbtable_lines + 1 )

dbDisconnect( db )

monetdb.server.stop( pid )

pid <- monetdb.server.start( batfile )

db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )
