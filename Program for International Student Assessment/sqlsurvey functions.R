# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # functions related to sqlsurvey statistical analysis # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# need to copy over the `with` method
with.svyMDBimputationList <- survey:::with.svyimputationList
# monetdb-backed objects should work the exact same as sqlite-backed ones


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


# initiate a pisa-specific survey design-adjusted t-test
# that will work on monetdb-backed, multiply-imputed designs
pisa.svyttest <-
	function( formula , design ){

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
			

			# actually create the current implicate,
			# using the string constructed above
			dbSendUpdate( conn , sql )

			
			# add a new column to the monetdb data table called `row_names`
			# that simply contains the row id
			dbSendUpdate( 
				conn , 
				paste( 
					'alter table' ,
					implicate.name ,
					'add column row_names int auto_increment' 
				)
			)
			
			
			# add an empty column called `one` that's an integer
			dbSendUpdate( 
				conn , 
				paste( 
					'alter table' ,
					implicate.name ,
					'add column one int' 
				)
			)
			
			
			# fill it full of ones
			dbSendUpdate( 
				conn , 
				paste( 
					'UPDATE' ,
					implicate.name ,
					'SET one = 1' 
				)
			)
			
			
			# construct the actual monetdb-backed,
			# replicate-weighted survey design.
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
		
		# save all of the database design objects as r data files
		save( list = all.implicates , file = ofn )

		# remove them from RAM
		rm( list = all.implicates )

		# clear up RAM
		gc()

		# disconnect from the monet database
		dbDisconnect( conn )
		
		# return the name of the file that has already been saved to the disk,
		# just for fun.
		ofn
	}

