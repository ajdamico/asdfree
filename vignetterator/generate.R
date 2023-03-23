commit_memo <- "'sbo haiku'"

# source( file.path( path.expand( "~" ) , "Github/asdfree/vignetterator/generate.R" ) )



# non-survey, not database-backed (ahrf)
# database-backed non-survey (nppes)
# survey, not database-backed, not multiply imputed (yrbss)
# database-backed survey, not multiply imputed (pnad)
# multiply-imputed survey, not database-backed (scf)
# multiply-imputed, database-backed survey (pisa)


source( file.path( path.expand( "~" ) , "Github\\asdfree\\vignetterator\\descriptive_statistics_blocks.R" ) )
source( file.path( path.expand( "~" ) , "Github\\asdfree\\vignetterator\\measures_of_uncertainty_blocks.R" ) )
source( file.path( path.expand( "~" ) , "Github\\asdfree\\vignetterator\\tests_of_association_blocks.R" ) )
source( file.path( path.expand( "~" ) , "Github\\asdfree\\vignetterator\\syntaxtractor.R" ) )


needs_actions_build_status_line <- '<a href="https://github.com/asdfree/chapter_tag/actions"><img src="https://github.com/asdfree/chapter_tag/actions/workflows/r.yml/badge.svg" alt="Github Actions Badge"></a>'

needs_local_build_status_line <- '```{r , echo = FALSE }\n\nmost_recent_build_date <- gsub( "\\-" , " " , if( dir.exists( "_bookdown_files/" ) ) as.Date( file.info( "_bookdown_files/" )$ctime ) else Sys.Date() )\n\nchapter_tag_badge <- paste0( "<img src=\'https://img.shields.io/badge/tested%20on%20my%20laptop:-" , most_recent_build_date , "-brightgreen\' alt=\'Local Testing Badge\'>" )\n\n```\n\n`r chapter_tag_badge`\n\n'


needs_dplyr_block <- '---\n\n## Analysis Examples with `dplyr` \\\\ {-}\n\nThe R `dplyr` library offers an alternative grammar of data manipulation to base R and SQL syntax.  [dplyr](https://github.com/tidyverse/dplyr/) offers many verbs, such as `summarize`, `group_by`, and `mutate`, the convenience of pipe-able functions, and the `tidyverse` style of non-standard evaluation.  [This vignette](https://cran.r-project.org/web/packages/dplyr/vignettes/dplyr.html) details the available features.  As a starting point for CHAPTER_TAG users, this code replicates previously-presented examples:\n\n```{r eval = FALSE , results = "hide" }\nlibrary(dplyr)\ntbl_initiation_line\n```\nCalculate the mean (average) of a linear variable, overall and by groups:\n```{r eval = FALSE , results = "hide" }\nchapter_tag_tbl %>%\n\tsummarize( mean = mean( linear_variable linear_narm ) )\n\nchapter_tag_tbl %>%\n\tgroup_by( group_by_variable ) %>%\n\tsummarize( mean = mean( linear_variable linear_narm ) )\n```'

needs_datatable_block <- "---\n\n## Analysis Examples with `data.table` \\\\ {-}\n\nThe R `data.table` library provides a high-performance version of base R's data.frame with syntax and feature enhancements for ease of use, convenience and programming speed.  [data.table](https://r-datatable.com) offers concise syntax: fast to type, fast to read, fast speed, memory efficiency, a careful API lifecycle management, an active community, and a rich set of features.  [This vignette](https://cran.r-project.org/web/packages/data.table/vignettes/datatable-intro.html) details the available features.  As a starting point for CHAPTER_TAG users, this code replicates previously-presented examples:\n\n```{r eval = FALSE , results = 'hide' }\nlibrary(data.table)\nchapter_tag_dt <- data.table( chapter_tag_df )\n```\nCalculate the mean (average) of a linear variable, overall and by groups:\n```{r eval = FALSE , results = 'hide' }\nchapter_tag_dt[ , mean( linear_variable linear_narm ) ]\n\nchapter_tag_dt[ , mean( linear_variable linear_narm ) , by = group_by_variable ]\n```"

