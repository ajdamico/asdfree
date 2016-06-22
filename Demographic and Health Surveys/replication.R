# analyze survey data for free (http://asdfree.com) with the r language
# demographic and health surveys
# malawi 2004

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/DHS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Demographic%20and%20Health%20Surveys/replication.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #


# this r script will replicate each of the statistics across
# the "children ever born" row on pdf page 324 (appendix b page 303) of
# http://dhsprogram.com/pubs/pdf/FR175/FR-175-MW04.pdf#page=324



# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#######################################################################################################
# prior to running this replication script, all dhs public use microdata files must be loaded as R data
# files (.rda) on the local machine. running the "download and import.R" script will create these files
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Demographic%20and%20Health%20Surveys/download%20and%20import.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will save a number of .rda files in C:/My Directory/DHS/ (or the working directory was chosen)
#######################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



################################################################################################
# analyze the 2004 malawi individual recode table of the demographic and health surveys with R #
################################################################################################


# set your working directory.
# all DHS data files will be stored here
# after downloading and importing.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/DHS/" )
# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( "survey" )


library(survey) 	# load survey package (analyzes complex design surveys)
library(foreign) 	# load foreign package (converts data files into R)


# by default, R will crash if a primary sampling unit (psu) has a single observation
# set R to produce conservative standard errors instead of crashing
# http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
# by uncommenting this line:
# options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN


# the r data.frame object can be loaded directly
# from your local hard drive,
# since the download script has already run

# load the 2004 malawi individual recodes data.frame object
load( "./Malawi/Standard DHS 2004/Individual Recode.rda" )

# convert the weight column to a numeric type
x$weight <- as.numeric( x$v005 )

# note: this next step is *not necessary* for your analyses.
# the only purpose of recoding the strata in this fashion is to
# match previously-published research


# you can read more about why this strata-recoding was performed
# and why it shouldn't be used for your own analyses here:
# http://userforum.dhsprogram.com/index.php?t=msg&th=1211&start=0&S=8d4ed15b72e445315cbe59ce0aa01205


