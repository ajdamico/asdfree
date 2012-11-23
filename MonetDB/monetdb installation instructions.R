# some usgsd scripts use a superfast (completely free) database program called monetdb.
# here's how to install and configure it to work with r on windows in four steps:


# 1) install java (not just for your web browser)
# type 'java download' into google and click the first link
# download and install java


# 2) install monetdb (an ultra-fast sql engine)
# go to http://www.monetdb.org/
# click 'download now'
# choose your operating system
# download the "MonetDB SQL Installer x86 64" option and run it.
# by default, monetdb will install to: C:\Program Files\MonetDB\MonetDB5\
# that's cool, just don't forget that path.  you'll need it later.
# jot down the filepath where you installed this (with slashes doubled):
# "c:\\program files\\monetdb\\monetdb5\\"


# 3) download the latest monetdb java driver
# go to http://dev.monetdb.org/downloads/Java/Latest/
# save the 'monetdb-jdbc-#.#.jar' file to your local disk..
# ..you can put it anywhere, but for convenience i recommend saving it in
# C:\Program Files\MonetDB\MonetDB5\
# be sure to change the number signs below to actual numbers and..
# ..remember the filepath where you saved this (with slashes reversed):
# "c:/program files/monetdb/monetdb5/monetdb-jdbc-#.#.jar"


# 4) install two R packages that are not currently available on CRAN and install a few others..
# open up your R console and run these two separate installation commands without the # sign in front:
# install.packages( c( "RMonetDB" , "sqlsurvey" ) , repos = c( "http://cran.r-project.org" , "http://R-Forge.R-project.org" ) , dep=TRUE )
# install.packages( c( 'SAScii' , 'descr' , 'survey' , 'RCurl' ) )