needs_duckdb_block <- "---\n\n## Analysis Examples with `duckdb` \\\\ {-}\n\nThe R `duckdb` library provides an embedded analytical data management system with support for the Structured Query Language (SQL).  [duckdb](https://duckdb.org) offers a simple, feature-rich, fast, and free SQL OLAP management system.  [This vignette](https://duckdb.org/docs/api/r) details the available features.  As a starting point for CHAPTER_TAG users, this code replicates previously-presented examples:\n\n```{r eval = FALSE , results = 'hide' }\nlibrary(duckdb)\ncon <- dbConnect( duckdb::duckdb() , dbdir = 'my-db.duckdb' )\ndbWriteTable( con , 'chapter_tag' , chapter_tag_df )\n```\nCalculate the mean (average) of a linear variable, overall and by groups:\n```{r eval = FALSE , results = 'hide' }\ndbGetQuery( con , 'SELECT AVG( linear_variable ) FROM chapter_tag' )\n\ndbGetQuery(\n\tcon ,\n\t'SELECT\n\t\tgroup_by_variable ,\n\t\tAVG( linear_variable )\n\tFROM\n\t\tchapter_tag\n\tGROUP BY\n\t\tgroup_by_variable'\n)\n```"



pull_chunk <-
	function( text_file , code_chunk ){
	
		metadata_lines <- readLines( text_file )
		start_line <- grep( paste0( "~~~\\{(.*)" , code_chunk , "(.*)\\}(.*)" ) , metadata_lines ) + 1
		if( length( start_line ) == 0 ) return( "" )
		end_lines <- grep( "~~~" , metadata_lines )
		end_line <- min( end_lines[ end_lines >= start_line ] ) - 1
		
		metadata_lines[ start_line:end_line ]
	}

pull_line <-
	function( text_file , code_line ){
		this_line <- grep( paste0( "^" , code_line , ":" ) , readLines( text_file ) , value = TRUE )
		if( length( this_line ) == 0 ) "" else as.character( gsub( paste0( code_line , ":( +)?" ) , "" , this_line ) )
	}

book_folder <- "C:/Users/anthonyd/Documents/Github/asdfree/"
sub_lines <- c( "chapter_title" , "password_parameters" , "table_structure" , "generalizable_population" , "publication_period" , "administrative_organization" , "sql_tablename" , "income_variable_description" , "income_variable" , "ratio_estimation_numerator" , "ratio_estimation_denominator" , "group_by_variable" , "categorical_variable" , "linear_variable" , "binary_variable" , "subset_definition_description" , "subset_definition" , "linear_narm" , "categorical_narm" , "ratio_narm" , "binary_narm" )
sub_chunks <- c( "reading_block" , "download_and_import_block" , "analysis_examples_survey_design" , "variable_recoding_block" , "replication_example_block" , "dataset_introduction" , "intermission_block" , "convey_block" , "replacement_block" )
needs_this_block <- c( "needs_srvyr_block" , "needs_dplyr_block" , "needs_datatable_block" , "needs_duckdb_block" , "needs_actions_build_status_line" , "needs_local_build_status_line" )


library(bookdown)
library(rmarkdown)
library(stringr)

metafiles <- sort( list.files( paste0( book_folder , 'metadata/' ) , full.names = TRUE ) )

full_text <- lapply( metafiles , readLines )

chapter_tag <- gsub( "\\.txt" , "" , basename( metafiles ) )

for( this_line in sub_lines ){

	assign( this_line , lapply( metafiles , function( fn ) pull_line( fn , this_line ) ) )

}


# add horizontal lines on top of certain chunks
horizontal_line_chunks <-
	c( "convey_block" , "replication_example_block" )

