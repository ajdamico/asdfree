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

dom01<-subset(dom,V0015=="01")

# design objec for people answering the long questionaire
pes_sel<-subset(pes,!is.na(M001)&M001=="1")

## registers with missing weights
pes.peso0<-subset(pes_sel,is.na(V0029))

# discard regiters with missing weights
pes_sel0<-subset(pes_sel,!is.na(V0029))

## people with self evalueted health good or very good  
pes_sel0<-transform(pes_sel0,saude.b.mb=ifelse(N001%in%c("1","2"),1,0))

## urban and rural
pes_sel0<-transform(pes_sel0,situ=substring(V0024,7,7))

# survey design
library(survey)
pes.sel.des<-svydesign(ids=~UPA_PNS,strata=~V0024,data=pes_sel0,weights=~V0029,nest=TRUE)

## pós-estratificação do desenho

post.pop<-unique(subset(pes_sel0,select=c(V00293,V00292)))
names(post.pop)<-c("V00293","Freq")

pes.sel.des.pos<-postStratify(pes.sel.des,~V00293,post.pop)



# calcula estimativas da tabela 5.1.1.1

## Brasil
tab5.1.1.1.BR<-svymean(~saude.b.mb,pes.sel.des.pos)
class(tab5.1.1.1.BR)
round(100*c(coef(tab5.1.1.1.BR),coef(tab5.1.1.1.BR)-2*SE(tab5.1.1.1.BR),
            coef(tab5.1.1.1.BR)+2*SE(tab5.1.1.1.BR)),1)
## Brasil por sexo
tab5.1.1.1_BR_SEXO<-svyby(~saude.b.mb,~C006,pes.sel.des.pos,svymean)
tab5.1.1.1_BR_SEXO<-transform(tab5.1.1.1_BR_SEXO,LI=saude.b.mb-2*se,LS=saude.b.mb+2*se)
## masculino
cbind(tab5.1.1.1_BR_SEXO[1,1],round(100*tab5.1.1.1_BR_SEXO[1,c(2,4,5)],1))
## feminino
cbind(tab5.1.1.1_BR_SEXO[2,1],round(100*tab5.1.1.1_BR_SEXO[2,c(2,4,5)],1))
## Situação

## Rural e urbana

tab5.1.1.1_SITU<-svyby(~saude.b.mb,~situ,pes.sel.des.pos,svymean)
tab5.1.1.1_SITU<-transform(tab5.1.1.1_SITU,LI=saude.b.mb-2*se,LS=saude.b.mb+2*se)
cbind(tab5.1.1.1_SITU[,1],round(100*tab5.1.1.1_SITU[,c(2,4,5)],1))

## Rural e urbana por sexo
tab5.1.1.1_SITU_SEXO<-svyby(~saude.b.mb,~situ+C006,pes.sel.des.pos,svymean)
tab5.1.1.1_SITU_SEXO<-transform(tab5.1.1.1_SITU_SEXO,LI=saude.b.mb-2*se,LS=saude.b.mb+2*se)
tab5.1.1.1_SITU_MASC<-subset(tab5.1.1.1_SITU_SEXO,C006==1)
tab5.1.1.1_SITU_FEM<-subset(tab5.1.1.1_SITU_SEXO,C006==2)
## SITU, sexo masculino
cbind(tab5.1.1.1_SITU_MASC[,1],round(100*tab5.1.1.1_SITU_MASC[,c(3,5,6)],1))
## SITU, sexo feminino
cbind(tab5.1.1.1_SITU_FEM[,1],round(100*tab5.1.1.1_SITU_FEM[,c(3,5,6)],1))

## UF

tab5.1.1.1_UF<-svyby(~saude.b.mb,~V0001,pes.sel.des.pos,svymean)

tab5.1.1.1_UF<-transform(tab5.1.1.1_UF,LI=saude.b.mb-2*se,LS=saude.b.mb+2*se)
cbind(tab5.1.1.1_UF$V0001,round(100*result[,c(2,4,5)],1))

## UF x SEXO 

tab5.1.1.1_UF_SEXO<-svyby(~saude.b.mb,~V0001+C006,pes.sel.des.pos,svymean)

tab5.1.1.1_UF_SEXO<-transform(tab5.1.1.1_UF_SEXO,LI=saude.b.mb-2*se,LS=saude.b.mb+2*se)
## UF, Sexo masculino
tab5.1.1.1_UF_MASC<-subset(tab5.1.1.1_UF_SEXO,C006==1)
cbind(tab5.1.1.1_UF_MASC[,1],round(100*tab5.1.1.1_UF_MASC[,c(3,5,6)],1))

##UF,  Sexo feminino
tab5.1.1.1_UF_FEM<-subset(tab5.1.1.1_UF_SEXO,C006==2)
cbind(tab5.1.1.1_UF_FEM[,1],round(100*tab5.1.1.1_UF_FEM[,c(3,5,6)],1))





