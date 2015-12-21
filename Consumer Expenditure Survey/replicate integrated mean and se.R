# analyze survey data for free (http://asdfree.com) with the r language
# consumer expenditure survey
# replication of "2011 Integrated Mean and SE.lst" table created with the "Integrated Mean and SE.sas" example program
# using 2011 public use microdata


# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/CES/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Consumer%20Expenditure%20Survey/replicate%20integrated%20mean%20and%20se.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# this r script will replicate the massive table in the folder "Programs 2011\SAS\2011 Integrated Mean and SE.lst" inside the bls documentation
# http://www.bls.gov/cex/pumd/documentation/documentation11.zip


# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###################################################################################################################
# prior to running this replication script, all ces 2011 public use microdata files must be loaded as R data      #
# files (.rda) on the local machine. running the "2010-2011 ces - download.R" script will create these files.     #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/asdfree/blob/master/Consumer%20Expenditure%20Survey/download%20all%20microdata.R      #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will save a number of .rda files in C:/My Directory/CES/2011/ (or the working directory was chosen) #
###################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


#####################################################################################################
# replicate the 2011 Consumer Expenditure Survey (CES) integrated mean and se program output with R #
#####################################################################################################


# set your working directory.
# the CES 2011 R data files (.rda) should have been
# stored in a year-specific directory within this folder.
# so if the file "fmli111x.rda" exists in the directory "C:/My Directory/CES/2011/intrvw/" 
# then the working directory should be set to "C:/My Directory/CES/"
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/CES/" )
# ..in order to set your current working directory


# turn off scientific notation in most output

options( scipen = 20 )


library(stringr) 		# load stringr package (manipulates character strings easily)
library(reshape2)		# load reshape2 package (transposes data frames quickly)
library(sqldf)			# load the sqldf package (enables sql queries on data frames)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(MonetDBLite)	# load MonetDBLite package (creates database files in R)


# # # # # # # # # # # # # # # # # # # #
# this replication example uses 2011  #
# note: some ucc codes and other variables may change year-to-year
# so running this code to replicate the "Integrated Mean and SE.sas" program may result in small bugs or errorss
# for an example of year-specific coding, ctrl+f for "710110" in the code below.  this ucc code likely changes between years
year <- 2011


############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #


# pull the last two digits of the year variable into a separate string
yr <- substr( year , 3 , 4 )


# create a new function that reads in quarterly R data files (.rda)
# previously created by the "2010-2011 ces - download.R" script
read.in.qs <- 
	function( 
		# define the function parameters..
		filestart , 	# the start of the filename (skipping year, quarter, and any x's)
		filefolder , 	# the path within the current working directory
		four 			# does this file type contain four quarterly files, or five?  set TRUE for four, FALSE for five.
	){
	
	# if there are four quarterly files to read in..
	if ( four ){

		# load all four
		
		load( paste0( "./" , filefolder , "/" , filestart , yr , "1.rda" ) )
		load( paste0( "./" , filefolder , "/" , filestart , yr , "2.rda" ) )
		load( paste0( "./" , filefolder , "/" , filestart , yr , "3.rda" ) )
		load( paste0( "./" , filefolder , "/" , filestart , yr , "4.rda" ) )

		# stack them on top of each other into a new data frame called x
		x <- rbind( 
			get( paste0( filestart , yr , "1" ) ) ,
			get( paste0( filestart , yr , "2" ) ) ,
			get( paste0( filestart , yr , "3" ) ) ,
			get( paste0( filestart , yr , "4" ) ) 
		)
		
	} else {

		# load all five
		
		# note the first will contain an x in the filename
		load( paste0( "./" , filefolder , "/" , filestart , yr , "1x.rda" ) )
		load( paste0( "./" , filefolder , "/" , filestart , yr , "2.rda" ) )
		load( paste0( "./" , filefolder , "/" , filestart , yr , "3.rda" ) )
		load( paste0( "./" , filefolder , "/" , filestart , yr , "4.rda" ) )
		# note the fifth will be from the following year's first quarter
		load( paste0( "./" , filefolder , "/" , filestart , as.numeric( yr ) + 1 , "1.rda" ) )

		# stack them on top of each other into a new data frame called x
		x <- 
			rbind( 
				get( paste0( filestart , yr , "1x" ) ) ,
				get( paste0( filestart , yr , "2" ) ) ,
				get( paste0( filestart , yr , "3" ) ) ,
				get( paste0( filestart , yr , "4" ) ) ,
				get( paste0( filestart , as.numeric( yr ) + 1 , "1" ) )
			)
			
	}

	# return the four or five combined data frames
	# as a single, stacked data frame
	x
}


