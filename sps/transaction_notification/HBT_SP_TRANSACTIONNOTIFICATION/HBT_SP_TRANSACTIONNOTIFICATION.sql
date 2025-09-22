CREATE 
PROCEDURE HBT_SP_TRANSACTIONNOTIFICATION
 ( in object_type nvarchar(50),
 -- SBO Object Type
in transaction_type nchar(1),
	 -- [A]dd, [U]pdate, [D]elete, [C]ancel, C[L]ose
in num_of_cols_in_key int,
	 in list_of_key_cols_tab_del nvarchar(255),
	 in list_of_cols_val_tab_del nvarchar(255),
	 inout error int,
	 -- Result (0 for no error)
 inout error_message nvarchar (200) -- Error string to be displayed
 ) LANGUAGE SQLSCRIPT AS -- Return values
 --Variables procesos HBT
 cnt int;
 cnt1 int;
 cont int;
 NUMERO_OT int;
 subt int;
 temp_var_0 int;				-- Result (0 for no error)
 ret int;
 ret1 int;
 ret2 int;
 ret3 int;
 serie1 nvarchar(10);
 serie2 nvarchar(10);	
 codart nvarchar(20);	
 v_tiporuc nvarchar(2);
 v_tipcont nvarchar(3);
 v_cnuruc nvarchar(20);
 v_condicion nvarchar(20);
 v_I int;
 v_d1 int;
 v_acumular int;
 v_Intdecena int;
 v_digitover int;
 v_comparador int;
 cnt2 nvarchar (4);
 codcli nvarchar(50);
 listaprecio smallint;
 descuento smallint;
 ItemCode NVARCHAR(20);
 Family NVARCHAR(30);
 PymntGroup NVARCHAR(100);
 MaxDiscPrcnt DECIMAL(19,2);
 Prom DECIMAL(19,2);
 v_clasuj NVARCHAR(10);
 
BEGIN
 --------------------------------LOCALIZACION-------------------------------------------------------
--------------------------------SOCIOS DE NEGOCIO---------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-- Heinsohntech 08-12-2017
-- No permitir registro de SN sin Nombre
IF :object_type='2' --Creacion y actualizacion de SN
AND (:transaction_type='A' OR :transaction_type='U') 
then select count(*) 
into cnt 
FROM OCRD T0 
WHERE T0."CardCode" = :list_of_cols_val_tab_del 
AND (T0."CardName" IS NULL or T0."CardName" = ' ');
	if :cnt > 0 
	then error := -200;
	error_message := 'HBT: El nombre del Socio de Negocios es obligatorio';
	end if;
end if;
 

if :object_type='2' --Creacion y actualizacion de SN
and (:transaction_type='A' or :transaction_type='U') 
then select count(*) 
into cnt 
FROM OCRD T0 
WHERE T0."CardCode" = :list_of_cols_val_tab_del 
AND T0."CardType" <> 'L'
AND (T0."Phone1" IS NULL or T0."Phone1" = ' ');
	if :cnt > 0 
	then error := -201;
	error_message := 'HBT: El campo TELÉFONO 1 es obligatorio en la pestaña de GENERAL';
	end if;
end if;


if :object_type='2' --Creacion y actualizacion de SN
and (:transaction_type='A' or :transaction_type='U') 
then select count(*) 
into cnt 
FROM OCRD T0 
WHERE T0."CardCode" = :list_of_cols_val_tab_del 
AND (T0."E_Mail" IS NULL or T0."E_Mail" = ' ');
	if :cnt > 0 
	then error := -202;
	error_message := 'HBT: El campo E-MAIL es obligatorio en la pestaña de GENERAL';
	end if;
end if;


--Validación campos de usuario socios de negocio

IF :object_type='2'
AND (:transaction_type='A'or :transaction_type='U')
THEN
cnt:=0;
SELECT COUNT (*)
INTO cnt
FROM "OCRD" T0
WHERE T0."CardCode" = :list_of_cols_val_tab_del
AND (T0."U_HBT_TIPCONT" IS NULL OR T0."U_HBT_TIPCONT"='')
AND T0."CardType" <> 'L'
;
	IF :cnt>0
	THEN error := -203;
	error_message := 'SP: Complete campo Tipo Contribuyente';
	END IF;
END IF;

IF :object_type='2'
AND (:transaction_type='A'or :transaction_type='U')
THEN
cnt:=0;
SELECT COUNT (*)
INTO cnt
FROM "OCRD" T0
WHERE T0."CardCode" = :list_of_cols_val_tab_del
AND (T0."U_HBT_TIPPRO" IS NULL OR T0."U_HBT_TIPPRO"=''
OR T0."U_HBT_ATRESI" IS NULL OR T0."U_HBT_ATRESI"='')
AND T0."CardType" = 'S'
AND T0."U_HBT_TIPO_ID"='03'
;
	IF :cnt>0
	THEN error := -204;
	error_message := 'SP: Complete campos Tipo Proveedor y Pago Residente';
	END IF;
END IF;

IF :object_type='2'
AND (:transaction_type='A'or :transaction_type='U')
THEN
cnt:=0;
SELECT COUNT (*)
INTO cnt
FROM "OCRD" T0
WHERE T0."CardCode" = :list_of_cols_val_tab_del
AND (T0."U_HBT_DBL_TRIB" IS NULL OR T0."U_HBT_DBL_TRIB"=''
OR T0."U_HBT_REGFIS" IS NULL OR T0."U_HBT_REGFIS"=''
OR T0."U_HBT_PAIS_PAGO" IS NULL OR T0."U_HBT_PAIS_PAGO"='')
AND T0."CardType" = 'S'
AND T0."U_HBT_ATRESI"='02'
;
	IF :cnt>0
	THEN error := -205;
	error_message := 'SP: Complete campos Doble Tributacion, Registro Fiscal Preferente y Pais Pago';
	END IF;
END IF;


----------------------------------------------------------------------------------------------------------------
---- Validación Proveedores Inicien con 'P'

if :object_type='2' 
and :transaction_type='A'
then SELECT count(*) 
into cnt 
FROM OCRD T0
where T0."CardType" = 'S' 
and T0."CardCode" = :list_of_cols_val_tab_del 
and not(T0."CardCode" like 'P%');
	if :cnt>0 
	then error := -206;
	error_message := 'SP: Codigo del Proveedor debe iniciar con P';
	end if;
END if;

--Validación: Campo tipo de identificación del dato maestro SN

IF :object_type='2' --Creacion y actualizacion de SN
AND (:transaction_type='A' OR :transaction_type='U') 
THEN SELECT COUNT (*) 
INTO cnt 
FROM OCRD T0 
WHERE T0."CardCode"=:list_of_cols_val_tab_del 
AND T0."CardType" <> 'L'
AND (T0."U_HBT_TIPO_ID" IS NULL OR T0."U_HBT_TIPO_ID" = ' ');
	IF :cnt>0 
	THEN error := -207;
	error_message := 'HBT: El campo Tipo de Identificación es obligatorio';
	END IF;
END IF;

--Tatiana Cepeda
--14/10/2014
---Validacion para parte relacionada. sera necesario ingresar la parte relacionada.
 
if :object_type='2' 
and (:transaction_type='A' or :transaction_type='U') 
then select count(*) 
into cnt 
from "OCRD" T0 
where T0."CardCode" = :list_of_cols_val_tab_del
and T0."CardType" <> 'L' 
and (T0."U_HBT_PARTREL" is null OR T0."U_HBT_PARTREL" = ' ');
	if :cnt > 0 
	then error := -208;
	error_message := 'HBT:Debe ingresar si el socio de negocios es Parte Relacionada';
	end if;
end if;

--NO PERMITE SOCIO DE NEGOCIO REPETIDO CON CEDULA O RUC
--Control para evitar duplicar socio de negocio (PROVEEDOR) 

IF :object_type = '2' 
AND ((:transaction_type = 'A' )) 
THEN SELECT
	 COUNT(*) 
INTO cnt 
FROM OCRD T0 
WHERE SUBSTRING(T0."LicTradNum",
	 2,
	 10) = (SELECT
	 SUBSTRING(T1."LicTradNum",
	 2,
	 10) 
	FROM OCRD T1 
	WHERE T1."CardCode" = :list_of_cols_val_tab_del 
	AND T1."CardType" = 'S') 
AND T0."CardCode" <> :list_of_cols_val_tab_del 
AND T0."CardType" = 'S';
 
IF :cnt > 0 
THEN error := -209;
 error_message := 'SP: El proveedor ya existe con este RUC o Cedula';
 
END IF;

END IF;
 ----------------------------------------------------------------------------------------------------------------
