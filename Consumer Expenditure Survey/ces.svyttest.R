# # # # # # # # # # # # # # # #
# modified svyttest functions #
# # # # # # # # # # # # # # # #

# these two functions are slight modifications of the svyttest function written by dr. thomas lumley
# found in the survey package.  to view the original function, click the 'package source:' link on http://cran.r-project.org/web/packages/survey/
# and look for the file "svyttest.R" inside the "r" folder of that zipped file


# svyttest variant that allows the user to set the degrees of freedom
# includes the df parameter (the consumer expenditure survey requires this to be set manually)
svyttest.df<-function(formula, design, df = degf( design ) ,...){

	m <- eval(bquote(svyglm(formula,design, family=gaussian())))

	rval<-list(statistic=coef(m)[2]/SE(m)[2],
			   parameter=df-1,					# this is now based on the user-input but still defaults to degf(design)-1
			   estimate=coef(m)[2],
			   null.value=0,
			   alternative="two.sided",
			   method="Design-based t-test",
			   data.name=deparse(formula))
	rval$p.value<-2*pt(-abs(rval$statistic),df=rval$parameter)
	names(rval$statistic)<-"t"
	names(rval$parameter)<-"df"
	names(rval$estimate)<-"difference in mean"
	names(rval$null.value)<-"difference in mean"
	class(rval)<-"htest"

	
	return(rval)
}


# svyttest variant that works on multiply-imputed data
svyttest.mi<-function(formula, design ,...){

	# the MIcombine function runs differently than a normal svyglm() call
	m <- eval(bquote(MIcombine( with( design , svyglm(formula,family=gaussian()))) ) )

	rval<-list(statistic=coef(m)[2]/SE(m)[2],
			   parameter=m$df[2],		
			   estimate=coef(m)[2],
			   null.value=0,
			   alternative="two.sided",
			   method="Design-based t-test",
			   data.name=deparse(formula))
			   
	rval$p.value <- ( 1 - pf( ( rval$statistic )^2 , 1 , m$df[2] ) )

	names(rval$statistic)<-"t"
	names(rval$parameter)<-"df"
	names(rval$estimate)<-"difference in mean"
	names(rval$null.value)<-"difference in mean"
	class(rval)<-"htest"

	return(rval)
  
}
