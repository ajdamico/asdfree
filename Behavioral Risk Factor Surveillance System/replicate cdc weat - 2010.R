# analyze survey data for free (http://asdfree.com) with the r language
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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#########################################################################################################################################
# prior to running this analysis script, the brfss 2010 single-year file must be loaded as a monet database-backed sqlsurvey object     #
# on the local machine. running the 1984-2011 download and create database script will create a monet database containing this file     #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/usgsd/blob/master/Behavioral%20Risk%20Factor%20Surveillance%20System/download%20all%20microdata.R         #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "b2010 design.rda" in C:/My Directory/BRFSS or wherever the working directory was set for the program  #
#########################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


require(sqlsurvey)		# load sqlsurvey package (analyzes large complex design surveys)
require(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)

# after running the r script above, users should have handy a few lines
# to initiate and connect to the monet database containing all behavioral risk factor surveillance system tables
# run them now.  mine look like this:


######################################################################
# lines of code to hold on to for all other `brfss` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/BRFSS/MonetDB/brfss.bat"

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "brfss"
dbport <- 50004

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url )


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
# so uncomment that line and the other three choices commented out.

# load the desired behavioral risk factor surveillance system monet database-backed complex sample design objects

# uncomment one of these lines by removing the `#` at the front..
# load( 'C:/My Directory/BRFSS/b2010 design.rda' )	# analyze the 2010 single-year acs
# load( 'C:/My Directory/BRFSS/b2011 design.rda' )	# analyze the 2011 single-year acs
# load( 'C:/My Directory/BRFSS/b2009 design.rda' )	# analyze the 2009 single-year acs
# load( 'C:/My Directory/BRFSS/b1984 design.rda' )	# analyze the 1984 single-year acs

# note: this r data file should already contain the 2010 single-year design

# if you wnated to use an unedited version of this, you could simply #
# connect the complex sample designs to the monet database like this: #
# brfss.d <- open( brfss.design , driver = MonetDB.R() )	# single-year design

# # # # # # # # # # # # # # # # #
# numeric-to-factor conversion  #

# however, the 'asthma' column is coded as numeric 
# in the importation sas script for the 2010 brfss
# http://www.cdc.gov/brfss/annual_data/2010/sasout10.sas
# so that needs to be converted over to a factor.

# the variable `asthmst` was imported as a numeric variable
# the sqlsurvey package cannot convert numeric variables to factors
# on-the-fly, so instead just re-run the survey design object line

# the one object that needs to be modified is the check.factors table
# it's stored here
brfss.design$zdata

# extract only the non-numeric columns
all.cols <- sapply( brfss.design$zdata , 'class' )
fac.cols <- names( all.cols[ !( all.cols %in% c( 'numeric' , 'integer' ) ) ] )
# now you have a character string..
fac.cols
# containing all of the columns that are non-numeric already.

# now simply add the asthma column to it.
fac.cols <- c( fac.cols , 'xasthmst' )


# and re-run the brfss.design object.
# take a look at the old design to get most of your variables..

brfss.d <-
	sqlsurvey(
		weight = brfss.design$weights ,		# weight variable column (defined in the character string above)
		nest = TRUE ,						# whether or not psus are nested within strata
		strata = brfss.design$strata ,		# stratification variable column (defined in the character string above)
		id = brfss.design$id ,				# sampling unit column (defined in the character string above)
		table.name = brfss.design$table ,	# table name within the monet database (defined in the character string above)
		key = brfss.design$key ,			# sql primary key column (created with the auto_increment line above)
		check.factors = fac.cols ,			# character vector containing all factor columns for this year
		database = monet.url ,				# monet database location on localhost
		driver = MonetDB.R()
	)



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

# dear everyone: please contribute your script.
# have you written syntax that precisely matches an official publication?
message( "if others might benefit, send your code to ajdamico@gmail.com" )
# http://asdfree.com needs more user contributions

# let's play the which one of these things doesn't belong game:
# "only you can prevent forest fires" -smokey bear
# "take a bite out of crime" -mcgruff the crime pooch
# "plz gimme your statistical programming" -anthony damico
