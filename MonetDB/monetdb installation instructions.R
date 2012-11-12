# # # # # # # # # # # # # # #
# warning: monetdb required #
# # # # # # # # # # # # # # #


# some usgsd scripts use a superfast (completely free) database program called monetdb.
# here's how to install and configure it to work with r on windows in four steps:


# 1) install java (not just for your browser)
# type 'java download' into google and click the first link
# download and install java


# 2) install monetdb (an ultra-fast sql engine)
# go to http://www.monetdb.org/
# click 'download now'
# choose your operating system
# download "MonetDB SQL server and client, 64 bit" and run it.
# by default, monetdb will install to: C:\Program Files\MonetDB\MonetDB5\
# that's cool, just don't forget that path.  you'll need it later.
# jot down the filepath where you installed this (with slashes doubled):
# "c:\\program files\\monetdb\\monetdb5\\"


# 3) download the latest monetdb java driver
# go to http://dev.monetdb.org/downloads/Java/Latest/
# save the 'monetdb-jdbc-#.#.jar' file to your local disk..
# ..you can put it anywhere, but for convenience i recommend saving it in
# C:\Program Files\MonetDB\MonetDB5\
# be sure to change the number signs below to actual numbers and..
# ..remember the filepath where you saved this (with slashes reversed):
# "c:/program files/monetdb/monetdb5/monetdb-jdbc-#.#.jar"


# 4) install two R packages that are not currently available on CRAN and install a few others..
# open up your R console and run these two separate installation commands without the # sign in front:
# install.packages( c( "RMonetDB" , "sqlsurvey" ) , repos = c( "http://cran.r-project.org" , "http://R-Forge.R-project.org" ) , dep=TRUE )
# install.packages( c( 'SAScii' , 'descr' , 'survey' , 'RCurl' ) )



# # # # # # # # # # # #
# end of installation #
# # # # # # # # # # # #



# if you've successfully installed monetdb to your machine,
# you should be able to initiate your first database with these commands:


require(RMonetDB)	# load the RMonetDB package (connects r to a monet database)


#######################################################	
# function to download scripts directly from github.com
# http://tonybreyal.wordpress.com/2011/11/24/source_https-sourcing-an-r-script-from-github/
source_https <- function(url, ...) {
  # load package
  require(RCurl)

  # parse and evaluate each .R script
  sapply(c(url, ...), function(u) {
    eval(parse(text = getURL(u, followlocation = TRUE, cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl"))), envir = .GlobalEnv)
  })
}
#######################################################

# load the windows.monetdb.configuration() function,
# which allows the easy creation of an executable (.bat) file
# to run the monetdb server specific to this data
source_https( "https://raw.github.com/ajdamico/usgsd/master/MonetDB/windows.monetdb.configuration.R" )


# run the windows.monetdb.configuration() function to
# write the .bat file to the disk
# this .bat file only needs to be created once
# do not re-create the .bat file after you've initalized the database
windows.monetdb.configuration( 

		# choose a path on the local drive to store the .bat file
		# that will be used to run the monetdb server
		# note: do *not* put this file in the database.directory
		
		bat.file.location = "C:\\My Directory\\MonetDB\\test.bat" , 
		
		
		# find the main path to the monetdb installation program
		# the windows installer defaults here:
		# (but you might have changed the path)
		
		monetdb.program.path = "C:\\Program Files\\MonetDB\\MonetDB5\\" ,
		
		
		# set the path to the directory where the data will be stored
		
		database.directory = "C:\\My Directory\\MonetDB\\test\\" ,
		
		
		# choose a database name
		
		dbname = "test" ,
		
		
		# choose a database port
		# this port should not conflict with other monetdb databases
		# on your local computer.  two databases with the same port number
		# cannot be accessed at the same time
		
		dbport = 50000
		
	)
	
# now the local windows machine contains a new program at "c:\my directory\monetdb\test\test.bat"


# in the future, execute the .bat file to launch the monetdb server
# this will run a dos prompt window that needs to be left open
# until you have finished all monetdb-related commands

shell.exec( "C:\\My Directory\\MonetDB\\test.bat" )

# you'll also need the dbname and dbport settings you've used above
dbname <- "test"
dbport <- 50000


# my dos window contains the text below.  leave it open until you're done.

# MonetDB 5 server v11.11.11 "Jul2012-SP2"
# Serving database 'test', using 2 threads
# Compiled for x86_64-pc-winnt/64bit with 64bit OIDs dynamically linked
# Found 15.873 GiB available main-memory.
# Copyright (c) 1993-July 2008 CWI.
# Copyright (c) August 2008-2012 MonetDB B.V., all rights reserved
# Visit http://www.monetdb.org/ for further information
# Listening for connection requests on mapi:monetdb://127.0.0.1:50000/
# MonetDB/SQL module loaded
