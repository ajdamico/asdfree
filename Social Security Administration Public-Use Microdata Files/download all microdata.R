# analyze survey data for free (http://asdfree.com) with the r language
# social security administration public-use microdata files
# 2001, 2004, and 2006 benefits, earnings, oasdi, and ssi files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/SSAPUMF/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Social%20Security%20Administration%20Public-Use%20Microdata%20Files/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
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



#########################################################################
# download all social security administration public-use file microdata #
#########################################################################


# set your  data directory
# use forward slashes instead of back slashes

# setwd( "C:/My Directory/SSAPUMF/" )

# initiate two temporary files and a temporary directory
tf <- tempfile() ; tf2 <- tempfile() ; td <- tempdir()


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# point-in-time supplemental security income 5-percent sample #
# december 2001 ssi                                           #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# This SSI Public-Use Microdata File consists of a 5 percent random, representative sample of records of SSI recipients who received a federal SSI payment in December 2001. All information in this file is as of December 2001; in particular, the payment amounts refer to the payment in that month. 

# data dictionary
# http://www.ssa.gov/policy/docs/microdata/ssr/ssr_dictionary.pdf

fn <- "http://www.ssa.gov/policy/docs/microdata/ssr/ssr_csv.zip"

# download and unzip the file onto the local computer
download.file( fn , tf , mode = 'wb' )
z <- unzip( tf , exdir = td )

# identify the comma-separated value (csv) file within the unzipped files
csv.file <- z[ grepl( '.csv' , z ) ]

# read the csv file into memory
ssi01 <- read.csv( csv.file )

# convert all column names to lowercase
names( ssi01 ) <- tolower( names( ssi01 ) )


# confirm approximately 320,000 records
# as specified under `content and sample design` on this page
# http://www.ssa.gov/policy/docs/microdata/ssr/index.html

nrow( ssi01 )

# save this data.frame into an R data file (.rda) on the local disk
save( ssi01 , file = "ssi01.rda" )

# open the `ssi01` data.frame in future R sessions with the command
# load( 'ssi01.rda' )

# remove the data.frame from memory and clear up RAM
rm( ssi01 )
gc()

# delete the downloaded (pre-import) files from the local disk
file.remove( z , tf )

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# old-age, survivors, disability insurance (oasdi) 1-percent sample #
# ssa master beneficiary record (mbr) file - december 2001 ssi      #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# This OASDI Public-Use Microdata File consists of a 1 percent random, representative sample of records of OASDI beneficiaries who were entitled to receive a Social Security (OASDI) benefit for December 2001. All information in this file is as of December 2001; in particular, the benefit amounts refer to the benefit for that month. 

# data dictionary
# http://www.ssa.gov/policy/docs/microdata/mbr/mbr_dictionary.pdf

fn <- "http://www.ssa.gov/policy/docs/microdata/mbr/mbr_csv.zip"

# download and unzip the file onto the local computer
download.file( fn , tf , mode = 'wb' )
z <- unzip( tf , exdir = td )

# identify the comma-separated value (csv) file within the unzipped files
csv.file <- z[ grepl( '.csv' , z ) ]

# read the csv file into memory
oasdi01 <- read.csv( csv.file )

# convert final two `factor` columns to integers
oasdi01[ , names( oasdi01 ) %in% c( 'lemba' , 'samba' ) ] <- 
	sapply( 
		oasdi01[ , names( oasdi01 ) %in% c( 'lemba' , 'samba' ) ] , 
		function( x ) as.integer( as.character( x ) ) 
	)

# confirm approximately 460,000 records
# as specified under `content and sample design` on this page
# http://www.ssa.gov/policy/docs/microdata/mbr/index.html

nrow( oasdi01 )

# save this data.frame into an R data file (.rda) on the local disk
save( oasdi01 , file = "oasdi01.rda" )


# open the `oasdi01` data.frame in future R sessions with the command
# load( 'oasdi01.rda' )

# remove the data.frame from memory and clear up RAM
rm( oasdi01 )
gc()

# delete the downloaded (pre-import) files from the local disk
file.remove( z , tf )


# # # # # # # # # # # # # # # # # # # #
# december 2004 benefits and earnings #
# point-in-time 1-percent sample      #
# # # # # # # # # # # # # # # # # # # #

