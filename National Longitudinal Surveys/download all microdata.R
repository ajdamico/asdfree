library(httr)
library(XML)
library(stringr)

# setwd( "C:/My Directory/NLS" )

studies <- GET( "https://www.nlsinfo.org/investigator/servlet1?get=STUDIES" )

study.names <- xpathSApply( content( studies ) , "//option" , xmlAttrs )

study.names <- study.names[ study.names != '-1' ]

tf <- tempfile() ; td <- tempdir()

						
for ( this.study in study.names ){
# for ( this.study in study.names[2] ){

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
			
				if ( attempt.count > 5 ) stop( "tried five times with no luck.  peace out." )
			
				attempt <-
					try( {

						GET( paste0( "https://www.nlsinfo.org/investigator/servlet1?set=STUDY&id=" , study.id , "&reset=true" ) )

						print( 
							paste( 
								"currently working on file" , 
								which( option.value == all.option.values ) ,
								"of" ,
								length( all.option.values ) ,
								"extract" ,
								option.value , 
								"attempt" , 
								attempt.count 
							) 
						)

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
				
				if( class( attempt ) == 'try-error' ) Sys.sleep( 60 ) else Sys.sleep( 15 )	
					
			}
				
		}



		for ( ov in all.option.values ){


			load( paste0( this.dir , "/" , ov , ".rda" ) )
			
			if ( ov == all.option.values[1] ){
			
				x <- get( ov )
				
				first.rowsize <- nrow( x )
				
			} else {
			
				load( paste0( this.dir , "/" , "all columns.rda" ) )

				x <- merge( x , get( ov ) )
				
				# this never changes.
				stopifnot( nrow( x ) == first.rowsize )
				
			}

			save( x , file = paste0( this.dir , "/" , "all columns.rda" ) )
			
			rm( list = c( 'x' , ov ) )
			
			gc()

		}
	}
}

file.remove( tf )

unlink( d , recursive = TRUE )