--AUTOR: HEINSOHN Leonardo López  
--DESCRIPCION: SP DIGITO VERIFICADOR SOCIOS DE NEGOCIOS
--FECHA: 18/08/2014
----------------------------------------------------------------------------------------------------------------
/*
if :object_type='2' and (:transaction_type='A'	or :transaction_type='U') THEN
	Select T0."LicTradNum"  into v_cnuruc  FROM OCRD T0 WHERE T0."CardCode" = :list_of_cols_val_tab_del;
	Select T1."U_HBT_TIPO_ID", T1."U_HBT_TIPPRO" into v_tiporuc, v_clasuj  FROM  OCRD T1 WHERE T1."CardCode" = :list_of_cols_val_tab_del;

v_comparador := 1;

IF :v_tiporuc <> '01' AND :v_tiporuc <> '02' AND :v_tiporuc <> '03' AND :v_tiporuc <> '07'
THEN
        error_message := 'SP: Tipo de Identificación no valido';
		error := 1;
	
end if;

IF :v_tiporuc = '03' or :v_tiporuc = '07'
THEN
		v_condicion := 'fin';
		v_comparador := 0;
end if;

-- Se valida par el ruc 01 - Ruc - 02 - Cedula - 03 --Pasaporte esto se toma del dato maestro
If :v_tiporuc = '02' THEN
   v_condicion := 'RucPerNat';
else 
	if :v_tiporuc = '01' then
		If :v_clasuj = '' or :v_clasuj is null THEN --Agregado el 130319 
		    error_message := 'SP: Debe seleccionar tipo de socio de negocio en pestaña Localización';
			error := 1;
		else
			If  :v_tiporuc = '01'
			THEN
			     --error_message := (substring(v_cnuruc,11,3 ));
				If LENGTH(rTrim(v_cnuruc )) <> 13
				THEN
					error_message := 'SP: RUC debe tener 13 dígitos';
					error := 1;
					v_condicion := 'fin';
				end if;
				
				if substring(v_cnuruc, 3, 1)= '9'
					THEN
						If substring(v_cnuruc,11,3 ) = '000'
							THEN
								error_message := 'SP:RUC debe tener por lo menos una principal';
								error := 1;
								v_condicion := 'fin';
							
						else
							v_condicion := 'RucSocPri';
						end if;	
				--	end if;	
				else
					if substring(v_cnuruc, 3, 1)= '6' and v_clasuj = '02' --Agregado el 130319 
					THEN
							If substring(v_cnuruc,10,4 ) = '0000' THEN
									error_message := 'SP:RUC debe tener por lo menos una principal';
									error := 1;
									v_condicion := 'fin';
							else
							   v_condicion := 'RucSocPub';
							end if;	
					--end if;	
					else
						if substring(v_cnuruc, 3, 1) <= '6' AND v_clasuj = '01' --Agregado el 130319 <= 6 and v_clasuj = '01'
							THEN
								If substring(v_cnuruc,11,3 ) = '000'
									THEN
										error_message := 'SP:RUC debe tener por lo menos una principal';
										error := 1;
										v_condicion := 'fin'; 		
								else
								   v_condicion := 'RucPerNat';
								end if;
						else
							error_message := 'SP:Verificar campo RUC y Clase de Sujeto';
							error := 1;
						end if;
					end if;
				end if;
			end if;
		end if;
	end if;
end if;

if :v_condicion ='RucSocPub'
THEN
	 v_d1 := TO_INTEGER((substring(v_cnuruc, 1, 1))) * 3;
	 v_d1 := v_d1 + TO_INTEGER((substring(v_cnuruc, 2, 1))) * 2;
	 v_d1 := v_d1 + TO_INTEGER((substring(v_cnuruc, 3, 1))) * 7;
	 v_d1 := v_d1 + TO_INTEGER((substring(v_cnuruc, 4, 1))) * 6;
	 v_d1 := v_d1 + TO_INTEGER((substring(v_cnuruc, 5, 1))) * 5;
	 v_d1 := v_d1 + TO_INTEGER((substring(v_cnuruc, 6, 1))) * 4;
	 v_d1 := v_d1 + TO_INTEGER((substring(v_cnuruc, 7, 1))) * 3;
	 v_d1 := v_d1 + TO_INTEGER((substring(v_cnuruc, 8, 1))) * 2;
	 v_d1 := mod(v_d1,11);
	If :v_d1 <> 0
	THEN
	   	v_digitover := 11 - v_d1;
	Else
	   	v_digitover := 0;
	END IF;	
		If TO_INT((substring(v_cnuruc,9,1))) <> v_digitover
		   THEN
			 error_message := 'SP:Digito Verificador Incorrecto, entidad publica';
			 error := 1;
		   END IF;	
		v_condicion := 'fin';
END IF;


if :v_condicion ='RucSocPri'
THEN
	 v_d1 := TO_INTEGER((substring(v_cnuruc, 1, 1))) * 4;
	 v_d1 := v_d1 + TO_INTEGER((substring(v_cnuruc, 2, 1))) * 3;
	 v_d1 := v_d1 + TO_INTEGER((substring(v_cnuruc, 3, 1))) * 2;
	 v_d1 := v_d1 + TO_INTEGER((substring(v_cnuruc, 4, 1))) * 7;
	 v_d1 := v_d1 + TO_INTEGER((substring(v_cnuruc, 5, 1))) * 6;
	 v_d1 := v_d1 + TO_INTEGER((substring(v_cnuruc, 6, 1))) * 5;
	 v_d1 := v_d1 + TO_INTEGER((substring(v_cnuruc, 7, 1))) * 4;
	 v_d1 := v_d1 + TO_INTEGER((substring(v_cnuruc, 8, 1))) * 3;
	 v_d1 := v_d1 + TO_INTEGER((substring(v_cnuruc, 9, 1))) * 2;
	 v_d1 := mod(v_d1,11);
	If v_d1 <> 0
      THEN
	    v_digitover := 11 - v_d1;
	
	Else
	    v_digitover := 0;
	
    END IF;
	If TO_INTEGER((substring(v_cnuruc, 10, 1))) <> v_digitover
	   THEN
		 error_message := 'SP:Digito Verificador Incorrecto, entidad Privada';
		 error := 1;
	   END IF;
	  	
	v_condicion := 'fin';

END IF;

if :v_condicion ='RucPerNat'
THEN
	 v_I := 1;
	 v_acumular := 0;
	 v_comparador :=1;
		If :v_tiporuc = '02' and  LENGTH(rTrim(v_cnuruc ))<>10
			THEN
				error_message := 'SP:Longitud del CI Incorrecta,Persona Natural';
				error := 1;
				v_comparador :=0;
				v_condicion := 'fin';
			END IF;
		If :v_tiporuc = '01' and  LENGTH(rTrim(v_cnuruc ))<>13
			THEN
				error_message := 'SP:Longitud del RUC Incorrecta,Persona Natural';
				error := 1;
				v_comparador :=0;
				v_condicion := 'fin';
			END IF;
			
					WHILE :v_I < 10 DO
						 If mod(v_I,2) <> 0
						  THEN
							  v_d1 := TO_INTEGER((substring(v_cnuruc, v_I, 1))) * 2;
						  Else
							  v_d1 := TO_INTEGER((substring(v_cnuruc, v_I, 1))) * 1;
						  END IF;
						
						  If v_d1 >= 10
						   THEN
							 v_d1 := TO_INTEGER((substring(TO_VARCHAR(v_d1), 1, 1))) + TO_INTEGER((substring(TO_VARCHAR (v_d1), 2, 1)));
						   END IF;
							v_acumular := v_acumular + v_d1;
							v_I := v_I +1;
					END WHILE;
			If substring(TO_VARCHAR(v_acumular), 2, 1) = '0'
				THEN
						 v_digitover := 0;
					Else
						 v_Intdecena := mod(v_acumular,10);
						 v_digitover := (10 - v_Intdecena );
				END IF;

			If TO_INT((substring(v_cnuruc, 10, 1))) <> v_digitover and :v_comparador = 1
				THEN
					   error_message := 'SP:Digito Verificador Incorrecto,Persona Natural ';
					   error := 1;
				END IF;
END IF;
end if;
*/ 


---------------------------------------------------------------------Fin Digito Verificador---------------------------------------
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
--AUTOR:  (HEINSOHNTHECH)
--DESCRIPCION: Forma de pago obligatoria en Factura de Venta
--FECHA:            
----------------------------------------------------------------------------------------------------------------

if :object_type='13' 
and (:transaction_type='A' 
	or :transaction_type='U') 
then cnt:=0
;
 SELECT
	 COUNT(OINV."DocNum") 
INTO cnt 
FROM OINV 
WHERE OINV."DocEntry" =:list_of_cols_val_tab_del 
AND IFNULL(OINV."U_HBT_FP",	'')= ''; 
 
if :cnt>0 
then error := -211;
 error_message := 'SP: La forma de Pago es Obligatoria.';
 
end if; 

end if;
 ----------------------------------------------------------------------------------------------------------------
--AUTOR:  (HEINSOHNTHECH)
--DESCRIPCION: Forma de pago obligatoria en Factura de Compra
--FECHA:            
----------------------------------------------------------------------------------------------------------------

if :object_type='18' 
and (:transaction_type='A' 
	or :transaction_type='U') 
then cnt:=0
;
 SELECT
	 COUNT(OPCH."DocNum") 
INTO cnt 
FROM OPCH 
WHERE OPCH."DocEntry" =:list_of_cols_val_tab_del 
AND IFNULL(OPCH."U_HBT_FP",	'')= ''; 
 
if :cnt>0 
then error := -212;
error_message := 'SP: La forma de Pago es Obligatoria.';
 
end if; 

end if;
--Para el tipo de Comprobante Liquidacion de Compras el SN no debe tener tipo de Identificacion RUC

IF ((:transaction_type = 'A' 
		OR :transaction_type = 'U') 
	AND :object_type = '18') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM OPCH T0 
inner join OCRD T1 ON T0."CardCode"=T1."CardCode" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."U_HBT_TIP_COMP"='03' 
AND T1."U_HBT_TIPO_ID"='01' 
AND "CANCELED"='N';
 
IF :cnt > 0 
THEN error := -213;
 error_message := 'SP: Para el tipo de Comprobante Liquidacion de Compras el SN no debe tener tipo de Identificacion RUC';
 
END IF;

END IF;
--------------------------------FACTURA DE PROVEEDORES----------------------------------------------------------
--Erley Peña  01/03/2014
--No permite número de factura, sustento tributario o tipo de comprobante vacios

IF :object_type='18' --Factura proveedores

AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM "OPCH" T0 
INNER JOIN "PCH1" T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND "CANCELED"='N' --AND T0."Series"<>115

AND (T0."NumAtCard" IS NULL 
	OR T0."U_HBT_SUS_TRIB" IS NULL 
	OR T0."NumAtCard"='' 
	OR T0."U_HBT_TIP_COMP" IS NULL);
 
IF :cnt>0 
THEN error := -214;
 error_message := 'SP: No se permite número de factura, sustento tributario o tipo de comprobante vacíos';
 
END IF;

END IF;
----------------------------------------------------------------------------------------------------------------
--- No debe dejar crear el mismo numero de factura al mismo proveedor.
----Tatiana Cepeda
--14/010/2014

IF :object_type='18' --Factura proveedores

AND (:transaction_type='A') 
THEN DECLARE v_NroFact VARCHAR(100);
 DECLARE CardCode VARCHAR(100);
 DECLARE Serie VARCHAR(100);
 DECLARE est VARCHAR(100);
 DECLARE aut VARCHAR(100);
 SELECT
	 T0."NumAtCard",
	 T0."CardCode",
	 T0."U_HBT_SER_EST",
	 T0."U_HBT_PTO_EST",
	 T0."U_HBT_AUT_FAC" 
INTO v_NroFact,
	 CardCode,
	 Serie,
	 est,
	 aut 
FROM "OPCH" T0 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
 --and "CANCELED"='N';
 
IF :v_NroFact IS NOT NULL 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM "OPCH" T0 
WHERE T0."NumAtCard" = :v_NroFact 
AND T0."CardCode" = :CardCode 
AND T0."CANCELED"='N' 
AND T0."U_HBT_SER_EST"= :Serie 
AND T0."U_HBT_PTO_EST"= :est 
AND "U_HBT_SUS_TRIB" <> 99;
 
IF :cnt > 1 
THEN error := -215;
 error_message := 'SP: Ya existe la factura '|| :v_NroFact ||' para el proveedor '|| :CardCode ||', ingrese otro numero';
 cnt := 0;
 
END IF;
 
END IF;

END IF;
 ----------------------------------------------------------------------------------------------------------------
--Erley Peña  01/03/2014
--Validación facturación proveedores longitud de autorización y serie (socios de negocio con retención).

IF :object_type='18' 
AND (:transaction_type='A' 
	OR :transaction_type='U') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM "OPCH" T0 
INNER JOIN "PCH1" T1 ON T0."DocEntry"=T1."DocEntry" 
INNER JOIN "OCRD" T2 ON T0."CardCode"=T2."CardCode" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T2."WTLiable"='Y' 
AND T0."U_HBT_TIP_COMP" NOT IN ('99') 
AND "CANCELED"='N' 
AND (LENGTH(T0."U_HBT_AUT_FAC") NOT IN (10,	37,	49) 
	OR LENGTH(T0."U_HBT_SER_EST")<> (3) 
	OR LENGTH(T0."U_HBT_PTO_EST")<> (3) 
	OR (T0."U_HBT_AUT_FAC")= '' 
	OR (T0."U_HBT_SER_EST")= '' 
	OR (T0."U_HBT_PTO_EST")= '' 
	OR (T0."U_HBT_AUT_FAC") IS null 
	OR (T0."U_HBT_SER_EST") IS null 
	OR (T0."U_HBT_PTO_EST") IS null );
 
IF :cnt>0 
THEN error := -216;
 error_message := 'SP: Revise longitud Autorización Factura (10,37,49), Serie o Punto Emisión (3)';
 
END IF;

END IF;
----------------------------------------------------------------------------------------------------------------
--Erley Peña  01/03/2014
--Validación facturación proveedores socios de negocio sin retención.

