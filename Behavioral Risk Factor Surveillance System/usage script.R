library(RSQLite)
library(survey)
options( survey.lonely.psu = "adjust" )


brfss <- 
	svydesign(
		id = ~xpsu , 
		strata = ~xststr ,
		nest = TRUE ,
		weights = ~xfinalwt ,
		data = 'b10' ,
		dbtype = "SQLite" , 
		dbname = "s:/temp/temp.db"
	)

# does this work?
save( brfss , file = "s:/temp/brfss10.rda" )

db <- dbConnect( SQLite() , "s:/temp/temp.db" )
x <- dbReadTable( db , 'b10' )


brfss <- 
	svydesign(
		id = ~xpsu , 
		strata = ~xststr ,
		nest = TRUE ,
		weights = ~xfinalwt ,
		data = x
	)
# this object can also be saved... is that faster?
# otherwise use MonetDB!

unwtd.count( ~age , brfss )
unwtd.count( ~sex , brfss )
svyby( ~age , ~sex , brfss , unwtd.count )
( a <- svymean( ~factor( sex ) , brfss ) )
confint( a )

	
PROC CROSSTAB DATA=(your data filename) FILETYPE=SAS DESIGN=WR;
NEST _STSTR _PSU / MISSUNIT;
WEIGHT _finalwt;
SUBGROUP FAIRPOOR;
LEVELS 2;
