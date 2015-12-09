setwd( "C:/Djalma/PNS/" )

library(SAScii)
tf <- tempfile()
download.file( "ftp://ftp.ibge.gov.br/PNS/2013/microdados/pns_2013_microdados.zip" , tf , mode = 'wb' )
z <- unzip( tf , exdir = tempdir() )

# files
z

dd <- grep( "Dados/DOMPNS" , z , value = TRUE )
pd <- grep( "Dados/PESPNS" , z , value = TRUE )
ds <- grep( "DOMPNS(.*)\\.sas" , z , value = TRUE )
ps <- grep( "PESPNS(.*)\\.sas" , z , value = TRUE )

dom <- read.SAScii( dd , ds )
pes <- read.SAScii( pd , ps )

save(dom,file="dom.rda")
save(pes,file="pes.rda")

###################################################################################

load("pes.rda")

# design object for people answering the long questionaire
pes_sel<-subset(pes,!is.na(M001)&M001=="1")


## people with self evaluated health good or very good  
pes_sel<-transform(pes_sel,saude.b.mb=ifelse(N001%in%c("1","2"),1,0))

## urban and rural
pes_sel<-transform(pes_sel,situ=substring(V0024,7,7))
pes_sel$situ<-factor(pes_sel$situ,labels=c("urbano","rural"))

# sexo

pes_sel$C006<-factor(pes_sel$C006,labels=c("masculino","feminino"))

# UF

estado.names <- c( "Rondônia" , "Acre" , "Amazonas" , "Roraima" , "Pará" , "Amapá" ,
"Tocantins" , "Maranhão" , "Piauí" , "Ceará" , "Rio Grande do Norte" , "Paraíba" ,
"Pernambuco" , "Alagoas" , "Sergipe" , "Bahia" , "Minas Gerais" , "Espírito Santo" ,
"Rio de Janeiro" , "São Paulo" , "Paraná" , "Santa Catarina" , "Rio Grande do Sul" ,
"Mato Grosso do Sul" , "Mato Grosso" , "Goiás" , "Distrito Federal" )
pes_sel$UF<-factor(pes_sel$V0001,labels=estado.names)

# Region
region.names<-c("Norte","Nordeste","Sudeste","Sul","Centro-Oeste")
pes_sel$Region<-substring(pes_sel$V0001,1,1)
pes_sel$Region<-factor(pes_sel$Region,labels=region.names)
table(pes_sel$Region)

##
pes_sel<-transform(pes_sel,tempo_desl_trab=ifelse(is.na(P04101),0,P04101 * 60 + P04102))
pes_sel<-transform(pes_sel,tempo_desl_athab =ifelse(is.na(P04301),0,P04301 * 60 + P04302))
pes_sel<-transform(pes_sel,tempo_desl = tempo_desl_trab + tempo_desl_athab)
pes_sel<-transform(pes_sel,atfi04=ifelse(tempo_desl >= 30,1,0))

# variable 1
pes_sel$one<-1                   

# survey design
library(survey)
pes.sel.des<-svydesign(ids=~UPA_PNS,strata=~V0024,data=pes_sel,weights=~V0029,nest=TRUE)

## post-stratify design

post.pop<-unique(subset(pes_sel,select=c(V00293,V00292)))
names(post.pop)<-c("V00293","Freq")

pes.sel.des.pos<-postStratify(pes.sel.des,~V00293,post.pop)


############################################################
# compute estimates of table tabela 5.1.1.1 in
# ftp://ftp.ibge.gov.br/PNS/2013/pns2013.pdf
#################################################################

## Brasil
saudbr<-svymean(~saude.b.mb, design=pes.sel.des.pos)
c(round(100*coef(saudbr),1),round(100*confint(saudbr)[1,],1))

# by sex

saudbrsex<-svyby(~saude.b.mb,~C006, design= pes.sel.des.pos,  vartype="ci",  level = 0.95,  svymean)
cbind(saudbrsex[,1],round(100*saudbrsex[,2:4],1))
## Situation
## by situation (Rural and urban)

saudsitu<-svyby(~saude.b.mb,~situ, design= pes.sel.des.pos,  vartype="ci",  level = 0.95,  svymean)
cbind(saudsitu[,1],round(100*saudsitu[,2:4],1))

## situation x sex

saudsitusex<-svyby(~saude.b.mb,~situ+C006, design= pes.sel.des.pos,  vartype="ci",  level = 0.95,  svymean)
cbind(saudsitusex[,1:2],round(100*saudsitusex[,3:5],1))

## by UF

sauduf<-svyby(~saude.b.mb,~UF, design= pes.sel.des.pos,  vartype="ci",  level = 0.95,  svymean)
cbind(sauduf[,1],round(100*sauduf[,2:4],1))

## UF x SEX 

saudufsex<-svyby(~saude.b.mb,~UF+C006, design= pes.sel.des.pos,  vartype="ci",  level = 0.95,  svymean)
cbind(saudufsex[,1:2],round(100*saudufsex[,3:5],1))

###########################################################################################

### Estimativas da Tabela 3.4.1.1 em 
# ftp://ftp.ibge.gov.br/PNS/2013/pns2013.pdf
####################################################


# Compare Estimates against , 
# % of ind. above 18yearsold that practice active travel for > 30minutes
  
# Brasil    
atfibr<-svymean(~atfi04, design=pes.sel.des.pos)
svymean(~atfi04, design=pes.sel.des.pos,vartype="ci",   level = 0.95)
c(round(100*coef(atfibr),1),round(100*confint(atfibr)[1,],1))


