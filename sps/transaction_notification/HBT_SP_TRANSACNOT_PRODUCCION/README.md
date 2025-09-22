# HBT_SP_TRANSACNOT_PRODUCCION

**Módulo:** Producción / Inventarios  
**Objetivos:** Validaciones de negocio en creación/actualización de OF (OWOR), Entradas (OIGN/IGN1), Salidas (OIGE/IGE1) y Revalorización (OMRV/MRV1).

## Reglas principales (ejemplos)
- R-1000: Campo Lote obligatorio (OWOR).
- R-1005: No dos OF abiertas de la misma variedad.
- R-1006: No cerrar OF sin consumos de componentes.
- R-1007: No cerrar OF sin recibos de PT.
- R-1008: Prohíbe recibo de completos en almacén DS (cuarentena).
- R-1011: Tipo de entrada obligatorio (OIGN).
- R-1032: Prohíbe consumo si lote no ha sido revalorizado (reproceso).

## Performance
- Indexar claves usadas en filtros y joins: `DocEntry`, `ItemCode`, `BaseEntry`, `DistNumber`.
- Validar costo con `EXPLAIN PLAN` en QA y adjuntar notas en `/explain`.

## Cómo contribuir
1. Agregar regla como YAML en `/rules`.
2. Añadir caso(s) de prueba en `/tests/unit` y dataset(s) en `/tests/qa`.
3. Actualizar `rules/INDEX.yaml` y `metadata.yaml` si aplica.