for( this_chunk in sub_chunks ){

	current_chunk <- lapply( metafiles , function( fn ) pull_chunk( fn , this_chunk ) )

	if( this_chunk %in% horizontal_line_chunks ){
		
		current_chunk[ current_chunk != "" ] <-
			lapply( 
				current_chunk[ current_chunk != "" ] ,
				function( w ) c( "---\n\n" , w )
			)
			
	}

	assign( this_chunk , current_chunk )

}



# move all rmd files in /posts/ to the main folder
rmd_posts <- list.files( paste0( book_folder , "posts/" ) , full.names = TRUE )
# overwrite only posts that have changed (so as not to invalidate the cache)
for( this_post in rmd_posts ){
	if(
		is.na( tools::md5sum( gsub( "posts\\/" , "" , this_post ) ) )
		
		||
		
		( tools::md5sum( this_post ) != tools::md5sum( gsub( "posts\\/" , "" , this_post ) ) )
		
	){
		
			file.copy(
				this_post ,
				gsub( "posts\\/" , "" , this_post ) ,
				overwrite = TRUE
			)
	}
}




for ( i in seq_along( chapter_tag ) ){

	this_rmd <- paste0( book_folder , chapter_tag[ i ] , ".Rmd" )

	rmd_lines <- readLines( paste0( book_folder , "skeleton/skeleton.Rmd" ) )
	
	is_survey <- any( grepl( "library(survey)" , full_text[[i]] , fixed = TRUE ) )
	is_mi <- any( grepl( "library(mitools)" , full_text[[i]] , fixed = TRUE ) )
	is_db <- any( grepl( "library(DBI)" , full_text[[i]] , fixed = TRUE ) ) 
	
	needs_srvyr_block <- paste0( '---\n\n## Analysis Examples with `srvyr` \\\\ {-}\n\nThe R `srvyr` library calculates summary statistics from survey data, such as the mean, total or quantile using [dplyr](https://github.com/tidyverse/dplyr/)-like syntax. [srvyr](https://github.com/gergness/srvyr) allows for the use of many verbs, such as `summarize`, `group_by`, and `mutate`, the convenience of pipe-able functions, the `tidyverse` style of non-standard evaluation and more consistent return types than the `survey` package.  [This vignette](https://cran.r-project.org/web/packages/srvyr/vignettes/srvyr-vs-survey.html) details the available features.  As a starting point for CHAPTER_TAG users, this code replicates previously-presented examples:\n\n```{r eval = FALSE , results = "hide" }\n' , if( is_db ) 'library(dbplyr)\n' , 'library(srvyr)\nchapter_tag_srvyr_design <- as_survey( chapter_tag_design )\n```\nCalculate the mean (average) of a linear variable, overall and by groups:\n```{r eval = FALSE , results = "hide" }\nchapter_tag_srvyr_design %>%\n\tsummarize( mean = survey_mean( linear_variable linear_narm ) )\n\nchapter_tag_srvyr_design %>%\n\tgroup_by( group_by_variable ) %>%\n\tsummarize( mean = survey_mean( linear_variable linear_narm ) )\n```' )


	rmd_lines <- gsub( "kind_of_analysis_examples" , if( is_survey ) "the `survey` library" else if( is_db ) "SQL and `RSQLite`" else "base R" , rmd_lines )
	
	for( this_block in needs_this_block ){
		rmd_lines <- gsub( this_block , if( any( grepl( paste0( "^" , this_block , ": yes" ) , tolower( full_text[[i]] ) ) ) ) get( this_block ) else "" , rmd_lines )
	}
	
	if( !is_survey ) rmd_lines <- gsub( "tbl_initiation_line" , if( is_db ) "library(dbplyr)\ndplyr_db <- dplyr::src_sqlite( dbdir )\nchapter_tag_tbl <- tbl( dplyr_db , 'sql_tablename' )" else "chapter_tag_tbl <- as_tibble( chapter_tag_df )" , rmd_lines )
	

	
	# standalone dataset, survey design, multiply-imputed survey design, database-backed survey design, or multiply-imputed database-backed survey design
	
	if( is_db ){
		stop( "revisit this" )
	} else {
		rmd_lines <- gsub( "^save_a_what_line" , '\n\n### Save locally \\\\ {-}\n\nSave the object at any point:\n\n```{r eval = FALSE , results = "hide" }\n# chapter_tag_fn <- file.path( path.expand( "~" ) , "CHAPTER_TAG" , "this_file.rds" )\n# saveRDS( chapter_tag_df , file = chapter_tag_fn , compress = FALSE )\n```\n\nLoad the same object:\n\n```{r eval = FALSE , results = "hide" }\n# chapter_tag_df <- readRDS( chapter_tag_fn )\n```' , rmd_lines )
	}
		
	# standalone dataset, survey design, multiply-imputed survey design, database-backed survey design, or multiply-imputed database-backed survey design
	construct_a_this_line <- 
		paste0( 
			if( is_survey ) "### Survey Design Definition {-}\nConstruct a " else if( is_db ) "### Database Definition {-}\nConnect to a " ,
			if( is_mi ) "multiply-imputed, " ,
			if( is_db ) "database" ,
			if( is_survey & is_db ) "-backed " ,
			if( is_survey ) "complex sample survey design" ,
			if( !is_survey & !is_db ) "" ,
			if( is_survey | is_db ) ":"
		)				
	
	rmd_lines <- gsub( "^construct_a_what_line" , construct_a_this_line , rmd_lines )

	unweighted_counts_block <-
		if( is_survey ){
			if( is_mi ){
				'Count the unweighted number of records in the survey sample, overall and by groups:\n```{r eval = FALSE , results = "hide" }\nMIcombine( with( chapter_tag_design , svyby( ~ one , ~ one , unwtd.count ) ) )\n\nMIcombine( with( chapter_tag_design , svyby( ~ one , ~ group_by_variable , unwtd.count ) ) )\n```'
			} else {
				'Count the unweighted number of records in the survey sample, overall and by groups:\n```{r eval = FALSE , results = "hide" }\nsum( weights( chapter_tag_design , "sampling" ) != 0 )\n\nsvyby( ~ one , ~ group_by_variable , chapter_tag_design , unwtd.count )\n```'
			}
		} else if( is_db ){
			'Count the unweighted number of records in the SQL table, overall and by groups:\n```{r eval = FALSE , results = "hide" }\ndbGetQuery( db , "SELECT COUNT(*) FROM sql_tablename" )\n\ndbGetQuery( db ,\n\t"SELECT\n\t\tgroup_by_variable ,\n\t\tCOUNT(*) \n\tFROM sql_tablename\n\tGROUP BY group_by_variable"\n)\n```'
		} else {
			'Count the unweighted number of records in the table, overall and by groups:\n```{r eval = FALSE , results = "hide" }\nnrow( chapter_tag_df )\n\ntable( chapter_tag_df[ , "group_by_variable" ] , useNA = "always" )\n```'
		}

	rmd_lines <- gsub( "^unweighted_counts_block$" , unweighted_counts_block , rmd_lines )

	
	# survey_only_* blocks
	if( is_survey ){

		weighted_counts_block <-
			if( is_mi ){
				'Count the weighted size of the generalizable population, overall and by groups:\n```{r eval = FALSE , results = "hide" }\nMIcombine( with( chapter_tag_design , svytotal( ~ one ) ) )\n\nMIcombine( with( chapter_tag_design ,\n\tsvyby( ~ one , ~ group_by_variable , svytotal )\n) )\n```'
			} else {
				'Count the weighted size of the generalizable population, overall and by groups:\n```{r eval = FALSE , results = "hide" }\nsvytotal( ~ one , chapter_tag_design )\n\nsvyby( ~ one , ~ group_by_variable , chapter_tag_design , svytotal )\n```'
			}
			
		rmd_lines <- gsub( "^survey_only_weighted_counts_block$" , paste0( '### Weighted Counts {-}\n' , weighted_counts_block ) , rmd_lines )
		
	} else {
	
		rmd_lines <- gsub( "^survey_only_(.*)" , "" , rmd_lines )
		
	}
	
	

	descriptive_statistics_block <-
		if( is_survey ) {
			if( is_mi ) mi_descriptive_block else survey_descriptive_block
		} else if( is_db ) db_descriptive_block else base_descriptive_block

	rmd_lines <- gsub( "^descriptive_statistics_block$" , descriptive_statistics_block , rmd_lines )


	measures_of_uncertainty_block <-
		if( is_survey ) {
			if( is_mi ) mi_measures_of_uncertainty_block else survey_measures_of_uncertainty_block
		} else if( is_db ) db_measures_of_uncertainty_block else base_measures_of_uncertainty_block

	rmd_lines <- gsub( "^measures_of_uncertainty_block$" , measures_of_uncertainty_block , rmd_lines )

	
	tests_of_association_block <-
		if( is_survey ) {
			if( is_mi ) mi_tests_of_association_block else survey_tests_of_association_block
		} else if( is_db ) db_tests_of_association_block else base_tests_of_association_block

	rmd_lines <- gsub( "^tests_of_association_block$" , tests_of_association_block , rmd_lines )

	
	
	subsetting_block <-
		if( is_survey ){
			if( is_mi ){
				'Restrict the survey design to subset_definition_description:\n```{r eval = FALSE , results = "hide" }\nsub_chapter_tag_design <- subset( chapter_tag_design , subset_definition )\n```\nCalculate the mean (average) of this subset:\n```{r eval = FALSE , results = "hide" }\nMIcombine( with( sub_chapter_tag_design , svymean( ~ linear_variable linear_narm ) ) )\n```'
			} else {
				'Restrict the survey design to subset_definition_description:\n```{r eval = FALSE , results = "hide" }\nsub_chapter_tag_design <- subset( chapter_tag_design , subset_definition )\n```\nCalculate the mean (average) of this subset:\n```{r eval = FALSE , results = "hide" }\nsvymean( ~ linear_variable , sub_chapter_tag_design linear_narm )\n```'
			}
		} else if( is_db ){
			'Limit your SQL analysis to subset_definition_description with `WHERE`:\n```{r eval = FALSE , results = "hide" }\ndbGetQuery( db ,\n\t"SELECT\n\t\tAVG( linear_variable )\n\tFROM sql_tablename\n\tWHERE subset_definition"\n)\n```'
		} else {
			'Limit your `data.frame` to subset_definition_description:\n```{r eval = FALSE , results = "hide" }\nsub_chapter_tag_df <- subset( chapter_tag_df , subset_definition )\n```\nCalculate the mean (average) of this subset:\n```{r eval = FALSE , results = "hide" }\nmean( sub_chapter_tag_df[ , "linear_variable" ] linear_narm )\n```'
		}

	rmd_lines <- gsub( "^subsetting_block$" , subsetting_block , rmd_lines )

		
	
	for( this_chunk in sub_chunks ){
		rmd_lines <- gsub( this_chunk , paste( get( this_chunk )[[i]] , collapse = "\n" ) , rmd_lines )
	}

	for( this_line in c( sub_lines , "chapter_tag" ) ){
		rmd_lines <- gsub( this_line , get( this_line )[ i ] , rmd_lines )
		rmd_lines <- gsub( toupper( this_line ) , toupper( get( this_line )[ i ] ) , rmd_lines )
	}
	
	
	rmd_lines <- gsub( "\\\\\\\\n" , '\n' , rmd_lines )
	rmd_lines <- gsub( "\\\\\\\\t" , '\t' , rmd_lines )
	rmd_lines <- paste( rmd_lines , collapse = "\n" )
	
	while( grepl( "\n\n\n" , rmd_lines ) ) rmd_lines <- gsub( "\n\n\n" , "\n\n" , rmd_lines )
	while( grepl( "\n\t\n\t\n" , rmd_lines ) ) rmd_lines <- gsub( "\n\t\n\t\n" , "\n\t\n" , rmd_lines )
	while( grepl( "  " , rmd_lines ) ) rmd_lines <- gsub( "  " , " " , rmd_lines )
	
	rmd_lines <- gsub( "\t0.5 , na.rm = TRUE" , "\t0.5 ,\n\tna.rm = TRUE" , rmd_lines )
	rmd_lines <- gsub( "\t\tsvymean , na.rm = TRUE" , "\t\tsvymean ,\n\t\tna.rm = TRUE" , rmd_lines )
	rmd_lines <- gsub( "\tsvymean , na.rm = TRUE" , "\tsvymean ,\n\tna.rm = TRUE" , rmd_lines )
	rmd_lines <- gsub( "\tmean , na.rm = TRUE" , "\tmean ,\n\tna.rm = TRUE" , rmd_lines )
	rmd_lines <- gsub( "\tvar , na.rm = TRUE" , "\tvar ,\n\tna.rm = TRUE" , rmd_lines )
	rmd_lines <- gsub( "\tsum , na.rm = TRUE" , "\tsum ,\n\tna.rm = TRUE" , rmd_lines )
	rmd_lines <- gsub( "\n\t([a-z]+)_design , na\\.rm = TRUE\n" , "\n\t\\1_design ,\n\tna.rm = TRUE\n" , rmd_lines )
	
	if( length( replacement_block[[i]] ) > 1 ){
		for( this_replacement in seq( 2 , length( replacement_block[[i]] ) , by = 2 ) ) rmd_lines <- gsub( replacement_block[[i]][ this_replacement - 1 ] , replacement_block[[i]][ this_replacement ] , rmd_lines , fixed = TRUE )
	}
	
	writeLines( rmd_lines , this_rmd )
	
}