# alter the current working directory to include the current analysis year
# ..instead of "C:/My Directory/CES/" use "C:/My Directory/CES/2011"
setwd( paste( getwd() , year , sep = "/" ) )


# designate a temporary folder to store a temporary database
temp.db <- tempdir()


# notes from the "Integrated Mean and SE.sas" file about this section: 

  # /***************************************************************************/
  # /* STEP1: READ IN THE STUB PARAMETER FILE AND CREATE FORMATS               */
  # /* ----------------------------------------------------------------------- */
  # /* 1 CONVERTS THE STUB PARAMETER FILE INTO A LABEL FILE FOR OUTPUT         */
  # /* 2 CONVERTS THE STUB PARAMETER FILE INTO AN EXPENDITURE AGGREGATION FILE */
  # /* 3 CREATES FORMATS FOR USE IN OTHER PROCEDURES                           */
  # /***************************************************************************/


# find the filepath to the IntStubYYYY.txt file
sf <- paste0( "./docs/Programs " , year , "/IntStub" , year , ".txt" )

# create a temporary file on the local disk..
tf <- tempfile()

# read the IntStubYYYY.txt file into memory
# in order to make a few edits
st <- readLines( sf )

# only keep rows starting with a one
st <- st[ substr( st , 1 , 1 ) == '1' ]

# replace these two tabs with seven spaces instead
st <- gsub( "\t\t" , "       " , st )

# save to the temporary file created above
writeLines( st , tf )

# read that temporary file (the slightly modified IntStubYYYY.txt file)
# into memory as an R data frame
stubfile <- 
	read.fwf( 
		tf , 
		width = c( 1 , -2 , 1 , -2 , 60 , -3 , 6 , -4 , 1 , -5 , 7 ) ,
		col.names = c( "type" , "level" , "title" , "ucc" , "survey" , "group" )
	)

# eliminate all whitespace (on both sides) in the group column
stubfile$group <- str_trim( as.character( stubfile$group ) )
	
# subset the stubfile to only contain records
# a) in the four groups below
# b) where the survey column isn't "T"
stubfile <- 
	subset( 
		stubfile , 
		group %in% c( "CUCHARS" , "FOOD" , "EXPEND" , "INCOME" ) &
		survey != "T"
	)

# remove the rownames from the stubfile
# (after subsetting, rows maintain their original numbering.
# this action wipes it out.)
rownames( stubfile ) <- NULL

# create a new count variable starting at 10,000
stubfile$count <- 9999 + ( 1:nrow( stubfile ) )

# create a new line variable by concatenating the count and level variables
stubfile$line <- paste0( stubfile$count , stubfile$level )


# start with a character vector with ten blank strings..
curlines <- rep( "" , 10 )

# initiate a matrix containing the line numbers of each expenditure category
aggfmt1 <- matrix( nrow = nrow( stubfile ) , ncol = 10 )

# loop through each record in the stubfile..
for ( i in seq( nrow( stubfile ) ) ){

	# if the 'ucc' variable is numeric (that is, as.numeric() does not return a missing NA value)
	if ( !is.na( as.numeric( as.character( stubfile[ i , "ucc" ] ) ) ) ){
		
		# save the line number as the last element in the character vector
		curlines[ 10 ] <- stubfile[ i , "line" ]
	
	# otherwise blank it out
	} else curlines[ 10 ] <- ""

	# store the current line and level in separate atomic variables
	curlevel <- stubfile[ i , "level" ]
	curline <- stubfile[ i , "line" ]

	# write the current line inside the length-ten character vector
	curlines[ curlevel ] <- curline
	
	# if the current level is 1-8, blank out everything above it up to nine
	if ( curlevel < 9 ) curlines[ (curlevel+1):9 ] <- ""

	# remove actual value
	savelines <- curlines
	savelines[ curlevel ] <- ""
	
	# overwrite the entire row with the character vector of length ten
	aggfmt1[ i , ] <- savelines
}

# convert the matrix to a data frame..
aggfmt1 <- data.frame( aggfmt1 )

# ..and name its columns line1 - line10
names( aggfmt1 ) <- paste0( "line" , 1:10 )

