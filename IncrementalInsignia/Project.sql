USE [master]
GO

-- Create database with optimized settings for SQL Server Express
IF DB_ID('InsigniaDW') IS NULL
BEGIN
    PRINT 'Creating database InsigniaDW...'
    CREATE DATABASE [InsigniaDW] 
    ON PRIMARY 
    (
        NAME = N'InsigniaDW',
        FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\InsigniaDW.mdf',
        SIZE = 100MB,
        FILEGROWTH = 50MB
    )
    LOG ON 
    (
        NAME = N'InsigniaDW_log',
        FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\InsigniaDW_log.ldf',
        SIZE = 50MB,
        FILEGROWTH = 25MB
    )
    
    -- Set database compatibility level and optimize settings
    ALTER DATABASE [InsigniaDW] SET COMPATIBILITY_LEVEL = 160
    ALTER DATABASE [InsigniaDW] SET RECOVERY SIMPLE
    ALTER DATABASE [InsigniaDW] SET AUTO_CREATE_STATISTICS ON
    ALTER DATABASE [InsigniaDW] SET AUTO_UPDATE_STATISTICS ON
    ALTER DATABASE [InsigniaDW] SET AUTO_UPDATE_STATISTICS_ASYNC ON
    
    PRINT 'Database InsigniaDW created successfully at C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\'
END
ELSE
BEGIN
    PRINT 'Database InsigniaDW already exists.'
END
GO

USE [InsigniaDW]
GO

-- Create schemas for organization
PRINT 'Creating schemas...'
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'stg')
    EXEC('CREATE SCHEMA [stg]')
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dim')
    EXEC('CREATE SCHEMA [dim]')
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'fact')
    EXEC('CREATE SCHEMA [fact]')
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'etl')
    EXEC('CREATE SCHEMA [etl]')
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'audit')
    EXEC('CREATE SCHEMA [audit]')
GO

-- Create optimized staging table with appropriate data types
PRINT 'Creating staging table...'
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Sales' AND schema_id = SCHEMA_ID('stg'))
BEGIN
    CREATE TABLE [stg].[Sales] (
        [InvoiceId] VARCHAR(20) NOT NULL,
        [Description] VARCHAR(100) NULL,
        [Quantity] SMALLINT NULL,
        [Unit_Price] DECIMAL(10,2) NULL,
        [Tax_Rate] DECIMAL(5,2) NULL,
        [Total_Excluding_Tax] DECIMAL(12,2) NULL,
        [Tax_Amount] DECIMAL(12,2) NULL,
        [Profit] DECIMAL(12,2) NULL,
        [Total_Including_Tax] DECIMAL(12,2) NULL,
        [employee_Id] SMALLINT NULL,
        [EmployeeFirstName] VARCHAR(50) NULL,
        [EmployeeLastName] VARCHAR(50) NULL,
        [Is_Salesperson] BIT NULL,
        [Stock_Item_Id] INT NULL,
        [Stock_Item_Name] VARCHAR(100) NULL,
        [Stock_ItemColor] VARCHAR(30) NULL,
        [Stock_Item_Size] VARCHAR(20) NULL,
        [Item_Size] VARCHAR(20) NULL,
        [Stock_ItemPrice] DECIMAL(10,2) NULL,
        [Customer_Id] INT NULL,
        [CustomerName] VARCHAR(100) NULL,
        [CustomerCategory] VARCHAR(50) NULL,
        [CustomerContactName] VARCHAR(100) NULL,
        [CustomerPostalCode] VARCHAR(20) NULL,
        [CustomerContactNumber] VARCHAR(20) NULL,
        [City_ID] INT NULL,
        [City] VARCHAR(50) NULL,
        [State_Province] VARCHAR(50) NULL,
        [Country] VARCHAR(50) NULL,
        [Continent] VARCHAR(50) NULL,
        [Sales_Territory] VARCHAR(50) NULL,
        [Region] VARCHAR(50) NULL,
        [Subregion] VARCHAR(50) NULL,
        [Latest_Recorded_Population] INT NULL,
        [LoadDate] DATETIME2(0) DEFAULT SYSDATETIME(),
        [BatchId] INT NULL
    )
    
    -- Add indexes after table creation
    CREATE INDEX [IX_stg_Sales_StockItemId] ON [stg].[Sales] ([Stock_Item_Id])
    CREATE INDEX [IX_stg_Sales_CustomerId] ON [stg].[Sales] ([Customer_Id])
    CREATE INDEX [IX_stg_Sales_EmployeeId] ON [stg].[Sales] ([employee_Id])
    CREATE INDEX [IX_stg_Sales_CityId] ON [stg].[Sales] ([City_ID])
    
    PRINT 'Staging table stg.Sales created successfully.'
