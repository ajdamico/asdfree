/****************************   MACRO PARA LEITURA DO ARQUIVO DE PESSOAS   ***********************************************/

/* 	PARÂMETROS DE ENTRADA	

		PASTA - caminho da pasta onde está o arquivo com as informações das pessoas da UF desejada.
		UF - código numérico da UF desejada
	
	SAIDA 

		Arquivo PESSOAS no formato SAS

****************************************************************************************************************************/

%MACRO LE_PESSOAS(PASTA,UF);

FILENAME PESSOAS "&PASTA.\PES&UF..TXT" LRECL=390 ;

DATA PESSOAS;
INFILE PESSOAS MISSOVER;
INPUT
@1 	V0102 $2.	/*	"UNIDADE DA FEDERAÇÃO
				11- Rondônia
				12- Acre
				13- Amazonas
				14- Roraima
				15- Pará
				16- Amapá
				17- Tocantins
				21- Maranhão
				22- Piauí
				23- Ceará
				24- Rio Grande do Norte
				25- Paraíba
				26- Pernambuco
				27- Alagoas
				28- Sergipe
				29- Bahia
				31- Minas Gerais
				32- Espírito Santo
				33- Rio de Janeiro
				35- São Paulo
				41- Paraná
				42- Santa Catarina
				43- Rio Grande do Sul
				50- Mato Grosso do Sul
				51- Mato Grosso
				52- Goiás
				53 - Distrito Federal"	*/
@3 	V1002 $4.	/*	"CODIGO DA MESORREGIÃO
				A RELAÇÃO ENCONTRA-SE NO ARQUIVO “Divisão Territorial Brasileira.xls”"	*/
@7 	V1003 $5.	/*	"CODIGO DA MICRORREGIÃO
				A RELAÇÃO ENCONTRA-SE NO ARQUIVO “Divisão Territorial Brasileira.xls”"	*/
@12 	V1103 $7.	/*	"CODIGO DO MUNICIPIO
				A RELAÇÃO ENCONTRA-SE NO ARQUIVO “Divisão Territorial Brasileira.xls”"	*/
@19 	V0104 $9.	/*	"CODIDO DO DISTRITO
				A RELAÇÃO ENCONTRA-SE NO ARQUIVO “Divisão Territorial Brasileira.xls”"	*/
@28 	V0105 $11.	/*	"CODIGO DO SUBDISTRITO
				A RELAÇÃO ENCONTRA-SE NO ARQUIVO “Divisão Territorial Brasileira.xls”"	*/
@39 	V0300 8.	/*	CONTROLE	*/
@47 	V0400 2.	/*	> 00 (PESSOA)	*/
@49 	V1004 $2.	/*	"REGIÃO METROPOLITANA
				VER ARQUIVO AUXILIAR"	*/
@51 	AREAP $13.	/*	"ÁREA DE PONDERAÇÃO
					A RELAÇÃO ENCONTRA-SE NO ARQUIVO “Municípios Com Mais de Uma Área de Ponderação.xls”"	*/
@64 	V1001 $1.	/*	"REGIÃO GEOGRÁFICA
					1- Região Norte (uf = 11 a 17)
					2- Região Nordeste (uf = 21 a 29)
					3- Região Sudeste (uf = 31 a 35)
					4- Região Sul (uf = 41 a 43)
					5- Região Centro-Oeste (uf = 50 a 53)"	*/
@65 	V1005 $1.	/*	"SITUAÇÃO DO SETOR
					1- Área urbanizada de cidade ou vila
					2- Área não urbanizada de cidade ou vila
					3- Área urbanizada isolada
					4- Rural - de extensão urbana
					5- Rural - povoado
					6- Rural - núcleo
					7- Rural - outros aglomerados
					8- Rural - exclusive os aglomerados rurais"	*/
@66 	V1006 $1.	/*	"SITUAÇÃO DO DOMICÍLIO
					1- Urbano, se V1005 = 1, 2, 3
					2- Rural, se V1005 = 4, 5, 6, 7, 8"	*/
@67 	V1007 $1.	/*	"TIPO DO SETOR
					0- Setor comum ou não especial
					1- Setor especial de aglomerado subnormal
					2- Setor especial de quartéis, bases militares, etc.
					3- Setor especial de alojamento, acampamentos, etc.
					4- Setor especial de embarcações, barcos, navios, etc.
					5- Setor especial de aldeia indígena
					6- Setor especial de penitenciárias, colônias penais, presídios, cadeias, etc.
					7- Setor especial de asilos, orfanatos, conventos, hospitais, etc."	*/
