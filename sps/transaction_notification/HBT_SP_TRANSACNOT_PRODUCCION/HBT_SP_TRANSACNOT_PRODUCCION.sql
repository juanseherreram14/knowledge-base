CREATE PROCEDURE HBT_SP_TRANSACNOT_PRODUCCION
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
 
BEGIN
----------------------------------------------------------------------------------------------------------------
------------------------------------------------PRODUCCION------------------------------------------------------
----------------------------------------------------------------------------------------------------------------
 --Validar campo OP en la orden de fabricación

IF :object_type = '202' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt1 
FROM "OWOR" T0 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."U_ASA_PROC_OF" <> 'P-AGR' 
AND T0."U_ASA_PROC_OF" <> 'P-REEMP'
AND (T0."U_ASA_OP" IS NULL 
	OR T0."U_ASA_OP" = ' ');
 
IF :cnt1 > 0 
THEN error := -1000;
 error_message := 'HBT: Debe llenar el campo Lote';   
 
END IF;
END IF;
------------------------------------------------------------------------------------------------------------------
--Validar campo Rack en la orden de fabricación

IF :object_type = '202' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN select
	 COUNT(*) 
into cnt1 
from "OWOR" T0 
where T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."U_ASA_PROC_OF" <> 'P-AGR' 
AND T0."U_ASA_PROC_OF" <> 'P-PIN' 
AND T0."U_ASA_PROC_OF" <> 'P-REEMP' 
AND (T0."U_ASA_RACK" IS NULL 
	OR T0."U_ASA_RACK" = ' ');
 
IF :cnt1 > 0 
THEN error := -1001;
error_message := 'HBT: Debe llenar el campo Rack';
 
END IF;
END IF;
 -----------------------------------------------------------------------------------------------------------------
--Validar campo Proceso en la lista de materiales

IF :object_type = '66' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN select
	 COUNT(*) 
into cnt1 
from "OITT" T0 
where T0."Code" = :list_of_cols_val_tab_del 
AND (T0."U_ASA_PROC_LM" IS NULL 
	OR T0."U_ASA_PROC_LM" = '');
 
IF :cnt1 > 0 
THEN error := -1002;
error_message := 'HBT: Debe llenar el campo Proceso';
 
END IF;
END IF;

 --Validar campo Proceso en la orden de fabricación

IF :object_type = '202' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt1 
FROM "OWOR" T0 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND (T0."U_ASA_PROC_OF" IS NULL 
	OR T0."U_ASA_PROC_OF"='');
 
IF :cnt1 > 0 
THEN error := -1003;
 error_message := 'HBT: Debe llenar el campo Proceso';   
 
END IF;
END IF;
 --Validar campo Variedad en la orden de fabricación

IF :object_type = '202' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt1 
FROM "OWOR" T0 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND (T0."U_ASA_VAR" IS NULL 
	OR T0."U_ASA_VAR"='');
 
IF :cnt1 > 0 
THEN error := -1004;
 error_message := 'HBT: Debe llenar el campo Variedad' ;   
 
END IF;
END IF;
 -- NO PERMITE DOS OF DE LA MISMA VARIEDAD ABIERTAS 

IF :object_type = '202' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt 
FROM OWOR T0 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."ItemCode" IN (SELECT
	 T1."ItemCode" 
	FROM "OWOR" T1 
	WHERE T1."DocEntry" <> :list_of_cols_val_tab_del 
	AND T1."U_ASA_PROC_OF"='P-AGR' 
	AND (T1."Status"='R' 
		OR T1."Status"='P'));
 
IF :cnt > 0 
THEN error := -1005;
 error_message := 'HBT: No puede haber dos ordenes de fabricación abiertas de la misma variedad';
 
END IF;
END IF;
 -- NO PERMITE CERRAR OF SIN CONSUMOS DE COMPONENTES

IF :object_type = '202' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt 
FROM OWOR T0 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."Status"='L' 
AND T0."DocNum" NOT IN (SELECT T1."BaseRef" FROM IGE1 T1 INNER JOIN OITM T2 ON T1."ItemCode"=T2."ItemCode"
WHERE T1."BaseEntry"=:list_of_cols_val_tab_del);
 
IF :cnt > 0 
THEN error := -1006;
 error_message := 'HBT: No puede cerrar orden sin consumo de componentes';
 
END IF;
END IF;

 -- NO PERMITE CERRAR OF SIN RECIBOS

IF :object_type = '202' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt 
FROM OWOR T0 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."Status"='L' 
AND T0."DocNum" NOT IN (SELECT
	 T1."BaseRef" 
	FROM IGN1 T1 
	WHERE T1."BaseEntry"=:list_of_cols_val_tab_del);
 
IF :cnt > 0 
THEN error := -1007;
 error_message := 'HBT: No puede cerrar orden sin ingreso de producto terminado';
 
END IF;
END IF;
 -- NO PERMITE RECIBO DE COMPLETOS EN ALMACEN DS

IF :object_type = '59' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt 
FROM IGN1 T0 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."TranType"='C' 
AND T0."WhsCode"='DS' 
AND T0."BaseType"=202;
 
IF :cnt > 0 
THEN error := -1008;
 error_message := 'HBT: No puede ingresar producto completo a almacén cuarentena';
 
END IF;
END IF;

-- NO PERMITE RECIBO DE RECHAZOS EN ALMACEN DIFERENTE A DESECHO
IF :object_type = '59' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt 
FROM IGN1 T0 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."TranType"='R' 
AND T0."WhsCode"<>'DS' 
AND T0."BaseType"=202;
 
IF :cnt > 0 
THEN error := -1009;
 error_message := 'HBT: No puede ingresar producto rechazado a almacén distinto a Desecho';
 
END IF;
END IF;
-- NO PERMITE SALIDA DE RECHAZOS PARA REVALORIZACION DESDE ALMACEN DIFERENTE A DS

