library(sqlsurvey)


shell.exec( "C:/My Directory/BRFSS/MonetDB/monetdb.bat" )


dbname <- "brfss"
dbport <- 50003

Sys.sleep( 20 )

monetdriver <- "c:/program files/monetdb/monetdb5/monetdb-jdbc-2.7.jar"
drv <- MonetDB( classPath = monetdriver )
monet.url <- paste0( "jdbc:monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( drv , monet.url , user = "monetdb" , password = "monetdb" )


# manual fix of the open() method for the sqlsurvey() function
open.sqlsurvey<-function(con, driver, ...){  
  con$conn<-dbConnect(driver, url=con$dbname,...)
  if (!is.null(con$subset)){
    con$subset$conn<-con$conn
  }
  con
}
# this bug has been reported to the sqlsurvey package author


load( 'C:/My Directory/BRFSS/b2010 design.rda' )
brfss.d <- open( brfss.design , driver = drv , user = "monetdb" , password = "monetdb" )


# calculate unweighted sample size column
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
