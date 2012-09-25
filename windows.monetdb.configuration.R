windows.monetdb.configuration <-
	function( 
		# choose a path on the local drive to store the .bat file
		# that will be used to run the monetdb server
		bat.file.location , 
		
		# find the main path to the monetdb installation program
		monetdb.program.path ,
		
		# set the path to the directory where the data will be stored
		database.directory ,
		
		# choose a database name
		dbname ,
		
		# choose a database port
		# this port should not conflict with other monetdb databases
		# on your local computer.  two databases with the same port number
		# cannot be accessed at the same time
		dbport
	){

		# confirm that the last four characters of the bat file end in '.bat'
		if ( substr( bat.file.location , nchar( bat.file.location ) - 3 , nchar( bat.file.location ) ) != '.bat' ) stop( 'bat.file.location must end as .bat' )
	
		# if the directory containing the .bat file doesn't exist, break
		if ( !file.exists( dirname( bat.file.location ) ) )	stop( paste( "bat.file.location's directory does not yet exist.  you must create the directory" , dirname( bat.file.location ) , "first" ) )
	
		# if the .bat file already exists, break
		if ( file.exists( bat.file.location ) ) stop( "the .bat file already exists.  if you're sure you want to overwrite it, manually delete it first" )
		
		
		# if the database directory exists, break
		if ( file.exists( file.path( database.directory ) ) ) stop( paste( "the directory" , database.directory , "already exists.  if you've already created this monetdb database,\nyou do not need to re-run this function.  if you're sure you want to overwrite it, delete the directory first." ) )
		
		
		# switch all slashes to match windows
		monetdb.program.path <- normalizePath( monetdb.program.path , mustWork = FALSE )
		database.directory <- normalizePath( database.directory , mustWork = FALSE )
			
	
		# store all file lines for the .bat into a character vector
		bat.contents <-
			c(
				"@echo off" ,
				"setlocal" ,
				"rem set the path containing mserver5.exe on your windows machine" ,
				paste0( "set MONETDB=" , monetdb.program.path ) ,
				"rem remove the final backslash from the path" ,
				"set MONETDB=%MONETDB:~0,-1%" ,
				"rem extend the search path with our EXE and DLL folders" ,
				"rem we depend on pthreadVC2.dll having been copied to the lib folder" ,
				"set PATH=%MONETDB%\\bin;%MONETDB%\\lib;%MONETDB%\\lib\\MonetDB5;%PATH%" ,
				"rem choose the location of this database" ,
				paste0( "set MONETDBDIR=" , database.directory ) ,
				paste0( "set MONETDBFARM=\"--dbfarm=" , database.directory , "dbfarm\"" ) ,
				"rem the SQL log directory used to be in %MONETDBDIR%, but we now" ,
				"rem prefer it inside the dbfarm, so move it there" ,
				"if not exist \"%MONETDBDIR%\\sql_logs\" goto skipmove" ,
				"for /d %%i in (\"%MONETDBDIR%\"\\sql_logs\\*) do move \"%%i\" \"%MONETDBDIR%\\dbfarm\"\\%%~ni\\sql_logs" ,
				"rmdir \"%MONETDBDIR%\\sql_logs\"" ,
				":skipmove" ,
				"rem start the real server" ,
				paste0( "\"%MONETDB%\\bin\\mserver5.exe\" --set \"prefix=%MONETDB%\" --set \"exec_prefix=%MONETDB%\" %MONETDBFARM% %* --dbname=\"" , dbname , "\" --set mapi_port=" , dbport ) ,
				"if ERRORLEVEL 1 pause" ,
				"endlocal"
			)
		
		# write the .bat contents to a file on the local disk
		writeLines( bat.contents , bat.file.location )
	
		# just return that it worked
		TRUE
	}
