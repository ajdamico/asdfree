# analyze us government survey data with the r language
# consumer expenditure survey
# replication of "2011 Integrated Mean and SE.lst" table created with the "Integrated Mean and SE.sas" example program
# using 2011 public use microdata


# this r script will replicate the massive table in the folder "Programs 2011\SAS\2011 Integrated Mean and SE.lst" inside the bls documentation
# ftp://ftp.bls.gov/pub/special.requests/ce/pumd/documentation/documentation11.zip


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


########################################################################################
# Analyze the 2011 Consumer Expenditure Survey (CES) family and expenditure data files #
########################################################################################


# set your working directory.
# all CES data files will be stored here
# after downloading and importing.
# use forward slashes instead of back slashes

setwd( "C:/My Directory/CES/" )


# turn off scientific notation in most output

options( scipen = 20 )


# remove the # in order to run this install.packages line only once
# install.packages( c( "stringr" , "reshape2" , "sqldf" , "RSQLite" ) )


library(stringr) 	# load stringr package (manipulates character strings easily)
library(reshape2)	# load reshape2 package (transposes data frames quickly)
library(sqldf)		# load the sqldf package (enables sql queries on data frames)
require(RSQLite) 	# load RSQLite package (creates database files in R)




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



year <- 2011


yr <- substr( year , 3 , 4 )

# put the big tables into RSQLite -- laptop should be able to handle this.


options( scipen = 10 )

setwd( paste( "C:/My Directory/CES" , year , sep = "/" ) )

# load the package containing str_trim() and str_pad()
library(stringr)

# load the package containing melt() and dcast()
library(reshape2)

# load the sql package
library(sqldf)

# load the sqlite package
library(RSQLite)


# designate a temporary database
temp.db <- tempfile()

# designate the IntStub2011.txt file
sf <- paste0( "./docs/Programs " , year , "/IntStub" , year , ".txt" )

# read the IntStub2011.txt file onto the local disk, to make a few edits
tf <- tempfile()
st <- readLines( sf )

# only keep rows starting with a one
st <- st[ substr( st , 1 , 1 ) == '1' ]
# replace this two tabs typo with seven spaces
st <- gsub( "\t\t" , "       " , st )
# save to a temporary file
writeLines( st , tf )


stubfile <- 
	read.fwf( 
		tf , 
		width = c( 1 , -2 , 1 , -2 , 60 , -3 , 6 , -4 , 1 , -5 , 7 ) ,
		col.names = c( "type" , "level" , "title" , "ucc" , "survey" , "group" )
	)

stubfile$group <- str_trim( as.character( stubfile$group ) )
	
stubfile <- 
	subset( 
		stubfile , 
		group %in% c( "CUCHARS" , "FOOD" , "EXPEND" , "INCOME" ) &
		survey != "T"
	)

rownames( stubfile ) <- NULL

stubfile$count <- 9999 + ( 1:nrow( stubfile ) )

stubfile$line <- paste0( stubfile$count , stubfile$level )

head( stubfile )

# start with a character vector with ten blank strings
curlines <- rep( "" , 10 )

aggfmt1 <- matrix( nrow = nrow( stubfile ) , ncol = 10 )

for ( i in seq( nrow( stubfile ) ) ){

	if ( !is.na( as.numeric( as.character( stubfile[ i , "ucc" ] ) ) ) ){
		curlines[ 10 ] <- stubfile[ i , "line" ]
	} else curlines[ 10 ] <- ""

	curlevel <- stubfile[ i , "level" ]
	curline <- stubfile[ i , "line" ]

	curlines[ curlevel ] <- curline
	
	if ( curlevel < 9 ) curlines[ (curlevel+1):9 ] <- ""

	# remove actual value
	savelines <- curlines
	savelines[ curlevel ] <- ""
	
	aggfmt1[ i , ] <- savelines
	
}

aggfmt1 <- data.frame( aggfmt1 )
names( aggfmt1 ) <- paste0( "line" , 1:10 )

aggfmt1 <- cbind( aggfmt1 , stubfile[ , c( "ucc" , "line" ) ] )
aggfmt1 <- subset( aggfmt1 , !is.na( as.numeric( as.character( ucc ) ) ) )

aggfmt1 <- aggfmt1[ order( aggfmt1$ucc ) , ]

aggfmt1$compare <- aggfmt1$line
aggfmt1$line <- NULL

rownames( aggfmt1 ) <- NULL


aggfmt2 <- melt(aggfmt1, id=c("ucc","compare")) 
names( aggfmt2 )[ 4 ] <- "line"

aggfmt <- subset( aggfmt2 , line != "" , select = c( "ucc" , "line" ) )

aggfmt <- aggfmt[ order( aggfmt$ucc ) , ]

head( aggfmt )


d <- read.in.qs( "fmld" , "diary" , TRUE )

gc()


