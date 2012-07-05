#only run this line of code the first time
install.packages("SAScii")

#load the SAScii library
library(SAScii)

#set the directory to save NHIS data frames
setwd("C:/My Directory/NHIS/")


##Load the 2010 National Health Interview Survey Persons file as an R data frame
NHIS.10.personsx.SAS.read.in.instructions <-
	"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Program_Code/NHIS/2010/PERSONSX.sas"
NHIS.10.personsx.file.location <-
	"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/2010/personsx.zip"

#store the NHIS file as an R data frame
NHIS.10.personsx.df <-
	read.SAScii (
		NHIS.10.personsx.file.location ,
		NHIS.10.personsx.SAS.read.in.instructions ,
		zipped = T )

#or store the NHIS SAS import instructions for use in a
#read.fwf function call outside of the read.SAScii function
NHIS.10.personsx.sas <-
	parse.SAScii( NHIS.10.personsx.SAS.read.in.instructions )

#save the data frame now for instantaneous loading later
save( NHIS.10.personsx.df , file = "NHIS.10.personsx.data.rda" )

##Load the 2010 National Health Interview Survey Sample Adult file as an R data frame
NHIS.10.samadult.SAS.read.in.instructions <-
	"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Program_Code/NHIS/2010/SAMADULT.sas"
NHIS.10.samadult.file.location <-
	"ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/2010/samadult.zip"

#store the NHIS file as an R data frame!
NHIS.10.samadult.df <-
	read.SAScii (
		NHIS.10.samadult.file.location ,
		NHIS.10.samadult.SAS.read.in.instructions ,
		zipped = T )

#or store the NHIS SAS import instructions for use in a
#read.fwf function call outside of the read.SAScii function
NHIS.10.samadult.sas <-
	parse.SAScii( NHIS.10.samadult.SAS.read.in.instructions )

#save the data frame now for instantaneous loading later
save( NHIS.10.samadult.df , file = "NHIS.10.samadult.data.rda" )