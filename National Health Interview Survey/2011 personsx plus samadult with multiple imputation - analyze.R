# analyze us government survey data with the r language
# national health interview survey
# 2011 personsx plus samadult with multiple imputation

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



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################################
# prior to running, the nhis 2011 personsx, samadult, incmimp# files must be loaded as an R data file (.rda) on the local machine.  #
# running the "1963-2011 - download all microdata.R" script will create this R data file (note: only 2011 files need to be loaded)  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/usgsd/blob/master/National%20Health%20Interview%20Survey/1963-2011%20-%20download%20all%20microdata.R #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a files "/2011/_filename_.rda" in C:/My Directory/NHIS (or wherever the working directory was chosen)     #
#####################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



#########################################################################################################
# Analyze the 2011 National Health Interview Survey personsx, samadult, and imputed income files with R #
#########################################################################################################


# set your working directory.
# the NHIS 2011 personsx, samadult, and incmimp# data files should have been
# stored in a year-specific directory within this folder.
# so if the file "personsx.rda" exists in the directory "C:/My Directory/NHIS/2011/" 
# then the working directory should be set to "C:/My Directory/NHIS/"
# use forward slashes instead of back slashes

setwd( "C:/My Directory/NHIS/" )


# remove the # in order to run this install.packages line only once
# install.packages( c( "survey" , "mitools" ) )
	
require(survey) 	# load survey package (analyzes complex design surveys)
require(mitools)	# allows analysis of multiply-imputed survey data

# set R to produce conservative standard errors instead of crashing
# http://faculty.washington.edu/tlumley/survey/exmample-lonely.html
options( survey.lonely.psu = "adjust" )
# this setting matches the MISSUNIT option in SUDAAN


# choose what year of data to analyze
# note: this can be changed to any year that has already been downloaded locally
# by the "1963-2011 - download all microdata.R" program above
year <- 2011


# construct the filepath (within the current working directory) to the three rda files
path.to.personsx.file <- paste( getwd() , year , "personsx.rda" , sep = "/" )
path.to.samadult.file <- paste( getwd() , year , "samadult.rda" , sep = "/" )
path.to.incmimp.file <- paste( getwd() , year , "incmimp.rda" , sep = "/" )


# print those filepaths to the screen
print( path.to.personsx.file )
print( path.to.samadult.file )
print( path.to.incmimp.file )


# now the "NHIS.11.personsx.df" data frame can be loaded directly
# from your local hard drive.  this is much faster.
load( path.to.personsx.file )		# this loads a data frame called NHIS.11.personsx.df
load( path.to.samadult.file )		# this loads a data frame called NHIS.11.samadult.df
# the five imputed income files will be loaded later

# all objects currently in memory can be viewed with the list function
ls()


# construct a string containing the data frame name of the personsx data table
# stored within the R data file (.rda)
# note: for 2011, this data frame will be named "NHIS.11.personsx.df"
# but constructing it dynamically will allow analyses of other years
# by simply changing the 'year' variable above
df.name <- paste( "NHIS" , substr( year , 3 , 4 ) , "personsx" , "df" , sep = "." )

# repeat this for the sample adult data frame, 
# but not for the five imputed income data frames (which will be dealt with later)
samadult.name <- paste( "NHIS" , substr( year , 3 , 4 ) , "samadult" , "df" , sep = "." )


# copy the personsx data frame to the variable x for easier analyses
# (because NHIS.11.personsx.df is unwieldy to keep typing)
x <- get( df.name )

# copy the samadult data frame to the variable sa for easier typing
# (because NHIS.11.samadult.df is unwieldy to keep typing)
sa <- get( samadult.name )


# remove the original copy of the two data frames from memory
rm( list = c( df.name , samadult.name ) )

# clear up RAM
gc()


#####################################
# merge personsx and samadult files #
#####################################

# note: the logical steps taken here could also be applied to 
# merging the personsx and samchild files

# the personsx and samadult files are both at the individual or person-level
# (as opposed to family-level or household-level)
# so merging them together will require three variables:
# hhx (household unique identifier)
# fmx (family unique identifier)
# fpx (person unique identifier)

# store the names of these three columns in a character vector
merge.vars <- c( "hhx" , "fmx" , "fpx" )

# these two files have multiple overlapping (redundant) columns,
# so determine which columns are included in both data frames
# at the same time, enclose this statement in () thereby printing the vector to the screen
( columns.in.both.dfs <- intersect( names( sa ) , names( x ) ) )


