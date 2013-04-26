/*
*      	This program creates a SAS dataset of data for occupied housing units     
		for the 2011 HVS.
*
*       file read:      lng11_occ11_web.dat
*       file written:   occ11_raw.sas7bdat
*/

libname hvs11 "J:\DEPT\REUP\Core Data\HVS - Housing Vacancy Survey\2011\SAS";
filename occ11 'J:\DEPT\REUP\Core Data\HVS - Housing Vacancy Survey\2011\Raw Data\lng11_occ11_web.dat';

data hvs.occ11_raw;
     infile occ11 lrecl=598;
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
     
	 /* new in 2011 */
     energyassist   185
	 assistamt      186-189
	 blank190		190
	 /* end new */

     rentm          191-195        /* 99999 -> missing */
     lengthls		196

     blank197		197-205      /* 2008: this used to be rent regulation status (respondent's report) but it seems to be gone this year */

     /* 2011: the rentgov variables are different this year, just yes/no
	    they used to include the year that the subsidy started */
     rentgov_sec8           206
     rentgov_SCRIE          207
     rentgov_advantage      208
	 rentgov_pubass         209
	 rentgov_hsp            210
	 rentgov_eihp           211
	 rentgov_LTSP           212
	 rentgov_jig            213
	 rentgov_feps           214
	 rentgov_otherfed       215
     rentgov_othercity      216

     blank217               217-222 
     /* end new rent gov */

     o_p_rent       223-227
     heatbrk		228
     htgeqp         229        /* 8 -> missing, 9 = none */
     blank230       230-235    /* new in 08, blank field */
     addtlht        236
     rodent         237
 
     cockroach      238        /* new in 08 */
 
     extermin		239
     cracks1        240
     cracks2        241
     brkpnti        242
     brkpnt         243
     waterlks       244
     
     nghbrtg        245
     pubas1         246
     pubas2         247
     pubas3         248
     pubas4         249
     
     /* not in 2008 file
     smokers		238-240 	
     smkwork		241			
     insured		242-243		
     */

	 blank250       250-255
     
     phone          256				/* new in 2005 */
     cellphone      257-258             /* new in 2008 */
     health         259				/* new in 2005 */

     /* new health variables 2011 */
	 health_dental  260
	 health_prevent 261
	 health_mental  262
	 health_ill     263
	 health_rx      264

	 health_bars    265
	 blank266       266-269
	 health_fall    270
	 /* end new health */

     immigrnt       271
     yr_immig       272-275
     yr_nyc         276-279
     blank280       280            /* new in 2008, blank field */
     

     dhcrflag		407
     progstat		408-409
     blank_control  410-411
     new_csr		412-413			/* new in 2005 */
     strclass		414-415
     schdcode		416-417
     blank_sro_flag 418
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
	 nodefic1987    438
     nodefic2011    439
     persons        440-441         /* no missings */
     crowd100       442-444         /* no missings */
     grent          445-449         /* 9999-> missing */
     grentrcd		450-453
     crentrcd		454-457
     kpoverty       458             /* no missings */
     yhincome       459-465
     incflag1		466
     income2		467-473
     incflag2		474
     income3		475-481
     incflag3		482
     income4		483-489
     incflag4		490
     income5		491-497
     incflag5		498
     income6		499-505
     incflag6		506
     income7		507-513
     incflag7		514
     income8		515-521
     incflag8		522
     blank523       523-525

     subboro        526-527         /* 98 -> missing */
     gburden        528-531        /* 0,9999 -> missing */
     cburden        532-535         /* 0,9999 -> missing */
     under6         536				
     under18		537				
     hhweight       538-546         /* no missings */
     blank547		547-555
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
