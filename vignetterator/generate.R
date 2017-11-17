# Sys.getenv("RSTUDIO_PANDOC")
Sys.setenv("RSTUDIO_PANDOC"="C:/Program Files/RStudio/bin/pandoc")
commit_memo <- "'whoops'"
# source( file.path( path.expand( "~" ) , "Github/asdfree/vignetterator/generate.R" ) )

# non-survey, not database-backed (ahrf)
# database-backed non-survey (nppes)
# survey, not database-backed, not multiply imputed (yrbss)
# database-backed survey, not multiply imputed (pnad)
# multiply-imputed survey, not database-backed (scf)
# multiply-imputed, database-backed survey (pisa)


github_password <- readLines( "C:\\Users\\anthonyd\\Documents\\github password.txt" )
source( "C:\\Users\\anthonyd\\Documents\\GitHub\\asdfree\\vignetterator\\descriptive_statistics_blocks.R" )
source( "C:\\Users\\anthonyd\\Documents\\GitHub\\asdfree\\vignetterator\\measures_of_uncertainty_blocks.R" )
source( "C:\\Users\\anthonyd\\Documents\\GitHub\\asdfree\\vignetterator\\tests_of_association_blocks.R" )


needs_travis_build_status_line <- "[![Build Status](https://travis-ci.org/asdfree/chapter_tag.svg?branch=master)](https://travis-ci.org/asdfree/chapter_tag) [![Build status](https://ci.appveyor.com/api/projects/status/github/asdfree/chapter_tag?svg=TRUE)](https://ci.appveyor.com/project/ajdamico/chapter_tag)"


needs_catalog_block <- '`lodown` also provides a catalog of available microdata extracts with the `get_catalog()` function.  After requesting the CHAPTER_TAG catalog, you could pass a subsetted catalog through the `lodown()` function in order to download and import specific extracts (rather than all available extracts).\n\n```{r eval = FALSE , results = "hide" }\nlibrary(lodown)\n# examine all available CHAPTER_TAG microdata files\nchapter_tag_cat <-\n\tget_catalog( "chapter_tag" ,\n\t\toutput_dir = file.path( path.expand( "~" ) , "CHAPTER_TAG" ) get_catalog_password_parameters )\n\ncatalog_subset_description\ncatalog_subset\n# download the microdata to your local computer\nlodown( "chapter_tag" , chapter_tag_cat lodown_password_parameters )\n```'

needs_srvyr_block <- '## Analysis Examples with `srvyr` {-}\n\nThe R `srvyr` library calculates summary statistics from survey data, such as the mean, total or quantile using [dplyr](https://github.com/tidyverse/dplyr/)-like syntax. [srvyr](https://github.com/gergness/srvyr) allows for the use of many verbs, such as `summarize`, `group_by`, and `mutate`, the convenience of pipe-able functions, the `tidyverse` style of non-standard evaluation and more consistent return types than the `survey` package.  [This vignette](https://cran.r-project.org/web/packages/srvyr/vignettes/srvyr-vs-survey.html) details the available features.  As a starting point for CHAPTER_TAG users, this code replicates previously-presented examples:\n\n```{r eval = FALSE , results = "hide" }\nlibrary(srvyr)\nchapter_tag_srvyr_design <- as_survey( chapter_tag_design )\n```\nCalculate the mean (average) of a linear variable, overall and by groups:\n```{r eval = FALSE , results = "hide" }\nchapter_tag_srvyr_design %>%\n\tsummarize( mean = survey_mean( linear_variable linear_narm ) )\n\nchapter_tag_srvyr_design %>%\n\tgroup_by( group_by_variable ) %>%\n\tsummarize( mean = survey_mean( linear_variable linear_narm ) )\n```'

needs_dplyr_block <- '## Analysis Examples with `dplyr` {-}\n\nThe R `dplyr` library offers an alternative grammar of data manipulation to base R and SQL syntax.  [dplyr](https://github.com/tidyverse/dplyr/) offers many verbs, such as `summarize`, `group_by`, and `mutate`, the convenience of pipe-able functions, and the `tidyverse` style of non-standard evaluation.  [This vignette](https://cran.r-project.org/web/packages/dplyr/vignettes/dplyr.html) details the available features.  As a starting point for CHAPTER_TAG users, this code replicates previously-presented examples:\n\n```{r eval = FALSE , results = "hide" }\nlibrary(dplyr)\ntbl_initiation_line\n```\nCalculate the mean (average) of a linear variable, overall and by groups:\n```{r eval = FALSE , results = "hide" }\nchapter_tag_tbl %>%\n\tsummarize( mean = mean( linear_variable linear_narm ) )\n\nchapter_tag_tbl %>%\n\tgroup_by( group_by_variable ) %>%\n\tsummarize( mean = mean( linear_variable linear_narm ) )\n```'