END
ELSE
BEGIN
    PRINT 'Staging table stg.Sales already exists.'
END
GO

-- Create lineage tracking table
PRINT 'Creating audit tables...'
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Lineage' AND schema_id = SCHEMA_ID('audit'))
BEGIN
    CREATE TABLE [audit].[Lineage] (
        [LineageId] INT IDENTITY(1,1) PRIMARY KEY,
        [BatchId] INT NOT NULL,
        [SourceSystem] VARCHAR(50) NOT NULL,
        [LoadStart] DATETIME2(0) NOT NULL,
        [LoadEnd] DATETIME2(0) NULL,
        [RowsInSource] INT NULL,
        [RowsInserted] INT NULL,
        [RowsUpdated] INT NULL,
        [Status] VARCHAR(20) NULL
    )
    
    CREATE INDEX [IX_Lineage_BatchId] ON [audit].[Lineage] ([BatchId])
    
    PRINT 'Audit table audit.Lineage created successfully.'
END
ELSE
BEGIN
    PRINT 'Audit table audit.Lineage already exists.'
END
GO

-- Create date dimension with optimized structure
PRINT 'Creating date dimension...'
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Date' AND schema_id = SCHEMA_ID('dim'))
BEGIN
    CREATE TABLE [dim].[Date] (
        [DateKey] INT NOT NULL PRIMARY KEY,
        [Date] DATE NOT NULL,
        [Day] TINYINT NOT NULL,
        [Month] TINYINT NOT NULL,
        [MonthName] VARCHAR(10) NOT NULL,
        [Quarter] TINYINT NOT NULL,
        [Year] SMALLINT NOT NULL,
        [FiscalMonth] TINYINT NOT NULL,
        [FiscalQuarter] TINYINT NOT NULL,
        [FiscalYear] SMALLINT NOT NULL,
        [DayOfWeek] TINYINT NOT NULL,
        [DayName] VARCHAR(10) NOT NULL,
        [IsWeekend] BIT NOT NULL
    )
    
    CREATE INDEX [IX_Date_Date] ON [dim].[Date] ([Date])
    
    PRINT 'Dimension table dim.Date created successfully.'
END
ELSE
BEGIN
    PRINT 'Dimension table dim.Date already exists.'
END
GO

-- Create geography dimension with SCD Type 3 on population
PRINT 'Creating geography dimension...'
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Geography' AND schema_id = SCHEMA_ID('dim'))
BEGIN
    CREATE TABLE [dim].[Geography] (
        [GeographyKey] INT IDENTITY(1,1) PRIMARY KEY,
        [GeographyId] INT NOT NULL,
        [City] VARCHAR(50) NOT NULL,
        [StateProvince] VARCHAR(50) NOT NULL,
        [Country] VARCHAR(50) NOT NULL,
        [Continent] VARCHAR(50) NOT NULL,
        [Region] VARCHAR(50) NULL,
        [Subregion] VARCHAR(50) NULL,
        [CurrentPopulation] INT NULL,
        [PreviousPopulation] INT NULL,
        [PopulationChangeDate] DATE NULL,
        [PostalCode] VARCHAR(20) NULL,
        [EffectiveDate] DATE NOT NULL,
        [ExpirationDate] DATE NULL,
        [IsCurrent] BIT NOT NULL,
        [LineageId] INT NOT NULL
    )
    
    CREATE INDEX [IX_Geography_GeographyId] ON [dim].[Geography] ([GeographyId])
    CREATE INDEX [IX_Geography_IsCurrent] ON [dim].[Geography] ([IsCurrent])
    
    PRINT 'Dimension table dim.Geography created successfully.'
END
ELSE
BEGIN
    PRINT 'Dimension table dim.Geography already exists.'
END
GO

-- Create customer dimension with SCD Type 2
PRINT 'Creating customer dimension...'
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Customer' AND schema_id = SCHEMA_ID('dim'))
BEGIN
    CREATE TABLE [dim].[Customer] (
        [CustomerKey] INT IDENTITY(1,1) PRIMARY KEY,
        [CustomerId] INT NOT NULL,
        [CustomerName] VARCHAR(100) NOT NULL,
        [Category] VARCHAR(50) NOT NULL,
        [ContactName] VARCHAR(100) NULL,
        [ContactNumber] VARCHAR(20) NULL,
        [EffectiveDate] DATE NOT NULL,
        [ExpirationDate] DATE NULL,
        [IsCurrent] BIT NOT NULL,
        [LineageId] INT NOT NULL
    )
    
    CREATE INDEX [IX_Customer_CustomerId] ON [dim].[Customer] ([CustomerId])
    CREATE INDEX [IX_Customer_IsCurrent] ON [dim].[Customer] ([IsCurrent])
    
    PRINT 'Dimension table dim.Customer created successfully.'
