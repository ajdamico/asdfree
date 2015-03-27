/****************************   MACRO PARA LEITURA DO ARQUIVO DE FAMILIAS   ********************************************/

/* 	PARÂMETROS DE ENTRADA	

	PASTA - caminho da pasta onde está o arquivo com as informações das famílias da UF desejada.
	UF - código numérico da UF desejada
	
	SAIDA 

	Arquivo FAMILIAS no formato SAS

****************************************************************************************************************************/

%MACRO LE_FAMILIAS(PASTA,UF);

FILENAME FAMILIAS "&PASTA.\FAMI&UF..TXT" LRECL=118;

DATA FAMILIAS;
INFILE FAMILIAS MISSOVER;
INPUT
@1 	V0102 $2.		/*	"UNIDADE DA FEDERAÇÃO
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
					53- Distrito Federal"	*/
@3 	V1002 $4.		/*	"MESORREGIÃO
						A relação encontra-se na pasta “Arquivos Auxiliares” no arquivo “Divisão Territorial Brasileira.xls”"	*/
@7 	V1003 $5.		/*	"MICRORREGIÃO
						A relação encontra-se na pasta “Arquivos Auxiliares” no arquivo “Divisão Territorial Brasileira.xls”"	*/
@12 	V0103 $7.	/*	"MUNICÍPIO
						A relação encontra-se na pasta “Arquivos Auxiliares” no arquivo “Divisão Territorial Brasileira.xls”"	*/
@19 	V0104 $9.	/*	"DISTRITO
						A relação encontra-se na pasta “Arquivos Auxiliares” no arquivo “Divisão Territorial Brasileira.xls”"	*/
@28 	V0105 $11.	/*	"SUDISTRITO
						A relação encontra-se na pasta “Arquivos Auxiliares” no arquivo “Divisão Territorial Brasileira.xls”"	*/
@39 	V0300 8.	/*	CONTROLE	*/
@47 	V0404 2.	/*	> 00 (NÚMERO DE ORDEM DA FAMILIA NO DOMICÍLIO)	*/
@49 	V1001 $1.	/*	"REGIÃO GEOGRÁFICA
						1- Região Norte
						2- Região Nordeste
						3- Região Sudeste
						4- Região Sul
						5- Região Centro-Oeste"	*/
@50 	V1004 $2.	/*	"REGIÃO METROPOLITANA
						01- Belém
						02- Grande São Luís
						03- Fortaleza
						04- Natal
						05- Recife
						06- Maceió
						07- Salvador
						08- Belo Horizonte
						09- Colar Metropolitano da RM de Belo Horizonte
						10- Vale do Aço
						11- Colar Metropolitano da RM do Vale do Aço
						12- Grande Vitória
						13- Rio de Janeiro
						14- São Paulo
						15- Baixada Santista
						16- Campinas
						17- Curitiba
						18- Londrina
						19- Maringá
						20- Florianópolis
						21- Área de Expansão Metropolitana da RM de Florianópolis
						22- Núcleo Metropolitano da RM Vale do Itajaí
						23- Área de Expansão Metropolitana da RM Vale do Itajaí
						24- Norte/Nordeste Catarinense
						25- Área de Expansão Metropolitana da RM Norte/Nordeste Catarinense
						26- Porto Alegre
						27– Goiânia
						28– RIDE (Região Integrada de Desenvolvimento do Distrito Federal e Entorno)
						Branco - Não aplicável"	*/
@52 	AREAP $13.	/*	"ÁREA DE PONDERAÇÃO
						A relação encontra-se na pasta “Arquivos Auxiliares” no arquivo “MUNICÍPIOS COM MAIS DE UMA ÁREA DE PONDERAÇÃO.xls”"	*/
@65 	CODV0404 $1.	/*	"TIPO DE FAMÍLIA (1)
						0- Única (uma só família vive no domicílio)
						1- Famílias conviventes: 1ª família
						2- Famílias conviventes: 2ª família
						3- Famílias conviventes: 3ª família
						4- Famílias conviventes: 4ª família
						5- Famílias conviventes: 5ª família e mais
						9- Morador individual"	*/
@66 	CODV0404_2 $2./*	"TIPO DE FAMÍLIA (2)
						01- Casal sem filhos
						02- Casal com filhos menores de 14 anos
						03- Casal com filhos de 14 anos ou mais
						04- Casal com filhos de idades variadas
						05- Mãe com filhos menores de 14 anos
						06- Mãe com filhos de 14 anos ou mais
						07- Mãe com filhos de idades variadas
						08- Pai com filhos menores de 14 anos
						09- Pai com filhos de 14 anos ou mais
						10- Pai com filhos de idades variadas
						11- Outros tipos de famílias
						12- Morador individual"	*/
