# analyze survey data for free (http://asdfree.com) with the r language
# basic stand alone medicare claims public use files
# 2008 files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# batfile <- "C:/My Directory/BSAPUF/MonetDB/bsapuf.bat"
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Basic%20Stand%20Alone%20Medicare%20Claims%20Public%20Use%20Files/2008%20-%20replicate%20cms%20publications.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

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


# this r script will replicate statistics found on nine different
# centers for medicare and medicaid services (cms) publications
# and match the output exactly (except where noted)


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###########################################################################################################################################################################
# prior to running this analysis script, the basic stand alone public use files for 2008 must be imported into a monet database on the local machine. you must run this:  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/usgsd/master/Basic%20Stand%20Alone%20Medicare%20Claims%20Public%20Use%20Files/2008%20-%20import%20all%20csv%20files%20into%20monetdb.R  #
###########################################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # #
# warning: monetdb required #
# # # # # # # # # # # # # # #


require(MonetDB.R)	# load the MonetDB.R package (connects r to a monet database)


# after running the r script above, users should have handy a few lines
# to initiate and connect to the monet database containing the 2008
# basic stand alone public use files.  run them now.  mine look like this:



###################################################################################
# lines of code to hold on to for the start of all other bsa puf monetdb analyses #

# first: specify your batfile.  again, mine looks like this:
# uncomment this line by removing the `#` at the front..
# batfile <- "C:/My Directory/BSAPUF/MonetDB/bsapuf.bat"

# second: run the MonetDB server
pid <- monetdb.server.start( batfile )

# third: your five lines to make a monet database connection.
# just like above, mine look like this:
dbname <- "bsapuf"
dbport <- 50003

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url )

# end of lines of code to hold on to for all other bsa puf monetdb analyses #
#############################################################################



# # # # # # # # # # # # # #
# replicated statistics 1 #
# # # # # # # # # # # # # #
# the centers for medicare and medicaid services published this presentation containing
# table record counts on pdf page 28.  the following code will print each table and match each record count
# http://www.academyhealth.org/files/ProfDev/Files/PUFs%20Session%202%20Slides_For%20Download%202.pdf

# set the current year of data to analyze
year <- 2008

# create a character vector with each table
pufs <- c( "hha" , "snf" , "hospice" , "carrier" , "pde" , "outpatient" , "dme" , "inpatient" , "ipbs" , "cc" )

# add the last two digits of the analysis year to each string
pufs <- 
	paste0( 
		pufs , 
		substr( year , 3 , 4 ) 
	)

# loop through each public use file..
for ( i in pufs ){

	# print the name of the current table
	print( i )
	
	
	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	# create a monet.frame object (experimental, but designed to behave like an R data frame) #
	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

	assign( i , monet.frame( db , i ) )

	# print the number of records stored in that table
	print( 
		paste( 
			"table" , 
			i , 
			"contains" , 
			nrow( get( i ) ) , 
			"rows" 
		) 
	)
}

# and now you can access each of those objects as if they were an R data frame #


# # # # # # # # # # # # # #
# replicated statistics 2 #
# # # # # # # # # # # # # #
# the centers for medicare and medicaid services published this enrollment and user rates document containing
# estimated user rates for home health agency (hha) services in fee-for-service medicare in 2008
# in table 9 on pdf page 7.  the following code will precisely replicate the "12 months of enrollment" rows for both sexes.
# http://www.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/BSAPUFS/Downloads/2008_Enrollment_and_User_Rates.pdf

# start with the 'part a & b' -- '12 months' rows from table 1 on pdf page 2 of the same publication.
# these statistics are not available in the public use files, so must be recorded from an external source.
benes <-
	# initiate a matrix called 'benes' containing the age and sex breakouts of the 2008 fee-for-service medicare population
	matrix( 
		c( 
			2629901 , 2723408 , 2701379 , 2113641 , 1570310 , 1222630 ,
			2343581 , 3099587 , 3230174 , 2794191 , 2447474 , 2683070 
		) ,
		6 , 
		2
	)