# construct a two-column table of old- and new-strata identifiers
strata.recodes <-
	structure(list(oldstrata = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 
	12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 
	28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 
	44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 
	60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 
	76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 
	92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 
	106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 
	119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 
	132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 
	145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 
	158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 
	171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 
	184, 185, 186, 187, 188, 189, 190, 192, 193, 194, 195, 196, 197, 
	198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 
	211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 
	224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 
	237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 
	250, 251, 252, 253, 254, 255, 256, 257, 258, 259, 260, 261, 262, 
	263, 264, 265, 266, 267, 268, 269, 270, 271, 272, 273, 274, 275, 
	276, 277, 278, 279, 280, 281, 282, 283, 284, 285, 286, 287, 288, 
	289, 290, 291, 292, 293, 294, 295, 296, 297, 298, 299, 300, 301, 
	302, 303, 304, 305, 306, 307, 308, 309, 310, 311, 312, 313, 314, 
	315, 316, 317, 318, 319, 320, 321, 322, 323, 324, 325, 326, 327, 
	328, 329, 330, 331, 332, 333, 334, 335, 336, 337, 338, 339, 340, 
	341, 342, 343, 344, 345, 346, 347, 348, 349, 350, 351, 352, 353, 
	354, 355, 356, 357, 358, 359, 360, 361, 362, 363, 364, 365, 366, 
	367, 368, 369, 370, 371, 372, 373, 374, 375, 376, 377, 378, 379, 
	380, 381, 382, 383, 384, 385, 386, 387, 388, 389, 390, 391, 392, 
	393, 394, 395, 396, 397, 398, 399, 400, 401, 402, 403, 404, 405, 
	406, 407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417, 418, 
	419, 420, 421, 422, 423, 424, 425, 426, 427, 428, 429, 430, 431, 
	432, 433, 434, 435, 436, 437, 438, 439, 440, 441, 442, 443, 444, 
	445, 446, 447, 448, 449, 450, 451, 452, 453, 454, 455, 456, 457, 
	458, 459, 460, 461, 462, 463, 464, 465, 466, 467, 468, 469, 470, 
	471, 472, 473, 474, 475, 476, 477, 478, 479, 480, 481, 482, 483, 
	484, 485, 486, 487, 488, 489, 490, 491, 492, 493, 494, 495, 496, 
	497, 498, 499, 500, 501, 502, 503, 504, 505, 506, 507, 508, 509, 
	510, 511, 512, 513, 514, 515, 516, 517, 518, 519, 520, 521, 522
	), newstrata = c(103, 66, 140, 56, 21, 214, 243, 109, 71, 201, 
	30, 215, 210, 172, 236, 46, 99, 43, 248, 222, 110, 182, 63, 61, 
	221, 220, 171, 192, 185, 22, 77, 54, 92, 89, 144, 158, 35, 250, 
	153, 97, 132, 3, 176, 90, 183, 204, 177, 2, 47, 161, 244, 94, 
	220, 234, 80, 138, 52, 24, 124, 4, 186, 44, 222, 120, 6, 216, 
	227, 126, 71, 49, 186, 38, 189, 12, 190, 86, 58, 83, 13, 169, 
	73, 232, 116, 96, 208, 1, 151, 90, 34, 130, 241, 11, 172, 114, 
	40, 242, 28, 28, 199, 10, 167, 48, 45, 69, 119, 7, 209, 146, 
	10, 27, 183, 228, 32, 25, 156, 48, 177, 128, 197, 251, 174, 166, 
	57, 147, 140, 20, 163, 156, 123, 189, 176, 237, 249, 88, 166, 
	212, 73, 224, 36, 36, 108, 65, 191, 228, 210, 40, 196, 160, 15, 
	78, 83, 118, 19, 22, 81, 152, 219, 125, 127, 188, 250, 55, 195, 
	129, 67, 221, 51, 233, 105, 231, 97, 24, 251, 79, 172, 78, 100, 
	57, 116, 148, 134, 74, 227, 237, 214, 171, 175, 240, 163, 21, 
	93, 76, 201, 187, 62, 125, 157, 79, 126, 234, 136, 102, 8, 96, 
	170, 178, 70, 213, 31, 19, 192, 240, 121, 174, 231, 95, 202, 
	179, 226, 246, 14, 194, 33, 109, 233, 138, 108, 42, 91, 154, 
	39, 232, 245, 56, 141, 213, 16, 38, 197, 220, 82, 65, 31, 117, 
	218, 159, 205, 47, 195, 182, 223, 154, 173, 218, 39, 104, 52, 
	184, 133, 26, 247, 160, 123, 142, 149, 147, 41, 193, 106, 50, 
	168, 61, 194, 92, 164, 67, 187, 219, 86, 4, 12, 6, 43, 51, 161, 
	230, 106, 175, 17, 145, 84, 211, 158, 5, 87, 244, 130, 72, 91, 
	89, 151, 37, 33, 41, 115, 55, 122, 243, 165, 23, 64, 109, 136, 
	168, 95, 131, 170, 88, 113, 44, 206, 235, 37, 187, 29, 211, 144, 
	115, 74, 190, 78, 114, 63, 242, 26, 66, 248, 107, 60, 29, 139, 
	20, 142, 134, 59, 77, 184, 219, 68, 27, 45, 135, 103, 128, 162, 
	179, 246, 155, 15, 64, 165, 53, 107, 230, 42, 99, 30, 46, 25, 
	137, 198, 84, 200, 149, 125, 164, 62, 112, 127, 200, 113, 193, 
	124, 7, 209, 16, 111, 133, 93, 202, 155, 112, 32, 178, 225, 239, 
	14, 23, 117, 229, 224, 72, 162, 140, 204, 188, 111, 98, 135, 
	157, 69, 18, 9, 59, 181, 208, 196, 203, 235, 13, 76, 153, 181, 
	171, 110, 70, 150, 94, 238, 236, 98, 203, 238, 217, 119, 68, 
	100, 201, 9, 205, 199, 159, 245, 105, 223, 86, 121, 167, 143, 
	75, 141, 129, 247, 137, 82, 180, 60, 102, 185, 198, 53, 156, 
	249, 157, 11, 1, 145, 146, 202, 180, 132, 120, 77, 215, 101, 
	17, 118, 2, 50, 216, 206, 92, 148, 191, 81, 229, 49, 212, 217, 
	207, 173, 58, 241, 101, 104, 35, 225, 5, 122, 139, 3, 87, 239, 
	80, 143, 226, 93, 150, 18, 169, 141, 124, 108, 54, 75, 131, 188, 
	152, 34, 207, 8)), .Names = c("oldstrata", "newstrata"), row.names = c(NA, 
	-521L), class = "data.frame")

# now we have access to a table full of strata recodes
# look at the first six records
head( strata.recodes )
	
# merge these strata recodes on to the main individual recodes data.frame object
x <- merge( x , strata.recodes , by.x = 'v021' , by.y = 'oldstrata' )
# these older strata should line up to column v021 precisely.



#################################################
# survey design for taylor-series linearization #
#################################################

# create a survey design object with DHS design information
y <- 
	svydesign( 
		~v021 , 
		strata = ~newstrata , 
		data = x , 
		weights = ~weight 
	)
# to repeat: for more current analyses, `newstrata` is incorrect.
# instead, follow the examples in the `analysis examples` script

# start reproducing the "children ever born" row of the malawi 2004 table

# print the unweighted n to the screen
nrow( y )

# print the weighted n to the screen
sum( x$weight ) / 1000000

# store the svymean result of the "children ever born" column
z <- svymean( ~v201 , y , deff = TRUE )
# into a new object called `z`

# print the mean - coefficient
coef( z )

# print the standard error
SE( z )

# print the square root of the design effect, the deft
sqrt( deff( z ) )

# print the relative standard error
SE( z ) / coef( z )

# print the dhs lower and upper bounds of the confidence interval (they use 2 instead of 1.96
coef( z ) - SE( z ) * 2
coef( z ) + SE( z ) * 2

# print hooray
print( "hooray!" )

###############################################################
# end of printing the exact contents of the row to the screen #
###############################################################

