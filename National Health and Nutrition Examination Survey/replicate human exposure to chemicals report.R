# contributed by..

# PD Dr. Ralph Pirow
# Bundesinstitut für Risikobewertung
# Fachgruppe Toxikologie
# Abteilung Sicherheit von verbrauchernahen Produkten
# -
# Federal Institute for Risk Assessment
# Unit Toxicology
# Department Safety of Consumer Products
# -
# Ralph.Pirow@bfr.bund.de

# **********************************************************************
# Analyse the NHANES 2007-2008 data on urinary Bisphenol A (BPA)
#
# National Health and Nutrition Examination Survey (NHANES)
# Replication of the BPA summary statistics published by the
# Centers for Disease Control and Prevention (CDC)
# using the 2007-2008 demographics and laboratory files
#  
# The CDC has published the BPA summary statistics at:
# http://www.cdc.gov/exposurereport/pdf/FourthReport_UpdatedTables_Sep2012.pdf#page=21
#
# This R script will replicate the results on urinary BPA concentration (µg/l)
# for the survey years 2007-2008
# **********************************************************************

library(foreign)         # required for reading SAS XPORT transport format files
library(survey)          # required for the analysis of complex survey samples


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Setting to produce conservative standard errors instead of crashing
# this setting matches the MISSUNIT option in SUDAAN
# http://faculty.washington.edu/tlumley/survey/exmample-lonely.html
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
options(survey.lonely.psu="adjust")


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# FTP file path to the required 2007-2008 NHANES data sets
#
# Demographic Variables and Sample Weights (DEMO_E)
# Laboratory files: Environmental Phenols (EPH_E)
#
# http://www.cdc.gov/nchs/nhanes/nhanes2007-2008/DEMO_E.htm
# http://www.cdc.gov/nchs/nhanes/nhanes2007-2008/EPH_E.htm
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
ftp.path <- "ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/nhanes/2007-2008"

NHANES07.demo <- file.path(ftp.path, "DEMO_E.xpt")
NHANES07.eph  <- file.path(ftp.path, "EPH_E.xpt")


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# A function for the download and import of data sets
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DownloadImport <- function(ftp.filepath)
{
    tf <- tempfile()    # create a temporary file
    download.file(ftp.filepath, destfile=tf, mode="wb")
    d <- read.xport(tf)
    return(d)
}


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Download the Demographics and Laboratory files
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dD <- DownloadImport(NHANES07.demo) # Demogr. variables & Sample Weights
dL <- DownloadImport(NHANES07.eph)  # Environmental Phenols


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Limit the data set to the relevant variables
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DemoKeepVars  <- c("SEQN",         # Respondent sequence number (merge variable)
                   "SDMVPSU" ,     # primary sampling unit variable
                   "SDMVSTRA",     # strata variable
                   "RIDRETH1",     # person race / ethnicity
                   "RIDAGEYR",     # person age / Age at Screening Adjudicated
                   "RIAGENDR")     # gender

LabKeepVars   <- c("SEQN",         # Respondent sequence number
                   "WTSB2YR",      # Two-year B subsample weights
                   "URXUCR",       # Urinary creatinine
                   "URXBPH",       # Urinary Bisphenol A (ng/mL)
                   "URDBPHLC")     # Urinary Bisphenol A comment (1:<=LOD, 0:>LOD)

dD <- dD[,DemoKeepVars]
dL <- dL[,LabKeepVars]

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Show the first two lines of the data sets
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
head(dD)
head(dL)


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Display the number of rows in the two data sets
#
# The row numbers is not equal, since not all individuals with demographic
# information completed the mobile examination center (MEC) component.
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
nrow(dD)    # 10149 entries
nrow(dL)    #  2718 entries


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Merge the data sets
#
# Merge by respondent sequence number (SEQN). Set "all=F" to keep only
# the matching cases; this is it sufficient to take the weights from
# lab file.
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
d <- merge(dD, dL, by="SEQN", all=F)
nrow(d)     # 2718 entries


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Assign gender levels
# http://www.cdc.gov/nchs/nhanes/nhanes2007-2008/DEMO_E.htm#RIAGENDR
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
d$RIAGENDR <- factor(d$RIAGENDR, levels=1:2, labels=c("male","female"))
head(d)


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Assign age levels
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
agelev   <- c("6-11 years","12-19 years","20 years and older")
age      <- d$RIDAGEYR             # Age at Screening Adjudicated

d$agecat <- ifelse(age>= 6 & age<=11, agelev[1],
            ifelse(age>=12 & age<=19, agelev[2], agelev[3]))
d$agecat <- factor(d$agecat, levels=agelev)


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Assign race/ethnicity levels
# http://www.cdc.gov/nchs/nhanes/nhanes2007-2008/DEMO_E.htm#RIDRETH1
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
relev      <- c("Mexican Americans","Non-Hispanic blacks","Non-Hispanic whites","Other")
x          <- d$RIDRETH1

