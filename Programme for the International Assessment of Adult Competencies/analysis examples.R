# analyze survey data for free (http://asdfree.com) with the r language
# programme for the international assessment of adult competencies
# panel #1 (surveys conducted august 1st 2011 - march 31st 2012)

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/PIAAC/" )
# source_url( "https://raw.github.com/ajdamico/asdfree/master/Programme%20for%20the%20International%20Assessment%20of%20Adult%20Competencies/analysis%20examples.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# https://www.youtube.com/watch?v=JLt9JfaAxUg

# anthony joseph damico
# ajdamico@gmail.com

# if you use this script for a project, please send me a note
# it's always nice to hear about how people are using this stuff

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
###########################################################################################################################################
# prior to running this analysis script, the piaac multiply-imputed tables must be loaded as a replicate-weighted survey object on the    #
# local machine. running the download, import, and design script will create an r data file (.rda) with whatcha need.                     #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "https://raw.github.com/ajdamico/asdfree/master/Programme%20for%20the%20International%20Assessment%20of%20Adult%20Competencies/download%20import%20and%20design.R"  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create the files "prgautp1.rda" and "prgbelp1.rda" in C:/My Directory/PIAAC or wherever the working directory was set. #
###########################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PIAAC/" )


library(survey)			# load survey package (analyzes complex design surveys)
library(mitools) 		# load mitools package (analyzes multiply-imputed data)


# load the r data file of the country you'd like to work with.
# the `.rda` file should already exist in the working directory,
# because you've already run the download script, right?
load( 'prgusap1.rda' )

# note: if you want to analyze multiple countries,
# you'll have to write a loop or create some `apply` functions.
# the replication script has a simple example of how to analyze all countries inside a loop.


# now you have a data.frame object..
class( prgusap1 )

# ..and also the replicate-weighted, multiply-imputed svyimputationList object.
class( prgusap1.design )



# # # # # # # # # # # # #
# quick recode example  #
# # # # # # # # # # # # #

# recodes to piaac tables are simple.
# just use the `update` function on a svyimputationList object
# the way you would use the `transform` function on a data.frame object
prgusap1.design <- update( prgusap1.design , one = 1 )
# the line above just added a column of all ones.
# you can read more about it by typing
# ?survey::update.svyrep.design




# count the total (unweighted) number of records in the usa table's piaac #

# this can either be run on the original data.frame object..
nrow( prgusap1 )

# ..or on the multiply-imputed, replicate-weighted design object
nrow( prgusap1.design )

# count the total (unweighted) number of records in piaac #
# broken out by age group #

# again, either use the data.frame object..
table( prgusap1$ageg10lfs )

# ..or the survey design object
MIcombine( with( prgusap1.design , svyby( ~ one , ~ ageg10lfs , unwtd.count ) ) )


# count the weighted number of adults aged 16 to 65 in the united states
MIcombine( with( prgusap1.design , svytotal( ~ one ) ) )

# by age group
MIcombine( with( prgusap1.design , svyby( ~ one , ~ ageg10lfs , svytotal ) ) )


# calculate the mean of a linear variable #

# average numeracy - across all individuals in the data set
MIcombine( with( prgusap1.design , svymean( ~ pvnum , na.rm = TRUE ) ) )

# by age group
MIcombine( with( prgusap1.design , svyby( ~ pvnum , ~ ageg10lfs , svymean , na.rm = TRUE ) ) )


# calculate the distribution of a categorical variable #

# sex should be treated as a factor (categorical) variable
# instead of a numeric (linear) variable
# this update statement converts it.
# the commands below will not give distributions without this
prgusap1.design <- update( prgusap1.design , gender_r = factor( gender_r ) )


# percent of 16 - 65 year old males vs. females - nationwide
MIcombine( with( prgusap1.design , svymean( ~ gender_r , na.rm = TRUE ) ) )

# by age group
MIcombine( with( prgusap1.design , svyby( ~ gender_r , ~ ageg10lfs , svymean , na.rm = TRUE ) ) )


# calculate the median and other percentiles #

# minimum, 25th, 50th, 75th, maximum
# numeracy
MIcombine( 
	with( 
		prgusap1.design , 
		svyby( 
			~ pvnum , 
			~ one , 
			svyquantile , 
			c( 0 , .25 , .5 , .75 , 1 ) , 
			ci = TRUE ,
			na.rm = TRUE
		) 
	) 
)

# by age group
MIcombine( 
	with( 
		prgusap1.design , 
		svyby( 
			~ pvnum , 
			~ ageg10lfs , 
			svyquantile , 
			c( 0 , .25 , .5 , .75 , 1 ) , 
			ci = TRUE ,
			na.rm = TRUE
		) 
	) 
)


######################
# subsetting example #
######################

# restrict the prgusap1.design object to females
prgusap1.design.females <- subset( prgusap1.design , gender_r %in% 2 )
# now any of the above commands can be re-run
# using prgusap1.design.females object
# instead of the prgusap1.design object
# in order to analyze females only

# calculate the mean of a linear variable #

# average numeracy - nationwide, 
# restricted to females
MIcombine( with( prgusap1.design.females , svymean( ~ pvnum , na.rm = TRUE ) ) )

# remove this subset design to clear up memory
rm( prgusap1.design.females )

# clear up RAM
gc()



##################
# export example #
##################

# calculate the literacy scale score by age group

# store the results into a new object, `literacy.scores.by.agegroup`
literacy.scores.by.agegroup <-
	MIcombine( 
		with( 
			prgusap1.design , 
			svyby( 
				~ pvlit , 
				~ ageg10lfs , 
				svymean ,
				na.rm = TRUE
			) 
		) 
	)

# print the results to the screen 
literacy.scores.by.agegroup

# now you have the results saved into a new object of type "MIresult"
class( literacy.scores.by.agegroup )

# print only the statistics (coefficients) to the screen
# and save them into the object `lsba.c`
( lsba.c <- coef( literacy.scores.by.agegroup ) )

# print only the standard errors to the screen
# and save them into the object `lsba.se`
( lsba.se <- SE( literacy.scores.by.agegroup ) )

# this object cannot be coerced (converted) to a data frame.. 
# literacy.scores.by.agegroup <- data.frame( literacy.scores.by.agegroup ) # this command will throw an error
# instead, manually place the coefficients and standard errors into a data frame side-by-side
# note that the row numbers match the age group values in this case..
lsba <- data.frame( coef = lsba.c , se = lsba.se )

# (look at lsba)
lsba

# ..however, if they didn't, it might be useful to add a column containing those values.
lsba <- 
	data.frame( 
		agegroup = names( lsba.c ) ,
		coef = lsba.c ,
		se = lsba.se
	)
	
# (look at lsba again)
lsba


# immediately export the results as a comma-separated value file
# into your current working directory..
write.csv( lsba , "literacy scores by age group.csv" )

# ..or directly into a bar plot
barplot(
	lsba[ , 2 ] ,
	main = "Literacy Scores by Age Group" ,
	names.arg = c( '24 or less' , '25-34' , '35-44' , '45-54' , '55 plus' ) ,
	ylim = c( 0 , 300 )
)


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