# The Benefits and Earnings Public-Use File, 2004, consists of a 1 percent random, representative sample of records of Old-Age, Survivors, and Disability Insurance beneficiaries who were entitled to receive a Social Security (OASDI) benefit for December 2004, and all benefit information is as of December 2004. This file consists of two separate, linkable components—one with benefit information (the benefit subfile) and one with earnings information (the earnings subfile). Each record on these subfiles has a unique identifier that allows each earnings record to be linked to a corresponding benefit record. 

# benefits
fn <- "http://www.ssa.gov/policy/docs/microdata/earn/benefits04text.zip"

# download and unzip the file onto the local computer
download.file( fn , tf , mode = 'wb' )
z <- unzip( tf , exdir = td )

# identify the fixed-width (txt) file within the unzipped files
text.file <- z[ grepl( '.txt' , z ) ]

# read the fixed-width file into memory, using hardcoded column widths and names
bene04 <-
	read.fwf(
		text.file ,
		widths = c( 6 , 4 , 2 , 4 , 3 , 4 , 4 , 4 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 4 , 4 ) ,
		col.names = c( 'id' , 'yob' , 'sex' , 'yoce' , 'tob' , 'pia' , 'tpia' , 'mbc' , 'broa' , 'brads' , 'drci' ,  'dei' , 'deop' , 'otob' , 'debi' , 'lemba' , 'samba' )
	)

# convert final two `factor` columns to integers
bene04[ , names( bene04 ) %in% c( 'lemba' , 'samba' ) ] <- 
	sapply( 
		bene04[ , names( bene04 ) %in% c( 'lemba' , 'samba' ) ] , 
		function( x ) as.integer( as.character( x ) ) 
	)
	

# confirm exactly 473,366 records
# as specified on pdf page 10 of the earnings dictionary
# http://www.ssa.gov/policy/docs/microdata/earn/earn_dictionary.pdf#page=10
nrow( bene04 )


# save this data.frame into an R data file (.rda) on the local disk
save( bene04 , file = "bene04.rda" )

# open the `bene04` data.frame in future R sessions with the command
# load( 'bene04.rda' )

# remove the data.frame from memory and clear up RAM
rm( bene04 )
gc()

# delete the downloaded (pre-import) files from the local disk
file.remove( z , tf )


# earnings
fn <- "http://www.ssa.gov/policy/docs/microdata/earn/earnings04text.zip"

# download and unzip the file onto the local computer
download.file( fn , tf , mode = 'wb' )
z <- unzip( tf , exdir = td )

# identify the fixed-width (txt) file within the unzipped files
text.file <- z[ grepl( '.txt' , z ) ]

# in its current state, this text file is not readable and requires some re-shaping.
# take a look at the first twenty records on the screen to see what i mean:
readLines( text.file , n = 20 )
# notice what's going on here: the `ssteYYYY` fields started wrapping after 1998
# so 1999 - 2003 each have their own line, incorrectly.  these need to be reshaped and merged back

# create a file connection to the text file
incon <- file( text.file , "r" ) 

# create a second file connection to the secondary temporary file
outcon <- file( tf2 , "w" ) 


# read in six lines at a time
while( length( six.lines <- readLines( incon , 6 ) ) > 0 ){
	
	# stitch them all together into a single line
	single.line <- paste( six.lines , collapse = "" )
	
	# write each line to the second temporary file
	writeLines( single.line , outcon )
}

# read the fixed-width file into memory, using hardcoded column widths and names
earn04 <-
	read.fwf(
		tf2 ,
		widths = c( 6 , 3 , 5 , rep( 5 , 53 ) ) ,
		col.names = c( 'id' , 'tc' , 'ae3750' , paste0( 'sste' , 1951:2003 ) )
	)
 

# confirm exactly 472,511 records
# as specified on pdf page 10 of the earnings dictionary
# http://www.ssa.gov/policy/docs/microdata/earn/earn_dictionary.pdf#page=10
nrow( earn04 )


# save this data.frame into an R data file (.rda) on the local disk
save( earn04 , file = "earn04.rda" )

# open the `earn04` data.frame in future R sessions with the command
# load( 'earn04.rda' )