# tack on the ucc and line columns from the stubfile (which has the same number of records)
aggfmt1 <- cbind( aggfmt1 , stubfile[ , c( "ucc" , "line" ) ] )

# remove records where the ucc is numeric
aggfmt1 <- subset( aggfmt1 , !is.na( as.numeric( as.character( ucc ) ) ) )

# order the data frame by ucc
aggfmt1 <- aggfmt1[ order( aggfmt1$ucc ) , ]

# rename line to compare
aggfmt1$compare <- aggfmt1$line
aggfmt1$line <- NULL

# reset the row names/numbers
rownames( aggfmt1 ) <- NULL

# transpose the data, holding ucc and compare
aggfmt2 <- melt(aggfmt1, id=c("ucc","compare")) 
names( aggfmt2 )[ 4 ] <- "line"

# retain the ucc-to-line crosswalk wherever the 'line' variable is not blank
aggfmt <- subset( aggfmt2 , line != "" , select = c( "ucc" , "line" ) )

# re-order the data frame by ucc
aggfmt <- aggfmt[ order( aggfmt$ucc ) , ]


# notes from the "Integrated Mean and SE.sas" file about this section: 

  # /***************************************************************************/
  # /* STEP2: READ IN ALL NEEDED DATA                                          */
  # /* ----------------------------------------------------------------------- */
  # /* 1 READ IN THE INTERVIEW AND DIARY FMLY FILES & CREATE MO_SCOPE VARIABLE */
  # /* 2 READ IN THE INTERVIEW MTAB/ITAB AND DIARY EXPN/DTAB FILES             */
  # /* 3 MERGE FMLY AND EXPENDITURE FILES TO DERIVE WEIGHTED EXPENDITURES      */
  # /***************************************************************************/


# use the read.in.qs (read-in-quarters) function (defined above)
# to read in the four 'fmld' files in the diary folder
# this contains all family diary records
d <- read.in.qs( "fmld" , "diary" , TRUE )

# clear up RAM
gc()


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# read in the five quarters of family data files (fmli)
# perform this by hand (as opposed to with the read.in.qs() function)
# because of the large number of exceptions for these five files

# load all five R data files (.rda)
load( paste0( "./intrvw/fmli" , yr , "1x.rda" ) )
load( paste0( "./intrvw/fmli" , yr , "2.rda" ) )
load( paste0( "./intrvw/fmli" , yr , "3.rda" ) )
load( paste0( "./intrvw/fmli" , yr , "4.rda" ) )
load( paste0( "./intrvw/fmli" , as.numeric( yr ) + 1 , "1.rda" ) )

# copy the fmliYY1x data frame to another data frame 'x'
x <- get( paste0( "fmli" , yr , "1x" ) )

# create an 'high_edu' column containing all missings
x$high_edu <- NA

# add a quarter variable
x$qtr <- 1

# copy the x data frame to a third data frame 'fmli1'
assign( "fmli1" , x )

# loop through the second, third, and fourth fmli data frames
for ( i in 2:4 ){

	x <- get( paste0( "fmli" , yr , i ) )

	# add a quarter variable (2, 3, then 4)
	x$qtr <- i
	
	# copy the data frame over to fmli#
	assign( paste0( "fmli" , i ) , x )
}

# repeat the steps above on the fifth quarter (which uses the following year's first quarter of data)
x <- get( paste0( "fmli" , as.numeric( yr ) + 1 , "1" ) )
x$qtr <- 5
assign( "fmli5" , x )

# stack all five fmli# files together, into a large single data frame 'f'
f <- rbind( fmli1 , fmli2 , fmli3 , fmli4 , fmli5 )

# delete all of the independent data frames from memory
rm( fmli1 , fmli2 , fmli3 , fmli4 , fmli5 , x )

# also delete the data frames loaded by the five load() function calls above
rm( 
	list = 
		c( 
			paste0( "fmli" , yr , "1x" ) , 
			paste0( "fmli" , yr , 2:4 ) ,
			paste0( "fmli" , as.numeric( yr ) + 1 , "1" )
		)
)

# clear up RAM
gc()

# create a mo_scope variable in this large new family data frame
f <- 
	transform( 
		f ,
		mo_scope = 
			# the first quarter should be interview month minus one
			ifelse( qtr %in% 1 , as.numeric( qintrvmo ) - 1 ,
			# the final quarter should be four minus the interview month
			ifelse( qtr %in% 5 , ( 4 - as.numeric( qintrvmo )  ) ,
			# all other quarters should have a 3
				3 ) ) 
	)

