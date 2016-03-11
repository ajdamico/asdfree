# analyze survey data for free (http://asdfree.com) with the r language
# basic stand alone medicare claims public use files
# 2008 files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/BSAPUF/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Basic%20Stand%20Alone%20Medicare%20Claims%20Public%20Use%20Files/2008%20-%20import%20all%20csv%20files%20into%20monetdb.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


############################################################################################
# import all 2008 comma separated value files for the bsa medicare puf into monetdb with R #
############################################################################################


library(R.utils)		# load the R.utils package (counts the number of lines in a file quickly)
library(DBI)			# load the DBI package (implements the R-database coding)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(MonetDBLite)	# load MonetDBLite package (creates database files in R)


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#########################################################################################################################################################################
# prior to running this analysis script, the basic stand alone public use files for 2008 must be loaded as comma separated value files (.csv) on the                    #
# local machine.  running the 2008 - download all csv files script will store each of these files in the current working directory                                      #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/Basic%20Stand%20Alone%20Medicare%20Claims%20Public%20Use%20Files/2008%20-%20download%20all%20csv%20files.R  #
#########################################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# all 2008 BSA comma separated value (.csv) files
# should already be stored in the "2008" folder within this directory
# so if all 2008 BSA files are stored in C:\My Directory\BSAPUF\2008\
# set this directory to C:/My Directory/BSAPUF/
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/BSAPUF/" )


# set the current year of data to import
year <- 2008


# note: the MonetDB folder should *not* be within a year-specific directory.
# multiple bsa puf years will all be stored into the same monet database,
# in order to allow multi-year analyses.
# although the csv download script changed the working directory to a single year of data,
# this importation will include all monetdb files into a single database folder


# configure a monetdb database for the bsa pufs #

# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )

# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite() , dbfolder )

# end of monetdb database configuration #



# start of files to import #

# inpatient claims
inpatient <- paste0( "./" , year , "/" , year , "_BSA_Inpatient_Claims_PUF.csv" )

# durable medical equipment
dme <- paste0( "./" , year , "/" , year , "_BSA_DME_Line_Items_PUF.csv" )

# prescription drug events
pde <- paste0( "./" , year , "/" , year , "_BSA_PartD_Events_PUF_" , 1:5 , ".csv" )

# hospice
hospice <- paste0( "./" , year , "/" , year , "_BSA_Hospice_Beneficiary_PUF.csv" )

# physician carrier
carrier <- paste0( "./" , year , "/" , year , "_BSA_Carrier_Line_Items_PUF_" , 1:7 , ".csv" )

# home health agency
hha <- paste0( "./" , year , "/" , year , "_BSA_HHA_Beneficiary_PUF.csv" )

# outpatient
outpatient <- paste0( "./" , year , "/" , year , "_BSA_Outpatient_Procedures_PUF_" , 1:3 , ".csv" )

# skilled nursing facility
snf <- paste0( "./" , year , "/" , year , "_BSA_SNF_Beneficiary_PUF.csv" )

# chronic conditions
cc <- paste0( "./" , year , "/" , year , "_Chronic_Conditions_PUF.csv" )

# institutional provider & beneficiary summary
ipbs <- paste0( "./" , year , "/" , year , " IPBS PUF.csv" )

# prescription drug profiles
rxp <- paste0( "./" , year , "/" , year , "_PD_Profiles_PUF.csv" )


# end of files to import #


# note: slow. slow. slow. #
# the following monet.read.csv() functions take a while. #
# run them all together overnight if possible. #
# you'll never have to do this again.  hooray! #


# store the 2008 inpatient claims table in the database as the 'inpatient08' table
monet.read.csv( 

	# use the monet database connection initiated above
	db , 

	# store the external csv file contained in the 'inpatient' character string
	inpatient , 

	# save the csv file in the monetdb to a data table named 'inpatient08'
	paste0( 'inpatient' , substr( year , 3 , 4 ) ) ,
	
	# force all column names to be lowercase
	lower.case.names = TRUE
)


# store the 2008 durable medical equipment table in the database as the 'dme08' table
monet.read.csv( 
	db , 
	dme , 
	paste0( 'dme' , substr( year , 3 , 4 ) ) ,
	
	# force all column names to be lowercase
	lower.case.names = TRUE
)

# store the five 2008 prescription drug events tables in the database as a single 'pde08' table
monet.read.csv( 
	db , 
	pde , 
	paste0( 'pde' , substr( year , 3 , 4 ) ) ,
	
	# force all column names to be lowercase
	lower.case.names = TRUE
)

# store the 2008 hospice table in the database as the 'hospice08' table
monet.read.csv( 
	db , 
	hospice , 
	paste0( 'hospice' , substr( year , 3 , 4 ) ) ,
	
	# force all column names to be lowercase
	lower.case.names = TRUE
)

# store the seven 2008 carrier line items tables in the database as a single 'carrier08' table
monet.read.csv( 
	db , 
	carrier , 
	paste0( 'carrier' , substr( year , 3 , 4 ) ) ,
	
	# force all column names to be lowercase
	lower.case.names = TRUE
)


# store the 2008 home health agency table in the database as the 'hha08' table
monet.read.csv( 
	db , 
	hha , 
	paste0( 'hha' , substr( year , 3 , 4 ) ) ,
	
	# force all column names to be lowercase
	lower.case.names = TRUE
)


# store the three 2008 outpatient claims tables in the database as a single 'outpatient08' table
monet.read.csv( 
	db , 
	outpatient , 
	paste0( 'outpatient' , substr( year , 3 , 4 ) ) ,
	
	# force all column names to be lowercase
	lower.case.names = TRUE
)


# store the 2008 snf table in the database as the 'snf08' table
monet.read.csv( 
	db , 
	snf , 
	paste0( 'snf' , substr( year , 3 , 4 ) ) ,
	
	# force all column names to be lowercase
	lower.case.names = TRUE
)


# store the 2008 chronic conditions table in the database as the 'cc08' table
cc_df <- read.csv( cc , stringsAsFactors = FALSE )
names( cc_df ) <- tolower( names( cc_df ) )
dbWriteTable( db , paste0( 'cc' , substr( year , 3 , 4 ) ) , cc_df )
rm( cc_df ) ; gc()


# store the 2008 ipbs table in the database as the 'ipbs08' table
ipbs_df <- read.csv( ipbs , stringsAsFactors = FALSE )
names( ipbs_df ) <- tolower( names( ipbs_df ) )
dbWriteTable( db , paste0( 'ipbs' , substr( year , 3 , 4 ) ) , ipbs_df )
rm( ipbs_df ) ; gc()


# store the 2008 prescription drug profile table in the database as the 'rxp08' table
monet.read.csv( 
	db , 
	rxp , 
	paste0( 'rxp' , substr( year , 3 , 4 ) ) ,
	nrow.check = 10000 ,
	
	# force all column names to be lowercase
	lower.case.names = TRUE
)



# the current monet database folder should now
# contain eight newly-added tables
dbListTables( db )		# print the tables stored in the current monet database to the screen


# the current monet database can now be accessed
# like any other database in the r language
# here's an example of how to examine the first six records
# of the prescription drug events file
dbGetQuery( db , "select * from pde08 limit 6" )
# additional analysis examples are stored in the other scripts

# set every table you've just created as read-only inside the database.
for ( this_table in dbListTables( db ) ) dbSendQuery( db , paste( "ALTER TABLE" , this_table , "SET READ ONLY" ) )

# disconnect from the current monet database
dbDisconnect( db )


# once complete, this script does not need to be run again for this year of data.
# instead, use the example monetdb analysis scripts
