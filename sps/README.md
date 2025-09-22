# SP's (Stored Procedures)

Carpetas por dominio funcional:
- Compras
- Ventas
- Socios de Negocios

Incluye:
- Archivo `.sql` del SP
- `metadata.yaml` con tablas, objetos, UDFs y owner
- `rules/` con reglas atómicas (IF/THEN)
- `tests/` con casos unitarios
- `explain/` para planes/observaciones de performance

Además: carpeta `transaction_notification` con SPs ligados a eventos SBO.
