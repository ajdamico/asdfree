
mi_descriptive_block <-
'Calculate the mean (average) of a linear variable, overall and by groups:
```{r eval = FALSE , results = "hide" }
MIcombine( with( chapter_tag_design , svymean( ~ linear_variable linear_narm ) ) )

MIcombine( with( chapter_tag_design ,\n\tsvyby( ~ linear_variable , ~ group_by_variable , svymean linear_narm )\n) )
```

Calculate the distribution of a categorical variable, overall and by groups:
```{r eval = FALSE , results = "hide" }
MIcombine( with( chapter_tag_design , svymean( ~ categorical_variable categorical_narm ) ) )

MIcombine( with( chapter_tag_design ,\n\tsvyby( ~ categorical_variable , ~ group_by_variable , svymean categorical_narm )\n) )
```

Calculate the sum of a linear variable, overall and by groups:
```{r eval = FALSE , results = "hide" }
MIcombine( with( chapter_tag_design , svytotal( ~ linear_variable linear_narm ) ) )

MIcombine( with( chapter_tag_design ,\n\tsvyby( ~ linear_variable , ~ group_by_variable , svytotal linear_narm )\n) )
```

Calculate the weighted sum of a categorical variable, overall and by groups:
```{r eval = FALSE , results = "hide" }
MIcombine( with( chapter_tag_design , svytotal( ~ categorical_variable categorical_narm ) ) )

MIcombine( with( chapter_tag_design ,\n\tsvyby( ~ categorical_variable , ~ group_by_variable , svytotal categorical_narm )\n) )
```

Calculate the median (50th percentile) of a linear variable, overall and by groups:
```{r eval = FALSE , results = "hide" }
MIcombine( with( chapter_tag_design , svyquantile( ~ linear_variable , 0.5  , se = TRUE linear_narm ) ) )

MIcombine( with( chapter_tag_design ,\n\tsvyby( \n\t\t~ linear_variable , ~ group_by_variable , svyquantile , 0.5  ,\n\t\tse = TRUE , keep.var = TRUE , ci = TRUE linear_narm\n) ) )
```

Estimate a ratio:
```{r eval = FALSE , results = "hide" }
MIcombine( with( chapter_tag_design ,
	svyratio( numerator = ~ ratio_estimation_numerator , denominator = ~ ratio_estimation_denominator ratio_narm )
) )
```'

survey_descriptive_block <-
'Calculate the mean (average) of a linear variable, overall and by groups:
```{r eval = FALSE , results = "hide" }
svymean( ~ linear_variable , chapter_tag_design linear_narm )

svyby( ~ linear_variable , ~ group_by_variable , chapter_tag_design , svymean linear_narm )
```

Calculate the distribution of a categorical variable, overall and by groups:
```{r eval = FALSE , results = "hide" }
svymean( ~ categorical_variable , chapter_tag_design categorical_narm )

svyby( ~ categorical_variable , ~ group_by_variable , chapter_tag_design , svymean categorical_narm )
```

Calculate the sum of a linear variable, overall and by groups:
```{r eval = FALSE , results = "hide" }
svytotal( ~ linear_variable , chapter_tag_design linear_narm )

svyby( ~ linear_variable , ~ group_by_variable , chapter_tag_design , svytotal linear_narm )
```

Calculate the weighted sum of a categorical variable, overall and by groups:
```{r eval = FALSE , results = "hide" }
svytotal( ~ categorical_variable , chapter_tag_design categorical_narm )

svyby( ~ categorical_variable , ~ group_by_variable , chapter_tag_design , svytotal categorical_narm )
```

Calculate the median (50th percentile) of a linear variable, overall and by groups:
```{r eval = FALSE , results = "hide" }
svyquantile( ~ linear_variable , chapter_tag_design , 0.5 linear_narm )

svyby( 
	~ linear_variable , 
	~ group_by_variable , 
	chapter_tag_design , 
	svyquantile , 
	0.5 ,
	ci = TRUE ,
	keep.var = TRUE linear_narm
)
```

