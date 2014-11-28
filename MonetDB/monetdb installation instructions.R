# some asdfree scripts use a superfast (completely free) database program called monetdb.
# here's how to install and configure it to work with r in two steps.


# do not skip step two. #



# windows step one #

	# install monetdb (an ultra-fast sql engine)
	# go to http://www.monetdb.org/
	# click 'download now'
	# choose your operating system
	# download the "MonetDB SQL Installer x86 64" option and run it.
	# by default, monetdb will install to: C:\Program Files\MonetDB\MonetDB5\
	# that's cool, just don't forget that path.  you'll need it later.
	# jot down the filepath where you installed this (with slashes doubled):
	# "c:\\program files\\monetdb\\monetdb5\\"

# macintosh step one #

	# https://www.monetdb.org/Documentation/UserGuide/Downloads/Mac

# unix step one #

	# choose your flavor
	# https://www.monetdb.org/Documentation/UserGuide/Downloads/Fedora
	# https://www.monetdb.org/Documentation/UserGuide/Downloads/UbuntuDebian
	# https://www.monetdb.org/Documentation/UserGuide/Downloads/FreeBSD
	# https://www.monetdb.org/Documentation/UserGuide/Downloads/Solaris


# # all operating systems step two # #

	# 2) install two R packages that are not currently available on CRAN and install a few others..
	# open up your R console and run these two separate installation commands without the # sign in front:
	# install.packages( "sqlsurvey" , repos = c( "http://cran.r-project.org" , "http://R-Forge.R-project.org" ) , dep=TRUE )
	# install.packages( c( 'SAScii' , 'descr' , 'survey' , 'MonetDB.R' , 'downloader' , 'R.utils' ) )