readme_md_text <- "# You can find the book at http://asdfree.com/"


survey_db_closure <- '## Database Shutdown {-}\n\n```{r eval = FALSE , results = "hide" }\nclose( chapter_tag_design , shutdown = TRUE )\n```'

db_closure <- '## Database Shutdown {-}\n\n```{r eval = FALSE , results = "hide" }\ndbDisconnect( db , shutdown = TRUE )\n```'


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
sub_lines <- c( "chapter_title" , "lodown_password_parameters" , "get_catalog_password_parameters" , "authorship_line" , "table_structure" , "generalizable_population" , "publication_period" , "administrative_organization" , "catalog_subset_description" , "catalog_subset" , "sql_tablename" , "income_variable_description" , "income_variable" , "ratio_estimation_numerator" , "ratio_estimation_denominator" , "group_by_variable" , "categorical_variable" , "linear_variable" , "binary_variable" , "subset_definition_description" , "subset_definition" , "linear_narm" , "categorical_narm" , "ratio_narm" , "binary_narm" )
sub_chunks <- c( "analysis_examples_loading_block" , "analysis_examples_survey_design" , "variable_recoding_block" , "replication_example_block" , "dataset_introduction" , "convey_block" , "replacement_block" )
needs_this_block <- c( "needs_catalog_block" , "needs_srvyr_block" , "needs_dplyr_block" , "needs_travis_build_status_line" )


library(bookdown)
library(rmarkdown)
library(stringr)

metafiles <- sort( list.files( paste0( book_folder , 'metadata/' ) , full.names = TRUE ) )

full_text <- lapply( metafiles , readLines )

chapter_tag <- gsub( "\\.txt" , "" , basename( metafiles ) )

for( this_line in sub_lines ){

	assign( this_line , sapply( metafiles , function( fn ) pull_line( fn , this_line ) ) )

}

for( this_chunk in sub_chunks ){

	assign( this_chunk , sapply( metafiles , function( fn ) pull_chunk( fn , this_chunk ) ) )

}



fixed_chapters <- 6

rmds_to_clear <- paste0( str_pad( ( fixed_chapters + 1 ):99 , 2 , pad = '0' ) , "\\-" , collapse = "|" )

file.remove( grep( rmds_to_clear , list.files( book_folder , full.names = TRUE ) , value = TRUE ) )