# since the merge.vars will be used to merge the two data frames,
# those three variables should be excluded from the list of redundant columns
# keep all column names that don't match the merge variables
# at the same time, enclose this statement in () thereby printing the vector to the screen
( redundant.columns <- columns.in.both.dfs[ !( columns.in.both.dfs %in% merge.vars ) ] )

# notice that the three merge.vars have disappeared


# most analyses start with the personsx file,
# so shave the redundant columns off of the samadult file
# keep all columns in the samadult file that are not in the redundant.columns vector
sa <- sa[ , !( names( sa ) %in% redundant.columns ) ]


# at this point, the only overlap between the personsx and samadult files
# should be the three merge.vars
# throw an error if that's not true
stopifnot( merge.vars == intersect( names( sa ) , names( x ) ) )


# remember that the samadult file contains a subset of the individuals in personsx
# therefore, an inner join of the two should have the same number of records as samadult

# perform the actual merge
x.sa <- merge( x , sa )
# note that the merge() function merges using all intersecting columns -

# uncomment this line to see intersecting columns
# intersect( names( sa ) , names( x ) )

# - by default, the 'by' parameter does not need to be specified
# for more detail about the merge function, type ?merge in the console

# throw an error if the number of records in the merged file
# does not match the number of records in the samadult file
stopifnot( nrow( x.sa ) == nrow( sa ) )


# now the x.sa data frame contains all of the rows in the samadult file and 
# all columns from both the samadult and personsx files
# therefore, there's no more need for the samadult file on its own
# so delete the samadult file
rm( sa )

# and clear up RAM
gc()


# at this point, taylor-series linearization survey objects can be created
# so long as the analysis does not involve the imputed income variables


#################################################
# survey design for taylor-series linearization #
# not using any imputed income variables        #
#################################################

# create survey design object with NHIS design information
# using personsx alone
personsx.design <- 
	svydesign(
		id = ~psu_p , 
		strata = ~strat_p ,
		nest = TRUE ,
		weights = ~wtfa ,
		data = x
	)


# create survey design object with NHIS design information
# using the merged personsx and samadult files
psa.design <- 
	svydesign(
		id = ~psu_p , 
		strata = ~strat_p ,
		nest = TRUE ,
		weights = ~wtfa_sa ,	# note the change in the weighting variable
		data = x.sa				# note the change in the source data frame
	)

	
# notice these two 'design' objects can be used 
# in all subsequent analysis commands that do not involve imputed income

	
#######################
# analysis examples   #
# sans imputed income #
#######################

# count the total (unweighted) number of records in nhis #

# simply use the nrow function on both designs
nrow( personsx.design )
nrow( psa.design )

# since the samadult file is a subset of the personsx file,
# the personsx.design should always be used if it contains
# all variables necessary for the analysis.  the sample size is larger.


# count the weighted number of individuals in nhis #

# add a new variable 'one' that simply has the number 1 for each record #

personsx.design <-
	update( 
		one = 1 ,
		personsx.design
	)

psa.design <-
	update( 
		one = 1 ,
		psa.design
	)

# remember that the samadult file only generalizes to the adult population,
# so the merged personsx-samadult file also generalizes to adults only
	
# the civilian, non-institutionalized population of the united states #
svytotal( 
	~one , 
	personsx.design 
)

# the adult civilian, non-institutionalized population of the united states #
svytotal(
	~one ,
	psa.design 
)


# note that at any time, the personsx.design can be subsetted to adults only,
# which would also generalize to the adult civilian non-institutionalized pop.
adult.only.personsx.design <-
	subset( personsx.design , age_p >= 18 )

# and this number should be close to (but perhaps not perfectly aligned with)
# the personsx-samadult merge file's population total, since both estimate
# the adult civilian, non-institutionalized population of the united states #
svytotal(
	~one ,
	adult.only.personsx.design
)

	
# this has the advantage of a larger sample size
# than the samadult-personsx merge file
nrow( adult.only.personsx.design )
nrow( psa.design )

# but the disadvantage of not containing any columns
# included in the sample adult questionnaire
ncol( adult.only.personsx.design )
ncol( psa.design )


# # # # # # # # # # # # # # # # # # # 
# for additional analysis examples, #
# see the other 'analyze' script in #
# the same NHIS github folder       #

# any of those analysis examples    #
# starting with 'svy' like svymean, #
# svytotal, svyquantile, svyglm can #
# be run on designs created above   #
# # # # # # # # # # # # # # # # # # # 

# remove all of these objects from memory to conserve RAM
rm( personsx.design , psa.design , adult.only.personsx.design )

# clear up RAM
gc()


# end of personsx - samadult merge example #

