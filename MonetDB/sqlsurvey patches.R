
# slight modification of the sqlsurvey:::sqlvar function
sqlvar.patch <-
	function(U, utable, design){
		nstages<-length(design$id)
		units<-NULL
		strata<-NULL
		results<-vector("list",nstages)
		stagevar<-vector("list",nstages)
		p<-length(U)
		if (is.null(design$subset)){
		tablename<-design$table
		wtname<-design$weights
		} else {
		tablename<-sqlsubst(" %%tbl%% inner join %%subset%% using(%%key%%) ",
		list(tbl=design$table, subset=design$subset$table, key=design$key))
		wtname<-design$subset$weights
		}
		sumUs<-sqlsubst(paste(paste("sum(",U,"*%%wt%%) as _s_",U,sep=""),collapse=", "),list(wt=wtname))
		Usums<-paste("_s_",U,sep="")
		avgs<-paste("avg(",Usums,")",sep="")
		avgsq<-outer(Usums,Usums, function(i,j) paste("avg(",i,"*",j,")",sep=""))
		for(stage in 1:nstages){
		oldstrata<-strata
		strata<-unique(c(units, design$strata[stage]))
		units<-unique(c(units, design$strata[stage], design$id[stage]))
		unitnames <- paste0( "_unit" , units , "_" )
		unitas <- paste( units , "as" , unitnames , collapse = " , " )
		stratanames <- paste0( "_unit" , strata , "_" , collapse = " , " )
		
		if (length(strata) > 0) {
            query <- sqlsubst("select %%avgs%%, %%avgsq%%, _n_, _fpc_, %%strata%%\n                      from \n                            (select %%strata%%, %%sumUs%%, _fpc_ , count(*) as _n_ from (select %%fpc%% as _fpc_ , %%unitas%% , * from %%basetable%% ) as r_temp2 inner join %%tbl%% using(%%key%%) group by %%unitnames%%,_fpc_)  as r_temp\n                      group by %%strata%%, _fpc_, _n_", 
                list(unitas = unitas, unitnames = unitnames, strata = stratanames, sumUs = sumUs, 
                  tbl = utable, avgs = avgs, avgsq = avgsq, fpc = design$fpc[stage], 
                  strata = strata, basetable = tablename, key = design$key))
        }
        else {
            query <- sqlsubst("select %%avgs%%, %%avgsq%%, _n_,  _fpc_\n                      from \n                            (select  %%sumUs%%, _fpc_ , count(*) as _n_  from ( select %%fpc%% as _fpc_ , %%unitas%% , * from %%basetable%% ) as r_temp2 inner join %%tbl%% using(%%key%%) group by %%unitnames%%,_fpc_)  as r_temp group by _n_ , _fpc_", 
                list(unitas = unitas, unitnames = unitnames, strata = stratanames, sumUs = sumUs, 
                  tbl = utable, avgs = avgs, avgsq = avgsq, fpc = design$fpc[stage], 
                  basetable = tablename, key = design$key))
        }
		
		
		result<-dbGetQuery(design$conn, query)
		
		result<-subset(result, `_fpc_`!=`_n_`) ## remove certainty units
		if (is.null(oldstrata)){
		result$`_p_samp_`<-1
		} else {
		index<-match(result[,oldstrata], results[[stage-1]][,oldstrata])
		keep<-!is.na(index)
		result<-result[keep,,drop=FALSE]
		index<-index[keep]
		result$`_p_samp_`<-results[[stage-1]][index,"_n_"]/results[[stage-1]][index,"_fpc_"] ##assumes p = n/N (missing data?)
		}
		means<-as.matrix(result[,1:p])
		ssp<-as.matrix(result[,p+(1:(p*p))])
		meansq<-means[,rep(1:p,p)]*means[,rep(1:p,each=p)]
		nminus1<-(result$`_n_`-1)
		if (any(nminus1==0)){
		if (getOption("survey.lonely.psu")=="remove")
		nminus1[nminus1==0]<-Inf
		else
		stop("strata with only one PSU at stage ",stage)
		}
		stagevar[[stage]]<-((ssp-meansq) * (result$`_n_`^2)/nminus1)*result$`_p_samp_`

		if (any(result$`_fpc_`>0)) {## without-replacement
		stagevar[[stage]][result$`_fpc_`>0]<-stagevar[[stage]][result$`_fpc_`>0]*((result$`_fpc_`-result$`_n_`)/result$`_fpc_`)[result$`_fpc_`>0]
		}
		results[[stage]]<-result
		}
		vars<-lapply(stagevar, function(v) matrix(colSums(v),p,p))
		rval<-vars[[1]]
		for(i in seq(length=nstages-1)) rval<-rval+vars[[i+1]]
		dimnames(rval)<-list(U,U)
		rval
	}


# make sure the sqlsurvey package has been loaded
library(sqlsurvey)		# load sqlsurvey package (analyzes large complex design surveys)


# overwrite sqlsurvey:::sqlvar with sqlvar.patch (constructed above)
assignInNamespace( "sqlvar" , sqlvar.patch , ns = "sqlsurvey" )
