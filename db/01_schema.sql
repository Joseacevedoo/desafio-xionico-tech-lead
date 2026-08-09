SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;
GO

IF DB_ID(N'xionico_orders') IS NULL
BEGIN
    CREATE DATABASE xionico_orders;
END;
GO

USE xionico_orders;
GO

CREATE TABLE dbo.users (
    user_id INT IDENTITY(1,1) NOT NULL,
    username NVARCHAR(100) NOT NULL,
    display_name NVARCHAR(150) NOT NULL,
    password_hash NVARCHAR(500) NOT NULL,
    is_active BIT NOT NULL
        CONSTRAINT DF_users_is_active DEFAULT (1),
    created_at DATETIME2(0) NOT NULL
        CONSTRAINT DF_users_created_at DEFAULT (SYSUTCDATETIME()),
    updated_at DATETIME2(0) NOT NULL
        CONSTRAINT DF_users_updated_at DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_users PRIMARY KEY CLUSTERED (user_id),
    CONSTRAINT UQ_users_username UNIQUE (username),
    CONSTRAINT CK_users_username_not_empty CHECK (LEN(LTRIM(RTRIM(username))) > 0),
    CONSTRAINT CK_users_display_name_not_empty CHECK (LEN(LTRIM(RTRIM(display_name))) > 0),
    CONSTRAINT CK_users_password_hash_not_empty CHECK (LEN(LTRIM(RTRIM(password_hash))) > 0)
);
GO

CREATE TABLE dbo.customers (
    customer_id INT IDENTITY(1,1) NOT NULL,
    code NVARCHAR(50) NOT NULL,
    name NVARCHAR(200) NOT NULL,
    is_active BIT NOT NULL
        CONSTRAINT DF_customers_is_active DEFAULT (1),
    created_at DATETIME2(0) NOT NULL
        CONSTRAINT DF_customers_created_at DEFAULT (SYSUTCDATETIME()),
    updated_at DATETIME2(0) NOT NULL
        CONSTRAINT DF_customers_updated_at DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_customers PRIMARY KEY CLUSTERED (customer_id),
    CONSTRAINT UQ_customers_code UNIQUE (code),
    CONSTRAINT CK_customers_code_not_empty CHECK (LEN(LTRIM(RTRIM(code))) > 0),
    CONSTRAINT CK_customers_name_not_empty CHECK (LEN(LTRIM(RTRIM(name))) > 0)
);
GO

CREATE TABLE dbo.products (
    product_id INT IDENTITY(1,1) NOT NULL,
    code NVARCHAR(50) NOT NULL,
    name NVARCHAR(200) NOT NULL,
    description NVARCHAR(500) NULL,
    unit_price DECIMAL(18,2) NOT NULL,
    is_active BIT NOT NULL
        CONSTRAINT DF_products_is_active DEFAULT (1),
    created_at DATETIME2(0) NOT NULL
        CONSTRAINT DF_products_created_at DEFAULT (SYSUTCDATETIME()),
    updated_at DATETIME2(0) NOT NULL
        CONSTRAINT DF_products_updated_at DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_products PRIMARY KEY CLUSTERED (product_id),
    CONSTRAINT UQ_products_code UNIQUE (code),
    CONSTRAINT CK_products_code_not_empty CHECK (LEN(LTRIM(RTRIM(code))) > 0),
    CONSTRAINT CK_products_name_not_empty CHECK (LEN(LTRIM(RTRIM(name))) > 0),
    CONSTRAINT CK_products_unit_price_non_negative CHECK (unit_price >= 0)
);
GO

CREATE TABLE dbo.inventory (
    product_id INT NOT NULL,
    available_stock INT NOT NULL,
    updated_at DATETIME2(0) NOT NULL
        CONSTRAINT DF_inventory_updated_at DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_inventory PRIMARY KEY CLUSTERED (product_id),
    CONSTRAINT FK_inventory_products FOREIGN KEY (product_id)
        REFERENCES dbo.products (product_id),
    CONSTRAINT CK_inventory_available_stock_non_negative CHECK (available_stock >= 0)
);
GO

CREATE TABLE dbo.orders (
    order_id INT IDENTITY(1,1) NOT NULL,
    order_number NVARCHAR(30) NULL,
    idempotency_key UNIQUEIDENTIFIER NOT NULL,
    request_hash CHAR(64) NOT NULL,
    customer_id INT NOT NULL,
    created_by_user_id INT NOT NULL,
    status NVARCHAR(20) NOT NULL
        CONSTRAINT DF_orders_status DEFAULT (N'CONFIRMED'),
    currency_code CHAR(3) NOT NULL
        CONSTRAINT DF_orders_currency_code DEFAULT ('ARS'),
    total_amount DECIMAL(18,2) NOT NULL
        CONSTRAINT DF_orders_total_amount DEFAULT (0),
    created_at DATETIME2(0) NOT NULL
        CONSTRAINT DF_orders_created_at DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_orders PRIMARY KEY CLUSTERED (order_id),
    CONSTRAINT UQ_orders_idempotency_key UNIQUE (idempotency_key),
    CONSTRAINT FK_orders_customers FOREIGN KEY (customer_id)
        REFERENCES dbo.customers (customer_id),
    CONSTRAINT FK_orders_users FOREIGN KEY (created_by_user_id)
        REFERENCES dbo.users (user_id),
    CONSTRAINT CK_orders_status CHECK (status IN (N'CONFIRMED', N'CANCELLED')),
    CONSTRAINT CK_orders_currency_code CHECK (currency_code LIKE '[A-Z][A-Z][A-Z]'),
    CONSTRAINT CK_orders_total_amount_non_negative CHECK (total_amount >= 0),
    CONSTRAINT CK_orders_request_hash_format CHECK (
        LEN(request_hash) = 64
        AND request_hash NOT LIKE '%[^0-9A-F]%'
    )
);
GO

CREATE UNIQUE NONCLUSTERED INDEX UX_orders_order_number
ON dbo.orders (order_number)
WHERE order_number IS NOT NULL;
GO

CREATE NONCLUSTERED INDEX IX_orders_created_at_status_customer
ON dbo.orders (created_at, status, customer_id);
GO

CREATE TABLE dbo.order_items (
    order_item_id INT IDENTITY(1,1) NOT NULL,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(18,2) NOT NULL,
    subtotal AS (CONVERT(DECIMAL(18,2), quantity * unit_price)),

    CONSTRAINT PK_order_items PRIMARY KEY CLUSTERED (order_item_id),
    CONSTRAINT FK_order_items_orders FOREIGN KEY (order_id)
        REFERENCES dbo.orders (order_id),
    CONSTRAINT FK_order_items_products FOREIGN KEY (product_id)
        REFERENCES dbo.products (product_id),
    CONSTRAINT UQ_order_items_order_product UNIQUE (order_id, product_id),
    CONSTRAINT CK_order_items_quantity_positive CHECK (quantity > 0),
    CONSTRAINT CK_order_items_unit_price_non_negative CHECK (unit_price >= 0)
);
GO

CREATE NONCLUSTERED INDEX IX_products_active_product_id
ON dbo.products (is_active, product_id);
GO
