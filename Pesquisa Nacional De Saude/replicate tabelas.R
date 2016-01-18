# analyze survey data for free (http://asdfree.com) with the r language
# pesquisa nacional de saude

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/PNS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Pesquisa%20Nacional%20De%20Saude/replicate%20tabelas.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# djalma pessoa
# pessoad@gmail.com

# anthony joseph damico
# ajdamico@gmail.com


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#########################################################################################################################
# prior to running this analysis script, the pns 2013 file must be loaded on the local machine with this script:        #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/Pesquisa%20Nacional%20De%20Saude/download%20and%20import.R  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "2013 long questionnaire survey design.rda" in the working directory                   #
#########################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PNS/" )
# ..in order to set your current working directory


load( "2013 long questionnaire survey design.rda" )


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# compute estimates of table tabela 5.1.1.1 in ftp://ftp.ibge.gov.br/PNS/2013/pns2013.pdf #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

three_stats <- function( z ) print( round( 100 * c( coef( z ) , coef( z ) - 2 * SE( z ) , coef( z ) + 2 * SE( z ) ) , 1 ) )


# nationwide
saudbr <- svymean( ~ saude_b_mb , design = pes_sel_des_pos )

three_stats( saudbr )


# by sex
saudbrsex <- svyby( ~ saude_b_mb , ~ c006 , design = pes_sel_des_pos , svymean )

three_stats( saudbrsex )


# by situation (rural and urban)
saudsitu <- svyby( ~saude_b_mb , ~situ , design = pes_sel_des_pos , svymean )

three_stats( saudsitu )


# situation x sex
saudsitusex <- svyby( ~ saude_b_mb , ~ situ + c006 , design = pes_sel_des_pos , svymean )

three_stats( saudsitusex )


# by UF
sauduf <- svyby( ~ saude_b_mb , ~ uf , design = pes_sel_des_pos , svymean )

three_stats( sauduf )


# UF x sex 
saudufsex <- svyby( ~ saude_b_mb , ~ uf + c006 , design = pes_sel_des_pos , svymean )

three_stats( saudufsex )



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
planage<-svyby(~i001,~age_cat, design=pes.all.des.pos,vartype="ci",  level = 0.95,  svymean,na.rm=TRUE)
planage.res<-data.frame(age_cat=planage[,1],round(100*planage[,c(2,4,6)],1))

planage
## bar plot
ggplot(planage.res,aes(x=age_cat,y=i0011,fill=age_cat))+ 
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