@68 	MARCA $1.	/*	"SE A PRÓPRIA PESSOA PRESTOU AS INFORMAÇÕES
					1- Se a própria pessoa prestou as informações
					Branco- As informações foram prestadas por outra pessoa do domicílio"	*/
@69 	V0401 $1.	/*	"SEXO
					1- Masculino
					2- Feminino"	*/
@70 	M0401 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0401
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@71 	V0402 $2.	/*	"RELAÇÃO COM RESPONSÁVEL PELO DOMICÍLIO
					01- Pessoa responsável
					02- Cônjuge, companheiro(a)
					03- Filho(a), enteado(a)
					04- Pai, mãe, sogro(a)
					05- Neto(a), bisneto(a)
					06- Irmão, irmã
					07- Outro parente
					08- Agregado(a)
					09- Pensionista
					10- Empregado(a) doméstico(a)
					11- Parente do(a) empregado(a) doméstico(a)
					12- Individual em domicílio coletivo"	*/
@73 	M0402 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0402
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@74 	V0403 $2.	/*	"RELAÇÃO COM RESPONSÁVEL PELA FAMÍLIA
					01- Pessoa responsável
					02- Cônjuge, companheiro(a)
					03- Filho(a), enteado(a)
					04- Pai, mãe, sogro(a)
					05- Neto(a), bisneto(a)
					06- Irmão, irmã
					07- Outro parente
					08- Agregado(a)
					09- Pensionista
					10- Empregado(a) doméstico(a)
					11- Parente do(a) empregado(a) doméstico(a)
					12- Individual em domicílio coletivo"	*/
@76 	M0403 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0403
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@77 	V0404 1.	/*	"NÚMERO DA FAMÍLIA
					0- Individual em domicílio coletivo"	*/
@78 	M0404 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0404
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@79 	V4572 3.	/*	IDADE CALCULADA EM ANOS COMPLETOS - A PARTIR DE 1 ANO	*/
@82 	M4752 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4752
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@83 	V4754 2.	/*	"IDADE CALCULADA EM MESES - MENOS DE UM ANO (Valores de 00 a 11)
					00- Inclusive para as pessoas com idade em anos completos a partir de um ano"	*/
@85 	M4754 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4754
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@86 	V4070 $1.	/*	"INDICADORA DA FORMA DE DECLARAÇÃO DA IDADE (DATA DE NASCIMENTO, IDADE INFORMADA OU IDADE ESTIMADA)
					1- Idade calculada
					2- Idade presumida/declarada"	*/
@87 	V0408 $1.	/*	"COR OU RAÇA
					1-Branca
					2- Preta
					3- Amarela
					4- Parda
					5- Indígena
					9- Ignorado"	*/
@88 	M0408 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0408
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@89 	V4090 $3.	/*	"CÓDIGO DA RELIGIÃO
					CATEGORIAS NO ARQUIVO “Estrutura de Religião-V4090.doc”"	*/
@92 	M4090 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4090 (0 e 1)
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@93 	V0410 $1.	/*	"PROBLEMA MENTAL PERMANENTE
					1- Sim
					2- Não
					9- Ignorado"	*/
@94 	M0410 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0410
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@95 	V0411 $1.	/*	"CAPACIDADE DE ENXERGAR
					1- Incapaz
					2- Grande dificuldade permanente
					3- Alguma dificuldade permanente
					4- Nenhuma dificuldade
					9- Ignorado"	*/
@96 	M0411 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0411
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@97 	V0412 $1.	/*	"CAPACIDADE DE OUVIR
					1- Incapaz
					2- Grande dificuldade permanente
					3- Alguma dificuldade permanente
					4- Nenhuma dificuldade
					9- Ignorado"	*/
@98 	M0412 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0412
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@99 	V0413 $1.	/*	"CAPACIDADE DE CAMINHAR/SUBIR ESCADAS
					1- Incapaz
					2- Grande dificuldade permanente
					3- Alguma dificuldade permanente
					4- Nenhuma dificuldade
					9- Ignorado"	*/
@100 	M0413 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0413
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@101 	V0414 $1.	/*	"DEFICIÊNCIAS
					1- Paralisia permanente total
					2- Paralisia permanente das pernas
					3- Paralisia permanente de um dos lados do corpo
					4- Falta de perna, braço, mão, pé ou dedo polegar
					5- Nenhuma das enumeradas
					9- Ignorado"	*/
@102 	M0414 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0414
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@103 	V0415 $1.	/*	"SEMPRE MOROU NESTE MUNICÍPIO
					1- Sim
					2- Não"	*/
@104 	M0415 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0415
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@105 	V0416 2.	/*	"TEMPO DE MORADIA NESTE MUNICÍPIO
					Branco- para os não migrantes"	*/
