# analyze survey data for free (http://asdfree.com) with the r language
# censo demografico
# 2010 gerais da amostra (general sample)
# household-level file

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( "monetdb.sequential" = TRUE )		# # only windows users need this line
# library(downloader)
# batfile <- "C:/My Directory/CENSO/MonetDB/censo_demografico.bat"		# # note for mac and *nix users: `censo_demografico.bat` might be `censo_demografico.sh` instead
# load( 'C:/My Directory/CENSO/dom 2010 design.rda' )
# source_url( "https://raw.github.com/ajdamico/asdfree/master/Censo%20Demografico/variable%20recode%20example.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# https://www.youtube.com/watch?v=JLt9JfaAxUg

# djalma pessoa
# pessoad@gmail.com

# anthony joseph damico
# ajdamico@gmail.com

# if you use this script for a project, please send me a note
# it's always nice to hear about how people are using this stuff

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###############################################################################################
# prior to running this analysis script, the 2010 censo demografico must be loaded as a monet #
# database-backed sqlsurvey object on the local machine. running this script will do it.      #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/asdfree/master/Censo%20Demografico/download%20and%20import.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "pes 2010 design.rda" in C:/My Directory/CENSO or wherever.  #
###############################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # #
# warning: monetdb required #
# # # # # # # # # # # # # # #


# windows machines and also machines without access
# to large amounts of ram will often benefit from
# the following option, available as of MonetDB.R 0.9.2 --
# remove the `#` in the line below to turn this option on.
# options( "monetdb.sequential" = TRUE )		# # only windows users need this line
# -- whenever connecting to a monetdb server,
# this option triggers sequential server processing
# in other words: single-threading.
# if you would prefer to turn this on or off immediately
# (that is, without a server connect or disconnect), use
# turn on single-threading only
# dbSendQuery( db , "set optimizer = 'sequential_pipe';" )
# restore default behavior -- or just restart instead
# dbSendQuery(db,"set optimizer = 'default_pipe';")



library(sqlsurvey)		# load sqlsurvey package (analyzes large complex design surveys)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)

# remove certainty units
options( survey.lonely.psu = "remove" )
# for more detail, see
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html


# after running the r script above, users should have handy a few lines
# to initiate and connect to the monet database containing all behavioral risk factor surveillance system tables
# run them now.  mine look like this:



##################################################################################
# lines of code to hold on to for all other `censo_demografico` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/CENSO/MonetDB/censo_demografico.bat"		# # note for mac and *nix users: `censo_demografico.bat` might be `censo_demografico.sh` instead

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "censo_demografico"
dbport <- 50011

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

# if you are running windows, you might see a performance improvement
# by turning off multi-threading with this command:
if (.Platform$OS.type == "windows") dbSendQuery( db , "set optimizer = 'sequential_pipe';" )
# this must be set every time you start the server.

# # # # run your analysis commands # # # #


# the censo demografico download and importation script
# has already created a monet database-backed survey design object
# connected to the 2010 household-level table

# sqlite database-backed survey objects are described here: 
# http://r-survey.r-forge.r-project.org/survey/svy-dbi.html
# monet database-backed survey objects are similar, but:
# the database engine is, well, blazingly faster
# the setup is kinda more complicated (but all done for you)


# making any changes to the data table downloaded directly from ibge currently
# requires directly accessing the table using dbSendQuery() to run sql commands


# note: recoding (writing) variables in monetdb often takes much longer
# than querying (reading) variables in monetdb.  therefore, it might be wise to
# run all recodes at once, and leave your computer running overnight.


# variable recodes on monet database-backed survey objects might be
# more complicated than you'd expect, but it's far from impossible
# three steps:



################################################################
# step 1: connect to the CENSO data table you'd like to recode # 
# then make a copy so you don't lose the pristine original.    #

# the command above
# db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )
# has already connected the current instance of r to the monet database

# now simply copy you'd like to recode into a new table
dbSendQuery( db , "CREATE TABLE recoded_c10_dom AS SELECT * FROM c10_dom WITH DATA" )
# this action protects the original 'c10_dom' table from any accidental errors.
# at any point, we can delete this recoded copy of the data table using the command..
# dbRemoveTable( db , "recoded_c10_dom" )
# ..and start fresh by re-copying the pristine file from c10_dom



############################################
# step 2: make all of your recodes at once #

# from this point forward, all commands will only touch the
# 'recoded_c10_dom' table.  the 'c10_dom' is now off-limits.