IF :object_type = '60' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt 
FROM OIGE T0 
INNER JOIN IGE1 T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."U_ASA_TIP_SAL" = '03' 
AND T1."WhsCode" <> 'DS' 
AND T1."BaseType" = '-1';
	IF :cnt > 0 
	THEN error := -1010;
	error_message := 'HBT: No puede sacar producto rechazado para revalorización desde almacén distinto a cuarentena';
	END IF;
END IF;

-- NO PERMITE ENTRADA DE PRODUCTOS SIN TIPO

IF :object_type = '59' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt 
FROM OIGN T0 
INNER JOIN IGN1 T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND (T0."U_ASA_TIP_ENT" IS NULL 
	OR T0."U_ASA_TIP_ENT"='') 
AND T1."BaseType"<>'202'
;
IF :cnt > 0 
THEN error := -1011;
 error_message := 'HBT: Debe registrar tipo de entrada';
 
END IF;
END IF;

-- NO PERMITE ENTRADA DE PRODUCTOS CON SERIE DIFERENTE A PRIMARIO

IF :object_type = '59' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt 
FROM OIGN T0 
INNER JOIN IGN1 T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T1."BaseType"<>'202'
AND T0."Series" <> '25'
;
IF :cnt > 0 
THEN error := -1055;
 error_message := 'HBT: Debe registrar con serie primario';
 
END IF;
END IF;

-- NO PERMITE SALIDA DE PRODUCTOS SIN TIPO

IF :object_type = '60' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt 
FROM OIGE T0 
INNER JOIN IGE1 T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND (T0."U_ASA_TIP_SAL" IS NULL 
	OR T0."U_ASA_TIP_SAL"='') 
AND T1."BaseType"<>'202';
 
IF :cnt > 0 
THEN error := -1012;
 error_message := 'HBT: Debe registrar tipo de salida';
 
END IF;
END IF;
-- NO PERMITE REVALORIZACIÓN EN ALMACEN DISTINTO A PINCHADO

IF :object_type = '162' 
AND (:transaction_type='A' or :transaction_type='U') 
THEN SELECT COUNT(*) 
INTO cnt 
FROM OMRV T0 
INNER JOIN MRV1 T1 ON T0."DocEntry" = T1."DocEntry"
LEFT JOIN OITT T2 ON T1."ItemCode" = T2."Code"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T2."U_ASA_PROC_LM" = 'P-AGR' 
AND T1."WhsCode" <> 'PI';
	IF :cnt > 0 
	THEN error := -1013;
	error_message := 'HBT: No puede hacer revalorización de productos en almacén diferente a Pinchado';
	END IF;
END IF;
---------------------------------------------------------------------------------------------------------------
-- NO PERMITE REVALORIZACIÓN DE TIPO "MODIFICACION DE PRECIO"

IF :object_type = '162' 
AND (:transaction_type='A' OR :transaction_type='U') 
THEN SELECT COUNT(*) 
INTO cnt 
FROM OMRV T0 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."RevalType" = 'P';
	IF :cnt > 0 
	THEN error := -1014;
	error_message := 'HBT: No puede hacer revalorización de tipo "Modificación de precio"';
	END IF;
END IF;

 --NO PERMITE SEMIELABORADO EN ALMACENES DIFERENTES A LINEAS

IF :object_type = '202' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt1 
FROM "OWOR" T0 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."U_ASA_PROC_OF" NOT IN ('P-AGR','P-PIN','P-TYS','P-EMP','P-REMP') 
--AND T0."U_ASA_PROC_OF"<>'P-PIN' 
--AND T0."U_ASA_PROC_OF"<>'P-TYS' 
AND SUBSTRING(T0."ItemCode",1,2)='MP' 
AND SUBSTRING(T0."Warehouse",1,1)<>'L';
IF :cnt1 > 0 
THEN error := -1015;
 error_message := 'HBT: Asignar una línea en campo Almacén/Línea';   
 
END IF;
END IF;
 --NO PERMITE DOS OF ABIERTAS CON LA MISMA ORDEN DE PRODUCCION
IF :object_type = '202' 
AND (:transaction_type='A' or :transaction_type='U') 
THEN 

SELECT COUNT ("U_ASA_OP"||"U_ASA_VAR"||"U_ASA_RACK")
INTO cnt1
FROM OWOR T1 
WHERE ("U_ASA_OP"||"ItemCode"||"U_ASA_RACK")=(SELECT ("U_ASA_OP"||"ItemCode"||"U_ASA_RACK") 
												FROM OWOR T2 
												WHERE T2."DocEntry" = :list_of_cols_val_tab_del )
AND T1."U_ASA_PROC_OF" NOT IN ('P-AGR','P-TYS','P-EMP')
AND T1."Status"<>'C';
					 
IF :cnt1 > 1 
THEN error := -1016;
 error_message := 'HBT: No puede haber dos OF con el mismo número de Lote';   
 
END IF;
END IF;