END
ELSE
BEGIN
    PRINT 'Dimension table dim.Customer already exists.'
END
GO

-- Create employee dimension with SCD Type 2
PRINT 'Creating employee dimension...'
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Employee' AND schema_id = SCHEMA_ID('dim'))
BEGIN
    CREATE TABLE [dim].[Employee] (
        [EmployeeKey] INT IDENTITY(1,1) PRIMARY KEY,
        [EmployeeId] SMALLINT NOT NULL,
        [FirstName] VARCHAR(50) NOT NULL,
        [LastName] VARCHAR(50) NOT NULL,
        [IsSalesperson] BIT NOT NULL,
        [EffectiveDate] DATE NOT NULL,
        [ExpirationDate] DATE NULL,
        [IsCurrent] BIT NOT NULL,
        [LineageId] INT NOT NULL
    )
    
    CREATE INDEX [IX_Employee_EmployeeId] ON [dim].[Employee] ([EmployeeId])
    CREATE INDEX [IX_Employee_IsCurrent] ON [dim].[Employee] ([IsCurrent])
    
    PRINT 'Dimension table dim.Employee created successfully.'
END
ELSE
BEGIN
    PRINT 'Dimension table dim.Employee already exists.'
END
GO

-- Create product dimension (SCD Type 1)
PRINT 'Creating product dimension...'
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Product' AND schema_id = SCHEMA_ID('dim'))
BEGIN
    CREATE TABLE [dim].[Product] (
        [ProductKey] INT IDENTITY(1,1) PRIMARY KEY,
        [ProductId] INT NOT NULL,
        [ProductName] VARCHAR(100) NOT NULL,
        [Color] VARCHAR(30) NULL,
        [Size] VARCHAR(20) NULL,
        [ItemSize] VARCHAR(20) NULL,
        [Price] DECIMAL(10,2) NULL,
        [LineageId] INT NOT NULL
    )
    
    CREATE INDEX [IX_Product_ProductId] ON [dim].[Product] ([ProductId])
    
    PRINT 'Dimension table dim.Product created successfully.'
END
ELSE
BEGIN
    PRINT 'Dimension table dim.Product already exists.'
END
GO

-- Create fact table with optimized structure
PRINT 'Creating fact table...'
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Sales' AND schema_id = SCHEMA_ID('fact'))
BEGIN
    CREATE TABLE [fact].[Sales] (
        [SalesKey] BIGINT IDENTITY(1,1) PRIMARY KEY,
        [InvoiceId] VARCHAR(20) NOT NULL,
        [OrderDateKey] INT NOT NULL,
        [CustomerKey] INT NOT NULL,
        [EmployeeKey] INT NOT NULL,
        [ProductKey] INT NOT NULL,
        [GeographyKey] INT NOT NULL,
        [Quantity] SMALLINT NOT NULL,
        [UnitPrice] DECIMAL(10,2) NOT NULL,
        [TaxRate] DECIMAL(5,2) NOT NULL,
        [NetAmount] DECIMAL(12,2) NOT NULL,
        [TaxAmount] DECIMAL(12,2) NOT NULL,
        [GrossAmount] DECIMAL(12,2) NOT NULL,
        [Profit] DECIMAL(12,2) NOT NULL,
        [LineageId] INT NOT NULL
    )
    
    CREATE INDEX [IX_FactSales_OrderDateKey] ON [fact].[Sales] ([OrderDateKey])
    CREATE INDEX [IX_FactSales_CustomerKey] ON [fact].[Sales] ([CustomerKey])
    CREATE INDEX [IX_FactSales_EmployeeKey] ON [fact].[Sales] ([EmployeeKey])
    CREATE INDEX [IX_FactSales_ProductKey] ON [fact].[Sales] ([ProductKey])
    CREATE INDEX [IX_FactSales_GeographyKey] ON [fact].[Sales] ([GeographyKey])
    
    PRINT 'Fact table fact.Sales created successfully.'
END
ELSE
BEGIN
    PRINT 'Fact table fact.Sales already exists.'
END
GO

-- Create sequence for batch IDs
IF NOT EXISTS (SELECT * FROM sys.sequences WHERE name = 'BatchSequence' AND schema_id = SCHEMA_ID('audit'))
BEGIN
    CREATE SEQUENCE [audit].[BatchSequence]
        AS INT
        START WITH 1
        INCREMENT BY 1;
    
    PRINT 'Sequence audit.BatchSequence created successfully.'
