*******************************************************************************;
* Macro to clean data (recoded from inherited program);
* Include the following variables in dataset: loanamt income appethn apprace1-apprace5 corace1-corace5 coethn appsex cosex preapp occupy loanpurp loantype;
%macro clean;
    if loanamt < 0 then loanamt = .;
    if income < 0 then income = .;
    if appethn < 0 then appethn = 3;
    if apprace1 < 0 then apprace1 = 6;
    if appsex < 0 then appsex = 3;
    if apprace1 in(1,2,3,4,5,6) & appethn = 4 then appethn = 3;
    if appethn in (1,2,3) & apprace1 = 7 then apprace1 = 6;
    if apprace1 = 6 then do;
        apprace2 = .;
	apprace3 = .;
	apprace4 = .;
	apprace5 = .;
    end;
    if apprace1 = 7 | appsex = 4 | appethn = 4 then do;
        apprace1 = 7;
	appsex = 4;
	appethn = 4;
	apprace2 = .;
	apprace3 = .;
	apprace4 = .;
	apprace5 = .;
    end;
    if corace1 < 0 then corace1 = 6;
    if coethn < 0 then coethn = 3;
    if cosex < 0 then cosex = 3;
    if corace1 in (1,2,3,4,5,6) & coethn = 4 then coethn = 3;
    if coethn in (1,2,3) & corace1 = 7 then corace1 = 6;
    if corace1 = 8 | cosex = 5 | coethn = 5 then do;
        corace1 = 8;
	cosex = 5;
	coethn = 5;
	corace2 = .;
	corace3 = .;
	corace4 = .;
	corace5 = .;
    end;
    if corace1 = 6 then do;
        corace2 = .;
	corace3 = .;
	corace4 = .;
	corace5 = .;
    end;
    if corace1 = 7 | cosex = 4 | coethn = 4 then do;
        corace1 = 7;
	cosex = 4;
	coethn = 4;
	corace2 = .;
	corace3 = .;
	corace4 = .;
	corace5 = .;
    end;
* Identify business loans;
    if apprace1 = 7 | corace1 = 7 then business = 1;
        else business = 0;
* Identify bad loans;
    if property < 0 |
       lien < 0 |
       loanpurp < 0 |
       loantype < 0 |
       occupy < 0 |
       loanamt < 0 |
       (action not in (1,2,3,4,5,7,8) & loanpurp not in (1))
       then bad = 1;
       else bad = 0;
%mend clean;
*******************************************************************************;





*******************************************************************************;
* Race macro;

/*To keep race, minority status and ethnicity classifications consistent with IT
     M1SCM01.SASMACRO(RACE) - 01.02               
 ***************************** Top of Data ******************************
         **modified by scm 6/16/05 for use w/ bobs hmlar files;
 */
%macro race;
 %********************************************************************;
 %* race macro                                                       *;
 %* This macro derives the application race for tabulating hmda data.*;
 %*                                                                  *;
 %* Development/Maintenance History                                  *;
 %* Date     By                 Description                          *;
 %* 02/2005  SAF                Initial creation.                    *;
 %********************************************************************;
 %put NOTE:  ***Macro race Release 1.0 Beginning Execution***;
 
 arv1=0; arv2=0; arv3=0; arv4=0; arv5=0;
 crv5=0; cr_min=0;
 
 if apprace1 in(1,2,3,4,5,6,7) then do;
     if apprace1 = 6 or apprace1 = 7  then race = 8; /*not available*/
     else do;
             /* identify valid unique applicant race values */
             array arace {5} apprace1 - apprace5;
             do i = 1 to 5;
                 if arace(i) =  1  then arv1 = 1;
                 else if arace(i) =  2  then arv2 = 1;
                 else if arace(i) =  3  then arv3 = 1;
                 else if arace(i) =  4  then arv4 = 1;
                 else if arace(i) =  5  then arv5 = 1;
             end;
             /* count the number of minorities and unique races */
             ar_min = sum (of arv1-arv4);
             ar_cnt = sum (of arv1-arv5);
             /* check for joint race, if co-appl. race 1 = (1-5) */
             if corace1 in (1,2,3,4,5) then
           do;
             array crace {5}corace1 - corace5;
             do i = 1 to 5;
                 if crace(i) =5 then crv5 = 1;
                 else if crace(i) in (1,2,3,4) then cr_min=1;
             end;
             if ((arv5 = 1 and ar_min = 0) and cr_min > 0) or
                ((crv5 = 1 and cr_min = 0) and ar_min > 0) then
                race = 7;
           end;
           /*****************************************************/
           /* if race ne joint (7), use the applicant race only */
           /* to determine the application race:                */
           /*      . Set race to the value of applicant race 1, */
           /*        when exactly one unique race value is      */
           /*        detected.                                  */
           /*      . set race to the minority race, when one    */
           /*        minority race has been detected.           */
           /*      . set race to 2 or more minority races (6),  */
           /*        when more than one minority race have been */
           /*        detected.                                  */
           /*****************************************************/
           if race ne 7 then
           do;
               if ar_cnt = 1 then race = apprace1;
               else do;
                      if ar_min > 1 then race = 6;
                      else do;
                             if arv1 = 1 then race = 1;
                             else if arv2 = 1 then race = 2;
                             else if arv3 = 1 then race = 3;
                             else if arv4 = 1 then race = 4;
                           end;
                     end;
            end;
         end;
 end;
ethnicity = appethn;
if (appethn = 1 & coethn = 2) | (appethn = 2 & coethn = 1) then ethnicity = 3;
if appethn in (3,4) then ethnicity = 4;
if race = 5 and ethnicity = 2 then min_stat = 1;
    else if ethnicity in (1,3) | race in (1,2,3,4,6,7) then min_stat = 2;
%mend race;

%macro raceformat;
proc format;
    value f_race 1 = "American Indian/Alaskan Native"
    	  	 2 = "Asian"
		 3 = "Black/African American"
		 4 = "Native Hawaiian/Other Pacific Islander"
		 5 = "White"
		 6 = "2 or more races"
		 7 = "Joint (one applicant white, other not"
		 8 = "Unkown";
    value f_ethnicity 1 = "Hispanic or Latino"
    	  	      2 = "Not Hispanic or Latino"
		      3 = "Joint (one applicant Hispanic, other not)"
		      4 = "Unkown";
    value f_min_stat 1 = "Non-Hispanic white"
    	  	     2 = "Minority or Hispanic";

%mend raceformat;

*******************************************************************************;
