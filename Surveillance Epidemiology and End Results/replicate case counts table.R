# analyze us government survey data with the r language
# surveillance epidemiology and end results
# 1973 through 2010

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


###################################################
# replicate nci-seer case counts pdf with monetdb #
###################################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#########################################################################################################################################################
# prior to running this replication script, the seer text files must be loaded into monetdb and stacked into a table called `x` in that database.       #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/usgsd/master/Surveillance%20Epidemiology%20and%20End%20Results/import%20individual-level%20tables%20into%20monetdb.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a 'MonetDB' directory in C:/My Directory/SEER (or wherever the current working directory had been set) that will be accessed. #
#########################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


require(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)


###########################################################################################
# lines of code that you should have held onto from the previous script (mentioned above) #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/SEER/MonetDB/seer.bat"

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "seer"
dbport <- 50008

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url )

# # # # # # # # # # # # #
# analysis start point  #

# look at all available tables in monetdb
dbListTables( db )


# look at all available columns in the `x` table in monetdb
dbListFields( db , 'x' )
# dbListFields is just like the names() function, but for database-stored tables


# precisely match the record counts table available on the nci-seer website
# http://seer.cancer.gov/manuals/TextData.cd1973-2010counts.pdf
dbGetQuery( db , 'select tablename , count(*) from x group by tablename' )

# note that 
# 'select tablename , count(*) from x group by tablename'
# in the above `dbGetQuery` function is just a sql command.
# if you don't know sql, you should beeline to the nearest sql tutorial website
# and get learnin' because it's terribly powerful and blazingly fast
# w3schools has a good intro.  http://www.w3schools.com/sql/default.asp


# instead of printing results to the screen, you might want to
# store everything into a new `counts.by.table` object..
counts.by.table <- dbGetQuery( db , 'select tablename , count(*) from x group by tablename' )
# ..which is a data.frame object
class( counts.by.table )


# that you can print..
counts.by.table

# or save as an r object
# save( counts.by.table , file = "C:/My Directory/counts by table.rda" )

# or export to a comma separated value (.csv) file
# write.csv( counts.by.table , file = "C:/My Directory/counts by table.csv" )

# ..or really do just about whatever you like with.  hey, it's just another table
# maybe check out http://twotorials.com/ to see what other
# exciting things you can do with data.frame objects in the r language


# analysis end point  #
# # # # # # # # # # # #

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of monetdb analyses #
###########################


# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
