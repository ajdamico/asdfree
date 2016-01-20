# analyze survey data for free (http://asdfree.com) with the r language
# pesquisa nacional de saude

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/PNS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Pesquisa%20Nacional%20De%20Saude/replicate%20tabelas.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# djalma pessoa
# pessoad@gmail.com

# anthony joseph damico
# ajdamico@gmail.com


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#########################################################################################################################
# prior to running this analysis script, the pns 2013 file must be loaded on the local machine with this script:        #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/Pesquisa%20Nacional%20De%20Saude/download%20and%20import.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "2013 long questionnaire survey design.rda" in the working directory                   #
#########################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PNS/" )
# ..in order to set your current working directory


library(survey) 	# load survey package (analyzes complex design surveys)
library(ggplot2)	# load ggplot2 package (plots data according to the grammar of graphics)



load( "2013 long questionnaire survey design.rda" )

load( "2013 all questionnaire survey design.rda" )


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# compute estimates of table tabela 5.1.1.1 in ftp://ftp.ibge.gov.br/PNS/2013/pns2013.pdf #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

three_stats <- function( z ) print( round( 100 * c( coef( z ) , coef( z ) - 2 * SE( z ) , coef( z ) + 2 * SE( z ) ) , 1 ) )


# nationwide
saudbr <- svymean( ~ saude_b_mb , design = pes_sel_des_pos )

three_stats( saudbr )


# by sex
saudbrsex <- svyby( ~ saude_b_mb , ~ c006 , design = pes_sel_des_pos , svymean )

three_stats( saudbrsex )


# by situation (rural and urban)
saudsitu <- svyby( ~saude_b_mb , ~situ , design = pes_sel_des_pos , svymean )

three_stats( saudsitu )


# situation x sex
saudsitusex <- svyby( ~ saude_b_mb , ~ situ + c006 , design = pes_sel_des_pos , svymean )

three_stats( saudsitusex )


# by UF
sauduf <- svyby( ~ saude_b_mb , ~ uf , design = pes_sel_des_pos , svymean )

three_stats( sauduf )


# UF x sex 
saudufsex <- svyby( ~ saude_b_mb , ~ uf + c006 , design = pes_sel_des_pos , svymean )

three_stats( saudufsex )


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# compute estimates of table tabela 3.4.1.1 in ftp://ftp.ibge.gov.br/PNS/2013/pns2013.pdf #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# % with at least 30 minutes of physical activity
  
# nationwide
atfibr <- svymean( ~ atfi04 , design = pes_sel_des_pos )

three_stats( atfibr )


# by sex
atfibrsex <- svyby( ~ atfi04 , ~ c006 , design = pes_sel_des_pos , svymean )

three_stats( atfibrsex )


# by situation (rural and urban)
atfisitu <- svyby( ~atfi04 , ~situ , design = pes_sel_des_pos , svymean )

three_stats( atfisitu )


# situation x sex
atfisitusex <- svyby( ~ atfi04 , ~ situ + c006 , design = pes_sel_des_pos , svymean )

three_stats( atfisitusex )


# by UF
atfiuf <- svyby( ~ atfi04 , ~ uf , design = pes_sel_des_pos , svymean )

three_stats( atfiuf )


# UF x sex 
atfiufsex <- svyby( ~ atfi04 , ~ uf + c006 , design = pes_sel_des_pos , svymean )

three_stats( atfiufsex )


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# replicate grafico 8 on                                                  #
# http://biblioteca.ibge.gov.br/visualizacao/livros/liv94074.pdf#page=30  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# people with health insurance (overall)
overall <- data.frame( svyby( ~ as.numeric( i001 == 1 ) , ~ one , design = pes_all_des_pos , vartype = "ci" ,  level = 0.95 ,  svymean , na.rm = TRUE ) )
overall[ 1 , 1 ] <- "overall"

# by sex
bysex <- data.frame( svyby( ~ as.numeric( i001 == 1 ) , ~ c006 , design = pes_all_des_pos , vartype = "ci" ,  level = 0.95 ,  svymean , na.rm = TRUE ) )

# by age
byage <- data.frame( svyby( ~ as.numeric( i001 == 1 ) , ~ age_cat , design = pes_all_des_pos , vartype = "ci" ,  level = 0.95 ,  svymean , na.rm = TRUE ) )

# by race
byrace <- data.frame( svyby( ~ as.numeric( i001 == 1 ) , ~ raca , design = pes_all_des_pos , vartype = "ci" ,  level = 0.95 ,  svymean , na.rm = TRUE ) )

# by education
byeduc <- data.frame( svyby( ~ as.numeric( i001 == 1 ) , ~ educ , design = pes_all_des_pos , vartype = "ci" ,  level = 0.95 ,  svymean , na.rm = TRUE ) )

# re-categorize all four columns
names( overall ) <- names( bysex ) <- names( byage ) <- names( byrace ) <- names( byeduc ) <- c( "breakout_variable" , "coefficient" , "lower_bound" , "upper_bound" )

# combine all results into a single table
graphic_data <- rbind( overall , bysex , byage , byrace , byeduc )
graphic_data$yplot <- seq( nrow( graphic_data ) )

# plot these results
ggplot(
	graphic_data ,
	aes( x = yplot , y = coefficient )
	) +
	geom_bar( stat = "identity" ) +
	geom_errorbar( aes( ymin = lower_bound , ymax = upper_bound ) ) +
	xlab( "grafico 8" ) +
	ylab( "% with health insurance" )
		

# happy?
