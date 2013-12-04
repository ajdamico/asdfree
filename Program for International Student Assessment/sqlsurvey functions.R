# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # functions related to sqlsurvey statistical analysis # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# combine five sqlrepsurvey designs
# into a single monetdb-backed multiply-imputed replicate-weighted list
svyMDBdesign <-
	function( five.designs ){
	
		# start with an empty object
		rval <- NULL
		# load in the five designs
		rval$designs <- five.designs
		
		# store the call where it all began
		rval$call <- sys.call()

		# open each of those design connections with MonetDB hooray
		rval$designs <- lapply( rval$designs , open , MonetDB.R() )

		# class it.  that way other functions below will recognize this object as very very special.
		class( rval ) <- "svyMDBimputationList"

		rval
	}

	
# svyquantile functions run on a multiply-imputed sqlrepsurvey design
# do not include a variance-covariance matrix.
# therefore, the standard errors need to be extracted manually
# and passed in as a separate variance object for `MIcombine` to work its magic.
sqlquantile.MIcombine <-
	function( x ){
		
		# extract the standard errors from the multiply-imputed svyquantile call
		se <- lapply( lapply( x , attr , 'ci' ) , '[' , 3 )
		
		# square the standard errors to get the variances
		var <- lapply( se , function( y ) y^2 )
	
		# call `MIcombine` and return those results.
		MIcombine( x , var )
	}

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
	function( monet.url , year , table.name , pv.vars , sas_ri , additional.factors = NULL ){

		# step one - find all character columns #
		sascii <- parse.SAScii( sas_ri )
		
		factor.vars <- tolower( sascii[ sascii$char %in% TRUE , 'varname' ] )

		factor.vars <- factor.vars[ !( factor.vars %in% 'toss_0' ) ]
		
		factor.vars <- c( factor.vars , additional.factors )
		# end of finding all character columns #
		
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
					check.factors = factor.vars ,
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

