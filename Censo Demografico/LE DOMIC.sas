/****************************  MACRO PARA LEITURA DO ARQUIVO DE DOMICÍLIOS   ********************************************/

/* 	PARÂMETROS DE ENTRADA	

		PASTA - caminho da pasta onde está o arquivo com as informações dos domicílios da UF desejada.
		UF - código numérico da UF desejada
	
	SAIDA 

		Arquivo DOMIC no formato SAS

****************************************************************************************************************************/

%MACRO LE_DOMIC(PASTA,UF);

FILENAME DOMIC "&PASTA.\DOM&UF..TXT" LRECL=170 ;

DATA DOMIC;
INFILE DOMIC MISSOVER;
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
					A RELAÇÃO ENCONTRA-SE NO ARQUIVO Divisão Territorial Brasileira.xls”"	*/
@12 	V0103 $7.	/*	"CODIGO DO MUNICÍPIO
					A RELAÇÃO ENCONTRA-SE NO ARQUIVO “Divisão Territorial Brasileira.xls”"	*/
@19 	V0104 $9.	/*	"CODIGO DO DISTRITO
					A RELAÇÃO ENCONTRA-SE NO ARQUIVO “Divisão Territorial Brasileira.xls”"	*/
@28 	V0105 $11.	/*	"CODIGO DO SUBDISTRITO
					A RELAÇÃO ENCONTRA-SE NO ARQUIVO “Divisão Territorial Brasileira.xls”"	*/
@39 	V0300 8.	/*	CONTROLE	*/
@47 	V0400 2.	/*	'= 00 (DOMICÍLIO) 	*/
@49 	V1001 $1.	/*	"REGIÃO GEOGRÁFICA
					1- Região Norte
					2- Região Nordeste
					3- Região Sudeste
					4- Região Sul
					5- Região Centro-Oeste"	*/
@50 	V1004 $2.	/*	"REGIÃO METROPOLITANA
						VER ARQUIVO AUXILIARES"	*/
@52 	AREAP $13.	/*	"ÁREA DE PONDERAÇÃO
					CATEGORIAS NO ARQUIVO “Municípios Com Mais de Uma Área de Ponderação.xls”"	*/
@65 	V1005 $1.	/*	"SITUAÇÃO DO SETOR
					1- Área urbanizada de vila ou cidade
					2- Área não urbanizada de vila ou cidade
					3- Área urbanizada isolada
					4- Rural - extensão urbana
					5- Rural - povoado
					6- Rural - núcleo
					7- Rural - outros aglomerados
					8- Rural - exclusive os aglomerados rurais"	*/
@66 	V1006 $1.	/*	"SITUAÇÃO DO DOMICÍLIO
					1- Urbano
					2- Rural"	*/
@67 	V1007 $1.	/*	"TIPO DO SETOR
					0- Setor comum ou não especial
					1- Setor especial de aglomerado subnormal
					2- Setor especial de quartéis, bases militares, etc.
					3- Setor especial de alojamento, acampamentos, etc.
					4- Setor especial de embarcações, barcos, navios, etc.
					5- Setor especial de aldeia indígena
					6- Setor especial de penitenciárias, colônias penais, presídios, cadeias, etc.
					7- Setor especial de asilos, orfanatos, conventos, hospitais, etc."	*/
@68 	V0110 2.	/*	TOTAL DE HOMENS	*/
@70 	V0111 2.	/*	TOTAL DE MULHERES	*/
@72 	V0201 $1.	/*	"ESPÉCIE DE DOMICILIO
					1- Particular permanente
					2- Particular improvisado
					3- Coletivo"	*/
@73 	M0201 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0201
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
@74 	V0202 $1.	/*	"TIPO DO DOMICÍLIO
					1- Casa
					2- Apartamento
					3- Cômodo
					Branco- Não aplicável"	*/
@75 	M0202 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0202
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
@76 	V0203 2.	/*	"TOTAL DE CÔMODOS
					Branco- para particular improvisado e domicílio coletivo"	*/
@78 	M0203 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0203
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
@79 	V0204 1.	/*	"TOTAL DE CÔMODOS SERVINDO DE DORMITÓRIO
					Branco- para particular improvisado e domicílio coletivo"	*/
@80 	M0204 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0204
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
@81 	V0205 $1.	/*	"CONDIÇÃO DO DOMICÍLIO
					1- Próprio, já pago
					2- Próprio, ainda pagando
					3- Alugado
					4- Cedido por empregador
					5- Cedido de outra forma
					6- Outra Condição
					Branco- para domicílio particular improvisado e domicílio coletivo"	*/
