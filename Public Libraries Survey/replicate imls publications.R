# analyze survey data for free (http://asdfree.com) with the r language
# public libraries survey
# replication of tables published by the 
# institute of museum and library services

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/PLS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Public%20Libraries%20Survey/replicate%20imls%20publications.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


####################################################
# analyze the Public Libraries Survey files with R #
####################################################


# set your working directory.
# all pls data files will be stored here
# after downloading and importing.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PLS/" )
# ..in order to set your current working directory


# increase the number of digits printed to the screen
options( digits = 8 )


# load the main 2001 microdata set,
# already downloaded into the current working directory
# thanks to the handy download script
load( "2001 - pupldb.rda" )


# precisely match the frequencies for the `c_relatn` variable
# shown on pdf page 73 of this imls-published document
# http://www.imls.gov/assets/1/AssetManager/fy2001_pls_database_documentation.pdf#page=73
table( pupldb$c_relatn )


# precisely match the mean, min, max for the `popu_lsa` variable
# shown on pdf page 76 of this imls-published document
# http://www.imls.gov/assets/1/AssetManager/fy2001_pls_database_documentation.pdf#page=76
summary( pupldb$popu_lsa , na.rm = TRUE )

# print the standard deviation as well
sd( pupldb$popu_lsa , na.rm = TRUE )



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
