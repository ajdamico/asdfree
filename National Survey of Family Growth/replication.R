library(survey)
load( "C:/My Directory/NSFG/2002femresp.rda" )

y <- svydesign( ~ secu_r , strata = ~ sest , data = x , weights = ~ finalwgt , nest = TRUE )

y <- 
	update( 
		y , 
		pill = as.numeric( constat1 == 6 ) ,
		agerx = factor( findInterval( ager , c( 15 , 20 , 25 , 30 , 35 , 40 ) ) ) 
	)

# matches http://www.cdc.gov/nchs/data/nsfg/ser2_example1_final.pdf#page=2
svyby( ~ pill , ~ agerx , y , svytotal )
svyby( ~ pill , ~ agerx , y , svymean )
