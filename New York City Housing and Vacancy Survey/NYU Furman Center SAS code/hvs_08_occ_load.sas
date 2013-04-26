/*
*      	This program creates a SAS dataset of data for occupied housing units     
		for the 2008 HVS.
*
*       file read:      occ08.dat
*       file written:   hvs05o.sas7bdat
*/

libname hvs08 "J:\DEPT\REUP\Core Data\HVS - Housing Vacancy Survey\2008\SAS";
filename occ08 'J:\DEPT\REUP\Core Data\HVS - Housing Vacancy Survey\2008\Raw data\occ_08_revised.dat';


data hvs08.occ08_raw;
     infile occ08 lrecl=598;
     input
     rectype        1
     borough        2
     walls          3-8
     windows		9-13
     stairway		14-19
     floors         20-25
     condition      26              /* 8 -> missing */
     badbldgo       27              /* 8 -> missing */
     wl_street		28
     wl_elvtr		29
     wl_entr		30
     sex            31
     age            32-33           /* no missing */
     hhethn         34              /* 8-> missing */
     hhrace1 		35-56			
     tempaff        57-58           /* 98, 99 missing */
     tempoth        59-60           /* 98, 99 missing */  
     pl_lived		61-62
     recsba         63-64			/* new in 2005: most recent SBA lived in */
     yrmove         65-68           /* no missing */
     july1          69
     firstocc		70
     rsn_move		71-72
     birthpl        73-74           /* 98 -> missing */
     birthf         75-76           /* 98 -> missing */
     birthm         77-78           /* 98 -> missing */
     coopcond       79              /* 4,8 -> missing */
     hten           80
     tenure2		81
     conversn		82
     nonevict		83
     year_acq		84-87
     stat_acq		88
     cndo_acq		89
     purpric1		90-96
     purpric2		97
     downpay        98-104           /* 9999998,9999999 -> missing */
     downpay2		105
     value          106-112           /* 9999998,9999999 -> missing */
     mstatus        113
     mortgage       114-118           /* 9998,9999 -> missing */
     mortorig		120-123			/* new in 2005 */
     mortrate		124-127			/* new in 2005 */
     fees           128-129           /* 98,99 -> missing */
     sen_exmp		130
     firei          131
     fire           132-135         /* 9998,9999 -> missing */
     fire_per		136
     retaxi         137
     retax          138-139         /* 98,99 -> missing */
     numunit        140-141
     o_in_bld		142
     stories		143-144
     flr_unit		145-146
     elevator		147
     sid2elev		148
     sid2unit		149
     rooms          150
     bdrms          151-152
     plumbing		153
     useplumb		154
     toilet         155
     kitchen		156
     usekitch		157
     kit_func		158
     fueltype		159
     electri        160
     electrc        161-164
     gasi           165
     gasc           166-169
     gaselecc       170-173
     wateri         174
     waterc         175-178
     ofueli         179
     ofuelc         180-184
     lengthls		185
     rentm          186-190         /* 99999 -> missing */
     blank191		191            /* 2008: this used to be rent regulation status (respondent's report) but it seems to be gone this year */
     rentgov1       192-196
     rentgov2       197-201
     rentgov3       202-206
      
     /*everything is the same as 05-ish, before here*/
     rentgov_jig    207-211    /* new in 08 */
     rentgov_eihp   212-216    /* new in 08 */
     rentgov_hhp    217-221    /* new in 08 */     /* there are a lot of blank values */
     /* there appear to be new rentgov categories, now we are back on track for a while */
     
     rentgov4       222-226    /* kept 05 name */  /* there are a lot of blank values */
     rentgov5       227-231    /* kept 05 name */  /* there are a lot of blank values */
     o_p_rent       232-236
     heatbrk		237
     htgeqp         238        /* 8 -> missing, 9 = none */
     blank239       239-245    /* new in 08, blank field */
     addtlht        246
     rodent         247
 
     cockroach      248        /* new in 08 */
 
     extermin		249
     cracks1        250
     cracks2        251
     brkpnti        252
     brkpnt         253
     waterlks       254
     
     /* not in 2008 file: 
     badbldgr       232       
     */  
     
     nghbrtg        255
     pubas1         256
     pubas2         257
     pubas3         258
     pubas4         259
     
     /* not in 2008 file
     smokers		238-240 	
     smkwork		241			
     insured		242-243		
     */
     
     health         260				/* new in 2005 */
     phone          261				/* new in 2005 */
     cellphone      262-263             /* new in 2008 */
     immigrnt       264
     yr_immig       265-268
     yr_nyc         269-272
     blank273       273-279             /* new in 2008, blank field */
     
     /* new in 2008 */
     ownpaint       280-285
     ownplumb       286-291
     ownroof        292-297
     ownheat        298-303
     ownstair       304-309
     ownwalls       310-315
     ownsidew       316-321
     costexterm     322-327
     costlawn       328-333
     costotherro    334-339
     costnewheat    340-345
     costnewbath    346-351
     costnewkitch   352-357
     costnewlaund   358-363
     costnewroof    364-369
     costnewelec    370-375
     costnewsecur   376-381
     costnewwindo   382-387
     costrehaz      388-393
     costotherim    394-399
     blank400       400-406
     /* end new */
     
     dhcrflag		407
     progstat		408-409
     control        410-411
     new_csr		412-413			/* new in 2005 */
     strclass		414-415
     schdcode		416-417
     sro_flag		418
     built          419-420         /* no missings */
     cond_rcd		421
     respline		422-423
     hhcomp         424-425
     nonrel         426
     hhrace2        427
     hhrace3		428
     blank429       429-433
     hhrace4		434-435
     presplum		436
     presktch		437
     nodefic        439
     persons        440-441         /* no missings */
     crowd100       442-444         /* no missings */
     grent          445-448         /* 9999-> missing */
     grentrcd		449-452
     crentrcd		453-456
     kpoverty       457             /* no missings */
     yhincome       458-464
     incflag1		465
     income2		466-472
     incflag2		473
     income3		474-480
     incflag3		481
     income4		482-488
     incflag4		489
     income5		490-496
     incflag5		497
     income6		498-504
     incflag6		505
     income7		506-512
     incflag7		513
     income8		514-520
     incflag8		521
     blank522       522-524
     subboro        525-526         /* 98 -> missing */
     gburden        527-530        /* 0,9999 -> missing */
     blank531       531
     cburden        532-535         /* 0,9999 -> missing */
     under6         536				
     under18		537				
     hhweight       538-546         /* no missings */
     agperswt		547-555
     seqnum         556-561
     blank562       562-570
     f_hhsex		571
     f_hhage        572
     f_hisp         573
     f_hhrace		574
     f_yrmvin		575
     f_yracq		576
     f_value		577
     f_stries		578
     f_nrooms		579				/* now includes bedrooms */
     f_plumb		580				/* includes for exclusive use */
     f_kitch		581				/* includes for exclusive use */
     f_heat         582
     f_elec         583
     f_gascst		584
     f_gaselc		585
     f_sewer		586
     f_ofuels		587
     f_crent		588
     f_rntgv		589				/* includes all gov programs */
     f_oprent		590		
     f_hhinc		591
     f_inc1         592
     f_inc2         593
     f_inc3         594
     f_inc4         595
     f_inc5         596
     f_inc6         597
     f_inc7         598
     ;  
run;