load( paste0( "./intrvw/fmli" , yr , "1x.rda" ) )
load( paste0( "./intrvw/fmli" , yr , "2.rda" ) )
load( paste0( "./intrvw/fmli" , yr , "3.rda" ) )
load( paste0( "./intrvw/fmli" , yr , "4.rda" ) )
load( paste0( "./intrvw/fmli" , as.numeric( yr ) + 1 , "1.rda" ) )

x <- get( paste0( "fmli" , yr , "1x" ) )
x$high_edu <- NA
x$qtr <- 1
assign( "fmli1" , x )

for ( i in 2:4 ){
	x <- get( paste0( "fmli" , yr , i ) )
	x$qtr <- i
	assign( paste0( "fmli" , i ) , x )
}

x <- get( paste0( "fmli" , as.numeric( yr ) + 1 , "1" ) )
x$qtr <- 5
assign( "fmli5" , x )

f <- rbind( fmli1 , fmli2 , fmli3 , fmli4 , fmli5 )

rm( fmli1 , fmli2 , fmli3 , fmli4 , fmli5 , x )
rm( 
	list = 
		c( 
			paste0( "fmli" , yr , "1x" ) , 
			paste0( "fmli" , yr , 2:4 ) ,
			paste0( "fmli" , as.numeric( yr ) + 1 , "1" )
		)
)

gc()

f <- 
	transform( 
		f ,
		mo_scope = 
			ifelse( qtr %in% 1 , as.numeric( qintrvmo ) - 1 ,
			ifelse( qtr %in% 5 , ( 4 - as.numeric( qintrvmo )  ) ,
				3 ) ) 
	)

d$mo_scope <- 3
f$source <- "I"
d$source <- "D"

wtrep <- c( paste0( "wtrep" , str_pad( 1:44 , 2 , pad = "0" ) ) , "finlwt21" )
repwt <- paste0( "repwt" , 1:45 )

f.d.vars <- c( wtrep , "mo_scope" , "inclass" , "newid" , "source" )

fmly <- rbind( f[ , f.d.vars ] , d[ , f.d.vars ] )

rm( f )

gc()

for ( i in 1:45 ){
	fmly[ , wtrep[ i ] ] <- as.numeric( as.character( fmly[ , wtrep[ i ] ] ) )
	fmly[ is.na( fmly[ , wtrep[ i ] ] ) , wtrep[ i ] ] <- 0
	fmly[ , repwt[ i ] ] <- ( fmly[ , wtrep[ i ] ] * fmly[ , "mo_scope" ] / 12 )
}


expd <- read.in.qs( "expd" , "diary" , TRUE )

gc()

dtbd <- read.in.qs( "dtbd" , "diary" , TRUE )

gc()

mtbi <- read.in.qs( "mtbi" , "intrvw" , FALSE )

gc()

itbi <- read.in.qs( "itbi" , "intrvw" , FALSE )

gc()

	
dtbd$cost <- dtbd$amount
itbi$cost <- itbi$value

edmi.vars <- c( "newid" , "ucc" , "cost" )


expend.itbi <- subset( itbi , pubflag == 2 & refyr == 2011 )
expend.mtbi <- subset( mtbi , pubflag == 2 & ref_yr == 2011 )

expend.im <- 
	rbind( 
		expend.itbi[ , edmi.vars ] , 
		expend.mtbi[ , edmi.vars ] 
	)

expend.im$source <- "I"
expend.im <- 
	transform( 
		expend.im , 
		cost = ifelse( ucc == '710110' , cost * 4 , cost )
	)
	

expend.expd <- subset( expd , pub_flag == 2 , select = edmi.vars )
expend.expd$source <- "D"
expend.expd$cost <- expend.expd$cost * 13

expend <- rbind( expend.im , expend.expd )

rm( itbi , mtbi , expend.itbi , expend.mtbi , expend.im , expend.expd )

gc()

expend <- expend[ order( expend$newid ) , ]

db <- dbConnect( SQLite() , temp.db )
dbWriteTable( db , 'fmly' , fmly , row.names = FALSE )
dbWriteTable( db , 'expend' , expend , row.names = FALSE )

rcost <- paste0( "rcost" , 1:45 )

wtrep.cost <- paste0( "( b.cost * a." , wtrep , " ) as " , rcost , collapse = ", " )

sql.line <- 
	paste( 
		"create table pubfile as select a.newid , a.inclass , b.source , b.ucc ," ,
		wtrep.cost ,
		"from fmly as a inner join expend as b on a.newid = b.newid AND a.source = b.source" 
	)

dbSendQuery( 
	db , 
	sql.line
)




rpop <- paste0( "rpop" , 1:45 )

rpop.sums <- paste( "sum( " , repwt , ") as " , rpop , collapse = ", " )

rcost.sums <- paste( "sum( " , rcost , ") as " , rcost , collapse = ", " )


pop.all <- dbGetQuery( db , paste( "select 10 as inclass, source, " , rpop.sums , "from fmly group by source" ) )
pop.by <- dbGetQuery( db , paste( "select inclass, source," , rpop.sums , "from fmly group by inclass, source" ) )
pop <- rbind( pop.all , pop.by )