@107 	M0416 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0416
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@108 	V0417 $1.	/*	"NASCEU NESTE MUNICÍPIO
					1- Sim
					2- Não
					Branco- para os não migrantes"	*/
@109 	M0417 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0417
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@110 	V0418 $1.	/*	"NASCEU NESTA UF
					1- Sim
					2- Não
					Branco- para os não migrantes e os naturais do município"	*/
@111 	M0418 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0418
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@112 	V0419 $1.	/*	"NACIONALIDADE
					1- Brasileiro nato
					2- Naturalizado brasileiro
					3- Estrangeiro
					Branco- para os não migrantes e os naturais da Unidade da Federação onde foi realizado o Censo 2000"	*/
@113 	M0419 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0419
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@114 	V0420 $4.	/*	"ANO QUE FIXOU RESIDÊNCIA NO BRASIL
					Branco- para os não migrantes e os brasileiros natos"	*/
@118 	M0420 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0420
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@119 	V4210 $2.	/*	"CÓDIGO DA UF OU PAÍS DE NASCIMENTO
					Branco- para os não migrantes e os naturais da Unidade da Federação onde foi realizado o Censo 2000
					CATEGORIAS NO ARQUIVO “Estrutura Migração V4210, V4260.xls”"	*/
@121 	M4210 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4210
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@122 	V0422 2.	/*	"TEMPO DE MORADIA NA UF
					Branco- para os não migrantes"	*/
@124 	M0422 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0422
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@125 	V4230 $2.	/*	"CÓDIGO DA UF OU PAÍS DE RESIDÊNCIA ANTERIOR
					Branco– para os não migrantes e os que moram na Unidade da Federação há 10 anos ou mais. 
					CATEGORIAS NO ARQUIVO ”Estrutura de Migração V4230.xls”"	*/
@127 	M4230 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4230
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@128 	V0424 $1.	/*	"RESIDÊNCIA EM 31 DE JULHO DE 1995
					1- Neste município, na zona urbana
					2- Neste município, na zona rural
					3- Em outro município, na zona urbana
					4- Em outro município, na zona rural
					5- Em outro país
					6- Não era nascido
					Branco- para os não migrantes"	*/
@129 	M0424 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0424
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@130 	V4250 $7.	/*	"CÓDIGO DO MUNICÍPIO DE RESIDÊNCIA
					Branco- para os não migrantes, os moradores no município onde foi realizado o Censo 2000, os moradores em outro 
					país e aos não nascidos em 31/07/1995.
					CATEGORIAS NO ARQUIVO “Municípios-V4250.xls”"	*/
@137 	M4250 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4250
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@138 	V4260 $2.	/*	"CÓDIGO DA UF OU PAÍS DE RESIDÊNCIA EM 31/07/1995
					Branco- para os não migrantes, os moradores no município onde foi realizado o Censo 2000 e os não nascidos em 31/07/1995.
					CATEGORIAS NO ARQUIVO “Estrutura de Migração V4210, V4260.xls”"	*/
@140 	M4260 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4260
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@141 	V4276 $7.	/*	"CÓDIGO DO MUNICÍPIO E UF OU PAÍS ESTRANGEIRO QUE TRABALHA OU ESTUDA
					CATEGORIAS NO ARQUIVO “Municípios e País Estrangeiro-V4276.xls”"	*/
@148 	M4276 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4276
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@149 	V0428 $1.	/*	"SABE LER E ESCREVER
					1- Sabe ler e escrever
					2- Não sabe"	*/
@150 	M0428 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0428
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@151 	V0429 $1.	/*	"FREQÜENTA ESCOLA OU CRECHE
					1- Sim, rede particular
					2- Sim, rede pública
					3- Não, já freqüentou
					4- Nunca freqüentou"	*/
@152 	M0429 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0429
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@153 	V0430 $2.	/*	"CURSO QUE FREQÜENTA
					01- Creche
					02- Pré-escolar
					03- Classe de alfabetização
					04- Alfabetização de adultos
					05- Ensino fundamental ou 1º grau - regular seriado
					06- Ensino fundamental ou 1º grau - regular não-seriado
					07- Supletivo (ensino fundamental ou 1º grau)
					08- Ensino médio ou 2º grau - regular seriado
					09- Ensino médio ou 2º grau - regular não-seriado
					10- Supletivo (ensino médio ou 2º grau)
					11- Pré-vestibular
					12- Superior – graduação
					13- Superior – mestrado ou doutorado
					Branco- para os não estudantes"	*/
@155 	M0430 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0430
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@156 	V0431 $1.	/*	"SÉRIE QUE FREQÜENTA
					1- Primeira Série
					2- Segunda Série
					3- Terceira Série
					4- Quarta Série
					5- Quinta Série
					6- Sexta Série
					7- Sétima Série
					8- Oitava Série
					9- Curso não-seriado
					Branco- para os não estudantes"	*/