# print this matrix to the screen
benes

# examine the first and last six records of the home health agency (hha) table
head( hha08 )

tail( hha08 )

# create an 'hhusers' data frame, constructed by querying the monet database
hhusers <-
	# run a sql (read-only) query
	dbGetQuery( 

		# use the monet database connection
		db , 
		
		# run this select statement -
		# number of records -- count(*)
		# broken out by beneficiary sex and age categories
		# ordered by the same sex and age categories
		"select 
			bene_sex_ident_cd , bene_age_cat_cd , count(*) 

		from 
			hha08 

		group by 
			bene_sex_ident_cd , bene_age_cat_cd

		order by 
			bene_sex_ident_cd , bene_age_cat_cd" 
	)

# print the current home health users table to the screen
hhusers
	
# note that the basic stand alone public use file is roughly 5% of the medicare fee-for-service population
# so multiply each number by twenty, and store the results in the same matrix shape as the 'benes' table above
hhusers <- matrix( 20 * as.numeric( hhusers$L1 ) , 6 , 2 )

# print this matrix to the screen
hhusers

# sum up each column
# divide the hh users by the total number of beneficiaries
# this matches the percent totals by sex
round( colSums( hhusers ) / colSums( benes ) , 4 )

# divide the hh users by the total number of beneficiaries
# within each sex and age category
# this matches the percents shown in table 9
round( hhusers / benes , 4 )


# # # # # # # # # # # # # #
# replicated statistics 3 #
# # # # # # # # # # # # # #
# the centers for medicare and medicaid services published a table in the inpatient claims general documentation
# distribution of inpatient claims for beneficiaries in fee-for-service medicare by sex in 2008
# the following code will precisely match the 'total' (bottom) row in tables 5 and 6 of the inpatient documentation (pdf page 20)
# http://www.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/BSAPUFS/Downloads/2008_BSA_Inpatient_Claims_PUF_GenDoc.pdf

# examine the first six records of the 2008 inpatient claims (inpatient08) table using SQL..
dbGetQuery( db , "select * from inpatient08 limit 6" )

# ..or access the monet.frame object
head( inpatient08 )


# run a simple sql query on the inpatient claims table in the 2008 monet database
dbGetQuery( 
	db , 
	"select 
		bene_sex_ident_cd ,
		bene_age_cat_cd ,
		count(*) as claims
	from 
		inpatient08 
	group by 
		bene_sex_ident_cd ,
		bene_age_cat_cd
	order by
		bene_age_cat_cd,
		bene_sex_ident_cd"
)


# # # # # # # # # # # # # #
# replicated statistics 4 #
# # # # # # # # # # # # # #
# the centers for medicare and medicaid services published a table in the inpatient claims general documentation
# distribution of inpatient claims by length of stay (inpatient days) for beneficiaries in fee-for-service medicare in 2008
# the following code will precisely match the puf (rightmost) column in table 12 of the inpatient documentation (pdf page 23)
# http://www.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/BSAPUFS/Downloads/2008_BSA_Inpatient_Claims_PUF_GenDoc.pdf


# count the total number of claims in the monet data table using SQL..
( total.claims <- dbGetQuery( db , "select count(*) from inpatient08" ) )

# ..or as a monet.frame
nrow( inpatient08 )

# print the distinct values of the 'ip_clm_days_cd' column to the screen
dbGetQuery( db , "select distinct ip_clm_days_cd from inpatient08" )
# according to pdf page 4 of the documentation, this length of stay variable contains four categories:

# Length (IP_CLM_DAYS_CD): The length of stay is reported in four categories:
# (1) 1 day, (2) 2 - 4 days, (3) 5 - 7 days, and (4) 8 or more days.


