

stop( "these instructions are obsolete.  instead, use https://github.com/hannesmuehleisen/MonetDBLite/blob/master/README.md" )


# # # # # # # # # # # # # # #
# warning: monetdb required #
# # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
###########################################################################################################################################
# prior to running this database creation script, monetdb must be installed on the local machine. follow each step outlined on this page: #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/asdfree/blob/master/MonetDB/monetdb%20installation%20instructions.R                                           #
###########################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# if you've successfully installed monetdb to your machine,
# you should be able to initiate your first database with these commands:

library(DBI)			# load the DBI package (implements the R-database coding)
library(MonetDB.R)	# load the MonetDB.R package (connects r to a monet database)


# set your working directory
# setwd( "C:/My Directory/" )


# configure a test monetdb database on windows #

# note: only run this command once.  this creates an executable (.bat) file
# in the appropriate directory on your local disk.
# when adding new files or adding a new year of data, this script does not need to be re-run.

# create a monetdb executable (.bat) file for the medicare basic stand alone public use file
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
					dbname = "test" ,
					
					# choose a database port
					# this port should not conflict with other monetdb databases
					# on your local computer.  two databases with the same port number
					# cannot be accessed at the same time
					dbport = 50000
	)

	
# this next step is so very important.

# store a line of code that will make it easy to open up the monetdb server in the future.
# this should contain the same file path as the batfile created above,
# you're best bet is to actually look at your local disk to find the full filepath of the executable (.bat) file.
# if you ran this script without changes, the batfile will get stored in C:\My Directory\BSAPUF\MonetDB\bsapuf.bat

# here's the batfile location:
batfile

# note that since you only run the `monetdb.server.setup()` function the first time this script is run,
# you will need to note the location of the batfile for future MonetDB analyses!

# in future R sessions, you can create the batfile variable with a line like..
# batfile <- "C:/My Directory/MonetDB/test.bat"		# # note for mac and *nix users: `test.bat` might be `test.sh` instead
# obviously, without the `#` comment character

# hold on to that line for future scripts.
# you need to run this line *every time* you access
# the files in this `test` database with monetdb.
# this is the monetdb server.

# two other things you need: the database name and the database port.
# store them now for later in this script, but hold on to them for other scripts as well
dbname <- "test"
dbport <- 50000

# now the local windows machine contains a new executable program at "c:\my directory\monetdb\test.bat"



# it's recommended that after you've _created_ the monetdb server,
# you create a block of code like the one below to _access_ the monetdb server


######################################################################
# lines of code to hold on to for all other `test` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
batfile <- "C:/My Directory/MonetDB/test.bat"		# # note for mac and *nix users: `test.bat` might be `test.sh` instead

# second: run the MonetDB server
monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "test"
dbport <- 50000

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

# fourth: store the process id
pid <- as.integer( dbGetQuery( db , "SELECT value FROM env() WHERE name = 'monet_pid'" )[[1]] )


# # # # run your analysis commands # # # #


# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other `test` monetdb analyses #
#############################################################################



# to access (read/write/analyze tables in) your new database,
# open up a fresh instance of r and follow the instructions at:

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/asdfree/blob/master/MonetDB/monetdb%20database%20accessing%20instructions.R #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