/*
--NO PERMITE CERRAR OF SIN REGISTRO DE PARÁMETROS - LINEAS
IF :object_type = '202' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt1 
FROM "OWOR" T0 
INNER JOIN "WOR1" T1 ON T0."DocEntry" = T1."DocEntry" 
INNER JOIN "ORSC" T2 ON T1."ItemCode" = T2."VisResCode"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."Status"='L' 
AND (T0."U_ASA_PROC_OF"='P-LIX'
 	OR T0."U_ASA_PROC_OF" = 'P-BLA'
	OR T0."U_ASA_PROC_OF" = 'P-NEU'
	OR T0."U_ASA_PROC_OF" = 'P-DIF' 
	OR T0."U_ASA_PROC_OF" = 'P-TYS')
AND T1."ItemType"=290 
AND T2."ResGrpCod" = 3
AND T1."U_ASA_DEN" = 0;
 
IF :cnt1 > 0 
THEN error := -1017;
 error_message := 'HBT: Debe llenar el campo Densidad';   
 
END IF;
END IF;

--------------------------------------------------------------- 
IF :object_type = '202' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt1 
FROM "OWOR" T0 
INNER JOIN "WOR1" T1 ON T0."DocEntry" = T1."DocEntry" 
INNER JOIN "ORSC" T2 ON T1."ItemCode" = T2."VisResCode"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."Status"='L' 
AND (T0."U_ASA_PROC_OF"='P-LIX'
 	OR T0."U_ASA_PROC_OF" = 'P-BLA'
	OR T0."U_ASA_PROC_OF" = 'P-NEU'
	OR T0."U_ASA_PROC_OF" = 'P-DIF' 
	OR T0."U_ASA_PROC_OF" = 'P-TYS')
AND T1."ItemType" = 290 
AND T2."ResGrpCod" = 3
AND T1."U_ASA_PH" = 0;
 
IF :cnt1 > 0 
THEN error := -1018;
 error_message := 'HBT: Debe llenar el campo Ph'; 
 
END IF;
END IF;
--------------------------------------------------------------- 
IF :object_type = '202' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt1 
FROM "OWOR" T0 
INNER JOIN "WOR1" T1 ON T0."DocEntry" = T1."DocEntry" 
INNER JOIN "ORSC" T2 ON T1."ItemCode" = T2."VisResCode"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."Status"='L' 
AND (T0."U_ASA_PROC_OF"='P-LIX'
 	OR T0."U_ASA_PROC_OF" = 'P-BLA'
	OR T0."U_ASA_PROC_OF" = 'P-NEU'
	OR T0."U_ASA_PROC_OF"='P-DIF' 
	OR T0."U_ASA_PROC_OF"='P-TYS')
AND T1."ItemType"=290 
AND T2."ResGrpCod" = 3
AND T1."U_ASA_TEM" = 0;
 
IF :cnt1 > 0 
THEN error := -1019;
 error_message := 'HBT: Debe llenar el campo Temperatura';   
 
END IF;
END IF;
---------------------------------------------------------------
IF :object_type = '202' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt1 
FROM "OWOR" T0 
INNER JOIN "WOR1" T1 ON T0."DocEntry" = T1."DocEntry" 
INNER JOIN "ORSC" T2 ON T1."ItemCode" = T2."VisResCode"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."Status"='L' 
AND (T0."U_ASA_PROC_OF"='P-LIX'
	OR T0."U_ASA_PROC_OF"='P-BLA'
	OR T0."U_ASA_PROC_OF"='P-NEU' 
	OR T0."U_ASA_PROC_OF"='P-DIF' 
	OR T0."U_ASA_PROC_OF"='P-TYS')
AND T1."ItemType"=290 
AND T2."ResGrpCod" = 3
AND T1."U_ASA_HORA_INI" IS NULL;
 
IF :cnt1 > 0 
THEN error := -1020;
 error_message := 'HBT: Debe llenar el campo Hora Inicio';   
 
END IF;
END IF;
---------------------------------------------------------------
IF :object_type = '202' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt1 
FROM "OWOR" T0 
INNER JOIN "WOR1" T1 ON T0."DocEntry" = T1."DocEntry" 
INNER JOIN "ORSC" T2 ON T1."ItemCode" = T2."VisResCode"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."Status"='L' 
AND T0."U_ASA_PROC_OF"='P-BLA'
AND T1."ItemType"=290 
AND T2."ResGrpCod" = 3
AND T1."U_ASA_ORP"<=0;
 
IF :cnt1 > 0 
THEN error := -1021;
 error_message := 'HBT: Debe llenar el campo ORP';   
 
END IF;
END IF;
*/
---------------------------------------------------------------     
IF :object_type = '202' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt1 
FROM "OWOR" T0 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."Status" = 'R'
AND T0."U_ASA_PROC_OF"='P-BLA'
AND (T0."U_ASA_TOMA" IS NULL 
	OR T0."U_ASA_TOMA" = '') ;
 
IF :cnt1 > 0 
THEN error := -1022;
 error_message := 'HBT: Debe llenar el campo Blanqueo - Tanque';   
 
END IF;
END IF;
 --------------------------------------------------------------- 
/*
IF :object_type = '202' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt1 
FROM "OWOR" T0 
INNER JOIN "WOR1" T1 ON T0."DocEntry" = T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."Status"='L' 
AND T0."U_ASA_PROC_OF"='P-TYS'
AND T1."ItemType"=290
AND T1."U_ASA_HUM" = 0;
 
IF :cnt1 > 0 
THEN error := -1023;
 error_message := 'HBT: Debe llenar el campo Humedad';   
 
END IF;
END IF;
*/
--------------------------------------------------------------- 
--Valida que la serie corresponda al proceso
 IF :object_type = '202' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt1 
FROM OWOR T0 
INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T1."Remark" <>  T0."U_ASA_PROC_OF";

IF :cnt1 > 0 
THEN error := -1024;
 error_message := 'HBT: La serie no corresponde al proceso que se esta registrando';   
 
END IF;
END IF;
 --------------------------------------------------------------- 
 --Validar campo Rack en la orden de fabricación de Pinchado

IF :object_type = '202' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN select
	 COUNT(*) 
into cnt1 
from "OWOR" T0 
where T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."U_ASA_PROC_OF" = 'P-PIN' 
AND (T0."U_ASA_RACK_PIN" IS NULL 
	OR T0."U_ASA_RACK_PIN" = '');
 
IF :cnt1 > 0 
THEN error := -1025;
error_message := 'HBT: Debe llenar el campo Rack';

END IF;
END IF;
 --------------------------------------------------------------- 
 --RESPONSABLE DE REJILLA OBLIGATORIO EN RECIBO DE PRODUCCION

IF :object_type = '59' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt 
FROM OIGN T0 
INNER JOIN IGN1 T1 ON T0."DocEntry"=T1."DocEntry" 
INNER JOIN OITT T2 ON T1."ItemCode"=T2."Code"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T1."BaseType"='202' 
AND T2."U_ASA_PROC_LM" = 'P-PIN'
AND(T1."U_ASA_RES" IS NULL OR T1."U_ASA_RES"=' ');
 
