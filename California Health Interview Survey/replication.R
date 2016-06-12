# carl ganz
# carlganz@ucla.edu



# setwd( "C:/My Directory/CHIS" )


library(survey)

load( "./2011/adult.rda" )

options( survey.replicates.mse = TRUE )

# http://healthpolicy.ucla.edu/chis/analyze/Documents/2012MAY02-CHIS-PUF-Weighting-and-Variance-2Frequency.pdf
# consistent with Complex Surveys: a Guide to Analysis in R by Thomas Lumley Chapter #2
chis_svy <- svrepdesign( data = x , weights = ~ rakedw0 , repweights = "rakedw[1-9]" , type = "other" , scale = 1 , rscales = 1  , mse = TRUE )


# compare to 2014 state level estimates for Adults from the AskCHIS web query system

# Health Status
hs <- svymean(~factor(ab1),chis_svy)
round(100*hs,1)
round(100*confint(hs,df=degf(chis_svy)),1)

### AskCHIS output:
browseURL("http://i.imgur.com/TAQrygz.png")
