# analyze survey data for free (http://asdfree.com) with the r language
# national survey of oaa participants
# 2003 and 2012

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NPS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Survey%20of%20OAA%20Participants/replication.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico the first
# ajdamico@gmail.com


############################################################
# this script matches every statistic and standard error pulled from agidnet at:
# https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Survey%20of%20OAA%20Participants/agidnet%202003%20caregiver%20-%20respite%20care.png
# and
# https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Survey%20of%20OAA%20Participants/agidnet%202012%20home%20delivered%20meals%20-%20past%20year%20hospital%20and%20nursing%20home.png
############################################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#########################################################################################################################
# prior to running this analysis script, the 2003 caregiver and 2012 home delivered meals files must be loaded onto the #
# local machine.  running the download all microdata script below will import all of the files that are needed.         #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Survey%20of%20OAA%20Participants/download%20all%20microdata.R #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will files in the C:/My Directory/NPS directory or wherever the working directory was set.                #
#########################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# set your working directory.
# the NPS data files should have been stored here
# after running the program described above
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NPS/" )
# ..in order to set your current working directory

# remove the # in order to run this install.packages line only once
# install.packages( "survey" )


library(survey)		# load survey package (analyzes complex design surveys)


# # # # # # # # # # # # # # # # # # # # # # #
# precisely match the 2003 caregiver output #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Survey%20of%20OAA%20Participants/agidnet%202003%20caregiver%20-%20respite%20care.png

# load the 2003 caregiver file into working memory
load( "./2003/caregiver.rda" )

# according to the 2003 caregiver codebook,
# http://www.agidnet.org/DataFiles/Documents/NPS/Caregiver2003/Codebook_Caregiver_2003.html
# `cgsvc05` is the "received respite care" variable

# run a simple unweighted crosstab
table( x$cgsvc05 , useNA = 'always' )
# matchs the "survey responses" column

# sum up the main weight 
sum( x$cpswgt )
# matches the "grand total" of the "weighted count" column

# create the fay's adjusted brr design object
y <- 
	svrepdesign( 
		data = x , 
		repweights = "cpwgt[0-9]" , 
		weights = ~cpswgt , 
		type = "Fay" , 
		rho = 0.29986 , 
		mse = TRUE
	)

# precisely match each of the numbers in the "weighted count" column
svytotal( ~factor( cgsvc05 ) , y )

# sum up the main weight without missings
svytotal( ~one , subset( y , cgsvc05 > 0 ) )
# matches the "weighted count" of the
# "total" but not "grand total" row

# match the percent and percent standard error columns
svymean( ~factor( cgsvc05 ) , subset( y , cgsvc05 > 0 ) )

# clear both the data.frame `x` and
# the svrepdesign `y` objects from memory
rm( x , y )

# clear up RAM
gc()


# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# precisely match the 2012 home delivered meals output  #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Survey%20of%20OAA%20Participants/agidnet%202012%20home%20delivered%20meals%20-%20past%20year%20hospital%20and%20nursing%20home.png

# load the 2012 home delivered meals file into working memory
load( "./2012/home delivered meals.rda" )

# according to the 2012 home delivered meals codebook,
# http://www.agidnet.org/DataFiles/Documents/NPS/HomeDeliveredMeals2012/Codebook_Home_Meals_2012.html
# `hlmhosp` is the "overnight stay in a hospital" variable
# and
# `hlmnh` is the "overnight stay in a nursing home or rehab center" variable

# run two simple unweighted crosstabs
table( x$hlmhosp , useNA = 'always' )

table( x$hlmnh , useNA = 'always' )
# matchs the "survey responses" column

# create the fay's adjusted brr design object
y <- 
	svrepdesign( 
		data = x , 
		repweights = "pswgt[0-9]" , 
		weights = ~pswgt , 
		type = "Fay" , 
		rho = 0.29986 , 
		mse = TRUE
	)

# precisely match each of the numbers in the "weighted count" column
svytotal( ~factor( hlmhosp ) + factor( hlmnh ) , y )

# sum up the main weight without missings
svytotal( ~one , subset( y , hlmhosp > 0 ) )
svytotal( ~one , subset( y , hlmnh > 0 ) )
# matches the "weighted count" of the
# "total" but not "grand total" row

# match the percent and percent standard error columns
svymean( ~factor( hlmhosp ) , subset( y , hlmhosp > 0 ) )

svymean( ~factor( hlmnh ) , subset( y , hlmnh > 0 ) )

# clear both the data.frame `x` and
# the svrepdesign `y` objects from memory
rm( x , y )

# clear up RAM
gc()


#########################################
# end of agidnet statistics replication #
#########################################
