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


require(MonetDB.R)	# load the MonetDB.R package (connects r to a monet database)




######################################################################
# lines of code to hold on to for all other `test` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
batfile <- "C:/My Directory/MonetDB/test.bat"

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "test"
dbport <- 50000

drv <- dbDriver("MonetDB")
monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( drv , monet.url , "monetdb" , "monetdb" )

# # # # run your analysis commands # # # #



# my shell window contains the text below.  leave it open until you're done.

# when the monetdb server runs, my computer shows:
# MonetDB 5 server v11.15.1 "Feb2013"
# Serving database 'bsapuf', using 8 threads
# Compiled for x86_64-pc-winnt/64bit with 64bit OIDs dynamically linked
# Found 7.860 GiB available main-memory.
# Copyright (c) 1993-July 2008 CWI.
# Copyright (c) August 2008-2013 MonetDB B.V., all rights reserved
# Visit http://www.monetdb.org/ for further information
# Listening for connection requests on mapi:monetdb://127.0.0.1:50003/
# MonetDB/JAQL module loaded
# MonetDB/SQL module loaded


# go back to the r console and run some database commands


# see all tables currently stored in the database
# note: if this is a newly-constructed database, you are looking at meta-data
dbListTables( db )

# print the example mtcars data table to the screen
mtcars

# write the mtcars data table to your new database as a table called x
dbWriteTable( db , 'x' , mtcars )

# look at the available tables again - a table 'x' should exist
dbListTables( db )

# look at the fields of the mtcars table (called x) in the monet database
dbListFields( db , 'x' )


# note to self: revise this block to fit the structure of a haiku -

# yes.  of course it's silly to use monetdb 
# on tables small enough to load into ram
# that's not the point of this exercise, though.
# this code shows you how everything works, so
# you feel comfortable working with your own big data


##########################################
# make a new column in the monetdb table #

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


########################################################
# make a new categorical variable in the monetdb table #


# example of a linear recode with multiple categories, and a loop to perform each recode quickly

original.variable.name <- 'wt'			# variable to recode from	

cutpoints <- 
	c( 0 , 2.5 , 3.3 , 3.6 , 10 )		# points to split the variable
										# note that the lowest and highest bound should also be defined,
										# anything outside of those numbers will be NA
										# also: monetdb does not understand the value "Inf" or "-Inf"
										# so just use an impossibly large or small number at the ends of your range

new.variable.name <- 'wtcat'			# new variable to create


# step one: add the column

( first.command <- paste( "ALTER TABLE x ADD" , new.variable.name , "double" ) )
dbSendUpdate( db , first.command )
	

# step two: loop through each cutpoint (except the last)
for ( i in seq( length( cutpoints ) - 1 ) ){

	# if you're working with a large data table, these commands may be slow
	# so print a counter to the screen
	cat( 
		'     currently creating category' , 
		i , 
		'of' , 
		new.variable.name , 
		'from' , 
		original.variable.name , 
		'with' , 
		length( cutpoints ) - 1 , 
		'distinct categories' , 
		'\r'
	)

	
	# step three: create the specific category (still just a character string)
	
	second.command <- 
		paste( 
			"UPDATE x SET" , 
			new.variable.name , 
			"=" , 
			i , 
			"WHERE" , 
			original.variable.name , 
			">=" , 							# depending on how you want the interval open and closed, you might want this line changed to
											# ">" and..
			cutpoints[ i ] , 				
			"AND" ,
			original.variable.name ,
			"<" ,							# ..this line changed to "<="
			cutpoints[ i + 1 ]
		) 

	# print each second.command to the screen, so you can confirm if each recode has been defined appropriately
	print( second.command )
	
	# step four: send the character string command to the database
	
	dbSendUpdate( db , second.command )		# recode wt >= cutpoints[ i ] AND wt < cutpoints[ i + 1 ] to wtcat = i

}

# look at all thirty two records for those two columns to confirm recodes have worked properly
dbGetQuery( db , "select wt , wtcat from x" )

# end of changes to the monetdb table #
#######################################


########################
# run some sql queries #

# look at the first six records of x
dbGetQuery( db , 'select * from x limit 6' )

# look at only cars with four gears in x
dbGetQuery( db , 'select * from x where gear = 4' )

# calculate the mean, median, max, min, and standard deviation of the
# kilometers per liter for each cylinder category.
# also count the number of cars available in each category
dbGetQuery( db , 'select cyl, avg( kpl ) , median( kpl ) , max( kpl ) , min( kpl ) , stddev_pop( kpl ) , count(*) from x group by cyl' )

# in sum: use dbGetQuery() to examine a table within a database

# if you've never used sql before, you are so missing out
# check out w3schools for an intro: http://www.w3schools.com/sql/default.asp

# run some sql queries #
########################


# pull the monetdb table x back into memory
# note: if your table is too large for your ram,
# this will overload your computer.
# at least save your work before you try it,
# just in case it requires you to restart r.
x <- dbReadTable( db , 'x' )


# here's the same first six records of x
head( x )


# when you're finished, close the database connection..
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other `test` monetdb analyses #
#############################################################################

# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
