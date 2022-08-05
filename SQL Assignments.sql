/*
1. List of Persons’ full name, all their fax and phone numbers,
as well as the phone number and fax of the company they are working for (if any). 
*/

--Check any suppliers who are people
SELECT * FROM purchasing.Suppliers p
WHERE p.SupplierName IN (SELECT DISTINCT SupplierName FROM purchasing.Suppliers)

--Check any customers who are people
SELECT * FROM sales.Customers s
WHERE s.CustomerName IN (SELECT DISTINCT CustomerName FROM sales.Customers) AND
CustomerName NOT like '%Toys%';

--Answer
SELECT FullName, PhoneNumber, FaxNumber, IsEmployee as IsWWIEmployee 
FROM Application.People

Union All

SELECT CustomerName, PhoneNumber, FaxNumber, RunPosition 
FROM Sales.Customers WHERE CustomerName NOT like '%Toys%'
ORDER BY IsWWIEmployee DESC
GO

/*
2.	If the customer's primary contact person has 
the same phone number as the customer’s phone number, 
list the customer companies.
*/

SELECT c.CustomerName
FROM Sales.Customers c
JOIN Application.People p 
ON c.PrimaryContactPersonID = p.PersonID
WHERE c.PhoneNumber = p.PhoneNumber
GO

/*
3.	List of customers to whom we made a sale prior to 2016 but no sale since 2016-01-01.
*/
SELECT DISTINCT(C.CustomerName)
FROM Sales.Customers C
JOIN Sales.Invoices I
ON C.CustomerID = I.CustomerID
WHERE I.InvoiceDate < '2016-01-01' AND I.ConfirmedDeliveryTime IS NOT NULL

EXCEPT 

SELECT DISTINCT(C.CustomerName)
FROM Sales.Customers C
JOIN Sales.Invoices I
ON C.CustomerID = I.CustomerID
WHERE I.InvoiceDate >= '2016-01-01' AND I.ConfirmedDeliveryTime IS NOT NULL


/*
4.	List of Stock Items and total quantity for each stock item in Purchase Orders in Year 2013.
*/
SELECT WS.StockItemName, SUM(WST.Quantity) FROM Warehouse.StockItems WS
JOIN Warehouse.StockItemTransactions WST ON WS.StockItemID = WST.StockItemID
JOIN Purchasing.PurchaseOrders PO ON WST.PurchaseOrderID = PO.PurchaseOrderID
WHERE PO.OrderDate BETWEEN '2013-01-01' AND '2013-12-31'
GROUP BY WS.StockItemName


/*
5.	List of stock items that have at least 10 characters in description.
*/
SELECT StockItemName, SearchDetails AS Description FROM Warehouse.StockItems
WHERE SearchDetails like '%__________%'


/*
6.	List of stock items that are not sold to the state of Alabama and Georgia in 2014.
*/
SELECT DISTINCT(WS.StockItemName) FROM Warehouse.StockItems WS
JOIN Warehouse.StockItemTransactions WST ON WS.StockItemID = WST.StockItemID
JOIN Sales.Customers SC ON WST.CustomerID = SC.CustomerID
JOIN Application.Cities AC ON SC.DeliveryCityID = AC.CityID
JOIN Application.StateProvinces ASP ON AC.StateProvinceID = ASP.StateProvinceID
WHERE ASP.StateProvinceName NOT IN ('Alabama', 'Georgia')


/*
7.	List of States and Avg dates for processing (confirmed delivery date – order date).
*/
SELECT ASP.StateProvinceName, AVG(DATEDIFF(DAY, SO.OrderDate, CAST(SI.ConfirmedDeliveryTime AS DATE))) AS AvgDatesForProcessing
FROM Application.StateProvinces ASP
JOIN Application.Cities AC ON ASP.StateProvinceID = AC.StateProvinceID
JOIN Sales.Customers SC ON AC.CityID = SC.DeliveryCityID
JOIN Sales.Orders SO ON SC.CustomerID = SO.CustomerID
JOIN Sales.Invoices SI ON SO.OrderID = SI.OrderID
WHERE SI.ConfirmedDeliveryTime IS NOT NULL OR SO.OrderDate IS NOT NULL
GROUP BY ASP.StateProvinceName
ORDER BY AvgDatesForProcessing DESC


/*
8.	List of States and Avg dates for processing (confirmed delivery date – order date) by month.
*/
SELECT ASP.StateProvinceName, AVG(DATEDIFF(DAY, SO.OrderDate, CAST(SI.ConfirmedDeliveryTime AS DATE))) AS AvgDatesForProcessing,
	MONTH(SO.OrderDate) AS Month
FROM Application.StateProvinces ASP
JOIN Application.Cities AC ON ASP.StateProvinceID = AC.StateProvinceID
JOIN Sales.Customers SC ON AC.CityID = SC.DeliveryCityID
JOIN Sales.Orders SO ON SC.CustomerID = SO.CustomerID
JOIN Sales.Invoices SI ON SO.OrderID = SI.OrderID
WHERE SI.ConfirmedDeliveryTime IS NOT NULL OR SO.OrderDate IS NOT NULL 
GROUP BY ASP.StateProvinceName, MONTH(so.OrderDate)
--HAVING ASP.StateProvinceName = 'Ohio'
ORDER BY AvgDatesForProcessing DESC


