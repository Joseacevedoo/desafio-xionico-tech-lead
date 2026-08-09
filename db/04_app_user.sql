/*
    Crea el login y usuario restringido utilizado por el backend.

    La contraseña se recibe mediante la variable DB_APP_PASSWORD
    durante la inicialización de Docker y no se almacena en Git.
*/

USE master;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.sql_logins
    WHERE name = N'xionico_app'
)
BEGIN
    CREATE LOGIN xionico_app
    WITH PASSWORD = '$(DB_APP_PASSWORD)',
         CHECK_POLICY = ON,
         CHECK_EXPIRATION = OFF;
END;
GO

USE xionico_orders;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_principals
    WHERE name = N'xionico_app'
)
BEGIN
    CREATE USER xionico_app FOR LOGIN xionico_app;
END;
GO

GRANT SELECT ON dbo.users TO xionico_app;
GRANT SELECT ON dbo.customers TO xionico_app;
GRANT SELECT ON dbo.products TO xionico_app;
GRANT SELECT ON dbo.inventory TO xionico_app;
GRANT SELECT ON dbo.orders TO xionico_app;
GRANT SELECT ON dbo.order_items TO xionico_app;
GRANT SELECT ON dbo.vw_DailyOrderSummary TO xionico_app;
GRANT EXECUTE ON dbo.sp_RegisterOrder TO xionico_app;
GO
