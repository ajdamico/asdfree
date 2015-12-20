# analyze survey data for free (http://asdfree.com) with the r language
# progress in international reading literacy study
# a few examples from the user guide, you know how it goes.

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/PIRLS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Progress%20in%20International%20Reading%20Literacy%20Study/replication.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###########################################################################################################################################
# prior to running this analysis script, the piaac multiply-imputed tables must be loaded as a replicate-weighted survey object on the    #
# local machine. running the download, import, and design script will create an r data file (.rda) with whatcha need.                     #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "https://raw.githubusercontent.com/ajdamico/asdfree/master/Progress%20in%20International%20Reading%20Literacy%20Study/download%20import%20and%20design.R"  ###
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create the files "asg_ash_design.rda" and "asg_design.rda" in C:/My Directory/PIRLS or wherever the working directory was set. #
###################################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PIRLS/" )



##########################################
# okay time to start replicating numbers #
##########################################

library(survey)			# load survey package (analyzes complex design surveys)
library(mitools) 		# load mitools package (analyzes multiply-imputed data)
library(downloader)		# downloads and then runs the source() function on scripts from github

# load the multiply-imputed design combination alteration function (scf.MIcombine)
# from the survey of consumer finances directory.  that function's algorithm is what pirls uses.
source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Survey%20of%20Consumer%20Finances/scf.survey.R" , prompt = FALSE )


# reproduce output from
# http://timssandpirls.bc.edu/pirls2011/downloads/P11_UserGuide.pdf

# load the ASG (student background) + ASH (home background) merged design
load( "./2011/asg_ash_design.rda" )

# note: this is not a multiply-imputed design.
# therefore, it just uses the standard survey package syntax

# # # # # # # # # # # # # # #
# pdf page 72, exhibit 3.16 #
svyby( 
	~ asbhela , 
	~ idcntry , 
	# limit the survey design to only the four countries shown in the pdf
	subset( asg_ash_design , idcntry %in% c( 36 , 40 , 31 , 957 ) ) , 
	svymean , 
	na.rm = TRUE 
)
# boom.

# clear up RAM
rm( asg_ash_design )

# load the standalone ASG (student background) multiply-imputed design
load( "./2011/asg_design.rda" )

# # # # # # # # # # # # # # #
# pdf page 21, exhibit 2.5  #
scf.MIcombine( 
	with( 
		# limit the survey design to only the four countries shown in the pdf
		subset( asg_design , idcntry %in% c( 36 , 40 , 31 , 957 ) ) , 
		svyby( 
			~ asrrea , 
			~ idcntry , 
			svymean 
		) 
	) 
)
# boom.

# # # # # # # # # # # # # # #
# pdf page 24, exhibit 2.8  #
scf.MIcombine( 
	with( 
		# limit the survey design to only the four countries shown in the pdf
		subset( asg_design , idcntry %in% c( 36 , 40 , 31 , 957 ) ) , 
		svyby( 
			~ asrrea , 
			~ idcntry + itsex , 
			svymean 
		) 
	) 
)
# boom.

# # # # # # # # # # # # # # #
# pdf page 27, exhibit 2.11 #

# run the regression on australia alone
aust <- subset( asg_design , idcntry == 36 )

# construct the `regsex` variable off of `itsex`
aust <- update( aust , regsex = as.numeric( itsex == 2 ) )

# run a simple multiply-imputed, replicate-weighted, survey-adjusted glm
scf.MIcombine( with( aust , svyglm( asrrea ~ regsex ) ) )
# boom.

# # # # # # # # # # # # # # #
# pdf page 30, exhibit 2.14 #

# construct a four-value at-or-above formula
aoa <- ~ as.numeric( asrrea >= 400 ) + as.numeric( asrrea >= 475 ) + as.numeric( asrrea >= 550 ) + as.numeric( asrrea >= 625 )

scf.MIcombine( 
	with( 	
		# limit the survey design to only the four countries shown in the pdf
		subset( asg_design , idcntry %in% c( 36 , 40 , 31 , 957 ) ) , 
		svyby( aoa , ~ idcntry , svymean ) 
	) 
)
# boom.

# # # # # # # # # #
# precisely match # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# http://timssandpirls.bc.edu/pirls2011/downloads/P11_IR_AppendixF.pdf	#

# bet you didn't know you could match all those percentiles and standard errors too.
res <- 
	scf.MIcombine( 
		with( 
			asg_design , 
			svyby( 
				~ asrrea , 
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


