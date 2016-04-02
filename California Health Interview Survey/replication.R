

# carl ganz
# carlganz@ucla.edu

### download CHIS 2011 ADULT PUF file
library(foreign)
library(survey)
# load data
chis <- read.dta(".../ADULT.dta")
# create svy object
chis.svy <- svrepdesign(chis[,-(322:402)], #input variables
                        weights=chis$rakedw0, #input main weight
                        repweights=chis[,323:402], #input replicate weights
                        type='other',scale=1,rscales=1,
                        combined.weights=TRUE,MSE=TRUE)

# compare to 2011 state level estimates in adult health profiles 
# http://healthpolicy.ucla.edu/health-profiles/adults/Documents/2011/Regions/LosAngeles.pdf

# No usual source of care
## CI should equal 16.3-18.1
x <- svymean(~usoc,chis.svy)
x
round(100*confint(x),1)

# Obesity
## CI should equal 24.1-26.0
y <- svymean(~rbmi,chis.svy)
y
round(100*confint(y),1)

# Diabetes
## CI should equal 7.8-8.9
z <- svymean(~ab22,chis.svy)
z
round(100*confint(z),1)
