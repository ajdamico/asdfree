# analyze survey data for free (http://asdfree.com) with the r language
# trends in international mathematics and science study
# one example from the user guide, matched perfectly everywhere

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/TIMSS/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Trends%20in%20International%20Mathematics%20and%20Science%20Study/replication.R" , prompt = FALSE , echo = TRUE )# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# http://www.screenr.com/Zpd8

# anthony joseph damico
# ajdamico@gmail.com

# if you use this script for a project, please send me a note
# it's always nice to hear about how people are using this stuff

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###########################################################################################################################################
# prior to running this analysis script, the timss multiply-imputed tables must be loaded as a replicate-weighted survey object on the    #
# local machine. running the download, import, and design script will create an r data file (.rda) with whatcha need.                     #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.github.com/ajdamico/usgsd/master/Trends%20in%20International%20Mathematics%20and%20Science%20Study/download%20import%20and%20design.R #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create the files "asg_design.rda" in C:/My Directory/TIMSS or wherever the working directory was set.                          # #
#####################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/TIMSS/" )



##########################################
# okay time to start replicating numbers #
##########################################

library(survey)			# load survey package (analyzes complex design surveys)
library(mitools) 		# load mitools package (analyzes multiply-imputed data)
library(downloader)		# downloads and then runs the source() function on scripts from github
library(RSQLite) 		# load RSQLite package (creates database files in R)

# load the multiply-imputed design combination alteration function (scf.MIcombine)
# from the survey of consumer finances directory.  that function's algorithm is what pirls uses.
source_url( "https://raw.github.com/ajdamico/usgsd/master/Survey%20of%20Consumer%20Finances/scf.survey.R" , prompt = FALSE )

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



# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/

# dear everyone: please contribute your script.
# have you written syntax that precisely matches an official publication?
message( "if others might benefit, send your code to ajdamico@gmail.com" )
# http://asdfree.com needs more user contributions

# let's play the which one of these things doesn't belong game:
# "only you can prevent forest fires" -smokey bear
# "take a bite out of crime" -mcgruff the crime pooch
# "plz gimme your statistical programming" -anthony damico
