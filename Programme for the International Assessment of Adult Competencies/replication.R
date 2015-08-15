# analyze survey data for free (http://asdfree.com) with the r language
# programme for the international assessment of adult competencies
# austria.. belgium.. oh hell why not all of them

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/PIAAC/" )
# source_url( "https://raw.github.com/ajdamico/asdfree/master/Programme%20for%20the%20International%20Assessment%20of%20Adult%20Competencies/replication.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
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



##########################################
# okay time to start replicating numbers #
##########################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# in oecd publication
# http://www.oecd.org/site/piaac/SkillsOutlook2013_ENG_Table_Annex%20B.xlsx


# load the austria data.frame and survey design object
load( "prgautp1.rda" )

# load the belgium data.frame and survey design object
load( "prgbelp1.rda" )


# in this excel document, check the tab titled `Table B3.4` #

# exactly match the % and SEs for austria
MIcombine( with( prgautp1.design , svymean( ~ factor( gender_r ) ) ) )	

# exactly match the % and SEs for belgium
MIcombine( with( prgbelp1.design , svymean( ~ factor( gender_r ) ) ) )	
	

# no.  really.  click on each excel cell to see that it *exactly* matches
# down to the tiniest decimal.  kewl, eh?

	
# same excel document, tab titled `Table B3.1 (N)` #

# exactly match the mean and SEs for austria
MIcombine( with( prgautp1.design , svyby( ~ pvnum , ~ gender_r + ageg10lfs , svymean , na.rm = TRUE ) ) )

# exactly match the mean and SEs for belgium
MIcombine( with( prgbelp1.design , svyby( ~ pvnum , ~ gender_r + ageg10lfs , svymean , na.rm = TRUE ) ) )


# done with that!  remove those objects from working memory
rm( prgautp1.design , prgautp1 , prgbelp1.design , prgbelp1 )

# clear up RAM
gc()

# end of precise oecd matching in that excel file.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# pdf page 48 of this oecd technical report document
# http://www.oecd.org/site/piaac/Technical%20Report_Part%205.pdf#page=48
# contains the three multiply-imputed variables with standard errors.
# let's loop through every country and match these, shall we?

# first, look inside your current working directory
# for `.rda` files that contain the survey design objects
# to do that, we'll look for files that match the pattern `[anything]p1.rda`
cwd.rdas <- list.files()[ grep( "p1\\.rda\\b" , list.files() ) ]

# loop through each country file..
for ( this.country in cwd.rdas ){

	# load the survey design object of the current country
	load( this.country )
	
	# figure out the country abbreviation from the filename
	country.abb <- gsub( "prg(.*)p1\\.rda" , "\\1" , this.country )

	# figure out the country's survey design object from the filename
	country.design.name <- paste0( gsub( "\\.rda" , "" , this.country ) , ".design" )
	
	# print the country abbreviation to the screen
	print( country.abb )
		
	print( MIcombine( with( get( country.design.name ) , svymean( ~pvlit , na.rm = TRUE ) ) ) )
	print( MIcombine( with( get( country.design.name ) , svymean( ~pvnum , na.rm = TRUE ) ) ) )
	
	# some countries do not have an avilable pstre measure.
	pstre.attempt <- try( print( MIcombine( with( get( country.design.name ) , svymean( ~pvpsl , na.rm = TRUE ) ) ) ) , silent = TRUE )

	if ( class( pstre.attempt ) == 'try-error' ) print( paste( 'pstre measure not available in' , country.abb ) )
	
	rm( list = c( gsub( "\\.rda" , "" , this.country ) , country.design.name ) )
	
	gc()
	
}

# end of precise oecd matching in that pdf document.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


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
