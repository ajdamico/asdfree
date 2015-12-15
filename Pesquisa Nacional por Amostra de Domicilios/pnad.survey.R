# initiate a function that removes the "UF" field from the PNAD SAS importation script,
# because the R `SAScii` package does not currently handle overlapping fields and this UF column always overlaps
remove.uf <-
	function( sasfile ){

		# read the SAS import file into R
		sas_lines <- readLines( sasfile )

		# remove any TAB characters, replace them with two spaces
		sas_lines <- gsub( "\t" , "  " , sas_lines )
		
		# throw out any lines that contain the UF line
		sas_lines <- sas_lines[ !grepl( "@00005[ ]+UF[ ]" , sas_lines ) ]

		# fix the "$1 ." difference seen in a number of PNAD SAS importation scripts
		# by simply switching the space and the period
		sas_lines <- 
			gsub(
				"@00840  V2913  $1 ./* LOCAL ÚLTIMO FURTO    */" ,
				"@00840  V2913  $1. /* LOCAL ÚLTIMO FURTO    */" ,
				sas_lines ,
				fixed = TRUE
			)
		
		# fix the duplicate column names in 2007
		sas_lines <-
			gsub(
				"00965  V9993" ,
				"00965  V9993A" ,
				sas_lines ,
			)
		
		# create a temporary file
		tf <- tempfile()

		# write the updated sas input file to the temporary file
		writeLines( sas_lines , tf )

		# return the filepath to the temporary file containing the updated sas input script
		tf
}


# initiate a function that post-stratifies the PNAD survey object,
# because the R `survey` package does not currently allow post-stratification of database-backed survey objects
pnad.postStratify <-
	function( design , strata.col , oldwgt ){
		
		# extract the tablename within the SQLite database
		tablename <- design$db$tablename
		
		# extract the SQLite connection
		conn <- design$db$connection

		# create an R data frame containing one record per strata
		# that will be used to determine the weights-multiplier for each strata in survey dataset
		# this table contains one record per strata
		population <- 
			dbGetQuery( 
				conn , 
				paste(
					'select' ,
					strata.col ,
					", CAST( " ,
					strata.col ,
					' AS DOUBLE ) as newwgt , sum( ' ,
					oldwgt ,
					' ) as oldwgt from ' ,
					tablename , 
					'group by' ,
					strata.col
				)
			)
		
		# calculate the multiplier
		population$mult <- population$oldwgt / population$newwgt
		
		# retain only the strata identifier and the multiplication value
		population <- population[ , c( strata.col , 'mult' ) ]
		
		# pull the strata and the original weight variable from the original table
		# this data.frame contains one record per respondent in the PNAD dataset
		# as opposed to one record per strata
		so.df <- 
			dbGetQuery( 
				conn , 
				paste( 
					'select' , 
					strata.col , 
					"," ,
					oldwgt ,
					'from' , 
					tablename 
				) 
			)
		
		# add a row number variable to re-order post-merge
		so.df$n <- 1:nrow( so.df )
			
		# merge the strata with the multipliers
		so.df <-
			merge( so.df , population )
		
		# since ?merge undid the order relative to the original table,
		# put the strata and old weight table back in order
		so.df <-
			so.df[ order( so.df$n ) , ]
		
		# extract the multipliers into a numeric vector
		prob.multipliers <- so.df[ , 'mult' ]
		
		# overwrite the design's probability attribute with post-stratified probabilities
		design$prob <- design$prob * prob.multipliers

		# construct the `postStrata` attribute of the survey design object
		index <- as.numeric( so.df[ , strata.col ] )
		
		# extract the original weights..
		attr( index , 'oldweights' ) <- so.df[ , oldwgt ]
		
		# ..and the new weights
		attr( index , 'weights' ) <-  1 / design$prob
		
		# so that the standard errors accurately reflect the
		# process of post-stratification
		design$postStrata <- list(index)

		# return the updated database-backed survey design object
		design
	}

# thanks for playing