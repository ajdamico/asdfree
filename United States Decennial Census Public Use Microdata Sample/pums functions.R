# construct a function that..
# takes an ascii file to be downloaded and two household/structure files,
# parses it, and saves it to a temporary file on the local disk as a tab-separated value file
get.tsv <-
	function(
		fp ,
		zipped ,
		hh.stru ,
		person.stru ,
		fileno
	){
		
		# store the warnings into a variable
		previous.warning.setting <- getOption( "warn" )

		# at the end of this function, put the warning option
		# back to its original setting
		on.exit( options( "warn" = previous.warning.setting ) )

		# set warnings to behave like errors, so if a download
		# does not complete properly, the program re-tries.
		options( "warn" = 2 )
		
		# construct two missing objects
		attempt1 <- attempt2 <- NA
		
		# specify a temporary file on the local disk
		cur.pums <- tempfile()

		# try to download the text file
		attempt1 <- try( download.cache( fp , cur.pums , mode = 'wb' ) , silent = TRUE )
		
		# if the first attempt returned an error..
		if ( class( attempt1 ) == 'try-error' ) {
		
			# wait sixty seconds
			Sys.sleep( 60 )
			
			# and try again
			attempt2 <- try( download.cache( fp , cur.pums , mode = 'wb' ) , silent = TRUE )
			
		}	
		
		# if the second attempt returned an error..
		if ( class( attempt2 ) == 'try-error' ) {
		
			# wait two minutes
			Sys.sleep( 120 )
			
			# and try one last time.
			download.cache( fp , cur.pums , mode = 'wb' )
			# since there's no `try` function encapsulating this one,
			# it will break the whole program if it doesn't work
		}	

		# if the downloaded file was a zipped file,
		# unzip it and replace it with its decompressed contents
		if ( zipped ) {
			tf <- tempfile()
			tf <- unzip( cur.pums )
			
			# try to get rid of the file..if it's weirdly-named, who cares.
			try( file.remove( cur.pums ) , silent = TRUE )
					
			cur.pums <- tf
		}
		
		# create two more temporary files
		tf.household <- tempfile()
		tf.person <- tempfile()
		
		# initiate a read-only connection to the input file
		incon <- file( cur.pums , "r")

		# initiate two write-only file connections "w" - pointing to the household and person files
		outcon.household <- file( tf.household , "w" )
		outcon.person <- file( tf.person , "w" )

		# start line counter #
		line.num <- 0

		# loop through every row of data in the original input file
		while( length( line <- readLines( incon , 1 , skipNul = TRUE ) ) > 0 ){

			# confirm this is either a household or person record..
			stopifnot( substr( line , 1 , 1 ) %in% c( 'H' , 'P' ) )
			# ..otherwise, there's something wrong with the file!

			# remove goofy special characters (that will break monetdb)
			line <- gsub( "Î?" , "62" , line , fixed = TRUE )
			line <- gsub( "zÙ" , " " , line , fixed = TRUE )
			line <- gsub( "m99" , " 99" , line , fixed = TRUE )
			line <- gsub( "jÂ" , " " , line , fixed = TRUE )
			
			line <- gsub( "[^[:alnum:]///' ]" , " " ,  line )
			
			line <- iconv( line , "" , "ASCII" , sub = " " )

			line <- gsub( "P00083710210010540112000012110014100000028401800020193999910000000200000000000000000000000000000000000000p" , "P00083710210010540112000012110014100000028401800020193999910000000200000000000000000000000000000000000000  " , line , fixed = TRUE )
			# end of goofy special character removal
			
			# ..and if the first character is a H, add it to the new household-only pums file.
			if ( substr( line , 1 , 1 ) == "H" ) {
				writeLines( 
					paste0(
						substr( 
							# add the line number at the end
							line ,
							1 , 
							cumsum( abs( hh.stru$width ) )[ nrow( hh.stru ) ]
						) , 
						str_pad( fileno , 10 ) 
					) , 
					outcon.household 
				)
			}
				
			# ..and if the first character is a P, add it to the new person-only pums file.
			if ( substr( line , 1 , 1 ) == "P" ) {
				writeLines( 
					paste0(
						substr( 
							# add the line number at the end
							line ,
							1 , 
							cumsum( abs( person.stru$width ) )[ nrow( person.stru ) ]
						) , 
						str_pad( fileno , 10 ) 
					)  , 
					outcon.person 
				)				
			}
				
			# add to the line counter #
			line.num <- line.num + 1

			# every 10k records, print current progress to the screen
			if ( line.num %% 10000 == 0 ) cat( " " , prettyNum( line.num , big.mark = "," ) , "census pums lines processed" , "\r" )

		}
		
		# close all file connections
		close( outcon.household )
		close( outcon.person )
		close( incon )
		
		# remove the file that was downloaded
		
		# file.remove sometimes needs a few seconds to cool off.
		remove.attempt <- try( stop() , silent = TRUE )
		while( class( remove.attempt ) == 'try-error' ){ 
			remove.attempt <- try( file.remove( cur.pums ) , silent = TRUE )
			Sys.sleep( 1 )
		}
		
		# now we've got `tf.household` and `tf.person` on the local disk instead.
		# these have one record per household and one record per person, respectively.

		# create a place to store the tab-separated value file on the local disk
		hh.tsv <- tempfile()
		
		# convert..
		fwf2csv( 
			# the household-level file
			tf.household , 
			# to a tsv file
			hh.tsv ,
			# with these column names
			names = c( hh.stru$variable , 'fileno' ) ,
			# starting positions
			begin = c( hh.stru$beg , hh.stru$end[ nrow( hh.stru ) ] + 1 ) ,
			# ending positions
			end = c( hh.stru$end , hh.stru$end[ nrow( hh.stru ) ] + 10 )
		)

		# remove the pre-tsv file
		file.remove( tf.household )


		# create a place to store the tab-separated value file on the local disk
		person.tsv <- tempfile()
		
		# convert..
		fwf2csv( 
			# the person-level file
			tf.person , 
			# to a tsv file
			person.tsv , 
			# with these column names
			names = c( person.stru$variable , 'fileno' ) ,
			# starting positions
			begin = c( person.stru$beg , person.stru$end[ nrow( person.stru ) ] + 1 ) ,
			# ending positions
			end = c( person.stru$end , person.stru$end[ nrow( person.stru ) ] + 10 )
		)

		# remove the pre-tsv file
		file.remove( tf.person )
		
		# return a character vector (of length two) containing the location on the local disk
		# where the household-level and person-level tsv files have been saved.
		c( hh.tsv , person.tsv )
	}


