/*
*      	This program reads the data file hvs99occ, matches it to person-level data
        from hvs99per, and creates a SAS dataset of data for occupied housing units     
		for the 1999 HVS.
*
*       file read:      uf_02_occ.dat, uf_02_per.dat
*       file written:   hvs02op.ssd01
*/

/******************************************************************************
**** MW: In 2006 a revised 2002 HVS was released.  We are interested in it ****
**** now because it contains the NEW Control Status Recode (characters 35-36) *
**** The original did not.  
******************************************************************************/


options replace nocenter linesize=80;
*libname hvs 'C:\Denise\Data Sources\HVS\2002\Data';
filename occ02 "F:\DEPT\REUP\Core Data\HVS - Housing Vacancy Survey\2002\Revised Data\uf_02_occ_rev.dat";
filename per02 "F:\DEPT\REUP\Core Data\HVS - Housing Vacancy Survey\2002\Revised Data\uf_02_pers_rev.dat";


/* Read person level data to get labor force status of householder */
**** MW:  I don't think we need this right now, so I'm going to leave this step out;
/*********************************************************************************
data person;
     infile per02 lrecl=156;
     input
     relation 8-9
     lfsr 94
     seqnum 105-110;
     if relation=1;
run;
*****************************************************************************/


/*The documentation ABSTRACT says that the LRL is 413, but the records go
to number 421 in the household record layout.*/
data hvs.occ02_raw;
     infile occ02 lrecl=421;
     input

     rectype        1
     borough        2
     walls          3-8
     windows        9-13
     stairway       14-19
     floors         20-25
     condition      26              /* 8 -> missing */
     badbldgo       27              /* 8 -> missing */
     wl_street      28
     wl_elvtr       29
     wl_entr        30
     sex            31
     age            32-33           /* no missing */
     hhethn         34              /* 8-> missing */

     /********************** This is the new line *********************************/
     new_csr        35-36
     /********************** end new line *****************************************/ 
 
     tempaff        37-38           /* 98, 99 missing */
     tempoth        39-40           /* 98, 99 missing */  
     pl_lived		41-42
     yrmove         43-46           /* no missing */
     july1          47
     firstocc		48
     rsn_move		49-50
     birthpl        51-52           /* 98 -> missing */
     birthf         53-54           /* 98 -> missing */
     birthm         55-56           /* 98 -> missing */
     coopcond       57              /* 4,8 -> missing */
     hten           58
     tenure2		59
     conversn		60
     nonevict		61
     year_acq		62-65
     stat_acq		66
     cndo_acq		67
     purpric1		68-74
     purpric2		75
     downpay        76-82           /* 9999998,9999999 -> missing */
     downpay2		83
     value          84-90           /* 9999998,9999999 -> missing */
     mstatus        91
     mortgage       92-95           /* 9998,9999 -> missing */
     fees           96-97           /* 98,99 -> missing */
     sen_exmp		98
     firei          99
     fire           100-103         /* 9998,9999 -> missing */
     fire_per		104
     retaxi         105
     retax          106-107         /* 98,99 -> missing */
     numunit        108-109
     o_in_bld		110
     stories		111-112
     flr_unit		113-114
     elevator		115
     sid2elev		116
     sid2unit		117
     rooms          118
     bdrms          119-120
     plumbing		121
     useplumb		122
     toilet         123
     kitchen		124
     usekitch		125
     kit_func		126
     fueltype		127
     electri        128
     electrc        129-131
     gasi           132
     gasc           133-135
     gaselecc       136-138
     wateri         139
     waterc         140-142
     ofueli         143
     ofuelc         144-147
     lengthls		148
     rentm          149-153         /* 99999 -> missing */
     regstatr		154
     rentgov1       155-159
     rentgov2       160-164
     rentgov3       165-169
     rentgov4       170-174
     rentgov5       175-179
     o_p_rent		180-184
     heatbrk		185
     htgeqp         186             /* 8 -> missing, 9 = none */
     addtlht        187
     rodent         188
     extermin		189
     cracks1        190
     cracks2        191
     brkpnti        192
     brkpnt         193
     waterlks       194
     badbldgr       195             /* 8 -> missing */
     nghbrtg        196
     pubas1         197
     pubas2         198
     pubas3         199
     pubas4         200
     immigrnt		201
     yr_immig		202-205
     yr_nyc         206-209
     dhcrflag		210
     progstat		211-212
     control        213-214
     strclass		215-216
     schdcode		217-218
     sro_flag		219
     built          220-221         /* no missings */
     cond_rcd		222
     respline		223-224
     hhcomp         225-226
     nonrel         227
     hhrace2        228
     presplum		229
     presktch		230
     nodefic        232             /* 9 -> missing */
     persons        233-234         /* no missings */
     crowd100       235-237         /* no missings */
     grent          238-241         /* 9999-> missing */
     grentrcd		242-245
     crentrcd		246-249
     kpoverty       250             /* no missings */
     yhincome       251-257
     incflag1		258
     income2		259-265
     incflag2		266
     income3		267-273
     incflag3		274
     income4		275-281
     incflag4		282
     income5		283-289
     incflag5		290
     income6		291-297
     incflag6		298
     income7		299-305
     incflag7		306
     income8		307-313
     incflag8		314
     subboro        315-316         /* 98 -> missing */
     gburden        317-320        /* 0,9999 -> missing */
     cburden        321-324         /* 0,9999 -> missing */
     hhweight       325-333         /* no missings */
     agperswt		334-342
     seqnum         343-348
     f_hhsex		349
     f_hhage		350
     f_hisp         351
     f_hhrace		352
     f_yrmvin		353
     f_yracq		354
     f_value		355
     f_stries		356
     f_nrooms		357
     f_nbedrm		358
     f_plumb		359
     f_usepl		360
     f_kitch		361
     f_usekch		362
     f_heat         363
     f_elec         364
     f_gascst		365
     f_gaselc		366
     f_sewer		367
     f_ofuels		368
     f_crent		369
     f_rntgv1		370
     f_rntgv2		371
     f_rntgv3		372
     f_rntgv4		373
     f_rntgv5		374
     f_oprent		375
     f_hhinc		376
     f_inc1         377
     f_inc2         378
     f_inc3         379
     f_inc4         380
     f_inc5         381
     f_inc6         382
     f_inc7         383
     hhrace1		384-405
     smokers		406-408
     asthma         409-411
     asthma2		412-414
     probact		415-417
     helpnbr		418
     trustnbr		419
     under18		420
     under6         421
     ;
run;
