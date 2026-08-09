USE xionico_orders;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

/* =========================================================
   Procedimiento almacenado para registrar pedidos

   Responsabilidades:
   - Validar el payload JSON.
   - Garantizar la idempotencia.
   - Validar usuario, cliente y productos activos.
   - Bloquear las filas de inventario durante la sección crítica.
   - Crear el pedido y sus detalles de forma atómica.
   - Descontar stock sin permitir valores negativos.
   - Devolver el identificador del pedido resultante.
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.sp_RegisterOrder
    @user_id          INT,
    @customer_id      INT,
    @idempotency_key  UNIQUEIDENTIFIER,
    @request_hash     CHAR(64),
    @items_json       NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    /* ---------- Validaciones estructurales previas a la transacción ---------- */
    IF @user_id IS NULL OR @user_id <= 0
    BEGIN
        RAISERROR(N'INVALID_USER_ID', 16, 1);
        RETURN;
    END;

    IF @customer_id IS NULL OR @customer_id <= 0
    BEGIN
        RAISERROR(N'INVALID_CUSTOMER_ID', 16, 1);
        RETURN;
    END;

    IF @idempotency_key IS NULL
    BEGIN
        RAISERROR(N'INVALID_IDEMPOTENCY_KEY', 16, 1);
        RETURN;
    END;

    SET @request_hash = UPPER(LTRIM(RTRIM(@request_hash)));

    IF @request_hash IS NULL
       OR LEN(@request_hash) <> 64
       OR @request_hash LIKE '%[^0-9A-F]%'
    BEGIN
        RAISERROR(N'INVALID_REQUEST_HASH', 16, 1);
        RETURN;
    END;

    IF @items_json IS NULL OR ISJSON(@items_json) <> 1
    BEGIN
        RAISERROR(N'INVALID_ITEMS_JSON', 16, 1);
        RETURN;
    END;

    /* Verifica que el valor JSON raíz sea un arreglo de ítems del pedido. */
    IF LEFT(LTRIM(@items_json), 1) <> N'['
    BEGIN
        RAISERROR(N'ITEMS_JSON_MUST_BE_ARRAY', 16, 1);
        RETURN;
    END;

    DECLARE @parsed_items TABLE
    (
        product_id  INT NULL,
        quantity    INT NULL
    );

    INSERT INTO @parsed_items (product_id, quantity)
    SELECT
        src.product_id,
        src.quantity
    FROM OPENJSON(@items_json)
    WITH
    (
        product_id INT '$.product_id',
        quantity   INT '$.quantity'
    ) AS src;

    DECLARE @item_count INT = (SELECT COUNT(*) FROM @parsed_items);

    IF @item_count = 0
    BEGIN
        RAISERROR(N'EMPTY_ORDER', 16, 1);
        RETURN;
    END;

    IF @item_count > 50
    BEGIN
        RAISERROR(N'ORDER_ITEMS_LIMIT_EXCEEDED', 16, 1);
        RETURN;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM @parsed_items
        WHERE product_id IS NULL OR product_id <= 0
    )
    BEGIN
        RAISERROR(N'INVALID_PRODUCT_ID', 16, 1);
        RETURN;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM @parsed_items
        WHERE quantity IS NULL OR quantity <= 0 OR quantity > 10000
    )
    BEGIN
        RAISERROR(N'INVALID_QUANTITY', 16, 1);
        RETURN;
    END;

    IF EXISTS
    (
        SELECT product_id
        FROM @parsed_items
        GROUP BY product_id
        HAVING COUNT(*) > 1
    )
    BEGIN
        RAISERROR(N'DUPLICATE_PRODUCT', 16, 1);
        RETURN;
    END;

    DECLARE @items TABLE
    (
        product_id  INT NOT NULL PRIMARY KEY,
        quantity    INT NOT NULL
    );

    INSERT INTO @items (product_id, quantity)
    SELECT product_id, quantity
    FROM @parsed_items;

    BEGIN TRY
        BEGIN TRANSACTION;

        /*
          El índice único sobre orders.idempotency_key junto con
          UPDLOCK/HOLDLOCK serializa las solicitudes concurrentes
          que utilizan la misma clave de idempotencia.
        */
        DECLARE
            @existing_order_id     INT,
            @existing_order_number NVARCHAR(30),
            @existing_total_amount DECIMAL(18,2),
            @existing_user_id      INT,
            @existing_request_hash CHAR(64);

        SELECT
            @existing_order_id = o.order_id,
            @existing_order_number = o.order_number,
            @existing_total_amount = o.total_amount,
            @existing_user_id = o.created_by_user_id,
            @existing_request_hash = o.request_hash
        FROM dbo.orders AS o WITH (UPDLOCK, HOLDLOCK)
        WHERE o.idempotency_key = @idempotency_key;

        IF @existing_order_id IS NOT NULL
        BEGIN
            IF @existing_user_id = @user_id
               AND @existing_request_hash = @request_hash
            BEGIN
                COMMIT TRANSACTION;

                SELECT
                    @existing_order_id AS order_id,
                    @existing_order_number AS order_number,
                    @existing_total_amount AS total_amount,
                    CAST(1 AS BIT) AS is_replay;

                RETURN;
            END;

            RAISERROR(N'IDEMPOTENCY_KEY_CONFLICT', 16, 1);
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.users
            WHERE user_id = @user_id
              AND is_active = 1
        )
        BEGIN
            RAISERROR(N'USER_NOT_FOUND_OR_INACTIVE', 16, 1);
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.customers
            WHERE customer_id = @customer_id
              AND is_active = 1
        )
        BEGIN
            RAISERROR(N'CUSTOMER_NOT_FOUND_OR_INACTIVE', 16, 1);
        END;

        IF EXISTS
        (
            SELECT 1
            FROM @items AS i
            LEFT JOIN dbo.products AS p
                ON p.product_id = i.product_id
            WHERE p.product_id IS NULL
        )
        BEGIN
            RAISERROR(N'PRODUCT_NOT_FOUND', 16, 1);
        END;

        IF EXISTS
        (
            SELECT 1
            FROM @items AS i
            INNER JOIN dbo.products AS p
                ON p.product_id = i.product_id
            WHERE p.is_active = 0
        )
        BEGIN
            RAISERROR(N'PRODUCT_INACTIVE', 16, 1);
        END;

        IF EXISTS
        (
            SELECT 1
            FROM @items AS i
            LEFT JOIN dbo.inventory AS inv
                ON inv.product_id = i.product_id
            WHERE inv.product_id IS NULL
        )
        BEGIN
            RAISERROR(N'INVENTORY_NOT_FOUND', 16, 1);
        END;

        /* Adquiere y mantiene bloqueos de actualización sobre todas las filas de inventario solicitadas. */
        DECLARE @locked_inventory TABLE
        (
            product_id      INT NOT NULL PRIMARY KEY,
            available_stock INT NOT NULL
        );

        INSERT INTO @locked_inventory (product_id, available_stock)
        SELECT TOP (2147483647)
            inv.product_id,
            inv.available_stock
        FROM dbo.inventory AS inv WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN @items AS i
            ON i.product_id = inv.product_id
        ORDER BY inv.product_id;

        IF EXISTS
        (
            SELECT 1
            FROM @items AS i
            INNER JOIN @locked_inventory AS li
                ON li.product_id = i.product_id
            WHERE li.available_stock < i.quantity
        )
        BEGIN
            RAISERROR(N'INSUFFICIENT_STOCK', 16, 1);
        END;

        DECLARE @created_at DATETIME2(0) = SYSUTCDATETIME();
        DECLARE @order_id INT;
        DECLARE @order_number NVARCHAR(30);
        DECLARE @numeric_order_part VARCHAR(20);

        INSERT INTO dbo.orders
        (
            order_number,
            idempotency_key,
            request_hash,
            customer_id,
            created_by_user_id,
            status,
            currency_code,
            total_amount,
            created_at
        )
        VALUES
        (
            NULL,
            @idempotency_key,
            @request_hash,
            @customer_id,
            @user_id,
            N'CONFIRMED',
            'ARS',
            0,
            @created_at
        );

        SET @order_id = CONVERT(INT, SCOPE_IDENTITY());
        SET @numeric_order_part = CONVERT(VARCHAR(20), @order_id);

        IF LEN(@numeric_order_part) < 6
        BEGIN
            SET @numeric_order_part =
                RIGHT(REPLICATE('0', 6) + @numeric_order_part, 6);
        END;

        SET @order_number = CONCAT
        (
            N'ORD-',
            CONVERT(CHAR(8), @created_at, 112),
            N'-',
            @numeric_order_part
        );

        UPDATE dbo.orders
        SET order_number = @order_number
        WHERE order_id = @order_id;

        INSERT INTO dbo.order_items
        (
            order_id,
            product_id,
            quantity,
            unit_price
        )
        SELECT
            @order_id,
            i.product_id,
            i.quantity,
            p.unit_price
        FROM @items AS i
        INNER JOIN dbo.products AS p
            ON p.product_id = i.product_id;

        UPDATE inv
        SET
            inv.available_stock = inv.available_stock - i.quantity,
            inv.updated_at = @created_at
        FROM dbo.inventory AS inv
        INNER JOIN @items AS i
            ON i.product_id = inv.product_id
        WHERE inv.available_stock >= i.quantity;

        IF @@ROWCOUNT <> @item_count
        BEGIN
            RAISERROR(N'INSUFFICIENT_STOCK', 16, 1);
        END;

        DECLARE @total_amount DECIMAL(18,2);

        SELECT
            @total_amount = CONVERT(DECIMAL(18,2), SUM(oi.subtotal))
        FROM dbo.order_items AS oi
        WHERE oi.order_id = @order_id;

        UPDATE dbo.orders
        SET total_amount = COALESCE(@total_amount, 0)
        WHERE order_id = @order_id;

        COMMIT TRANSACTION;

        SELECT
            @order_id AS order_id,
            @order_number AS order_number,
            COALESCE(@total_amount, 0) AS total_amount,
            CAST(0 AS BIT) AS is_replay;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER VIEW dbo.vw_DailyOrderSummary
AS
SELECT
    CAST(o.created_at AS DATE) AS summary_date,
    o.status,
    c.customer_id,
    c.code AS customer_code,
    c.name AS customer_name,
    COUNT_BIG(*) AS total_orders,
    COALESCE(SUM(items.total_units), 0) AS total_units,
    COALESCE(SUM(o.total_amount), 0) AS total_amount,
    COALESCE(AVG(o.total_amount), 0) AS average_order_amount
FROM dbo.orders AS o
INNER JOIN dbo.customers AS c
    ON c.customer_id = o.customer_id
LEFT JOIN (
    SELECT
        order_id,
        SUM(quantity) AS total_units
    FROM dbo.order_items
    GROUP BY order_id
) AS items
    ON items.order_id = o.order_id
GROUP BY
    CAST(o.created_at AS DATE),
    o.status,
    c.customer_id,
    c.code,
    c.name;
GO
