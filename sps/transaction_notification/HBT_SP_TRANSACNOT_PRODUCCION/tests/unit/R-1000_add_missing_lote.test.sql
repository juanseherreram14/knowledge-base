-- GIVEN: OWOR con U_ASA_OP NULL/'' y U_ASA_PROC_OF NOT IN ('P-AGR','P-REEMP')
-- WHEN: transaction_type='A' sobre object_type='202'
-- THEN: error = -1000

-- 1) Seed de datos mínimos (usa la semilla en tests/qa si lo prefieres)
-- INSERT INTO OWOR (DocEntry, U_ASA_PROC_OF, U_ASA_OP, Status, ItemCode) VALUES (10001, 'P-EMP', '', 'R', 'ITEM-01');

-- 2) Simulación de llamada (pseudocódigo; adapta a tu harness de QA)
-- CALL HBT_SP_TRANSACNOT_PRODUCCION('202','A',..., :DocEntry:=10001, :error, :error_message);
-- EXPECT :error = -1000
