


mi_tests_of_association_block <-
'Perform a design-based t-test:
```{r eval = FALSE , results = "hide" }
lodown:::MIsvyttest( linear_variable ~ binary_variable , chapter_tag_design )
```

Perform a chi-squared test of association for survey data:
```{r eval = FALSE , results = "hide" }
lodown:::MIsvychisq( ~ binary_variable + categorical_variable , chapter_tag_design )
```

Perform a survey-weighted generalized linear model:
```{r eval = FALSE , results = "hide" }
glm_result <- 
	MIcombine( with( chapter_tag_design ,
		svyglm( linear_variable ~ binary_variable + categorical_variable )
	) )
	
summary( glm_result )
```'


survey_tests_of_association_block <-
'Perform a design-based t-test:
```{r eval = FALSE , results = "hide" }
svyttest( linear_variable ~ binary_variable , chapter_tag_design )
```

Perform a chi-squared test of association for survey data:
```{r eval = FALSE , results = "hide" }
svychisq( 
	~ binary_variable + categorical_variable , 
	chapter_tag_design 
)
```

Perform a survey-weighted generalized linear model:
```{r eval = FALSE , results = "hide" }
glm_result <- 
	svyglm( 
		linear_variable ~ binary_variable + categorical_variable , 
		chapter_tag_design 
	)

summary( glm_result )
```'

db_tests_of_association_block <-
'Calculate the correlation between two variables, overall and by groups:
```{r eval = FALSE , results = "hide" }
dbGetQuery( db , 
	"SELECT 
		CORR( CAST( binary_variable AS DOUBLE ) , CAST( linear_variable AS DOUBLE ) )
	FROM sql_tablename" 
)

dbGetQuery( db , 
	"SELECT 
		group_by_variable , 
		CORR( CAST( binary_variable AS DOUBLE ) , CAST( linear_variable AS DOUBLE ) )
	FROM sql_tablename 
	GROUP BY group_by_variable" 
)
```'


base_tests_of_association_block <-
'Perform a t-test:
```{r eval = FALSE , results = "hide" }
t.test( linear_variable ~ binary_variable , chapter_tag_df )
```

Perform a chi-squared test of association:
```{r eval = FALSE , results = "hide" }
this_table <- table( chapter_tag_df[ , c( "binary_variable" , "categorical_variable" ) ] )

chisq.test( this_table )
```

Perform a generalized linear model:
```{r eval = FALSE , results = "hide" }
glm_result <- 
	glm( 
		linear_variable ~ binary_variable + categorical_variable , 
		data = chapter_tag_df
	)

summary( glm_result )
```'
