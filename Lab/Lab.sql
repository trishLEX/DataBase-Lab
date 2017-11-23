USE master
GO

IF DB_ID (N'ShopDB') IS NOT NULL
	DROP DATABASE ShopDB;
GO

CREATE DATABASE ShopDB
	ON (
		name = Shop_dat,
		filename = 'E:\Sorry\DBProjects\Lab\ShopDB_dat.mdf',
		size = 10,
		maxsize = unlimited,
		filegrowth = 5%
		)
	LOG ON (
		name = Shop_log,
		filename = 'E:\Sorry\DBProjects\Lab\ShopDB_log.ldf',
		size = 5,
		maxsize = 25,
		filegrowth = 5
		) ;
GO

USE ShopDB
GO

IF SCHEMA_ID(N'ShopSchema') IS NOT NULL
	DROP SCHEMA ShopSchema;
	GO

CREATE SCHEMA ShopSchema;
 GO

CREATE TABLE ShopDB.ShopSchema.[Shop]
(
    shopCode INT PRIMARY KEY NOT NULL IDENTITY(0, 1),
    shopName VARCHAR(100),
    isOutlet BIT DEFAULT 0 NOT NULL,
    address  VARCHAR(100)   NOT NULL,
    city VARCHAR(50) NOT NULL
)
 GO

CREATE FUNCTION ShopSchema.[calculateAge](@dateOfBirth DATE) RETURNS INT
  BEGIN
    DECLARE @Age INT
    DECLARE @birthday DATE
    SET @birthday = @dateOfBirth
    SET @Age = datediff(YY, @birthday, getdate()) -
    CASE
      WHEN DATEADD(YY, DATEDIFF(YY, @birthday, GETDATE()), @birthday) > GETDATE() THEN 1 ELSE 0 END
    RETURN @Age
  END
  GO

CREATE TABLE ShopDB.ShopSchema.[Shopman]
(
    shopmanCode INT PRIMARY KEY NOT NULL IDENTITY(0, 1),
    firstName VARCHAR(25) NOT NULL,
    lastName VARCHAR(25) NOT NULL,
    middleName VARCHAR(25),
    dateOfBirth DATE NOT NULL CHECK (ShopSchema.calculateAge(dateOfBirth) >= 18),
    phone CHAR(11) NOT NULL,
    position VARCHAR(25),
    isFired BIT DEFAULT 0,

    shopCode INT NOT NULL,
    FOREIGN KEY (shopCode) REFERENCES ShopDB.ShopSchema.[Shop](shopCode))
  GO

CREATE TABLE ShopDB.ShopSchema.[Check]
(
    checkID INT PRIMARY KEY NOT NULL IDENTITY(0, 1),
    date DATE NOT NULL,
    totalCost MONEY NOT NULL,
    typeOfPay BIT NOT NULL,
    discount SMALLINT DEFAULT 0,
    shopmanCode INT NOT NULL,
    FOREIGN KEY (shopmanCode) REFERENCES ShopDB.ShopSchema.[Shopman] (shopmanCode)
)
  GO

CREATE TABLE ShopDB.ShopSchema.[Card]
(
  checkID INT PRIMARY KEY NOT NULL,
  FOREIGN KEY (checkID) REFERENCES ShopDB.ShopSchema.[Check] (checkID),

  cardID INT NOT NULL UNIQUE IDENTITY(0, 1),
  type BIT DEFAULT 0,
  phone CHAR(11) NOT NULL,
  firstName VARCHAR(25) NOT NULL,
  lastName VARCHAR(25) NOT NULL,
)
  GO

CREATE TABLE ShopDB.ShopSchema.[Event]
(
  checkID INT PRIMARY KEY NOT NULL,
  FOREIGN KEY (checkID) REFERENCES ShopDB.ShopSchema.[Check] (checkID),

  eventID INT NOT NULL UNIQUE IDENTITY(0, 1),
  description VARCHAR(500) NOT NULL,
  expDate DATE NOT NULL,
)
  GO

CREATE TABLE ShopDB.ShopSchema.[Item]
(
  itemID INT PRIMARY KEY NOT NULL IDENTITY(0, 1),
  itemName VARCHAR(100) NOT NULL,
  description VARCHAR(100) NOT NULL,
  country VARCHAR(58) NOT NULL
)
  GO

