# analyze us government survey data with the r language
# behavioral risk factor surveillance system
# 2010

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


######################################################################
# this script matches the web-enabled analysis tool output shown at  ##############################################################################################################
# https://github.com/ajdamico/usgsd/blob/master/Behavioral%20Risk%20Factor%20Surveillance%20System/WEAT%202010%20Asthma%20Status%20-%20Crosstab%20Analysis%20Results.pdf?raw=true #
###################################################################################################################################################################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###################################################################################################################################################
# prior to running this analysis script, the brfss 2010 single-year file must be loaded as a monet database-backed sqlsurvey object               #
# on the local machine. running the 1984-2011 download and create database script will create a monet database containing this file               #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/usgsd/blob/master/Behavioral%20Risk%20Factor%20Surveillance%20System/1984%20-%202011%20download%20all%20microdata.R #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "b2010 design.rda" in C:/My Directory/BRFSS or wherever the working directory was set for the program            #
###################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


require(sqlsurvey)		# load sqlsurvey package (analyzes large complex design surveys)
require(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)

# after running the r script above, users should have handy a few lines
# to initiate and connect to the monet database containing all behavioral risk factor surveillance system tables
# run them now.  mine look like this:


######################################################################
# lines of code to hold on to for all other `brfss` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
batfile <- "C:/My Directory/BRFSS/MonetDB/brfss.bat"

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "brfss"
dbport <- 50004

drv <- dbDriver("MonetDB")
monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( drv , monet.url , "monetdb" , "monetdb" )


# # # # run your analysis commands # # # #


# the behavioral risk factor surveillance system download and importation script
# has already created a monet database-backed survey design object
# connected to the 2010 single-year table

# since this script only loads one file off of the local drive,
# there's no need to set the working directory.
# instead, simply use the full filepath to the r data file (.rda)
# as shown in the load() examples below.

# choose which single-year file in your BRFSS directory to analyze
# this script replicates the 2010 single-year estimates,
# so leave that line uncommented and the other three choices commented out.

# load the desired behavioral risk factor surveillance system monet database-backed complex sample design objects

load( 'C:/My Directory/BRFSS/b2010 design.rda' )	# analyze the 2010 single-year acs
# load( 'C:/My Directory/BRFSS/b2011 design.rda' )	# analyze the 2011 single-year acs
# load( 'C:/My Directory/BRFSS/b2009 design.rda' )	# analyze the 2009 single-year acs
# load( 'C:/My Directory/BRFSS/b1984 design.rda' )	# analyze the 1984 single-year acs

# note: this r data file should already contain the 2010 single-year design




# connect the complex sample designs to the monet database #
brfss.d <- open( brfss.design , driver = drv , user = "monetdb" , password = "monetdb" )	# single-year design



#############################################################################
# ..and immediately start printing the statistics in the replication target #
#############################################################################

# https://github.com/ajdamico/usgsd/blob/master/Behavioral%20Risk%20Factor%20Surveillance%20System/WEAT%202010%20Asthma%20Status%20-%20Crosstab%20Analysis%20Results.pdf?raw=true #

	
# calculate unweighted sample size column #
dbGetQuery( 
	db , 
	'select 
		xasthmst , count(*) as sample_size 
	from 
		b2010 
	group by 
		xasthmst
	order by
		xasthmst'
)


###########################
# row percent replication #
###########################


# run the row and S.E. of row % columns
# print the row percent column to the screen
( row.pct <- svymean( ~xasthmst , brfss.d , se = TRUE ) )

# extract the covariance matrix attribute from the svymean() output
# take only the values of the diagonal (which contain the variances of each value)
# square root them all to calculate the standard error
# save the result into the se.row.pct object and at the same time
# print the standard errors of the row percent column to the screen
# ( by surrounding the assignment command with parentheses )
( se.row.pct <- sqrt( diag( attr( row.pct , 'var' ) ) ) )

# confidence interval lower bounds for row percents
row.pct - qnorm( 0.975 ) * se.row.pct 

# confidence interval upper bounds for row percents
row.pct + qnorm( 0.975 ) * se.row.pct


####################################
# weighted sample size replication #
####################################

# run the sample size and S.E. of weighted size columns
# print the sample size (weighted) column to the screen
( sample.size <- svytotal( ~xasthmst , brfss.d , se = TRUE ) )


# extract the covariance matrix attribute from the svymean() output
# take only the values of the diagonal (which contain the variances of each value)
# square root them all to calculate the standard error
# save the result into the se.sample.size object and at the same time
# print the standard errors of the weighted size column to the screen
# ( by surrounding the assignment command with parentheses )
( se.sample.size <- sqrt( diag( attr( sample.size , 'var' ) ) ) )

# confidence interval lower bounds for weighted size
sample.size - qnorm( 0.975 ) * se.sample.size 

# confidence interval upper bounds for weighted size
sample.size + qnorm( 0.975 ) * se.sample.size

# close the connection to the two sqlsurvey design object
close( brfss.d )



# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other `brfss` monetdb analyses #
#############################################################################


# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