@157 	M0431 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0431
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@158 	V0432 $1.	/*	"CURSO MAIS ELEVADO QUE FREQÜENTOU, CONCLUINDO PELO MENOS UMA SÉRIE
					1- Alfabetização de adultos
					2- Antigo primário
					3- Antigo ginásio
					4- Antigo clássico, científico, etc.
					5- Ensino fundamental ou 1º grau
					6- Ensino médio ou 2º grau
					7- Superior - graduação
					8- Mestrado ou doutorado
					9- Nenhum
					Branco- para os estudantes"	*/
@159 	M0432 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0432
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@160 	V0433 $2.	/*	"ÚLTIMA SÉRIE CONCLUÍDA COM APROVAÇÃO
					01- Primeira Série
					02- Segunda Série
					03- Terceira Série
					04- Quarta Série
					05- Quinta Série
					06- Sexta Série
					07- Sétima Série
					08- Oitava Série
					09- Curso não-seriado
					10- Nenhuma
					Branco- para os estudantes"	*/
@162 	M0433 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0433
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@163 	V0434 $1.	/*	"CONCLUIU O CURSO NO QUAL ESTUDOU
					1- Sim
					2- Não
					Branco- para os estudantes"	*/
@164 	M0434 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0434
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@165 	V4355 $2.	/*	"CÓDIGO DO CURSO MAIS ELEVADO CONCLUÍDO
					Branco- para os estudantes e os não estudantes que não concluíram curso.
					CATEGORIAS NO ARQUIVO “Cursos Superiores-Estrutura V4535.xls”"	*/
@167 	M0435 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0435
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@168 	V4300 $2.	/*	"ANOS DE ESTUDO
					00- Sem instrução ou menos de 1 ano
					01- 1 ano
					02- 2 anos
					03- 3 anos
					04- 4 anos
					05- 5 anos
					06- 6 anos
					07- 7 anos
					08- 8 anos
					09- 9 anos
					10- 10 anos
					11- 11 anos
					12- 12 anos
					13- 13 anos
					14- 14 anos
					15- 15 anos
					16- 16 anos
					17- 17 anos ou mais
					20- Não determinado
					30- Alfabetização de adultos"	*/
@170 	V0436 $1.	/*	"VIVE EM COMPANHIA DE CÔNJUGE OU COMPANHEIRO(A)
					1- Sim
					2- Não, mas viveu
					3- Nunca viveu
					Branco- para as pessoas com menos de 10 anos de idade"	*/
@171 	M0436 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0436
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@172 	V0437 $1.	/*	"NATUREZA DA ÚLTIMA UNIÃO
					1- Casamento civil e religioso
					2- Só casamento civil
					3- Só casamento religioso
					4- União consensual
					5- Nunca viveu
					Branco- para as pessoas com menos de 10 anos de idade"	*/
@173 	M0437 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0437
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@174 	V0438 $1.	/*	"ESTADO CIVIL
					1- Casado(a)
					2- Desquitado(a) ou separado(a) judicialmente
					3- Divorciado(a)
					4- Viúvo(a)
					5- Solteiro(a)
					Branco- para as pessoas com menos de 10 anos de idade"	*/
@175 	M0438 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0438
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@176 	V0439 $1.	/*	"NA SEMANA DE 23 A 29 DE JULHO DE 2000, TRABALHOU REMUNERADO
					1- Sim
					2- Não
					Branco- para as pessoas com menos de 10 anos de idade"	*/
@177 	M0439 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0439
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@178 	V0440 $1.	/*	"NA SEMANA, TINHA TRABALHO MAS ESTAVA AFASTADO
					1- Sim
					2- Não
					Branco- para as pessoas com menos de 10 anos de idade e pessoas com 10 anos ou mais de idade que exerceram algum  
					trabalho remunerado na totalidade ou em parte da semana de referência do Censo"	*/
@179 	M0440 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0440
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@180 	V0441 $1.	/*	"NA SEMANA, AJUDOU SEM REMUNERAÇÃO, NO TRABALHO EXERCIDO POR PESSOA MORADORA DO DOMICÍLIO, OU COMO APRENDIZ/ESTAGIÁRIO
					1- Sim
					2- Não
					Branco- para as pessoas com menos de 10 anos de idade e pessoas com 10 anos ou mais de idade que exerceram algum 
					trabalho remunerado na totalidade ou em parte da semana de referência do Censo ou tinham algum trabalho remunerado 
					na semana de referência do qual estava temporariamente afastado"	*/
