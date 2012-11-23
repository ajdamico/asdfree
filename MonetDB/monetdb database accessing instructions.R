# # # # # # # # # # # # # # # # # # # # # # # #
# warning: specific monetdb database required #
# # # # # # # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#################################################################################################################################
# prior to running this analysis script, a monetdb database should already be created.  follow each step outlined on this page: #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/usgsd/blob/master/MonetDB/monetdb%20database%20creation%20instructions.R                          #
#################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


require(RMonetDB)	# load the RMonetDB package (connects r to a monet database)


##################################################################################
# lines of code to keep handy for all analyses using the 'test' monetdb database #

# first: your shell.exec() function.  again, mine looks like this:
shell.exec( "C:/My Directory/MonetDB/test.bat" )

# second: add a ten second system sleep in between the shell.exec() function
# and the database connection lines.  this gives your local computer a chance
# to get monetdb up and running.
Sys.sleep( 10 )

# third: your six lines to make a monet database connection.
# mine look like this:
dbname <- "test"
dbport <- 50000
monetdriver <- "c:/program files/monetdb/monetdb5/monetdb-jdbc-2.7.jar"
drv <- MonetDB( classPath = monetdriver )
monet.url <- paste0( "jdbc:monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( drv , monet.url , user = "monetdb" , password = "monetdb" )

# end of lines of code to hold on to for all analyses using the 'test' monetdb database #
#########################################################################################


# my dos window contains the text below.  leave it open until you're done.

# MonetDB 5 server v11.13.5 "Oct2012-SP1"
# Serving database 'test', using 8 threads
# Compiled for x86_64-pc-winnt/64bit with 64bit OIDs dynamically linked
# Found 7.860 GiB available main-memory.
# Copyright (c) 1993-July 2008 CWI.
# Copyright (c) August 2008-2012 MonetDB B.V., all rights reserved
# Visit http://www.monetdb.org/ for further information
# Listening for connection requests on mapi:monetdb://127.0.0.1:50000/
# MonetDB/JAQL module loaded
# MonetDB/SQL module loaded


# go back to the r console and run some database commands


# see all tables currently stored in the database
# note: if this is a newly-constructed database, these are meta-data
dbListTables( db )

# print the example mtcars data table to the screen
mtcars

# write the mtcars data table to your new database as a table called x
dbWriteTable( db , 'x' , mtcars )

# look at the available tables again
dbListTables( db )

# look at the fields of the mtcars table (called x) in the monet database
dbListFields( db , 'x' )


##########################################
# make some changes to the monetdb table #

# create a kilometers per liter column
dbSendUpdate( db , 'alter table x add column kpl double' )
# note: the above command just adds an empty column.
# the following command actually fills it with data
dbSendUpdate( db , 'update x set kpl = mpg * 0.425144' )
# one kilometer per liter equals ~0.4 miles per gallon

# in sum: use dbSendUpdate() to make changes
# to a table within a database

# end of changes to the monetdb table #
#######################################

########################
# run some sql queries #

# look at the first six records of x
dbGetQuery( db , 'select * from x limit 6' )

# look at all four gear cars in x
dbGetQuery( db , 'select * from x where gear = 4' )

# calculate the mean, median, max, min, and standard deviation of the
# kilometers per liter for each cylinder category.
# also count the number of cars available in each category
dbGetQuery( db , 'select cyl, avg( kpl ) , median( kpl ) , max( kpl ) , min( kpl ) , stddev( kpl ) , count(*) from x group by cyl' )

# in sum: use dbGetQuery() to examine
# a table within a database

# if you've never used sql before, you are so missing out
# check out w3schools for an intro: http://www.w3schools.com/sql/default.asp

# run some sql queries #
########################


# pull the monetdb table x back into memory
# note: if your table is too large for your ram,
# this will overload your computer.
# at least save your work before you try it,
# just in case it requires you to restart.
x <- dbReadTable( db , 'x' )


# here's the same first six records of x
head( x )


# when you're finished, close the database connection..
dbDisconnect( db )
# ..and close the dos shell window by hand


# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