# the source column for family records should be "I" (interview) throughout
f$source <- "I"
	
# the mo_scope variable for the 'd' (fmld) data frame should be 3 for all records
d$mo_scope <- 3
# ..and the source should be "D" throughout
d$source <- "D"

# create a character vector containing 45 variable names (wtrep01, wtrep02, ... wtrep44 and finlwt21)
wtrep <- c( paste0( "wtrep" , str_pad( 1:44 , 2 , pad = "0" ) ) , "finlwt21" )

# create a second character vector containing 45 variable names (repwt1, repwt2, .. repwt44, repwt45)
repwt <- paste0( "repwt" , 1:45 )

# create a third character vector that will be used to define which columns to keep
f.d.vars <- c( wtrep , "mo_scope" , "inclass" , "newid" , "source" )

# stack the family interview and diary records together,
# keeping only the 45 wtrep columns, plus the additional four written above
fmly <- rbind( f[ , f.d.vars ] , d[ , f.d.vars ] )

# remove data frames 'f' and 'd' from memory
rm( f , d )

# clear up RAM
gc()


# loop through the 45 wtrep variables in the newly-stacked fmly data frame..
for ( i in 1:45 ){

	# convert all columns to numeric
	fmly[ , wtrep[ i ] ] <- as.numeric( as.character( fmly[ , wtrep[ i ] ] ) )
	
	# replace all missings with zeroes
	fmly[ is.na( fmly[ , wtrep[ i ] ] ) , wtrep[ i ] ] <- 0
	
	# multiply by months in scope, then divide by 12 (months)
	fmly[ , repwt[ i ] ] <- ( fmly[ , wtrep[ i ] ] * fmly[ , "mo_scope" ] / 12 )
}


# read in the expenditure files..
expd <- read.in.qs( "expd" , "diary" , TRUE )
dtbd <- read.in.qs( "dtbd" , "diary" , TRUE )
mtbi <- read.in.qs( "mtbi" , "intrvw" , FALSE )
itbi <- read.in.qs( "itbi" , "intrvw" , FALSE )

# clear up RAM
gc()

# copy (effectively rename) the 'amount' and 'value' columns to 'cost'
dtbd$cost <- dtbd$amount
itbi$cost <- itbi$value

# limit the itbi and mtbi (interview) data frames to records from the current year with pubflags of two
expend.itbi <- subset( itbi , pubflag == 2 & refyr == 2011 )
expend.mtbi <- subset( mtbi , pubflag == 2 & ref_yr == 2011 )

# choose which columns to keep when stacking these data frames
edmi.vars <- c( "newid" , "ucc" , "cost" )

# stack the itbi and mtbi files
expend.im <- 
	rbind( 
		expend.itbi[ , edmi.vars ] , 
		expend.mtbi[ , edmi.vars ] 
	)

# create a new 'source' column, with "I" (interview) throughout
expend.im$source <- "I"

# multiply the 'cost' column by 4 whenever the ucc code is 710110
expend.im <- 
	transform( 
		expend.im , 
		cost = ifelse( ucc == '710110' , cost * 4 , cost )
	)
	
# limit the expenditure diary to the same short list of variables, and only with a pubflag of two
expend.expd <- subset( expd , pub_flag == 2 , select = edmi.vars )

# create a new 'source' column, with "D" (diary) throughout
expend.expd$source <- "D"

# multiply the diary records' cost column by 13
expend.expd$cost <- expend.expd$cost * 13

# stack the interview and diary expenditure records together
expend <- rbind( expend.im , expend.expd )

# remove all of these smaller R data frames from memory
rm( itbi , mtbi , expend.itbi , expend.mtbi , expend.im , expend.expd )

# clear up RAM
gc()

# order the expenditure data frame by the unique consumer unit id (newid)
expend <- expend[ order( expend$newid ) , ]

# note: merging the family and expenditure files will overload RAM on smaller machines
# therefore, the following database (db) commands use sql to avoid memory issues

# create a new connection to the temporary database file (defined above)
db <- dbConnect( SQLite() , temp.db )

# store the family data frame in that database
dbWriteTable( db , 'fmly' , fmly , row.names = FALSE )

