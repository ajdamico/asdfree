# analyze survey data for free (http://asdfree.com) with the r language
# trends in international mathematics and science study
# one example from the user guide, matched perfectly everywhere

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/TIMSS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Trends%20in%20International%20Mathematics%20and%20Science%20Study/replication.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#########################################################################################################################################################
# prior to running this analysis script, the piaac multiply-imputed tables must be loaded as a replicate-weighted survey object on the                  #
# local machine. running the download, import, and design scripts will create an r data file (.rda) with whatcha need.                                  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/Trends%20in%20International%20Mathematics%20and%20Science%20Study/download%20and%20import.R #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/Trends%20in%20International%20Mathematics%20and%20Science%20Study/construct%20designs.R     #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create the files "asg_design.rda" in C:/My Directory/TIMSS or wherever the working directory was set.                                #
#########################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/TIMSS/" )



##########################################
# okay time to start replicating numbers #
##########################################


library(survey)			# load survey package (analyzes complex design surveys)
library(mitools) 		# load mitools package (analyzes multiply-imputed data)
library(downloader)		# downloads and then runs the source() function on scripts from github
library(survey) 		# load survey package (analyzes complex design surveys)
library(MonetDBLite)
library(DBI)			# load the DBI package (implements the R-database coding)


# load the multiply-imputed design combination alteration function (scf.MIcombine)
# from the survey of consumer finances directory.  that function's algorithm is what pirls uses.
source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Survey%20of%20Consumer%20Finances/scf.survey.R" , prompt = FALSE )

# load the survey design object
load( "./2011/asg_design.rda" )

# establish a connection to the SQLite database
asg_design$designs <- lapply( asg_design$designs , open )


# # # # # # # # # #
# precisely match # # # # # # # # # # # # # # # # # # # # # # # # #
# timssandpirls.bc.edu/timss2011/downloads/T11_IR_M_AppendixG.pdf #

# bet you didn't know you could match all those percentiles and standard errors.
res <- 
	scf.MIcombine( 
		with( 
			asg_design , 
			svyby( 
				~ asmmat , 
				~ idcntry , 
				svyquantile , 
				c( 0.05 , 0.1 , 0.25 , 0.5 , 0.75 , 0.9 , 0.95 ) , 
				method = 'constant' , 
				interval.type = 'quantile' 
			) 
		) 
	)

# copy the result over as a data.frame object
out <- data.frame( results = coef( res ) , se = sqrt( diag( vcov( res ) ) ) )

# copy over the countries and quantiles to actual column names
out$idcntry <- gsub( ":(.*)" , "" , rownames( out ) )
out$qtile <- gsub( "(.*):" , "" , rownames( out ) )

# make the table more liveable.
out <- reshape( out , idvar = 'idcntry' , timevar = 'qtile' , direction = 'wide' )

out
# boom.


######################
# end of replication #
######################
