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

# Example 1

library(survey)
# design object for people answering the long questionaire
pes_sel<-subset(pes,!is.na(M001)&M001=="1")

## registers with missing weights
pes.peso0<-subset(pes_sel,is.na(V0029))

# discard regiters with missing weights
pes_sel0<-subset(pes_sel,!is.na(V0029))

## people with self evalueted health good or very good  
pes_sel0<-transform(pes_sel0,saude.b.mb=ifelse(N001%in%c("1","2"),1,0))

## urban and rural
pes_sel0<-transform(pes_sel0,situ=substring(V0024,7,7))
pes_sel0$situ<-factor(pes_sel0$situ,labels=c("Urbano","Rural"))

# sex
pes_sel0$C006<-factor(pes_sel0$C006,labels=c("Masculino","Feminino"))

# States

estado.names <- c( "Rondônia" , "Acre" , "Amazonas" , "Roraima" , "Pará" , "Amapá" ,
"Tocantins" , "Maranhão" , "Piauí" , "Ceará" , "Rio Grande do Norte" , "Paraíba" ,
"Pernambuco" , "Alagoas" , "Sergipe" , "Bahia" , "Minas Gerais" , "Espírito Santo" ,
"Rio de Janeiro" , "São Paulo" , "Paraná" , "Santa Catarina" , "Rio Grande do Sul" ,
"Mato Grosso do Sul" , "Mato Grosso" , "Goiás" , "Distrito Federal" )
pes_sel0$V0001<-factor(pes_sel0$V0001,labels=estado.names)

## this is a separate sample just for a group of people not a domain
# survey design
library(survey)
pes.sel.des<-svydesign(ids=~UPA_PNS,strata=~V0024,data=pes_sel0,weights=~V0029,nest=TRUE)

## design post-stratification

post.pop<-unique(subset(pes_sel0,select=c(V00293,V00292)))
names(post.pop)<-c("V00293","Freq")

pes.sel.des.pos<-postStratify(pes.sel.des,~V00293,post.pop)


####################Example 1#############################################
## Brasil
tab5.1.1.1.BR<-svymean(~saude.b.mb,pes.sel.des.pos)

round(100*c(coef(tab5.1.1.1.BR),coef(tab5.1.1.1.BR)-2*SE(tab5.1.1.1.BR),
            coef(tab5.1.1.1.BR)+2*SE(tab5.1.1.1.BR)),1)

# create a funtion to organize the results of the svyby function

tab5111<-function(svyby.obj,nomevar){
  LI<-coef(svyby.obj)-2*SE(svyby.obj)
  LS<-coef(svyby.obj)+2*SE(svyby.obj)
  result<-data.frame(svyby.obj[,1:length(nomevar)],saude.b.mb=round(100*coef(svyby.obj),1),
                     LI=round(100*LI,1),LS=round(100*LS,1))
  names(result)[1:length(nomevar)]<-nomevar
  rownames(result)<-NULL
  result
}

# sex
tab5.1.1.1_BR_SEXO<-svyby(~saude.b.mb,~C006,pes.sel.des.pos,svymean)
tab5111(tab5.1.1.1_BR_SEXO,"sexo")

# situation (urban, rural)
tab5.1.1.1_SITU<-svyby(~saude.b.mb,~situ,pes.sel.des.pos,svymean)
tab5111(tab5.1.1.1_SITU,"situação")

# situação e sexo
tab5.1.1.1_SITU_SEXO<-svyby(~saude.b.mb,~situ+C006,pes.sel.des.pos,svymean)
tab5111(tab5.1.1.1_SITU_SEXO,c("situação","sexo"))

# UF
tab5.1.1.1_UF<-svyby(~saude.b.mb,~V0001,pes.sel.des.pos,svymean)
tab5111(tab5.1.1.1_UF,"UF")

# UF X sexo
tab5.1.1.1_UF_SEXO<-svyby(~saude.b.mb,~V0001+C006,pes.sel.des.pos,svymean)
tab5111(tab5.1.1.1_UF_SEXO,c("UF","sexo"))
###########################End of Example 1 ########################################################3


## Example 2:
## Question answered by all people

# design object for all people

pes.all.des<-svydesign(ids=~UPA_PNS,strata=~V0024,data=pes,weights=~V0028,nest=TRUE)

## post-stratification


post.pop.all<-subset(pes,select=c(V00283,V00282))
post.pop.all<-unique(post.pop.all)
names(post.pop.all)<-c("V00283","Freq")
pes.all.des.pos<-postStratify(pes.sel.des,~V00283,post.pop.all)

## Higher schooling level ( age>=5)
svymean(~VDD004,pes.all.des.pos)

x<-subset(pes.all.des.pos,C008>=5)
svymean(~VDD004,x) 
## this result was not published yet.