CREATE TABLE ShopDB.ShopSchema.[Check_Item_INT]
(
  checkID INT NOT NULL,
  itemID INT NOT NULL,

  PRIMARY KEY (checkID, itemID),

  FOREIGN KEY (checkID) REFERENCES ShopDB.ShopSchema.[Check] (checkID),
  FOREIGN KEY (itemID)  REFERENCES ShopDB.ShopSchema.[Item]  (itemID)
)
  GO

CREATE TABLE ShopDB.ShopSchema.[Store]
(
  shopCode INT NOT NULL,
  FOREIGN KEY (shopCode) REFERENCES ShopDB.ShopSchema.[Shop] (shopCode),

  itemID INT NOT NULL,
  FOREIGN KEY (itemID)  REFERENCES ShopDB.ShopSchema.[Item]  (itemID),

  PRIMARY KEY (shopCode, itemID),

  rest INT NOT NULL,
  price MONEY NOT NULL
)
  GO


--чеки с дисконтной картой
SELECT [Check].[checkID], [Check].[totalCost] FROM ShopDB.ShopSchema.[Check] WHERE [Check].[checkID] in (SELECT Card.checkID FROM ShopDB.ShopSchema.Card WHERE type = 0)
GO

--чеки от неуволенных сотрудников
SELECT [Check].[checkID], [Check].[totalCost] FROM ShopDB.ShopSchema.[Check]
WHERE [Check].[checkID] in (
  SELECT Card.checkID FROM ShopDB.ShopSchema.Card
  WHERE [shopmanCode] in
        (SELECT shopmanCode FROM ShopDB.ShopSchema.Shopman WHERE isFired = 0))
GO

--чеки из Питера
SELECT checkID, totalCost FROM ShopDB.ShopSchema.[Check] WHERE exists(SELECT b.[shopmanCode] FROM ShopDB.ShopSchema.Shopman as b
WHERE shopCode > 24
      and shopCode < 34
      and b.shopmanCode = [Check].shopmanCode)

--чеки с товаром из 501 линейки
SELECT checkID, totalCost FROM ShopSchema.[Check] AS checktable WHERE exists(SELECT INT.checkID FROM ShopSchema.Check_Item_INT AS INT WHERE
  exists(SELECT Item.itemName FROM ShopDB.ShopSchema.Item WHERE itemName LIKE '501%' and Item.itemID = INT.itemID)
  AND INT.checkID = checktable.checkID)
GO


--таблица, где для каждого магазина указана максимальная стоимость в чеке
SELECT MX.shopName, MAX(MX.maxCost) AS maxSale FROM (SELECT shopName, shopmanCode, maxCost FROM (SELECT C.shopmanCode, MAX(totalCost) AS maxCost
                                                                                                 FROM (SELECT Shopman.shopmanCode, totalCost
                                                                                                       FROM ShopSchema.Shopman JOIN ShopSchema.[Check]
                                                                                                           ON Shopman.shopmanCode = [Check].shopmanCode) AS C
  GROUP BY shopmanCode) AS A
  JOIN ShopSchema.Shop AS B ON exists(SELECT D.shopCode FROM ShopSchema.Shopman AS D WHERE D.shopCode = B.shopCode AND D.shopmanCode = A.shopmanCode))
  AS MX GROUP BY MX.shopName ORDER BY maxSale DESC
GO


-- костыль, чтобы избавиться от повторений
-- SELECT D.itemName, D.Count, D.price, MAX(D.Count) AS [SMTH] FROM (SELECT C.itemName, C.itemID, C.Count, price FROM (SELECT itemName, A.Count, B.itemID FROM (SELECT itemID, count(*) as Count FROM ShopSchema.Check_Item_INT GROUP BY itemID) AS A
--   JOIN ShopSchema.Item AS B ON A.itemID = B.itemID) AS C JOIN ShopSchema.Store ON C.itemID = ShopSchema.Store.itemID) AS D GROUP BY D.itemName, D.Count, D.price

--таблица, где для каждого товара указано количесвто его продаж и выручка с этого
SELECT T.itemName, T.Count, T.price * T.Count AS [Total Profit] FROM (SELECT D.itemName, D.Count, D.price, MAX(D.Count) AS [SMTH]
                                                                      FROM (SELECT C.itemName, C.itemID, C.Count, price
                                                                            FROM (SELECT itemName, A.Count, B.itemID
                                                                                  FROM (SELECT itemID, count(*) as Count
                                                                                        FROM ShopSchema.Check_Item_INT GROUP BY itemID) AS A
  JOIN ShopSchema.Item AS B ON A.itemID = B.itemID) AS C JOIN ShopSchema.Store ON C.itemID = ShopSchema.Store.itemID) AS D GROUP BY D.itemName, D.Count, D.price) AS T
  ORDER BY [Total Profit] DESC