d$RIDRETH1 <- ifelse(x==1, relev[1],
              ifelse(x==4, relev[2],
              ifelse(x==3, relev[3], relev[4])))
d$RIDRETH1 <- factor(d$RIDRETH1, levels=relev)


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# New variable to quickly total weighted counts
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
d$one <- 1


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Use the short-named variable 'y' for urinary Bisphenol A (ng/mL)
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
d$Y   <- d$URXBPH
d$lgY <- log10(d$URXBPH)


# ######################################################################
# Analysis
# ######################################################################

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Survey design for taylor-series linearization
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
des <- svydesign(id=~SDMVPSU, strata=~SDMVSTRA, nest=T, weights=~WTSB2YR, data=d)


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Total (unweighted) number of records
# http://www.cdc.gov/nchs/nhanes/nhanes2007-2008/EPH_E.htm#URXBPH
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
nrow(des)              # Total:  2718



# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Total (unweighted) number of records broken out by URDBPHLC (i.e. <LOD)
#
# "unwtd.count" is passed to svyby to report the number of non-missing
# observations in each subset. Observations with exactly zero weight
# will also be counted as missing.
# http://www.cdc.gov/nchs/nhanes/nhanes2007-2008/EPH_E.htm#URDBPHLC
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
unwtd.count( ~URDBPHLC , des )							# 2604
svyby(~Y, by=~URDBPHLC, design=des, FUN=unwtd.count) 	# 2438, 166


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Number of records broken out by gender, age class, and race/ethnicity
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
svyby(~Y, by=~RIAGENDR, design=des, FUN=unwtd.count)
svyby(~Y, by=~agecat  , design=des, FUN=unwtd.count)
svyby(~Y, by=~RIDRETH1, design=des, FUN=unwtd.count)


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Weighted number of individuals
# i.e. the civilian, non-institutionalized population of the USA
#
# This is exactly equivalent to summing up the weight variable
# from the original NHANES data frame
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
svytotal(~one, des)
sum(d$WTSB2YR)


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# The civilian, non-institutionalized population of the USA
# by gender category
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
svyby(~one, by=~RIAGENDR, design=des, FUN=svytotal)


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Geometric mean urinary Bisphenol A (BPA) - Total population
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
r1 <- svymean(~lgY, design=des, na.rm=T)
(d1 <- data.frame(GM=round(10^r1[[1]],2)))


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Geometric mean urinary Bisphenol A (BPA) - by gender, age class,
# and race/ethnicity
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
r2 <- svyby(~lgY, by=~RIAGENDR, design=des, FUN=svymean, na.rm=T)
r3 <- svyby(~lgY, by=~agecat  , design=des, FUN=svymean, na.rm=T)
r4 <- svyby(~lgY, by=~RIDRETH1, design=des, FUN=svymean, na.rm=T)
(d2 <- data.frame(demo.cat=r2[,1], GM=round(10^r2[,2],2)))
(d3 <- data.frame(demo.cat=r3[,1], GM=round(10^r3[,2],2)))
(d4 <- data.frame(demo.cat=r4[,1], GM=round(10^r4[,2],2)))


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# 95% confidence intervals for the geometric means
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
cbind(d1, round(10^confint(r1,df=degf(des)), 2))
cbind(d2, round(10^confint(r2,df=degf(des)), 2))
cbind(d3, round(10^confint(r3,df=degf(des)), 2))
cbind(d4, round(10^confint(r4,df=degf(des)), 2))


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# 50th 75th 90th 95th percentiles (with 95% CI) for total BPA (ng/ml)
#
# The parameters method, f and interval.type were chosen to match
# the published CDC results
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
p  <- c(0.5,0.75,0.90,0.95)
r5 <- svyquantile(~Y, design=des, quantiles=p, ci=T, na.rm=T,
                  method="constant", f=1, interval.type="betaWald")
cbind(t(r5$quantiles), t(data.frame(r5$CIs)))


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Percentiles with CIs - by gender, age class, and race/ethnicity
# The CIs are slightly different from the published CDC values
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
p  <- c(0.5, 0.95)
svyby( formula = ~Y, by = ~RIAGENDR, des, FUN = svyquantile, quantiles=p, na.rm=T, ci=T, vartype="ci", method="constant", f=1, interval.type="betaWald",ties='discrete')
svyby( formula = ~Y, by = ~agecat  , des, FUN = svyquantile, quantiles=p, na.rm=T, ci=T, vartype="ci", method="constant", f=1, interval.type="betaWald",ties='discrete')
svyby( formula = ~Y, by = ~RIDRETH1, des, FUN = svyquantile, quantiles=p, na.rm=T, ci=T, vartype="ci", method="constant", f=1, interval.type="betaWald",ties='discrete')
