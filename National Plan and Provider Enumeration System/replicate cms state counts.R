# analyze us government survey data with the r language
# national plan and provider enumeration system files

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


# this r script will replicate the counts table provided by
# the centers for medicare and medicaid services (cms)


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###################################################################################################################################
# prior to running this analysis script, the national plan and provider enumeration system must be imported into a monet database #
# on the local machine. you must run this:                                                                                        #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/usgsd/master/National%20Plan%20and%20Provider%20Enumeration%20System/download%20and%20import.R  #                                        #
###################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # #
# warning: monetdb required #
# # # # # # # # # # # # # # #


require(MonetDB.R)	# load the MonetDB.R package (connects r to a monet database)


# after running the r script above, users should have handy a few lines
# to initiate and connect to the monet database containing the latest
# national plan and provider enumeration system table.  run them now.  mine look like this:



####################################################################
# lines of code to hold on to for all other nppes monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/NPPES/nppes.bat"

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "nppes"
dbport <- 50006

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url )

# end of lines of code to hold on to for all other nppes monetdb analyses #
###########################################################################






# # # # # # # # # # # # # # # #
# create a monet.frame object #
# # # # # # # # # # # # # # # #





###########################################################################
# end of lines of code to hold on to for all other nppes monetdb analyses #

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other nppes monetdb analyses #
###########################################################################

# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