GO

--для каждого города указана максимальнеая продажа
SELECT [SHOPS].city, MAX([SHOPS].maxSale) AS maxSale FROM (SELECT S.city, R.maxSale FROM ShopSchema.[Shop] AS S, (SELECT MX.shopName, MAX(MX.maxCost) AS maxSale
                                                        FROM (SELECT shopName, shopmanCode, maxCost FROM (SELECT C.shopmanCode, MAX(totalCost) AS maxCost
                                                                                                 FROM (SELECT Shopman.shopmanCode, totalCost
                                                                                                       FROM ShopSchema.Shopman JOIN ShopSchema.[Check]
                                                                                                           ON Shopman.shopmanCode = [Check].shopmanCode) AS C
  GROUP BY shopmanCode) AS A
  JOIN ShopSchema.Shop AS B ON exists(SELECT D.shopCode FROM ShopSchema.Shopman AS D WHERE D.shopCode = B.shopCode AND D.shopmanCode = A.shopmanCode))
  AS MX GROUP BY MX.shopName) AS R WHERE S.shopName = R.shopName) AS [SHOPS] GROUP BY [SHOPS].city ORDER BY  maxSale DESC
GO

--суммарная прибыль с каждого города с какой-то по какую-то дату
WITH SELLINGS_CTE (City, Cost)
AS
(
  SELECT A.city, [CHECKS].totalCost AS [COST] FROM (SELECT [SHOPS].city, [SALERS].shopmanCode
                                                    FROM ShopSchema.Shop AS [SHOPS], ShopSchema.Shopman AS [SALERS] WHERE [SHOPS].shopCode = [SALERS].shopCode) AS A
  JOIN ShopSchema.[Check] AS [CHECKS] ON [CHECKS].shopmanCode = A.shopmanCode and CHECKS.date BETWEEN '2017-06-01' AND '2017-08-31'
)
SELECT SELLINGS_CTE.City, SUM(SELLINGS_CTE.Cost) AS [Total Profit] FROM SELLINGS_CTE GROUP BY SELLINGS_CTE.City ORDER BY [Total Profit] DESC
GO

CREATE TABLE ShopDB.ShopSchema.[tempItemTable] (itemID INT PRIMARY KEY , country VARCHAR(50))
INSERT INTO ShopDB.ShopSchema.[tempItemTable] VALUES
  (0, 'India'),
  (1, 'India')
GO

MERGE INTO ShopSchema.Item AS [item] USING (SELECT Temp.itemID, Temp.country FROM ShopSchema.tempItemTable AS [Temp]) [temp]
ON ([temp].itemID = [item].itemID)
WHEN MATCHED THEN UPDATE SET [item].country = [temp].country;
DROP TABLE ShopSchema.tempItemTable
GO

