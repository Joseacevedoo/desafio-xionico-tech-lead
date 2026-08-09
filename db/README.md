# Base de datos

Scripts SQL Server para reproducir la base usada por la PoC.

Orden sugerido:

```text
01_schema.sql
02_procedures.sql
03_seed_data.sql
04_app_user.sql
```

Los scripts crean la base `xionico_orders`, las tablas requeridas por el backend, datos mínimos de demo, el stored procedure transaccional `dbo.sp_RegisterOrder` y la vista `dbo.vw_DailyOrderSummary`.

Docker Compose ejecuta automáticamente este orden mediante `init-db.sh`; no es necesario aplicar los archivos manualmente para la puesta en marcha estándar.

La vista consolida pedidos por fecha, estado y cliente para consumo del endpoint de métricas.

`04_app_user.sql` crea el login restringido que utiliza el backend. La contraseña se recibe desde `DB_APP_PASSWORD` durante la inicialización con Docker.

## Usuario demo

```text
username: operador
password: Demo123!
```

También se crea un usuario inactivo para pruebas:

```text
username: operador_inactivo
password: Demo123!
```

## Notas

- El backend usa `DEFAULT_CUSTOMER_CODE=CUST-DEFAULT`; por eso el seed incluye ese cliente activo.
- El hash de password fue generado con `pwdlib.PasswordHash.recommended()`, compatible con el backend.
- `DB_APP_PASSWORD` debe mantenerse fuera del repositorio y reemplazarse por un secreto seguro en ambientes reales.

## Evolución del modelo de inventario

La PoC mantiene un saldo total por producto. Para una operación logística con múltiples depósitos se propone evolucionar el modelo con:

- Depósitos, zonas y ubicaciones físicas o posiciones.
- Saldos por producto y ubicación.
- Cantidades disponibles, reservadas y comprometidas.
- Movimientos auditables de ingreso, egreso, ajuste y transferencia.
- Lotes, series o vencimientos cuando el tipo de producto lo requiera.

Esta evolución permitiría conocer no solo cuánto stock existe, sino dónde está y qué movimientos explican el saldo actual.