# add new columns for each poverty line

# since it's actually a categorical variable, make it DOUBLE PRECISION
dbSendQuery( db , "ALTER TABLE recoded_c10_dom ADD COLUMN nmorpob1 DOUBLE PRECISION" )
dbSendQuery( db , "ALTER TABLE recoded_c10_dom ADD COLUMN nmorpob2 DOUBLE PRECISION" )
dbSendQuery( db , "ALTER TABLE recoded_c10_dom ADD COLUMN nmorpob3 DOUBLE PRECISION" )
dbSendQuery( db , "ALTER TABLE recoded_c10_dom ADD COLUMN nmorpob4 DOUBLE PRECISION" )
dbSendQuery( db , "ALTER TABLE recoded_c10_dom ADD COLUMN nmorpob5 DOUBLE PRECISION" )
dbSendQuery( db , "ALTER TABLE recoded_c10_dom ADD COLUMN nmorpob6 DOUBLE PRECISION" )

dbSendQuery( db , "ALTER TABLE recoded_c10_dom ADD COLUMN mult_nmorpob1 DOUBLE PRECISION" )


# if you wanted to create a numeric variable, substitute DOUBLE PRECISION with VARCHAR( 255 ) like this:
# dbSendQuery( db , "ALTER TABLE recoded_c10_dom ADD COLUMN new_column VARCHAR( 255 )" )


dbSendQuery( db , "UPDATE recoded_c10_dom SET nmorpob1 = 1 * ( v6531 < 70 )" )
dbSendQuery( db , "UPDATE recoded_c10_dom SET nmorpob2 = 1 * ( v6531 < 80 )" )
dbSendQuery( db , "UPDATE recoded_c10_dom SET nmorpob3 = 1 * ( v6531 < 90 )" )
dbSendQuery( db , "UPDATE recoded_c10_dom SET nmorpob4 = 1 * ( v6531 < 100 )" )
dbSendQuery( db , "UPDATE recoded_c10_dom SET nmorpob5 = 1 * ( v6531 < 140 )" )
dbSendQuery( db , "UPDATE recoded_c10_dom SET nmorpob6 = 1 * ( v6531 < 272.50 )" )

dbSendQuery( db , "UPDATE recoded_c10_dom SET mult_nmorpob1 = nmorpob1 * dom_count_pes" )


# quickly check your work by running a simple SELECT COUNT(*) command with sql
dbGetQuery( db , "SELECT nmorpob1 , nmorpob2 , nmorpob3 , nmorpob4 , nmorpob5 , nmorpob6 , COUNT(*) as number_of_records from recoded_c10_dom GROUP BY nmorpob1 , nmorpob2 , nmorpob3 , nmorpob4 , nmorpob5 , nmorpob6" )
# and notice that each value of increasing value of nmorpob contains 100% of the previous



#############################################################################
# step 3: create a new survey design object connecting to the recoded table #

# to initiate a new complex sample survey design on the data table
# that's been recoded to include the six new poverty variables
# simply re-run the sqlsurvey() function and update the table.name =
# argument so it now points to the recoded_ table in the monet database

# this process runs much faster if you create a character vector containing all non-numeric columns
# otherwise, just set `check.factors = 10` within the sqlsurvey function and it take a guess at which columns
# are character strings or factor variables and which columns should be treated as numbers

# step 3a: load the pre-recoded (previous) design 

# load( 'C:/My Directory/CENSO/dom 2010 design.rda' )
# uncomment the line above by removing the `#`

# step 3b: extract the character columns
all.classes <- sapply( dom.design$zdata , class )
factor.columns <- names( all.classes[ !( all.classes %in% c( 'integer' , 'numeric' ) ) ] )

# *if and only if* the column you added is also a character/factor, non-numeric column
# then add it to this character vector as i've done here:
# factor.columns <- c( factor.columns , 'new_column' )
# but since all of the nmorpob# variables are numeric,
# the `factor.columns` object does not need to change


# step 3c: re-create a sqlsurvey complex sample design object
# using the *recoded* table
recoded.dom.design <-
	sqlsurvey(
		weight = 'dom_wgt' ,
		nest = TRUE ,
		strata = 'v0011' ,
		id = 'v0300' ,
		fpc = 'dom_fpc' ,
		table.name = 'recoded_c10_dom' ,	# this parameter..
		key = "idkey" ,
		check.factors = factor.columns ,	# ..and possibly this parameter are the only changes from the download and import script.
		database = monet.url ,
		driver = MonetDB.R()
	)



