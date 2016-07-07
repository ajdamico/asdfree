## example using pnad2011
library(DBI)
library(MonetDBLite)	# load MonetDBLite package (creates database files in R)
library(downloader)		# downloads and then runs the source() function on scripts from github
library(survey)
library(convey)

# setwd( "C:/My Directory/PNAD/" )
pnad.dbfolder <- paste0( getwd() , "/MonetDB" )
db <- dbConnect( MonetDBLite::MonetDBLite() , pnad.dbfolder )
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

# by region: 1- North; 2- Northeast; 3- Southeast; 4- South and 5 - Midwest

svyby(~v4720, by=~region, design = y.sub, FUN = svyarpt, na.rm=TRUE)

# estimate the proportion below the poverty threshold arpt

svyarpr(~v4720, y.sub , na.rm = TRUE)
svyby(~v4720, by=~region, design = y.sub, FUN = svyarpr, na.rm=TRUE)

# estimate the median of incomes less than the arpt:

svypoormed( ~v4720 , y.sub , na.rm = TRUE )
svyby(~v4720, by=~region, design = y.sub, FUN = svypoormed, na.rm=TRUE)

# estimate the relative median poverty gap
svyrmpg(~v4720 , y.sub , na.rm = TRUE )
svyby(~v4720, by=~region, design = y.sub, FUN = svyrmpg, na.rm=TRUE)

# estimate the quintile share ratio
svyqsr(~v4720 , y.sub , na.rm = TRUE)
svyby(~v4720, by=~region, design = y.sub, FUN = svyqsr, na.rm=TRUE)

# estimate the Gini index
svygini (~ v4720,y.sub, na.rm=TRUE)

# estimate the Gini index by region: see table below Figure 5.1  http://biblioteca.ibge.gov.br/visualizacao/livros/liv66777.pdf

svyby(~v4720, ~region, y.sub, svygini, na.rm=TRUE )


# estimate the relative median income ratio: ratio of medians for people older than 65 and
# younger than 65:

svyrmir( ~v4720 , y.sub, age= ~v8005, agelim = 65 , na.rm=TRUE)

svyby(~v4720, by= ~region, design= y.sub, FUN= svyrmir, na.rm=TRUE, age=~v8005) # check region 2


## For fgt use percapita income by household - v4621
# poverty threshold: 1/2 minimum mensal wage: 545/2 use per-capita



svyfgt(~v4621, y.sub, g=0, type_thresh= "abs", abs_thresh=545/2 , na.rm = TRUE )

svyby(~v4621, by= ~region, design= y.sub, FUN= svyfgt, na.rm=TRUE, g=0,type_thresh= "abs", abs_thresh=545/2)


#

svyrenyi (~v4720 , y.sub, na.rm=TRUE )

svyby(~v4720, by=~region, design= y.sub, FUN = svyrenyi, na.rm=TRUE )


svygei (~v4720 , y.sub, na.rm=TRUE )
svyby(~v4720, by=~region, design= y.sub, FUN = svygei, na.rm=TRUE )



svylorenz( ~v4720 , y.sub, seq(0,1,.05), alpha = .01, na.rm=TRUE )









############################################
# working with data frame
############################################

# cria data frame

pnad2011<- dbGetQuery( db , 'select one, v4618 , v4617 , pre_wgt , v4609 , v4610, v4614, v4719, v4720, v4729, v8005, v0102, v0201, v0401, v0302,v4621, region, uf from pnad2011')


#Transforma os dados:
pnad2011$v4614<- as.numeric(pnad2011$v4614)
pnad2011$v4719<- as.numeric(pnad2011$v4719)
pnad2011$v4720<- as.numeric(pnad2011$v4720)
pnad2011$region<- factor(pnad2011$region, labels=c("NORTE","NORDESTE","SUDESTE","SUL", "CENTRO_OESTE"))
pnad2011$SEXO<- factor(pnad2011$v0302, labels=c("H","M"))
nomes.estados<-c("RO","AC","AM","RR","PA","AP","TO","MA","PI","CE","RN","PB","PE","AL","SE",
  "BA","MG","ES","RJ","SP","PR","SC","RS","MS","MT","GO","DF" )