# create an index on the fmly table to drastically speed up future queries
dbSendQuery( db , "CREATE INDEX nsf ON fmly ( newid , source )" )

# store the expenditure data frame in that database as well
dbWriteTable( db , 'expend' , expend , row.names = FALSE )

# create an index on the expend table to drastically speed up future queries
dbSendQuery( db , "CREATE INDEX nse ON expend ( newid , source )" )

# create a character vector rcost1 - rcost45
rcost <- paste0( "rcost" , 1:45 )

# partially build the sql string, multiply each 'wtrep##' variable by 'cost' and rename it 'rcost##'
wtrep.cost <- paste0( "( b.cost * a." , wtrep , " ) as " , rcost , collapse = ", " )

# build the entire sql string..
sql.line <- 
	paste( 
		# creating a new 'pubfile' table, saving a few columns from each table
		"create table pubfile as select a.newid , a.inclass , b.source , b.ucc ," ,
		wtrep.cost ,
		# joining the family and expenditure tables on two fields
		"from fmly as a inner join expend as b on a.newid = b.newid AND a.source = b.source" 
	)

# execute that sql query
dbSendQuery( 
	db , 
	sql.line
)
  
# create an index on the pubfile table to drastically speed up future queries
dbSendQuery( db , "CREATE INDEX isu ON pubfile ( inclass , source , ucc )" )


# notes from the "Integrated Mean and SE.sas" file about this section: 

  # /***************************************************************************/
  # /* STEP3: CALCULATE POPULATIONS                                            */
  # /* ----------------------------------------------------------------------- */
  # /*  SUM ALL 45 WEIGHT VARIABLES TO DERIVE REPLICATE POPULATIONS            */
  # /*  FORMATS FOR CORRECT COLUMN CLASSIFICATIONS                             */
  # /***************************************************************************/


# create a character vector containing 45 variable names (rpop1, rpop2, ... rpop44, rpop45)
rpop <- paste0( "rpop" , 1:45 )

# partially build the sql string, sum each 'repwt##' variable into 'rpop##'
rpop.sums <- paste( "sum( " , repwt , ") as " , rpop , collapse = ", " )

# partially build the sql string, sum each 'rcost##' variable into the same column name, 'rcost##'
rcost.sums <- paste( "sum( " , rcost , ") as " , rcost , collapse = ", " )

# create a total population sum (not grouping by 'inclass' -- instead assigning everyone to '10')
pop.all <- dbGetQuery( db , paste( "select 10 as inclass, source, " , rpop.sums , "from fmly group by source" ) )

# create a population sum, grouped by inclass (the income class variable)
pop.by <- dbGetQuery( db , paste( "select inclass, source," , rpop.sums , "from fmly group by inclass, source" ) )

# stack the overall and grouped-by population tables
pop <- rbind( pop.all , pop.by )


# notes from the "Integrated Mean and SE.sas" file about this section: 

  # /***************************************************************************/
  # /* STEP4: CALCULATE WEIGHTED AGGREGATE EXPENDITURES                        */
  # /* ----------------------------------------------------------------------- */
  # /*  SUM THE 45 REPLICATE WEIGHTED EXPENDITURES TO DERIVE AGGREGATES/UCC    */
  # /*  FORMATS FOR CORRECT COLUMN CLASSIFICATIONS                             */
  # /***************************************************************************/

  
# create the right hand side of the aggregate expenditures table
aggright <-
	# use a sql query from the temporary database (.db) file
	dbGetQuery( 
		db , 
		paste( 
			# group by inclass (income class) and a few other variables
			"select inclass, source, ucc," , 
			rcost.sums , 
			"from pubfile group by source , inclass , ucc" ,
			# the 'union' command stacks the grouped data (above) with the overall data (below)
			"union" ,
			# do not group by inclass, instead assign everyone as an inclass of ten
			"select '10' as inclass, source , ucc," , 
			rcost.sums , 
			"from pubfile group by source , ucc" 
		)
	)


# disconnect from the temporary database (.db) file
dbDisconnect( db )

# delete that temporary database file from the local disk
unlink( temp.db , recursive = TRUE )

# create three character vectors containing every combination of..

# the expenditure table's source variable
so <- names( table( expend$source ) )
# the expenditure table's ucc variable
uc <- names( table( expend$ucc ) )
# the family table's inclass (income class) variable
cl <- names( table( fmly[ , 'inclass' ] ) )
# add a '10' - overall category to the inclass variable
cl <- c( cl , "10" )

