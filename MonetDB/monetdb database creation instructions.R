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