# sqlite database-backed survey objects are described here: 
# http://r-survey.r-forge.r-project.org/survey/svy-dbi.html
# monet database-backed survey objects are similar, but:
# the database engine is, well, blazingly faster
# the setup is kinda more complicated (but all done for you)



# save this new complex sample survey design
# into an r data file (.rda) that can now be
# analyzed quicker than anything else.
# unless you've set your working directory elsewhere, 
# spell out the entire filepath to the .rda file
# use forward slashes instead of backslashes

# uncomment this line by removing the `#` at the front..
# save( recoded.dom.design , file = "C:/My Directory/CENSO/recoded dom 2010 design.rda" )



# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )



# # # # # # # # # # # # # # # # #
# you've completed your recodes #
# # # # # # # # # # # # # # # # #

# everything's peaches and cream from here on in.

# to analyze your newly-recoded year of data:

# close r

# open r back up

library(sqlsurvey)		# load sqlsurvey package (analyzes large complex design surveys)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)

# remove certainty units
options( survey.lonely.psu = "remove" )
# for more detail, see
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html

# run your..
# lines of code to hold on to for all other CENSO monetdb analyses #
# (the same block of code i told you to hold onto at the end of the download script)

# load your new the survey object

# uncomment this line by removing the `#` at the front..
# load( "C:/My Directory/CENSO/recoded dom 2010 design.rda" )


##################################################################################
# lines of code to hold on to for all other `censo_demografico` monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/CENSO/MonetDB/censo_demografico.bat"		# # note for mac and *nix users: `censo_demografico.bat` might be `censo_demografico.sh` instead

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "censo_demografico"
dbport <- 50011

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )

# if you are running windows, you might see a performance improvement
# by turning off multi-threading with this command:
if (.Platform$OS.type == "windows") dbSendQuery( db , "set optimizer = 'sequential_pipe';" )
# this must be set every time you start the server.

# # # # run your analysis commands # # # #

# connect the recoded complex sample design to the monet database #
recoded.dom.d <- open( recoded.dom.design , driver = MonetDB.R() , wait = TRUE )	# recoded

# remove anyone with missing poverty levels
valid.dom <- subset( recoded.dom.d , v6531 >= 0 )

# ..and now you can calculate poverty rates many different ways


# calculate unweighted sample sizes
dbGetQuery( 
	db , 
	'select 
		sum( nmorpob1 ) as num_below_70 ,
		sum( nmorpob2 ) as num_below_80 ,
		sum( nmorpob3 ) as num_below_90 ,
		sum( nmorpob4 ) as num_below_100 ,
		sum( nmorpob5 ) as num_below_140 ,
		sum( nmorpob6 ) as num_below_272p5 ,
		sum( dom_count_pes ) as num_dom_count_pes
	from 
		recoded_c10_dom
	where
		v6531 IS NOT NULL'
)



# calculate weighted sample sizes using sql..
dbGetQuery( 
	db , 
	'select 
		sum( dom_wgt * nmorpob1 ) as wtd_below_70 ,
		sum( dom_wgt * nmorpob2 ) as wtd_below_80 ,
		sum( dom_wgt * nmorpob3 ) as wtd_below_90 ,
		sum( dom_wgt * nmorpob4 ) as wtd_below_100 ,
		sum( dom_wgt * nmorpob5 ) as wtd_below_140 ,
		sum( dom_wgt * nmorpob6 ) as wtd_below_272p5 ,
		sum( dom_wgt * dom_count_pes ) as wtd_dom_count_pes
	from 
		recoded_c10_dom
	where
		v6531 IS NOT NULL'
)

# ..or with syntax from the R survey package
svytotal( ~ nmorpob1 + nmorpob2 + nmorpob3 + nmorpob4 + nmorpob5 + nmorpob6 + dom_count_pes , valid.dom )

# including the standard error - warning: computationally intensive
# svytotal( ~ nmorpob1 + nmorpob2 + nmorpob3 + nmorpob4 + nmorpob5 + nmorpob6 + dom_count_pes , valid.dom , se = TRUE )