@181 	M0441 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0441
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@182 	V0442 $1.	/*	"NA SEMANA, AJUDOU SEM REMUNERAÇÃO, NO TRABALHO EXERCIDO POR PESSOA MORADORA DO DOMICÍLIO EM ATIVIDADE DE CULTIVO, 
					EXTRAÇÃO VEGETAL...
					1- Sim
					2- Não
					Branco- para as pessoas com menos de 10 anos de idade e pessoas com 10 anos ou mais de idade que exerceram algum 
					trabalho remunerado na totalidade ou em parte da semana de referência do Censo ou tinham algum trabalho remunerado 
					na semana de referência do qual estavam temporariamente afastado ou ajudaram sem remuneração pessoa conta-própria 
					ou empregadora moradora no domicílio, ou como aprendiz ou estagiário"	*/
@183 	M0442 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0442
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@184 	V0443 $1.	/*	"NA SEMANA, TRABALHOU EM CULTIVO, ETC.,  PARA ALIMENTAÇÃO DE PESSOAS MORADORAS NO DOMICÍLIO
					1- Sim
					2- Não
					Branco- para as pessoas com menos de 10 anos de idade e pessoas com 10 anos ou mais de idade que exerceram 
					algum trabalho remunerado na totalidade ou em parte da semana de referência do Censo ou tinham algum trabalho 
					remunerado na semana de referência do qual estavam temporariamente afastado ou ajudaram sem remuneração pessoa 
					conta-própria ou empregadora moradora no domicílio, ou como aprendiz ou estagiário ou ajudaram sem remuneração 
					pessoa moradora no domicílio empregada em atividade de produção de bens primários"	*/
@185 	M0443 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0443
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@186 	V0444 $1.	/*	"QUANTOS TRABALHOS, TINHA NA SEMANA DE 23 A 29 DE JULHO DE 2000 ?
					1- Um
					2- Dois ou mais
					Branco- para as pessoas com menos de 10 anos de idade e pessoas com 10 anos ou mais de idade que não tinham 
					trabalho na semana de referência"	*/
@187 	M0444 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0444
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@188 	V4452 $4.	/*	"CÓDIGO NOVO DA OCUPAÇÃO
					Branco- para pessoa de menos de 10 anos de idade ou pessoa de 10 ou mais anos de idade que não tinha 
					trabalho na semana de referência CATEGORIAS NO ARQUIVO “Ocupação-Estrutura.doc”"	*/
@192 	M4452 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4452
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@193 	V4462 $5.	/*	"CÓDIGO NOVO DA ATIVIDADE
					Branco- para pessoa de menos de 10 anos de idade ou pessoa de 10 ou mais anos de idade que não tinha trabalho 
					na semana de referência do Censo. CATEGORIAS NO ARQUIVO “CnaeDom-Estrutura.xls”"	*/
@198 	M4462 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4462
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@199 	V0447 $1.	/*	"NESSE TRABALHO ERA...
					1- Trabalhador doméstico com carteira de trabalho assinada
					2- Trabalhador doméstico sem carteira de trabalho assinada
					3- Empregado com carteira de trabalho assinada
					4- Empregado sem carteira de trabalho assinada
					5- Empregador
					6- Conta-própria
					7- Aprendiz ou estagiário sem remuneração
					8- Não remunerado em ajuda a membro do domicílio
					9- Trabalhador na produção para o próprio consumo
					Branco- para as pessoas com menos de 10 anos de idade e pessoas com 10 anos ou mais de idade que não tinham 
					trabalho na semana de referência"	*/
@200 	M0447 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0447
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@201 	V0448 $1.	/*	"ERA EMPREGADO PELO RJUOU COMO MILITAR
					1- Sim
					2- Não
					Branco- para as pessoas com menos de 10 anos de idade e pessoas com 10 anos ou mais de idade que não tinham trabalho 
					na semana de referência do Censo e as que não tenham sido classificadas como empregado sem carteira de trabalho 
					assinada no trabalho principal, posição na ocupação"	*/
@202 	M0448 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0448
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@203 	V0449 $1.	/*	"QUANTOS EMPREGADOS TRABALHAVAM NESSA FIRMA
					1- Um empregado
					2- Dois empregados
					3- Três a cinco empregados
					4- Seis a dez empregados
					5- Onze ou mais empregados
					Branco- para as pessoas com menos de 10 anos de idade e pessoas com 10 anos ou mais de idade que não tinham 
					trabalho na semana de referência do Censo e as que não tenham sido classificadas como empregador no trabalho principal, 
					posição na ocupação"	*/
