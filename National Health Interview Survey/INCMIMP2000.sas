*********************************************************************
 August 21, 2012
 
 THIS IS AN EXAMPLE OF A SAS PROGRAM THAT CREATES A SAS
 FILE FROM THE Public Use Imputed Income ASCII FILE
 
 THIS IS STORED IN INCMIMP.SAS
*********************************************************************;

* USER NOTE: REPLACE CORRECT PATH AND PARAMETERS BEFORE EXECUTING THE SAS PROGRAM;

%LET YEAR = 2000;       *** provide survey year ***;

  *** path to the imputed income ASCII datasets ***;
FILENAME  ASCIIDAT  "C:\NHIS2000\INCMIMP&IMPNUM..DAT";  

  *** path to store the imputed income SAS datasets ***;
LIBNAME  NHIS   "C:\NHIS2000\";  
LIBNAME  LIBRARY   "C:\NHIS2000\";  
* DEFINE VARIABLE VALUES FOR REPORTS;

*  USE THE STATEMENT "PROC FORMAT LIBRARY=LIBRARY"
     TO PERMANENTLY STORE THE FORMAT DEFINITIONS;

*  USE THE STATEMENT "PROC FORMAT" IF YOU DO NOT WISH
      TO PERMANENTLY STORE THE FORMATS.;

PROC FORMAT LIBRARY=LIBRARY;
*PROC FORMAT;

   VALUE INC001X
      0                  = "0 Reported"
      1                  = "1 Imputed, no information"
      2                  = "2 Imputed, 2-category income reported"
   ; 
   VALUE INC002X
      01                 = "01 0 - $4999"
      02                 = "02 $5000-$9999"
      03                 = "03 $10000-$14999"
      04                 = "04 $15000-$19999"
      05                 = "05 $20000-$24999"
      06                 = "06 $25000-$34999"
      07                 = "07 $35000-$44999"
      08                 = "08 $45000-$54999"
      09                 = "09 $55000-$64999"
      10                 = "10 $65000-$74999"
      11                 = "11 $75000 and over"
   ;
   VALUE INC003X
      0                  = "0 Based on reported income"
      1                  = "1 Imputed, no information"
      2                  = "2 Imputed; 2-category income reported"
      3                  = "3 Imputed; 44-category income reported"
      5                  = "5 Undefinable"
   ;
   VALUE INC004X
      01                 = "01 Under .50"
      02                 = "02 .50 to .74"
      03                 = "03 .75 to .99"
      04                 = "04 1.00 to 1.24"
      05                 = "05 1.25 to 1.49"
      06                 = "06 1.50 to 1.74"
      07                 = "07 1.75 to 1.99"
      08                 = "08 2.00 to 2.49"
      09                 = "09 2.50 to 2.99"
      10                 = "10 3.00 to 3.49"
      11                 = "11 3.50 to 3.99"
      12                 = "12 4.00 to 4.49"
      13                 = "13 4.50 to 4.99"
      14                 = "14 5.00 and over"
      96                 = "96 Undefinable"
   ;
   VALUE INC005X
      0                  = "0 Not imputed"
      1                  = "1 Imputed"
   ;
   VALUE INC006X
      1                  = "1 Employed"
      2                  = "2 Not employed"
   ;
   VALUE INC007X
      0                  = "0 Reported"
      1                  = "1 Imputed"
   ;
RUN;

%macro allimp;
%do IMPNUM = 1 %to 5;

  *** path to the imputed income ASCII datasets ***;
FILENAME  ASCIIDAT  "C:\NHIS&YEAR.\INCMIMP&IMPNUM..DAT";

DATA NHIS.INCMIMP&IMPNUM;   *** CREATE A SAS DATA SET ***;        
   
   INFILE ASCIIDAT PAD LRECL=28;

   * DEFINE LENGTH OF ALL VARIABLES;

   LENGTH
      RECTYPE     3   SRVY_YR    4    HHX      $6   FMX      $2
      FPX        $2   IMPNUM     3   INCGRP_F   3   INCGRP_I  3 
      RAT_CATF    3   RAT_CATI   3   EMPLOY_F   3   EMPLOY_I  3
      ERNYR_F     3   ERNYRG_I   3
      ;
 
   * INPUT ALL VARIABLES;

   INPUT
      RECTYPE       1 -   2    SRVY_YR       3 -   6
      HHX      $    7 -  12    FMX      $   13 -  14
      FPX      $   15 -  16    IMPNUM       17
      INCGRP_F     18          INCGRP_I     19 -  20 
      RAT_CATF     21          RAT_CATI     22 -  23   
      EMPLOY_F     24          EMPLOY_I     25
      ERNYR_F      26          ERNYRG_I     27 -  28
      ;

   * DEFINE VARIABLE LABELS;

   LABEL
      RECTYPE    ="File type identifier"
      SRVY_YR    ="Year of National Health Interview Survey"
      HHX        ="HH identifier"
      FMX        ="Family Serial Number"
      FPX        ="Person Number"
      IMPNUM     ="Imputation Number"
      INCGRP_F   ="Family income group imputation flag"
      INCGRP_I   ="Total combined famioy income (group)"
      RAT_CATF   ="Poverty ratop category imputation flag"
      RAT_CATI   ="Ratio of fam inc to pov threshold group"
      EMPLOY_F   ="Employment status imputation flag"
      EMPLOY_I   ="Person's employment status"
      ERNYR_F    ="Person's earnings imputation flag"
      ERNYRG_I   ="Total earnings in last year (group)"
   ;

   * ASSOCIATE VARIABLES WITH FORMAT VALUES;
     FORMAT
      INCGRP_F    INC001X.   
      INCGRP_I    INC002X.   
      RAT_CATF    INC003X.
      RAT_CATI    INC004X.   
      EMPLOY_F    INC005X.   
      EMPLOY_I    INC006X.
      ERNYR_F     INC007X.   
      ERNYRG_I    INC002X.
     ; 
RUN;

PROC CONTENTS DATA=NHIS.INCMIMP&IMPNUM;
   TITLE1 "CONTENTS OF THE &YEAR NHIS IMPUTED INCOME FILE, DATASET &IMPNUM";
RUN;
PROC FREQ DATA=NHIS.INCMIMP&IMPNUM;

   TABLES    RECTYPE  SRVY_YR  FMX  FPX IMPNUM   INCGRP_F  INCGRP_I
             RAT_CATF RAT_CATI EMPLOY_F EMPLOY_I ERNYR_F   ERNYRG_I ;            
   TITLE1 "FREQUENCY REPORT FOR &YEAR NHIS IMPUTED INCOME FILE, DATASET &IMPNUM";
   TITLE2 '(UNWEIGHTED)';

* USER NOTE: TO SEE UNFORMATTED VALUES IN PROCEDURES, ADD THE
             STATEMENT: FORMAT _ALL_;
RUN;

%end;
%mend allimp;
%allimp;
