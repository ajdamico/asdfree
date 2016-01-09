

install.packages( c( "SAScii" , "downloader" , "survey" ) )


library(survey)
library(downloader)
library(SAScii)

setwd( "C:/My Directory/PNS/" )



# load the download_cached and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url( 
	"https://raw.githubusercontent.com/ajdamico/asdfree/master/Download%20Cache/download%20cache.R" , 
	prompt = FALSE , 
	echo = FALSE 
)


# initiate a temporary file
tf <- tempfile()

# download the latest pns microdata
download_cached( "ftp://ftp.ibge.gov.br/PNS/2013/microdados/pns_2013_microdados_2015_08_21.zip" , tf , mode = 'wb' )

# extract all files to the local disk
z <- unzip( tf , exdir = tempdir() )

# identify household (domicilio) data file
dd <- grep( "Dados/DOMPNS" , z , value = TRUE )

# identify person data file
pd <- grep( "Dados/PESPNS" , z , value = TRUE )

# identify household (domicilio) sas import script
ds <- grep( "DOMPNS(.*)\\.sas" , z , value = TRUE )

# identify person sas import script
ps <- grep( "PESPNS(.*)\\.sas" , z , value = TRUE )

# create a data.frame object `dom` containing one record per household
dom <- read.SAScii( dd , ds )

# create a data.frame object `pes` containing one record per person
pes <- read.SAScii( pd , ps )

# convert all columns to lowercase
names( dom ) <- tolower( names( dom ) )
names( pes ) <- tolower( names( pes ) )


save( dom , file = "dom.rda" )

save( pes , file = "pes.rda" )

# merge dom and pes
dompes <- merge(dom,pes, by.x=c("v0001","v0024", "upa_pns", "v0006_pns"),
  by.y= c("v0001","v0024", "upa_pns", "v0006_pns") 
)

save( dompes , file = "dompes.rda")

# people with self evaluated health good or very good  
dompes <- transform( dompes , saude_b_mb = as.numeric( n001 %in% c( '1' , '2' ) ) )

# urban / rural
dompes <- transform( dompes , situ = factor( substr( v0024 , 7 , 7 ) , labels = c( 'urbano' , 'rural' ) ) )

# sex
dompes <- transform( dompes , c006 = factor( c006 , labels = c( 'masculino' , 'feminino' ) ) )

# state names
estado_names <- 
	c( "Rondônia" , "Acre" , "Amazonas" , "Roraima" , "Pará" , "Amapá" , "Tocantins" , "Maranhão" , "Piauí" , "Ceará" , "Rio Grande do Norte" , "Paraíba" , "Pernambuco" , "Alagoas" , "Sergipe" , "Bahia" , "Minas Gerais" , "Espírito Santo" , "Rio de Janeiro" , "São Paulo" , "Paraná" , "Santa Catarina" , "Rio Grande do Sul" , "Mato Grosso do Sul" , "Mato Grosso" , "Goiás" , "Distrito Federal" )

dompes <- transform( dompes , uf = factor( v0001 , labels = estado_names ) )

# region
dompes <- transform( dompes , region = factor( substr( v0001 , 1 , 1 ) , labels = c( "Norte" , "Nordeste" , "Sudeste" , "Sul" , "Centro-Oeste" ) ) )


# numeric recodes
dompes[ , c( 'p04101' , 'p04102' , 'p04301' , 'p04302' ) ] <- sapply( dompes[ , c( 'p04101' , 'p04102' , 'p04301' , 'p04302' ) ] , as.numeric )


# worker recodes
dompes <-
	transform(
		dompes ,
		tempo_desl_trab = ifelse( is.na( p04101 ) , 0 , p04101 * 60 + p04102 ) ,
		tempo_desl_athab = ifelse( is.na( p04301 ) , 0 , p04301 * 60 + p04302 ) )

dompes <-
	transform(
		dompes ,
		tempo_desl = tempo_desl_trab + tempo_desl_athab )

dompes <-
	transform(
		dompes ,
		atfi04 = as.numeric( tempo_desl >= 30 ) )
	

# column of all ones
dompes$one <- 1                   



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# design object for people answering the long questionnaire #
pes_sel <- subset( dompes , m001 == "1" )


# pre-stratified design
pes_sel_des <-
	svydesign(
		id = ~ upa_pns ,
		strata = ~ v0024 ,
		data = pes_sel ,
		weights = ~ v0029.y ,
		nest = TRUE
	)