# by situation (Urban vs Rural) 
atfisitu<-svyby(~atfi04, ~situ, design= pes.sel.des.pos,  vartype="ci",  level = 0.95,  svymean,na.rm=T)
cbind(atfisitu[,1],round(100*atfisitu[,2:4],1))


#  by Region
atfireg<-svyby(~atfi04, ~Region, design= pes.sel.des.pos,  vartype="ci",  level = 0.95,  svymean)
cbind(atfireg[,1],round(100*atfireg[,2:4],1))

#  by Race
atfirace<-svyby(~atfi04, ~C009, design= pes.sel.des.pos,  vartype="ci",  level = 0.95,  svymean)
cbind(atfirace[-6,1],round(100*atfirace[-6,2:4],1))

## by UF

atfiuf<-svyby(~atfi04,~UF, design= pes.sel.des.pos,  vartype="ci",  level = 0.95,  svymean)
cbind(atfiuf[,1],round(100*atfiuf[,2:4],1))

## UF x SEX 

atfiufsex<-svyby(~atfi04,~UF+C006, design= pes.sel.des.pos,  vartype="ci",  level = 0.95,  svymean)
cbind(atfiufsex[,1:2],round(100*atfiufsex[,3:5],1))


###############################################################
## Examples for the whole population
#  match with Gráfico 8 in http://biblioteca.ibge.gov.br/visualizacao/livros/liv94074.pdf
############################################################

## Cria variaveis

# idade categorizada
pes$C008<-as.numeric(pes$C008)
pes$age.cat<-cut(pes$C008,c(0,18,30,40,60,150),right=FALSE,include.lowest=TRUE)

# raça:
pes$raca<-pes$C009
pes$raca[pes$raca%in%c("3","5","9")]<-NA
pes$raca<-factor(pes$raca,labels=c("Branca","Preta","Parda"))
## Educ
pes$educ<-pes$VDD004
pes$educ[pes$educ==" "]<-NA
pes$educ[pes$educ%in%c("1","2")]<-"1"
pes$educ[pes$educ%in%c("3","4")]<-"2"
pes$educ[pes$educ%in%c("5","6")]<-"3"
pes$educ<-factor(pes$educ,labels=c("SinstFundi","FundcMedi","MedcSupi","Supc"))


## Question answered by all people

# design object for all people

pes.all.des<-svydesign(ids=~UPA_PNS,strata=~V0024,data=pes,weights=~V0028,nest=TRUE)


## post-stratification


post.pop.all<-subset(pes,select=c(V00283,V00282))
post.pop.all<-unique(post.pop.all)
names(post.pop.all)<-c("V00283","Freq")
pes.all.des.pos<-postStratify(pes.all.des,~V00283,post.pop.all)


# Variable VDD004:
## Higher schooling level ( age>=5)
# 1 No instruction
# 2 incomplete elementary or equivalent
# 3 complete elementary or equivalent
# 4 incomplete middle or equivalent
# 5 complete middle or equivalent
# 6 incomplete university or equivalent
# 7 Graduation

svymean(~VDD004,pes.all.des.pos)
## people with health insurance
svymean(~I001,pes.all.des.pos,na.rm=TRUE)

## by sex
plansex<-svyby(~I001,~C006, design=pes.all.des.pos,vartype="ci",  level = 0.95,  svymean,na.rm=TRUE)
plansex.res<-data.frame(Sex=c("Male","Female"),round(100*plansex[,c(2,4,6)],1))
## bar plot
library(ggplot2)
ggplot(plansex.res,aes(x=Sex,y=I0011,fill=Sex))+
  geom_bar( stat="identity", width=0.9) +
  geom_errorbar(aes(ymin=ci_l.I0011, ymax=ci_u.I0011))+
xlab("Sex")+ylab("% Health Insurance")+  ggtitle("Proportion of people having health insurance by sex")+
  theme_bw()  


# by age class
# Estimates
planage<-svyby(~I001,~age.cat, design=pes.all.des.pos,vartype="ci",  level = 0.95,  svymean,na.rm=TRUE)
planage.res<-data.frame(age.cat=planage[,1],round(100*planage[,c(2,4,6)],1))
## bar plot
ggplot(planage.res,aes(x=age.cat,y=I0011,fill=age.cat))+ 
  geom_bar( stat="identity") + 
  geom_errorbar(aes(ymin=ci_l.I0011, ymax=ci_u.I0011))+
xlab("Age")+ylab("% Health Insurance")+  ggtitle("Proportion of people having health insurance by age")+
  theme_bw()


# by education class
planeduc<-svyby(~I001,~educ, design=pes.all.des.pos,vartype="ci",  level = 0.95,  svymean,na.rm=TRUE)
planeduc.res<-data.frame(educ=planeduc[,1],round(100*planeduc[,c(2,4,6)],1))
planeduc.res
## bar plot
ggplot(planeduc.res,aes(x=educ,y=I0011,fill=educ))+
  geom_bar( stat="identity") +
  geom_errorbar(aes(ymin=ci_l.I0011, ymax=ci_u.I0011))+
   xlab("Education")+ylab("% health insurance")+
  ggtitle("Proportion of people having health insurance by education")+
  theme_bw()

# by race
planraca<-svyby(~I001,~raca, design=pes.all.des.pos,vartype="ci",  level = 0.95,  svymean,na.rm=TRUE)
planraca.res<-data.frame(race=planraca[,1],round(100*planraca[,c(2,4,6)],1))
planraca.res
## bar plot
ggplot(planraca.res,aes(x=race,y=I0011,fill=race))+
  geom_bar( stat="identity") +
  geom_errorbar(aes(ymin=ci_l.I0011, ymax=ci_u.I0011))+
  xlab("Education")+ylab("% health insurance")+
  ggtitle("Proportion of people having health insurance by race")+
  theme_bw()







