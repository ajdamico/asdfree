
mi_measures_of_uncertainty_block <-
'Extract the coefficient, standard error, confidence interval, and coefficient of variation from any descriptive statistics function result, overall and by groups:
```{r eval = FALSE , results = "hide" }
this_result <-\n\tMIcombine( with( chapter_tag_design ,\n\t\tsvymean( ~ linear_variable linear_narm )\n\t) )

coef( this_result )
SE( this_result )
confint( this_result )
cv( this_result )


grouped_result <-\n\tMIcombine( with( chapter_tag_design ,\n\t\tsvyby( ~ linear_variable , ~ group_by_variable , svymean linear_narm )\n\t) )

coef( grouped_result )
SE( grouped_result )
confint( grouped_result )
cv( grouped_result )
```

Calculate the degrees of freedom of any survey design object:
```{r eval = FALSE , results = "hide" }
degf( chapter_tag_design$designs[[1]] )
```

Calculate the complex sample survey-adjusted variance of any statistic:
```{r eval = FALSE , results = "hide" }
MIcombine( with( chapter_tag_design , svyvar( ~ linear_variable linear_narm ) ) )
```

Include the complex sample design effect in the result for a specific statistic:
```{r eval = FALSE , results = "hide" }
# SRS without replacement
MIcombine( with( chapter_tag_design ,\n\tsvymean( ~ linear_variable linear_narm , deff = TRUE )\n) )

# SRS with replacement
MIcombine( with( chapter_tag_design ,\n\tsvymean( ~ linear_variable linear_narm , deff = "replace" )\n) )
```

Compute confidence intervals for proportions using methods that may be more accurate near 0 and 1.  See `?svyciprop` for alternatives:
```{r eval = FALSE , results = "hide" }
lodown:::MIsvyciprop( ~ binary_variable , chapter_tag_design ,
	method = "likelihood" binary_narm )
```'


survey_measures_of_uncertainty_block <-
'Extract the coefficient, standard error, confidence interval, and coefficient of variation from any descriptive statistics function result, overall and by groups:
```{r eval = FALSE , results = "hide" }
this_result <- svymean( ~ linear_variable , chapter_tag_design linear_narm )

coef( this_result )
SE( this_result )
confint( this_result )
cv( this_result )


grouped_result <-
	svyby( 
		~ linear_variable , 
		~ group_by_variable , 
		chapter_tag_design , 
		svymean linear_narm 
	)
	
coef( grouped_result )
SE( grouped_result )
confint( grouped_result )
cv( grouped_result )
```

Calculate the degrees of freedom of any survey design object:
```{r eval = FALSE , results = "hide" }
degf( chapter_tag_design )
```

Calculate the complex sample survey-adjusted variance of any statistic:
```{r eval = FALSE , results = "hide" }
svyvar( ~ linear_variable , chapter_tag_design linear_narm )
```

Include the complex sample design effect in the result for a specific statistic:
```{r eval = FALSE , results = "hide" }
# SRS without replacement
svymean( ~ linear_variable , chapter_tag_design linear_narm , deff = TRUE )

# SRS with replacement
svymean( ~ linear_variable , chapter_tag_design linear_narm , deff = "replace" )
```

Compute confidence intervals for proportions using methods that may be more accurate near 0 and 1.  See `?svyciprop` for alternatives:
```{r eval = FALSE , results = "hide" }
svyciprop( ~ binary_variable , chapter_tag_design ,
	method = "likelihood" binary_narm )
```'

db_measures_of_uncertainty_block <-
'Calculate the variance and standard deviation, overall and by groups:
```{r eval = FALSE , results = "hide" }
dbGetQuery( db , 
	"SELECT 
		VAR_SAMP( linear_variable ) , 
		STDDEV_SAMP( linear_variable ) 
	FROM sql_tablename" 
)

dbGetQuery( db , 
	"SELECT 
		group_by_variable , 
		VAR_SAMP( linear_variable ) AS var_linear_variable ,
		STDDEV_SAMP( linear_variable ) AS stddev_linear_variable
	FROM sql_tablename 
	GROUP BY group_by_variable" 
)
```'


base_measures_of_uncertainty_block <-
'Calculate the variance, overall and by groups:
```{r eval = FALSE , results = "hide" }
var( chapter_tag_df[ , "linear_variable" ] linear_narm )

tapply(\n\tchapter_tag_df[ , "linear_variable" ] ,\n\tchapter_tag_df[ , "group_by_variable" ] ,\n\tvar linear_narm \n)
```'