IF :cnt > 0 
THEN error := -1026;
 error_message := 'HBT: Debe registrar el responsable de la rejilla';
 
END IF;
END IF;
 --NUMERO DE REJILLA OBLIGATORIO EN RECIBO DE PRODUCCION

IF :object_type = '59' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt 
FROM OIGN T0 
INNER JOIN IGN1 T1 ON T0."DocEntry"=T1."DocEntry" 
INNER JOIN OITT T2 ON T1."ItemCode"=T2."Code"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T1."BaseType"='202' 
AND (T2."U_ASA_PROC_LM" = 'P-PIN' 
OR T2."U_ASA_PROC_LM" = 'P-DIF')
AND(T1."U_ASA_REJI" IS NULL OR T1."U_ASA_REJI"='');
 
IF :cnt > 0 
THEN error := -1027;
 error_message := 'HBT: Debe registrar el número de la rejilla';
 
END IF;
END IF;
--NO PERMITE RECIBO DE PRODUCCION CON NORMA DE REPARTO NRK001
IF :object_type = '59' 
AND (:transaction_type='A' or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt 
FROM OIGN T0 
INNER JOIN IGN1 T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T1."BaseType"='202' 
AND T1."OcrCode3"='NRK001' ;
IF :cnt > 0 
THEN error := -1028;
error_message := 'HBT: Modificar el centro de costos agrícola';
END IF;
END IF;
---------------------------------------------------------------------------------------------------------------
--NO PERMITE RECIBO DE RECHAZADOS SIN MOTIVO EN AGRICOLA
IF :object_type = '59' 
AND (:transaction_type='A' or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt 
FROM OIGN T0 
INNER JOIN IGN1 T1 ON T0."DocEntry"=T1."DocEntry" 
INNER JOIN OITT T2 ON T1."ItemCode" = T2."Code"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T1."BaseType"='202' 
AND T1."TranType"= 'R'
AND T2."U_ASA_PROC_LM" = 'P-AGR' 
AND T1."U_ASA_MRR_01" = 0
AND T1."U_ASA_MRR_02" = 0
AND T1."U_ASA_MRR_03" = 0
AND T1."U_ASA_MRR_04" = 0
AND T1."U_ASA_MRR_05" = 0
AND T1."U_ASA_MRR_06" = 0
AND T1."U_ASA_MRR_07" = 0
AND T1."U_ASA_MRR_08" = 0
AND T1."U_ASA_MRR_09" = 0
AND T1."U_ASA_MRR_10" = 0
AND T1."U_ASA_MRR_11" = 0
AND T1."U_ASA_MRR_12" = 0
AND T1."U_ASA_MRR_13" = 0
AND T1."U_ASA_MRR_14" = 0
AND T1."U_ASA_MRR_15" = 0
AND T1."U_ASA_MRR_16" = 0
;
IF :cnt > 0 
THEN error := -1029;
error_message := 'HBT: Ingresar al menos un motivo de rechazo';
END IF;
END IF;
---------------------------------------------------------------------------------------------------------------
--NO PERMITE RECIBO DE RECHAZADOS SIN MOTIVO EN TINTURADO
IF :object_type = '59' 
AND (:transaction_type='A' or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt 
FROM OIGN T0  
INNER JOIN IGN1 T1 ON T0."DocEntry" = T1."DocEntry" 
INNER JOIN OITT T2 ON T1."ItemCode" = T2."Code"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T1."BaseType"='202' 
AND T1."TranType"= 'R'
AND T2."U_ASA_PROC_LM" = 'P-TYS' 
AND T1."U_ASA_MRC_01" = 0
AND T1."U_ASA_MRC_02" = 0
AND T1."U_ASA_MRC_03" = 0
AND T1."U_ASA_MRC_04" = 0
AND T1."U_ASA_MRC_05" = 0
AND T1."U_ASA_MRC_06" = 0
AND T1."U_ASA_MRC_07" = 0
AND T1."U_ASA_MRC_08" = 0
AND T1."U_ASA_MRC_09" = 0
AND T1."U_ASA_MRC_10" = 0
AND T1."U_ASA_MRC_11" = 0
AND T1."U_ASA_MRC_12" = 0
AND T1."U_ASA_MRC_13" = 0
AND T1."U_ASA_MRC_14" = 0
AND T1."U_ASA_MRC_15" = 0
AND T1."U_ASA_MRC_16" = 0
AND T1."U_ASA_MRC_17" = 0
AND T1."U_ASA_MRC_18" = 0
AND T1."U_ASA_MRC_19" = 0
;
IF :cnt > 0 
THEN error := -1030;
error_message := 'HBT: Ingresar al menos un motivo de rechazo';
END IF;
END IF;
---------------------------------------------------------------------------------------------------------------
--No permite lote en OF con 9 caracteres
IF :object_type = '202' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN select
	 COUNT(*) 
into cnt1 
from "OWOR" T0 
where T0."DocEntry" = :list_of_cols_val_tab_del
AND T0."U_ASA_REPROC" = '02'
AND LENGTH(T0."U_ASA_OP")<>10;
 
IF :cnt1 > 0 
THEN error := -1031;
error_message := 'HBT: Revisar numero de Lote';
 
END IF;
END IF;
---------------------------------------------------------------------------------------------------------------
--No permite crear OF con lote que no ha sido revalorizado

IF :object_type = '60' 
AND (:transaction_type='A' or :transaction_type='U')
THEN SELECT COUNT(*) INTO cnt1 
FROM OIGE T0 
INNER JOIN IGE1 T1 ON T0."DocEntry" = T1."DocEntry" 
INNER JOIN OWOR T2 ON T1."BaseEntry" = T2."DocEntry"
INNER JOIN OITM T3 ON T1."ItemCode" = T3."ItemCode" 
INNER JOIN OITL T4 ON T0."DocEntry" = T4."DocEntry"
INNER JOIN ITL1 T5 ON T4."LogEntry" = T5."LogEntry" 
INNER JOIN OBTN T6 ON T5."SysNumber" = T6."SysNumber"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del
AND T6."DistNumber" NOT IN (SELECT T7."DistNumber" FROM OBVL T7 
WHERE T7."DocType"=162 AND T7."ItemCode"=T1."ItemCode")
AND T6."ItemCode"=T1."ItemCode"
AND T2."U_ASA_PROC_OF"='P-PIN'
AND T3."U_ASA_TIPO"='02'
--AND SUBSTRING(T6."DistNumber",10,1) = 'M'
AND (CASE WHEN LENGTH(T6."DistNumber")=12 THEN SUBSTRING(T6."DistNumber",10,1)
                  WHEN LENGTH(T6."DistNumber")=11 THEN SUBSTRING(T6."DistNumber",8,1) ELSE 'P' END) = 'M'
;
	IF :cnt1 > 0 
	THEN error := -1032;
	error_message := 'HBT: No puede consumir si no hay revalorización del lote';
	END IF;
END IF;

---------------------------------------------------------------------------------------------------------------
--No permite lote en recibo que no corresponde a lote de OF
IF :object_type = '59' 
AND (:transaction_type='A' or :transaction_type='U') 
THEN SELECT COUNT(*) INTO cnt1
FROM OIGN T0 
INNER JOIN IGN1 T1 ON T0."DocEntry" = T1."DocEntry"
INNER JOIN OWOR T2 ON T2."DocEntry" = T1."BaseEntry" AND T1."ItemCode" = T2."ItemCode"
INNER JOIN OBVL T3 ON T0."DocEntry"= T3."DocEntry" AND T1."ItemCode" = T3."ItemCode"
WHERE T1."DocEntry" = :list_of_cols_val_tab_del
AND T2."U_ASA_PROC_OF" <> 'P-AGR'
AND T2."U_ASA_OP" <> SUBSTRING(T3."DistNumber",1,10)
AND T2."U_ASA_REPROC" = '02'
;
	IF :cnt1 > 0
	THEN error := -1033;
	error_message := 'HBT: Lote no corresponde a OF';
	END IF;
END IF;

---------------------------------------------------------------------------------------------------------------
--No permite crear el lote en la OF si no corresponde al Rack Selecccionado
IF :object_type = '202' 
AND (:transaction_type='A' 	or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt1 
FROM "OWOR" T0 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."U_ASA_PROC_OF"='P-PIN'
AND RIGHT (T0."U_ASA_OP",1)<>T0."U_ASA_RACK_PIN";
 
IF :cnt1 > 0 
THEN error := -1034;
 error_message := 'HBT: El lote no corresponde al número de RACK PINCHADO';   
 
END IF;
END IF;
---------------------------------------------------------------------------------------------------------------
--No permite crear si el comentario y el lote de la OF no son los mismos
IF :object_type = '202' 
AND (:transaction_type='A' 	or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt1 
FROM "OWOR" T0 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."U_ASA_PROC_OF"<>'P-AGR'
AND T0."U_ASA_OP"<>T0."Comments";
 
IF :cnt1 > 0 
THEN error := -1035;
 error_message := 'HBT: El comentario no coincide con el N° de Lote';   
 
END IF;
END IF;
---------------------------------------------------------------
IF :object_type = '202' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt1 
FROM "OWOR" T0 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."Status" = 'R'
AND T0."U_ASA_PROC_OF" NOT IN ('P-AGR','P-PIN','P-EMP', 'P-REEMP')
AND (T0."U_ASA_ETAP" IS NULL 
	OR T0."U_ASA_ETAP" = ' ') ;
 
IF :cnt1 > 0 
THEN error := -1036;
 error_message := 'HBT: Debe llenar el campo Etapa';   
 
END IF;
END IF;
---------------------------------------------------------------
IF :object_type = '202' 
AND (:transaction_type='A'	or :transaction_type='U') 
THEN SELECT COUNT(*) INTO cnt1 
FROM OWOR T0 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."U_ASA_PROC_OF" <> 'P-AGR'
AND T0."PlannedQty"<(T0."CmpltQty"+T0."RjctQty");
	IF :cnt1 > 0 
	THEN error := -1037;
 	error_message := 'HBT: La cantidad recibida no debe superar la cantidad planificada';   
	END IF;
END IF;

---------------------------------------------------------------
--Validar que el proceso corresponda al item

IF :object_type = '202' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN select
	 COUNT(*) 
into cnt1 
from OWOR T0 INNER JOIN OITT T1 
ON T0."ItemCode" = T1."Code"
where T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."U_ASA_PROC_OF" <> T1."U_ASA_PROC_LM"
AND T0."U_ASA_PROC_OF" <> 'P-REEMP' ;

IF :cnt1 > 0 
THEN error := -1038;
error_message := 'HBT: El artículo no corresponde al Proceso';

END IF;
END IF;
---------------------------------------------------------------
--SELECCIONAR UN TIPO DE OBSERVACION EN EL RECIBO DE TINTURADO (CALIDAD)

IF :object_type = '59' 
AND (:transaction_type='A' or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt 
FROM OIGN T0 
INNER JOIN IGN1 T1 ON T0."DocEntry"=T1."DocEntry" 
INNER JOIN OITT T2 ON T1."ItemCode"=T2."Code"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T1."BaseType"='202' 
AND T1."TranType"='C' 
AND T2."U_ASA_PROC_LM" = 'P-TYS'
AND(T1."U_ASA_RESTR" IS NULL OR T1."U_ASA_RESTR"=' ');
	IF :cnt > 0 
	THEN error := -1039;
	error_message := 'HBT: Debe seleccionar un estado';
	END IF;
END IF;

---------------------------------------------------------------
--COLOR EN EL RECIBO DE PRODUCCION DE PROCESO DE DIFUSION

IF :object_type = '59' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt 
FROM OIGN T0 
INNER JOIN IGN1 T1 ON T0."DocEntry"=T1."DocEntry" 
INNER JOIN OITT T2 ON T1."ItemCode"=T2."Code"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T1."BaseType"='202' 
AND T2."U_ASA_PROC_LM" = 'P-DIF'
AND(T1."U_ASA_COLOR" IS NULL OR T1."U_ASA_COLOR"=' ');
 
IF :cnt > 0 
THEN error := -1040;
 error_message := 'HBT: Debe seleccionar el color';
 
END IF;
END IF;
---------------------------------------------------------------
--COLOCAR UN COMENTARIO EN EL RECIBO DE TINTURADO (CALIDAD)

IF :object_type = '59' 
AND (:transaction_type='A' or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt 
FROM OIGN T0 
INNER JOIN IGN1 T1 ON T0."DocEntry"=T1."DocEntry" 
INNER JOIN OITT T2 ON T1."ItemCode"=T2."Code"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T1."BaseType"='202' 
AND T1."TranType"='C' 
AND T2."U_ASA_PROC_LM" = 'P-TYS'
AND (T1."U_ASA_RESTR" = '02' OR T1."U_ASA_RESTR" = '03')
AND T1."U_ASA_FREE_TXT" IS NULL;
	IF :cnt > 0 
	THEN error := -1041;
	error_message := 'HBT: Debe llenar el comentario';
	END IF;
END IF;

--NO PERMITE REGISTRAR RECIBO CON CANTIDAD DIFERENTE A LA SUMA DE RECHAZADOS

IF :object_type = '59' 
AND (:transaction_type='A' OR :transaction_type='U') 
THEN SELECT COUNT(*) 
INTO cnt 
FROM OIGN T0 
INNER JOIN IGN1 T1 ON T0."DocEntry"=T1."DocEntry" 
INNER JOIN OITT T2 ON T1."ItemCode"=T2."Code"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T1."BaseType"='202' 
AND T1."TranType"='R' 
AND (T2."U_ASA_PROC_LM" = 'P-AGR' 
OR T2."U_ASA_PROC_LM" = 'P-TYS')
AND T1."Quantity" <> (
T1."U_ASA_MRR_01" + 
T1."U_ASA_MRR_02" + 
T1."U_ASA_MRR_03" + 
T1."U_ASA_MRR_04" + 
T1."U_ASA_MRR_05" + 
T1."U_ASA_MRR_06" + 
T1."U_ASA_MRR_07" + 
T1."U_ASA_MRR_08" + 
T1."U_ASA_MRR_09" + 
T1."U_ASA_MRR_10" + 
T1."U_ASA_MRR_11" + 
T1."U_ASA_MRR_12" + 
T1."U_ASA_MRR_13" + 
T1."U_ASA_MRR_14" +
T1."U_ASA_MRR_15" +
T1."U_ASA_MRR_16" +
T1."U_ASA_MRC_01" + 
T1."U_ASA_MRC_02" + 
T1."U_ASA_MRC_03" + 
T1."U_ASA_MRC_04" + 
T1."U_ASA_MRC_05" + 
T1."U_ASA_MRC_06" + 
T1."U_ASA_MRC_07" + 
T1."U_ASA_MRC_08" + 
T1."U_ASA_MRC_09" + 
T1."U_ASA_MRC_10" + 
T1."U_ASA_MRC_11" + 
T1."U_ASA_MRC_12" + 
T1."U_ASA_MRC_13" + 
T1."U_ASA_MRC_14" + 
T1."U_ASA_MRC_15" + 
T1."U_ASA_MRC_16" + 
T1."U_ASA_MRC_17" + 
T1."U_ASA_MRC_18" + 
T1."U_ASA_MRC_19" + 
T1."U_ASA_MRC_20");
	IF :cnt > 0 
	THEN error := -1042;
	error_message := 'HBT: Cantidad debe ser igual a la suma de rechazados';
 	END IF;
END IF;


-- NO PERMITE SALIDA DIFERENTE A REVALORIZACION

IF :object_type = '60' 
AND (:transaction_type='A' or :transaction_type='U') 
THEN SELECT	 COUNT(*) 
INTO cnt 
FROM OIGE T0 
INNER JOIN IGE1 T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."U_ASA_TIP_SAL" NOT IN ('03','04','05')
AND T1."BaseType" = '-1'
AND T0."UserSign" = '14';
	IF :cnt > 0 
	THEN error := -1043;
	error_message := 'HBT: No puede hacer salida con tipo diferente a Revalorizacion o Reproceso';
	END IF;
END IF;

-- NO PERMITE SALIDA DIFERENTE A REPROCESO
IF :object_type = '60' 
AND (:transaction_type='A' or :transaction_type='U') 
THEN SELECT	 COUNT(*) 
INTO cnt 
FROM OIGE T0 
INNER JOIN IGE1 T1 ON T0."DocEntry"=T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."U_ASA_TIP_SAL" <> '03'
AND T1."BaseType" = '-1'
AND T0."UserSign" = '11';
	IF :cnt > 0 
	THEN error := -1044;
	error_message := 'HBT: No puede hacer salida con tipo diferente a Revalorizacion';
	END IF;
END IF;
--COLOCAR REJILLA EN EL RECIBO DE TINTURADO (CALIDAD) CUANDO ES UN REPROCESO

IF :object_type = '59' 
AND (:transaction_type='A' or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt 
FROM OIGN T0 
INNER JOIN IGN1 T1 ON T0."DocEntry"=T1."DocEntry" 
INNER JOIN OITT T2 ON T1."ItemCode"=T2."Code"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T1."BaseType"='202' 
AND T1."TranType"='C' 
AND T2."U_ASA_PROC_LM" = 'P-TYS'
AND T1."U_ASA_RESTR" = '03'
AND(T1."U_ASA_REJI" IS NULL OR T1."U_ASA_REJI"='');
	IF :cnt > 0 
	THEN error := -1045;
	error_message := 'HBT: Debe llenar la rejilla cuando es Recibo';
	END IF;
END IF;

--COLOCAR REJILLA EN LA ENTRADA CUANDO ES UN REPROCESO

IF :object_type = '59' 
AND (:transaction_type='A' or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt 
FROM OIGN T0 
INNER JOIN IGN1 T1 ON T0."DocEntry"=T1."DocEntry" 
INNER JOIN OITT T2 ON T1."ItemCode"=T2."Code"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."U_ASA_TIP_ENT"='03' 
AND(T1."U_ASA_REJI" IS NULL OR T1."U_ASA_REJI"='');
	IF :cnt > 0 
	THEN error := -1046;
	error_message := 'HBT: Debe llenar la rejilla cuando es un reproceso';
	END IF;
END IF;

--NO PERMITE REGISTRA RECIBOS DE PRODUCCION DE TYS

IF :object_type = '59' 
AND (:transaction_type='A' or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt 
FROM OIGN T0 
INNER JOIN IGN1 T1 ON T0."DocEntry"=T1."DocEntry" 
INNER JOIN OITT T2 ON T1."ItemCode"=T2."Code"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T1."BaseType"='202' 
AND T1."TranType"='C' 
AND T2."U_ASA_PROC_LM" = 'P-TYS'
AND T0."UserSign" = '12';
	IF :cnt > 0 
	THEN error := -1047;
	error_message := 'HBT: No puede realizar recibos de Tinturado y Secado';
	END IF;
END IF;
--------------------------------------------------------------------------------------------------------------
-- NO PERMITE REVALORIZACIÓN EN ALMACEN DISTINTO A EMPAQUE

IF :object_type = '162' 
AND (:transaction_type='A' or :transaction_type='U') 
THEN SELECT COUNT(*) 
INTO cnt 
FROM OMRV T0 
INNER JOIN MRV1 T1 ON T0."DocEntry" = T1."DocEntry"
LEFT JOIN OITT T2 ON T1."ItemCode" = T2."Code"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T2."U_ASA_PROC_LM" = 'P-TYS'
AND T1."WhsCode" <> 'EM';
	IF :cnt > 0 
	THEN error := -1048;
	error_message := 'HBT: No puede hacer revalorización de productos en almacén diferente a Empaque';
	END IF;
END IF;

-----------------------------------------------------------------------------------------------------------------
--Valida que la serie corresponda a la clase de operación
IF :object_type = '59' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT("DocNum") 
INTO cnt1 
FROM OIGN T0
INNER JOIN IGN1 T1 ON T0."DocEntry" = T1."DocEntry" 
LEFT JOIN NNM1 T2 ON T0."Series" = T2."Series"
LEFT JOIN OITT T3 ON T1."ItemCode" = T3."Code"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T3."U_ASA_PROC_LM" ='P-AGR' AND (T2."Remark" IS NULL
OR T2."Remark" <>  T1."TranType") AND T2."SeriesName" <> 'Primario';

IF :cnt1 > 0 
THEN error := -1049;
 error_message := 'HBT: La serie no corresponde a la clase de operación COMPLETAR o RECHAZAR';   
 
END IF;
END IF;
----------------------------------------------------------------------------------------------------------------------
---Validación: No permite guardar Orden de Fabricación de Tinturado con un item
---y lote ya registrado, que no se haya reprocesado 
IF :object_type = '202' 
AND (:transaction_type='A' or :transaction_type='U') 
THEN 

SELECT COUNT ("U_ASA_OP"||"U_ASA_VAR"||"U_ASA_RACK")
INTO cnt1
FROM OWOR T1 
WHERE ("U_ASA_OP"||"ItemCode"||"U_ASA_RACK")=(SELECT ("U_ASA_OP"||"ItemCode"||"U_ASA_RACK") 
												FROM OWOR T2 
												WHERE T2."DocEntry" = :list_of_cols_val_tab_del )
AND T1."U_ASA_PROC_OF" IN ('P-TYS','P-EMP')
AND T1."U_ASA_REPROC" <> '01'
AND T1."Status"<>'C';
					 
IF :cnt1 > 1 
THEN error := -1050;
 error_message := 'HBT: No puede haber dos OF con el mismo número de Lote';   
 
END IF;
END IF;

-- NO PERMITE REVALORIZAR LOTES MAS DE UNA VEZ
IF :object_type = '162' 
AND (:transaction_type='A' or :transaction_type='U') 
THEN SELECT COUNT(*) 
INTO cnt 
FROM OMRV T0 
INNER JOIN MRV1 T1 ON T0."DocEntry" = T1."DocEntry"
INNER JOIN MRV3 T2 ON T0."DocEntry" = T2."DocEntry" AND T1."LineNum" = T2."LineNum"
INNER JOIN 
(SELECT T12."SNBNum", T11."ItemCode" FROM OMRV T10 
INNER JOIN MRV1 T11 ON T10."DocEntry" = T11."DocEntry"
INNER JOIN MRV3 T12 ON T10."DocEntry" = T12."DocEntry" AND T11."LineNum" = T12."LineNum"
WHERE T10."DocEntry" = :list_of_cols_val_tab_del) A ON A."SNBNum" = T2."SNBNum" AND A."ItemCode" = T1."ItemCode"
;
	IF :cnt > 1 
	THEN error := -1051;
	error_message := 'HBT: No puede revalorizar mismo lote más de una vez';
	END IF;
END IF; 

--COLOCAR COMENTARIO EN LA ENTRADA CUANDO ES UN REPROCESO

IF :object_type = '59' 
AND (:transaction_type='A' or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt 
FROM OIGN T0 
INNER JOIN IGN1 T1 ON T0."DocEntry"=T1."DocEntry" 
INNER JOIN OITT T2 ON T1."ItemCode"=T2."Code"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T0."U_ASA_TIP_ENT"='03' 
AND (T0."Comments" IS NULL OR T0."Comments" = '');

	IF :cnt > 0 
	THEN error := -1052;
	error_message := 'HBT: Debe llenar el comentario cuando es un reproceso';
	END IF;
END IF;
 
 --NO PERMITE DOS OF ABIERTAS CON LA MISMA ORDEN DE PRODUCCION
IF :object_type = '202' 
AND (:transaction_type='A' or :transaction_type='U') 
THEN 

SELECT COUNT ("U_ASA_OP"||"U_ASA_VAR"||"U_ASA_RACK_PIN")
INTO cnt1
FROM OWOR T1 
WHERE ("U_ASA_OP"||"ItemCode"||"U_ASA_RACK_PIN")=(SELECT ("U_ASA_OP"||"ItemCode"||"U_ASA_RACK_PIN") 
												FROM OWOR T2 
												WHERE T2."DocEntry" = :list_of_cols_val_tab_del )
AND T1."U_ASA_PROC_OF" = 'P-PIN'
AND T1."Status"<>'C';
					 
IF :cnt1 > 1 
THEN error := -1053;
 error_message := 'HBT: No puede haber dos OF con el mismo número de Lote';   
 
END IF;
END IF;


-- NO RECIBO CON COSTO CERO (0)

IF :object_type = '59' 
AND (:transaction_type='A' 
	or :transaction_type='U') 
THEN SELECT
	 COUNT(*) 
INTO cnt 
FROM OIGN T0 INNER JOIN IGN1 T1 ON T0."DocEntry" = T1."DocEntry"
WHERE T1."DocEntry" = :list_of_cols_val_tab_del 
AND T0."RelatedTyp" = -1 
AND T1."BaseType" = 202
AND T1."StockPrice" <= 0 ;
	IF :cnt > 0 
	THEN error := -1054;
	error_message := 'HBT: No puede ingresar artículos con costos cero';
	END IF;
END IF;

---------------------------------------------------------------------------------------------------------------
--No permite crear OF con lote que no ha sido revalorizado
---------------------------------------------------------------------------------------------------------------
IF :object_type = '60' AND (:transaction_type='A' OR :transaction_type='U') THEN
SELECT  COUNT(*) INTO cnt
FROM OIGE T0 
INNER JOIN IGE1 T1 ON T0."DocEntry" = T1."DocEntry" 
INNER JOIN OWOR T2 ON T1."BaseEntry" = T2."DocEntry"
INNER JOIN OITM T3 ON T1."ItemCode" = T3."ItemCode" 
INNER JOIN OITL T4 ON T0."DocEntry" = T4."DocEntry"
INNER JOIN ITL1 T5 ON T4."LogEntry" = T5."LogEntry" 
INNER JOIN OBTN T6 ON T5."SysNumber" = T6."SysNumber"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND (
    -- Primera y segunda condiciones combinadas
    T6."DistNumber" IN (
        SELECT T3."U_ASA_OP"
        FROM OIGN T0  
        INNER JOIN IGN1 T1 ON T0."DocEntry" = T1."DocEntry"
        INNER JOIN OWOR T3 ON T1."BaseEntry" = T3."DocEntry"
        WHERE T3."U_ASA_OP" = T6."DistNumber"
        --AND T0."Series" = 105
		AND T1."TranType"= 'R'
		AND T3."ItemCode"=T6."ItemCode"
        AND T3."U_ASA_PROC_OF" = 'P-TYS'
    )
    AND T6."DistNumber"  NOT IN (
        SELECT T7."DistNumber"
        FROM OBVL T7 
        WHERE T7."DocType" = 162 
        AND T7."ItemCode" = T1."ItemCode"
    )
)
AND T6."ItemCode"=T1."ItemCode"
AND T2."U_ASA_PROC_OF"='P-EMP'
AND T3."U_ASA_TIPO"='02';
IF :cnt > 0 
	THEN error := -1055;
	error_message := 'HBT: Existe un procesos de rechazo pero aún no se ha realizado la revalorización';
	END IF;
END IF;
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
----- No permite crear el recibo si todos los componente no se han consumido-----------
IF :object_type = '59' 
AND (:transaction_type='A' or :transaction_type='U') THEN 
Select COUNT (*) into cnt from  (
Select T1."ItemCode",T1."ItemName",T1."PlannedQty",
(SELECT COALESCE(Sum(T22."Quantity"),0)
FROM  IGE1 T22 
WHERE 
CAST(T22."BaseRef" AS NVARCHAR)=  CAST(T0."DocNum" AS NVARCHAR)
AND T22."ItemCode"=T1."ItemCode"
AND T22."BaseLine"=T1."LineNum") AS "Total"
From IGN1 T21
INNER JOIN OWOR T0 ON CAST(T21."BaseRef" AS NVARCHAR)=  CAST( T0."DocNum" AS NVARCHAR)
INNER JOIN WOR1 T1 ON T0."DocEntry" = T1."DocEntry"
WHERE
T21."DocEntry"= :list_of_cols_val_tab_del AND
T1."ItemType" = 4
AND T0."Series" != 37
AND T0."Type" != 'D'
GROUP BY 
T1."ItemCode",T1."PlannedQty",T1."ItemName",T1."LineNum",T0."DocNum"
Having T1."PlannedQty" != (SELECT COALESCE(Sum(T22."Quantity"),0)
							FROM  IGE1 T22 
							WHERE 
							CAST(T22."BaseRef" as varchar)= CAST( T0."DocNum" as varchar)
							AND T22."ItemCode"=T1."ItemCode"
							AND T22."BaseLine"=T1."LineNum")
							) AS Consumo;
 
IF :cnt > 0 
THEN error := -1056;
 error_message := 'HBT: No puede crear el recibo de producción si no se ha realizado el consumo de todos los componentes';
 
END IF;
END IF;
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
END