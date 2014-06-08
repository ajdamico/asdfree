library(httr)
library(XML)
library(stringr)
library(RSQLite)

# setwd( "C:/My Directory/NLS" )
# setwd( "R:/National Longitudinal Surveys/" )

studies <- GET( "https://www.nlsinfo.org/investigator/servlet1?get=STUDIES" )

study.names <- xpathSApply( content( studies ) , "//option" , xmlAttrs )

study.names <- study.names[ study.names != '-1' ]

tf <- tempfile() ; td <- tempdir()

						
for ( this.study in study.names ){
# for ( this.study in study.names[5] ){

	substudies <- 
		GET( 
			paste0( 
				"https://www.nlsinfo.org/investigator/servlet1?get=SUBSTUDIES&study=" , 
				this.study 
			) 
		)
		
	substudy.numbers <- xpathSApply( content( substudies ) , "//option" , xmlAttrs )
	
	substudy.names <- xpathSApply( content( substudies ) , "//option" , xmlValue )
	
	substudy.numbers <- unlist( substudy.numbers )
	
	substudy.numbers <- substudy.numbers[ names( substudy.numbers ) == 'value' ]
	
	substudy.names <- substudy.names[ substudy.numbers != "-1" ]
	
	substudy.numbers <- substudy.numbers[ substudy.numbers != "-1" ]
	
	substudy.names <- str_trim( substudy.names )
	
	# content( study.html )
	# study.block <- htmlParse( study.html , asText = TRUE )
	# study.id <- tail( xpathSApply(study.block, "//option", function(u) xmlAttrs(u)["value"]) , 1 )

	for ( study.id in substudy.numbers ){
	
		this.dir <- paste0( getwd() , "/" , substudy.names[ study.id == substudy.numbers ] )
	
		dir.create( this.dir , showWarnings = FALSE , recursive = TRUE )
		
		GET( paste0( "https://www.nlsinfo.org/investigator/servlet1?set=STUDY&id=" , study.id ) )

		z <- GET( "https://www.nlsinfo.org/investigator/servlet1?get=SEARCHVALUES&type=RNUM" )

		doc <- htmlParse( z )
		opts <- getNodeSet( doc , "//select/option" )
		all.option.values <- sapply( opts , xmlGetAttr , "value" )
		all.option.values <- all.option.values[ all.option.values != "-1" ]

		for ( option.value in all.option.values ){


			attempt.count <- 0
			attempt <- try( stop() , silent = TRUE )
			
			while( class( attempt ) == 'try-error' ){
				
				attempt.count <- attempt.count + 1
			
				# display any actual errors.
				if ( attempt.count > 1 ) print( attempt )
			
				if ( attempt.count > 5 ) stop( "tried five times with no luck.  peace out." )
			
				attempt <-
					try( {

						GET( paste0( "https://www.nlsinfo.org/investigator/servlet1?set=STUDY&id=" , study.id , "&reset=true" ) )

						print( 
							paste( 
								"currently downloading extract" , 
								which( option.value == all.option.values ) ,
								"of" ,
								length( all.option.values ) ,
								"extract" ,
								option.value , 
								"attempt" , 
								attempt.count 
							) 
						)

						
						GET( "https://www.nlsinfo.org/investigator/servlet1?set=preference&pref=all" )
						
						GET( paste0( "https://www.nlsinfo.org/investigator/servlet1?get=Results&xml=true&criteria=RNUM%7CSW%7C" , option.value , "&sortKey=RNUM&sortOrder=ascending&&PUBID=noid&limit=all" ) )
					
						GET( "https://www.nlsinfo.org/investigator/servlet1?set=tagset&select=all&value=true" )

						# add `identification code` to every query, no matter what.
						# GET( "https://www.nlsinfo.org/investigator/servlet1?get=ResultCount&criteria=QTEXT%7CCNT%7Cidentification%20code" )
						# GET( "https://www.nlsinfo.org/investigator/servlet1?set=tagset&select=all&value=true" )
						# no longer necessary now that steve set to default
						
						job.char <- GET( "https://www.nlsinfo.org/investigator/servlet1?collection=on&sas=off&spss=off&stata=off&codebook=on&csv=on&event=start&cmd=extract&desc=default" )
													
						job.id <- gsub( 'job:' , '' , as.character( job.char ) )

						GET( "https://www.nlsinfo.org/investigator/servlet1?get=downloads&study=current" )


						v <- ""
						
						while( !( grepl( "{\"status_response\":{\"message\":\"\",\"name\"" , as.character( v ) , fixed = TRUE ) ) ){
							
							v <- GET( paste0( "https://www.nlsinfo.org/investigator/servlet1?job=" , job.id , "&event=progress&cmd=extract&_=" , as.numeric( Sys.time() ) * 1000 ) )
						
							# if the download hits an error, break out of the current loop.
							ep <- FALSE
							
							# see if the current page contains an error page text
							# instead of actual data.
							try( ep <- xpathSApply( htmlParse( v , asText = TRUE ) , '//title' , xmlValue ) == 'Error Page' , silent = TRUE )
							
							# if it does contain an error page, break the program.
							if( ( length( ep ) > 0 ) && ( ep ) ) stop( "Error Page" )
							# first successful usage of `&&` operator.  pat on the back.
						
							msg <- strsplit( strsplit( as.character(v) , 'message\":\"' )[[1]][2] , '\",\"name' )[[1]][1]
							
							cat( "    " , msg , "\r" )
							
							# give the progress bar fifteen seconds before it
							# refreshes so it's not overloading the website
							Sys.sleep( 15 )
							
						}

						u <- NULL
						
						u$headers$status <- 500

						start.time <- Sys.time()
						
						while( u$headers$status == 500 ){

							# if you've been waiting more than two minutes, just stop.
							if ( Sys.time() - start.time > 120 ) stop( 'waited two minutes after extract created, still no download' )
						
							u <- GET( paste0( "https://www.nlsinfo.org/investigator/downloads/" , job.id , "/default.zip" ) )
							
						}

						writeBin( content( u , "raw" ) , tf )
						
						d <- unzip( tf , exdir = td )

						csv <- d[ grep( '.csv' , d , fixed = TRUE ) ]

						assign( option.value , read.csv( csv ) )

						save( list = option.value , file = paste0( this.dir , "/" , option.value , ".rda" ) )
						
						rm( list = c( 'u' , option.value ) )
						
						gc()
						
					} , 
					silent = TRUE 
				)
				
				# wait the same number of minutes as you have attempted-counted,
				# but after the last attempt, don't wait at all.
				if( class( attempt ) == 'try-error' ) Sys.sleep( 60 * ifelse( attempt.count >= 5 , 0 , attempt.count ) ) else Sys.sleep( 15 )
					
			}
				
		}



		x <- NULL
		
		re.start <- FALSE
		
		db <- dbConnect( SQLite() , paste0( this.dir , "/" , 'study.db' ) )
				
		for ( ov in all.option.values ){

			print( 
				paste( 
					"currently merging file" , 
					which( ov == all.option.values ) ,
					"of" ,
					length( all.option.values ) ,
					"extract" ,
					ov
				) 
			)
		
			load( paste0( this.dir , "/" , ov , ".rda" ) )
				
			dbWriteTable( db , ov , get( ov ) )
				
			if ( ov == all.option.values[1] | re.start ){
							
				first.rowsize <- nrow( get( ov ) )
							
				dbWriteTable( db , 'x' , get( ov ) )
				
				re.start <- FALSE
				
			} else {

				( columns.in.both.dfs <- intersect( dbListFields( db , 'x' ) , names( get( ov ) ) ) )
			
				dbRemoveTable( db , 'y' )
				
				sql <- 
					paste( 
						'CREATE TABLE y AS SELECT * FROM x INNER JOIN' , 
						ov , 
						'USING (' ,
						paste( columns.in.both.dfs , collapse = " , " ) ,
						')'
					)
			
				dbSendQuery( db , sql )
				
				dbRemoveTable( db , 'x' )
				
				# dbRemoveTable( db , ov )
				
				dbSendQuery( db , 'CREATE TABLE x as SELECT * FROM y' )
			
				# this never changes.
				stopifnot( as.numeric( dbGetQuery( db , 'SELECT count(*) FROM x' ) ) == first.rowsize )
				
				
				if ( length( dbListFields( db , 'x' ) ) > 25000 ){
				
					if( is.null( x ) ){
					
						x <- dbReadTable( db , 'x' )
		
					} else {
					
						x <- merge( x , dbReadTable( db , 'x' ) )
					
					}
		
					dbRemoveTable( db , 'x' )
								
					re.start <- TRUE
					
					stopifnot( nrow( x ) == first.rowsize )
					
					gc()
					
				}
				
				
			}
			
			rm( list = ov )
			
			gc()

		}
		
		if( !re.start ){
			x <- merge( x , dbReadTable( db , 'x' ) )
		
			dbRemoveTable( db , 'x' )
			
			dbRemoveTable( db , 'y' )
		}
		
		dbDisconnect( db )
		
		save( x , file = paste0( this.dir , "/all columns.rda" ) )
		
		rm( x )
		
		gc()
	
	}
}

file.remove( tf )

unlink( d , recursive = TRUE )