# construct a function that..
# takes a character vector full of tab-separated files stored on the local disk
# imports them all into monetdb, merges (rectangulates) them into a merged (_m) table,
# and finally creates a sqlsurvey design object
pums.import.merge.design <-
	function( db , monet.url , fn , merged.tn , hh.tn , person.tn , hh.stru , person.stru ){
		
		# extract the household tsv file locations
		hh.tfs <- as.character( fn[ 1 , ] )
		
		# extract the person tsv file locations
		person.tfs <- as.character( fn[ 2 , ] )

		# read one of the household-level files into RAM..
		hh.h <- read.table( hh.tfs[3], header = TRUE , sep = '\t' , na.strings = "NA" )
		
		# unique(sapply( hh.h , dbDataType , dbObj = db ))
		
		# count the number of records in each file
		hh.lines <- sapply( hh.tfs , countLines )

		# read one of the person-level files into RAM..
		person.h <- read.table( person.tfs[3], header = TRUE , sep = '\t' , na.strings = "NA" )
		
		# unique(sapply( person.h , dbDataType , dbObj = db ))
		
		# count the number of records in each file
		person.lines <- sapply( person.tfs , countLines )

		# use the monet.read.tsv function
		# to read the household files into a table called `hh.tn` in the monet database
		monet.read.tsv(
			db ,
			hh.tfs ,
			hh.tn ,
			nrows = hh.lines ,
			structure = hh.h ,
			nrow.check = 10000
		)

		# use the monet.read.tsv function
		# to read the household files into a table called `hh.tn` in the monet database
		monet.read.tsv(
			db ,
			person.tfs ,
			person.tn ,
			nrows = person.lines ,
			structure = person.h ,
			nrow.check = 10000
		)
		
		# remove blank_# fields in the monetdb household table
		lf <- dbListFields( db , hh.tn )
		hh.blanks <- lf[ grep( 'blank_' , lf ) ]
		for ( i in hh.blanks ) dbSendUpdate( db , paste( 'alter table' , hh.tn , 'drop column' , i ) )

		# remove blank_# fields in the monetdb person table
		lf <- dbListFields( db , person.tn )
		person.blanks <- lf[ grep( 'blank_' , lf ) ]
		for ( i in person.blanks ) dbSendUpdate( db , paste( 'alter table' , person.tn , 'drop column' , i ) )


		# intersect( dbListFields( db , hh.tn ) , dbListFields( db , person.tn ) )

		# find overlapping fields
		nonmatch.fields <- 
			paste0( 
				"b." , 
				dbListFields( db , person.tn )[ !( dbListFields( db , person.tn ) %in% dbListFields( db , hh.tn ) ) ] , 
				collapse = ", "
			)

		# create the merge statement
		ij <- 
			paste( 
				"create table" ,
				merged.tn , 
				"as select a.* ," , 
				nonmatch.fields , 
				"from" , 
				hh.tn ,
				"as a inner join" , 
				person.tn , 
				"as b on a.fileno = b.fileno AND a.serialno = b.serialno WITH DATA" 
			)
		
		# create a new merged table (named according to the input parameter `merged.tn`
		dbSendUpdate( db , ij )

		# modify the `rectype` column for this new merged table so it's all Ms
		dbSendUpdate( db , paste( "update" , merged.tn , "set rectype = 'M'" ) )

		# confirm that the number of records in the merged file
		# matches the number of records in the person file
		stopifnot( 
			dbGetQuery( db , paste( "select count(*) as count from" , merged.tn ) ) == 
			dbGetQuery( db , paste( "select count(*) as count from" , person.tn ) )
		)

		print( paste( merged.tn , "created!" ) )
		

		# add a column containing all ones to the current table
		dbSendUpdate( db , paste0( 'alter table ' , merged.tn , ' add column one int' ) )
		dbSendUpdate( db , paste0( 'UPDATE ' , merged.tn , ' SET one = 1' ) )
		
		# add a column containing the record (row) number
		dbSendUpdate( db , paste0( 'alter table ' , merged.tn , ' add column idkey int auto_increment' ) )
		
		# store the names of factor/character variables #
		hh.char <- hh.stru[ hh.stru$char %in% TRUE , 'variable' ]
		person.char <- person.stru[ person.stru$char %in% TRUE , 'variable' ]
		
		# throw in rectype, of course
		mergefile.factor.variables <- unique( c( hh.char , person.char , 'rectype' ) )

		# finally, restrict the character vector to only columns that are actually in the merged table..
		mffv <- 
			intersect( 
				dbListFields( db , merged.tn ) , 
				mergefile.factor.variables 
			)
		# ..some of the blank_ columns may have been thrown out
		
		# end of names of factor/character variable storage #

		
		# create a sqlsurvey complex sample design object
		pums.design <-
			sqlsurvey(
				weight = 'pweight' ,		# weight variable column
				id = 1 ,					# sampling unit column (defined in the character string above)
				table.name = merged.tn ,	# table name within the monet database (defined in the character string above)
				key = "idkey" ,				# sql primary key column (created with the auto_increment line above)
				check.factors = mffv ,		# designate all of the mergefile factor variables, in one convenient character vector
				database = monet.url ,		# monet database location on localhost
				driver = MonetDB.R()
			)

		# ..and return that at the end of the function.
		pums.design
	}
