/*      This program reads data from the 2008 HVS-Vacant Units file.

                file read:      vac08.dat
*               file written:   hvs08v.sas7bdat
*/

options replace center linesize=80;

libname hvs "J:\DEPT\REUP\Core Data\HVS - Housing Vacancy Survey\2011\SAS";
filename hvs11 'J:\DEPT\REUP\Core Data\HVS - Housing Vacancy Survey\2011\Raw Data\lng11_vac11_web.dat';

data hvs.vac11_raw;
        infile hvs11 lrecl=107;
     input
     rectype        1
     borough        2
     walls          3-8
     windows		9-13
     stairway		14-19
     floors         20-25
     condit         26              /* 8 -> missing */
     badbldgo       27              /* 8 -> missing */
     wl_street      28
     wl_elev		29
     wl_enter		30
     respond        31              /* 8 -> missing */
     prevocc        32              /* 8 -> missing */ /*CHECK*/
     numunit        33-34           /* no missings */
     o_in_bdg		35
     stories		36-37
     floor          38-39
     elevator		40
     sid2elev		41
     sid2unit		42
     rms            43                /* 9=missing */
     bdrms          44-45           /* 98=missing */
     plumbing		46
     useplumb		47
     kitchen		48
     usekitch		49
     heatfuel		50
     coopcond       51              /*4, 8 -> missing */
     vacdur         52              /* 8 -> missing */
     prevtenr       53              /* 4,8 -> missing */
     prevcoop       54              /* 4,8 -> missing */
     vactenr        55              /* no missings */
     reasna         56-57           /* 98,99 -> missing */
     vacrent        58-62           /* 9999 -> missing */
     dhcrflag		63
     progstat		64-65
     blank_control  66-67           /* no longer included */
     new_csr        68-69           /* Moved New Control Status for 2008 */
     strclrcd		70-71
     typ_scdl		72-73
     sro_flag		74
     built          75-76           /* no missings */
     plumbrcd		77
     kitchrcd       78
     rent_rm		79-82
	 blank83        83
     cond_rcd		84
     subboro        85-86           /* no missings */
     seqnum         87-92           /* no missings */
     hhweight       93-101           /* no missings */
     f_story		102
     f_rooms		103
     f_plumb		104
     f_kitch		105
     f_htfuel		106
     f_rent         107
     ;
run;