/*
9.	List of StockItems that the company purchased more than sold in the year of 2015.
*/
SELECT WS.StockItemName, SUM(WST.Quantity) AS RemainingQuantity FROM Warehouse.StockItems WS
JOIN Warehouse.StockItemTransactions WST ON WS.StockItemID = WST.StockItemID
WHERE WST.Quantity > 0 AND WST.TransactionOccurredWhen BETWEEN '2015-01-01' AND '2015-12-31'
GROUP BY WS.StockItemID, WS.StockItemName


/*
10.	List of Customers and their phone number, together with the primary contact person’s name,
to whom we did not sell more than 10  mugs (search by name) in the year 2016.
*/
SELECT SC.CustomerName, SC.PhoneNumber, AP.FullName AS PrimaryContactPersonName FROM Sales.Customers SC
JOIN Application.People AP ON SC.PrimaryContactPersonID = AP.PersonID
JOIN Warehouse.StockItemTransactions WST ON SC.CustomerID = WST.CustomerID
WHERE WST.TransactionOccurredWhen BETWEEN '2016-01-01' AND '2016-12-31' 
	AND InvoiceID IS NOT NULL

EXCEPT

SELECT SC.CustomerName, SC.PhoneNumber, AP.FullName AS PrimaryContactPersonName FROM Sales.Customers SC
JOIN Application.People AP ON SC.PrimaryContactPersonID = AP.PersonID
JOIN Warehouse.StockItemTransactions WST ON SC.CustomerID = WST.CustomerID
JOIN Warehouse.StockItems WS ON WST.StockItemID = WS.StockItemID
WHERE WS.StockItemName LIKE '%mug%'
	AND WST.TransactionOccurredWhen BETWEEN '2016-01-01' AND '2016-12-31' 
	AND InvoiceID IS NOT NULL
GROUP BY WST.StockItemID, SC.CustomerName, SC.PhoneNumber, AP.FullName
HAVING SUM(WST.Quantity) < -10


/*
11.	List all the cities that were updated after 2015-01-01.
*/
SELECT CityName FROM Application.Cities FOR SYSTEM_TIME
    CONTAINED IN ('2013-01-01 00:00:00.0000000', '2022-07-31 00:00:00.0000000')
WHERE ValidTo > '2015-01-01'


/*
12.	List all the Order Detail 
(Stock Item name, delivery address, delivery state, city, country, customer name, 
customer contact person name, customer phone, quantity) for the date of 2014-07-01. 
Info should be relevant to that date.
*/
SELECT WS.StockItemName, CONCAT(SC.DeliveryAddressLine2, ', ', SC.DeliveryAddressLine1) AS DeliveryAddress,
	AC.CityName, ASP.StateProvinceName, ACS.CountryName, SC.CustomerName, AP.FullName AS PrimaryContactPerson,
	SC.PhoneNumber, WST.Quantity 
FROM Sales.Orders SO
JOIN Sales.Invoices SI ON SO.OrderID = SI.OrderID
JOIN Warehouse.StockItemTransactions WST ON SI.InvoiceID = WST.InvoiceID
JOIN Warehouse.StockItems WS ON WST.StockItemID = WS.StockItemID
JOIN Sales.Customers SC ON SO.CustomerID = SC.CustomerID
JOIN Application.Cities AC ON SC.DeliveryCityID = AC.CityID
JOIN Application.StateProvinces ASP ON AC.StateProvinceID = ASP.StateProvinceID
JOIN Application.Countries ACS ON ASP.CountryID = ACS.CountryID
JOIN Application.People AP ON SC.PrimaryContactPersonID = AP.PersonID
WHERE SO.OrderDate = '2014-07-01'


/*
13.	List of stock item groups and total quantity purchased, total quantity sold,
and the remaining stock quantity (quantity purchased – quantity sold)
*/
/* Answer one with run time of 6mins38seconds
SELECT WSG.StockGroupName, SUM(PWST.Quantity) AS TotalQuantityPurchased,
	SUM(SWST.Quantity) AS TotalQuantitySold,
	SUM(WST.Quantity) AS RemainingStockQuantity
FROM Warehouse.StockItems WS
JOIN Warehouse.StockItemTransactions WST ON WS.StockItemID = WST.StockItemID
JOIN Warehouse.StockItemStockGroups WSIS ON WS.StockItemID = WSIS.StockItemID
JOIN Warehouse.StockGroups WSG ON WSIS.StockGroupID = WSG.StockGroupID
JOIN (SELECT WSIT.StockItemID, WSIT.Quantity 
	  FROM Warehouse.StockItemTransactions WSIT
	  WHERE	WSIT.PurchaseOrderID IS NOT NULL) PWST ON PWST.StockItemID = WS.StockItemID
JOIN (SELECT WSITS.StockItemID, WSITS.Quantity 
	  FROM Warehouse.StockItemTransactions WSITS
	  WHERE	WSITS.CustomerID IS NOT NULL) SWST ON SWST.StockItemID = WS.StockItemID
GROUP BY WSG.StockGroupName
*/
--Answer two with runtime 6mins47seconds. no performance increase --!
SELECT StockItemID , Quantity INTO #PWST
	  FROM Warehouse.StockItemTransactions 
	  WHERE PurchaseOrderID IS NOT NULL