for ( i in seq_along( chapter_tag ) ){

	this_rmd <- paste0( book_folder , str_pad( fixed_chapters + i , 2 , pad = '0' ) , "-" , chapter_tag[ i ] , ".Rmd" )

	rmd_lines <- readLines( paste0( book_folder , "skeleton/skeleton.Rmd" ) )
	
	is_survey <- any( grepl( "library(survey)" , full_text[[i]] , fixed = TRUE ) )
	is_mi <- any( grepl( "library(mitools)" , full_text[[i]] , fixed = TRUE ) )
	is_db <- any( grepl( "library(DBI)" , full_text[[i]] , fixed = TRUE ) ) 

	rmd_lines <- gsub( "kind_of_analysis_examples" , if( is_survey ) "the `survey` library" else if( is_db ) "SQL and `MonetDBLite`" else "base R" , rmd_lines )
	
	for( this_block in needs_this_block ){
		rmd_lines <- gsub( this_block , if( any( grepl( paste0( "^" , this_block , ": yes" ) , tolower( full_text[[i]] ) ) ) ) get( this_block ) else "" , rmd_lines )
	}
	
	# store the build status badges
	if( any( grepl( "^needs_travis_build_status_line: yes" , tolower( full_text[[i]] ) ) ) ) {
		readme_md_text <- c( readme_md_text , paste0( chapter_tag[ i ] , ": " , gsub( "chapter_tag" , chapter_tag[ i ] , needs_travis_build_status_line ) , '\n' ) )
	}
	
	
	if( !is_survey ) rmd_lines <- gsub( "tbl_initiation_line" , if( is_db ) "dplyr_db <- MonetDBLite::src_monetdblite( dbdir )\nchapter_tag_tbl <- tbl( dplyr_db , 'sql_tablename' )" else "chapter_tag_tbl <- tbl_df( chapter_tag_df )" , rmd_lines )
	
	
	# standalone dataset, survey design, multiply-imputed survey design, database-backed survey design, or multiply-imputed database-backed survey design
	construct_a_this_line <- 
		paste0( 
			if( is_survey ) "Construct a " else if( is_db ) "Connect to a " ,
			if( is_mi ) "multiply-imputed, " ,
			if( is_db ) "database" ,
			if( is_survey & is_db ) "-backed " ,
			if( is_survey ) "complex sample survey design" ,
			if( !is_survey & !is_db ) "Load a data frame" ,
			":"
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

	
	db_closure_block <-
		if( is_survey & is_db ) {
			survey_db_closure
		} else if( is_db ) db_closure else ""

	rmd_lines <- gsub( "^db_closure_block$" , db_closure_block , rmd_lines )


	
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
	rmd_lines <- gsub( "\tkeep.var = TRUE , na.rm = TRUE" , "\tkeep.var = TRUE ,\n\tna.rm = TRUE" , rmd_lines )
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

# writeLines( "`r if (knitr:::is_html_output()) '# References {-}'`" , paste0( book_folder , str_pad( fixed_chapters + i + 1 , 2 , pad = '0' ) , "-references.Rmd" ) )

setwd( book_folder )
clean_site()
render_site(output_format = 'bookdown::gitbook', encoding = 'UTF-8')
# render_site( encoding = 'UTF-8' )



# delete the datasets folder
datasets_path <- normalizePath( file.path( path.expand( "~" ) , "Github/datasets/" ) , winslash = '/' )
file.remove( list.files( datasets_path , recursive = TRUE , full.names = TRUE , include.dirs = TRUE ) )
travis_ymls <- grep( "\\.travis\\.yml$" , list.files( file.path( path.expand( "~" ) , "Github/datasets/" ) , recursive = TRUE , full.names = TRUE , include.dirs = TRUE , all.files = TRUE ) , value = TRUE )
file.remove( travis_ymls )

# create github repository for dataset
repo_files <- list.files( normalizePath( file.path( path.expand( "~" ) , "Github/asdfree/repo/" ) , winslash = '/' ) , recursive = TRUE , full.names = TRUE , all.files = TRUE )

rmd_files <- grep( "\\.Rmd$" , list.files( file.path( path.expand( "~" ) , "Github/asdfree/" ) , full.names = TRUE ) , value = TRUE )

ci_rmd_files <- sapply( rmd_files , function( w ) any( grepl( "travis|appveyor" , readLines( w ) ) & grepl( "Build Status" , readLines( w ) ) ) )
ci_rmd_files <- names( ci_rmd_files[ ci_rmd_files ] )


for( this_ci_file in ci_rmd_files ){

	chapter_tag <- gsub( "(.*)-(.*)\\.Rmd" , "\\2" , basename( this_ci_file ) )

	if( dir.exists( paste0( "C:/Users/AnthonyD/Documents/Github/datasets/" , chapter_tag ) ) ){
		system( paste0( "powershell git -C 'C:/Users/AnthonyD/Documents/Github/datasets/" , chapter_tag , "' pull" ) )
	} else {
		system( paste0( "powershell git clone https://github.com/asdfree/" , chapter_tag , "/ 'C:/Users/AnthonyD/Documents/Github/datasets/" , chapter_tag , "'" ) )
	}
	
	this_metadata_file <- gsub( paste0( "/([0-9]+)-" , chapter_tag , ".Rmd$" ) , paste0( "/metadata/" , chapter_tag , ".txt" ) , this_ci_file )

	needed_libraries <- paste( gsub( "^(dependencies: )?library\\(|\\)" , "" , unique( grep( "^(dependencies: )?library\\(" , c( if( file.exists( this_metadata_file ) ) readLines( this_metadata_file ) , readLines( this_ci_file ) ) , value = TRUE ) ) ) , collapse = ", " )
	
	this_repo_path <- normalizePath( file.path( datasets_path , chapter_tag ) , winslash = '/' , mustWork = FALSE )
	
	copied_files <- gsub( normalizePath( file.path( path.expand( "~" ) , "Github/asdfree/repo/" ) , winslash = '/' ) , this_repo_path , repo_files )
	
	this_repo_dirs <- unique( dirname( copied_files ) )
	
	lapply( this_repo_dirs , dir.create , showWarnings = FALSE )
	
	# do this for dataset pages
	if( file.exists( this_metadata_file ) ){
		
		file.copy( repo_files , copied_files , overwrite = TRUE )
		
		for( this_file in copied_files ){
		
			these_lines <- readLines( this_file )

			if( grepl( 'setup\\.R$|test\\.R$' , this_file ) ){

				environment_variables <- pull_chunk( this_metadata_file , "environment_variables_block" )

				these_lines <- c( these_lines , environment_variables )
				
				msrb <- pull_chunk( this_metadata_file , "machine_specific_replacements_block" )
			
				msrb <- gsub( "CHAPTER_TAG" , toupper( chapter_tag ) , msrb )
					
				if( identical( msrb , '' ) ) msrb <- c("machine_specific_replacements <- ", "\tlist( ", "\t\t", "\t\t# replace the folder path on macnix", paste0( "\t\tc( 'path.expand( \\\"~\\\" ) , \\\"" , toupper( chapter_tag ) , "\\\"' , 'getwd()' ) ," ), "\t\t", "\t\t# change other things in the script to be run", "\t\tc( \"hello\" , \"howdy\" )", "\t)")

				eval( parse( text = msrb ) )
				
				if( grepl( 'setup\\.R$' , this_file ) ) {
				
					sample_setup_block <- pull_chunk( this_metadata_file , "sample_setup_block" )
			
					if( identical( sample_setup_block , '' ) ){
				
						these_lines <- c( these_lines , readLines( lodown::syntaxtractor( chapter_tag , replacements = machine_specific_replacements , setup_test = "setup" , local_comp = TRUE ) ) )
					
					} else {

						sample_setup_block <- gsub( "CHAPTER_TAG" , toupper( chapter_tag ) , sample_setup_block )
						sample_setup_block <- gsub( "sample_setup_breaks" , pull_line( this_metadata_file , "sample_setup_breaks" ) , sample_setup_block )
						for ( this_replacement in machine_specific_replacements ) sample_setup_block <- gsub( this_replacement[ 1 ] , this_replacement[ 2 ] , sample_setup_block , fixed = TRUE )
						these_lines <- c( these_lines , sample_setup_block )
						
					}
					
				}
				
				if( grepl( 'test\\.R$' , this_file ) ) these_lines <- c( these_lines , readLines( lodown::syntaxtractor( chapter_tag , replacements = machine_specific_replacements , setup_test = "test" , local_comp = TRUE ) ) )

			}
			
			
			
			
			sample_setup_breaks <- pull_line( this_metadata_file , "sample_setup_breaks" )

			if( sample_setup_breaks != '' ){
				
				if( basename( this_file ) == 'appveyor.yml' ){
				
					these_lines <-
						gsub( 
							"# this_build_matrix" ,
							paste0( 
								"    matrix:\n" ,
								paste0( "    - this_sample_break: " , seq( as.integer( sample_setup_breaks ) ) , collapse = "\n" ) ,
								collapse = "\n"
							) , 
							these_lines 
						)
						
				}
				
				if( basename( this_file ) == '.travis.yml' ){
					
					these_lines <-
						gsub( 
							"# this_build_matrix" ,
							paste0( 
								"env:\n" ,
								paste0( " - this_sample_break=" , seq( as.integer( sample_setup_breaks ) ) , collapse = "\n" ) ,
								collapse = "\n"
							) , 
							these_lines 
						)
							
				}
			
			}
		

			these_lines <- gsub( "chapter_tag" , chapter_tag , these_lines )
			these_lines <- gsub( "CHAPTER_TAG" , toupper( chapter_tag ) , these_lines )
			these_lines <- gsub( "needed_libraries" , needed_libraries , these_lines )

			writeLines( these_lines , this_file )
		
		}
	
	
	# do this for tutorial pages
	} else {

		readme_md_text <- 
			sort( c( 
				readme_md_text , 
				paste0( chapter_tag , ": [![Build Status](https://travis-ci.org/asdfree/" , chapter_tag , ".svg?branch=master)](https://travis-ci.org/asdfree/" , chapter_tag , ") [![Build status](https://ci.appveyor.com/api/projects/status/github/asdfree/" , chapter_tag , "?svg=TRUE)](https://ci.appveyor.com/project/ajdamico/" , chapter_tag , ")\n" )
			) )
	
		if( chapter_tag == "lavaanex" ){
		
			needed_libraries <- paste( needed_libraries , "memisc" , sep = ", " )
		
			machine_specific_replacements <- 
				list( 
					
					# replace the folder path on macnix
					c( 'path.expand( \"~\" ) , \"CHAPTER_TAG\"' , 'getwd()' ) ,
					
					# change other things in the script to be run
					c( "hello" , "howdy" ) ,
					
					c( '"email@address.com"' , 'Sys.getenv( "my_email_address" )' )
					
				)
		} else {
			machine_specific_replacements <- 
				list( 
					
					# replace the folder path on macnix
					c( 'path.expand( \"~\" ) , \"CHAPTER_TAG\"' , 'getwd()' ) ,
					
					# change other things in the script to be run
					c( "hello" , "howdy" )
					
				)
		}
		
				
	
		# setup.R only, no test.
		file.copy( 
			repo_files[ !grepl( "test\\.R$" , repo_files ) ] , 
			copied_files[ !grepl( "test\\.R$" , copied_files ) ] , 
			overwrite = TRUE 
		)
		
		setup_fn <- grep( "setup\\.R$" , copied_files , value = TRUE )
		
		file.copy(
			lodown::syntaxtractor( chapter_tag , replacements = machine_specific_replacements , local_comp = TRUE ) ,
			setup_fn ,
			overwrite = TRUE
		)
	
		for( this_copied_file in copied_files[ !grepl( "test\\.R$" , copied_files ) ] ){
			
			these_lines <- readLines( this_copied_file )
			
			# install.packages() lines should be skipped on travis/appveyor
			these_lines <- these_lines[ !grepl( "^install\\.packages" , these_lines ) ]
			these_lines <- gsub( "chapter_tag" , chapter_tag , these_lines )
			these_lines <- gsub( "CHAPTER_TAG" , toupper( chapter_tag ) , these_lines )
			these_lines <- gsub( "needed_libraries" , needed_libraries , these_lines )
				
			writeLines( these_lines , this_copied_file )
		
		}
	
	}
	
	
	
	system( paste0( "powershell git -C 'C:/Users/AnthonyD/Documents/Github/datasets/" , chapter_tag , "' add -u" ) )
	system( paste0( "powershell git -C 'C:/Users/AnthonyD/Documents/Github/datasets/" , chapter_tag , "' add ." ) )
	system( paste0( "powershell git -C 'C:/Users/AnthonyD/Documents/Github/datasets/" , chapter_tag , "' commit -m " , commit_memo ) )
	# system( paste0( "powershell git -C 'C:/Users/AnthonyD/Documents/Github/datasets/" , chapter_tag , "' remote add origin https://ajdamico:" , github_password , "@github.com/asdfree/" , chapter_tag , ".git" ) )
	system( paste0( "powershell git -C 'C:/Users/AnthonyD/Documents/Github/datasets/" , chapter_tag , "' push origin master" ) )

}


writeLines( readme_md_text , file.path( path.expand( "~" ) , "Github/asdfree/README.md" ) )

system( paste0( "powershell git -C 'C:/Users/AnthonyD/Documents/Github/asdfree' add -u" ) )
system( paste0( "powershell git -C 'C:/Users/AnthonyD/Documents/Github/asdfree' add ." ) )
system( paste0( "powershell git -C 'C:/Users/AnthonyD/Documents/Github/asdfree' commit -m " , commit_memo ) )
# system( paste0( "powershell git -C 'C:/Users/AnthonyD/Documents/Github/asdfree' remote add origin https://ajdamico:" , github_password , "@github.com/ajdamico/asdfree.git" ) )
system( "powershell git -C 'C:/Users/AnthonyD/Documents/Github/asdfree' push origin master" )