# now create a data frame containing every combination of every variable in the above three vectors
# (this matches the 'COMPLETETYPES' option in a sas proc summary call
aggleft <- expand.grid( so , uc , cl )

# name the columns in this new data frame appropriately
names( aggleft ) <- c( 'source' , 'ucc' , 'inclass' )

# perform a left-join, keeping all records in the left hand side, even ones without a match
agg <- merge( aggleft , aggright , all.x = TRUE )


# notes from the "Integrated Mean and SE.sas" file about this section: 

  # /***************************************************************************/
  # /* STEP5: CALCULTATE MEAN EXPENDITURES                                     */
  # /* ----------------------------------------------------------------------- */
  # /* 1 READ IN POPULATIONS AND LOAD INTO MEMORY USING A 3 DIMENSIONAL ARRAY  */
  # /*   POPULATIONS ARE ASSOCIATED BY INCLASS, SOURCE(t), AND REPLICATE(j)    */
  # /* 2 READ IN AGGREGATE EXPENDITURES FROM AGG DATASET                       */
  # /* 3 CALCULATE MEANS BY DIVIDING AGGREGATES BY CORRECT SOURCE POPULATIONS  */
  # /*   EXPENDITURES SOURCED FROM DIARY ARE CALULATED USING DIARY POPULATIONS */
  # /*   WHILE INTRVIEW EXPENDITURES USE INTERVIEW POPULATIONS                 */
  # /* 4 SUM EXPENDITURE MEANS PER UCC INTO CORRECT LINE ITEM AGGREGATIONS     */
  # /***************************************************************************/

# create a character vector containing mean1, mean2, ... , mean45
means <- paste0( "mean" , 1:45 )

# merge the population and weighted aggregate data tables together
avgs1 <- merge( pop , agg )

# loop through all 45 weights..
for ( i in 1:45 ){
	# calculate the new 'mean##' variable by dividing the expenditure (rcost##) by the population (rpop##) variables
	avgs1[ , means[ i ] ] <- ( avgs1[ , rcost[ i ] ] / avgs1[ , rpop[ i ] ] )
	
	# convert all missing (NA) mean values to zeroes
	avgs1[ is.na( avgs1[ , means[ i ] ] ) , means[ i ] ] <- 0
}

# keep only a few columns, plus the 45 'mean##' columns
avgs1 <- avgs1[ , c( "source" , "inclass" , "ucc" , means ) ]

# partially build the sql string, sum each 'mean##' variable into the same column name, 'mean##'
avgs.sums <- paste( "sum( " , means , ") as " , means , collapse = ", " )

# merge on the 'line' column from the 'aggfmt' data frame
avgs3 <- merge( avgs1 , aggfmt )

# remove duplicate records from the data frame
avgs3 <- sqldf( 'select distinct * from avgs3' )

# construct the full sql string, grouping each sum by inclass (income class) and line (expenditure category)
sql.avgs <- paste( "select inclass, line," , avgs.sums , "from avgs3 group by inclass, line" )

# execute the sql string
avgs2 <- sqldf( sql.avgs )


# notes from the "Integrated Mean and SE.sas" file about this section: 

  # /***************************************************************************/
  # /* STEP6: CALCULTATE STANDARD ERRORS                                       */
  # /* ----------------------------------------------------------------------- */
  # /*  CALCULATE STANDARD ERRORS USING REPLICATE FORMULA                      */
  # /***************************************************************************/

# copy the avgs2 table over to a new data frame named 'se'
se <- avgs2

# create a character vector containing 44 strings, diff1, diff2, .. diff44
diffs <- paste0( "diff" , 1:44 )

# loop through the numbers 1-44, and calculate the diff column as the square of the difference between the current mean and the 45th mean
for ( i in 1:44 ) se[ , diffs[ i ] ] <- ( se[ , means[ i ] ] - se[ , "mean45" ] )^2
# for example, when i is 30, diff30 = ( mean30 - mean45 )^2

# save the 45th mean as the overall mean
se$mean <- se$mean45

# sum the differences, divide by 44 to calculate the variance,
# then take the square root to calculate the standard error
se$se <- sqrt( rowSums( se[ , diffs ] ) / 44 )

# retain only a few important columns in the se data frame
se <- se[ , c( "inclass" , "line" , "mean" , "se" ) ]