CREATE VIEW ShopSchema.[Shopmans' phone numbers] AS
  (SELECT [Shopman].firstName, [Shopman].lastName, [Shopman].phone
  FROM ShopSchema.Shopman AS [Shopman])
GO
CREATE VIEW ShopSchema.[Stores' Profit] WITH SCHEMABINDING
  AS
    (SELECT MX.shopName, MAX(MX.maxCost) AS maxSale FROM (SELECT shopName, shopmanCode, maxCost FROM (SELECT C.shopmanCode, MAX(totalCost) AS maxCost
                                                                                                 FROM (SELECT Shopman.shopmanCode, totalCost
                                                                                                       FROM ShopSchema.Shopman JOIN ShopSchema.[Check]
                                                                                                           ON Shopman.shopmanCode = [Check].shopmanCode) AS C
  GROUP BY shopmanCode) AS A
  JOIN ShopSchema.Shop AS B ON
                              exists(SELECT D.shopCode FROM ShopSchema.Shopman AS D WHERE D.shopCode = B.shopCode AND D.shopmanCode = A.shopmanCode))
  AS MX GROUP BY MX.shopName)
GO

CREATE INDEX [Shopman_IDX]
  ON ShopSchema.Shopman(shopmanCode)
  INCLUDE (position, shopCode)
GO

--представление администраторов в каждом магазине
CREATE VIEW ShopSchema.[Admins] WITH SCHEMABINDING
  AS
  SELECT shopmanCode, firstName, lastName, middleName, dateOfBirth, phone, isFired, shopName, Shop.shopCode
  FROM ShopSchema.[Shopman] JOIN ShopSchema.[Shop] ON Shopman.shopCode = Shop.shopCode
  WHERE position = 'администратор'
GO

CREATE UNIQUE CLUSTERED INDEX [Admins_IDX]
  ON ShopSchema.Admins (shopmanCode, shopName)


--процедура выборки чеков с определённой даты по сегодняшнюю
CREATE PROCEDURE ShopSchema.usp_checks_from_data_cursor
  @date DATE,
  @checks_cursor CURSOR VARYING OUTPUT
AS
  SET @checks_cursor = CURSOR FORWARD_ONLY
                              STATIC
  FOR
  (SELECT [Check].totalCost, [Check].discount, [Shopman].lastName, [Shopman].firstName
   FROM ShopSchema.[Check] JOIN ShopSchema.[Shopman] ON [Check].shopmanCode = Shopman.shopmanCode
  WHERE [Check].date BETWEEN @date AND GETDATE())
  OPEN @checks_cursor
GO

--процедура выборки чеков с определённой даты по сегодняшнюю с возрастом продавца
CREATE PROCEDURE ShopSchema.usp_checks_from_data_cursor_withAge
  @date DATE,
  @checks_cursor CURSOR VARYING OUTPUT
AS
  SET @checks_cursor = CURSOR FORWARD_ONLY
                              STATIC
  FOR
  (SELECT [Check].totalCost, [Check].discount, [Shopman].lastName, [Shopman].firstName, ShopSchema.calculateAge([Shopman].dateOfBirth) AS [AGE]
   FROM ShopSchema.[Check] JOIN ShopSchema.[Shopman] ON [Check].shopmanCode = Shopman.shopmanCode
  WHERE [Check].date BETWEEN @date AND GETDATE())
  OPEN @checks_cursor
GO

CREATE FUNCTION ShopSchema.fn_full_price (@totalCost MONEY, @discount SMALLINT)
RETURNS MONEY
AS
  BEGIN
    DECLARE @res MONEY
    IF (@discount = 0)
      SET @res = @totalCost
    ELSE
      SET @res = @totalCost / (100 - @discount)
    RETURN @res
  END
GO


CREATE PROCEDURE ShopSchema.usp_scroll_checks_cursor_by_full_price
AS
  DECLARE @checks_autumn_cursor CURSOR

  DECLARE @totalCost INT
  DECLARE @discount  SMALLINT
  DECLARE @firstName VARCHAR(25)
  DECLARE @lastName  VARCHAR(25)

  EXEC ShopSchema.usp_checks_from_data_cursor '2017-09-01', @checks_cursor = @checks_autumn_cursor OUTPUT

  FETCH NEXT FROM @checks_autumn_cursor INTO @totalCost, @discount, @lastName, @firstName

  WHILE (@@FETCH_STATUS = 0)
  BEGIN
    IF (ShopSchema.fn_full_price(@totalCost, @discount) BETWEEN 10000 AND 15000)
      PRINT @lastName + ' ' + @firstName + ' sold on ' + CAST(@totalCost as CHAR)
    FETCH NEXT FROM @checks_autumn_cursor INTO @totalCost, @discount, @lastName, @firstName
  END
  CLOSE @checks_autumn_cursor
  DEALLOCATE @checks_autumn_cursor
GO

ShopSchema.usp_scroll_checks_cursor_by_full_price

CREATE FUNCTION ShopSchema.fn_sellers_by_city(@city VARCHAR(50)) RETURNS TABLE
AS
  RETURN SELECT S.lastName, S.firstName, Shop.shopName, Shop.shopCode FROM ShopSchema.Shopman AS S JOIN ShopSchema.Shop ON S.shopCode = Shop.shopCode WHERE Shop.city = @city
GO

CREATE PROCEDURE ShopSchema.usp_checks_from_data_by_city_cursor
  @date DATE,
  @checks_cursor CURSOR VARYING OUTPUT
AS
  SET @checks_cursor = CURSOR FORWARD_ONLY
                            STATIC
  FOR SELECT [Check].totalCost, [Check].discount, [Shopman].lastName, [Shopman].firstName, CITY.shopName AS [AGE]
  FROM ShopSchema.[Check]
  JOIN ShopSchema.[Shopman] AS S ON [Check].shopmanCode = Shopman.shopmanCode
  JOIN ShopSchema.fn_sellers_by_city('Moscow') AS CITY ON S.shopCode = CITY.shopCode
  WHERE [Check].date BETWEEN @date AND GETDATE()
  OPEN @checks_cursor
GO


CREATE TRIGGER ShopSchema.shopman_insert
ON ShopSchema.Shopman
INSTEAD OF INSERT
AS
  BEGIN
    DECLARE @firstName   VARCHAR(25)
    DECLARE @lastName    VARCHAR(25)
    DECLARE @middleName  VARCHAR(25)
    DECLARE @dateOfBirth DATE
    DECLARE @phone       CHAR(11)
    DECLARE @position    VARCHAR(25)
    DECLARE @shopCode    INT

    DECLARE @error_msg VARCHAR(100)

    DECLARE @shopman_cursor CURSOR

    SET @shopman_cursor = CURSOR FORWARD_ONLY
                          STATIC
    FOR SELECT inserted.firstName, inserted.lastName, inserted.middleName,
          inserted.dateOfBirth, inserted.phone, inserted.position, inserted.shopCode FROM inserted
    OPEN @shopman_cursor

    FETCH NEXT FROM @shopman_cursor INTO @firstName, @lastName, @middleName, @dateOfBirth, @phone, @position, @shopCode

    WHILE (@@FETCH_STATUS = 0)
    BEGIN
      IF (exists(SELECT * FROM ShopSchema.Shopman WHERE shopCode = @shopCode AND @position = position AND position = 'администратор'))
        BEGIN
          SET @error_msg = 'Attempt to add second administrator in shop: ' + CAST(@shopCode AS VARCHAR)
          RAISERROR (@error_msg, 10, 1)
        END
      ELSE IF (@position NOT IN ('уборщик', 'администратор', 'продавец-консультант', 'старший продавец'))
        BEGIN
          SET @error_msg = 'Invalid position: ' + @position
          RAISERROR (@error_msg, 10, 1)
        END
      ELSE
        BEGIN
          INSERT INTO ShopSchema.Shopman (firstName, lastName, middleName, dateOfBirth, phone, position, shopCode)
          VALUES (@firstName, @lastName, @middleName, @dateOfBirth, @phone, @position, @shopCode)
        END

      FETCH NEXT FROM @shopman_cursor INTO @firstName, @lastName, @middleName, @dateOfBirth, @phone, @position, @shopCode
    END
    CLOSE @shopman_cursor
    DEALLOCATE @shopman_cursor
  END
GO

INSERT ShopSchema.Shopman (firstName, lastName, middleName, dateOfBirth, phone, position, shopCode) VALUES ('a', 'b', 'c', '1993-01-01', '89164472638', 'bellboy', 0)
GO

CREATE TRIGGER ShopSchema.shopman_update
ON ShopSchema.Shopman
AFTER UPDATE
AS
  BEGIN
    IF UPDATE(dateOfBirth) OR UPDATE(middleName)
      BEGIN
        RAISERROR ('Invalid columns are tried to update', 10, 1)
        ROLLBACK
      END
    ELSE IF (exists(SELECT inserted.position FROM inserted WHERE inserted.position NOT IN ('уборщик', 'администратор', 'продавец-консультант', 'старший продавец')))
      BEGIN
        RAISERROR ('Invalid position', 10, 1)
        ROLLBACK
      END
  END
GO

UPDATE ShopSchema.Shopman SET position = 'администрато' WHERE position = 'администратор'
GO


CREATE TRIGGER ShopSchema.shopman_delete
ON ShopSchema.Shopman
INSTEAD OF DELETE
AS
  BEGIN
    DECLARE @shopmanCode INT
    DECLARE @firstName   VARCHAR(25)
    DECLARE @lastName    VARCHAR(25)
    DECLARE @middleName  VARCHAR(25)
    DECLARE @dateOfBirth DATE
    DECLARE @phone       CHAR(11)
    DECLARE @position    VARCHAR(25)
    DECLARE @shopCode    INT

    DECLARE @shopman_cursor CURSOR

    SET @shopman_cursor = CURSOR FORWARD_ONLY
                          STATIC
    FOR SELECT deleted.shopmanCode, deleted.firstName, deleted.lastName, deleted.middleName,
          deleted.dateOfBirth, deleted.phone, deleted.position, deleted.shopCode FROM deleted

    OPEN @shopman_cursor

    FETCH NEXT FROM @shopman_cursor INTO @shopmanCode, @firstName, @lastName, @middleName, @dateOfBirth, @phone, @position, @shopCode

    WHILE (@@FETCH_STATUS = 0)
    BEGIN
      PRINT 'Fired: ' + CAST(@shopmanCode AS VARCHAR) + ' ' + @firstName + ' ' + @lastName + ' ' + @middleName + ' ' +
            CAST(@dateOfBirth AS VARCHAR) + ' ' + @phone + ' ' + @position + ' ' + CAST(@shopCode AS VARCHAR)
      UPDATE ShopSchema.Shopman SET isFired = 1 WHERE shopmanCode = @shopmanCode
      FETCH NEXT FROM @shopman_cursor INTO @shopmanCode, @firstName, @lastName, @middleName, @dateOfBirth, @phone, @position, @shopCode
    END
  END
GO

INSERT ShopSchema.Shopman (firstName, lastName, middleName, dateOfBirth, phone, position, shopCode) VALUES ('a', 'b', 'c', '1993-01-01', '89164472638', 'уборщик', 0)
DELETE FROM ShopSchema.Shopman WHERE firstName = 'a'
GO

CREATE TRIGGER ShopSchema.admins_insert
ON ShopSchema.Admins
INSTEAD OF INSERT
AS
  BEGIN
    INSERT INTO ShopSchema.Shopman SELECT inserted.firstName, inserted.lastName, inserted.middleName, inserted.dateOfBirth, inserted.phone, 'администратор' AS position, 0 AS isFired, (SELECT Shop.shopCode FROM Shop WHERE Shop.shopName = inserted.shopName)
                                   FROM inserted
  END
GO

INSERT INTO ShopSchema.Admins (firstName, lastName, middleName, dateOfBirth, phone, isFired, shopName)
    VALUES ('asd', 'cvb', 'asd', '1980-10-10', '89454874529', 0, 'Levi''s store Moscow MEGA Belaya Dacha')
GO

CREATE TRIGGER ShopSchema.admins_update
ON ShopSchema.Admins
INSTEAD OF UPDATE
AS
  BEGIN
    DECLARE @shopmanCode INT
    DECLARE @phone       CHAR(11)
    DECLARE @isFired     BIT
    DECLARE @shopCode    INT
    DECLARE @firstName   VARCHAR(25)
    DECLARE @lastName    VARCHAR(25)

    DECLARE @admins_cursor CURSOR

    SET @admins_cursor = CURSOR FORWARD_ONLY
                         STATIC
    FOR SELECT inserted.shopmanCode, inserted.firstName, inserted.lastName, inserted.phone, inserted.isFired, inserted.shopCode FROM inserted
    OPEN @admins_cursor

    FETCH NEXT FROM @admins_cursor INTO @shopmanCode, @firstName, @lastName, @phone, @isFired, @shopCode

    WHILE (@@FETCH_STATUS = 0)
    BEGIN
      IF UPDATE(shopName)
        BEGIN
          RAISERROR ('''ShopName'' column are tried to update', 10, 1)
          ROLLBACK
        END
      ELSE
        BEGIN
          UPDATE ShopSchema.Shopman SET
            firstName = @firstName,
            lastName = @lastName,
            phone = @phone,
            isFired = @isFired,
            shopCode = @shopCode
          WHERE ShopSchema.Shopman.shopmanCode = @shopmanCode
        END
      FETCH NEXT FROM @admins_cursor INTO @shopmanCode, @firstName, @lastName, @phone, @isFired, @shopCode
    END
  END
GO

UPDATE ShopSchema.Admins SET phone = '89253577755' WHERE shopmanCode = 6
GO

CREATE TRIGGER ShopSchema.admins_delete
ON ShopSchema.Admins
INSTEAD OF DELETE
AS
  DELETE FROM Shopman WHERE Shopman.shopmanCode IN (SELECT deleted.shopmanCode FROM deleted)
GO

DELETE FROM ShopSchema.Admins WHERE firstName = 'asd'