@204 	M0449 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0449
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@205 	V0450 $1.	/*	"ERA CONTRIBUINTE DE INSTITUTO DE PREVIDÊNCIA OFICIAL
					1- Sim
					2- Não
					Branco- para as pessoas com menos de 10 anos de idade e pessoas com 10 anos ou mais de idade que não tinham trabalho 
					na semana de referência do Censo e as que tenham sido classificadas como aprendiz ou estagiário sem remuneração, 
					exerciam trabalho não remunerado em ajuda a membro do domicílio, ou trabalhavam para o próprio consumo"	*/
@206 	M0450 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0450
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@207 	V4511 $1.	/*	"NÃO TEM RENDIMENTO NO TRABALHO PRINCIPAL
					0- Não tem
					1- Somente em benefícios
					Branco- para as pessoas com menos de 10 anos de idade e pessoas com 10 anos ou mais de idade que não tinham trabalho 
					na semana de referência do Censo e as que tinham rendimento do trabalho principal remunerado na semana de 
					referência do Censo"	*/
@208 	M4511 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4511
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@209 	V4512 6.	/*	"RENDIMENTO BRUTO NO TRABALHO PRINCIPAL
					Branco- para as pessoas com menos de 10 anos de idade e pessoas com 10 anos ou mais de idade que não tinham trabalho, 
					a pessoa que tinha trabalho principal remunerado recebendo somente em benefícios e a pessoa que tinha trabalho principal não remunerado na semana de referência do Censo"	*/
@215 	M4512 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4512
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@216 	V4513 6.	/*	"TOTAL DE RENDIMENTOS NO TRABALHO PRINCIPAL
					Branco- para as pessoas com menos de 10 anos de idade e pessoas com 10 anos ou mais de idade que não tinham trabalho 
					na semana de referência do Censo"	*/
@222 	V4514 6.2	/*	"TOTAL DE RENDIMENTOS NO TRABALHO PRINCIPAL, EM SALÁRIOS MÍNIMOS
					Branco- para as pessoas com menos de 10 anos de idade e pessoas com 10 anos ou mais de idade que não tinham trabalho 
					na semana de referência do Censo"	*/
@228 	V4521 $1.	/*	"NÃO TEM RENDIMENTO NOS DEMAIS TRABALHOS
					0- Não tem
					1- Somente em benefícios
					Branco- para as pessoas com menos de 10 anos de idade e pessoas com 10 anos ou mais de idade que não tinham trabalho 
					na semana de referência do Censo e as que tinham rendimento de outro trabalho remunerado na semana de referência do Censo"	*/
@229 	M4521 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4521
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@230 	V4522 6.	/*	"RENDIMENTO BRUTO NOS DEMAIS TRABALHOS
					Branco- para a pessoa com menos de 10 anos de idade e pessoa com 10 anos ou mais de idade que não tinham trabalho, 
					a pessoa que tinha outro trabalho remunerado recebendo somente em benefícios e a pessoa que tinha outro trabalho não remunerado na semana de referência do Censo"	*/
@236 	M4522 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4522
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@237 	V4523 6.	/*	"TOTAL DE RENDIMENTOS NOS DEMAIS TRABALHOS
					Branco- para a pessoa com menos de 10 anos de idade e a pessoa com 10 anos ou mais de idade que não tinham trabalho 
					na semana de referência do Censo"	*/
@243 	V4524 6.2	/*	"TOTAL DE RENDIMENTOS NOS DEMAIS TRABALHOS, EM SALÁRIOS MÍNIMOS
					Branco- para a pessoa com menos de 10 anos de idade e a pessoa com 10 anos ou mais de idade que não tinham trabalho 
					na semana de referência do Censo"	*/
@249 	V4525 6.	/*	"TOTAL DE RENDIMENTOS EM TODOS OS TRABALHOS
					Branco- para a pessoa com menos de 10 anos de idade e a pessoa com 10 anos ou mais de idade que não tinham trabalho 
					na semana de referência do Censo"	*/
@255 	V4526 6.2	/*	"TOTAL DE RENDIMENTOS EM TODOS OS TRABALHOS, EM SALÁRIOS MÍNIMOS
					Branco- para a pessoa com menos de 10 anos de idade e a pessoa com 10 anos ou mais de idade que não tinham trabalho 
					na semana de referência do Censo"	*/
@261 	V0453 2.	/*	"HORAS TRABALHADAS POR SEMANA NO TRABALHO PRINCIPAL
					Branco- para a pessoa com menos de 10 anos de idade e a pessoa com 10 anos ou mais de idade que não tinham trabalho 
					na semana de referência do Censo"	*/