SELECT StockItemID, Quantity INTO #SWST
	  FROM Warehouse.StockItemTransactions 
	  WHERE	CustomerID IS NOT NULL
SELECT WSG.StockGroupName, ABS(SUM(#PWST.Quantity)) AS TotalQuantityPurchased,
	ABS(SUM(#SWST.Quantity)) AS TotalQuantitySold,
	ABS(SUM(WST.Quantity)) AS RemainingStockQuantity
FROM Warehouse.StockItems WS
JOIN Warehouse.StockItemTransactions WST ON WS.StockItemID = WST.StockItemID
JOIN Warehouse.StockItemStockGroups WSIS ON WS.StockItemID = WSIS.StockItemID
JOIN Warehouse.StockGroups WSG ON WSIS.StockGroupID = WSG.StockGroupID
JOIN #PWST ON #PWST.StockItemID = WS.StockItemID
JOIN #SWST ON #SWST.StockItemID = WS.StockItemID
GROUP BY WSG.StockGroupName
DROP TABLE #PWST
DROP TABLE #SWST


/*
14.	List of Cities in the US and the stock item that the city got the most deliveries in 2016. 
If the city did not purchase any stock items in 2016, print “No Sales”.
*/
SELECT AC.CityName, WS.StockItemName, WS.StockItemID, SUM(Quantity) AS Quantity
INTO #TEMP1
FROM Application.Cities AC
JOIN Application.StateProvinces ASP ON ASP.StateProvinceID = AC.StateProvinceID
JOIN Application.Countries ACS ON ACS.CountryID = ASP.CountryID
LEFT JOIN Sales.Customers SC ON AC.CityID = SC.DeliveryCityID
LEFT JOIN Sales.Invoices SI ON SI.CustomerID = SC.CustomerID
LEFT JOIN Warehouse.StockItemTransactions WST ON WST.InvoiceID = SI.InvoiceID
LEFT JOIN Warehouse.StockItems WS ON WS.StockItemID = WST.StockItemID
WHERE WST.InvoiceID IS NOT NULL 
	AND SI.ConfirmedDeliveryTime BETWEEN '2016-01-01' AND '2016-12-31'
	AND ACS.IsoAlpha3Code LIKE '%USA%'
GROUP BY WS.StockItemID, AC.CityName, WS.StockItemName
ORDER BY WS.StockItemID

SELECT T1.CityName, T1.StockItemName FROM #TEMP1 T1
WHERE T1.Quantity IN (SELECT MIN(T.Quantity) FROM #TEMP1 T
					  GROUP BY T.CityName
					 )
ORDER BY T1.CityName
DROP TABLE #TEMP1


/*
15.	List any orders that had more than one delivery attempt (located in invoice table).
*/
/* My original answer
SELECT SI.OrderID
FROM Sales.Invoices SI
WHERE SI.CustomerPurchaseOrderNumber IN (SELECT CustomerPurchaseOrderNumber
										FROM Sales.Invoices
										GROUP BY CustomerPurchaseOrderNumber
										HAVING COUNT(CustomerPurchaseOrderNumber) > 1
										)

*/
SELECT OrderID
FROM Sales.Invoices
WHERE ISJSON(ReturnedDeliveryData) >0
GROUP BY JSON_VALUE(ReturnedDeliveryData, '$.Events[1].Event'), OrderID
HAVING COUNT(JSON_VALUE(ReturnedDeliveryData, '$.Events[1].Event')) >1


/*
16.	List all stock items that are manufactured in China. (Country of Manufacture)
*/
SELECT WS.StockItemName, JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture
FROM Warehouse.StockItems WS
JOIN Warehouse.StockItemTransactions WST ON WST.StockItemID = WS.StockItemID
WHERE WST.SupplierID IS NOT NULL 
	AND JSON_VALUE(CustomFields, '$.CountryOfManufacture') LIKE 'China'


/*
17.	Total quantity of stock items sold in 2015, group by country of manufacturing.
*/
SELECT JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture, 
		ABS(SUM(WST.Quantity)) AS Quantity 
FROM Warehouse.StockItemTransactions WST
JOIN Sales.Invoices SI ON SI.InvoiceID = WST.InvoiceID
JOIN Warehouse.StockItems WS ON WS.StockItemID = WST.StockItemID
WHERE WST.InvoiceID IS NOT NULL 
	AND SI.ConfirmedDeliveryTime BETWEEN '2015-01-01' AND '2015-12-31'
GROUP BY JSON_VALUE(CustomFields, '$.CountryOfManufacture')
GO

/*
18.	Create a view that shows the total quantity of stock items of 
each stock group sold (in orders) by year 2013-2017. 
[Stock Group Name, 2013, 2014, 2015, 2016, 2017]
*/
CREATE VIEW 
	udvSaleByYearByGroup
AS
	WITH
		CTE (StockGroupNames, TotalQuantity, Year)
	AS
		(
			SELECT 
				WSG.StockGroupName, ABS(SUM(WST.Quantity)) AS TotalQuantity, YEAR(SI.InvoiceDate) AS Year
			FROM 
				Warehouse.StockGroups WSG
			JOIN 
				Warehouse.StockItemStockGroups WSIS ON WSG.StockGroupID = WSIS.StockGroupID
			JOIN 
				Warehouse.StockItemTransactions WST ON WSIS.StockItemID = WST.StockItemID
			JOIN 
				Sales.Invoices SI ON WST.InvoiceID = SI.InvoiceID
			GROUP BY WSG.StockGroupName, YEAR(SI.InvoiceDate)
		)
	
	SELECT
	  StockGroupNames,
	  MAX(CASE WHEN (Year = 2013) THEN TotalQuantity ELSE NULL END) AS '2013',
	  MAX(CASE WHEN (Year = 2014) THEN TotalQuantity ELSE NULL END) AS '2014',
	  MAX(CASE WHEN (Year = 2015) THEN TotalQuantity ELSE NULL END) AS '2015',
	  MAX(CASE WHEN (Year = 2016) THEN TotalQuantity ELSE NULL END) AS '2016'
	FROM
		CTE
	GROUP BY StockGroupNames
GO
SELECT * FROM udvSaleByYearByGroup
ORDER BY StockGroupNames
GO


/*
19.	Create a view that shows the total quantity of stock items of 
each stock group sold (in orders) by year 2013-2017. 
[Year, Stock Group Name1, Stock Group Name2, Stock Group Name3, … , Stock Group Name10] 
*/
CREATE VIEW 
	udvSaleByGroupByYear
AS
	WITH
		CTE (StockGroupNames, TotalQuantity, Year)
	AS
		(
			SELECT 
				WSG.StockGroupName, ABS(SUM(WST.Quantity)) AS TotalQuantity, YEAR(SI.InvoiceDate) AS Year
			FROM 
				Warehouse.StockGroups WSG
			JOIN 
				Warehouse.StockItemStockGroups WSIS ON WSG.StockGroupID = WSIS.StockGroupID
			JOIN 
				Warehouse.StockItemTransactions WST ON WSIS.StockItemID = WST.StockItemID
			JOIN 
				Sales.Invoices SI ON WST.InvoiceID = SI.InvoiceID
			GROUP BY WSG.StockGroupName, YEAR(SI.InvoiceDate)
		)
	
	SELECT
	  Year,
	  MAX(CASE WHEN (StockGroupNames = 'Novelty Items') THEN TotalQuantity ELSE NULL END) AS 'Novelty Items',
	  MAX(CASE WHEN (StockGroupNames = 'T-Shirts') THEN TotalQuantity ELSE NULL END) AS 'T-Shirts',
	  MAX(CASE WHEN (StockGroupNames = 'Mugs') THEN TotalQuantity ELSE NULL END) AS 'Mugs',
	  MAX(CASE WHEN (StockGroupNames = 'Toys') THEN TotalQuantity ELSE NULL END) AS 'Toys',
	  MAX(CASE WHEN (StockGroupNames = 'Clothing') THEN TotalQuantity ELSE NULL END) AS 'Clothing',
	  MAX(CASE WHEN (StockGroupNames = 'Furry Footwear') THEN TotalQuantity ELSE NULL END) AS 'Furry Footwear',
	  MAX(CASE WHEN (StockGroupNames = 'Computing Novelties') THEN TotalQuantity ELSE NULL END) AS 'Computing Novelties',
	  MAX(CASE WHEN (StockGroupNames = 'Packaging Materials') THEN TotalQuantity ELSE NULL END) AS 'Packaging Materials',
	  MAX(CASE WHEN (StockGroupNames = 'USB Novelties') THEN TotalQuantity ELSE NULL END) AS 'USB Novelties'
	FROM
		CTE
	GROUP BY Year
GO
SELECT * FROM udvSaleByGroupByYear
ORDER BY Year
GO


/*
20.	Create a function, input: order id; return: total of that order. 
List invoices and use that function to attach the order total to the other fields of invoices.
*/
CREATE FUNCTION dbo.udfOrderTotal(@OrderId int)
	RETURNS INT
AS
BEGIN
	DECLARE @Ret INT
	SELECT @Ret = ABS(SUM(WST.Quantity)) 
	FROM Warehouse.StockItemTransactions WST
	JOIN Sales.Invoices SI ON SI.InvoiceID = WST.InvoiceID
	WHERE SI.OrderID = @OrderId
		IF (@Ret IS NULL)
			SET @Ret = 0
	RETURN @Ret
END;
GO

ALTER TABLE Sales.Invoices ADD OrderTotal INT
GO
SELECT SI.OrderID, dbo.udfOrderTotal(SI.OrderID) AS TOrderTotal
	INTO #temp
FROM Sales.Invoices SI;
GO
--SELECT * FROM Sales.Invoices, SELECT * FROM #temp
UPDATE Sales.Invoices
SET OrderTotal = TOrderTotal	
FROM Sales.Invoices SIS
JOIN #temp T ON SIS.OrderID = T.OrderID
WHERE SIS.OrderID = T.OrderID
GO
DROP TABLE #Temp
GO


/*
21.	Create a new table called ods.Orders. 
Create a stored procedure, with proper error handling and transactions, 
that input is a date; when executed, it would find orders of that day, 
calculate order total, and save the information (order id, order date, 
order total, customer id) into the new table. If a given date is already existing in the new table,
throw an error and roll back. Execute the stored procedure 5 times using different dates. 
*/
CREATE SCHEMA ods
CREATE TABLE WideWorldImporters.ods.Orders(
	orderId int,
	orderDate DATE,
	orderTotal INT,
	customerId int
)
--DROP TABLE ods.Orders
GO
CREATE PROCEDURE saveOrderInfoToNewTable(
	@OrderDate DATE
) AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			IF (@OrderDate IN (SELECT OrderDate FROM ods.Orders))
				THROW 51000, 'The date is already exit', 1;
			ELSE
				INSERT INTO ods.Orders
					SELECT SI.OrderID, SO.OrderDate, SI.OrderTotal, SI.CustomerID 
					FROM Sales.Invoices SI
					JOIN Sales.Orders SO ON SI.OrderID = SO.OrderID
					WHERE SO.OrderDate = @OrderDate
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		SELECT ERROR_MESSAGE() AS ErrorMessage
		IF (XACT_STATE()) = -1 
		BEGIN
			PRINT N'The transaction is in an uncommittable state.' +
					'Rolling back transaction'
			ROLLBACK TRANSACTION
		END
		IF (XACT_STATE()) = 1
		BEGIN
			PRINT N'The transaction is committable.' + 
					'Committing transaction'
			COMMIT TRANSACTION
		END
	END CATCH
END
GO
--DROP PROC saveOrderInfoToNewTable
EXEC saveOrderInfoToNewTable '2013-01-01'
EXEC saveOrderInfoToNewTable '2014-01-01'
EXEC saveOrderInfoToNewTable '2015-01-01'
EXEC saveOrderInfoToNewTable '2016-01-01'
EXEC saveOrderInfoToNewTable '2013-02-01'
--SELECT * FROM ODS.Orders


/*
22.	Create a new table called ods.StockItem. It has following columns: 
[StockItemID], [StockItemName] ,[SupplierID] ,[ColorID] ,[UnitPackageID] ,
[OuterPackageID] ,[Brand] ,[Size] ,[LeadTimeDays] ,[QuantityPerOuter] ,
[IsChillerStock] ,[Barcode] ,[TaxRate]  ,[UnitPrice],[RecommendedRetailPrice] ,
[TypicalWeightPerUnit] ,[MarketingComments]  ,[InternalComments], [CountryOfManufacture], 
[Range], [Shelflife]. Migrate all the data in the original stock item table.
*/
SELECT [StockItemID]
      ,[StockItemName]
      ,[SupplierID]
      ,[ColorID]
      ,[UnitPackageID]
      ,[OuterPackageID]
      ,[Brand]
      ,[Size]
      ,[LeadTimeDays]
      ,[QuantityPerOuter]
      ,[IsChillerStock]
      ,[Barcode]
      ,[TaxRate]
      ,[UnitPrice]
      ,[RecommendedRetailPrice]
      ,[TypicalWeightPerUnit]
      ,[MarketingComments]
      ,[InternalComments]
	  ,JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture
	  ,JSON_VALUE(CustomFields, '$.Range') AS Range
	  ,JSON_VALUE(CustomFields, '$.ShelfLife') AS ShelfLife
INTO ods.StockItem
  FROM [WideWorldImporters].[Warehouse].[StockItems]
GO


/*
23.	Rewrite your stored procedure in (21). Now with a given date, 
it should wipe out all the order data prior to the input date and 
load the order data that was placed in the next 7 days following the input date.
*/
CREATE PROCEDURE forQ23(
	@OrderDate DATE
) AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			IF (@OrderDate IN (SELECT OrderDate FROM ods.Orders))
			BEGIN
				DELETE FROM ods.Orders WHERE ods.Orders.orderDate < @OrderDate
				INSERT INTO ods.Orders
					SELECT SI.OrderID, SO.OrderDate, SI.OrderTotal, SI.CustomerID 
					FROM Sales.Invoices SI
					JOIN Sales.Orders SO ON SI.OrderID = SO.OrderID
					WHERE SO.OrderDate BETWEEN @OrderDate AND DATEADD(DAY, 7, @OrderDate)
			END
			ELSE
				INSERT INTO ods.Orders
					SELECT SI.OrderID, SO.OrderDate, SI.OrderTotal, SI.CustomerID 
					FROM Sales.Invoices SI
					JOIN Sales.Orders SO ON SI.OrderID = SO.OrderID
					WHERE SO.OrderDate = @OrderDate
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		SELECT ERROR_MESSAGE() AS ErrorMessage
		IF (XACT_STATE()) = -1 
		BEGIN
			PRINT N'The transaction is in an uncommittable state.' +
					'Rolling back transaction'
			ROLLBACK TRANSACTION
		END
		IF (XACT_STATE()) = 1
		BEGIN
			PRINT N'The transaction is committable.' + 
					'Committing transaction'
			COMMIT TRANSACTION
		END
	END CATCH
END
GO

EXEC saveOrderInfoToNewTable '2013-02-02'
SELECT * FROM ods.Orders ORDER BY ods.Orders.orderDate
EXEC forQ23 '2013-02-02'
GO


/*
24.	Consider the JSON file:

{
   "PurchaseOrders":[
      {
         "StockItemName":"Panzer Video Game",
         "Supplier":"7",
         "UnitPackageId":"1",
         "OuterPackageId":[6, 7],
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-01",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"WWI2308"
      },
      {
         "StockItemName":"Panzer Video Game",
         "Supplier":"5",
         "UnitPackageId":"1",
         "OuterPackageId":"7",
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-025",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"269622390"
      }
   ]
}


Looks like that it is our missed purchase orders. 
Migrate these data into Stock Item, Purchase Order and
Purchase Order Lines tables. Of course, save the script.
*/
/* Created a q24.JSON File with given data in Visual Studio as import
SELECT * FROM OPENROWSET (BULK 'C:\Users\hackn\Documents\Antra SQL Traning\q24.json', Single_CLOB) AS import;
Declare @JSON varchar(max)
SELECT @JSON=BulkColumn
FROM OPENROWSET (BULK 'E:\file1.json', SINGLE_CLOB) import
SELECT * FROM OPENJSON (@JSON)
WITH  (
		[StockItemName] VARCHAR,
        [SupplierId] INT,
        [UnitPackageId] INT,
         "OuterPackageId":[6, 7],
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-01",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference"
   [Firstname] varchar(20),  
   [Lastname] varchar(20),  
   [Gender] varchar(20),  
   [AGE] int );
*/
DECLARE @JSON NVARCHAR(MAX)
SET @JSON = 
	N'[
		{
         "StockItemName":"Panzer Video Game1",
         "Supplier":"7",
         "UnitPackageId":"1",
         "OuterPackageId":"6",
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-01",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"WWI2308"
      },
	  {
         "StockItemName":"Panzer Video Game2",
         "Supplier":"7",
         "UnitPackageId":"1",
         "OuterPackageId":"7",
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-01",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"WWI2308"
      },
      {
         "StockItemName":"Panzer Video Game3",
         "Supplier":"5",
         "UnitPackageId":"1",
         "OuterPackageId":"7",
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-25",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"269622390"
      }
	]'

SELECT * INTO ods.PurchaseOrders FROM
	OPENJSON(@JSON)
WITH
(
	StockItemName				NVARCHAR(20)	'$.StockItemName',
    SupplierId					INT				'$.Supplier',
    UnitPackageId				INT				'$.UnitPackageId',
    OuterPackageId				INT				'$.OuterPackageId',
    Brand						NVARCHAR(20)	'$.Brand',
    LeadTimeDays				INT				'$.LeadTimeDays',
    QuantityPerOuter			INT				'$.QuantityPerOuter',
    TaxRate						INT				'$.TaxRate',
    UnitPrice					DECIMAL(20,2)	'$.UnitPrice',
    RecommendedRetailPrice		DECIMAL(20,2)	'$.RecommendedRetailPrice',
    TypicalWeightPerUnit		DECIMAL(20,2)	'$.TypicalWeightPerUnit',
    CountryOfManufacture		NVARCHAR(20)	'$.CountryOfManufacture',
    Range						NVARCHAR(20)	'$.Range',
    OrderDate					DATE			'$.OrderDate',
    DeliveryMethod				NVARCHAR(20)	'$.DeliveryMethod',
    ExpectedDeliveryDate		DATE			'$.ExpectedDeliveryDate',
    SupplierReference			NVARCHAR(20)	'$.SupplierReference'
)
--DROP TABLE ODS.PURCHASEORDERS
/* find the different columns between two tables
SELECT * into #tblA
FROM information_schema.columns
WHERE table_Schema ='Warehouse' and table_name = 'StockItems' ;

SELECT * into #tblB
FROM information_schema.columns
WHERE table_Schema ='ods' and table_name = 'PurchaseOrders' ;

SELECT
COALESCE(A.Column_Name, B.Column_Name) AS [Column]
,CASE 
WHEN (A.Column_Name IS NULL and B.Column_Name IS NOT NULL)
THEN 'Column - [' + B.Column_Name+ '] exists in Table - ['+ B.TABLE_NAME + '] Only'
--WHEN (B.Column_Name IS NULL and A.Column_Name IS NOT NULL)
--THEN 'Column - [' + A.Column_Name+ '] exist in Table - ['+ A.TABLE_NAME + '] Only'
WHEN A.Column_Name = B.Column_Name
THEN 'Column - [' + A.Column_Name + '] exists in both Table - ['+ A.TABLE_NAME + ' , ' + B.TABLE_NAME + ']'
END AS Remarks
FROM #tblA A
FULL JOIN #tblB B ON A.Column_Name = B.Column_Name;

drop table #tblA;
drop table #tblB;
*/

ALTER TABLE Warehouse.StockItems 
	ADD CountryOfManufacture NVARCHAR(20),Range NVARCHAR(20),
		OrderDate DATE, DeliveryMethod NVARCHAR(20),
		ExpectedDeliveryDate DATE, SupplierReference NVARCHAR(20)
ALTER TABLE Warehouse.StockItems
  ADD CONSTRAINT DF_Doc_Exz_Column_B2
  --DEFAULT 0 FOR IsChillerStock, 
  DEFAULT 1 FOR LastEditedBy;
GO

--SELECT * FROM information_schema.columns WHERE table_Schema ='Warehouse' and table_name = 'StockItems' ;
MERGE Warehouse.StockItems AS TARGET
USING ods.PurchaseOrders AS SOURCE
ON TARGET.StockItemName = SOURCE.StockItemName

WHEN NOT MATCHED BY TARGET THEN
	INSERT(StockItemName, SupplierId, UnitPackageId, OuterPackageId, Brand, LeadTimeDays, QuantityPerOuter,
	TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit, CountryOfManufacture, Range, OrderDate,
	DeliveryMethod, ExpectedDeliveryDate,SupplierReference)
	VALUES(SOURCE.StockItemName, SOURCE.SupplierId, SOURCE.UnitPackageId, SOURCE.OuterPackageId, SOURCE.Brand, 
	SOURCE.LeadTimeDays, SOURCE.QuantityPerOuter, SOURCE.TaxRate, SOURCE.UnitPrice, SOURCE.RecommendedRetailPrice, 
	SOURCE.TypicalWeightPerUnit, SOURCE.CountryOfManufacture, SOURCE.Range, SOURCE.OrderDate, SOURCE.DeliveryMethod, 
	SOURCE.ExpectedDeliveryDate,SOURCE.SupplierReference);
GO


/*
25.	Revisit your answer in (19). Convert the result in JSON string and save it to the server using TSQL FOR JSON PATH.
*/
ALTER TABLE ods.Orders ADD JsonForQ25 NVARCHAR(MAX)
INSERT INTO ods.Orders(JsonForQ25)
(
	WITH
		CTE (StockGroupNames, TotalQuantity, Year)
	AS
		(
			SELECT 
				WSG.StockGroupName, ABS(SUM(WST.Quantity)) AS TotalQuantity, YEAR(SI.InvoiceDate) AS Year
			FROM 
				Warehouse.StockGroups WSG
			JOIN 
				Warehouse.StockItemStockGroups WSIS ON WSG.StockGroupID = WSIS.StockGroupID
			JOIN 
				Warehouse.StockItemTransactions WST ON WSIS.StockItemID = WST.StockItemID
			JOIN 
				Sales.Invoices SI ON WST.InvoiceID = SI.InvoiceID
			GROUP BY WSG.StockGroupName, YEAR(SI.InvoiceDate)
		)
	
	SELECT
	  Year,
	  MAX(CASE WHEN (StockGroupNames = 'Novelty Items') THEN TotalQuantity ELSE NULL END) AS 'Novelty Items',
	  MAX(CASE WHEN (StockGroupNames = 'T-Shirts') THEN TotalQuantity ELSE NULL END) AS 'T-Shirts',
	  MAX(CASE WHEN (StockGroupNames = 'Mugs') THEN TotalQuantity ELSE NULL END) AS 'Mugs',
	  MAX(CASE WHEN (StockGroupNames = 'Toys') THEN TotalQuantity ELSE NULL END) AS 'Toys',
	  MAX(CASE WHEN (StockGroupNames = 'Clothing') THEN TotalQuantity ELSE NULL END) AS 'Clothing',
	  MAX(CASE WHEN (StockGroupNames = 'Furry Footwear') THEN TotalQuantity ELSE NULL END) AS 'Furry Footwear',
	  MAX(CASE WHEN (StockGroupNames = 'Computing Novelties') THEN TotalQuantity ELSE NULL END) AS 'Computing Novelties',
	  MAX(CASE WHEN (StockGroupNames = 'Packaging Materials') THEN TotalQuantity ELSE NULL END) AS 'Packaging Materials',
	  MAX(CASE WHEN (StockGroupNames = 'USB Novelties') THEN TotalQuantity ELSE NULL END) AS 'USB Novelties'
	FROM
		CTE
	GROUP BY Year
	FOR JSON PATH, ROOT('Sales')
)WHERE orderId = 1750


/*
26.	Revisit your answer in (19). Convert the result into an XML string and save it to the server using TSQL FOR XML PATH.
*/
ALTER TABLE ods.Orders ADD XmlforQ26 XML
INSERT INTO ods.Orders(XmlforQ26)
Values(
	WITH
		CTE (StockGroupNames, TotalQuantity, Year)
	AS
		(
			SELECT 
				WSG.StockGroupName, ABS(SUM(WST.Quantity)) AS TotalQuantity, YEAR(SI.InvoiceDate) AS Year
			FROM 
				Warehouse.StockGroups WSG
			JOIN 
				Warehouse.StockItemStockGroups WSIS ON WSG.StockGroupID = WSIS.StockGroupID
			JOIN 
				Warehouse.StockItemTransactions WST ON WSIS.StockItemID = WST.StockItemID
			JOIN 
				Sales.Invoices SI ON WST.InvoiceID = SI.InvoiceID
			GROUP BY WSG.StockGroupName, YEAR(SI.InvoiceDate)
		)
	
	SELECT
	  Year,
	  MAX(CASE WHEN (StockGroupNames = 'Novelty Items') THEN TotalQuantity ELSE NULL END) AS 'Novelty Items',
	  MAX(CASE WHEN (StockGroupNames = 'T-Shirts') THEN TotalQuantity ELSE NULL END) AS 'T-Shirts',
	  MAX(CASE WHEN (StockGroupNames = 'Mugs') THEN TotalQuantity ELSE NULL END) AS 'Mugs',
	  MAX(CASE WHEN (StockGroupNames = 'Toys') THEN TotalQuantity ELSE NULL END) AS 'Toys',
	  MAX(CASE WHEN (StockGroupNames = 'Clothing') THEN TotalQuantity ELSE NULL END) AS 'Clothing',
	  MAX(CASE WHEN (StockGroupNames = 'Furry Footwear') THEN TotalQuantity ELSE NULL END) AS 'Furry Footwear',
	  MAX(CASE WHEN (StockGroupNames = 'Computing Novelties') THEN TotalQuantity ELSE NULL END) AS 'Computing Novelties',
	  MAX(CASE WHEN (StockGroupNames = 'Packaging Materials') THEN TotalQuantity ELSE NULL END) AS 'Packaging Materials',
	  MAX(CASE WHEN (StockGroupNames = 'USB Novelties') THEN TotalQuantity ELSE NULL END) AS 'USB Novelties'
	FROM
		CTE
	GROUP BY Year
	FOR XML PATH
) WHERE orderId = 1750


/*
27.	Create a new table called ods.ConfirmedDeviveryJson with 3 columns (id, date, value) . 
Create a stored procedure, input is a date. The logic would load invoice information (all columns) 
as well as invoice line information (all columns) and forge them into a JSON string and 
then insert into the new table just created. 
Then write a query to run the stored procedure for each DATE that customer id 1 got something delivered to him.
*/
CREATE TABLE ods.ConfirmedDeviveryJson(
	 Id INT PRIMARY KEY
	,Date DATE
	,Value NVARCHAR
)
GO
CREATE PROC uspForQ27(
	@Date DATE
) AS
BEGIN
	INSERT INTO ods.ConfirmedDeviveryJson (Date, Value)
	Values(
			@Date, (SELECT 
					   SI.[InvoiceID]
					  ,[CustomerID]
					  ,[BillToCustomerID]
					  ,[OrderID]
					  ,[DeliveryMethodID]
					  ,[ContactPersonID]
					  ,[AccountsPersonID]
					  ,[SalespersonPersonID]
					  ,[PackedByPersonID]
					  ,[InvoiceDate]
					  ,[CustomerPurchaseOrderNumber]
					  ,[IsCreditNote]
					  ,[CreditNoteReason]
					  ,[Comments]
					  ,[DeliveryInstructions]
					  ,[InternalComments]
					  ,[TotalDryItems]
					  ,[TotalChillerItems]
					  ,[DeliveryRun]
					  ,[RunPosition]
					  ,[ReturnedDeliveryData]
					  ,[ConfirmedDeliveryTime]
					  ,[ConfirmedReceivedBy]
					  ,SI.[LastEditedBy] AS SI_LastEditedBy
					  ,SI.[LastEditedWhen] AS SI_LastEditedWhen
					  ,[OrderTotal]
					  ,[InvoiceLineID]
					  ,[StockItemID]
					  ,[Description]
					  ,[PackageTypeID]
					  ,[Quantity]
					  ,[UnitPrice]
					  ,[TaxRate]
					  ,[TaxAmount]
					  ,[LineProfit]
					  ,[ExtendedPrice]
					  ,SIL.[LastEditedBy] AS SIL_LastEditedBy
					  ,SIL.[LastEditedWhen] AS SIL_LastEditedWhen
					FROM Sales.Invoices SI
					FULL OUTER JOIN Sales.InvoiceLines SIL
					ON SIL.InvoiceID = SI.InvoiceID
					FOR JSON PATH)
		)
END
GO

DECLARE @Date DATE
DECLARE cursorForQ27 CURSOR
FOR SELECT CAST(ConfirmedDeliveryTime AS DATE) 
	FROM Sales.Invoices
	WHERE CustomerID = 1
OPEN cursorForQ27
FETCH NEXT FROM cursorForQ27 INTO
	@Date
WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC uspForQ27 @Date
	END
CLOSE cursorForQ27
DEALLOCATE cursorForQ27