@82 	M0205 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0205
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
@83 	V0206 $1.	/*	"CONDIÇÃO DO TERRENO
					1- Próprio
					2- Cedido
					3- Outra condição
					Branco- para domicílio particular improvisado, domicílio coletivo e domicílio particular permanente 
					que não é próprio (V0205 = 3 a 6)"	*/
@84 	M0206 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0206
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
@85 	V0207 $1.	/*	"FORMA DE ABASTECIMENTO DE ÁGUA
					1- Rede geral
					2- Poço ou nascente (na propriedade)
					3- Outra
					Branco- para domicílio particular improvisado e domicílio coletivo"	*/
@86 	M0207 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0207
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
@87 	V0208 $1.	/*	"TIPO DE CANALIZAÇÃO
					1- Canalizada em pelo menos um cômodo
					2- Canalizada só na propriedade ou terreno
					3- Não canalizada
					Branco- para domicílio particular improvisado e domicílio coletivo"	*/
@88 	M0208 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0208
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
@89 	V0209 $1.	/*	"TOTAL DE BANHEIROS
					0- Não tem
					1- 1 banheiro
					2- 2 banheiros
					3- 3 banheiros
					4- 4 banheiros
					5- 5 banheiros
					6- 6 banheiros
					7- 7 banheiros
					8- 8 banheiros
					9- 9 ou mais banheiros
					Branco– para domicílio particular improvisado e domicílio coletivo"	*/
@90 	M0209 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0209
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
@91 	V0210 $1.	/*	"EXISTÊNCIA DE SANITÁRIO
					1- Sim
					2- Não
					Branco- para domicílio particular improvisado, domicílio coletivo e domicílio particular permanente que tinha banheiro(s)"	*/
@92 	M0210 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0210
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
@93 	V0211 $1.	/*	"TIPO DE ESCOADOURO
					1- Rede geral de esgoto ou pluvial
					2- Fossa séptica
					3- Fossa rudimentar
					4- Vala
					5- Rio, lago ou mar
					6- Outro escoadouro
					Branco- para domicílio particular improvisado, domicílio coletivo e domicílio particular permanente 
					que tinha banheiro(s) ou sanitário"	*/
@94 	M0211 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0211
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
@95 	V0212 $1.	/*	"COLETA DE LIXO
					1- Coletado por serviço de limpeza
					2- Colocado em caçamba de serviço de limpeza
					3- Queimado (na propriedade)
					4- Enterrado (na propriedade)
					5- Jogado em terreno baldio ou logradouro
					6- Jogado em rio, lago ou mar
					7- Tem outro destino
					Branco- para domicílio particular improvisado e domicílio coletivo"	*/
@96 	M0212 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0212
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
@97 	V0213 $1.	/*	"ILUMINAÇÃO ELÉTRICA
					1- Sim
					2- Não
					Branco- para domicílio particular improvisado e domicílio coletivo"	*/
@98 	M0213 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0213
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
@99 	V0214 $1.	/*	"EXISTÊNCIA DE RÁDIO
					1- Sim
					2- Não
					Branco- para domicílio particular improvisado e domicílio coletivo"	*/
@100 	M0214 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0214
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
@101 	V0215 $1.	/*	"EXISTÊNCIA DE GELADEIRA OU FREEZER
						1- Sim
						2- Não
						Branco- para domicílio particular improvisado e domicílio coletivo"	*/
@102 	M0215 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0215
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
@103 	V0216 $1.	/*	"EXISTÊNCIA DE VIDEOCASSETE
					1- Sim
					2- Não
					Branco- para domicílio particular improvisado e domicílio coletivo"	*/
@104 	M0216 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0216
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
@105 	V0217 $1.	/*	"EXISTÊNCIA DE MÁQUINA DE LAVAR ROUPA
					1- Sim
					2- Não
					Branco- para domicílio particular improvisado e domicílio coletivo"	*/
@106 	M0217 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0217
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
@107 	V0218 $1.	/*	"EXISTÊNCIA DE FORNO DE MICROONDAS
					1- Sim
					2- Não
					Branco- para domicílio particular improvisado e domicílio coletivo"	*/
@108 	M0218 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0218
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
@109 	V0219 $1.	/*	"EXISTÊNCIA DE LINHA TELEFÔNICA INSTALADA
					1- Sim
					2- Não
					Branco- para domicílio particular improvisado e domicílio coletivo"	*/
@110 	M0219 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0219
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
@111 	V0220 $1.	/*	"EXISTÊNCIA DE MICROCOMPUTADOR
					1- Sim
					2– Não
					Branco- para domicílio particular improvisado e domicílio coletivo"	*/
