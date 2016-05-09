# analyze survey data for free (http://asdfree.com) with the r language
# home mortgage disclosure act
# 2006 - 2014 files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# path.to.7z <- "7za"							# # only macintosh and *nix users need this line
# library(downloader)
# setwd( "C:/My Directory/HMDA/" )
# years.to.download <- 2014:2006
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Home%20Mortgage%20Disclosure%20Act/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


##################################################################################
# download all 2006 - 2014 microdata for the home mortgage disclosure act with R #
##################################################################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################################################
# macintosh and *nix users need 7za installed:  http://superuser.com/questions/548349/how-can-i-install-7zip-so-i-can-run-it-from-terminal-on-os-x  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# path.to.7z <- "7za"														# # this is probably the correct line for macintosh and *nix
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# the line above sets the location of the 7-zip program on your local computer. uncomment it by removing the `#` and change the directory if ya did #
#####################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# all 2006-2014 HMDA data files will be stored
# in a your current working directory
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/HMDA/" )

# remove the # in order to run this install.packages line only once
# install.packages( c( "MonetDB.R" , "MonetDBLite" , "SAScii" , "descr" , "downloader" , "digest" , "R.utils" ) )

# choose which hmda data sets to download
# uncomment this line to download all available data sets
# uncomment this line by removing the `#` at the front
# years.to.download <- 2014:2006
# if you have a big hard drive, hey why not download them all?

# remove the `#` in order to just download 2011
# years.to.download <- 2011


# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #


library(R.utils)		# load the R.utils package (counts the number of lines in a file quickly)
library(DBI)			# load the DBI package (implements the R-database coding)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(MonetDBLite)	# load MonetDBLite package (creates database files in R)
library(downloader)		# downloads and then runs the source() function on scripts from github
library(SAScii) 		# load the SAScii package (imports ascii data with a SAS script)


# load the download_cached and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url( 
	"https://raw.githubusercontent.com/ajdamico/asdfree/master/Download%20Cache/download%20cache.R" , 
	prompt = FALSE , 
	echo = FALSE 
)


# load the read.SAScii.monetdb() function,
# which imports ASCII (fixed-width) data files directly into a monet database
# using only a SAS importation script
source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/MonetDB/read.SAScii.monetdb.R" , prompt = FALSE )

# create five temporary files and also a temporary directory on the local disk
tf <- tempfile() ; tf2 <- tempfile() ; tf3 <- tempfile() ; tf4 <- tempfile() ; tf5 <- tempfile() ; td <- tempdir()


