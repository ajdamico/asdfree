# analyze survey data for free (http://asdfree.com) with the r language
# united states decennial census
# public use microdata sample
# 1990 , 2000

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/PUMS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/United%20States%20Decennial%20Census%20Public%20Use%20Microdata%20Sample/replicate%20control%20counts%20table.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#################################################################################################################################################################
# prior to running this analysis script, the 1% and 5% public use microdata samples from the 2000 census must be loaded on the local machine with               #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/United%20States%20Decennial%20Census%20Public%20Use%20Microdata%20Sample/download%20and%20import.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# ..that script will place a 'MonetDB' folder on the local drive containing the appropriate data tables for this code to work properly.                         #
#################################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


#############################################################################
# this script matches the unweighted and weighted totals shown in the       #
# census document: http://www.census.gov/prod/cen2000/doc/pums.pdf#page=645 #
#############################################################################


library(survey) 		# load survey package (analyzes complex design surveys)
library(DBI)			# load the DBI package (implements the R-database coding)




# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PUMS/" )


# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )

# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite::MonetDBLite() , dbfolder )


# # # # # sql-based analysis starts here # # # # #

# 1-percent pums file household counts by state
dbGetQuery( 
	db , 
	'select 
		state ,
		count( * ) as household_unweighted ,
		sum( hweight ) as household_weighted
	from
		pums_2000_1_h
	group by
		state
	order by
		state'
)

# 1-percent pums file person counts by state
dbGetQuery( 
	db , 
	'select 
		state ,
		count( * ) as person_unweighted ,
		sum( pweight ) as person_weighted
	from
		pums_2000_1_m
	group by
		state
	order by
		state'

)

# 5-percent pums file household counts by state
dbGetQuery( 
	db , 
	'select 
		state ,
		count( * ) as household_unweighted ,
		sum( hweight ) as household_weighted
	from
		pums_2000_5_h
	group by
		state
	order by
		state'

)

# 5-percent pums file person counts by state
dbGetQuery( 
	db , 
	'select 
		state ,
		count( * ) as person_unweighted ,
		sum( pweight ) as person_weighted
	from
		pums_2000_5_m
	group by
		state
	order by
		state'
)

# # # # # sql-based analysis ends here # # # # #

# disconnect from the current monet database
dbDisconnect( db , shutdown = TRUE )