# overwrite non-evaluation with run + cache
rmd_files <- grep( "\\.Rmd$" , list.files( file.path( path.expand( "~" ) , "Github/asdfree/" ) , full.names = TRUE ) , value = TRUE )
local_testing_rmd_files <- sapply( rmd_files , function( w ) any( grepl( "Local Testing Badge" , readLines( w ) ) ) )
local_testing_rmd_files <- names( local_testing_rmd_files[ local_testing_rmd_files ] )
for( this_rmd in local_testing_rmd_files ) writeLines( gsub( "eval = FALSE" , "cache = TRUE , warning = FALSE" , readLines( this_rmd ) ) , this_rmd )


setwd( book_folder )
clean_site( preview = FALSE )
render_site(output_format = 'bookdown::gitbook', encoding = 'UTF-8')
# render_site( encoding = 'UTF-8' )

# redirect "edit" buttons on metadata-driven pages #
html_files <- 
	grep( 
		"html$" ,
		list.files( 
			file.path( path.expand( "~" ) , "Github\\asdfree\\docs" ) ,
			full.names = TRUE ,
			recursive = FALSE
		) ,
		value = TRUE
	)
	
	
for( this_metafile in metafiles ){

	chapter_tag <- gsub( "\\.txt$" , "" , basename( this_metafile ) )
	
	link_line <-
		paste0(
			'"link": "https://github.com/ajdamico/asdfree/edit/master/' ,
			chapter_tag ,
			'.Rmd",'
		)

	html_file <- grep( paste0( '-' , chapter_tag , '.html$' ) , html_files , value = TRUE )

	html_lines <- readLines( html_file )

	html_lines <-
		gsub( 
			link_line ,
			paste0( '"link": "https://github.com/ajdamico/asdfree/edit/master/metadata/' , chapter_tag , '.txt",' ) ,
			html_lines ,
			fixed = TRUE
		)
		
	writeLines( html_lines , html_file )
	
}
# end of redirecting "edit" buttons on metadata-driven pages #


