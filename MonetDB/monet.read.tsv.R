# this is a slight modification of the monet.read.csv function found in the MonetDB.R package
# this is particularly useful alongside the descr package's fwf2csv function,
# which converts ascii files to tab-separated files.  this new monet.read.tsv will read in those straightaway!

monet.read.tsv <-
	function ( 
		conn , 
		files , 
		tablename , 
		nrows , header = TRUE , 
		locked = FALSE , 
		na.strings = "" , 
		nrow.check = 500 ,
		structure = NULL
	) {
    
	if (length(na.strings) > 1) stop("na.strings must be of length 1")

	# if a structure file is passed in
	if ( !is.null( structure ) ){
		dbWriteTable(conn, tablename, structure[FALSE, ])
	} else {
	
		# otherwise, determine headers yourself
		
		headers <- lapply(files, read.table, header = header , sep = '\t' , na.strings = "NA", nrows = nrow.check)
		
		if (length(files) > 1) {
			nn <- sapply(headers, ncol)
			if (!all(nn == nn[1])) stop("Files have different numbers of columns")
			nms <- sapply(headers, names)
			if (!all(nms == nms[, 1])) stop("Files have different variable names")
			types <- sapply(headers, function(df) sapply(df, dbDataType, dbObj = conn))
			if (!all(types == types[, 1])) stop("Files have different variable types")
		}
	
		dbWriteTable(conn, tablename, headers[[1]][FALSE, ])
	}
	

    if (header || !missing(nrows)) {
        if (length(nrows) == 1) nrows <- rep(nrows, length(files))
        for (i in seq_along(files)) {
            cat(files[i], thefile <- normalizePath(files[i]), "\n")
            dbSendQuery(
				conn , 
				paste(
					"copy", 
					format(nrows[i], scientific = FALSE), 
					"offset 2 records into", 
					tablename, 
					"from", 
					paste("'", thefile, "'", sep = ""), 
					"using delimiters '\t' NULL as", 
					paste("'", na.strings[1], "'", sep = ""), 
					if (locked) "LOCKED"
				)
			)
        }
    } else {
        for (i in seq_along(files)) {
            cat(files[i], thefile <- normalizePath(files[i]), "\n")
            dbSendQuery(
				conn, 
				paste(
					"copy into", 
					tablename, 
					"from", 
					paste("'", thefile, "'", sep = ""), 
					"using delimiters '\t' NULL as ", 
					paste("'", na.strings[1], "'", sep = ""), 
					if (locked)"LOCKED"
				)
			)
        }
    }
    dbGetQuery(conn, paste("select count(*) from", tablename))
}