IF :object_type='18' 
AND (:transaction_type='A' 
	OR :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt 
FROM "OPCH" T0 
INNER JOIN "PCH1" T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T1."WtLiable"='N' 
AND "CANCELED"='N' 
AND T0."U_HBT_TIP_COMP" NOT IN ('99') 
AND ((T0."U_HBT_COM_RET") IS NOT NULL 
	OR (T0."U_HBT_SER_RET1") IS NOT NULL 
	OR (T0."U_HBT_PTO_RET1") IS NOT NULL)
;
 
IF :cnt>0 
THEN error := -217;
 error_message := 'SP: Proveedor sin retención no aplica detalle retención';
 
END IF;
END IF;
----------------------------------------------------------------------------------------------------------------
--Erley Peña  01/03/2014
--Validación tipo de sustento comprobante para retención

IF :object_type='18' 
AND (:transaction_type='A' 
	OR :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt 
FROM "OPCH" T0 
INNER JOIN "PCH1" T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."WTSum" >0 
AND "CANCELED"='N' 
AND ((T0."U_HBT_SUS_TRIB" IN ('00','05','08','09','99')
		OR T0."U_HBT_TIP_COMP" NOT IN ('01','03')) 
	AND T0."U_HBT_TIP_COMP" NOT IN ('05','01','03'));
 
IF :cnt>0 
THEN error := -218;
 error_message := 'SP: Tipo de comprobante diferente(01,03,05) o sustento es (00,05,08,09,99) para comprobante (01,03) . No aplica para retención';
 
END IF;
END IF;
 --Campos obligatorios para ATS en Notas de Credito de proveedores
--30/04/2015
--06/05/2015 ACTUALIZADO
 
IF :object_type='19' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM ORPC T0 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."U_HBT_TIDOMO" IS NULL 
AND T0."U_HBT_SUS_TRIB" <> 99 
AND T0."CANCELED"='N';
 
IF :cnt>0 
THEN error := -219;
 error_message := 'SP: Debe escoger el Tipo de Comprobante Modificado';
END IF;
END IF;
---------------------------------------
IF :object_type='19' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM ORPC T0 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND (T0."U_HBT_PUFAMO" IS NULL --(PUNTO EMISION MOD
 	OR T0."U_HBT_EST_MOD" IS NULL --(No SERIE COMP MOD)
 	OR T0."U_HBT_AUFAMO" IS NULL --(NO AUT MODIFICADO)
) 
AND T0."U_HBT_SUS_TRIB" <> 99 
AND "CANCELED"='N';
 
IF :cnt>0 
THEN error := -220;
error_message := 'SP: Debe de llenar establecimiento comp. modificado, punto de emision comp modificado y autorización comp. modificado';
 
END IF;	
END IF;
 --------------------------------------
IF :object_type='19' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM ORPC T0 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND (T0."U_HBT_NUFAMO" IS NULL --(SECUENCIAL DEL COMP
 	OR T0."U_HBT_AUT_FAC" IS NULL --(NO AUTORIZACION)
)
AND T0."U_HBT_SUS_TRIB" <> 99 
AND "CANCELED"='N';
 
IF :cnt>0 
THEN error := -221;
error_message := 'SP: Debe de llenar el secuencial comp. modificado y el numero de autorizacion de la NC';
 
END IF;
END IF;		
------------------------------------ 
IF :object_type='19' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM ORPC T0 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND (T0."U_HBT_SER_EST" IS NULL --(SERIE ESTABLECIMIENTO
	OR T0."U_HBT_PTO_EST" IS NULL --(PUNTO ESTABLECIMIENTO
 ) 
AND T0."U_HBT_SUS_TRIB" <> 99 
AND "CANCELED"='N';
 
IF :cnt>0 
THEN error := -222;
 error_message := 'SP: Debe llenar establecimeinto y punto de emisión de NC';
 
END IF;
END IF;
--Datos obligatorios para NC clientes ATS
--04/05/2015
 
IF :object_type='14' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM ORIN T0 
INNER JOIN RIN1 T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T1."BaseType" <> 13 
AND (T0."U_HBT_TIDOMO" IS NULL --(TIPO COMP MOD
 ) 
AND "CANCELED"='N' 
AND ("U_HBT_TIP_COMP" NOT IN (99) 
	OR "U_HBT_TIP_COMP" IS NULL);
 
IF :cnt>0 
THEN error := -223;
 error_message := 'SP: Debe escoger el Tipo de Comprobante Modificado';
 
END IF;

END IF;
 -----------------------------
IF :object_type='14' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM ORIN T0 
INNER JOIN RIN1 T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T1."BaseType" <> 13 
AND (T0."U_HBT_PUFAMO" IS NULL --(PUNTO EMISION MOD
 	OR T0."U_HBT_EST_MOD" IS NULL --(No SERIE COMP MOD)
 ) 
AND "CANCELED"='N' 
AND ( "U_HBT_TIP_COMP" NOT IN (99) 
	OR "U_HBT_TIP_COMP" IS NULL);
 
if :cnt>0 
then error := -224;
 error_message := 'SP: Debe de llenar establecimiento comp. modificado y punto de emision comp. modificado';
 
END IF;
END IF;
 --------------------------
IF :object_type='14' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM ORIN T0 
INNER JOIN RIN1 T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T1."BaseType" <> 13 
AND (T0."U_HBT_NUFAMO" IS NULL --(SECUENCIAL DEL COMP)
 ) 
AND "CANCELED"='N' 
AND ("U_HBT_TIP_COMP" NOT IN (99) 
	OR "U_HBT_TIP_COMP" IS NULL);
 
IF :cnt>0 
THEN error := -225;
 error_message := 'SP: Debe de llenar secuencial del comprobante modificado';
 
END IF;
END IF;		
----------------------------- 
IF :object_type='14' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM ORIN T0 
INNER JOIN RIN1 T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T1."BaseType" <> 13 
AND (T0."U_HBT_FEDOMO" IS NULL --(FECHA DOCUMENTO SUSTENTO.
 ) 
AND "CANCELED"='N' 
AND ( "U_HBT_TIP_COMP" NOT IN (99) 
	OR "U_HBT_TIP_COMP" IS NULL);
 
IF :cnt>0 
THEN error := -226;
 error_message := 'SP: Debe llenar fecha comp. modificado';
END IF;
END IF;
 --------------------------
IF :object_type='14' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM ORIN T0 
INNER JOIN RIN1 T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T1."BaseType" <> 13 
AND (T0."Comments" IS NULL --Comentario
 ) 
AND "CANCELED"='N' 
AND ( "U_HBT_TIP_COMP" NOT IN (99) 
	OR "U_HBT_TIP_COMP" IS NULL);
 
IF :cnt>0 
THEN error := -227;
 error_message := 'SP: Debe llenar el comentario del documento';
 END IF;
END IF;
 ----------------------------------------------------------------------------------------------------------------
--Erley Peña  01/03/2014
--Validación Comprobantes tipo de sustento 01-Crédito Tributario para declaración de IVA

if :object_type='18' 
and (:transaction_type='A' 
	or :transaction_type='U') 
then select
	 count(*) 
into cnt 
from "OPCH" T0 
inner join "PCH1" T1 on T0."DocEntry"=T1."DocEntry" 
where T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."U_HBT_SUS_TRIB"='01' 
AND "CANCELED"='N' 
AND T0."U_HBT_TIP_COMP" NOT IN ('01','02','03','04','05','11','12','21','41','43','47','48');

if :cnt>0 
then error := -228;
error_message := 'SP: Comprobante no aplica sustento tributario 01-Crédito Tributario para declaración de IVA' ;

end if;
end if;
----------------------------------------------------------------------------------------------------------------
--Erley Peña  01/03/2014
--Validación Comprobantes tipo de sustento 02-Costo o Gasto para declaración de IR

if :object_type='18' 
and (:transaction_type='A' 
	or :transaction_type='U') 
then select
	 count(*) 
into cnt 
from "OPCH" T0 
inner join "PCH1" T1 on T0."DocEntry"=T1."DocEntry" 
where T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."U_HBT_SUS_TRIB"='02' 
AND "CANCELED"='N' 
AND T0."U_HBT_TIP_COMP" NOT IN ('01','02','03','04','05','11','12','15','19','20','21','41','43','47','48');

if :cnt>0 
then error := -229;
error_message := 'SP: Comprobante no aplica sustento tributario 02-Costo o Gasto para declaración de IR' ;

end if;
end if;
----------------------------------------------------------------------------------------------------------------
--Erley Peña  01/03/2014
--Validación Comprobantes tipo de sustento 03-Activo Fijo - Crédito Tributario para declaración de IVA

if :object_type='18' 
and (:transaction_type='A' 
	or :transaction_type='U') 
then select
	 count(*) 
into cnt 
from "OPCH" T0 
inner join "PCH1" T1 on T0."DocEntry"=T1."DocEntry" 
where T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."U_HBT_SUS_TRIB"='03' 
AND "CANCELED"='N' 
AND T0."U_HBT_TIP_COMP" NOT IN ('01','03','04','05','41','47','48');

if :cnt>0 
then error := -230;
error_message := 'SP: Comprobante no aplica sustento tributario 03-Activo Fijo - Crédito Tributario para declaración de IVA';

end if;
end if;
----------------------------------------------------------------------------------------------------------------
--Erley Peña 01/03/2014
--Validación Comprobantes tipo de sustento 04-Activo Fijo - Costo o Gasto para declaración de IR

if :object_type='18' 
and (:transaction_type='A' 
	or :transaction_type='U') 
then select
	 count(*) 
into cnt 
from "OPCH" T0 
inner join "PCH1" T1 on T0."DocEntry"=T1."DocEntry" 
where T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."U_HBT_SUS_TRIB"='04' 
AND "CANCELED"='N' 
AND T0."U_HBT_TIP_COMP" NOT IN ('01','02','03','04','05','15','41','47','48');

if :cnt>0 
then error := -231;
error_message := 'SP: Comprobante no aplica sustento tributario 04-Activo Fijo - Costo o Gasto para declaración de IR';

end if;
end if;
----------------------------------------------------------------------------------------------------------------
--Erley Peña  01/03/2014
--Validación Comprobantes tipo de sustento 05-Liquidación Gastos de Viaje, hospedaje y alimentación Gastos IR

if :object_type='18' 
and (:transaction_type='A' 
	or :transaction_type='U') 
then select
	 count(*) 
into cnt 
from "OPCH" T0 
inner join "PCH1" T1 on T0."DocEntry"=T1."DocEntry" 
where T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."U_HBT_SUS_TRIB"='05' 
AND "CANCELED"='N' 
AND T0."U_HBT_TIP_COMP" NOT IN ('01','02','03','04','05','11','15','41');

if :cnt>0 
then error := -232;
error_message := 'SP: Comprobante no aplica sustento tributario 05-Liquidación Gastos de Viaje, hospedaje y alimentación Gastos IR';

end if;
end if ;
----------------------------------------------------------------------------------------------------------------
--Erley Peña  01/03/2014
--Validación Comprobantes tipo de sustento 06- Inventario - Crédito Tributario para declaración de IVA

if :object_type='18' 
and (:transaction_type='A' 
	or :transaction_type='U') 
then select
	 count(*) 
into cnt 
from "OPCH" T0 
inner join "PCH1" T1 on T0."DocEntry"=T1."DocEntry" 
where T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."U_HBT_SUS_TRIB"='06' 
AND "CANCELED"='N' 
AND T0."U_HBT_TIP_COMP" NOT IN ('01','03','04','05','41','43','47','48');

if :cnt>0 
then error := -233;
error_message := 'SP: Comprobante no aplica sustento tributario 06- Inventario - Crédito Tributario para declaración de IVA';

end if;
end if;
----------------------------------------------------------------------------------------------------------------
--Erley Peña  01/03/2014
--Validación Comprobantes tipo de sustento 07-  Inventario - Costo o Gasto para declaración de IR

if :object_type='18' --Factura de proveedores

and (:transaction_type='A' 
	or :transaction_type='U') 
then select
	 count(*) 
into cnt 
from "OPCH" T0 
inner join "PCH1" T1 on T0."DocEntry"=T1."DocEntry" 
where T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."U_HBT_SUS_TRIB"='07' 
AND "CANCELED"='N' 
AND T0."U_HBT_TIP_COMP" NOT IN ('01','02','03','04','05','15','41','43','47','48');

if :cnt>0 
then error := -234;
error_message := 'SP: Comprobante no aplica sustento tributario 07-  Inventario - Costo o Gasto para declaración de IR';

end if;
end if;
----------------------------------------------------------------------------------------------------------------
--Erley Peña  01/03/2014
--Validación Comprobantes tipo de sustento 08-  Inventario - Costo o Gasto para declaración de IR

if :object_type='18' --Factura de proveedores
and (:transaction_type='A' 	or :transaction_type='U') 
then select
	 count(*) 
into cnt 
from "OPCH" T0 
inner join "PCH1" T1 on T0."DocEntry"=T1."DocEntry" 
where T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."U_HBT_SUS_TRIB"='08' 
AND "CANCELED"='N' 
AND T0."U_HBT_TIP_COMP" NOT IN ('01','02','03','04','05','21');

if :cnt>0 
then error := -235;
error_message := 'SP: Comprobante no aplica sustento tributario 08-  Inventario - Costo o Gasto para declaración de IR';

end if;
end if ;
----------------------------------------------------------------------------------------------------------------
--Erley Peña  01/03/2014
--Validación Comprobantes tipo de sustento 09-Reembolso por Siniestros

if :object_type='18' --Factura de proveedores
and (:transaction_type='A' 	or :transaction_type='U') 
then select
	 count(*) 
into cnt 
from "OPCH" T0 
inner join "PCH1" T1 on T0."DocEntry"=T1."DocEntry" 
where T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."U_HBT_SUS_TRIB"='09' 
AND "CANCELED"='N' 
AND T0."U_HBT_TIP_COMP" NOT IN ('45','04','05');

if :cnt>0 
then error := -236;
error_message := 'SP: Comprobante no aplica sustento tributario 09-Reembolso por Siniestros';
end if;
end if;
----------------------------------------------------------------------------------------------------------------
--Erley Peña  01/03/2014
--Validación Comprobantes tipo de sustento 10-Distribución de Dividendos, Beneficios o Utilidades

if :object_type='18' --Factura de proveedores

and (:transaction_type='A' 
	or :transaction_type='U') 
then select
	 count(*) 
into cnt 
from "OPCH" T0 
inner join "PCH1" T1 on T0."DocEntry"=T1."DocEntry" 
where T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."U_HBT_SUS_TRIB"='10' 
AND "CANCELED"='N' 
AND T0."U_HBT_TIP_COMP" NOT IN ('19');

if :cnt>0 
then error := -237;
error_message := 'SP: Comprobante no aplica sustento tributario 10-Distribución de Dividendos, Beneficios o Utilidades';
end if;
end if;
----------------------------------------------------------------------------------------------------------------
 --Erley Peña  01/03/2014
--Validación Comprobantes tipo de sustento 00-Casos especiales

if :object_type='18' --Factura de proveedores

and (:transaction_type='A' 
	or :transaction_type='U') 
then select
	 count(*) 
into cnt 
from "OPCH" T0 
inner join "PCH1" T1 on T0."DocEntry"=T1."DocEntry" 
where T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."U_HBT_SUS_TRIB"='00' 
AND "CANCELED"='N' 
AND T0."U_HBT_TIP_COMP" NOT IN ('01','02','04','05','42');

if :cnt>0 
then error := -238;
error_message := 'SP: Comprobante no aplica sustento tributario 00-Casos especiales';

end if;
end if;
---- validacion de NumAtCard
------En la OPCH

if :object_type='18' 
and (:transaction_type='A' 
	or :transaction_type='U') 
then select
	 COUNT(*) 
into cnt 
FROM OPCH T0 
WHERE "DocEntry" = :list_of_cols_val_tab_del 
AND (length("NumAtCard")<> 9 
	OR ("NumAtCard") IS NULL) 
AND "CANCELED"='N' 
AND "U_HBT_SUS_TRIB" <> 99;
 
if :cnt > 0 
then error := -239;
 error_message := 'SP: La referencia del documento debe ser igual a 9';
 
end if;
end if;	
 ---En las NC
 
if :object_type='19' 
and (:transaction_type='A' 
	or :transaction_type='U') 
then select
	 COUNT(*) 
into cnt 
FROM ORPC T0 
WHERE "DocEntry" = :list_of_cols_val_tab_del 
AND (length("NumAtCard")<> 9 
	OR ("NumAtCard") IS NULL) 
AND "CANCELED"='N' 
AND "U_HBT_SUS_TRIB" <> 99;
 
if :cnt > 0 
then error := -240;
 error_message := 'SP: La referencia del documento debe ser igual a 9';
 
end if;
end if;
 --- Tatiana Cepeda Pozo
---22/06/2015
 
if :object_type='18' 
and (:transaction_type='A' 
	or :transaction_type='U') 
then select
	 count(*) 
into cnt2 
FROM OPCH T0 
where T0."DocEntry" = :list_of_cols_val_tab_del 
AND "U_HBT_TIP_COMP"='05' 
AND "U_HBT_SUS_TRIB" NOT IN (99) 
AND "CANCELED"='N' 
AND ( T0."U_HBT_NUFAMO" IS NULL --(SECUENCIAL DEL COMP
 	OR T0."U_HBT_TIDOMO" IS NULL --(NO AUTORIZACION)
 ) 
AND "CANCELED"='N';

if :cnt2>0 
then error := -241;
error_message := 'SP: Debe de llenar el secuencial del comprobante y el tipo de comprobante modificado.';
 
END IF;
 cnt:=0;
select
	 count(*) 
into cnt 
FROM OPCH T0 
where T0."DocEntry" = :list_of_cols_val_tab_del 
AND "U_HBT_TIP_COMP"='05' 
AND "U_HBT_SUS_TRIB" NOT IN (99) 
AND "CANCELED"='N' 
AND ( T0."U_HBT_PUFAMO" IS NULL --(PUNTO EMISION MOD
 	OR T0."U_HBT_EST_MOD" IS NULL --(No SERIE COMP MOD)
 	OR T0."U_HBT_AUFAMO" IS NULL --(NO AUT MODIFICADO)
 ) 
AND "CANCELED"='N';

if :cnt>0 
then error := -242;
error_message := 'SP: Debe de llenar el No de Serie de Comprobante modificado , Punto de emision Modificado y No Aut Modificado.'; 
END IF;
END IF;
 -------------------------------------------------------------------------------------------------------------------------
--------------------------------FACTURA DE PROVEEDORES REEMBOLSOS---------------------------------
-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------
 
IF :object_type='18' 
AND (:transaction_type='A') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM "OPCH" T0 
INNER JOIN "PCH1" T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND "CANCELED"='N' 
AND T0."U_HBT_TIP_COMP"='41' 
AND (T1."U_HBT_IDPRRE" IS NULL 
	OR T1."U_HBT_NOPRRE" IS NULL 
	OR T1."U_HBT_TIPO_ID" IS NULL);

IF :cnt>0 
THEN error := -243;
error_message := 'HBT: No se permite ID PROVEEDOR REEMBOLSO, NOMBRE PROVEEDOR REEMBOLSO, TIPO DE ID vacios';

END IF;
END IF;
 -------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------

IF :object_type='18' 
AND (:transaction_type='A') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM "OPCH" T0 
INNER JOIN "PCH1" T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND "CANCELED"='N' 
AND T0."U_HBT_TIP_COMP"='41' 
AND (T1."U_HBT_SEREST" IS NULL 
	OR T1."U_HBT_PUNEMI" IS NULL 
	OR T1."U_HBT_NUMFAC" IS NULL);

IF :cnt>0 
THEN error := -244;
error_message := 'HBT: No se permite SERIE DEL ESTABLECIMIENTO, PUNTO DEL ESTABLECIMIENTO Y NÚMERO DE FACTURA DEL REEMBOLSO vacios';

END IF;
END IF;
 -------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------

IF :object_type='18' 
AND (:transaction_type='A') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM "OPCH" T0 
INNER JOIN "PCH1" T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND "CANCELED"='N' 
AND T0."U_HBT_TIP_COMP"='41' 
AND (LENGTH(T1."U_HBT_NUMFAC"))<> (9);

IF :cnt>0 
THEN error := -245;
error_message := 'HBT: El NÚMERO DE FACTURA DE REEMBOLSO debe ser igual a 9 digitos';

END IF;
END IF;
 -------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------

IF :object_type='18' 
AND (:transaction_type='A') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM "OPCH" T0 
INNER JOIN "PCH1" T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND "CANCELED"='N' 
AND T0."U_HBT_TIP_COMP"='41' 
AND T1."U_HBT_TIPO_ID"='02' 
AND (LENGTH(T1."U_HBT_NUMFAC")) <> (10);

IF :cnt>0 
THEN error := -246;
error_message := 'HBT: La identificación del proveedor de reembolso deber ser 10 digitos cuando el tipo de identificación es Cédula';

END IF;
END IF;
 -------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------

IF :object_type='18' 
AND (:transaction_type='A') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM "OPCH" T0 
INNER JOIN "PCH1" T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND "CANCELED"='N' 
AND T0."U_HBT_TIP_COMP"='41' 
AND T1."U_HBT_TIPO_ID"='01' 
AND (LENGTH(T1."U_HBT_NUMFAC")) <> (13);

IF :cnt>0 
THEN error := -247;
error_message := 'HBT: La identificación del proveedor de reembolso deber ser 13 digitos cuando el tipo de identificación es RUC';

END IF;
END IF;
 -------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------

IF :object_type='18' 
AND (:transaction_type='A') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM "OPCH" T0 
INNER JOIN "PCH1" T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND "CANCELED"='N' 
AND T0."U_HBT_TIP_COMP"='41' 
AND (T1."U_HBT_FECEMI" IS NULL 
	OR T1."U_HBT_AUFARE" IS NULL 
	OR T1."U_HBT_TIPCOM" IS NULL);

IF :cnt>0 
THEN error := -248;
error_message := 'HBT: No se permite FECHA FACTURA REEMBOLSO, AUTORIZACIÓN FACTURA REEMBOLSO Y TIPO DE COMPROBANTE REEMBOLSO vacios';

END IF;
END IF;
 -------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------

IF :object_type='18' 
AND (:transaction_type='A') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM "OPCH" T0 
INNER JOIN "PCH1" T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND "CANCELED"='N' 
AND T0."U_HBT_TIP_COMP"='41' 
AND (LENGTH(T1."U_HBT_AUFARE")) NOT IN (10,37,49);

IF :cnt>0 
THEN error := -249;
error_message := 'SP: Revise longitud AUTORIZACIÓN FACTURA REEMBOLSO debe ser (10,37,49)';

END IF;
END IF;
 -------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------

IF :object_type='18' 
AND (:transaction_type='A') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM "OPCH" T0 
INNER JOIN "PCH1" T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND "CANCELED"='N' 
AND T0."U_HBT_TIP_COMP"='41' 
AND (T1."U_HBT_BAIV12" IS NULL 
	OR T1."U_HBT_MONIVA" IS NULL);

IF :cnt>0 
THEN error := -250;
error_message := 'HBT: No se permite  BASE DISTINTA DE 0% REEMBOLSO, MONTO IVA REEMBOLSO vacios';

END IF;
END IF;
 ----------------------------------------------------------------------------------------------------------------
--Campos obligatorios para ATS en Notas de Credito de proveedores
--30/04/2015
--06/05/2015 ACTUALIZADO
 
IF :object_type='19' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM ORPC T0 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND (T0."U_HBT_TIDOMO" IS NULL 
	OR T0."U_HBT_TIDOMO"='') 
AND T0."U_HBT_SUS_TRIB" <> 99 
AND T0."CANCELED"='N';
 
IF :cnt>0 
THEN error := -251;
 error_message := 'SP: Debe escoger el Tipo de Comprobante Modificado';
 
END IF;
END IF;
 ---------------------
IF :object_type='19' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM ORPC T0 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND (T0."U_HBT_PUFAMO" IS NULL 
	OR T0."U_HBT_PUFAMO"='' 
	OR T0."U_HBT_EST_MOD" IS NULL 
	OR T0."U_HBT_EST_MOD"='' 
	OR T0."U_HBT_AUFAMO" IS NULL 
	OR T0."U_HBT_AUFAMO"='' ) 
AND T0."U_HBT_SUS_TRIB" <> 99 
AND T0."CANCELED"='N';
 
IF :cnt>0 
THEN error := -252;
 error_message := 'SP: Debe de llenar establecimiento, punto de emision y autorización del comprobante modificado';
 
END IF;	
END IF;
 
IF :object_type='19' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM ORPC T0 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND (T0."U_HBT_NUFAMO" IS NULL 
	or T0."U_HBT_NUFAMO"='' 
	OR T0."U_HBT_AUT_FAC" IS NULL 
	OR T0."U_HBT_AUT_FAC" ='') 
AND T0."U_HBT_SUS_TRIB" <> 99 
AND "CANCELED"='N';
 
IF :cnt>0 
THEN error := -253;
 error_message := 'SP: Debe llenar el secuencial del comprobante modificado y el numero de autorizacion de la NC';
 
END IF;
END IF;		
 -------------------------
 IF :object_type='19' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM ORPC T0 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND (T0."U_HBT_SER_EST" IS NULL 
	or T0."U_HBT_SER_EST"='' 
	OR T0."U_HBT_PTO_EST" IS NULL 
	or T0."U_HBT_PTO_EST"='') 
AND T0."U_HBT_SUS_TRIB" <> 99 
AND "CANCELED"='N';
 
IF :cnt>0 
THEN error := -254;
 error_message := 'SP: Debe llenar establecimeinto y punto de emisión de NC';
 
END IF;
END IF;
 ------------------------------------------------------------------------------------------------
--Datos obligatorios para NC clientes ATS
--04/05/2015
 
IF :object_type='14' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM ORIN T0 
INNER JOIN RIN1 T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T1."BaseType" <> 13 
AND (T0."U_HBT_TIDOMO" IS NULL 
	OR T0."U_HBT_TIDOMO"='') 
AND "CANCELED"='N' 
AND "U_HBT_TIP_COMP" NOT IN (99);
 
IF :cnt>0 
THEN error := -255;
 error_message := 'SP: Debe escoger el Tipo de Comprobante Modificado';
 
END IF;
END IF;
 ----------------------
 IF :object_type='14' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM ORIN T0 
INNER JOIN RIN1 T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T1."BaseType" <> 13 
AND (T0."U_HBT_PUFAMO" IS NULL 
	OR T0."U_HBT_PUFAMO"='' 
	OR T0."U_HBT_EST_MOD" IS NULL 
	OR T0."U_HBT_EST_MOD"='') 
AND T0."CANCELED"='N' 
AND T0."U_HBT_TIP_COMP" NOT IN (99);
 
if :cnt>0 
then error := -256;
 error_message := 'SP: Debe de llenar establecimiento y punto de emision del comprobante modificado';
 
END IF;
END IF;
 ----------------
IF :object_type='14' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM ORIN T0 
INNER JOIN RIN1 T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T1."BaseType" <> 13 
AND (T0."U_HBT_NUFAMO" IS NULL 
	OR T0."U_HBT_NUFAMO"='') 
AND T0."CANCELED"='N' 
AND T0."U_HBT_TIP_COMP" NOT IN (99);
 
IF :cnt>0 
THEN error := -257;
 error_message := 'SP: Debe de llenar secuencial del comprobante modificado';
 
END IF;
END IF;		
-----------------
IF :object_type='14' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM ORIN T0 
INNER JOIN RIN1 T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T1."BaseType" <> 13 
AND (T0."U_HBT_FEDOMO" IS NULL 
	OR T0."U_HBT_FEDOMO"='') 
AND T0."CANCELED"='N' 
AND T0."U_HBT_TIP_COMP" NOT IN (99);
 
IF :cnt>0 
THEN error := -258;
 error_message := 'SP: Debe llenar fecha del comprobante modificado';
 
END IF;
END IF;
 -----------------
IF :object_type='14' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT (*) 
INTO cnt 
FROM ORIN T0 
INNER JOIN RIN1 T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T1."BaseType" <> 13 
AND (T0."Comments" IS NULL 
	OR T0."Comments"='') 
AND T0."CANCELED"='N' 
AND T0."U_HBT_TIP_COMP" NOT IN (99);
 
IF :cnt>0 
THEN error := -259;
 error_message := 'SP: Debe llenar el comentario del documento';
 
END IF;
END IF;
------------------------------------------------------------------------------------------------------------------
---------------------------------------FACTURA DE EXPORTACION---------------------------------------------------
----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
---Validación: El campo TIPO EXPORTACION en la factura debe estar lleno

if :object_type='13' 
and (:transaction_type='A' or :transaction_type='U') 
then cnt:=0;
SELECT	COUNT(T0."DocNum") 
INTO cnt 
FROM OINV T0 INNER JOIN INV12 T1
ON T0."DocEntry" = T1."DocEntry"
WHERE T0."DocEntry" =:list_of_cols_val_tab_del
AND T1."CountryS" <> 'EC'
AND IFNULL(T0."U_HBT_TIPEXP",	'')= ''; 
 
if :cnt>0 
then error := -260;
 error_message := 'HBT: El campo Tipo Exportación es Obligatorio'; 
end if; 
end if;

---Validación: El campo Incoterm en la factura debe estar lleno
if :object_type='13' 
and (:transaction_type='A' or :transaction_type='U') 
then cnt:=0;
 SELECT
	 COUNT(OINV."DocNum") 
INTO cnt 
FROM OINV 
WHERE OINV."DocEntry" =:list_of_cols_val_tab_del 
AND OINV."U_HBT_TIPEXP" IS NOT NULL
AND IFNULL(OINV."U_HBT_INCOTE",	'')= ''; 
 
if :cnt>0 
then error := -261;
 error_message := 'HBT: El campo IncoTermFactura es Obligatorio';
 
end if; 
end if;
---Validación: El campo Lugar Incoterm en la factura debe estar lleno

if :object_type='13' 
and (:transaction_type='A' 	or :transaction_type='U') 
then cnt:=0;
 SELECT
	 COUNT(OINV."DocNum") 
INTO cnt 
FROM OINV 
WHERE OINV."DocEntry" =:list_of_cols_val_tab_del 
AND OINV."U_HBT_TIPEXP" IS NOT NULL
AND IFNULL(OINV."U_HBT_LUG_IT",	'')= ''; 
 
if :cnt>0 
then error := -262;
 error_message := 'HBT: El campo Lugar Incoterm es Obligatorio'; 

end if; 
end if;
---Validación: El campo País Origen en la factura debe estar lleno

if :object_type='13' 
and (:transaction_type='A' 	or :transaction_type='U') 
then cnt:=0;
 SELECT
	 COUNT(OINV."DocNum") 
INTO cnt 
FROM OINV 
WHERE OINV."DocEntry" =:list_of_cols_val_tab_del
AND OINV."U_HBT_TIPEXP" IS NOT NULL 
AND IFNULL(OINV."U_HBT_PAISOR",	'')= ''; 
 
if :cnt>0 
then error := -263;
 error_message := 'HBT: El campo País Origen es Obligatorio';
 
end if; 
end if;
---Validación: El campo Puerto de Embarque en la factura debe estar lleno

if :object_type='13' 
and (:transaction_type='A' 	or :transaction_type='U') 
then cnt:=0;
 SELECT
	 COUNT(OINV."DocNum") 
INTO cnt 
FROM OINV 
WHERE OINV."DocEntry" =:list_of_cols_val_tab_del 
AND OINV."U_HBT_TIPEXP" IS NOT NULL
AND IFNULL(OINV."U_HBT_PUEMBA",	'')= ''; 
 
if :cnt>0 
then error := -264;
 error_message := 'HBT: El campo Puerto Embarque es Obligatorio';
 
end if; 
end if;

---Validación: El campo Puerto Destino en la factura debe estar lleno

if :object_type='13' 
and (:transaction_type='A' 	or :transaction_type='U') 
then cnt:=0;
 SELECT
	 COUNT(OINV."DocNum") 
INTO cnt 
FROM OINV 
WHERE OINV."DocEntry" =:list_of_cols_val_tab_del 
AND OINV."U_HBT_TIPEXP" IS NOT NULL
AND IFNULL(OINV."U_HBT_PUDEST",	'')= ''; 
 
if :cnt>0 
then error := -265;
 error_message := 'HBT: El campo Puerto Destino es Obligatorio';
 
end if; 
end if;

---Validación: El campo País Destino en la factura debe estar lleno

if :object_type='13' 
and (:transaction_type='A' 	or :transaction_type='U') 
then cnt:=0;
 SELECT
	 COUNT(OINV."DocNum") 
INTO cnt 
FROM OINV 
WHERE OINV."DocEntry" =:list_of_cols_val_tab_del 
AND OINV."U_HBT_TIPEXP" IS NOT NULL
AND IFNULL(OINV."U_HBT_PAISDT",	'')= ''; 
 
if :cnt>0 
then error := -266;
 error_message := 'HBT: El campo País destino es Obligatorio';
 
end if; 
end if;

---Validación: El campo Flete en la factura debe ser igual a los gastos adicionales

if :object_type='13' 
and (:transaction_type='A' or :transaction_type='U') 
then cnt:=0;
SELECT	COUNT(T0."DocNum") 
INTO cnt 
FROM OINV T0 INNER JOIN INV3 T1
ON T0."DocEntry" = T1."DocEntry"
WHERE T0."DocEntry" =:list_of_cols_val_tab_del
AND T0."U_HBT_TIPEXP" IS NOT NULL
AND T1."ExpnsCode" = '3'
AND(T0."U_HBT_FLTINT" IS NULL 
	OR T0."U_HBT_FLTINT" <> (SELECT T2."LineTotal" 
								FROM INV3 T2 WHERE T2."DocEntry" =:list_of_cols_val_tab_del 
								AND T2."ExpnsCode" = '3') ); 
 
if :cnt>0 
then error := -267;
 error_message := 'HBT: El campo Flete no puede estar vacio, ni ser difente al gasto adicional';
 
end if; 
end if;
---Validación: El campo Distrito Aduanero en la factura debe estar lleno

if :object_type='13' 
and (:transaction_type='A' 	or :transaction_type='U') 
then cnt:=0;
 SELECT
	 COUNT(OINV."DocNum") 
INTO cnt 
FROM OINV 
WHERE OINV."DocEntry" =:list_of_cols_val_tab_del 
AND OINV."U_HBT_TIPEXP" IS NOT NULL
AND IFNULL(OINV."U_HBT_DISADU",	'')= ''; 
 
if :cnt>0 
then error := -268;
 error_message := 'HBT: El campo Distrito Aduanero es Obligatorio'; 

end if; 
end if;

---Validación: El campo Año en la factura debe estar lleno

if :object_type='13' 
and (:transaction_type='A' 	or :transaction_type='U') 
then cnt:=0;
 SELECT
	 COUNT(OINV."DocNum") 
INTO cnt 
FROM OINV 
WHERE OINV."DocEntry" =:list_of_cols_val_tab_del 
AND OINV."U_HBT_TIPEXP" IS NOT NULL
AND IFNULL(OINV."U_HBT_ANIO",	'')= ''; 
 
if :cnt>0 
then error := -269;
 error_message := 'HBT: El campo Año es Obligatorio';
 
end if; 
end if;
---Validación: El campo Regimen en la factura debe estar lleno

if :object_type='13' 
and (:transaction_type='A' 	or :transaction_type='U') 
then cnt:=0;
 SELECT
	 COUNT(OINV."DocNum") 
INTO cnt 
FROM OINV 
WHERE OINV."DocEntry" =:list_of_cols_val_tab_del 
AND OINV."U_HBT_TIPEXP" IS NOT NULL
AND IFNULL(OINV."U_HBT_REGIME",	'')= ''; 
 
if :cnt>0 
then error := -270;
 error_message := 'HBT: El campo Régimen es Obligatorio';
 
end if; 
end if;
---Validación: El campo Incoterm Sin Impuestos en la factura debe estar lleno

if :object_type='13' 
and (:transaction_type='A' 	or :transaction_type='U') 
then cnt:=0;
SELECT
	 COUNT(OINV."DocNum") 
INTO cnt 
FROM OINV 
WHERE OINV."DocEntry" =:list_of_cols_val_tab_del 
AND OINV."U_HBT_TIPEXP" IS NOT NULL
AND OINV."U_HBT_ITTSI" = 0; 
 
if :cnt > 0
then error := -271;
 error_message := 'HBT: El campo Incoterm sin Impuestos es Obligatorio';

end if; 
end if;
---Validación: El campo Refrendo-Correlativo en la factura debe estar lleno

if :object_type='13' 
and (:transaction_type='A' 	or :transaction_type='U') 
then cnt:=0;
SELECT COUNT(OINV."DocNum") 
INTO cnt 
FROM OINV 
WHERE OINV."DocEntry" =:list_of_cols_val_tab_del 
AND OINV."U_HBT_TIPEXP" IS NOT NULL
AND IFNULL(OINV."U_HBT_REFCOR",	'')= ''; 
 
if :cnt>0 
then error := -272;
 error_message := 'HBT: El campo N° Refrendo-Correlativo es Obligatorio';

end if; 
end if;
---Validación: El campo Valor FOB en la factura debe estar lleno

if :object_type='13' 
and (:transaction_type='A' 	or :transaction_type='U') 
then cnt:=0;
 SELECT
	 COUNT(OINV."DocNum") 
INTO cnt 
FROM OINV 
WHERE OINV."DocEntry" =:list_of_cols_val_tab_del 
AND OINV."U_HBT_TIPEXP" IS NOT NULL
AND OINV."U_HBT_VALFOB"=0; 
 
if :cnt>0 
then error := -273;
 error_message := 'HBT: El campo Valor FOB es Obligatorio';
 
end if; 
end if;

---Validación: El campo Valor Comprobante local en la factura debe estar lleno

if :object_type='13' 
and (:transaction_type='A' 	or :transaction_type='U') 
then cnt:=0;
 SELECT
	 COUNT(OINV."DocNum") 
INTO cnt 
FROM OINV 
WHERE OINV."DocEntry" =:list_of_cols_val_tab_del 
AND OINV."U_HBT_TIPEXP" IS NOT NULL
AND OINV."U_HBT_VALFOBC"=0; 
 
if :cnt>0 
then error := -274;
 error_message := 'HBT: El campo Valor Comprobante local es Obligatorio';
 
end if; 
end if;
---Validación: El campo Tipo de Régimen en la factura debe estar lleno

if :object_type='13' 
and (:transaction_type='A' 	or :transaction_type='U') 
then cnt:=0;
 SELECT
	 COUNT(OINV."DocNum") 
INTO cnt 
FROM OINV 
WHERE OINV."DocEntry" =:list_of_cols_val_tab_del 
AND OINV."U_HBT_TIPEXP" IS NOT NULL
AND IFNULL(OINV."U_HBT_REG_FIS",	'')= ''; 
 
if :cnt>0 
then error := -275;
 error_message := 'HBT: El campo Tipo de Régimen es Obligatorio';
 
end if; 
end if;
---Validación: El campo País a Exportar en la factura debe estar lleno

if :object_type='13' 
and (:transaction_type='A' 	or :transaction_type='U') 
then cnt:=0;
 SELECT
	 COUNT(OINV."DocNum") 
INTO cnt 
FROM OINV 
WHERE OINV."DocEntry" =:list_of_cols_val_tab_del 
AND OINV."U_HBT_TIPEXP" IS NOT NULL
AND OINV."U_HBT_REG_FIS" = '01'
AND IFNULL(OINV."U_HBT_PAIS_EFEC_EXP",	'')= ''; 
 
if :cnt>0 
then error := -276;
 error_message := 'HBT: El campo País a Exportar es Obligatorio en Régimen General';
end if; 
end if;
---Validación: El campo País a Exportar y Paraíso Fiscal en la factura debe estar lleno

if :object_type='13' 
and (:transaction_type='A' 	or :transaction_type='U') 
then cnt:=0;
 SELECT
	 COUNT(OINV."DocNum") 
INTO cnt 
FROM OINV 
WHERE OINV."DocEntry" =:list_of_cols_val_tab_del 
AND OINV."U_HBT_TIPEXP" IS NOT NULL
AND OINV."U_HBT_REG_FIS" = '02'
AND (IFNULL(OINV."U_HBT_PAIS_EFEC_EXP",	'')= ''
OR IFNULL(OINV."U_HBT_PARFI",	'')= ''); 
 
if :cnt>0 
then error := -277;
 error_message := 'HBT: El campo País a Exportar y Paraíso Fiscal es Obligatorio en Régimen Paraiso Fiscal';
 
end if; 
end if;

---Validación: El campo País a Exportar y Denominacion Régimen impositivo en la factura debe estar lleno

if :object_type='13' 
and (:transaction_type='A' 	or :transaction_type='U') 
then cnt:=0;
 SELECT
	 COUNT(OINV."DocNum") 
INTO cnt 
FROM OINV 
WHERE OINV."DocEntry" =:list_of_cols_val_tab_del 
AND OINV."U_HBT_TIPEXP" IS NOT NULL
AND OINV."U_HBT_REG_FIS" = '03'
AND (IFNULL(OINV."U_HBT_PAIS_EFEC_EXP",	'')= ''
OR IFNULL(OINV."U_HBT_DENJUR",	'')= ''); 
 
if :cnt>0 
then error := -278;
 error_message := 'HBT: El campo País a Exportar y Denominación Regimen Fiscal es Obligatorio';
 
end if; 
end if;

---Validación: El campo Número de documento de Transporte en la factura debe estar lleno

if :object_type='13' 
and (:transaction_type='A' 	or :transaction_type='U') 
then cnt:=0;
 SELECT
	 COUNT(OINV."DocNum") 
INTO cnt 
FROM OINV 
WHERE OINV."DocEntry" =:list_of_cols_val_tab_del 
AND OINV."U_HBT_TIPEXP" IS NOT NULL
AND IFNULL(OINV."U_HBT_DOCTRA",	'')= ''; 
 
if :cnt>0 
then error := -279;
 error_message := 'HBT: El campo Número de Documento de Transporte es Obligatorio';
 
end if; 
end if;

---Validación: El campo Comercio Exterior en la factura debe estar lleno

if :object_type='13' 
and (:transaction_type='A' 	or :transaction_type='U') 
then cnt:=0;
 SELECT
	 COUNT(OINV."DocNum") 
INTO cnt 
FROM OINV 
WHERE OINV."DocEntry" =:list_of_cols_val_tab_del 
AND OINV."U_HBT_TIPEXP" IS NOT NULL
AND IFNULL(OINV."U_HBT_COMEX",	'')= ''; 
 
if :cnt>0 
then error := -280;
 error_message := 'HBT: El campo Comercio Exterior es Obligatorio';
 
end if; 
end if;
-----------------------
---Validación de totales de factura de exportación
/*
if :object_type='13' 
and (:transaction_type='A' 	or :transaction_type='U') 
then cnt:=0;

 SELECT
	 COUNT(OINV."DocNum") 
INTO cnt 
FROM OINV 
WHERE OINV."DocEntry" = :list_of_cols_val_tab_del 
AND OINV."U_HBT_TIPEXP" IS NOT NULL
AND OINV."DocTotal" <> OINV."U_HBT_VALFOBC";

if :cnt>0 
then error := -281;
 error_message := 'HBT: Valor del Comprobante Local y el Total de la Factura deben ser iguales';
 
end if; 
end if;
*/
-------------------------------------FIN FACTURA DE EXPORTACION------------------------------------------
--AUTOR: HEINSOHNTECH
--DESCRIPCION:  No permite escoger las formas de pago que ya no estén vigentes en la Factura de Compra
--FECHA:            
----------------------------------------------------------------------------------------------------------------
if :object_type='18' and (:transaction_type='A' or :transaction_type='U')   
then
 
cnt:=0;
  
 SELECT COUNT(T0."DocNum") INTO cnt
     FROM OPCH T0
                INNER JOIN PCH1 T1 ON T0."DocEntry" = T1."DocEntry"             
                 WHERE T0."DocEntry" =:list_of_cols_val_tab_del
                                   AND T0."U_HBT_FP" IN ('02','03','04','05','06','07','08','09','10','11','12','13','14');
 
               if :cnt>0 
               then error := -282;
               error_message := 'SP: La forma de Pago seleccionada no está vigente';
               end if; 
               end if;

--AUTOR: HEINSOHNTECH
--DESCRIPCION:  No permite escoger las formas de pago que ya no estén vigentes en la Factura de Venta
--FECHA:            
----------------------------------------------------------------------------------------------------------------
if :object_type='13' and (:transaction_type='A' or :transaction_type='U')   
then
 cnt:=0;
 
 SELECT COUNT(T0."DocNum") INTO cnt
     FROM OINV T0
                INNER JOIN INV1 T1 ON T0."DocEntry" = T1."DocEntry"             
                 WHERE T0."DocEntry" =:list_of_cols_val_tab_del
                                   AND T0."U_HBT_FP" IN ('02','03','04','05','06','07','08','09','10','11','12','13','14');
 
               if :cnt>0 
               then error := -283;
               error_message := 'SP: La forma de Pago seleccionada no está vigente';
end if; 
end if;

--Validación: El campo DESCRIPCION no puede estar vacio
if :object_type='4' --Creacion y actualizacion de ítems
and (:transaction_type='A' or :transaction_type='U') 
then select count(*) into cnt 
FROM OITM T0 
where T0."ItemCode" = :list_of_cols_val_tab_del 
AND (T0."ItemName" IS NULL or T0."ItemName"= ' ');
	if :cnt>0 
	then error := -284;
	error_message := 'HBT: El campo DESCRIPCION no puede estar vacio';
	end if;
end if;

----------------------------------------------------------------------------------------------------------------
-------------------------------FIN LOCALIZACION-------------------------------------------------------
----------------------------------------------------------------------------------------------------------------
---------------------------------------PERSONALIZACIONES-------------------------------------------------
----------------------------------------------------------------------------------------------------------------

-- NO PERMITE SN SIN ID DE DIRECCION
IF :object_type='2' --Creacion y actualizacion de SN
AND (:transaction_type='A' or :transaction_type='U') 
THEN SELECT COUNT (*) INTO cnt 
FROM OCRD T0 
LEFT JOIN CRD1 T1 ON T0."CardCode" = T1."CardCode"
WHERE T0."CardCode"=:list_of_cols_val_tab_del 
AND T0."CardType" <> 'L'
AND (T1."Address" IS NULL OR T1."Address" = ' ');
	IF :cnt>0 
	THEN
	error := -500;
	error_message := 'HBT: Los campos ID DE DIRECCIÓN y PAÍS son obligatorios en la pestaña DIRECCIÓN';
	END IF;
END IF;


--NO PERMITE CLIENTE SIN CAMPO CARGO AGENCY

IF :object_type='2' --Creacion y actualizacion de SN
AND (:transaction_type='A'	or :transaction_type='U') 
THEN SELECT COUNT (*) INTO cnt 
FROM OCRD T0 
LEFT JOIN CRD1 T1 ON T0."CardCode" = T1."CardCode" 
WHERE T0."CardCode"=:list_of_cols_val_tab_del 
AND T0."CardType" = 'C' 
AND (T1."U_ASA_CRG_AGN" IS NULL OR T1."U_ASA_CRG_AGN"='');
	IF :cnt>0 
	THEN
	error := -501;
	error_message := 'HBT: El campo CARGO AGENCY es obligatorio en la pestaña DIRECCIÓN';
	END IF;
END IF;
----------------------------------------------------------------------------------------------------------------
---Validación: Campo Incoterm en el dato maestro del cliente

if :object_type='2' --Creacion y actualizacion de SN

and (:transaction_type='A' 
	or :transaction_type='U') 
then select
	 count(*) 
into cnt 
FROM CRD1 T0 
inner join OCRD T1 ON T0."CardCode" = T1."CardCode" 
where T0."CardCode"=:list_of_cols_val_tab_del 
AND T1."CardType" = 'C' 
AND T0."Country" <> 'EC' 
AND T1."U_ASA_INCOTERM" IS NULL 
;
 
if :cnt>0 
then error := -502;
 error_message := 'HBT: El campo INCOTERM es obligatorio en el dato maestro de cliente';
 
end if;
end if;
----------------------------------------------------------------------------------------------------------------
---Validación: El artículo semielaborado debe ser gestionado por Lotes

if :object_type='4' --Creacion y actualizacion de SN
 
and (:transaction_type='A' 
	or :transaction_type='U') 
then select
	 count(*)
into cnt 
FROM OITM T0 
WHERE T0."ItemCode" = :list_of_cols_val_tab_del 
AND T0."ManBtchNum" <> 'Y' 
AND T0."U_ASA_TIPO" = '02';
 
if :cnt > 0 
then error := -503;
 error_message := 'HBT:Se debe Seleccionar el campo Articulo Gestionado por Numero de Lote';
 
end if;
end if;
----------------------------------------------------------------------------------------------------------------
---Validación: El artículo semielaborado debe ser valorado por Lotes

if :object_type='4' --Creacion y actualizacion de SN
 
and (:transaction_type='A' 
	or :transaction_type='U') 
then select
	 count(*)
into cnt 
FROM OITM T0 
WHERE T0."ItemCode" = :list_of_cols_val_tab_del 
AND T0."ManBtchNum" = 'Y' 
AND T0."U_ASA_TIPO" = '02' 
AND T0."EvalSystem" <> 'B';
 
if :cnt > 0 
then error := -504;
 error_message := 'HBT:En el Método de Valoración (pestaña inventario) debe colocarse Series/Lotes';
 
end if;
end if;
----------------------------------------------------------------------------------------------------------------
---Validación: El artículo semielaborado debe fijar el método de valoración por artículo
 
if :object_type='4' --Creacion y actualizacion de SN
 
and (:transaction_type='A' 
	or :transaction_type='U') 
then select
	 count(*)
into cnt 
FROM OITM T0 
WHERE T0."ItemCode" = :list_of_cols_val_tab_del 
AND T0."ManBtchNum" = 'Y' 
AND T0."U_ASA_TIPO" = '02' 
AND T0."EvalSystem" = 'B' 
AND T0."GLMethod" <> 'L';
 
if :cnt > 0 
then error := -505;
 error_message := 'HBT:En el campo Fijar Método de inventario (pestaña inventario) por Artículo';
 
end if;
end if;
 ----------------------------------------------------------------------------------------------------------------
---Validación: El campo Recupera IVA no puede estar vacio

if :object_type='4' --Creacion y actualizacion de ítems

and (:transaction_type='A' 
	or :transaction_type='U') 
then select
	 count(*) 
into cnt 
FROM OITM T0 
where T0."ItemCode" = :list_of_cols_val_tab_del 
AND T0."U_ASA_REC_IVA" IS NULL --AND T0."ItmsGrpCod"<>113 
;
 
if :cnt>0 
then error := -506;
 error_message := 'HBT: El campo Recupera IVA no puede estar vacio ';
 
end if;
end if;
 ----------------------------------------------------------------------------------------------------------------
---Validación: El campo Subcategoria 1 no puede estar vacio

if :object_type='4' --Creacion y actualizacion de ítems
and (:transaction_type='A' 
	or :transaction_type='U') 
then select
	 count(*) 
into cnt 
FROM OITM T0 
where T0."ItemCode" = :list_of_cols_val_tab_del 
AND T0."U_ASA_SUBCAT1" IS NULL 
AND T0."ItmsGrpCod"<> '117';
 
if :cnt>0 
then error := -507;
 error_message := 'HBT: El campo Subcategoria 1 no puede estar vacio ';
 
end if;
end if;
----------------------------------------------------------------------------------------------------------------
---Validación: El campo Subcategoria 2 no puede estar vacio

if :object_type='4' --Creacion y actualizacion de ítems

and (:transaction_type='A' 
	or :transaction_type='U') 
then select
	 count(*) 
into cnt 
FROM OITM T0 
where T0."ItemCode" = :list_of_cols_val_tab_del 
AND T0."U_ASA_SUBCAT2" IS NULL 
AND T0."ItmsGrpCod"<> '117';
 
if :cnt>0 
then error := -508;
 error_message := 'HBT: El campo Subcategoria 2 no puede estar vacio ';
 
end if;
end if;
 ----------------------------------------------------------------------------------------------------------------
---Validación: El campo Subcategoria 3 no puede estar vacio

if :object_type='4' --Creacion y actualizacion de ítems

and (:transaction_type='A' 
	or :transaction_type='U') 
then select
	 count(*) 
into cnt 
FROM OITM T0 
where T0."ItemCode" = :list_of_cols_val_tab_del 
AND T0."U_ASA_SUBCAT3" IS NULL 
AND T0."ItmsGrpCod" <> '117';
 
if :cnt>0 
then error := -509;
 error_message := 'HBT: El campo Subcategoria 3 no puede estar vacio ';
 
end if;
end if;
----------------------------------------------------------------------------------------------------------------
--Validación: El campo TIPO no puede estar vacio

if :object_type='4' --Creacion y actualizacion de ítems

and (:transaction_type='A' 
	or :transaction_type='U') 
then select
	 count(*) 
into cnt 
FROM OITM T0 
where T0."ItemCode" = :list_of_cols_val_tab_del 
AND T0."U_ASA_TIPO" IS NULL 
AND T0."ItmsGrpCod" <> '117';
 
if :cnt>0 
then error := -510;
 error_message := 'HBT: El campo Tipo no puede estar vacio ';
 
end if;
end if;
-----------------------------------------------------------------------------------------------------------------
---Validación: El campo M.A.W.B en la factura debe estar lleno

if :object_type='13' 
and (:transaction_type='A' or :transaction_type='U') 
then cnt:=0;
 SELECT
	 COUNT(T0."DocNum") 
INTO cnt 
FROM OINV T0 INNER JOIN INV12 T1
ON T0."DocEntry" = T1."DocEntry"
WHERE T0."DocEntry" =:list_of_cols_val_tab_del
AND T1."CountryS" <> 'EC'
AND IFNULL(T0."U_ASA_MAWB",	'')= ''
AND T0."CANCELED"= 'N'; 
 
if :cnt>0 
then error := -511;
 error_message := 'HBT: El campo M.A.W.B es Obligatorio';
 
end if; 
end if;
 -----------------------------------------------------------------------------------------------------------------
---Validación: El campo H.A.W.B en la factura debe estar lleno

if :object_type='13' 
and (:transaction_type='A' 
	or :transaction_type='U') 
then cnt:=0
;
 SELECT
	 COUNT(T0."DocNum") 
INTO cnt 
FROM OINV T0 INNER JOIN INV12 T1
ON T0."DocEntry" = T1."DocEntry"
WHERE T0."DocEntry" =:list_of_cols_val_tab_del
AND T1."CountryS" <> 'EC'
AND IFNULL(T0."U_ASA_HAWB",'')= ''
AND T0."CANCELED"= 'N'; 
 
if :cnt>0 
then error := -512;
error_message := 'HBT: El campo H.A.W.B es Obligatorio'; 

end if; 
end if;
--------------------------------------------------------------------------------------------------------------
---Validación: Se debe llenar el centro de costos en el datos maestro de Activo Fijo

if :object_type='4' 
and (:transaction_type='A') 
then cnt :=0
;
SELECT
	 T0."ItmsGrpCod" 
INTO v_condicion 
FROM OITM T0 
WHERE T0."ItemCode" = :list_of_cols_val_tab_del;
 
IF :v_condicion = 117 
THEN SELECT
	 count (*) 
INTO cnt 
FROM OITM T0 
INNER JOIN ITM6 T2 ON T0."ItemCode" = T2."ItemCode" 
WHERE T0."ItemCode" = :list_of_cols_val_tab_del;       
 
IF (:cnt < 1) 
THEN error := -513;
 error_message := ' Debe colocar el Centro de Costo al crear el ACTIVO FIJO.';
 
END IF;
END IF;
END IF;
------------------------------------------------------------------------------------------------------------------
--Validar los pagos recibidos, cambio de cuenta de anticipos

IF :object_type='24' 
and (:transaction_type='A'
	or :transaction_type='U') 
THEN select
	 COUNT(*) 
into cnt1 
from "ORCT" T0 
where T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."PayNoDoc" = 'Y' 
AND T0."Canceled"='N' 
AND T0."BpAct" <> '2120201';
 
IF :cnt1 > 0 
THEN error := -514;
error_message := 'HBT: Debe cambiar la cuenta contable de anticipo';
 
END IF;
END IF;
------------------------------------------------------------------------------------------------------------------
--Validar los pagos efectuados, cambio de cuenta de anticipos

IF :object_type='46' 
and (:transaction_type='A' or :transaction_type='U') 
THEN select COUNT(*) 
into cnt1 
from "OVPM" T0 
where T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."PayNoDoc" = 'Y' 
AND T0."Canceled"='N'
AND T0."DocType"='S'
AND T0."BpAct" <> '1130402';
	IF :cnt1 > 0 
	THEN error := -515;
	error_message := 'HBT: Debe cambiar la cuenta contable de anticipo';
	END IF;
END IF;
 ----------------------------------------------------------------------------------------------------------------
--Validación:  No permite registrar una factura de artículos sin un pedido previo

IF :object_type = '18' 
AND ((:transaction_type = 'A' 
		OR :transaction_type = 'U')) 
THEN SELECT
	 COUNT(*)
INTO cnt 
FROM OPCH T0 
INNER JOIN PCH1 T1 ON T0."DocEntry"=T1."DocEntry" 
INNER JOIN OITM T2 ON T1."ItemCode" = T2."ItemCode" 
WHERE T1."DocEntry" = :list_of_cols_val_tab_del 
AND T2."InvntItem" = 'Y'
AND T1. "ItemCode" NOT IN ('MP00476','MP00477','MP00478','MP00479')
AND (T1."BaseType" IS NULL 
	OR T1."BaseType" <> '20')
AND T0."CANCELED" = 'N';
 
IF :cnt > 0 
THEN error := -516;
 error_message:='HBT: La Factura de Proveedores debe tener un pedido';
 
END IF;
END IF;
----------------------------------------------------------------------------------------------------------------
--Validación:  No permite registrar una factura en estado rechazado.

IF :object_type = '18' 
AND (:transaction_type = 'A' OR :transaction_type = 'U')
THEN SELECT COUNT(*) INTO cnt 
FROM OPCH T0 
INNER JOIN PCH1 T1 ON T0."DocEntry"=T1."DocEntry"
LEFT JOIN OPOR T2 ON T1."BaseEntry"=T2."DocEntry"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND (T1."BaseType" IS NULL OR T1."BaseType" = '22') 
AND (T2."U_ASA_STATUS" IS NULL OR T2."U_ASA_STATUS" = '02')
AND T0."CANCELED" = 'N';
	IF :cnt > 0 
	THEN error := -517;
	error_message:='HBT: El estado del pedido de la factura es rechazado';
	END IF;
END IF;
----------------------------------------------------------------------------------------------------------------
--Validación:  No permite registrar un pedido sin cotización cuando no tiene acuerdo global
/*
IF :object_type = '22' 
AND ((:transaction_type = 'A' 
		OR :transaction_type = 'U')) 
THEN SELECT
	 COUNT(*)
INTO cnt 
FROM OPOR T0 
INNER JOIN POR1 T1 ON T0."DocEntry"=T1."DocEntry" --INNER JOIN OAT1 T2 ON T1."AgrNo" = T2."AgrNo"
 
WHERE T1."DocEntry" = :list_of_cols_val_tab_del 
AND T1."AgrNo" IS NULL 
AND (T1."BaseType" IS NULL 
	OR T1."BaseType" <> '540000006')
AND T0."CANCELED" = 'N';
 
IF :cnt > 0 
THEN error := -518;
 error_message:='HBT: El pedido debe tener una cotización cuando no tiene acuerdos Globales';
 
END IF;
END IF;
*/
----------------------------------------------------------------------------------------------------------------
--Validación:  No permite registrar una entrega sin pedido previo

IF :object_type = '15' 
AND ((:transaction_type = 'A' 
		OR :transaction_type = 'U')) 
THEN SELECT
	 COUNT(*)
INTO cnt 
FROM ODLN T0 
INNER JOIN DLN1 T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T1."DocEntry" = :list_of_cols_val_tab_del 
AND (T1."BaseType" IS NULL 
	OR T1."BaseType" <> '17') 
AND T0."CANCELED"='N';
 
IF :cnt > 0 
THEN error := 519;
 error_message:='HBT: El pedido confirmado (entrega) debe tener una orden de venta';
 
END IF;
END IF;
----------------------------------------------------------------------------------------------------------------
--Validación:  No permite registrar una factura de venta sin entrega previo

IF :object_type = '13' 
AND ((:transaction_type = 'A' 
		OR :transaction_type = 'U')) 
THEN SELECT
	 COUNT(*)
INTO cnt 
FROM OINV T0 
INNER JOIN INV1 T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T1."DocEntry" = :list_of_cols_val_tab_del 
AND (T1."BaseType" IS NULL 
	OR T1."BaseType" <> '15')
AND T0."CANCELED" = 'N';
 
IF :cnt > 0 
THEN error := -520;
 error_message:='HBT: La factura de venta debe tener un pedido confirmado (entrega)';
 
END IF;
END IF;
-----------------------------------------------------------------------------------------------------------------
---Validación: El campo DAE en la factura debe estar lleno

if :object_type='13' 
and (:transaction_type='A' or :transaction_type='U') 
then cnt:=0;
 SELECT
	 COUNT(T0."DocNum") 
INTO cnt 
FROM OINV T0 INNER JOIN INV12 T1
ON T0."DocEntry" = T1."DocEntry"
WHERE T0."DocEntry" =:list_of_cols_val_tab_del
AND T1."CountryS" <> 'EC'
AND IFNULL(T0."U_ASA_DAE",	'')= ''
AND T0."CANCELED" = 'N'; 
 
if :cnt>0 
then error := -521;
 error_message := 'HBT: El campo DAE es Obligatorio';
 
end if; 
end if;
-----------------------------------------------------------------------------------------------------------------
---Validación: El campo Cargo Agency en la factura debe estar lleno

if :object_type='13' 
and (:transaction_type='A' or :transaction_type='U') 
then cnt:=0;
 SELECT
	 COUNT(T0."DocNum") 
INTO cnt 
FROM OINV T0 INNER JOIN INV12 T1
ON T0."DocEntry" = T1."DocEntry"
WHERE T0."DocEntry" =:list_of_cols_val_tab_del
AND T1."CountryS" <> 'EC'
AND IFNULL(T0."U_ASA_CRG_AGN",	'')= ''
AND T0."CANCELED" = 'N'; 
 
if :cnt>0 
then error := -522;
 error_message := 'HBT: El campo Cargo Agency es Obligatorio';
 
end if; 
end if;
-----------------------------------------------------------------------------------------------------------------
---Validación: El campo C. Room en la factura debe estar lleno

if :object_type='13' 
and (:transaction_type='A' or :transaction_type='U') 
then cnt:=0;
 SELECT
	 COUNT(T0."DocNum") 
INTO cnt 
FROM OINV T0 INNER JOIN INV12 T1
ON T0."DocEntry" = T1."DocEntry"
WHERE T0."DocEntry" =:list_of_cols_val_tab_del
AND T1."CountryS" <> 'EC'
AND IFNULL(T0."U_ASA_CROOM",'')= ''
AND T0."CANCELED" = 'N'; 
 
if :cnt>0 
then error := -523;
 error_message := 'HBT: El campo C. Room es Obligatorio';
 
end if; 
end if;
-----------------------------------------------------------------------------------------------------------------
---Validación: El campo Aerolinea en la factura debe estar lleno

if :object_type='13' 
and (:transaction_type='A' or :transaction_type='U') 
then cnt:=0;
 SELECT
	 COUNT(T0."DocNum") 
INTO cnt 
FROM OINV T0 INNER JOIN INV12 T1
ON T0."DocEntry" = T1."DocEntry"
WHERE T0."DocEntry" =:list_of_cols_val_tab_del
AND T1."CountryS" <> 'EC'
AND IFNULL(T0."U_ASA_AIR_LINE",	'')= ''
AND T0."CANCELED" = 'N'; 
 
if :cnt>0 
then error := -524;
 error_message := 'HBT: El campo Air Line es Obligatorio';
 
end if; 
end if;
----------------------------------------------------------------------------------------------------------------------
-- NO PERMITE GUARDAR FACTURA SIN FLETE CON INCONTERM CIF"
IF :object_type = '13' 
AND (:transaction_type='A' OR :transaction_type='U')
THEN 
DECLARE INCOTE INT;
DECLARE IMP INT;
 SELECT COUNT(T1."ExpnsCode") 
INTO IMP 
FROM OINV T0
LEFT JOIN INV3 T1 ON T0."DocEntry" = T1."DocEntry" 
WHERE T1."ExpnsCode" = 3 AND T0."DocEntry" = :list_of_cols_val_tab_del
AND T0."CANCELED" = 'N';

SELECT COUNT(T0."U_HBT_INCOTE") 
INTO INCOTE 
FROM OINV T0
LEFT JOIN INV3 T1 ON T0."DocEntry" = T1."DocEntry" 
WHERE T0."U_HBT_INCOTE" = 'CIF' AND T0."DocEntry" = :list_of_cols_val_tab_del
AND T0."CANCELED" = 'N';

	IF :IMP = 0 AND :INCOTE > 0
	THEN error := -525;
	error_message := 'HBT: No puede crear factura con Incoterm CIF sin el impuesto Flete"';
	END IF;
END IF;

---Validación: LIMITE DE CREDITO NO PUEDE ESTAR EN BLANCO
if :object_type='2' --Creacion y actualizacion de SN

and (:transaction_type='A' 
	or :transaction_type='U') 
then select count(*) 
into cnt 
FROM OCRD T0 
where T0."CardCode"=:list_of_cols_val_tab_del 
AND T0."CardType" = 'C' 
AND T0."CreditLine" = 0 ;
 
if :cnt>0 
then error := -526;
 error_message := 'HBT: El LIMITE DE CREDITO es obligatorio en el dato maestro de cliente';
 
end if;
end if;
----------------------------------------------------------------------------------------------------------------------
-- NO PERMITE GUARDAR FACTURA SI LAS CANTIDADES NO CORRESPODEN CON LAS CAJAS
/*
IF :object_type = '13' 
AND (:transaction_type='A' OR :transaction_type='U')
THEN 

	DECLARE UNS INT;
	DECLARE CANTIDADES INT;
	DECLARE X3 NVARCHAR (15);
	DECLARE X6 NVARCHAR (15);
	DECLARE SPLX6 INT;
	DECLARE SPLX3 INT;
	
	SELECT COUNT (T1."ItemCode") 
	INTO SPLX6
	FROM OINV T0
	INNER JOIN INV1 T1 ON T1."DocEntry" = T0."DocEntry"
	WHERE T1."ItemCode" = 'PT00001' AND T0."DocEntry" = :list_of_cols_val_tab_del;
	
	SELECT COUNT (T1."ItemCode") 
	INTO SPLX3
	FROM OINV T0
	INNER JOIN INV1 T1 ON T1."DocEntry" = T0."DocEntry"
	WHERE T1."ItemCode" = 'PT00049' AND T0."DocEntry" = :list_of_cols_val_tab_del;
	
	IF :SPLX6 > 0 AND :SPLX3 > 0 THEN
	
		SELECT SUM (T1."Quantity")
		INTO X6
		FROM OINV T0
		INNER JOIN INV1 T1 ON T0."DocEntry" = T1."DocEntry"
		WHERE T1."ItemCode" = 'PT00001' AND T0."DocEntry" = :list_of_cols_val_tab_del;
		
		SELECT SUM (T1."Quantity")
		INTO X3
		FROM OINV T0
		INNER JOIN INV1 T1 ON T0."DocEntry" = T1."DocEntry"
		WHERE T1."ItemCode" = 'PT00049' AND T0."DocEntry" = :list_of_cols_val_tab_del;
		
		IF MOD (:X6 + (:X3/2), 30) <> 0
			THEN error := -527;
			error_message := 'HBT: Debe tener cantidades necesarias para combinar items en cajas exactas.';
		END IF;
	
	ELSEIF :SPLX6 > 0 AND :SPLX3 = 0 OR (:SPLX6 = 0 AND :SPLX3 > 0) THEN

		SELECT SUM(T2."SalPackUn") 
		INTO UNS 
		FROM OINV T0
		INNER JOIN INV1 T1 ON T0."DocEntry" = T1."DocEntry"
		LEFT JOIN OITM T2 ON T1."ItemCode" = T2."ItemCode"
		WHERE T2."Series" = 83 AND T0."DocEntry" = :list_of_cols_val_tab_del;
		
		SELECT SUM (T1."Quantity")
		INTO CANTIDADES
		FROM OINV T0
		INNER JOIN INV1 T1 ON T0."DocEntry" = T1."DocEntry"
		WHERE LEFT(T1."ItemCode",2) = 'PT' AND T0."DocEntry" = :list_of_cols_val_tab_del;
	
		IF MOD(:CANTIDADES , :UNS) <> 0
			THEN error := -527;
			error_message := 'HBT: Debe tener cantidades necesarias para armar cajas exactas.';
			END IF;
	--END IF;
	END IF;	
END IF;*/

---------------------------------------------------------------------------------------------------------------
END