# calculate the percent of households in poverty
dbGetQuery( 
	db , 
	'select 
		sum( dom_wgt * nmorpob1 ) / sum( dom_wgt ) as pct_below_70 ,
		sum( dom_wgt * nmorpob2 ) / sum( dom_wgt ) as pct_below_80 ,
		sum( dom_wgt * nmorpob3 ) / sum( dom_wgt ) as pct_below_90 ,
		sum( dom_wgt * nmorpob4 ) / sum( dom_wgt ) as pct_below_100 ,
		sum( dom_wgt * nmorpob5 ) / sum( dom_wgt ) as pct_below_140 ,
		sum( dom_wgt * nmorpob6 ) / sum( dom_wgt ) as pct_below_272p5 ,
		sum( dom_wgt * dom_count_pes ) / sum( dom_count_pes ) as wtd_pes_per_dom
	from 
		recoded_c10_dom
	where
		v6531 IS NOT NULL'
)


# ..or with syntax from the R survey package
svymean( ~ nmorpob1 + nmorpob2 + nmorpob3 + nmorpob4 + nmorpob5 + nmorpob6 + dom_count_pes , valid.dom )

# including the standard error - warning: computationally intensive
# svymean( ~ nmorpob1 + nmorpob2 + nmorpob3 + nmorpob4 + nmorpob5 + nmorpob6 + dom_count_pes , valid.dom , se = TRUE )



# # # # # # #
# by state  #
# # # # # # #

# weighted totals #
wtd.totals.by.state <-
	dbGetQuery( 
		db , 
		'select 
			v0001 ,
			sum( dom_wgt * nmorpob1 ) as wtd_below_70 ,
			sum( dom_wgt * nmorpob2 ) as wtd_below_80 ,
			sum( dom_wgt * nmorpob3 ) as wtd_below_90 ,
			sum( dom_wgt * nmorpob4 ) as wtd_below_100 ,
			sum( dom_wgt * nmorpob5 ) as wtd_below_140 ,
			sum( dom_wgt * nmorpob6 ) as wtd_below_272p5 ,
			sum( dom_wgt * dom_count_pes ) as wtd_pes_per_dom
		from 
			recoded_c10_dom
		where
			v6531 IS NOT NULL
		group by
			v0001
		order by
			v0001'
	)

# print these results to the screen
wtd.totals.by.state
	

# note that these by-state queries have been reduced because of their computational complexity  #
# it's advisable to use SQL commands if possible.  they will run much faster & more beautifully #

# both with and without the standard error, these commands are computationally intensive
# svytotal( ~ nmorpob1 + dom_count_pes , valid.dom , byvar = ~v0001 )
# svytotal( ~ nmorpob1 + dom_count_pes , valid.dom , byvar = ~v0001 , se = TRUE )



# weighted percents #
wtd.pcts.by.state <-
	dbGetQuery( 
		db , 
		'select 
			v0001 ,
			sum( dom_wgt * nmorpob1 ) / sum( dom_wgt ) as pct_below_70 ,
			sum( dom_wgt * nmorpob2 ) / sum( dom_wgt ) as pct_below_80 ,
			sum( dom_wgt * nmorpob3 ) / sum( dom_wgt ) as pct_below_90 ,
			sum( dom_wgt * nmorpob4 ) / sum( dom_wgt ) as pct_below_100 ,
			sum( dom_wgt * nmorpob5 ) / sum( dom_wgt ) as pct_below_140 ,
			sum( dom_wgt * nmorpob6 ) / sum( dom_wgt ) as pct_below_272p5 ,
			sum( dom_wgt * dom_count_pes ) / sum( dom_count_pes ) as wtd_pes_per_dom
		from 
			recoded_c10_dom
		where
			v6531 IS NOT NULL
		group by
			v0001
		order by
			v0001'
	)

# print these results to the screen
wtd.pcts.by.state


# note that these by-state queries have been reduced because of their computational complexity  #
# it's advisable to use SQL commands if possible.  they will run much faster & more beautifully #

# both with and without the standard error, these commands are computationally intensive
# svymean( ~ nmorpob1 + dom_count_pes , valid.dom , byvar = ~v0001 )
# svymean( ~ nmorpob1 + dom_count_pes , valid.dom , byvar = ~v0001 , se = TRUE )


# # # # # # # # # #
# export examples #
# # # # # # # # # #

