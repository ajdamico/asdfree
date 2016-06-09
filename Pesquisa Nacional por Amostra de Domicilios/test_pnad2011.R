# example using pnad2011
library(MonetDBLite)	# load MonetDBLite package (creates database files in R)
library(downloader)		# downloads and then runs the source() function on scripts from github
library(survey)
library(convey)

# setwd( "C:/My Directory/PNAD/" )
pnad.dbfolder <- paste0( getwd() , "/MonetDB" )
db <- dbConnect( MonetDBLite() , pnad.dbfolder )
dbListTables(db)

options(survey.lonely.psu = "adjust")

source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Pesquisa%20Nacional%20por%20Amostra%20de%20Domicilios/pnad.survey.R" , prompt = FALSE )

sample.pnad <-
  svydesign(
    id = ~v4618 ,
    strata = ~v4617 ,
    data = 'pnad2011' ,
    weights = ~pre_wgt ,
    nest = TRUE ,
    dbtype = "MonetDBLite" ,
    dbname = pnad.dbfolder
  )

y <- 
  pnad.postStratify( 
    design = sample.pnad ,
    strata.col = 'v4609' ,
    oldwgt = 'pre_wgt'
  )

y.sub <- subset (y,  !is.na(v4720) & v4720!=0 & v8005>=15)

y.sub <- convey_prep(y.sub)

## using functions of library convey

# estimate poverty threshold using .6*MED (arpr- Used by Eurostat)

svyarpt(~v4720, y.sub , na.rm = TRUE)

# estimate the proportion below the poverty threshold arpt

svyarpr(~v4720, y.sub , na.rm = TRUE)

# estimate the median of incomes less than the arpt:

svypoormed( ~v4720 , y.sub , na.rm = TRUE ) ## not working

# estimate the relative median poverty gap

svyrmpg(~v4720 , y.sub , na.rm = TRUE ) # not working

# estimate the quintile share ratio

svyqsr(~v4720 , y.sub , na.rm = TRUE)

# estimate the Gini index

svygini (~ v4720,y.sub, na.rm=TRUE)

# estimate the Gini index by region: see table below Figure 5.1  http://biblioteca.ibge.gov.br/visualizacao/livros/liv66777.pdf

svyby(~v4720, ~region, y.sub, svygini, na.rm=TRUE )


# estimate the relative median income ratio: ratio of medians for people older than 65 and
# younger than 65:

svyrmir( ~v4720 , y.sub, age= ~v8005, agelim = 65 , na.rm=TRUE)

# poverty threshold: 1/2 minimum mensal wage: 545/2

svyfgt(~v4720, y.sub, g=0, type_thresh= "abs", abs_thresh=545/2 , na.rm = TRUE )

svyfgt(~eqIncome, des_eusilc, g=0, type_thresh= "abs", abs_thresh=10000)




## compute percentile ratio

ratio_quant <- function(formula, design, alpha1, alpha2){

  q1 <-  svyiqalpha( formula , design = design, alpha1 ,na.rm =TRUE ) 
  q2 <-  svyiqalpha( formula , design = design, alpha2, na.rm =TRUE )
  q1_list <- list(value = coef(q1), lin = attr(q1, "lin"))
  q2_list <- list(value = coef(q2), lin = attr(q2, "lin"))
  list_all <- list(Q1= q1_list, Q2 = q2_list )
  Rquant<- contrastinf(quote(Q1/Q2), list_all)
  variance <- svyrecvar(Rquant$lin/design $prob, design$cluster, design$strata, 
    design$fpc, postStrata = design$postStrata)
  c(value= Rquant$value, se= sqrt(variance))
  
}

# percentile ratios:


prob_frame <- data.frame ( qnum = c(50, 75, 90, 95, 75, 90, 95, 90, 95, 95)/100,
  qden= c( 25, 25, 25, 25, 50, 50, 50,  75, 75, 90)/100)

percentile_ratio <- rep (NA,nrow(prob_frame) )

 
for(i in 1:nrow(prob_frame) ) percentile_ratio[i] <- ratio_quant (~ v4720, y.sub, 
  prob_frame$qnum[i], prob_frame$qden[i] )[1]


prob_frame$perc_raio <- round(percentile_ratio,1)

prob_frame

############################################
# working with data frame
############################################

# cria data frame

pnad2011<- dbGetQuery( db , 'select one, v4618 , v4617 , pre_wgt , v4609 , v4610, v4614, v4719, v4720, v4729, v8005, v0102, v0201, v0401, v0302, uf from pnad2011')


#Transforma os dados:
pnad2011$v4614<- as.numeric(pnad2011$v4614)
pnad2011$v4719<- as.numeric(pnad2011$v4719)
pnad2011$v4720<- as.numeric(pnad2011$v4720)
pnad2011$REG<- substring(pnad2011$v0102,1,1)
pnad2011$REG<- factor(pnad2011$REG, labels=c("NORTE","NORDESTE","SUDESTE","SUL", "CENTRO_OESTE"))
pnad2011$SEXO<- factor(pnad2011$v0302, labels=c("H","M"))
nomes.estados<-c("RO","AC","AM","RR","PA","AP","TO","MA","PI","CE","RN","PB","PE","AL","SE",
  "BA","MG","ES","RJ","SP","PR","SC","RS","MS","MT","GO","DF" )
pnad2011$uf <- factor(pnad2011$uf, labels = nomes.estados)

# save(pnad2011,file="pnad2011.rda")
# load(file="pnad2011.rda")

options( survey.lonely.psu = "adjust" )
pnad2011_des <- svydesign(
  id = ~v4618 ,
  strata = ~v4617 ,
  data = pnad2011 ,
  weights = ~pre_wgt ,
  nest = TRUE
)

# pos-stratify
pop.post<- data.frame(v4609= unique(pnad2011$v4609), 
  Freq= unique(as.numeric(pnad2011$v4609)))
pnad2011_des_pos <- postStratify(pnad2011_des, ~v4609, pop.post)
# pnad2011_des_pos<- convey_prep(pnad2011_des_pos)

#   pnad2011_des_pos_sub <- subset(pnad2011_des_pos,v4720!=0 & is.na(v4720)==FALSE & v8005>=15)

pnad2011_des_pos_sub <- subset( pnad2011_des_pos, is.na(v4720)==FALSE & v4720!=0 &  v8005>=15)

pnad2011_des_pos_sub<- convey_prep(pnad2011_des_pos_sub)



# variável de renda: v4720
svymean(~v4720,pnad2011_des_pos_sub, na.rm=TRUE)
svygini (~v4720,pnad2011_des_pos_sub, na.rm=TRUE)
svyiqalpha(~v4720, pnad2011_des_pos_sub, alpha= .5, na.rm=TRUE )
svyarpt(~v4720, pnad2011_des_pos_sub,na.rm=TRUE)
svyarpr(~v4720, pnad2011_des_pos_sub,na.rm=TRUE)