# store the number of claims for each length of stay category into a data frame called 'table12'
table12 <- 
	dbGetQuery(
		db ,
			paste(
				"select
					ip_clm_days_cd , 
					count(*) as claims
					from inpatient08
					group by ip_clm_days_cd
					order by ip_clm_days_cd"
			)
	)
	
# divide the number of claims within each length of stay category by the total number of claims
# and print the results to the screen:
table12$claims / as.numeric( total.claims )

# create a new 'pct' column containing each of these percents
table12$pct <- table12$claims / as.numeric( total.claims )

# the table12 'pct' column now matches the 'puf' column
# of table 12 from the inpatient general documentation
table12


# # # # # # # # # # # # # #
# replicated statistics 5 #
# # # # # # # # # # # # # #
# the centers for medicare and medicaid services published a table in the hospice enrollee general documentation
# distribution of beneficiaries by gender in hospice in fee-for-service medicare in 2008
# the following code will precisely match the puf (rightmost) column in table 4 of the hospice documentation (pdf page 7)
# http://www.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/BSAPUFS/Downloads/2008_BSA_Hospice_Bene_PUF_GenDoc.pdf

# examine the first six records of the 2008 hospice enrollee (hospice08) table using SQL..
dbGetQuery( db , "select * from hospice08 limit 6" )

# ..or access it as a monet.frame
head( hospice08 )


# store the number of beneficiaries in hospice (remember this is about 5% of the total population)
( total.benes <- dbGetQuery( db , "select count(*) from hospice08" ) )

# same old same old
nrow( hospice08 )

# store the number of beneficiaries in hospice - in each sex category - into a data frame called 'table4'
table4 <- 
	dbGetQuery(
		db ,
			paste(
				"select
					bene_sex_ident_cd , 
					count(*) as benes
					from hospice08
					group by bene_sex_ident_cd
					order by bene_sex_ident_cd"
			)
	)
	
# divide the number of hospice enrollees within each
# sex category by the total number of beneficiaries
# and print the results to the screen:
table4$benes / as.numeric( total.benes )

# create a new 'pct' column containing each of these percents
table4$pct <- table4$benes / as.numeric( total.benes )

# the table4 'pct' column now matches the 'puf' column
# of table 4 from the inpatient general documentation
table4



# # # # # # # # # # # # # #
# replicated statistics 6 #
# # # # # # # # # # # # # #
# the centers for medicare and medicaid services published a table in the skilled nursing facility (snf) beneficiary general documentation
# distribution of beneficiaries in fee-for-service medicare in 2008 by number of snf admissions
# the following code will precisely match the puf (rightmost) column in table 6 of the snf documentation (pdf page 8)
# http://www.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/BSAPUFS/Downloads/2008_BSA_SNF_Bene_PUF_GenDoc.pdf

# examine the first six records of the 2008 snf user (snf08) table
dbGetQuery( db , "select * from snf08 limit 6" )

# count the number of snf users, broken out by number of admissions
snf.users.by.admissions <- dbGetQuery( db , "select snf_adm_cd , count(*) as count from snf08 group by snf_adm_cd")

# divide the total number of snf users (the sum of the count column)
# by the number of snf users in each 'number of admissions' category
snf.users.by.admissions$count / sum( snf.users.by.admissions$count )



# # # # # # # # # # # # # #
# replicated statistics 7 #
# # # # # # # # # # # # # #
# the centers for medicare and medicaid services published a table in the carrier line item general documentation
# number of line items submitted by non-institutional providers (mostly doctors but other non-mds as well)
# providing services to fee-for-service medicare beneficiaries in 2008
# the following code will precisely match the number of line items (lower right box) in table 1 of the carrier documentation (pdf page 3)
# http://www.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/BSAPUFS/Downloads/2008_BSA_Carrier_Line_Items_PUF_GenDoc.pdf


# examine the first six records of the 2008 carrier line item (carrier08) table using SQL..
dbGetQuery( db , "select *  from carrier08 limit 6" )

# ..or as a monet.frame
head( carrier08 )