@263 	M4523 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4523
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@264 	V0454 2.	/*	"HORAS TRABALHADAS NOS DEMAIS TRABALHOS
					Branco- para a pessoa com menos de 10 anos de idade e a pessoa com 10 anos ou mais de idade que não tinham trabalho 
					na semana de referência do Censo"	*/
@266 	M0454 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0454
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@267 	V4534 3.	/*	"TOTAL DE HORAS TRABALHADAS
					Branco- para a pessoa com menos de 10 anos de idade e a pessoa com 10 anos ou mais de idade que não tinham trabalho 
					na semana de referência do Censo"	*/
@270 	V0455 $1.	/*	"PROVIDÊNCIA PARA CONSEGUIR TRABALHO
					1– Sim
					2- Não
					Branco– para a pessoa com menos de 10 anos de idade e a pessoa com 10 anos ou mais de idade que tinha trabalho 
					na semana de referência do Censo"	*/
@271 	M0455 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0455
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@272 	V0456 $1.	/*	"EM JULHO DE 2000, ERA APOSENTADO DE INSTITUTO DE PREVIDÊNCIA OFICIAL
					1- Sim
					2- Não
					Branco- para as pessoas com menos de 10 anos de idade"	*/
@273 	M0456 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0456
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@274 	V4573 6.	/*	"RENDIMENTO DE APOSENTADORIA, PENSÃO
					Branco- para a pessoa com menos de 10 anos de idade na data de referência do Censo"	*/
@280 	M4573 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4573
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@281 	V4583 6.	/*	"RENDIMENTO DE ALUGUEL
					Branco- para a pessoa com menos de 10 anos de idade na data de referência do Censo"	*/
@287 	M4583 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4583
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@288 	V4593 6.	/*	"RENDIMENTO DE PENSÃO ALIMENTÍCIA, MESADA, DOAÇÃO
					Branco- para a pessoa com menos de 10 anos de idade na data de referência do Censo"	*/
@294 	M4593 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4593
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@295 	V4603 6.	/*	"RENDIMENTO DE RENDA MÍNIMA, BOLSA-ESCOLA, SEGURO-DESEMPREGO
					Branco- para a pessoa com menos de 10 anos de idade na data de referência do Censo"	*/
@301 	M4603 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4603
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@302 	V4613 6.	/*	"OUTROS RENDIMENTOS
					Branco- para a pessoa com menos de 10 anos de idade na data de referência do Censo"	*/
@308 	M4613 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4613
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@309 	V4614 6.	/*	"TOTAL DE RENDIMENTOS
					Branco- para a pessoa com menos de 10 anos de idade na data de referência do Censo"	*/
@315 	V4615 6.2	/*	"TOTAL DE RENDIMENTOS, EM SALÁRIOS MÍNIMOS
					Branco- para a pessoa com menos de 10 anos de idade na data de referência do Censo"	*/
@321 	V4620 2.	/*	"TOTAL DE FILHOS NASCIDOS VIVOS
					Branco- para os homens e as mulheres com menos de 10 anos de idade na data de referência do Censo"	*/
@323 	M4620 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4620
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@324 	V0463 2.	/*	"TOTAL DE FILHOS NASCIDOS VIVOS QUE ESTAVAM VIVOS
					Branco- para os homens, as mulheres com menos de 10 anos de idade e as mulheres com 10 anos ou mais de idade 
					que não tiveram filhos vivos até a data de referência do Censo"	*/
@326 	V4654 2.	/*	"IDADE CALCULADA DO ÚLTIMO FILHO NASCIDO VIVO
					Branco- para os homens, as mulheres com menos de 10 anos de idade e as mulheres com 10 anos de idade ou mais 
					que não tiveram filhos vivos até a data de referência do Censo"	*/
@328 	M4654 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4654
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@329 	V4670 2.	/*	"TOTAL DE FILHOS NASCIDOS MORTOS
					Branco- para os homens e as mulheres com menos de 10 anos de idade na data de referência do Censo"	*/
@331 	M4670 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4670
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@332 	V4690 2.	/*	"TOTAL DE FILHOS TIDOS
					Branco- para os homens e as mulheres com menos de 10 anos de idade na data de referência do Censo"	*/
@334 	M0463 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0463
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@335 	P001 11.8	/*	PESO (Peso atribuído à pessoa)	*/
@346 	ESTR $2.	/*	ESTRATO DE IMPUTAÇÃO DE RENDA	*/
@348 	ESTRP $2.	/*	ESTRATO DE IMPUTAÇÃO DE RENDA PARCIAL	*/
@350 	V4621 2.	/*	"FILHOS NASCIDOS VIVOS: HOMENS
					Branco- para os homens e as mulheres com menos de 10 anos de idade na data de referência do Censo"	*/
