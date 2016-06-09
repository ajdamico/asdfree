library(survey)
library(DBI)

# http://www.bjs.gov/content/pub/pdf/Variance_Guide_Appendix_C_SAS.pdf

dbfolder <- paste0( getwd() , "/MonetDB" )

db <- dbConnect( MonetDBLite::MonetDBLite() , dbfolder )

dbSendQuery( db , "ALTER TABLE x34061_0004 ADD COLUMN series DOUBLE" )
dbSendQuery( db , "ALTER TABLE x34061_0004 ADD COLUMN serieswgt DOUBLE" )
dbSendQuery( db , "ALTER TABLE x34061_0004 ADD COLUMN n10v4016 DOUBLE" )
dbSendQuery( db , "ALTER TABLE x34061_0004 ADD COLUMN newwgt DOUBLE" )

dbSendQuery( db , "UPDATE x34061_0004 SET series = CASE WHEN v4017 IN ( 1 , 8 ) OR v4018 IN ( 2 , 8 ) OR v4019 IN ( 1 , 8 ) THEN 1 ELSE 2 END" )

dbSendQuery( db , "UPDATE x34061_0004 SET serieswgt = 1" )

dbSendQuery( db , "UPDATE x34061_0004 SET n10v4016 = v4016 WHERE NOT v4016 IN ( 997 , 998 )" )
dbSendQuery( db , "UPDATE x34061_0004 SET n10v4016 = 10 WHERE n10v4016 > 10" )
dbSendQuery( db , "UPDATE x34061_0004 SET serieswgt = n10v4016 WHERE series = 2" )
dbSendQuery( db , "UPDATE x34061_0004 SET serieswgt = 6 WHERE series = 2 AND ( n10v4016 IS NULL )" )
dbSendQuery( db , "UPDATE x34061_0004 SET newwgt = wgtviccy * serieswgt" )


w <- 
	svydesign( 
		id = ~ v2118 , 
		strata = ~ yr_grp + v2117 , 
		weights = ~ newwgt , 
		nest = TRUE ,
		data = "x34061_0002" ,									# table name within the monet database (defined in the character string above)
		dbtype = "MonetDBLite" ,
		dbname = dbfolder
	)

x <- subset( w , exclude_outUS = 0 & dummy = 0 & year = 2011 )
