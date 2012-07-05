#NOTE that the three packages below must be installed (just once)
#if this is the first time using R with these packages, run this line:
#install.packages(c("mitools","survey","SAScii"))

#load the SAScii SAS/ASCII data importation package
library(SAScii)

#load the multiple imputation package
library(mitools)

#load the complex survey analysis package
library(survey)

#set the number of digits displayed
options(digits=16)

#location of incimps sas import file
incimps.sas <- "ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/2000_Imputed_Income/INCIMPS.sas"

#location of incimps ascii data files
incimps.exe <- "ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/2000_Imputed_Income/INCIMPS.EXE"

#location of personsx ascii data file
personsx.exe <- "ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/2000/personsx.exe"

#location of personsx sas import file
personsx.sas <- "ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Program_Code/NHIS/2000/personsx.sas"

#read in the personsx file
personsx <- read.SAScii( personsx.exe , personsx.sas , zipped = T )

#only keep the variables you need (to conserve RAM)
personsx.sub <- personsx[ , c("SRVY_YR","HHX","FMX","PX","PSU","STRATUM","WTFA","NOTCOV") ]

#and then delete personsx to conserve RAM
personsx <- NULL

#garbage collection: this frees up RAM
gc()

#create a temporary file to store the incimps zip file
tf <- tempfile()

#create a temporary directory to store the five unzipped incimps files
td <- tempdir()

#download the incimps.exe file to the temporary file
download.file( incimps.exe , tf , mode = "wb" )

#unpack the incimps.exe file to the temporary directory - and store the file names of the five incimps files to the object "income.file.names"
income.file.names <- unzip( tf , exdir = td )

#create a character vector of x1 - x5
imputed.income.object.names <- paste( "x" , 1:5 , sep = "" )

#loop through all five imputed income files
for ( i in 1:5 ){

	#read the ascii dat file directly into R
	incimps <- read.SAScii( income.file.names[i] , incimps.sas )

	#dump RECTYPE variable from the incimps- it is already on the PERSONSX file
	incimps$RECTYPE <- NULL

	#merge the personsx file with the imputed income file
	y <- 
		merge( 
			personsx.sub , 
			incimps , 
			by.x=c("SRVY_YR","HHX","FMX","PX") , 
			by.y=c("SRVY_YR","HHX","FMX","FPX") 
		)
	
	###########################
	#START OF VARIABLE RECODING
	#any new variables that the user would like to create should be constructed here

	#RECODES GO HERE
	
	#create the NOTCOV variable
	#shown on page 47 (PDF page 51) of http://www.cdc.gov/nchs/data/nhis/tecdoc_2010.pdf
	y <- transform( y , NOTCOV = ifelse( NOTCOV %in% 7:9 , NA , NOTCOV ))
	
	#create the POVERTYI variable
	#shown on page 48 (PDF page 52) of http://www.cdc.gov/nchs/data/nhis/tecdoc_2010.pdf
	y <- transform( y , POVERTYI =
		ifelse( POVRATI2 < 100 , 1 ,
		ifelse( POVRATI2 >= 100 & POVRATI2 < 200 , 2 ,
		ifelse( POVRATI2 >= 200 & POVRATI2 < 400 , 3 ,
		ifelse( POVRATI2 >= 400 , 4 , NA ) ) ) ) )

	#END OF VARIABLE RECODING
	#########################
		
	#save the data frames as objects x1 - x5, depending on the iteration in the loop
	assign( imputed.income.object.names[i] , y )

	#if you run out of RAM, uncomment this line!
	#delete the y and incimps data frames to free up RAM
	y <- incimps <- NULL
	
	#garbage collection: this frees up RAM
	gc()
}
#when the loop has terminated, data frames x1 through x5 exist
#each are the personsx file merged with one of the five imputed income files
#and each include all recoded variables.

#using all five merged personsx-MI files,
#create the multiple imputation survey object
nhissvy <- svydesign( id = ~PSU , strata=~STRATUM , weight=~WTFA , data=imputationList(list(x1,x2,x3,x4,x5)) , nest=T )

#if you run out of RAM, uncomment this line!
#delete the personsx and x1 - x5 data frame objects to free up RAM
#personsx <- x1 <- x2 <- x3 <- x4 <- x5 <- NULL

#garbage collection: this frees up RAM
gc()

##################################################################
#now that the R survey object (nhissvy) has been constructed,
#analyses can be run.

#the following output matches PDF page 60 on http://www.cdc.gov/nchs/data/nhis/tecdoc_2010.pdf

#this displays the crosstab statistics..

	#not broken out by the POVERTYI variable

#print the unweighted N
MIcombine( with( subset( nhissvy , !is.na(POVERTYI)) , unwtd.count( ~factor(NOTCOV) , na.rm=T ) ) )
#print the weighted N
MIcombine( with( subset( nhissvy , !is.na(POVERTYI)) , svytotal( ~factor(NOTCOV) , na.rm=T ) ) )
#print the overall percents
MIcombine( with( subset( nhissvy , !is.na(POVERTYI)) , svymean( ~factor(NOTCOV) , na.rm=T ) ) )

	#broken out by the POVERTYI variable

#print the unweighted N
MIcombine( with( nhissvy , svyby(~factor(NOTCOV) , ~factor(POVERTYI) , unwtd.count , na.rm=T ) ) )
#print the weighted N
MIcombine( with( nhissvy , svyby(~factor(NOTCOV) , ~factor(POVERTYI) , svytotal , na.rm=T ) ) )
#print the row percents
MIcombine( with( nhissvy , svyby(~factor(NOTCOV) , ~factor(POVERTYI) , svymean , na.rm=T ) ) )