# remove the data.frame from memory and clear up RAM
rm( earn04 )
gc()

# close both the in and outward file connections
close( incon )
close( outcon )

# delete the downloaded (pre-import) files from the local disk
file.remove( z , tf )



# # # # # # # # # # # # # # # # # # # # # #
# december 2006 demographics and earnings #
# point-in-time 1-percent sample          #
# # # # # # # # # # # # # # # # # # # # # #

# The 2006 Earnings Public-Use File (EPUF) is a systematic 1 percent random sample of all Social Security numbers issued prior to January 1, 2007. With a few minor exceptions, all of the values for the data fields in this file are from the Summary Segment of SSA’s Master Earnings File, the administrative file used to determine an individual’s eligibility status under the Social Security program and the amount of benefits paid out.

# 2006 demographics and earnings
fn <- "http://www.ssa.gov/policy/docs/microdata/epuf/epuf2006_csv_files.zip"

# download and unzip the file onto the local computer
download.file( fn , tf , mode = 'wb' )
z <- unzip( tf , exdir = td )

# identify the annual and demographic files within the unzipped files
annual.file <- z[ grepl( 'ANNUAL' , z ) ]
demo.file <- z[ grepl( 'DEMOGRAPHIC' , z ) ]

# read the csv file into memory
ann06 <- read.csv( annual.file )

# convert all column names to lowercase
names( ann06 ) <- tolower( names( ann06 ) )

# confirm exactly 60,326,474 records
# as specified on pdf page 1 of the earnings dictionary
# http://www.ssa.gov/policy/docs/microdata/epuf/epuf_dictionary.pdf
nrow( ann06 )


# save this data.frame into an R data file (.rda) on the local disk
save( ann06 , file = 'ann06.rda' )

# open the `ann06` data.frame in future R sessions with the command
# load( 'ann06.rda' )


# super-special bonus note: if you have sufficient RAM,
# you can quickly re-shape this file from one-record-per-person-per-year to
# one-record-per-person with the commands
# library(reshape2)
# ann06.person_level <- reshape( ann06 , idvar = 'id' , timevar = 'year_earn' , direction = 'wide' )
# but - this is important - this will overload many computers.  before you even try it out, make sure it's what you want
# by using a subset (only the top 1,000 records) and looking carefully at the new structure like this:
# reshape( ann06[ 1:1000 , ] , idvar = 'id' , timevar = 'year_earn' , direction = 'wide' )
#
# what might be more useful, however, is person-level sums
# library(sqldf)
# ann06.lifetime_earnings <- sqldf( 'select id, sum( annual_earnings ) as lifetime_earnings from ann06 group by id' )
# both `ann06.person_level` and `ann06.lifetime_earnings` can be merged with `demo06` (you likely want all = TRUE)

# super-special bonus note for RAM-cheapskates only #
# # load the sqldf package to not overload memory
# library(sqldf)
# # read this file into a database directly
# read.csv.sql( annual.file , sql = "create table main.ann06 as select * from file", dbname = 'ssapumf.db' )
# # perform the same query as above, without overloading memory usage in the slightest
# same.result.as.above <- sqldf( 'select id, sum( annual_earnings ) as lifetime_earnings from ann06 group by id' , dbname = 'ssapumf.db' )


# remove the data.frame from memory and clear up RAM
rm( ann06 )
gc()


# read the csv file into memory
demo06 <- read.csv( demo.file )

# convert all column names to lowercase
names( demo06 ) <- tolower( names( demo06 ) )

# confirm exactly 4,84,254 records
# as specified on pdf page 1 of the earnings dictionary
# http://www.ssa.gov/policy/docs/microdata/epuf/epuf_dictionary.pdf
nrow( demo06 )

# save this data.frame into an R data file (.rda) on the local disk
save( demo06 , file = 'demo06.rda' )

# open the `demo06` data.frame in future R sessions with the command
# load( 'demo06.rda' )

# remove the data.frame from memory and clear up RAM
rm( demo06 )
gc()

# delete the downloaded (pre-import) files from the local disk
file.remove( z , tf )


# print a reminder: set the directory you just saved everything to as read-only!
message( paste( "all done.  you should set" , getwd() , "read-only so you don't accidentally alter these files." ) )

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
