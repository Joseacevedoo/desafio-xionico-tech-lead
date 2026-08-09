#!/bin/sh
set -eu

SQLCMD=/opt/mssql-tools18/bin/sqlcmd
SERVER="${DB_HOST:-sqlserver},${DB_PORT:-1433}"
: "${DB_APP_PASSWORD:?La variable DB_APP_PASSWORD es obligatoria}"

echo "Esperando a SQL Server en ${SERVER}..."

attempt=1
until "$SQLCMD" \
    -S "$SERVER" \
    -U sa \
    -P "$MSSQL_SA_PASSWORD" \
    -C \
    -Q "SELECT 1" \
    >/dev/null 2>&1
do
    if [ "$attempt" -ge 60 ]; then
        echo "SQL Server no estuvo disponible dentro del tiempo esperado." >&2
        exit 1
    fi

    attempt=$((attempt + 1))
    sleep 2
done

initialized=$("$SQLCMD" \
    -S "$SERVER" \
    -U sa \
    -P "$MSSQL_SA_PASSWORD" \
    -C \
    -h -1 \
    -W \
    -Q "SET NOCOUNT ON; SELECT CASE WHEN DB_ID(N'xionico_orders') IS NOT NULL AND OBJECT_ID(N'xionico_orders.dbo.sp_RegisterOrder', N'P') IS NOT NULL AND OBJECT_ID(N'xionico_orders.dbo.vw_DailyOrderSummary', N'V') IS NOT NULL THEN 1 ELSE 0 END;" \
    | tr -d '\r[:space:]')

if [ "$initialized" = "1" ]; then
    echo "La base xionico_orders ya está inicializada. No se requieren cambios."
    exit 0
fi

if "$SQLCMD" \
    -S "$SERVER" \
    -U sa \
    -P "$MSSQL_SA_PASSWORD" \
    -C \
    -h -1 \
    -W \
    -Q "SET NOCOUNT ON; SELECT CASE WHEN DB_ID(N'xionico_orders') IS NULL THEN 0 ELSE 1 END;" \
    | tr -d '\r[:space:]' \
    | grep -qx 1
then
    echo "La base existe, pero está incompleta. Para recrearla, eliminá primero el volumen de Docker." >&2
    exit 1
fi

for script in \
    /db/01_schema.sql \
    /db/02_procedures.sql \
    /db/03_seed_data.sql \
    /db/04_app_user.sql
do
    echo "Ejecutando $(basename "$script")..."
    "$SQLCMD" \
        -S "$SERVER" \
        -U sa \
        -P "$MSSQL_SA_PASSWORD" \
        -C \
        -b \
        -v "DB_APP_PASSWORD=$DB_APP_PASSWORD" \
        -i "$script"
done

echo "Base xionico_orders inicializada correctamente."
