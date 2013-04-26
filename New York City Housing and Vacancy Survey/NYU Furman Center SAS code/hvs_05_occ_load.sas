/*
*      	This program creates a SAS dataset of data for occupied housing units     
		for the 2005 HVS.
*
*       file read:      uf_05_occ.dat
*       file written:   hvs05o.sas7bdat
*/

options replace nocenter linesize=80;
filename occ05 'F:\DEPT\REUP\Core Data\HVS - Housing Vacancy Survey\2005\data\uf_05_occ.dat';

data hvs.occ05_raw;
     infile occ05 lrecl=428;
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
     mortgage       114-117           /* 9998,9999 -> missing */
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
     regstatr		191
     rentgov1       192-196
     rentgov2       197-201
     rentgov3       202-206
     rentgov4       207-211
     rentgov5       212-216
     o_p_rent		217-221
     heatbrk		222
     htgeqp         223             /* 8 -> missing, 9 = none */
     addtlht        224
     rodent         225
     extermin		226
     cracks1        227
     cracks2        228
     brkpnti        229
     brkpnt         230
     waterlks       231
     badbldgr       232             /* 8 -> missing */
     nghbrtg        233
     pubas1         234
     pubas2         235
     pubas3         236
     pubas4         237
     smokers		238-240 		/* new in 2005 */
     smkwork		241				/* new in 2005 */
     insured		242-243			/* new in 2005 */
     health         244				/* new in 2005 */
     phone          245				/* new in 2005 */
     immigrnt		246
     yr_immig		247-250
     yr_nyc         251-254
     dhcrflag		255
     progstat		256-257
     control        258-259
     new_csr		260-261			/* new in 2005 */
     strclass		262-263
     schdcode		264-265
     sro_flag		266
     built          267-268         /* no missings */
     cond_rcd		269
     respline		270-271
     hhcomp         272-273
     nonrel         274
     hhrace2        275
     hhrace3		276
     hhrace4		277-278
     presplum		279
     presktch		280
     nodefic        282             /* 9 -> missing */
     persons        283-284         /* no missings */
     crowd100       285-287         /* no missings */
     grent          288-291         /* 9999-> missing */
     grentrcd		292-295
     crentrcd		296-299
     kpoverty       300             /* no missings */
     yhincome       301-307
     incflag1		308
     income2		309-315
     incflag2		316
     income3		317-323
     incflag3		324
     income4		325-331
     incflag4		332
     income5		333-339
     incflag5		340
     income6		341-347
     incflag6		348
     income7		349-355
     incflag7		356
     income8		357-363
     incflag8		364
     subboro        365-366         /* 98 -> missing */
     gburden        367-370        /* 0,9999 -> missing */
     cburden        371-374         /* 0,9999 -> missing */
     under6         375				
     under18		376				
     hhweight       377-385         /* no missings */
     agperswt		386-394
     seqnum         395-400
     f_hhsex		401
     f_hhage		402
     f_hisp         403
     f_hhrace		404
     f_yrmvin		405
     f_yracq		406
     f_value		407
     f_stries		408
     f_nrooms		409				/* now includes bedrooms */
     f_plumb		410				/* includes for exclusive use */
     f_kitch		411				/* includes for exclusive use */
     f_heat         412
     f_elec         413
     f_gascst		414
     f_gaselc		415
     f_sewer		416
     f_ofuels		417
     f_crent		418
     f_rntgv		419				/* includes all gov programs */
     f_oprent		420		
     f_hhinc		421
     f_inc1         422
     f_inc2         423
     f_inc3         424
     f_inc4         425
     f_inc5         426
     f_inc6         427
     f_inc7         428
     ;    

run;