# delete the datasets folder
datasets_path <- normalizePath( file.path( path.expand( "~" ) , "Github/datasets/" ) , winslash = '/' )
file.remove( list.files( datasets_path , recursive = TRUE , full.names = TRUE , include.dirs = TRUE ) )

# create github repository for dataset
repo_files <- list.files( normalizePath( file.path( path.expand( "~" ) , "Github/asdfree/repo/" ) , winslash = '/' ) , recursive = TRUE , full.names = TRUE , all.files = TRUE )

rmd_files <- grep( "\\.Rmd$" , list.files( file.path( path.expand( "~" ) , "Github/asdfree/" ) , full.names = TRUE ) , value = TRUE )

ci_rmd_files <- sapply( rmd_files , function( w ) any( grepl( "Github Actions Badge" , readLines( w ) ) ) )
ci_rmd_files <- names( ci_rmd_files[ ci_rmd_files ] )

# stop( 'correct' )

for( this_ci_file in ci_rmd_files ){

	chapter_tag <- gsub( "\\.Rmd$" , "" , basename( this_ci_file ) )


	# test whether the repository exists
	repo_does_not_exist <-
		system( paste0( "powershell git ls-remote https://github.com/asdfree/" , chapter_tag , " HEAD" ) )
		
	# if the repository does not exist, ls-remote returns a 1.  in that case, create the repo
	if( repo_does_not_exist ){
	
		system( paste0( "powershell gh repo create asdfree/" , chapter_tag , " --public" ) )
		system( paste0( "powershell git -C 'C:/Users/AnthonyD/Documents/Github/datasets/" , chapter_tag , "' init" ) )
		
	}
	
	if( dir.exists( paste0( "C:/Users/AnthonyD/Documents/Github/datasets/" , chapter_tag ) ) ){
		system( paste0( "powershell git -C 'C:/Users/AnthonyD/Documents/Github/datasets/" , chapter_tag , "' pull" ) )
	} else {
		system( paste0( "powershell git clone https://github.com/asdfree/" , chapter_tag , "/ 'C:/Users/AnthonyD/Documents/Github/datasets/" , chapter_tag , "'" ) )
	}
	
	
	
	
	
	this_metadata_file <- gsub( paste0( "/" , chapter_tag , ".Rmd$" ) , paste0( "/metadata/" , chapter_tag , ".txt" ) , this_ci_file )

	needed_libraries <- paste( gsub( "^(dependencies: )?library\\(|\\)" , "" , unique( grep( "^(dependencies: )?library\\(" , c( if( file.exists( this_metadata_file ) ) readLines( this_metadata_file ) , readLines( this_ci_file ) ) , value = TRUE ) ) ) , collapse = ", " )
		
	this_repo_path <- normalizePath( file.path( datasets_path , chapter_tag ) , winslash = '/' , mustWork = FALSE )
	
	copied_files <- gsub( normalizePath( file.path( path.expand( "~" ) , "Github/asdfree/repo/" ) , winslash = '/' ) , this_repo_path , repo_files )
	
	this_repo_dirs <- unique( dirname( copied_files ) )
	
	lapply( this_repo_dirs , dir.create , showWarnings = FALSE , recursive = TRUE )
	
	file.copy( repo_files , copied_files , overwrite = TRUE )
	
	
	
	# do this for dataset pages
	if( file.exists( this_metadata_file ) ){
		
		# skip tests?  (currently only implemented for datasets)
		this_metadata_text <- readLines( this_metadata_file )
		skip_linux <- any( grepl( '^needs_actions_build_status_line: yes(.*)\\-linux' , this_metadata_text ) )
		skip_windows <- any( grepl( '^needs_actions_build_status_line: yes(.*)\\-windows' , this_metadata_text ) )
		skip_mac <- any( grepl( '^needs_actions_build_status_line: yes(.*)\\-mac' , this_metadata_text ) )
		r_yml <- grep( 'r\\.yml' , copied_files , value = TRUE )
		if( skip_linux ) writeLines( gsub( "          - {os: ubuntu-latest,   r: 'release'}" , "" , readLines( r_yml ) , fixed = TRUE ) , r_yml )
		if( skip_windows ) writeLines( gsub( "          - {os: windows-latest, r: 'release'}" , "" , readLines( r_yml ) , fixed = TRUE ) , r_yml )
		if( skip_mac ) writeLines( gsub( "          - {os: macOS-latest,   r: 'release'}" , "" , readLines( r_yml ) , fixed = TRUE ) , r_yml )
		
		
		for( this_file in copied_files ){
		
			these_lines <- readLines( this_file )
			
			if( grepl( 'setup\\.R$' , this_file ) ){
			
				these_lines <- 
					c( 

						these_lines , 
						
						syntaxtractor( chapter_tag )
						
					)
				
				
				
			}
			

			these_lines <- gsub( "chapter_tag" , chapter_tag , these_lines )
			these_lines <- gsub( "CHAPTER_TAG" , toupper( chapter_tag ) , these_lines )
			these_lines <- gsub( "needed_libraries" , needed_libraries , these_lines )
			
			
			writeLines( these_lines , this_file )
		
		}
	
	
	# do this for tutorial pages
	} else {

		setup_fn <- grep( "setup\\.R$" , copied_files , value = TRUE )
		
		these_lines <- 
			c(
				readLines( setup_fn ) ,
				syntaxtractor( chapter_tag )
			)
			
		writeLines( these_lines , setup_fn )

		for( this_copied_file in copied_files ){
			
			these_lines <- readLines( this_copied_file )
			
			# install.packages() lines should be skipped on continuous integration
			these_lines <- these_lines[ !grepl( "^install\\.packages" , these_lines ) ]
			these_lines <- gsub( "chapter_tag" , chapter_tag , these_lines )
			these_lines <- gsub( "CHAPTER_TAG" , toupper( chapter_tag ) , these_lines )
			these_lines <- gsub( "needed_libraries" , needed_libraries , these_lines )
			these_lines <- gsub( "desc_remotes_line" , "Remotes: ajdamico/lodown" , these_lines )

			writeLines( these_lines , this_copied_file )
		
		}
		
	}
	
	
	
		
	system( paste0( "powershell git -C 'C:/Users/AnthonyD/Documents/Github/datasets/" , chapter_tag , "' add -u" ) )
	system( paste0( "powershell git -C 'C:/Users/AnthonyD/Documents/Github/datasets/" , chapter_tag , "' add ." ) )
	system( paste0( "powershell git -C 'C:/Users/AnthonyD/Documents/Github/datasets/" , chapter_tag , "' commit -m " , commit_memo ) )
	system( paste0( "powershell git -C 'C:/Users/AnthonyD/Documents/Github/datasets/" , chapter_tag , "' push origin HEAD:master" ) )

}