dbSendQuery( 
	db , 
	paste( 
		"create table aggright as" ,
		"select inclass, source, ucc," , 
		rcost.sums , 
		"from pubfile group by source , inclass , ucc" ,
		"union" ,
		"select '10' as inclass, source , ucc," , 
		rcost.sums , 
		"from pubfile group by source , ucc" 
	)
)

aggright <- dbReadTable( db , 'aggright' )


so <- names( table( expend$source ) )
uc <- names( table( expend$ucc ) )
cl <- names( table( fmly[ , 'inclass' ] ) )
cl <- c( cl , "10" )

aggleft <- expand.grid( so , uc , cl )
names( aggleft ) <- c( 'source' , 'ucc' , 'inclass' )

agg <- merge( aggleft , aggright , all.x = TRUE )

nrow( agg )


means <- paste0( "mean" , 1:45 )

avgs1 <- merge( pop , agg )
nrow( avgs1 )


for ( i in 1:45 ){
	avgs1[ , means[ i ] ] <- ( avgs1[ , rcost[ i ] ] / avgs1[ , rpop[ i ] ] )
	
	avgs1[ is.na( avgs1[ , means[ i ] ] ) , means[ i ] ] <- 0
}

avgs1 <- avgs1[ , c( "source" , "inclass" , "ucc" , means ) ]

avgs.sums <- paste( "sum( " , means , ") as " , means , collapse = ", " )

avgs3 <- merge( avgs1 , aggfmt )
avgs3 <- sqldf( 'select distinct * from avgs3' )

sql.avgs <- paste( "select inclass, line," , avgs.sums , "from avgs3 group by inclass, line" )

avgs2 <- sqldf( sql.avgs )


se <- avgs2

diffs <- paste0( "diff" , 1:44 )

for ( i in 1:44 ) se[ , diffs[ i ] ] <- ( se[ , means[ i ] ] - se[ , "mean45" ] )^2

se$mean <- se$mean45
se$se <- sqrt( rowSums( se[ , diffs ] ) / 44 )

se <- se[ , c( "inclass" , "line" , "mean" , "se" ) ]

TAB1M <- dcast( se , line ~ inclass , mean , value.var = "mean" )
TAB1S <- dcast( se , line ~ inclass , mean , value.var = "se" )
TAB1M$estimate <- "MEAN"
TAB1S$estimate <- "SE"
TAB1 <- rbind( TAB1M , TAB1S )
names( TAB1 )[2:(ncol(TAB1)-1)] <- paste0( "inclass" , names( TAB1 )[2:(ncol(TAB1)-1)] )

cus <- 
	dcast( 
		pop[ pop$source == "I"  , c( "inclass" , "rpop45" ) ] , 
		1 ~ inclass 
	)
cus[ , 1 ] <- "100001"
names( cus ) <- paste0( "inclass" , names( cus ) )
names( cus )[ 1 ] <- "line"
cus$estimate <- "N"

TAB2 <- rbind( cus , TAB1 )


TAB <- merge( TAB2 , stubfile , all = TRUE )

for ( i in names( TAB )[ grepl( 'inclass' , names( TAB ) ) ] ) TAB[ is.na( TAB[ , i ] ) , i ] <- 0
TAB[ is.na( TAB[ , "estimate" ] ) , "estimate" ] <- "MEAN"

TAB <- TAB[ !( TAB$estimate %in% 'SE' & TAB$group %in% c( "CUCHARS" , "INCOME" ) ) , ]

TAB <- TAB[ order( TAB$line , TAB$estimate ) , ]

names( TAB ) <- gsub( "inclass0" , "inclass" , names( TAB ) )


# this TAB does not include the "OTHER" line.. is that okay?
# otherwise you're done.


###############################



library(sas7bdat)
tab <- read.sas7bdat( "C:/My Directory/CES/tab.sas7bdat" )
names( tab ) <- tolower( names( tab ) )
tab$i <- NULL
tab$line <- as.character( tab$line )

# remove OTHER line--
tab <- subset( tab , line != "OTHER" )


TAB$title <- str_trim( as.character( TAB$title ) )
tab$title <- str_trim( as.character( tab$title ) )
tab$estimate <- as.character( tab$estimate )

r <- 1:10
TAB[ r , ]
tab[ r , ]

for ( i in seq( ncol( tab ) ) ){
	if ( class( tab[ , i ] ) == 'numeric' ) tab[ , i ] <- round( tab[ , i ] )
	if ( class( TAB[ , i ] ) == 'numeric' ) TAB[ , i ] <- round( TAB[ , i ] )
}

for ( i in seq( ncol( tab ) ) ) {
	print( names( tab )[i] )
	print( identical( tab[ , i ] , TAB[ , i ] ) )
}


nrow( tab )
nrow( TAB )
head( tab )
head( TAB )
sapply( tab , class )
sapply( TAB , class )

