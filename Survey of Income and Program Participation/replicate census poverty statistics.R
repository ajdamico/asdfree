setwd( "C:/My Directory/SIPP/" )

require(survey)
require(sqldf)
require(RSQLite)

options(digits=22)
options( scipen = 10 )
options( survey.replicates.mse = TRUE )
db <- dbConnect( SQLite() , "SIPP08.db" )


x <- dbReadTable( db , 'w1' )
rw <- dbReadTable( db , 'rw1' )


x <- subset( x , rhcalmn == 8 )

nrow( x )
nrow( rw )
y <- merge( x , rw )
nrow( y )

# identify all integer columns
ic <- sapply( y , is.integer )

# convert all 'integer' types to 'numeric'
y[ic] <- lapply( y[ ic ] , as.numeric )

# divide all weights by ten thousand
# (the four implied decimal points are not included in the SAS input scripts)

# identify weight columns
wc <- names( y )[ grep( 'wgt' , names( y ) ) ]

# create a new divide-by-ten-thousand function
dbtt <- function( x ){ x / 10000 }

# apply that new dbtt() function to every single column specified in the 'wc' character variable
y[ wc ] <- lapply( y[ wc ] , dbtt )


y$pov <- as.numeric( y$thtotinc < y$rhpov )
y$povf <- as.numeric( y$tftotinc < y$rfpov )



#############################################################
# survey design for replicate weights with fay's adjustment #

# create a survey design object with SIPP design information
z <- 
	svrepdesign ( 
		data = y ,
		repweights = "repwgt[1-9]" , 
		type = "Fay" , 
		combined.weights = T , 
		rho = ( 1 - 1 / sqrt( 4 ) ) ,
		weights = ~wpfinwgt
	)


options( digits = 6 )
coef( svymean( ~pov , z ) )
options( digits = 4 )
SE( svymean( ~pov , z ) )


options( digits = 6 )
coef( svymean( ~pov , subset( z , ehrefper == epppnum ) ) )
options( digits = 4 )
SE( svymean( ~pov , subset( z , ehrefper == epppnum ) ) )

options( digits = 6 )
coef( svymean( ~pov , subset( z , efrefper == epppnum ) ) )
options( digits = 4 )
SE( svymean( ~pov , subset( z , efrefper == epppnum ) ) )
