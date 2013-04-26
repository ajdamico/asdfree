/*      This program reads data from the 2002 HVS-Vacant Units file.

                file read:      uf_02_vac.dat
*               file written:   hh02v.sd2
*/

options replace nocenter linesize=80;

*libname hvs 'D:\Data\Denises HVS';
filename hvs02 "F:\DEPT\REUP\Core Data\HVS - Housing Vacancy Survey\2002\Revised Data\uf_02_vac_rev.dat";

data hvs.vac02_raw;
     infile hvs02 lrecl=108;
     input
     rectype        1
     borough        2
     walls          3-8
     windows		9-13
     stairway		14-19
     floors         20-25
     condit         26              /* 8 -> missing */
     badbldgo       27              /* 8 -> missing */
     wl_street		28
     wl_elev		29
     wl_enter		30
     respond        31              /* 8 -> missing */
     prevocc        32              /* 8 -> missing */
     numunit        33-34           /* no missings */
     o_in_bdg		35
     stories		36-37
     floor          38-39
     elevator       40
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
     control        66-67           /* no missings */
     strclrcd		68-69
     typ_scdl		70-71
     sro_flag		72
     built          73-74           /* no missings */
     rent_rm		75-79
     cond_rcd		80
     subboro        81-82           /* no missings */
     seqnum         83-88           /* no missings */
     hhweight       89-97           /* no missings */
     /************************* This is the new line *************************/
     new_csr        98-99
     /************************* end new line *********************************/
     f_story        100
     f_rooms        101
     f_bedrms       102
     f_plumb        103
     f_useplm       104
     f_kitch        105
     f_usektc       106
     f_htfuel       107
     f_rent         108
     ;
run;
