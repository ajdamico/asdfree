scf.MIcombine <-
	function (results, variances, call = sys.call(), df.complete = Inf, ...) {
		m <- length(results)
		oldcall <- attr(results, "call")
		if (missing(variances)) {
			variances <- suppressWarnings(lapply(results, vcov))
			results <- lapply(results, coef)
		}
		vbar <- variances[[1]]
		cbar <- results[[1]]
		for (i in 2:m) {
			cbar <- cbar + results[[i]]
			# MODIFICATION:
			# vbar <- vbar + variances[[i]]
		}
		cbar <- cbar/m
		# MODIFICATION:
		# vbar <- vbar/m
		evar <- var(do.call("rbind", results))
		r <- (1 + 1/m) * evar/vbar
		df <- (m - 1) * (1 + 1/r)^2
		if (is.matrix(df)) df <- diag(df)
		if (is.finite(df.complete)) {
			dfobs <- ((df.complete + 1)/(df.complete + 3)) * df.complete * 
			vbar/(vbar + evar)
			if (is.matrix(dfobs)) dfobs <- diag(dfobs)
			df <- 1/(1/dfobs + 1/df)
		}
		if (is.matrix(r)) r <- diag(r)
		rval <- list(coefficients = cbar, variance = vbar + evar * 
		(m + 1)/m, call = c(oldcall, call), nimp = m, df = df, 
		missinfo = (r + 2/(df + 3))/(r + 1))
		class(rval) <- "MIresult"
		rval
	}
