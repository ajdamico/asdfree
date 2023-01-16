commit_memo <- "'trendy a less huge mess'"

# source( file.path( path.expand( "~" ) , "Github/asdfree/vignetterator/generate.R" ) )



# non-survey, not database-backed (ahrf)
# database-backed non-survey (nppes)
# survey, not database-backed, not multiply imputed (yrbss)
# database-backed survey, not multiply imputed (pnad)
# multiply-imputed survey, not database-backed (scf)
# multiply-imputed, database-backed survey (pisa)


github_password <- readLines( file.path( path.expand( "~" ) , "github password.txt" ) )
github_token <- readLines( file.path( path.expand( "~" ) , "github token.txt" ) )
source( file.path( path.expand( "~" ) , "Github\\asdfree\\vignetterator\\descriptive_statistics_blocks.R" ) )
source( file.path( path.expand( "~" ) , "Github\\asdfree\\vignetterator\\measures_of_uncertainty_blocks.R" ) )
source( file.path( path.expand( "~" ) , "Github\\asdfree\\vignetterator\\tests_of_association_blocks.R" ) )
source( file.path( path.expand( "~" ) , "Github\\asdfree\\vignetterator\\syntaxtractor.R" ) )


needs_actions_build_status_line <- '<a href="https://github.com/asdfree/chapter_tag/actions"><img src="https://github.com/asdfree/chapter_tag/actions/workflows/r.yml/badge.svg" alt="Github Actions Badge"></a>'

needs_dplyr_block <- '---\n\n## Analysis Examples with `dplyr` \\\\ {-}\n\nThe R `dplyr` library offers an alternative grammar of data manipulation to base R and SQL syntax.  [dplyr](https://github.com/tidyverse/dplyr/) offers many verbs, such as `summarize`, `group_by`, and `mutate`, the convenience of pipe-able functions, and the `tidyverse` style of non-standard evaluation.  [This vignette](https://cran.r-project.org/web/packages/dplyr/vignettes/dplyr.html) details the available features.  As a starting point for CHAPTER_TAG users, this code replicates previously-presented examples:\n\n```{r eval = FALSE , results = "hide" }\nlibrary(dplyr)\ntbl_initiation_line\n```\nCalculate the mean (average) of a linear variable, overall and by groups:\n```{r eval = FALSE , results = "hide" }\nchapter_tag_tbl %>%\n\tsummarize( mean = mean( linear_variable linear_narm ) )\n\nchapter_tag_tbl %>%\n\tgroup_by( group_by_variable ) %>%\n\tsummarize( mean = mean( linear_variable linear_narm ) )\n```'


readme_md_text <- "# You can find the book at http://asdfree.com/"


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
sub_chunks <- c( "reading_block" , "download_and_import_block" , "analysis_examples_loading_block" , "analysis_examples_survey_design" , "variable_recoding_block" , "replication_example_block" , "dataset_introduction" , "intermission_block" , "convey_block" , "replacement_block" )
needs_this_block <- c( "needs_srvyr_block" , "needs_dplyr_block" , "needs_actions_build_status_line" )


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



# delete all rmd files except for the index
rmd_files <- grep( "\\.Rmd$" , list.files( book_folder , full.names = TRUE ) , value = TRUE )
file.remove( rmd_files[ basename( rmd_files ) != 'index.Rmd' ] )

# move all rmd files in /posts/ to the main folder
rmd_posts <- list.files( paste0( book_folder , "posts/" ) , full.names = TRUE )
file.copy( rmd_posts , gsub( "posts\\/" , "" , rmd_posts ) )


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
	
	# store the build status badges
	if( any( grepl( "^needs_actions_build_status_line: yes" , tolower( full_text[[i]] ) ) ) ) {
		readme_md_text <- c( readme_md_text , paste0( chapter_tag[ i ] , ": " , gsub( "chapter_tag" , chapter_tag[ i ] , needs_actions_build_status_line ) , '\n' ) )
	}
	
	
	if( !is_survey ) rmd_lines <- gsub( "tbl_initiation_line" , if( is_db ) "library(dbplyr)\ndplyr_db <- dplyr::src_sqlite( dbdir )\nchapter_tag_tbl <- tbl( dplyr_db , 'sql_tablename' )" else "chapter_tag_tbl <- tbl_df( chapter_tag_df )" , rmd_lines )
	
	
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

# writeLines( "`r if (knitr:::is_html_output()) '# References {-}'`" , paste0( book_folder , "references.Rmd" ) )

setwd( book_folder )
clean_site()
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

# in case asdfree repo needs to be deleted and restored:
# system( paste0( "powershell git clone https://ajdamico:" , github_password , "@github.com/ajdamico/asdfree/ 'C:/Users/AnthonyD/Documents/Github/asdfree/'" ) )

for( this_ci_file in ci_rmd_files ){

	chapter_tag <- gsub( "\\.Rmd$" , "" , basename( this_ci_file ) )

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
		
		for( this_file in copied_files ){
		
			these_lines <- readLines( this_file )

			if( basename( this_file ) == 'DESCRIPTION' ) {
				
				if( grepl( 'archive' , needed_libraries ) ) {
				
					these_lines <- gsub( "desc_remotes_line" , "Remotes: jimhester/archive" , these_lines )
					
				} else these_lines <- gsub( "desc_remotes_line" , "" , these_lines )
				
			}
			
			if( grepl( 'setup\\.R$' , this_file ) ){

				environment_variables <- pull_chunk( this_metadata_file , "environment_variables_block" )

				these_lines <- c( these_lines , environment_variables )
				
				msrb <- pull_chunk( this_metadata_file , "machine_specific_replacements_block" )
			
				msrb <- gsub( "CHAPTER_TAG" , toupper( chapter_tag ) , msrb )
					
				if( identical( msrb , '' ) ) msrb <- c("machine_specific_replacements <- ", "\tlist( ", "\t\t", "\t\t# replace the folder path on macnix", paste0( "\t\tc( 'path.expand( \\\"~\\\" ) , \\\"" , toupper( chapter_tag ) , "\\\"' , 'getwd()' ) ," ), "\t\t", "\t\t# change other things in the script to be run", "\t\tc( \"hello\" , \"howdy\" )", "\t)")

				eval( parse( text = msrb ) )
			
				these_lines <- 
					c( 

						these_lines , 
						
						syntaxtractor( 
							chapter_tag , 
							replacements = machine_specific_replacements
						)
						
					)
				
				
				
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
				paste0( chapter_tag , ": " , ' <a href="https://github.com/asdfree/' , chapter_tag , '/actions"><img src="https://github.com/asdfree/' , chapter_tag , '/actions/workflows/r.yml/badge.svg" alt="Github Actions Badge"></a>\n' )
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
		

		setup_fn <- grep( "setup\\.R$" , copied_files , value = TRUE )
		
		these_lines <- 
			c(
				readLines( setup_fn ) ,
				syntaxtractor( chapter_tag , replacements = machine_specific_replacements )
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
	
	
	
	# test whether the repository exists
	repo_does_not_exist <-
		system( paste0( "powershell git ls-remote https://github.com/asdfree/" , chapter_tag , " HEAD" ) )
		
	# if the repository does not exist, ls-remote returns a 1.  in that case, create the repo
	if( repo_does_not_exist ){
	
		system( paste0( "powershell gh repo create asdfree/" , chapter_tag , " --public" ) )
	
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
system( "powershell git -C 'C:/Users/AnthonyD/Documents/Github/asdfree' push origin dev" )
