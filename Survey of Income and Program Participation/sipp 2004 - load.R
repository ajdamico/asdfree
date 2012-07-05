#just run this line once to install the SAScii package
install.packages("SAScii")

#run this line every time to load the SAScii package
library(SAScii)


#########################################################################################
#Load all twelve waves of the 2004 Survey of Income and Program Participation as R data frames

SIPP.04w1.SAS.read.in.instructions <-
	"http://smpbff2.dsd.census.gov/pub/sipp/2004/l04puw1.sas"

#note the text "INPUT" appears before the actual INPUT block of the SAS code
#so the parsing of the SAS instructions will fail without a beginline parameter specifying
#where the appropriate INPUT block occurs
#loop through all 12 waves of SIPP 2004
for ( i in 1:12 ){
	SIPP.04wX.file.location <-
		paste( "http://smpbff2.dsd.census.gov/pub/sipp/2004/l04puw" , i , ".zip" , sep = "" )

	#name the data frame based on the current wave
	df.name <- paste( "SIPP.04w" , i , ".df" , sep = "" )

	#store the SIPP file as an R data frame!
	assign(
		df.name ,
		read.SAScii (
			SIPP.04wX.file.location ,
			SIPP.04w1.SAS.read.in.instructions ,
			beginline = 5 ,
			buffersize = 5 ,
			zipped = T 
		)
	)
}