@112 	M0220 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0220
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
@113 	V0221 $1.	/*	"QUANTIDADE EXISTENTE DE TELEVISORES
					0- Não tem
					1- 1 televisor
					2- 2 televisores
					3- 3 televisores
					4- 4 televisores
					5- 5 televisores
					6- 6 televisores
					7- 7 televisores
					8- 8 televisores
					9- 9 ou mais televisores
					Branco- para domicílio particular improvisado e domicílio coletivo"	*/
@114 	M0221 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0221
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
@115 	V0222 $1.	/*	"QUANTIDADE EXISTENTE DE AUTOMÓVEIS PARA USO PARTICULAR
					0- Não tem
					1- 1 automóvel
					2- 2 automóveis
					3- 3 automóveis
					4- 4 automóveis
					5- 5 automóveis
					6- 6 automóveis
					7- 7 automóveis
					8- 8 automóveis
					9- 9 ou mais automóveis
					Branco- para domicílio particular improvisado e domicílio coletivo"	*/
@116 	M0222 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0222
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
@117 	V0223 $1.	/*	"QUANTIDADE EXISTENTE DE APARELHOS DE AR CONDICIONADO
					0- Não tem
					1- 1 aparelho
					2- 2 aparelhos
					3- 3 aparelhos
					4- 4 aparelhos
					5- 5 aparelhos
					6- 6 aparelhos
					7- 7 aparelhos
					8- 8 aparelhos
					9- 9 ou mais aparelhos
					Branco- para domicílio particular improvisado e domicílio coletivo"	*/
@118 	M0223 $1.	/*	"INDICADORA DE IMPUTAÇÃO NA V0223
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
@119 	V7100 2.	/*	TOTAL DE MORADORES NO DOMICÍLIO	*/
@121 	V7203 3.1	/*	"DENSIDADE DE MORADORES POR CÔMODO
					Branco- para domicílio particular improvisado e domicílio coletivo"	*/
@124 	V7204 3.1	/*	"DENSIDADE DE MORADORES POR DORMITÓRIO
					Branco- para domicílio particular improvisado e domicílio coletivo"	*/
@127 	V7401 2.	/*	"NÚMERO DE COMPONENTES DA FAMÍLIA 01
					Branco- para domicílio coletivo"	*/
@129 	V7402 2.	/*	"NÚMERO DE COMPONENTES DA FAMÍLIA 02
					Branco- para domicílio coletivo"	*/
@131 	V7403 2.	/*	"NÚMERO DE COMPONENTES DA FAMÍLIA 03
					Branco- para domicílio coletivo"	*/
@133 	V7404 2.	/*	"NÚMERO DE COMPONENTES DA FAMÍLIA 04
					Branco- para domicílio coletivo"	*/
@135 	V7405 2.	/*	"NÚMERO DE COMPONENTES DA FAMÍLIA 05
					Branco- para domicílio coletivo"	*/
@137 	V7406 2.	/*	"NÚMERO DE COMPONENTES DA FAMÍLIA 06
					Branco- para domicílio coletivo"	*/
@139 	V7407 2.	/*	"NÚMERO DE COMPONENTES DA FAMÍLIA 07
					Branco- para domicílio coletivo"	*/
@141 	V7408 2.	/*	"NÚMERO DE COMPONENTES DA FAMÍLIA 08
					Branco- para domicílio coletivo"	*/
@143 	V7409 2.	/*	"NÚMERO DE COMPONENTES DA FAMÍLIA 09
					Branco- para domicílio coletivo"	*/
@145 	V7616 6.	/*	TOTAL DE RENDIMENTOS DO DOMICÍLIO PARTICULAR	*/
@151 	V7617 6.2	/*	TOTAL DE RENDIMENTOS DO DOMICÍLIO PARTICULAR, EM SALÁRIOS MÍNIMOS	*/
@157 	P001 11.8	/*	PESO (Peso atribuído ao domicílio)	*/
@168 	V1111 $1.	/*	"EXISTÊNCIA DE IDENTIFICAÇÃO
					1- Sim
					2- Não
					9- Ignorado
					Branco- para domicílio coletivo"	*/
@169 	V1112 $1.	/*	"EXISTÊNCIA DE ILUMINAÇÃO PÚBLICA
					1- Sim
					2- Não
					9- Ignorado
					Branco- para domicílio coletivo"	*/
@170 	V1113 $1.	/*	"EXISTÊNCIA DE CALÇAMENTO/PAVIMENTAÇÃO
					1- Total
					2- Parcial
					3- Não Existe
					9- Ignorado
					Branco- para domicílio coletivo"	*/
;
RUN;

%MEND;

 /* Exemplo de chamada da macro para o Acre
	%LE_DOMIC(\\CHI00534610\Publico_IBGE,12)*/