# count the total number of line items
# note: the 'medicare payments' also comes close to the 'medicare payments' column
# however doesn't match exactly, because the cms published number is pre-rounded (see table 2 on pdf page 7 for details)

dbGetQuery( db , "select count(*) as number_of_line_items , sum( car_hcpcs_pmt_amt ) as medicare_payments from carrier08" )


# # # # # # # # # # # # # #
# replicated statistics 8 #
# # # # # # # # # # # # # #
# the centers for medicare and medicaid services published a table in the prescription drug events general documentation
# distribution of patient payment percents for all rx events among fee-for-service medicare beneficiaries in 2008
# the following code will precisely match the distribution in table 10 of the prescription drug events documentation (pdf page 9)
# http://www.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/BSAPUFS/Downloads/2008_BSA_PD_Events_PUF_GenDoc.pdf

# examine the first six records of the 2008 prescription drug events (pde08) table with SQL..
dbGetQuery( db , "select * from pde08 limit 6" )

# ..or with monet.frame
head( pde08 )

# count the number of events shown in table 1 (on pdf page 2) and get close (but not perfect) to the total drug cost, due to rounding
table1 <- dbGetQuery( db , "select count(*) as num_events , sum( pde_drug_cost ) as drug_cost_sum from pde08" )

# print these statistics to the screen
table1


# calculate the numerator of the (rightmost) puf column of table 10
patient.payment.dist <-
	dbGetQuery( 
		db , 
		"select pde_drug_pat_pay_cd , count(*) from pde08 group by pde_drug_pat_pay_cd order by pde_drug_pat_pay_cd" 
	)
	
# print these numerators to the screen
patient.payment.dist
	
# divide the patient payment distribution
# by the total number of events to replicate the final statistic
as.numeric( patient.payment.dist$L1 ) / as.numeric( table1[1] )


# # # # # # # # # # # # # #
# replicated statistics 9 #
# # # # # # # # # # # # # #
# the centers for medicare and medicaid services published a table in the chronic conditions general documentation
# distribution of beneficiaries by gender and age categories in 2008 after suppression
# the following code will precisely match the counts in table 5 of the chronic conditions puf general documentation (pdf page 13)
# https://www.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/BSAPUFS/Downloads/2008_Chronic_Conditions_PUF_GenDoc.pdf

# examine the first six records of the 2008 chronic conditions (cc08) table using SQL..
dbGetQuery( db , "select * from cc08 limit 6" )

# ..or with monet.frame
head( cc08 )

# create a character vector containing each of the data columns matching the enrollee columns in table 5
count.columns <-
	c( 
		"bene_count_pa_lt_12" , "bene_count_pa_eq_12" , "bene_count_pb_lt_12" , 
		"bene_count_pb_eq_12" , "bene_count_pc_lt_12" , "bene_count_pc_eq_12" ,
		"bene_count_pd_lt_12" , "bene_count_pd_eq_12"
	)

# start building the sql string that will be used to replicate table 5 #

# create a string holding all of the sums of each column
sum.strings <- paste( "sum(" , count.columns , ")" , collapse = "," )

# run the overall enrollee counts (the bottom row of table 5)
dbGetQuery( db , paste( "select" , sum.strings , "from cc08" ) )

# run the enrollee counts, broken out by male/female
dbGetQuery( db , paste( "select bene_sex_ident_cd, " , sum.strings , "from cc08 group by bene_sex_ident_cd" ) )

# run the enrollee counts, broken out by male/female and age category
dbGetQuery( db , paste( "select bene_sex_ident_cd, bene_age_cat_cd, " , sum.strings , "from cc08 group by bene_sex_ident_cd, bene_age_cat_cd" ) )


#################################################################################
# lines of code to hold on to for the end of all other bsa puf monetdb analyses #

# disconnect from the current monet database
dbDisconnect( db )

# and close it using the `pid`
monetdb.server.stop( pid )

# end of lines of code to hold on to for all other bsa puf monetdb analyses #
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