# download the layout files for the loan applications received (lar) and institutional records (ins) data tables
download_cached( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Home%20Mortgage%20Disclosure%20Act/lar_str.csv" , tf , FUN = download )
download_cached( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Home%20Mortgage%20Disclosure%20Act/ins_str.csv" , tf2 , FUN = download )


# configure a monetdb database for the hmda on windows #

# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )

# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite() , dbfolder )


# # # # run your analysis commands # # # #


# read in the loan application record structure file
lar_str <- read.csv( tf )
# paste all rows together into single strings
lar_col <- apply( lar_str , 1 , paste , collapse = " " )

# take a look at the `lar_str` and `lar_col` objects if you're curious
# just type 'em into the console to see what i mean ;)

# read in the loan application record structure file
ins_str <- read.csv( tf2 )
# paste all rows together into single strings
ins_col <- apply( ins_str , 1 , paste , collapse = " " )


# create an msa office sas importation script..
office.lines <- 
	"INPUT
	AS_OF_YEAR 4
	Agency_Code $ 1
	Respondent_ID $ 10
	MSA_MD $ 5
	MSA_MD_Description $ 50 
	;"
	
# ..save it to the local disk as a temporary file..
writeLines( office.lines , tf4 )

# ..and save the column names into a new object `office.names`
office.names <- tolower( parse.SAScii( tf4 )$varname )


# loop through each of the years to download..
for ( year in substr( years.to.download , 3 , 4 ) ){

	if( year == "14" ) one_two <- 'hmda' else one_two <- c( 'hmda' , 'pmic' )

	# loop through both the public (hmda) and private (pmic) data files..
	for ( pubpriv in one_two ){

		# reporter panel, msa_md with home, msa office do not exist in 2006, so skip it.
		if ( as.numeric( year ) > 6 ){

			# reporter panel read-in
			
			# the 2007, 2008, and 2009 reporter panel sas importation scripts are different from post-2009
			if ( as.numeric( year ) < 10 ){
				sas_ri <- "https://raw.githubusercontent.com/ajdamico/asdfree/master/Home%20Mortgage%20Disclosure%20Act/Reporter%20Panel%20Pre-2010.sas"
			} else {
				sas_ri <- "https://raw.githubusercontent.com/ajdamico/asdfree/master/Home%20Mortgage%20Disclosure%20Act/Reporter%20Panel%202010.sas"
			}
		
			# download the sas importation instructions to a temporary file on the local disk
			download_cached( sas_ri , tf3 , FUN = download )

			# construct the url of the current `ReporterPanel.zip` to download
			fn <- paste0( "https://www.ffiec.gov/" , pubpriv , "rawdata/OTHER/20" , year , toupper( pubpriv ) , "ReporterPanel.zip" )

			
			# read that temporary file directly into MonetDB,
			# using only the sas importation script
			read.SAScii.monetdb (
				fn ,			# the url of the file to download
				tf3 ,			# the 
				zipped = TRUE ,	# the ascii file is stored in a zipped file
				tl = TRUE ,		# convert all column names to lowercase
				tablename = paste( pubpriv , 'rep' , year , sep = "_" ) ,
				connection = db
			)

			# construct the url of the current `MSAOffice.zip`
			fn <- paste0( "https://www.ffiec.gov/" , pubpriv , "rawdata/OTHER/20" , year , toupper( pubpriv ) , "MSAOffice.zip" )
			
			# download that file..
			download_cached( fn , tf5 , mode = 'wb' )
			
			# ..and extract it to the temporary directory
			z <- unzip( tf5 , exdir = td )
			
			# read the entire file into RAM
			msa_ofc <-
				read.table(
					z ,
					header = FALSE ,
					quote = "\"" ,
					sep = '\t' ,
					# ..using the `office.names` extracted from the code above
					col.names = office.names
				)
				
			names( msa_ofc ) <- tolower( names( msa_ofc ) )
				
			# write the `msa` table into the database directly
			dbWriteTable( db , paste( pubpriv , 'msa' , year , sep = "_" ) , msa_ofc )
			
			# remove the table from memory
			rm( msa_ofc )
			
			# clear up RAM
			gc()
			
		} else z <- tempfile()
		
		# cycle through both institutional records and loan applications received microdata files
		for ( rectype in c( "institutionrecords" , "lar%20-%20National" ) ){

			# strip just the first three characters from `rectype`
			short.name <- substr( rectype , 1 , 3 )
		
			# construct a tablename.  for example: hmda_lar_11
			tablename <- paste( pubpriv , short.name , year , sep = "_" )
			
			# pull the structure construction
			col_str <- get( paste( short.name , "col" , sep = "_" ) )
			
			# design the monetdb table
			sql.create <- sprintf( paste( "CREATE TABLE" , tablename , "(%s)" ) , paste( col_str , collapse = ", " ) )

			# initiate the monetdb table
			dbSendQuery( db , sql.create )

			# find the url folder and the appropriate delimiter line for the monetdb COPY INTO command
			if ( short.name == "lar" ){
			
				folder <- "LAR/National"
				delim.line <- "' using delimiters ',','\\n','\"' NULL AS ''" 
				
			} else {
			
				folder <- "OTHER"
				delim.line <- "' using delimiters '\\t' NULL AS ''" 
			
			}
						
			# construct the full url path of the file to download
			fn <- paste0( "https://www.ffiec.gov/" , pubpriv , "rawdata/" , folder , "/20" , year , toupper( pubpriv ) , rectype , ".zip" )

			# clear out the temporary directory
			file.remove( list.files( td , full.names = TRUE ) )
			
			# download the url into a temporary file on your local disk
			download_cached( fn , tf , mode = 'wb' )

			# unzip the file's contents to the temporary directory
			# extract the file, platform-specific
			if ( .Platform$OS.type == 'windows' ){

				csv.file <- unzip( tf , exdir = td , overwrite = TRUE )

			} else {
			
				files.before <- list.files( td , full.names = TRUE )

				# build the string to send to the terminal on non-windows systems
				dos.command <- paste0( '"' , path.to.7z , '" x ' , tf , ' -aoa -o"' , td , '"' )

				system( dos.command )

				csv.file <- list.files( td , full.names = TRUE )

				csv.file <- csv.file[ !( csv.file %in% files.before ) ]
				
			}
			
			
			
			# construct the monetdb COPY INTO command
			sql.copy <- 
				paste0( 
					"copy " , 
					countLines( csv.file ) , 
					" records into " , 
					tablename , 
					" from '" , 
					normalizePath( csv.file ) , 
					delim.line
				)
				
			# actually execute the COPY INTO command
			dbSendQuery( db , sql.copy )
		
			# conversion of numeric columns incorrectly stored as character strings #
		
			# initiate a character vector containing all columns that should be numeric types
			revision.variables <- c( "sequencenumber" , "population" , "minoritypopulationpct" , "hudmedianfamilyincome" , "tracttomsa_mdincomepct" , "numberofowneroccupiedunits" , "numberof1to4familyunits" )

			# determine whether any of those variables are in the current table
			field.revisions <- dbListFields( db , tablename )[ tolower( dbListFields( db , tablename ) ) %in% revision.variables ]

			# loop through each of those variables
			for ( col.rev in field.revisions ){

				# add a new `temp_double` column in the data table
				dbSendQuery( db , paste( "ALTER TABLE" , tablename , "ADD COLUMN temp_double DOUBLE" ) )

				# copy over the contents of the character-typed column so long as the column isn't a textual missing
				dbSendQuery( db , paste( "UPDATE" , tablename , "SET temp_double = CAST(" , col.rev , " AS DOUBLE ) WHERE TRIM(" , col.rev , ") <> 'NA'" ) )
				
				# remove the character-typed column from the data table
				dbSendQuery( db , paste( "ALTER TABLE" , tablename , "DROP COLUMN" , col.rev ) )
				
				# re-initiate the same column name, but as a numeric type
				dbSendQuery( db , paste( "ALTER TABLE" , tablename , "ADD COLUMN" , col.rev , "DOUBLE" ) )
				
				# copy the corrected contents back to the original column name
				dbSendQuery( db , paste( "UPDATE" , tablename , "SET" , col.rev , "= temp_double" ) )
				
				# remove the temporary column from the data table
				dbSendQuery( db , paste( "ALTER TABLE" , tablename , "DROP COLUMN temp_double" ) )

			}

			# end of conversion of numeric columns incorrectly stored as character strings #

		}
		
		# now that all files have been imported for this hmda/pmic combination,
		# merge the lar and institution records for quicker access to lender information
		
		lar.tablename <- paste( pubpriv , 'lar' , year , sep = "_" )
		ins.tablename <- paste( pubpriv , 'ins' , year , sep = "_" )
		new.tablename <- paste( pubpriv , year , sep = "_" )
		
		# three easy steps #
		
		# step one: confirm the only intersecting fields are "respondentid" and "agencycode"
		# these are the merge fields, so nothing else can overlap
		
		stopifnot( 
			identical( 
				intersect( 
					dbListFields( db , lar.tablename ) , 
					dbListFields( db , ins.tablename ) 
				) , 
				c( 'respondentid' , 'agencycode' ) 
			) 
		)
		
		# step two: merge the two tables
		
		# extract the column names from the institution table
		ins.fields <- dbListFields( db , ins.tablename )
		
		# throw out the two merge fields
		ins.nomatch <- ins.fields[ !( ins.fields %in% c( 'respondentid' , 'agencycode' ) ) ]
		
		# add a "b." in front of every field name
		ins.b <- paste0( "b." , ins.nomatch )
		
		# separate all of them by commas into a single character string
		ins.string <- paste( ins.b , collapse = ", " )
		
		# construct the merge command
		sql.merge.command <-
			paste(
				"CREATE TABLE" , 
				new.tablename ,
				"AS SELECT a.* ," ,
				ins.string ,
				"FROM" ,
				lar.tablename ,
				"AS a INNER JOIN" ,
				ins.tablename ,
				"AS b ON a.respondentid = b.respondentid AND a.agencycode = b.agencycode WITH DATA"
			)
		
		# with your sql string built, execute the command
		dbSendQuery( db , sql.merge.command )
		
		# step three: confirm that the merged table contains the same record count
		stopifnot( 
			dbGetQuery( 
				db , 
				paste(
					'select count(*) from' ,
					new.tablename
				)
			) ==
			dbGetQuery( 
				db , 
				paste(
					'select count(*) from' ,
					lar.tablename
				)
			)
		)

		# # # # # # # # # # # # # # # # # #
		# # race and ethnicity recoding # #
		# # # # # # # # # # # # # # # # # #
		
		# number of minority races of applicant and co-applicant
		dbSendQuery( db , paste( 'ALTER TABLE' , new.tablename , 'ADD COLUMN app_min_cnt INTEGER' ) )
		dbSendQuery( db , paste( 'ALTER TABLE' , new.tablename , 'ADD COLUMN co_min_cnt INTEGER' ) )

		# sum up all four possibilities
		dbSendQuery( 
			db , 
			paste(
				'UPDATE' ,
				new.tablename ,
				'SET 
					app_min_cnt = 
					(
						( applicantrace1 IN ( 1 , 2 , 3 , 4 ) )*1 +
						( applicantrace2 IN ( 1 , 2 , 3 , 4 ) )*1 +
						( applicantrace3 IN ( 1 , 2 , 3 , 4 ) )*1 +
						( applicantrace4 IN ( 1 , 2 , 3 , 4 ) )*1 +
						( applicantrace5 IN ( 1 , 2 , 3 , 4 ) )*1
					)' 
			)
		)

		# same for the co-applicant
		dbSendQuery( 
			db , 
			paste(
				'UPDATE' ,
				new.tablename , 
				'SET 
					co_min_cnt = 
					(
						( coapplicantrace1 IN ( 1 , 2 , 3 , 4 ) )*1 +
						( coapplicantrace2 IN ( 1 , 2 , 3 , 4 ) )*1 +
						( coapplicantrace3 IN ( 1 , 2 , 3 , 4 ) )*1 +
						( coapplicantrace4 IN ( 1 , 2 , 3 , 4 ) )*1 +
						( coapplicantrace5 IN ( 1 , 2 , 3 , 4 ) )*1
					)' 
			)
		)

		# zero-one test of whether the applicant or co-applicant indicated white
		dbSendQuery( db , paste( 'ALTER TABLE' , new.tablename , 'ADD COLUMN appwhite INTEGER' ) )
		dbSendQuery( db , paste( 'ALTER TABLE' , new.tablename , 'ADD COLUMN cowhite INTEGER' ) )

		# check all five race categories for the answer
		dbSendQuery( 
			db , 
			paste(
				'UPDATE' ,
				new.tablename , 
				'SET 
					appwhite = 
					( 
						( ( applicantrace1 ) IN ( 5 ) )*1 + 
						( ( applicantrace2 ) IN ( 5 ) )*1 + 
						( ( applicantrace3 ) IN ( 5 ) )*1 + 
						( ( applicantrace4 ) IN ( 5 ) )*1 + 
						( ( applicantrace5 ) IN ( 5 ) )*1 
					)' 
			)
		)

		# same for the co-applicant
		dbSendQuery( 
			db , 
			paste(
				'UPDATE' ,
				new.tablename ,
				'SET 
					cowhite = 
					( 
						( ( coapplicantrace1 ) IN ( 5 ) )*1 + 
						( ( coapplicantrace2 ) IN ( 5 ) )*1 + 
						( ( coapplicantrace3 ) IN ( 5 ) )*1 + 
						( ( coapplicantrace4 ) IN ( 5 ) )*1 + 
						( ( coapplicantrace5 ) IN ( 5 ) )*1 
					)' 
			)
		)

		# if the applicant or co-applicant has a missing first race, set the above variables to missing as well
		dbSendQuery( db , paste( 'UPDATE' , new.tablename , 'SET app_min_cnt = NULL WHERE applicantrace1 IN ( 6 , 7 )' ) )
		dbSendQuery( db , paste( 'UPDATE' , new.tablename , 'SET appwhite = NULL WHERE applicantrace1 IN ( 6 , 7 )' ) )
		dbSendQuery( db , paste( 'UPDATE' , new.tablename , 'SET co_min_cnt = NULL WHERE coapplicantrace1 IN ( 6 , 7 , 8 )' ) )
		dbSendQuery( db , paste( 'UPDATE' , new.tablename , 'SET cowhite = NULL WHERE coapplicantrace1 IN ( 6 , 7 , 8 )' ) )

		# main race variable
		dbSendQuery( db , paste( 'ALTER TABLE' , new.tablename , 'ADD COLUMN race INTEGER' ) )

		# 7 indicates a loan by a white applicant and non-white co-applicant or vice-versa
		dbSendQuery( db , paste( 'UPDATE' , new.tablename , 'SET race = 7 WHERE ( appwhite = 1 AND app_min_cnt = 0 AND co_min_cnt > 0 ) OR ( cowhite = 1 AND co_min_cnt = 0 AND app_min_cnt > 0 )' ) )

		# 6 indicates the main applicant listed multiple non-white races
		dbSendQuery( db , paste( 'UPDATE' , new.tablename , 'SET race = 6 WHERE ( app_min_cnt > 1 ) AND ( race IS NULL )' ) )

		# for everybody else: if the first race listed by the applicant isn't white, use that.
		dbSendQuery( db , paste( "UPDATE" , new.tablename , "SET race = applicantrace1 WHERE ( applicantrace1 IN ( '1' , '2' , '3' , '4' ) ) AND ( app_min_cnt = 1 ) AND ( race IS NULL )" ) )
		# otherwise look to the second listed race
		dbSendQuery( db , paste( "UPDATE" , new.tablename , "SET race = applicantrace2 WHERE ( applicantrace2 IN ( '1' , '2' , '3' , '4' ) ) AND ( app_min_cnt = 1 ) AND ( race IS NULL )" ) )
		# otherwise confirm the applicant indicated he or she was white
		dbSendQuery( db , paste( 'UPDATE' , new.tablename , "SET race = 5 WHERE ( appwhite = 1 ) AND ( race IS NULL )" ) )

		# main ethnicity variable
		dbSendQuery( db , paste( 'ALTER TABLE' , new.tablename , 'ADD COLUMN ethnicity VARCHAR (255)' ) )

		# simple.  check the applicant's ethnicity
		dbSendQuery( db , paste( "UPDATE" , new.tablename , "SET ethnicity = 'Not Hispanic' WHERE applicantethnicity IN ( 2 )" ) )
		
		# simple.  check the applicant's ethnicity again
		dbSendQuery( db , paste( "UPDATE" , new.tablename , "SET ethnicity = 'Hispanic' WHERE applicantethnicity IN ( 1 )" ) )
		
		# overwrite the ethnicity variable if the main applicant indicates hispanic but the co-applicant does not.  or vice versa.
		dbSendQuery( db , paste( "UPDATE" , new.tablename , "SET ethnicity = 'Joint' WHERE ( applicantethnicity IN ( 1 ) AND coapplicantethnicity IN ( 2 ) ) OR ( applicantethnicity IN ( 2 ) AND coapplicantethnicity IN ( 1 ) )" ) )

		# # # # # # # # # # # # # # # # # # # # # # # # #
		# # finished with race and ethnicity recoding # #
		# # # # # # # # # # # # # # # # # # # # # # # # #
		
		# in general, use this new tablename for all your analyses,
		# since it's got institutional information already merged
		print( paste( new.tablename , "finito!" ) )
		
	}
	
}

# remove all files on your local disk
file.remove( tf , tf2 , tf3 , tf4 , tf5 , z , csv.file )



# the current working directory should now contain a MonetDB folder
# with all of the hmda contents of each year downloaded


# once complete, this script does not need to be run again.


# the current monet database should now contain
# all of the newly-added tables (in addition to meta-data tables)
dbListTables( db )		# print the tables stored in the current monet database to the screen


# set every table you've just created as read-only inside the database.
for ( this_table in dbListTables( db ) ) dbSendQuery( db , paste( "ALTER TABLE" , this_table , "SET READ ONLY" ) )


# disconnect from the current monet database
dbDisconnect( db , shutdown = TRUE )