@352 	M4621 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4621
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@353 	V4622 2.	/*	"FILHOS NASCIDOS VIVOS: MULHERES
					Branco- para os homens e as mulheres com menos de 10 anos de idade na data de referência do Censo"	*/
@355 	M4622 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4622
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@356 	V4631 2.	/*	"FILHOS QUE ESTAVAM VIVOS: HOMENS
					Branco- para os homens, as mulheres com menos de 10 anos de idade e as mulheres com 10 anos de idade ou mais 
					que não tiveram filhos vivos até a data de referência do Censo"	*/
@358 	M4631 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4631
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@359 	V4632 2.	/*	"FILHOS QUE ESTAVAM VIVOS: MULHERES
					Branco- para os homens, as mulheres com menos de 10 anos de idade e as mulheres com 10 anos de idade ou mais 
					que não tiveram filhos vivos até a data de referência do Censo"	*/
@361 	M4632 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4632
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@362 	V0464 $1.	/*	"SEXO DO ÚLTIMO FILHO NASCIDO VIVO
					1- Masculino
					2- Feminino
					Branco- para os homens, as mulheres com menos de 10 anos de idade e as mulheres com 10 anos ou mais 
					que não tiveram  filhos vivos até a data de referência do Censo"	*/
@363 	M0464 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0464
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@364 	V4671 2.	/*	"FILHOS NASCIDOS MORTOS: HOMENS
					Branco- para os homens e as mulheres com menos de 10 anos de idade na data de referência do Censo"	*/
@366 	M4671 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4671
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@367 	V4672 2.	/*	"FILHOS NASCIDOS MORTOS: MULHERES
					Branco- para os homens e as mulheres com menos de 10 anos de idade na data de referência do Censo"	*/
@369 	M4672 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V4672
					0- Sem imputação
					1- NIM/IMPS
					2- PRÉ-DIA
					3- DIA
					4- PRÉ-DIA e DIA
					5- SPLUS
					6- DIA e SPLUS
					7- PÓS-SPLUS
					8- PRÉ-DIA e PÓS-SPLUS
					9- DIA e PÓS-SPLUS
					A- PRÉ-DIA, DIA e PÓS-SPLUS
					C- DIA, SPLUS e PÓS-SPLUS"	*/
@370 	V4354 $3.	/*	"CÓDIGO DO CURSO MAIS ELEVADO CONCLUÍDO (CONCLA)
					Branco- para os estudantes que não concluíram curso CATEGORIAS NO ARQUIVO “Cursos Superiores-Estrutura V4534.xls”"	*/
@373 	V4219 $3.	/*	"CÓDIGO DA UF OU PAÍS DE NASCIMENTO (ONU)
					Branco- para os não migrantes e os naturais da Unidade da Federação onde foi realizado o Censo 2000. 	
					CATEGORIAS NO ARQUIVO “Estrutura ONU V4219, V4269.xls”"	*/
@376 	V4239 $3.	/*	"CÓDIGO DA UF OU PAÍS (ONU) DE RESIDÊNCIA ANTERIOR
					Branco- para os não migrantes e os que moram na Unidade da Federação há 10 anos ou mais 
					CATEGORIAS NO ARQUIVO “Estrutura ONU  V4239.xls”"	*/
@379 	V4269 $3.	/*	"CÓDIGO DA UF OU PAÍS (ONU) DE RESIDÊNCIA EM 31/07/1995
					Branco- para os não migrantes, os moradores no município onde foi realizado o Censo 2000 e os nascidos em 31/07/1995.
					CATEGORIAS NO ARQUIVO “Estrutura ONU V4219, V4269.xls”"	*/
@382 	V4279 $3.	/*	CÓDIGO DO PAÍS ESTRANGEIRO (ONU) QUE TRABALHA OU ESTUDA CATEGORIAS NO ARQUIVO “Estrutura ONU V4279.xls”	*/
@385 	V4451 $3.	/*	"CÓDIGO ANTIGO DA OCUPAÇÃO
					Branco- para pessoa de 10 anos de idade ou pessoa de 10 ou mais anos de idade que não tinha trabalho 
					na semana de referência CATEGORIAS NO ARQUIVO “Ocupação91-Estrutura.xls”"	*/
@388 	V4461 $3.	/*	"CÓDIGO ANTIGO DA ATIVIDADE
					Branco- para pessoa de 10 anos de idade ou pessoa de 10 ou mais anos de idade que não tinha trabalho 
					na semana de referência CATEGORIAS NO ARQUIVO “Atividade91-Estrutura.xls”"	*/
;
RUN;

%MEND;


 /* Exemplo de chamada da macro para o Acre
    %LE_PESSOAS(\\CHI00534610\PUBLICO_IBGE,12); */
