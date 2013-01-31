# load the complex sample survey design package
library(survey)
library(RSQLite)

# connect to the database
db <- dbConnect( SQLite() , "C:/My Directory/SIPP/SIPP08.db" )

# load the sipp 2008 panel wave 7 core file
SIPP.08w7.df <- dbReadTable( db , 'w7' )

# load the sipp 2008 panel wave 7 replicate weights file
SIPP.08w7.rw.df <- dbReadTable( db , 'rw7' )

# immediately limit this to srefmon == 4
rw <- subset( SIPP.08w7.rw.df , srefmon == 4 )


# count the number of records in the core file..
nrow( SIPP.08w7.df )
# the core wave 7 file contains 341,568 records

# limit the core wave 7 file to only srefmon == 4 and only keep a few columns
x <- 
	subset( 
		SIPP.08w7.df , 
		srefmon == 4 , 
		select = 
			c( 
				# only keep these seven columns
				"ssuid" , "epppnum" , 
				"whfnwgt" , "wpfinwgt" , 
				"tage" , "errp" , "etenure"
			) 
	)

# count the number of records in the core file restricted to srefmon == 4..
nrow( x )
# the core wave 7 file contains 85,397 records after restricting to srefmon == 4.


# load the sipp 2008 panel wave 7 topical module
SIPP.08w7.tm.df <- dbReadTable( db , 'tm7' )

# count the number of records in the wave 7 topical module
nrow( SIPP.08w7.tm.df )
# the topical module wave 7 file contains 85,397 as well!

# limit the topical module wave 7 file to only a few columns
y <- 
	subset( 
		SIPP.08w7.tm.df , 
		select = 
			c( 
				# only keep these four columns
				"ssuid" , "epppnum" , 
				"thhtnw" , "thhtheq"
			) 
	)

# merge the core file with the topical module
# (using the versions with only a few of the columns)
# merge by ssuid + epppnum
z <- merge( x , y )

# count the number of records in the merged file
nrow( z )
# the merged file still contains 85,397 records, which seems correct

# merge on the replicate weights
z.rw <- merge( z , rw  )


# identify all integer columns
ic <- sapply( z.rw , is.integer )

# convert all 'integer' types to 'numeric'
z.rw[ic] <- lapply( z.rw[ ic ] , as.numeric )

# divide all weights by ten thousand
# (the four implied decimal points are not included in the SAS input scripts)

# identify weight columns
wc <- names( z.rw )[ grep( 'wgt' , names( z.rw ) ) ]

# create a new divide-by-ten-thousand function
dbtt <- function( x ){ x / 10000 }

# apply that new dbtt() function to every single column specified in the 'wc' character variable
z.rw[ wc ] <- lapply( z.rw[ wc ] , dbtt )


# in 2010, the 'lgtcy2wt' variable was numeric but had not previously been divided by 10,000
# so run the dbtt() function on that column as well
z.rw[ , mainwgt ] <- dbtt( z.rw[ , mainwgt ] )




# create a survey design object with SIPP design information
wso.all <- 
	svrepdesign ( 
		data = z.rw ,
		repweights = "repwgt[1-9]" , 
		type = "Fay" , 
		combined.weights = T , 
		rho = ( 1 - 1 / sqrt( 4 ) ) ,
		weights = ~wpfinwgt
	)


# the survey design still contains 85,397 records
nrow( wso.all )

# keep only records where the person is the reference person
wso <- subset( wso.all , errp %in% 1:2 )

# but now only contains 33,795 records
nrow( wso )


# confirm that everyone in this new merged, restricted file has
# tage > 14
svytable( ~tage , wso )
# -- yes, every record is of a person aged 15 or older.





# calculate the mean total household net worth four different ways:

# calculate the mean total household net worth
svymean( ~thhtnw , wso )
# this gives $206,259  -- which is much lower than the published
# but i believe it's the correct number for the public use data


# calculate the mean total household net worth, restricted to only
# households with a reference person aged 15 or above
svymean( ~thhtnw , subset( wso , tage > 14 ) )
# this also gives $206,259  -- all household reference persons have tage > 14


# calculate the mean total household net worth, restricted to only
# households that thhtnw is not equal zero
svymean( ~thhtnw , subset( wso , thhtnw != 0 ) )
# this gives $216,250 -- this number is much lower than the published $322,352
# but i believe $206,259 is the correct number..


# calculate the mean total household net worth, restricted to only
# households that thhtnw is greater than zero
svymean( ~thhtnw , subset( wso , thhtnw > 0 ) )
# this gives $258,053 -- this number is still much lower than the published $322,352
# but i think the $206,259 number is correct, not this $258,053 number,
# because negative-asset households should be counted?

# this leads me to the conclusion that the outliers affect the 
# total household mean net worth that it should *not* be calculated
# using the public use data?



# calculate the median total household net worth three different ways:


# calculate the median total household net worth
svyquantile( ~thhtnw , wso , 0.5 )
# this gives $68,528 -- which is quite close to the published $66,740 number
# but i'm confused why it would be higher?

# calculate the median total household net worth
# excluding households with zero net worth
svyquantile( ~thhtnw , subset( wso , thhtnw != 0 ) , 0.5 )
# $80,057 -- much higher than the published number

# excluding households with non-positive net worth
svyquantile( ~thhtnw , subset( wso , thhtnw > 0 ) , 0.5 )
# $120,531 -- even higher than the published number


# calculate the median equity in own home variable,
# using only households with etenure == 1 (as specified in the SAS code)
svyquantile( ~thhtheq , subset( wso , etenure == 1 ) , 0.5 )
# $80,000 -- this matches the published number exactly

# calculate the mean equity in own home variable..
svymean( ~thhtheq , subset( wso , etenure == 1 ) )
# $123,954 -- this is lower than the published $135,850
# again, probably because the topcoding removed important outliers



# calculate the median net worth (excluding equity in own home)
svyquantile( ~as.numeric( thhtnw - thhtheq ) , wso , 0.5 )
# $15,102 -- this is almost the same as the published number of $15,000
# and is likely the result of a different quantile calculation between software
# all nine quantile calculation types are listed on
# http://stat.ethz.ch/R-manual/R-patched/library/stats/html/quantile.html



