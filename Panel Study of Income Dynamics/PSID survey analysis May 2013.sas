** program to do a simple table of survey corrected results for A. Damico request ;
** May 20 2013 ;
** downloaded 2009 individual data from PSID online site using the data cart method ;

libname d 'P:\pberg\psid replication for damico may 2013' ;

/* PSID DATA CENTER *****************************************************
   JOBID            : 157409                            
   DATA_DOMAIN      : PSID                              
   USER_WHERE       : NULL                              
   FILE_TYPE        : All Individuals Data              
   OUTPUT_DATA_TYPE : ASCII                             
   STATEMENTS       : SAS Statements                    
   CODEBOOK_TYPE    : PDF                               
   N_OF_VARIABLES   : 11                                
   N_OF_OBSERVATIONS: 24385                             
   MAX_REC_LENGTH   : 30                                
   DATE & TIME      : May 20, 2013 @ 13:44:35
************************************************************************/

FILENAME  ind_2009 "p:\pberg\psid replication for damico may 2013\psid_2009_ind_data.txt" ;

DATA ind_2009 ;
   ATTRIB
      ER30001  FORMAT=F4.   LABEL="1968 INTERVIEW NUMBER"                   
      ER30002  FORMAT=F3.   LABEL="PERSON NUMBER                         68"
      ER31996  FORMAT=F2.   LABEL="SAMPLING ERROR STRATUM"                  
      ER31997  FORMAT=F1.   LABEL="SAMPLING ERROR CLUSTER"                  
      ER32000  FORMAT=F1.   LABEL="SEX OF INDIVIDUAL"                       
      ER34001  FORMAT=F5.   LABEL="2009 INTERVIEW NUMBER"                   
      ER34002  FORMAT=F2.   LABEL="SEQUENCE NUMBER                       09"
      ER34003  FORMAT=F2.   LABEL="RELATION TO HEAD                      09"
      ER34004  FORMAT=F3.   LABEL="AGE OF INDIVIDUAL                     09"
      ER34020  FORMAT=F2.   LABEL="YEARS COMPLETED EDUCATION             09"
      ER34046  FORMAT=F5.   LABEL="CORE/IMM INDIVIDUAL CROSS-SECTION WT  09"
   ;
   INFILE ind_2009 LRECL = 30 ; 
   INPUT 
      ER30001      1 - 4     ER30002      5 - 7     ER31996      8 - 9    
      ER31997     10 - 10    ER32000     11 - 11    ER34001     12 - 16   
      ER34002     17 - 18    ER34003     19 - 20    ER34004     21 - 23   
      ER34020     24 - 25    ER34046     26 - 30   
   ;

* set 98 and 99 on completed education to missing ;
   if er34020 in (98,99) then completed_ed=. ; else completed_ed=er34020 ;
run ;

proc contents ; 
run ;

proc freq ;
tables er31996*er31997 / missing ;
run ;

proc surveymeans ;
strata er31996 ; cluster er31997 ; weight er34046 ;
var completed_ed ; 
domain er32000 ;
run ;

proc surveyfreq data=ind_2009 ;
strata er31996 ; cluster er31997 ; weight er34046 ;
tables er32000 ; 
run ;