pnad2011$uf <- factor(pnad2011$uf, labels = nomes.estados)

 save(pnad2011,file="pnad2011.rda")
 load(file="pnad2011.rda")

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




pnad2011_des_pos_sub <- subset( pnad2011_des_pos, is.na(v4720)==FALSE & v4720!=0 &v8005>=15)

pnad2011_des_pos_sub<- convey_prep(pnad2011_des_pos_sub)



# estimate poverty threshold using .6*MED (arpr- Used by Eurostat)

svyarpt(~v4720, pnad2011_des_pos_sub , na.rm = TRUE)

# by region: 1- North; 2- Northeast; 3- Southeast; 4- South and 5 - Midwest

svyby(~v4720, by=~region, design = pnad2011_des_pos_sub, FUN = svyarpt, na.rm=TRUE)

# estimate the proportion below the poverty threshold arpt

svyarpr(~v4720, pnad2011_des_pos_sub , na.rm = TRUE)
svyby(~v4720, by=~region, design = pnad2011_des_pos_sub, FUN = svyarpr, na.rm=TRUE)

# estimate the median of incomes less than the arpt:

svypoormed( ~v4720 , pnad2011_des_pos_sub , na.rm = TRUE )
svyby(~v4720, by=~region, design = pnad2011_des_pos_sub, FUN = svypoormed, na.rm=TRUE)

# estimate the relative median poverty gap
svyrmpg(~v4720 , pnad2011_des_pos_sub , na.rm = TRUE )
svyby(~v4720, by=~region, design = pnad2011_des_pos_sub, FUN = svyrmpg, na.rm=TRUE)

# estimate the quintile share ratio
svyqsr(~v4720 , pnad2011_des_pos_sub , na.rm = TRUE)
svyby(~v4720, by=~region, design = pnad2011_des_pos_sub, FUN = svyqsr, na.rm=TRUE)

# estimate the Gini index
svygini (~ v4720,pnad2011_des_pos_sub, na.rm=TRUE)

# estimate the Gini index by region: see table below Figure 5.1  http://biblioteca.ibge.gov.br/visualizacao/livros/liv66777.pdf

svyby(~v4720, ~region, pnad2011_des_pos_sub, svygini, na.rm=TRUE )


# estimate the relative median income ratio: ratio of medians for people older than 65 and
# younger than 65:

svyrmir( ~v4720 , pnad2011_des_pos_sub, age= ~v8005, agelim = 65 , na.rm=TRUE)

svyby(~v4720, by= ~region, design= pnad2011_des_pos_sub, FUN= svyrmir, na.rm=TRUE, age=~v8005) # check region 2


## For fgt use percapita income by household - v4621
# poverty threshold: 1/2 minimum mensal wage: 545/2 use per-capita



svyfgt(~v4621, pnad2011_des_pos_sub, g=0, type_thresh= "abs", abs_thresh=545/2 , na.rm = TRUE )

svyby(~v4621, by= ~region, design= pnad2011_des_pos_sub, FUN= svyfgt, na.rm=TRUE, g=0,type_thresh= "abs", abs_thresh=545/2)




svyrenyi (~v4720 , pnad2011_des_pos_sub, na.rm=TRUE )

svyby(~v4720, by=~region, design= pnad2011_des_pos_sub, FUN = svyrenyi, na.rm=TRUE )


svygei (~v4720 , pnad2011_des_pos_sub, na.rm=TRUE )
svyby(~v4720, by=~region, design= pnad2011_des_pos_sub, FUN = svygei, na.rm=TRUE )



svylorenz( ~v4720 , pnad2011_des_pos_sub, seq(0,1,.05), alpha = .01, na.rm=TRUE )




