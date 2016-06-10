library(MonetDBLite)
library(DBI)			# load the DBI package (implements the R-database coding)
library (dplyr)

## directory containing the monetdb data base
setwd ("C:/My Directory/ENEM/")

dbfolder <- paste0( getwd() , "/MonetDB" )

db <- dbConnect( MonetDBLite::MonetDBLite() , dbfolder )


## number of enrolled

dbGetQuery( db , "select count(*) from microdados_enem_2014" )

# took the math test

dbGetQuery( db , "select count(*) as took_math from microdados_enem_2014 where in_presenca_mt=1" )

## mean math score by UF

math_mean_uf <-dbGetQuery( db , "select uf_residencia , sum(nota_mt)/count(*) as med_mat from microdados_enem_2014 where in_presenca_mt=1 group by uf_residencia order by med_mat" )

# mean math score by UF barplot

barplot(math_mean_uf$med_mat, names.arg=math_mean_uf$uf_residencia, ylim=c(0,500), main= "math mean")

# range
max(math_mean_uf$med_mat)-min(math_mean_uf$med_mat)

## mean score in language

lang_mean_uf <- dbGetQuery( db , "select uf_residencia , sum(nota_lc)/count(*) as med_lc from microdados_enem_2014 where in_presenca_lc=1 group by uf_residencia order by med_lc" )
barplot(lang_mean_uf$med_lc, names.arg=lang_mean_uf$uf_residencia, ylim=c(0,500), main= "lang mean")
# range 
max(lang_mean_uf$med_lc)-min(lang_mean_uf$med_lc)

# math mean score by gender
math_mean_sex <- dbGetQuery( db , "select tp_sexo , sum(nota_mt)/count(*) as med_mat from microdados_enem_2014 where in_presenca_mt=1 group by tp_sexo" )
#range:
max(math_mean_sex$med_mat)-min(math_mean_sex$med_mat)


# mean language score by gender
lang_mean_sex <-dbGetQuery( db , "select tp_sexo , sum(nota_lc)/count(*) as med_lc FROM microdados_enem_2014 where in_presenca_lc=1 group by tp_sexo" )
# range

max(lang_mean_sex$med_lc)-min(lang_mean_sex$med_lc)



## math mean score by father's education level
# 1- nao estudou
# 2 - 1 a 4 serie
# 3 - 5 a 8 serie
# 4 - ensino medio incompleto
# 5 - ensino medio 
# 6 - ensino superior incompleto
# 7 - ensino superior 
# 8 - pos- graduacao
# 9 - nao sabe 

math_mean_father_educ <- dbGetQuery( db , "select q001 , sum(nota_mt)/count(*) as med_mat from microdados_enem_2014 where in_presenca_mt=1 group by q001" )
# range

max(math_mean_father_educ$med_mat)-min(math_mean_father_educ$med_mat)



##  math mean score by mother's education level

math_mean_mother_educ <- dbGetQuery( db , "select q002 , sum(nota_mt)/count(*) as med_mat FROM microdados_enem_2014 where in_presenca_mt=1 group by q002" )

#range 

max(math_mean_mother_educ$med_mat)-min(math_mean_mother_educ$med_mat)



# math mean by type of school
# 1 - public
# 2 - private

math_mean_type <- dbGetQuery( db , "select tp_escola , sum(nota_mt)/count(*) as med_mat FROM microdados_enem_2014 where in_presenca_mt=1 group by tp_escola" )

# range

max(math_mean_type $med_mat)-min(math_mean_type$med_mat)

## family income

math_mean_fam_inc <- dbGetQuery( db , "select q003 , sum(nota_mt)/count(*) as med_mat FROM microdados_enem_2014 where in_presenca_mt=1 group by q003" )

# range

max(math_mean_fam_inc$med_mat)-min(math_mean_fam_inc$med_mat)

##############################################################################
# using library dplyr

library (dplyr)


con <- dbConnect(MonetDB.R(), embedded = dbfolder)
ms <- src_monetdb(embedded = dbfolder)
mt <- tbl(ms, "microdados_enem_2014")

## number of students
dim(mt)[1]

# number of students that took the math test

mt %>% filter(in_presenca_mt==1) %>% summarise(n())

## mean math score by UF

math_mean_uf<- mt %>% filter(in_presenca_mt==1) %>% group_by(uf_residencia) %>% summarise(nstud = n(), math_mean= mean(nota_mt), min = min(nota_mt), max = max(nota_mt), range= max(nota_mt)-min(nota_mt)) %>% arrange(math_mean)



# math mean by type of school
# 1 - public
# 2 - private

mt %>% filter(in_presenca_lc==1) %>% group_by(tp_escola)  %>%summarise(nstud = n(), lc_mean= mean(nota_lc))

# math mean by father education level

mt %>% filter(in_presenca_lc==1) %>% group_by(q001)  %>%summarise(nstud = n(), lc_mean= mean(nota_lc))%>% arrange (q001)