# figure out stratification targets
post_pop <- unique( pes_sel[ c( 'v00293.y' , 'v00292.y' ) ] )

names( post_pop ) <- c( "v00293.y" , "Freq" )

# post-stratified design
pes_sel_des_pos <- postStratify( pes_sel_des , ~v00293.y , post_pop )


save( pes_sel_des_pos , file = "2013 survey design.rda" )

# final design object for people answering the long questionnaire #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #




###################################################################################


############################################################
# compute estimates of table tabela 5.1.1.1 in
# ftp://ftp.ibge.gov.br/PNS/2013/pns2013.pdf
#################################################################

## Brasil
saudbr<-svymean(~saude_b_mb, design=pes_sel_des_pos)
c(round(100*coef(saudbr),1),round(100*confint(saudbr)[1,],1))

#  using 2*se seems to get closer to the confidence interval published by IBGE

round(100*c(coef(saudbr),coef(saudbr)-2*SE(saudbr),
            coef(saudbr)+2*SE(saudbr)),1)


# by sex

saudbrsex<-svyby(~saude_b_mb,~c006, design= pes_sel_des_pos,  vartype="ci",  level = 0.95,  svymean)
cbind(saudbrsex[,1],round(100*saudbrsex[,2:4],1))
## Situation
## by situation (Rural and urban)

saudsitu<-svyby(~saude_b_mb,~situ, design= pes_sel_des_pos,  vartype="ci",  level = 0.95,  svymean)
cbind(saudsitu[,1],round(100*saudsitu[,2:4],1))

## situation x sex

saudsitusex<-svyby(~saude_b_mb,~situ+c006, design= pes_sel_des_pos,  vartype="ci",  level = 0.95,  svymean)
cbind(saudsitusex[,1:2],round(100*saudsitusex[,3:5],1))

## by UF

sauduf<-svyby(~saude_b_mb,~uf, design= pes_sel_des_pos,  vartype="ci",  level = 0.95,  svymean)
cbind(sauduf[,1],round(100*sauduf[,2:4],1))

## UF x SEX 

saudufsex<-svyby(~saude_b_mb,~uf+c006, design= pes_sel_des_pos,  vartype="ci",  level = 0.95,  svymean)
cbind(saudufsex[,1:2],round(100*saudufsex[,3:5],1))

###########################################################################################

### Estimates in Tabela 3.4.1.1 of 
# ftp://ftp.ibge.gov.br/PNS/2013/pns2013.pdf
####################################################


# Compare Estimates against , 
# % of ind. above 18yearsold that practice active travel for > 30minutes
  
# Brasil    
atfibr<-svymean(~atfi04, design=pes_sel_des_pos)
c(round(100*coef(atfibr),1),round(100*confint(atfibr)[1,],1))


# by situation (Urban vs Rural) 
atfisitu<-svyby(~atfi04, ~situ, design= pes_sel_des_pos,  vartype="ci",  level = 0.95,  svymean,na.rm=T)
cbind(atfisitu[,1],round(100*atfisitu[,2:4],1))


#  by Region
atfireg<-svyby(~atfi04, ~region, design= pes_sel_des_pos,  vartype="ci",  level = 0.95,  svymean)
cbind(atfireg[,1],round(100*atfireg[,2:4],1))

#  by Race
atfirace<-svyby(~atfi04, ~c009, design= pes_sel_des_pos,  vartype="ci",  level = 0.95,  svymean)
cbind(atfirace[-6,1],round(100*atfirace[-6,2:4],1))

## by UF

atfiuf<-svyby(~atfi04,~uf, design= pes_sel_des_pos,  vartype="ci",  level = 0.95,  svymean)
cbind(atfiuf[,1],round(100*atfiuf[,2:4],1))

## UF x SEX 

atfiufsex<-svyby(~atfi04,~uf+c006, design= pes_sel_des_pos,  vartype="ci",  level = 0.95,  svymean)
cbind(atfiufsex[,1:2],round(100*atfiufsex[,3:5],1))


###############################################################
## Examples for the whole population
#  match with Figure 8 in http://biblioteca.ibge.gov.br/visualizacao/livros/liv94074.pdf
############################################################

## Create variables

# categorical age 
dompes$c008<-as.numeric(dompes$c008)
dompes$age.cat<-cut(dompes$c008,c(0,18,30,40,60,150),right=FALSE,include.lowest=TRUE)