@68 	V4614B 7.	/*	RENDIMENTO NOMINAL FAMILIAR	*/
@75 	CODV4615B $2. /*	"CLASSE DE RENDIMENTO NOMINAL FAMILIAR
						01- Até 0,25 salário mínimo
						02- Mais de 0,25 a 0,5 salário mínimo
						03- Mais de 0,5 a 1 salário mínimo
						04- Mais de 1 a 2 salários mínimos
						05- Mais de 2 a 3 salários mínimos
						06- Mais de 3 a 5 salários mínimos
						07- Mais de 5 a 10 salários mínimos
						08- Mais de 10 a 15 salários mínimos
						09- Mais de 15 a 20 salários mínimos
						10- Mais de 20 a 30 salários mínimos
						11- Mais de 30 salários mínimos
						12- Sem rendimento"	*/
@77 	V4614C 7.	/*	RENDIMENTO NOMINAL, RESPONSAVEL/CASAL	*/
@84 	CODV4615C $2. /*	"CLASSE DE RENDIMENTO NOMINAL, RESPONSAVEL/CASAL
						01- Até 0,25 salário mínimo
						02- Mais de 0,25 a 0,5 salário mínimo
						03- Mais de 0,5 a 0,75 salário mínimo
						04- Mais de 0,75 a 1 salário mínimo
						05- Mais de 1 a 1,25 salários mínimos
						06- Mais de 1,25 a 1,5 salários mínimos
						07- Mais de 1,5 a 2 salários mínimos
						08- Mais de 2 a 3 salários mínimos
						09- Mais de 3 a 5 salários mínimos
						10- Mais de 5 a 10 salários mínimos
						11- Mais de 10 a 15 salários mínimos
						12- Mais de 15 a 20 salários mínimos
						13- Mais de 20 a 30 salários mínimos
						14- Mais de 30 salários mínimos
						15- Sem rendimento"	*/
@86 	V4616_7400 8.2 	/*	RENDIMENTO NOMINAL FAMILIAR PER-CAPITA	*/
@94 	CODV4615_7400 $2. /*	"CLASSE RENDIMENTO NOMINAL FAMILIAR PER-CAPITA
						01- Até 0,25 salário mínimo
						02- Mais de 0,25 a 0,5 salário mínimo
						03- Mais de 0,5 a 1 salário mínimo
						04- Mais de 1 a 2 salários mínimos
						05- Mais de 2 a 3 salários mínimos
						06- Mais de 3 a 5 salários mínimos
						07- Mais de 5 a 10 salários mínimos
						08- Mais de 10 a 15 salários mínimos
						09- Mais de 15 a 20 salários mínimos
						10- Mais de 20 a 30 salários mínimos
						11- Mais de 30 salários mínimos
						12- Sem rendimento"	*/
@96 	V7400 2.	/*	NÚMERO DE COMPONENTES DA FAMÍLIA	*/
@98 	CODV7400 $2.	/*	"CLASSE DE NÚMERO DE COMPONENTES
					01- 1 pessoa
					02- 2 pessoas
					03- 3 pessoas
					04- 4 pessoas
					05- 5 pessoas
					06- 6 pessoas
					07- 7 pessoas
					08- 8 pessoas
					09- 9 pessoas
					10- 10 pessoas
					11- 11 pessoas
					12- 12 pessoas
					13- 13 pessoas
					14- 14 pessoas
					15- 15 ou mais pessoas"	*/
@100 	V7400A 2.	/*	NÚMERO DE COMPONENTES HOMENS DA FAMÍLIA	*/
@102 	CODV7400A $2. /*	"CLASSE DE NÚMERO DE COMPONENTES HOMENS DA FAMÍLIA
					00- nenhum
					01- 1 homem
					02- 2 homens
					03- 3 homens
					04- 4 homens
					05- 5 homens
					06- 6 homens
					07- 7 homens
					08- 8 homens
					09- 9 homens
					10- 10 homens
					11- 11 homens
					12- 12 homens
					13- 13 homens
					14- 14 homens
					15- 15 ou mais homens"	*/
@104 	V7400B 2.	/*	NÚMERO DE COMPONENTES MULHERES DA FAMÍLIA	*/
@106 	CODV7400B $2. /*	"CLASSE DE NÚMERO DE COMPONENTES MULHERES DA FAMÍLIA
						00- nenhum
						01- 1 mulher
						02- 2 mulheres
						03- 3 mulheres
						04- 4 mulheres
						05- 5 mulheres
						06- 6 mulheres
						07- 7 mulheres
						08- 8 mulheres
						09- 9 mulheres
						10- 10 mulheres
						11- 11 mulheres
						12- 12 mulheres
						13- 13 mulheres
						14- 14 mulheres
						15- 15 ou mais mulheres"	*/
@108 	P001 11.8	/*	PESO (Peso atribuído ao domicílio)	*/
;
RUN;

%MEND;

 /* Exemplo de chamada da macro para o Acre
	%LE_FAMILIAS(\\CHI00534610\PUBLICO_IBGE,12);*/
