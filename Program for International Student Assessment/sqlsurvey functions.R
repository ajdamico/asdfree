# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # functions related to sqlsurvey statistical analysis # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# need to copy over the `with` method
with.svyMDBimputationList <- survey:::with.svyimputationList


# and create a new subset method for MDB imputation lists.
subset.svyMDBimputationList <-
	function( x , ... ){
		z <- x
		z$designs <- lapply( x$designs , subset , ... )
		
		z$call <- sys.call(-1)
		
		z
	}
# thanks.
# http://stackoverflow.com/questions/17407852/how-to-pass-an-expression-through-a-function-for-the-subset-function-to-evaluate


pisa.svyttest<-function(formula, design){

	# the MIcombine function runs differently than a normal svylm() call
	m <- eval(bquote(MIcombine( with( design , svylm(formula))) ) )

	rval <-
		list(
			statistic = coef( m )[ 1 ] / SE( m )[ 1 ] ,
			parameter = m$df[ 1 ] ,		
			estimate = coef( m )[ 1 ] ,
			null.value = 0 ,
			alternative = "two.sided" ,
			method = "Design-based t-test" ,
			data.name = deparse( formula ) 
		)
			   
	rval$p.value <- 
		( 1 - pf( ( rval$statistic )^2 , 1 , m$df[ 1 ] ) )

	names( rval$statistic ) <- "t"
	names( rval$parameter ) <- "df"
	names( rval$estimate ) <- "difference in mean"
	names( rval$null.value ) <- "difference in mean"
	class( rval ) <- "htest"

	return(rval)
}





# # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # functions related to sqlsurvey design creation  # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # #


construct.pisa.sqlsurvey.designs <-
	function( monet.url , year , table.name , pv.vars ){

		conn <- dbConnect( MonetDB.R() , monet.url )

		# identify all variables that are multiply-imputed
		pv.colnames <- paste0( "pv" , outer( 1:5 , pv.vars , paste0 ) )

		# identify all variables that are *not* multiply-imputed
		table.fields <- dbListFields( conn , table.name )

		nmi <- table.fields[ !( table.fields %in% pv.colnames ) ]

		# 'read' is not a valid column name in monetdb.
		nr.pv.vars <- gsub( "read" , "readZ" , pv.vars )

		all.implicates <- NULL

		# loop through each of the five variables..
		for ( i in 1:5 ){

			print( paste( 'currently working on implicate' , i , 'from table' , table.name ) )

			implicate.name <- paste0( table.name , "_imp" , i )
			
			all.implicates <- c( all.implicates , implicate.name )
			
			# build a sql string to create all five implicates
			sql <-
				paste(

					paste0( "create table " , implicate.name ) ,
					
					"as select" ,
					
					# all non-multiply imputed values
					paste( nmi , collapse = ", " ) ,
					
					# one of the five multiply-imputed values,
					# using a sql AS clause to rename
					paste0( ", pv" , i , pv.vars , " as " , nr.pv.vars , sep = "" , collapse = "" ) ,
					
					"from" ,
					
					table.name ,
					
					"with data"
				)
			
			
			dbSendUpdate( conn , sql )

			
			dbSendUpdate( 
				conn , 
				paste( 
					'alter table' ,
					implicate.name ,
					'add column row_names int auto_increment' 
				)
			)
			
			
			dbSendUpdate( 
				conn , 
				paste( 
					'alter table' ,
					implicate.name ,
					'add column one int' 
				)
			)
			
			
			dbSendUpdate( 
				conn , 
				paste( 
					'UPDATE' ,
					implicate.name ,
					'SET one = 1' 
				)
			)
			
			
			assign(
				implicate.name ,
				sqlrepsurvey( 	
					weights = "w_fstuwt" , 
					repweights = "w_fstr[1-9]" , 
					scale = 4 / 80 ,
					rscales = rep( 1 , 80 ) ,
					driver = MonetDB.R() , 
					database = monet.url ,
					mse = TRUE ,
					table.name = implicate.name
				)
			)
			
		}

		# output file name
		ofn <- paste0( year , " " , table.name , ".rda" )
		
		save( list = all.implicates , file = ofn )

		rm( list = all.implicates )

		gc()

		dbDisconnect( conn )
		
		ofn
	}



