# collect all build status badges:
readme_md_text <- 
	c(
		"# You can find the book at http://asdfree.com/" ,
		unlist( 
			lapply( 
				grep( "\\html$" , list.files( file.path( path.expand( "~" ) , "Github/asdfree/docs" ) , full.names = TRUE ) , value = TRUE ) , 
				function( w ){
					v <- grep( 'Github Actions Badge|Local Testing Badge' , readLines( w ) , value = TRUE )
					if( length( v ) > 0 ) paste( gsub( "\\.html" , ":" , basename( w ) ) , v ) else NULL
				}
			)
		)
	)


writeLines( readme_md_text , file.path( path.expand( "~" ) , "Github/asdfree/README.md" ) )


system( paste0( "powershell git -C 'C:/Users/AnthonyD/Documents/Github/asdfree' pull" ) )
system( paste0( "powershell git -C 'C:/Users/AnthonyD/Documents/Github/asdfree' add -u" ) )
system( paste0( "powershell git -C 'C:/Users/AnthonyD/Documents/Github/asdfree' add ." ) )
system( paste0( "powershell git -C 'C:/Users/AnthonyD/Documents/Github/asdfree' commit -m " , commit_memo ) )
system( "powershell git -C 'C:/Users/AnthonyD/Documents/Github/asdfree' push origin dev" )