Estimate a ratio:
```{r eval = FALSE , results = "hide" }
svyratio( 
	numerator = ~ ratio_estimation_numerator , 
	denominator = ~ ratio_estimation_denominator , 
	chapter_tag_design ratio_narm
)
```'

db_descriptive_block <-
'Calculate the mean (average) of a linear variable, overall and by groups:
```{r eval = FALSE , results = "hide" }
dbGetQuery( db , "SELECT AVG( linear_variable ) FROM sql_tablename" )

dbGetQuery( db , 
	"SELECT 
		group_by_variable , 
		AVG( linear_variable ) AS mean_linear_variable
	FROM sql_tablename 
	GROUP BY group_by_variable" 
)
```

Initiate a function that allows division by zero:
```{r eval = FALSE , results = "hide" }
dbSendQuery( db , 
	"CREATE FUNCTION 
		div_noerror(l DOUBLE, r DOUBLE) 
	RETURNS DOUBLE 
	EXTERNAL NAME calc.div_noerror" 
)
```

Calculate the distribution of a categorical variable:
```{r eval = FALSE , results = "hide" }
dbGetQuery( db , 
	"SELECT 
		categorical_variable , 
		div_noerror( 
			COUNT(*) , 
			( SELECT COUNT(*) FROM sql_tablename ) 
		) AS share_categorical_variable
	FROM sql_tablename 
	GROUP BY categorical_variable" 
)
```

Calculate the sum of a linear variable, overall and by groups:
```{r eval = FALSE , results = "hide" }
dbGetQuery( db , "SELECT SUM( linear_variable ) FROM sql_tablename" )

dbGetQuery( db , 
	"SELECT 
		group_by_variable , 
		SUM( linear_variable ) AS sum_linear_variable 
	FROM sql_tablename 
	GROUP BY group_by_variable" 
)
```

Calculate the median (50th percentile) of a linear variable, overall and by groups:
```{r eval = FALSE , results = "hide" }
dbGetQuery( db , "SELECT QUANTILE( linear_variable , 0.5 ) FROM sql_tablename" )

dbGetQuery( db , 
	"SELECT 
		group_by_variable , 
		QUANTILE( linear_variable , 0.5 ) AS median_linear_variable
	FROM sql_tablename 
	GROUP BY group_by_variable" 
)
```'


base_descriptive_block <-
'Calculate the mean (average) of a linear variable, overall and by groups:
```{r eval = FALSE , results = "hide" }
mean( chapter_tag_df[ , "linear_variable" ] linear_narm )

tapply(\n\tchapter_tag_df[ , "linear_variable" ] ,\n\tchapter_tag_df[ , "group_by_variable" ] ,\n\tmean linear_narm \n)
```

Calculate the distribution of a categorical variable, overall and by groups:
```{r eval = FALSE , results = "hide" }
prop.table( table( chapter_tag_df[ , "categorical_variable" ] ) )

prop.table(\n\ttable( chapter_tag_df[ , c( "categorical_variable" , "group_by_variable" ) ] ) ,\n\tmargin = 2\n)
```

Calculate the sum of a linear variable, overall and by groups:
```{r eval = FALSE , results = "hide" }
sum( chapter_tag_df[ , "linear_variable" ] linear_narm )

tapply(\n\tchapter_tag_df[ , "linear_variable" ] ,\n\tchapter_tag_df[ , "group_by_variable" ] ,\n\tsum linear_narm \n)
```

Calculate the median (50th percentile) of a linear variable, overall and by groups:
```{r eval = FALSE , results = "hide" }
quantile( chapter_tag_df[ , "linear_variable" ] , 0.5 linear_narm )

tapply(\n\tchapter_tag_df[ , "linear_variable" ] ,\n\tchapter_tag_df[ , "group_by_variable" ] ,\n\tquantile ,\n\t0.5 linear_narm \n)
```'