############################################


#######################################
# prepare data frames for an analysis #
# involving multiply-imputed income   #
#######################################


# from the code above, two large data frames are still in memory:
# x (the personsx data frame) and
# x.sa (the merged personsx-samadult data frame)

# note: the following steps to create a survey design with multiply-imputed variables
# can be applied using either the x or x.sa data frame.  the following example will use x.sa,
# but x can be used with the same techniques (however, the weighting variable must be changed)


# this example uses x.sa (the merged data frame), so delete x (the personsx data frame)
rm( x )

# and immediately clear up RAM
gc()


# now load the imputed income data frames
load( path.to.incmimp.file )		# this loads five data frames called ii1, ii2, ii3, ii4, and ii5


# loop through all five imputed income files
for ( i in 1:5 ){

	# create a temporary current.i data frame
	# containing the current iteration's (1 through 5) imputed income file
	current.i <- get( paste0( "ii" , i ) )

	# the 2011 imputed income merge fields are currently stored as character variables
	# and should immediately be converted over to numeric types
	merge.vars <- intersect( names( x.sa ) , names( current.i ) )
	
	# loop through all variables used in the merge
	# overwrite each column with itself, only converted to a numeric field
	for ( j in merge.vars ) x.sa[ , j ] <- as.numeric( x.sa[ , j ] )
	
	
	# a handy trick to view the class of all columns within a data frame at once:
	# sapply( x.sa , class )
	

	# merge the merged file with each of the five imputed income files
	y <- 
		merge( 
			x.sa , # the 2011 samadult-personsx merged data frame
			current.i # ii1 - ii5, depending on the current iteration of this loop
		)

	# and confirm the new data frame (merged + the current iteration of the multiply-imputed data)
	# contains the same number of records as the original merged file
	stopifnot( nrow( x.sa ) == nrow( y ) )
		
		
	##############################
	# START OF VARIABLE RECODING #
	# any new variables that the user would like to create should be constructed here #

	# create two different poverty category variables
	y <- 
		transform( 
			y , 
			
			# note that these poverty categories go out to the tenth decimal
			
			# create an 'at or above 200% fpl' flag
			at.or.above.200 = ifelse( povrati3 >= 2000 , 1 , 0 ) ,
			
			# create a four-category poverty variable
			fine.povcat =
				cut( 
					povrati3 , 
					c( -Inf , 1380 , 2000 , 4000 , Inf ) ,
					labels = c( "<138%" , "138-200%" , "200-399%" , "400%+" )
				)
		)

	# to look closely at, for example, the first imputed income file, uncomment these lines:
	# head( ii1 )				# first six records of ii1
	# summary( ii1$povrati3 )	# summary statistics of the povrati3 column in ii1
		
	# END OF VARIABLE RECODING #
	############################
		
	# save the data frames as objects x1 - x5, depending on the iteration in the loop
	assign( paste0( 'x' , i ) , y )

	# delete the y and ii# data frames
	y <- NULL
	assign( paste0( "ii" , i ) , NULL )
	
	# garbage collection - free up RAM from recently-deleted data tables
	gc()
}



# build a new survey design object,
# but unlike the 'personsx.design' or 'psa.design' objects above,
# this object contains the five multiply-imputed data tables - imp1 through imp5
psa.imp <- 
	svydesign( 
		id = ~psu_p , 
		strata = ~strat_p ,
		nest = TRUE ,
		weights = ~wtfa_sa ,	# note the change in the weighting variable
		data = imputationList( list( x1 , x2 , x3 , x4 , x5 ) )
	)

# if this analysis had not required samadult questions, the weighting variable
# would have been 'wtfa' from the personsx table

	
# note that survey design objects containing multiply-imputed data
# (like income in this case) must be analyzed using the MIcombine function 
# in the format of the examples below

	
# calculate the mean of a linear variable #

# average age
MIcombine( 
	with( 
		psa.imp , 
		svymean( ~age_p ) 
	) 
)

# broken out by fine poverty categories
MIcombine( 
	with( 
		psa.imp , 
		svyby( 
			~age_p , 
			~fine.povcat ,
			svymean 
		) 
	) 
)


# calculate the distribution of a categorical variable #

# any worries about paying medical bills
MIcombine( 
	with( 
		psa.imp , 
		svymean( 
			~factor( aworpay ) 
		) 
	) 
)

# broken out by above/below 200% fpl
MIcombine( 
	with( 
		psa.imp , 
		svyby( 
			~factor( aworpay ) , 
			~at.or.above.200 ,
			svymean 
		) 
	) 
)


# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/
