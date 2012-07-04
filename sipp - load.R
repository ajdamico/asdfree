#just run this line once to install the SAScii package
install.packages("SAScii")

#run this line every time to load the SAScii package
library(SAScii)


#########################################################################################
#Load the 2008 Survey of Income and Program Participation Wave 1 as an R data frame

SIPP.08w1.SAS.read.in.instructions <-
	"ftp://www.sipp.census.gov/pub/sipp/2008/l08puw1.sas"

SIPP.08w1.file.location <-
	"ftp://www.sipp.census.gov/pub/sipp/2008/l08puw1.zip"

#store the SIPP file as an R data frame
#note the text "INPUT" appears before the actual INPUT block of the SAS code
#so the parsing of the SAS instructions will fail without a beginline parameter specifying
#where the appropriate INPUT block occurs
SIPP.08w1.df <-
	read.SAScii (
		SIPP.08w1.file.location ,
		SIPP.08w1.SAS.read.in.instructions ,
		beginline = 5 ,
		buffersize = 10 ,
		zipped = T 
		)
		
		
#Load the Replicate Weights file of the
#2008 Survey of Income and Program Participation Wave 1 as an R data frame

SIPP.repwgt.08w1.SAS.read.in.instructions <-
	"ftp://www.sipp.census.gov/pub/sipp/2008/rw08wx.sas"

SIPP.repwgt.08w1.file.location <-
	"ftp://www.sipp.census.gov/pub/sipp/2008/rw08w1.zip"

#store the SIPP file as an R data frame
#note the text "INPUT" appears before the actual INPUT block of the SAS code
#so the parsing of the SAS instructions will fail without a beginline parameter specifying
#where the appropriate INPUT block occurs
SIPP.repwgt.08w1.df <-
	read.SAScii (
		SIPP.repwgt.08w1.file.location ,
		SIPP.repwgt.08w1.SAS.read.in.instructions ,
		beginline = 5 ,
		zipped = T 
		)

