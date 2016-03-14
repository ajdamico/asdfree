
# devtools:::install_github('djalmapessoa/convey')
library(convey)

library(mitools)	# allows analysis of multiply-imputed survey data
library(survey)		# load survey package (analyzes complex design surveys)
library(downloader)	# downloads and then runs the source() function on scripts from github
library(foreign) 	# load foreign package (converts data files into R)


setwd( "C:/My Directory/SCF/" )


# load the SCF
years.to.download <- c( 2004 , 2007 , 2010 )
source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Survey%20of%20Consumer%20Finances/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )


source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Survey%20of%20Consumer%20Finances/scf.survey.R" , prompt = FALSE )


# create the multiply-imputed survey design
for( year in years.to.download ){

	load( paste0( "scf" , year , ".rda" ) )

	vars.to.keep <- c( 'y1' , 'yy1' , 'wgt' , 'one' , 'five' , 'networth' , 'income' , 'asset' , 'agecl' )

	imp1 <- imp1[ , vars.to.keep ]
	imp2 <- imp2[ , vars.to.keep ]
	imp3 <- imp3[ , vars.to.keep ]
	imp4 <- imp4[ , vars.to.keep ]
	imp5 <- imp5[ , vars.to.keep ]



	# construct an imputed replicate-weighted survey design object
	# build a new replicate-weighted survey design object,
	# but unlike most replicate-weighted designs, this object includes the
	# five multiply-imputed data tables - imp1 through imp5
	scf.design <- 
		svrepdesign( 
			
			# use the main weight within each of the imp# objects
			weights = ~wgt , 
			
			# use the 999 replicate weights stored in the separate replicate weights file
			repweights = rw[ , -1 ] , 
			
			# read the data directly from the five implicates
			data = imputationList( list( imp1 , imp2 , imp3 , imp4 , imp5 ) ) , 

			scale = 1 ,

			rscales = rep( 1 / 998 , 999 ) ,

			# use the mean of the replicate statistics as the center
			# when calculating the variance, as opposed to the main weight's statistic
			mse = TRUE ,
			
			type = "other" ,

			combined.weights = TRUE
		)

	# this is the methodologically-correct way to analyze the survey of consumer finances
	# main disadvantage: requires code that's less intuitive for analysts familiar with 
	# the r survey package's svymean( ~formula , design ) layout



	# # # # # # # # # # # # # # #
	# convey_prep application on a multiply-imputed survey design object!
	scf.design$designs <- lapply( scf.design$designs , convey_prep )
	# # # # # # # # # # # # # # #

	# simple example of net worth using `svygini`
	print( scf.MIcombine( with( scf.design , svygini( ~networth ) ) ) )

	# http://www.ncbi.nlm.nih.gov/pmc/articles/PMC4200506/table/T5/
}