# create a character vector containing all states in order:
estado.names <- c( "Rondonia" , "Acre" , "Amazonas" , "Roraima" , "Para" , "Amapa" , "Tocantins" , "Maranhao" , "Piaui" , "Ceara" , "Rio Grande\ndo Norte" , "Paraiba" , "Pernambuco" , "Alagoas" , "Sergipe" , "Bahia" , "Minas Gerais" , "Espirito Santo" , "Rio de Janeiro" , "Sao Paulo" , "Parana" , "Santa Catarina" , "Rio Grande\ndo Sul" , "Mato Grosso\ndo Sul" , "Mato Grosso" , "Goias" , "Distrito Federal" )


# plot the percentage of households below 70 by state
barplot(
	wtd.pcts.by.state$pct_below_70 ,
	main = "Percent of People in Households With PCI Below 70" ,
	names.arg = estado.names ,
	ylim = c( 0 , .25 ) ,
	cex.names = 0.7 ,
	col = c( rep( "lightgreen" , 7 ) , rep( "sandybrown" , 9 ) , rep( "palevioletred" , 4 ) , rep( "plum" , 3 ) , rep( "khaki" , 4 ) ) ,
	las = 2 ,
	# do not print the y axis at first
	yaxt = "n"
)

# add the y axis..
axis( 
	side = 2 , 
	# from 0 to 0.25, with tick marks every 0.05
	at = seq( 0 , .25 , .05 ) , 
	# saying 0%, 5% ..etc.. up to 25%
	labels = paste0( seq( 0 , 25 , 5 ) , "%" ) , 
	# turn the numbers rightside-up
	las = 2 
)

legend( 
	"topright" , 
	c( "North" , "Northeast" , "Southeast" , "South" , "Midwest") , 
	fill = c( "lightgreen" , "sandybrown" , "palevioletred" , "plum" , "khaki" ) 
)


# plot the percentage of households below 272.5 by state
barplot(
	wtd.pcts.by.state$pct_below_272p5 ,
	main = "Percent of People in Households With PCI Below 272.50" ,
	names.arg = estado.names ,
	ylim = c( 0 , .6 ) ,
	cex.names = 0.7 ,
	col = c( rep( "lightgreen" , 7 ) , rep( "sandybrown" , 9 ) , rep( "palevioletred" , 4 ) , rep( "plum" , 3 ) , rep( "khaki" , 4 ) ) ,
	las = 2 ,
	# do not print the y axis at first
	yaxt = "n"
)

# add the y axis..
axis( 
	side = 2 , 
	# from 0 to 0.6, with tick marks every 0.1
	at = seq( 0 , .6 , .1 ) , 
	# saying 0%, 5% ..etc.. up to 25%
	labels = paste0( seq( 0 , 60 , 10 ) , "%" ) , 
	# turn the numbers rightside-up
	las = 2 
)

legend( 
	"topright" , 
	c( "North" , "Northeast" , "Southeast" , "South" , "Midwest") , 
	fill = c( "lightgreen" , "sandybrown" , "palevioletred" , "plum" , "khaki" ) 
)

# # # # # # # # # # # # # #
# end of export examples  #
# # # # # # # # # # # # # #



# # # # # # # # # # # # # # #
# ratio calculation example #
# # # # # # # # # # # # # # #

# calculate both the numerator and denominator of poverty, but not by state
num_den <- svytotal( ~ mult_nmorpob1 + dom_count_pes , valid.dom , se = TRUE )
# this gets computationally-intensive very fast.  either write a loop to perform one state at a time,
# or leave your computer running for a week, or buy a bigger computer.  ;)


# calculate the ratio estimate
ratio.estimate <- coef( num_den )[ 1 ] / coef( num_den )[ 2 ]

# print the ratio estimate to the screen
ratio.estimate


# calculate the variance of the ratio
vcov.num_den <- vcov( num_den )

variance.pob1 <-
	( 1 / coef( num_den )[ 2 ] ^ 2 ) * 
	( 
		vcov.num_den[ 1 , 1 ] - 
		2 * coef( num_den )[ 1 ] / coef( num_den )[ 2 ] * vcov.num_den[ 1 , 2 ] + 
		( coef( num_den )[ 1 ] / coef( num_den )[ 2 ]) ^ 2 * vcov.num_den[ 2 , 2 ] 
	)
	
# print the standard error of the ratio to the screen
sqrt( variance.pob1 )

# since R's sqlsurvey package does not yet have `svyratio` capabilities
# this brute-force approach calculates a ratio and accompanying standard error


# finito.

# close all connections to the sqlsurvey design object
close( recoded.dom.design , recoded.dom.d , valid.dom )

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other `censo_demografico` monetdb analyses #
#########################################################################################


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
