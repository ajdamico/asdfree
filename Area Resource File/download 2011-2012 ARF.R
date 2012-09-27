stop( "you need read.SAScii.sqlite()" )


# create two temporary files and a temporary directory
temp.db <- tempfile()
tf <- tempfile()
td <- tempdir()


# point to the most current ARF file
download.file( "http://datawarehouse.hrsa.gov/datadownload/ARF/arf2011-2012.zip" , tf , mode = 'wb' )

# unzip all of the files in the downloaded .zip file,
# then save all of their unzipped locations into a character vector called 'files'
files <- unzip( tf , exdir = td )


# install.packages( c( 'SAScii' , 'descr' , 'RSQLite' ) )
require(RSQLite)
require(foreign)




# identify ascii file
fn <- files[ grep( '\\.asc' , files ) ]


# identify sas import instructions
sas_ri <- files[ grep( '\\.sas' , files ) ]


# do you want to save the SAS importation script anywhere?
# it might be a good idea, since it contains all of the column labels
# this command will copy the importation script from its temporary location
# to a permanent one of your choosing (defaults to C:/My Directory/ARF/)
file.copy( sas_ri , "C:/My Directory/ARF/ARF 2011 SAS import script.sas" )


# create and connect to a temporary SQLite database
db <- dbConnect( SQLite() , temp.db )


# parse through the ARF without touching RAM #
read.SAScii.sqlite( 
		fn = fn ,
		sas_ri = sas_ri ,
		tl = TRUE ,			# convert all column names to lowercase?
		tablename = 'arf' ,
		db = db
	)


# read the ARF into RAM
arf <- dbReadTable( db , 'arf' )


# save the arf data table as an R data file (.rda)
# (for quick loading later)
save( arf , file = "C:/My Directory/ARF/arf2011.rda" )


# export the arf data table as a csv file
write.csv( arf , "C:/My Directory/ARF/arf2011.csv" )


# export the arf data table as a stata file
write.dta( arf , "C:/My Directory/ARF/arf2011.dta" )


# delete the ARF table from RAM
rm( arf )

# clear up RAM
gc()



# re-load the ARF table quickly from the R data file (.rda)
load( "C:/My Directory/ARF/arf2011.rda" )