# notes from the "Integrated Mean and SE.sas" file about this section: 

  # /***************************************************************************/
  # /* STEP7: TABULATE EXPENDITURES                                            */
  # /* ----------------------------------------------------------------------- */
  # /* 1 ARRANGE DATA INTO TABULAR FORM                                        */
  # /* 2 SET OUT INTERVIEW POPULATIONS FOR POPULATION LINE ITEM                */
  # /* 3 INSERT POPULATION LINE INTO TABLE                                     */
  # /* 4 INSERT ZERO EXPENDITURE LINE ITEMS INTO TABLE FOR COMPLETENESS        */
  # /***************************************************************************/


# transpose the se data frame by line and inclass, storing the value of the mean column
# save this result into a new data frame 'tab1m'
tab1m <- dcast( se , line ~ inclass , mean , value.var = "mean" )

# transpose the se data frame by line and inclass, storing the value of the se column
# save this result into a new data frame 'tab1s'
tab1s <- dcast( se , line ~ inclass , mean , value.var = "se" )

# create new columns in each data table, designating 'mean' and 'se'
tab1m$estimate <- "MEAN"
tab1s$estimate <- "SE"

# stack the mean and se tables together, into a new data frame called tab1
tab1 <- rbind( tab1m , tab1s )

# add the text 'inclass' in front of each column containing income class-specific values
names( tab1 )[2:(ncol(tab1)-1)] <- paste0( "inclass" , names( tab1 )[2:(ncol(tab1)-1)] )

# create a separate data frame with the total population sizes of each cu (consumer unit) in each income class
cus <- 
	dcast( 
		pop[ pop$source == "I"  , c( "inclass" , "rpop45" ) ] , 
		1 ~ inclass 
	)

# add the starting line number (see in the stubfile) to denote the weighted consumer unit count
cus[ , 1 ] <- "100001"

# rename all other columns by income class
names( cus ) <- paste0( "inclass" , names( cus ) )

# rename the first column 'line'
names( cus )[ 1 ] <- "line"

# add an 'estimate' column, different from the 'MEAN' or 'SE' values above
cus$estimate <- "N"

# stack this weighted count single-row table on top of the other counts
tab2 <- rbind( cus , tab1 )

# re-merge this tabulation with the stubfile
tab <- merge( tab2 , stubfile , all = TRUE )

# loop through each column in the 'tab' data frame specific to an income class, and convert all missing values (NA) to zero
for ( i in names( tab )[ grepl( 'inclass' , names( tab ) ) ] ) tab[ is.na( tab[ , i ] ) , i ] <- 0

# if the estimate is also missing, it was a record from the stubfile that did not have a match in the 'tab2' data frame,
# so label its 'estimate' column as 'MEAN' instead of leaving it missing
tab[ is.na( tab[ , "estimate" ] ) , "estimate" ] <- "MEAN"

# throw out standard error 'SE' records from stubfile categories CUCHARS (consumer unit characteristics) and INCOME
tab <- tab[ !( tab$estimate %in% 'SE' & tab$group %in% c( "CUCHARS" , "INCOME" ) ) , ]

# order the entire tab file by the line, then estimate columns
tab <- tab[ order( tab$line , tab$estimate ) , ]

# the data frame 'tab' matches the final 'tab' table created by the "Integrated Mean and SE.sas" example program

# this table can be viewed on the screen..
head( tab , 10 )				# view the first 10 records


# sort the columns to match the "Integrated Mean and SE.lst" file #

# make a copy of the tab data frame that will be re-sorted
tab.out <- tab

tab.out <- tab.out[ , c( "title" , "estimate" , "inclass10" , paste0( "inclass0" , 1:9 ) ) ]

# label the columns of the output file
names( tab.out )[ 3:12 ] <- 
	c( 
		"all consumer units" , 
		"less than $5,000" ,
		"$5,000 to $9,999" ,
		"$10,000 to $14,999" , 
		"$15,000 to $19,999" , 
		"$20,000 to $29,999" ,
		"$30,000 to $39,999" ,
		"$40,000 to $49,999" ,
		"$50,000 to $69,999" ,
		"$70,000 and over"
	)

# ..and save to a comma separated value file on the local disk
write.csv( tab.out , "2011 Integrated Mean and SE.csv" , row.names = FALSE )	# store the 'tab.out' data frame in a csv in the current working directory