END
ELSE
BEGIN
    PRINT 'Sequence audit.BatchSequence already exists.'
END
GO

-- Create procedure to populate date dimension
PRINT 'Creating ETL procedures...'
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'LoadDimDate' AND schema_id = SCHEMA_ID('etl'))
    DROP PROCEDURE [etl].[LoadDimDate]
GO
CREATE PROCEDURE [etl].[LoadDimDate]
    @StartDate DATE = '2000-01-01',
    @EndDate DATE = '2023-12-31',
    @BatchId INT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @LineageId INT;
    
    -- Start lineage tracking
    INSERT INTO [audit].[Lineage] (
        [BatchId], [SourceSystem], [LoadStart], [Status]
    )
    VALUES (
        @BatchId, 'Date Dimension', SYSDATETIME(), 'Running'
    );
    
    SET @LineageId = SCOPE_IDENTITY();
    
    -- Use efficient date population with CTE
    ;WITH DateSequence AS (
        SELECT @StartDate AS [Date]
        UNION ALL
        SELECT DATEADD(DAY, 1, [Date])
        FROM DateSequence
        WHERE DATEADD(DAY, 1, [Date]) <= @EndDate
    )
    INSERT INTO [dim].[Date] (
        [DateKey], [Date], [Day], [Month], [MonthName], [Quarter], [Year],
        [FiscalMonth], [FiscalQuarter], [FiscalYear], [DayOfWeek], [DayName], [IsWeekend]
    )
    SELECT
        CONVERT(INT, CONVERT(VARCHAR(8), [Date], 112)) AS [DateKey],
        [Date],
        DAY([Date]) AS [Day],
        MONTH([Date]) AS [Month],
        DATENAME(MONTH, [Date]) AS [MonthName],
        DATEPART(QUARTER, [Date]) AS [Quarter],
        YEAR([Date]) AS [Year],
        CASE WHEN MONTH([Date]) >= 7 THEN MONTH([Date]) - 6 ELSE MONTH([Date]) + 6 END AS [FiscalMonth],
        CASE WHEN MONTH([Date]) >= 7 THEN DATEPART(QUARTER, [Date]) ELSE DATEPART(QUARTER, DATEADD(MONTH, 6, [Date])) END AS [FiscalQuarter],
        CASE WHEN MONTH([Date]) >= 7 THEN YEAR([Date]) ELSE YEAR([Date]) - 1 END AS [FiscalYear],
        DATEPART(WEEKDAY, [Date]) AS [DayOfWeek],
        DATENAME(WEEKDAY, [Date]) AS [DayName],
        CASE WHEN DATEPART(WEEKDAY, [Date]) IN (1, 7) THEN 1 ELSE 0 END AS [IsWeekend]
    FROM DateSequence
    OPTION (MAXRECURSION 10000);
    
    -- Update lineage record
    UPDATE [audit].[Lineage]
    SET 
        [LoadEnd] = SYSDATETIME(),
        [RowsInSource] = (SELECT COUNT(*) FROM [dim].[Date]),
        [Status] = 'Success'
    WHERE [LineageId] = @LineageId;
    
    RETURN 0;
END
GO

-- Create master procedure to execute full ETL
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'ExecuteFullLoad' AND schema_id = SCHEMA_ID('etl'))
    DROP PROCEDURE [etl].[ExecuteFullLoad]
GO
CREATE PROCEDURE [etl].[ExecuteFullLoad]
    @BatchId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Generate batch ID if not provided
    IF @BatchId IS NULL
        SET @BatchId = NEXT VALUE FOR [audit].[BatchSequence];
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Load dimensions
        EXEC [etl].[LoadDimDate] @BatchId;
        -- EXEC [etl].[LoadDimGeography] @BatchId;
        -- EXEC [etl].[LoadDimCustomer] @BatchId;
        -- EXEC [etl].[LoadDimEmployee] @BatchId;
        -- EXEC [etl].[LoadDimProduct] @BatchId;
        
        -- Load fact table
        -- EXEC [etl].[LoadFactSales] @BatchId;
        
        COMMIT TRANSACTION;
        
        -- Return success
        SELECT 'ETL process completed successfully' AS [Message];
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Log error
        INSERT INTO [audit].[Lineage] (
            [BatchId], [SourceSystem], [LoadStart], [LoadEnd], [Status]
        )
        VALUES (
            @BatchId, 'Full ETL', SYSDATETIME(), SYSDATETIME(), 'Failed: ' + ERROR_MESSAGE()
        );
        
        -- Rethrow error
        THROW;
    END CATCH
    
    RETURN 0;
END
GO

PRINT 'Database schema and ETL procedures created successfully.'
GO