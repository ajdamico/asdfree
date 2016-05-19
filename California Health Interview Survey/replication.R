# carl ganz
# carlganz@ucla.edu



# setwd( "C:/My Directory/CHIS" )


library(survey)

load( "./2011/adult.rda" )

options( survey.replicates.mse = TRUE )

# footnote (a) says they might have used 0.9999:  http://healthpolicy.ucla.edu/chis/analyze/Documents/2012MAY02-CHIS-PUF-Weighting-and-Variance-2Frequency.pdf
chis_svy <- svrepdesign( data = x , weights = ~ rakedw0 , repweights = "rakedw[1-9]" , type = "other" , scale = 1 , rscales = 0.9999  , mse = TRUE )


# compare to 2011 state level estimates in adult health profiles 
# http://healthpolicy.ucla.edu/health-profiles/adults/Documents/2011/Regions/LosAngeles.pdf

# No usual source of care
## CI should equal 16.3-18.1
x <- svymean(~factor(usoc),chis_svy)
x
round(100*confint(x,df=degf(chis_svy)),1)

# Obesity
## CI should equal 24.1-26.0
y <- svymean(~factor(rbmi),chis_svy)
y
round(100*confint(y,df=degf(chis_svy)),1)

# Diabetes
## CI should equal 7.8-8.9
z <- svymean(~factor(ab22),chis_svy)
z
round(100*confint(z,df=degf(chis_svy)),1)
