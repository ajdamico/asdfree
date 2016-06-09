# analyze survey data for free (http://asdfree.com) with the r language
# censo demografico
# 2010 gerais da amostra (general sample)
# person-level file

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/CENSO/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Censo%20Demografico/variable%20recode%20example.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# djalma pessoa
# pessoad@gmail.com

# anthony joseph damico
# ajdamico@gmail.com


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###########################################################################################################
# prior to running this analysis script, the 2010 censo demografico must be loaded as a monet             #
# database-backed sqlsurvey object on the local machine. running this script will do it.                  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/Censo%20Demografico/download%20and%20import.R #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "pes 2010 design.rda" in C:/My Directory/CENSO or wherever.              #
###########################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/CENSO/" )


library(survey) 		# load survey package (analyzes complex design surveys)
library(DBI)			# load the DBI package (implements the R-database coding)


# the censo demografico download and importation script
# has already created a monet database-backed survey design object
# connected to the 2010 household-level table

# sqlite database-backed survey objects are described here: 
# http://r-survey.r-forge.r-project.org/survey/svy-dbi.html
# monet database-backed survey objects are similar, but:
# the database engine is, well, blazingly faster
# the setup is kinda more complicated (but all done for you)



# after running the r script above, users should have handy a few lines
# to initiate and connect to the monet database.  run them now.  mine look like this:

# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )

# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite::MonetDBLite() , dbfolder )


# uncomment this line by removing the `#` at the front..
load( "pes 2010 design.rda" )


# connect the recoded complex sample design to the monet database #
pes.d <- open( pes.design , driver = MonetDB.R() )	# recoded


################################################################
# step 1: connect to the CENSO data table you'd like to recode # 
# then make a copy so you don't lose the pristine original.    #

# the command above
# db <- dbConnect( MonetDBLite::MonetDBLite() , dbfolder )
# has already connected the current instance of r to the monet database


############################################
# step 2: make all of your recodes at once #

# add new columns for each poverty line
pes.d <-
	update(
		pes.d ,
		nmorpob1 = 1 * ( v6531 < 70 ) , 
		nmorpob2 = 1 * ( v6531 < 80 ) , 
		nmorpob3 = 1 * ( v6531 < 90 ) , 
		nmorpob4 = 1 * ( v6531 < 100 ) , 
		nmorpob5 = 1 * ( v6531 < 140 ) , 
		nmorpob6 = 1 * ( v6531 < 272.50 ) 
	)

# ..and now you can calculate poverty rates many different ways
# with syntax from the R survey package
svytotal( ~ nmorpob1 + nmorpob2 + nmorpob3 + nmorpob4 + nmorpob5 + nmorpob6 , subset( pes.d , v6531 >= 0 ) , na.rm = TRUE )


# by state  #
wtd.pcts.by.state <- svyby( ~ nmorpob1 , ~v0001 , subset( pes.d , v6531 >= 0 ) , svymean , na.rm = TRUE )

# print these results to the screen
wtd.pcts.by.state


# # # # # # # # # #
# export examples #
# # # # # # # # # #

# create a character vector containing all states in order:
estado.names <- c( "Rondonia" , "Acre" , "Amazonas" , "Roraima" , "Para" , "Amapa" , "Tocantins" , "Maranhao" , "Piaui" , "Ceara" , "Rio Grande\ndo Norte" , "Paraiba" , "Pernambuco" , "Alagoas" , "Sergipe" , "Bahia" , "Minas Gerais" , "Espirito Santo" , "Rio de Janeiro" , "Sao Paulo" , "Parana" , "Santa Catarina" , "Rio Grande\ndo Sul" , "Mato Grosso\ndo Sul" , "Mato Grosso" , "Goias" , "Distrito Federal" )


# plot the percentage of households below 70 by state
barplot(
	coef( wtd.pcts.by.state ) ,
	main = "Percent of People in Households With PCI Below 70" ,
	names.arg = estado.names ,
	ylim = c( 0 , .25 ) ,
	cex.names = 0.7 ,
	col = c( rep( "lightgreen" , 7 ) , rep( "sandybrown" , 9 ) , rep( "palevioletred" , 4 ) , rep( "plum" , 3 ) , rep( "khaki" , 4 ) ) ,
	las = 2 ,
	# do not print the y axis at first
	yaxt = "n"
)

# add the y axis..
axis( 
	side = 2 , 
	# from 0 to 0.25, with tick marks every 0.05
	at = seq( 0 , .25 , .05 ) , 
	# saying 0%, 5% ..etc.. up to 25%
	labels = paste0( seq( 0 , 25 , 5 ) , "%" ) , 
	# turn the numbers rightside-up
	las = 2 
)

legend( 
	"topright" , 
	c( "North" , "Northeast" , "Southeast" , "South" , "Midwest") , 
	fill = c( "lightgreen" , "sandybrown" , "palevioletred" , "plum" , "khaki" ) 
)

# # # # # # # # # # # # # #
# end of export examples  #
# # # # # # # # # # # # # #



# # # # # # # # # # # # # # #
# ratio calculation example #
# # # # # # # # # # # # # # #

# calculate both the numerator and denominator of poverty
svyratio( ~ nmorpob1 , ~ one , subset( pes.d , v6531 >= 0 ) , na.rm = TRUE )

# by state
svyby( ~ nmorpob1 + one , denominator = ~ one , by = ~v0001 , design = subset( pes.d , v6531 >= 0 ) , FUN = svyratio , na.rm = TRUE )

# finito.

# close the connection to the survey design object
close( pes.d )


# disconnect from the current monet database
dbDisconnect( db , shutdown = TRUE )
