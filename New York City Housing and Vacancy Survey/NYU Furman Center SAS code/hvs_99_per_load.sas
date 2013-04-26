/*
*      This program reads the data file per9696 and creates a SAS dataset
         of household level data from the 1996
          portion of the longitudinal (91-93-96) HVS.
*
*       files read:     pers9696.dat
*       file written:   hh96.sd2
*/

options replace nocenter linesize=80;

libname hvs 'C:\anna\hvs\data';
libname soc 'C:\anna\HVS\State of the City';
filename person 'C:\anna\hvs\data\hvs99.per';


data one;
infile person lrecl=133;
input
 @1 rectype 1.
 @2 boro 1.
 @3 persnum 2.
 @5 sex 1.
 @6 age 2.
 @8 relat 2.
 @10 hispanic 1.
 @11 race 2.
 @13 spsnum 2.
 @15 par1num 2.
 @17 par2num 2.
 @19 tempres 1.
 @20 worklwk 1.
 @21 hrslwk 2.
 @23 layoff 1.
 @24 lookwork 1.
 @25 reaslook 2.
 @27 lastwork 1.
 @28 majind 1.
 @29 detind 3.
 @32 occup 3.
 @35 worktype 1.
 @36 weekswrk 2.
 @38 avghrs 2.
 @40 incwage 6.
 @46 incbus 6.
 @52 incint 6.
 @58 incss 6.
 @64 incass 6.
 @70 incret 6.
 @76 incoth 6.
 @82 educ 2.
 @84 inctot 6.
 @90 incflag 1.
 @91 busloss 1.
 @92 intloss 1.
 @93 lfsr 1.
 @94 checkh 1.
 @95 perwgt 9.5
 @104 seqnum 6.
 @110 sexflag 1.
 @111 ageflag 1.
 @112 hispflag 1.
 @113 raceflag 1.
 @114 workflag 1.
 @115 hrswflag 1.
 @116 absflag 1.
 @117 lookflag 1.
 @118 reasflag 1.
 @119 lastflag 1.
 @120 mindflag 1.
 @121 dindflag 1.
 @122 occflag 1.
 @123 typeflag 1.
 @124 hrsyflag 1.
 @125 avhrflag 1.
 @126 wageflag 1.
 @127 busflag 1.
 @128 intflag 1.
 @129 ssflag 1.
 @130 assflag 1.
 @131 retflag 1.
 @132 othflag 1.
 @133 educflag 1.
 ;

/* Fix missing year data */
year=99;

/* Select age 16 and over */
if age ge 16;

/* Missing data recodes */

if sex=8 then sex=.;
if age=98 then age=.;
if relat=98 then relat=.;

if lfsr=4 or lfsr=5 then lfsr=.;

/* Create Labor Force Variables */

inlf=.;
if lfsr=1 or lfsr=2 then inlf=1;
if lfsr=3 then inlf=0;

unemp=.;
if lfsr=2 then unemp=1;
if lfsr=1 then unemp=0;

constant=1;

proc sort;
 by seqnum;

data two; set hvs.hvs99op;
sba=(100*borough)+subboro;
keep seqnum borough sba;

data three;
merge one two;
by seqnum;

/* Select age 16 and over */
if age ge 16;

proc sort;
 by sba;

proc means noprint;
by sba;
weight perwgt;
var constant inlf unemp;
output out=sba sum= per16 inlf unemp;

/*aggregate to borough level*/
data borough; set three;
proc sort;
by borough;

proc means noprint;
by borough;
weight perwgt;
var constant inlf unemp;
output out=boro sum= per16 inlf unemp;

data boro1; set boro;
if borough=1 then sba=601;
else if borough=2 then sba=602;
else if borough=3 then sba=603;
else if borough=4 then sba=604;
else if borough=5 then sba=605;

/*aggregate to city level*/
data city; set three;

proc means noprint;
weight perwgt;
var constant inlf unemp;
output out=nyc sum= per16 inlf unemp;

data nyc1; set nyc;
sba=606;

data soc.hvsemp99; set sba boro1 nyc1;
proc sort;
by sba;

run;
