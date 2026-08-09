USE xionico_orders;
GO

DECLARE @demo_password_hash NVARCHAR(500) =
    N'$argon2id$v=19$m=65536,t=3,p=4$hXCaCpFBX8haAigAGhNnjA$uVeOw+2qNWQSCM8/jqXMFUIjQA6VnUmlBQ13C7UsUOI';

IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE username = N'operador')
BEGIN
    INSERT INTO dbo.users (username, display_name, password_hash, is_active)
    VALUES (N'operador', N'Operador Demo', @demo_password_hash, 1);
END;

IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE username = N'operador_inactivo')
BEGIN
    INSERT INTO dbo.users (username, display_name, password_hash, is_active)
    VALUES (N'operador_inactivo', N'Operador Inactivo', @demo_password_hash, 0);
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.customers WHERE code = N'CUST-DEFAULT')
BEGIN
    INSERT INTO dbo.customers (code, name, is_active)
    VALUES (N'CUST-DEFAULT', N'Cliente Demo S.A.', 1);
END;

IF NOT EXISTS (SELECT 1 FROM dbo.customers WHERE code = N'CUST-002')
BEGIN
    INSERT INTO dbo.customers (code, name, is_active)
    VALUES (N'CUST-002', N'Distribuidora Norte', 1);
END;

IF NOT EXISTS (SELECT 1 FROM dbo.customers WHERE code = N'CUST-003')
BEGIN
    INSERT INTO dbo.customers (code, name, is_active)
    VALUES (N'CUST-003', N'Cliente Inactivo', 0);
END;
GO

DECLARE @products TABLE (
    code NVARCHAR(50) NOT NULL,
    name NVARCHAR(200) NOT NULL,
    description NVARCHAR(500) NULL,
    unit_price DECIMAL(18,2) NOT NULL,
    is_active BIT NOT NULL,
    available_stock INT NOT NULL
);

INSERT INTO @products (code, name, description, unit_price, is_active, available_stock)
VALUES
    (N'PROD-001', N'Arroz largo fino 1 kg', N'Paquete de arroz largo fino de 1 kilogramo.', 1850.00, 1, 20),
    (N'PROD-002', N'Aceite de girasol 900 ml', N'Botella de aceite de girasol de 900 mililitros.', 2750.00, 1, 15),
    (N'PROD-003', N'Azúcar 1 kg', N'Paquete de azúcar refinada de 1 kilogramo.', 1420.50, 1, 25),
    (N'PROD-004', N'Yerba mate 1 kg', N'Paquete de yerba mate de 1 kilogramo.', 4950.00, 1, 10),
    (N'PROD-005', N'Harina 000 1 kg', N'Paquete de harina de trigo tipo 000.', 1180.00, 1, 40),
    (N'PROD-006', N'Fideos secos 500 g', N'Paquete de fideos secos de 500 gramos.', 1350.00, 1, 20),
    (N'PROD-007', N'Leche entera 1 L', N'Leche entera en envase de 1 litro.', 1600.00, 1, 5),
    (N'PROD-008', N'Café molido 500 g', N'Paquete de café molido de 500 gramos.', 6800.00, 1, 0),
    (N'PROD-009', N'Galletitas surtidas', N'Paquete de galletitas surtidas.', 2300.00, 1, 15),
    (N'PROD-010', N'Producto discontinuado', N'Producto inactivo reservado para pruebas.', 3000.00, 0, 10),
    (N'PROD-011', N'Agua mineral 1.5 L', N'Botella de agua mineral sin gas.', 1250.00, 1, 30),
    (N'PROD-012', N'Gaseosa cola 2.25 L', N'Botella de gaseosa sabor cola.', 3100.00, 1, 18),
    (N'PROD-013', N'Atún al natural 170 g', N'Lata de atún al natural.', 2850.00, 1, 12),
    (N'PROD-014', N'Puré de tomate 520 g', N'Envase de puré de tomate.', 980.00, 1, 35),
    (N'PROD-015', N'Mayonesa 500 g', N'Aderezo mayonesa en envase flexible.', 2450.00, 1, 16),
    (N'PROD-016', N'Sal fina 500 g', N'Paquete de sal fina de mesa.', 750.00, 1, 45),
    (N'PROD-017', N'Té negro 25 saquitos', N'Caja de té negro en saquitos.', 1750.00, 1, 22),
    (N'PROD-018', N'Mermelada de durazno 454 g', N'Frasco de mermelada de durazno.', 2650.00, 1, 14),
    (N'PROD-019', N'Jabón líquido 750 ml', N'Jabón líquido para manos.', 3200.00, 1, 9),
    (N'PROD-020', N'Papel higiénico 4 unidades', N'Paquete de cuatro rollos de papel higiénico.', 3900.00, 1, 20);

MERGE dbo.products AS target
USING @products AS source
    ON target.code = source.code
WHEN MATCHED THEN
    UPDATE SET
        name = source.name,
        description = source.description,
        unit_price = source.unit_price,
        is_active = source.is_active,
        updated_at = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
    INSERT (code, name, description, unit_price, is_active)
    VALUES (source.code, source.name, source.description, source.unit_price, source.is_active);

MERGE dbo.inventory AS target
USING (
    SELECT p.product_id, source.available_stock
    FROM @products AS source
    INNER JOIN dbo.products AS p
        ON p.code = source.code
) AS source
    ON target.product_id = source.product_id
WHEN MATCHED THEN
    UPDATE SET
        available_stock = source.available_stock,
        updated_at = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
    INSERT (product_id, available_stock)
    VALUES (source.product_id, source.available_stock);
GO
