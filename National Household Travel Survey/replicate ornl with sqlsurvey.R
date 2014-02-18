library(MonetDB.R)
library(sqlsurvey)


batfile <- "s:/temp/NHTS/MonetDB/nhts.bat"

pid <- monetdb.server.start( batfile )

dbname <- "nhts"
dbport <- 50013

monet.url <- paste0( "monetdb://localhost:" , dbport , "/" , dbname )
db <- dbConnect( MonetDB.R() , monet.url , wait = TRUE )



dbSendUpdate( db , paste0( 'UPDATE hh_m_2009 SET one = 1' ) )
dbSendUpdate( db , paste0( 'alter table hh_m_2009 add column idkey int auto_increment' ) )
			

# create a sqlrepsurvey complex sample design object
# using the merged (household+person) table

options( survey.replicates.mse = TRUE )
nhts.hh.design <- 									# name the survey object
	sqlrepsurvey(									# sqlrepdesign function call.. type ?sqlrepdesign for more detail
		weight = 'wthhfin' , 							# person-level weights are stored in column "pwgtp"
		repweights = paste0( 'hhwgt' , 1:100 ) ,		# the acs contains 80 replicate weights, pwgtp1 - pwgtp80.  this [0-9] format captures all numeric values
		scale = 0.99 ,
		rscales = rep( 1 , 100 ) ,
		mse = TRUE ,
		table.name = paste0( 'hh_m_2009' ) , 			# use the person-household-merge data table
		key = "idkey" ,
		# check.factors = 10 by default.. uncommenting this next line would compute column classes based on `headers.m` instead
		check.factors = 10 ,					# use `headers.m` to determine the column types
		database = monet.url ,
		driver = MonetDB.R()
	)

# household size categories
svytotal(~I(hhsize == 1), nhts.hh.design)
svytotal(~I(hhsize == 2), nhts.hh.design)
svytotal(~I(hhsize == 3), nhts.hh.design)
svytotal(~I(hhsize > 3), nhts.hh.design)

confint(svytotal(~I(hhsize == 1), nhts.hh.design), df = 100 )
confint(svytotal(~I(hhsize == 2), nhts.hh.design), df = 100 )
confint(svytotal(~I(hhsize == 3), nhts.hh.design), df = 100 )
confint(svytotal(~I(hhsize > 3), nhts.hh.design), df = 100 )

coef(svytotal(~I(hhsize == 1), nhts.hh.design))-
confint(svytotal(~I(hhsize == 1), nhts.hh.design), df = 100 )

# MATCHED in monetdb.r

 a <- dbGetQuery( db , paste( 'select hhsize , wthhfin , ' , paste( 'hhwgt' , 1:100 , collapse = ',' , sep = '') , 'from hh_m_2009' ) )
 
b <-
    svrepdesign(
        weights = ~wthhfin,
        repweights = 'hhwgt[1-9]' ,
        type = "Fay",
        rho = (1-1/sqrt(99)),
        data = a ,
		mse = TRUE
    )

svytotal(~I(hhsize == 1), b)
confint(svytotal(~I(hhsize == 1), b), df = degf(b)+1 )

confint(svytotal(~I(hhsize == 1), b), df = degf(b)+1 ) - coef( svytotal(~I(hhsize == 1), b))

