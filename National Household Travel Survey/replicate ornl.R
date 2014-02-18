library(RSQLite)
library(survey) 					# load survey package (analyzes complex design surveys)

# This line is needed to (mostly) match the posted results
options(survey.replicates.mse = TRUE)


per.design <-
	svrepdesign(
		weights = ~wttrdfin ,
		repweights = "wtperfin[1-9]" ,
		type = "Fay" ,
		rho = ( 1 - 1 / sqrt( 99 ) ) ,
		data = "per_m_09" ,
		combined.weights = T ,
		dbtype = "SQLite" ,
		dbname = "nhts.db"
	)
		

day.design <-
	svrepdesign(
		weights = ~wttrdfin ,
		repweights = "daywgt[1-9]" ,
		type = "Fay" ,
		rho = ( 1 - 1 / sqrt( 99 ) ) ,
		data = "day_m_09" ,
		combined.weights = T ,
		dbtype = "SQLite" ,
		dbname = "nhts.db"
	)
		

hh.design <-
	svrepdesign(
		weights = ~wthhfin ,
		repweights = "hhwgt[1-9]" ,
		type = "Fay" ,
		rho = ( 1 - 1 / sqrt( 99 ) ) ,
		data = "hh_m_09" ,
		combined.weights = T ,
		dbtype = "SQLite" ,
		dbname = "nhts.db"
	)

# household size categories
svytotal(~I(hhsize == 1), hh.design)
svytotal(~I(hhsize == 2), hh.design)
svytotal(~I(hhsize == 3), hh.design)
svytotal(~I(hhsize > 3), hh.design)

confint(svytotal(~I(hhsize == 1), hh.design), df = degf(hh.design)+1)
confint(svytotal(~I(hhsize == 2), hh.design), df = degf(hh.design)+1)
confint(svytotal(~I(hhsize == 3), hh.design), df = degf(hh.design)+1)
confint(svytotal(~I(hhsize > 3), hh.design), df = degf(hh.design)+1)

# total HH vehicles
svytotal(~I(hhvehcnt), hh.design)
confint(svytotal(~I(hhvehcnt), hh.design), df = degf(hh.design)+1)

# this will blow your ram if left in, remove the large variables before moving on
rm(z.data)
rm(z.repwts)
rm(y)
gc()

# prepare person file data

z.data <- dbGetQuery(db, "SELECT r_age, r_sex, driver, worker, wtperfin FROM per_merged_2009")
z.repwts <- dbGetQuery(db, paste0("SELECT ", paste0(perrep.names, collapse = ", "), " FROM per_merged_2009"))

y <- 
	svrepdesign(
		weights = ~wtperfin,
		repweights = z.repwts,
		type = "Fay",
		rho = (1-1/sqrt(99)),
		data = z.data)

# All male = 1, all female = 2
svytotal(~I(r_sex == 1), y)
confint(svytotal(~I(r_sex == 1), y), df = degf(y)+1)

svytotal(~I(r_age < 16), y)
confint(svytotal(~I(r_age < 16), y), df = degf(y))

# Drivers
svytotal(~I(driver == 1), y, na.rm = TRUE)
confint(svytotal(~I(driver == 1), y, na.rm = TRUE), df = degf(y)+1)

# Male drivers
svytotal(~I(driver == 1 & r_sex == 1), y, na.rm = TRUE)
confint(svytotal(~I(driver == 1 & r_sex == 1), y, na.rm = TRUE), df = degf(y)+1)

# Female drivers
svytotal(~I(driver == 1 & r_sex == 2), y, na.rm = TRUE)
confint(svytotal(~I(driver == 1 & r_sex == 2), y, na.rm = TRUE), df = degf(y)+1)

# Workers
svytotal(~I(worker == 1), y, na.rm = TRUE)
confint(svytotal(~I(worker == 1), y, na.rm = TRUE), df = degf(y)+1)

# clean up
rm(z.data)
rm(z.repwts)
rm(y)
gc()

# disconnect from database
dbDisconnect(db)
monetdb.server.stop(pid)

# the trip file was analyzed using a sqlite database-backed survey object
# and the following commands, assuming the object 'y' is attached defined with reference
# to the trip table, as defined here:
# https://github.com/aakarner/nhts/blob/master/download%202009%20NHTS%20data%20(sqlite).R

# Person trips - calculated using a column of ones added to the trip file
# svytotal(~one, y)
# confint(svytotal(~I(one), y), df = degf(y)+1)

# Person-miles of travel
# svytotal(~trpmiles, y, na.rm = TRUE)
# confint(svytotal(~trpmiles, y, na.rm = TRUE), df = degf(y)+1)