# race:
dompes$raca<-dompes$c009
dompes$raca[dompes$raca%in%c("3","5","9")]<-NA
dompes$raca<-factor(dompes$raca,labels=c("Branca","Preta","Parda"))
## Educ
dompes$educ<-pes$vdd004
dompes$educ[dompes$educ==" "]<-NA
dompes$educ[dompes$educ%in%c("1","2")]<-"1"
dompes$educ[dompes$educ%in%c("3","4")]<-"2"
dompes$educ[dompes$educ%in%c("5","6")]<-"3"
dompes$educ<-factor(dompes$educ,labels=c("SinstFundi","FundcMedi","MedcSupi","Supc"))

# number of people in the household
dompes$c001<- as.numeric(dompes$c001)

## Questions answered by all people

# design object for all people

pes.all.des<-svydesign(ids=~upa_pns,strata=~v0024,data=dompes,weights=~v0028.y,nest=TRUE)



## post-stratification

post_pop.all<-subset(dompes,select=c(v00283.y,v00282.y))
post_pop.all<-unique(post_pop.all)
names(post_pop.all)<-c("v00283.y","Freq")
pes.all.des.pos<-postStratify(pes.all.des,~v00283.y,post_pop.all)


# Variable vdd004:
## Higher schooling level ( age>=5)
# 1 No instruction
# 2 incomplete elementary or equivalent
# 3 complete elementary or equivalent
# 4 incomplete middle or equivalent
# 5 complete middle or equivalent
# 6 incomplete university or equivalent
# 7 Graduation

svymean(~vdd004,pes.all.des.pos)
## people with health insurance
svymean(~i001,pes.all.des.pos,na.rm=TRUE)

## by sex
plansex<-svyby(~i001,~c006, design=pes.all.des.pos,vartype="ci",  level = 0.95,  svymean,na.rm=TRUE)
plansex.res<-data.frame(Sex=c("Male","Female"),round(100*plansex[,c(2,4,6)],1))

plansex.res
## bar plot
library(ggplot2)
ggplot(plansex.res,aes(x=Sex,y=i0011,fill=Sex))+
  geom_bar( stat="identity", width=0.9) +
  geom_errorbar(aes(ymin=ci_l.i0011, ymax=ci_u.i0011))+
xlab("Sex")+ylab("% Health Insurance")+  ggtitle("Proportion of people having health insurance by sex")+
  theme_bw()  


# by age class
# Estimates
planage<-svyby(~i001,~age.cat, design=pes.all.des.pos,vartype="ci",  level = 0.95,  svymean,na.rm=TRUE)
planage.res<-data.frame(age.cat=planage[,1],round(100*planage[,c(2,4,6)],1))

planage
## bar plot
ggplot(planage.res,aes(x=age.cat,y=i0011,fill=age.cat))+ 
  geom_bar( stat="identity") + 
  geom_errorbar(aes(ymin=ci_l.i0011, ymax=ci_u.i0011))+
xlab("Age")+ylab("% Health Insurance")+  ggtitle("Proportion of people having health insurance by age")+
  theme_bw()


# by education class
planeduc<-svyby(~i001,~educ, design=pes.all.des.pos,vartype="ci",  level = 0.95,  svymean,na.rm=TRUE)
planeduc.res<-data.frame(educ=planeduc[,1],round(100*planeduc[,c(2,4,6)],1))
planeduc.res
## bar plot
ggplot(planeduc.res,aes(x=educ,y=i0011,fill=educ))+
  geom_bar( stat="identity") +
  geom_errorbar(aes(ymin=ci_l.i0011, ymax=ci_u.i0011))+
   xlab("Education")+ylab("% health insurance")+
  ggtitle("Proportion of people having health insurance by education")+
  theme_bw()

# by race
planraca<-svyby(~i001,~raca, design=pes.all.des.pos,vartype="ci",  level = 0.95,  svymean,na.rm=TRUE)
planraca.res<-data.frame(race=planraca[,1],round(100*planraca[,c(2,4,6)],1))
planraca.res
## bar plot
ggplot(planraca.res,aes(x=race,y=i0011,fill=race))+
  geom_bar( stat="identity") +
  geom_errorbar(aes(ymin=ci_l.i0011, ymax=ci_u.i0011))+
  xlab("Education")+ylab("% health insurance")+
  ggtitle("Proportion of people having health insurance by race")+
  theme_bw()

  

#################################################################
## household characteristic estimation
#######################################################
# household design 
dom_des <- subset(pes.all.des.pos,c004=="01" )

# household people density for Brasil
svymean(~ c001,dom_des )

# household people density by region

svyby(~ c001,~region, dom_des,svymean)




