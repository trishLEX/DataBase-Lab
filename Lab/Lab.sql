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
    shopName VARCHAR(100) UNIQUE,
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
    phone CHAR(11) NOT NULL UNIQUE,
    position VARCHAR(25),
    isFired BIT DEFAULT 0,

    shopCode INT NOT NULL,
    FOREIGN KEY (shopCode) REFERENCES ShopDB.ShopSchema.[Shop](shopCode) ON DELETE CASCADE
)
  GO

CREATE TABLE ShopDB.ShopSchema.[Check]
(
    checkID INT PRIMARY KEY NOT NULL IDENTITY(0, 1),
    date DATETIME NOT NULL,
    totalCost MONEY NOT NULL,
    typeOfPay BIT NOT NULL,
    discount SMALLINT DEFAULT 0,
    shopmanCode INT NOT NULL,
    UNIQUE (date, totalCost),
    FOREIGN KEY (shopmanCode) REFERENCES ShopDB.ShopSchema.[Shopman] (shopmanCode)
)
  GO

CREATE TABLE ShopDB.ShopSchema.[Card_Subtype]
(
  checkID INT PRIMARY KEY NOT NULL,
  FOREIGN KEY (checkID) REFERENCES ShopDB.ShopSchema.[Check] (checkID) ON DELETE CASCADE ,

  cardID INT NOT NULL,
  FOREIGN KEY (cardID) REFERENCES ShopDB.ShopSchema.[Card] (cardID)
)
  GO

CREATE TABLE ShopDB.ShopSchema.[Card]
(
  cardID INT PRIMARY KEY NOT NULL IDENTITY(0, 1),
  type BIT DEFAULT 0,
  phone CHAR(11) NOT NULL UNIQUE,
  firstName VARCHAR(25) NOT NULL,
  lastName VARCHAR(25) NOT NULL,
)
  GO

CREATE TABLE ShopDB.ShopSchema.[Event]
(
  eventID INT PRIMARY KEY NOT NULL IDENTITY(0, 1),
  description VARCHAR(500) NOT NULL,
  expDate DATE NOT NULL,
)
  GO

CREATE TABLE ShopDB.ShopSchema.[Event_Subtype]
(
  checkID INT PRIMARY KEY NOT NULL,
  FOREIGN KEY (checkID) REFERENCES ShopDB.ShopSchema.[Check] (checkID) ON DELETE CASCADE ,

  eventID INT NOT NULL,
  FOREIGN KEY (eventID) REFERENCES ShopDB.ShopSchema.[Event] (eventID)
)
  GO

CREATE TABLE ShopDB.ShopSchema.[Item]
(
  itemID INT PRIMARY KEY NOT NULL IDENTITY(0, 1),
  itemName VARCHAR(100) NOT NULL UNIQUE,
  description VARCHAR(100) NOT NULL,
  country VARCHAR(58) NOT NULL
  --TODO триггер для связи со складом
  --TODO в триггере проверять при удалнии, что для него нет чеков
)
  GO

CREATE TABLE ShopDB.ShopSchema.[Check_Item_INT]
(
  checkID INT NOT NULL,
  itemID  INT NOT NULL,
  count   INT NOT NULL DEFAULT 1,

  PRIMARY KEY (checkID, itemID),

  FOREIGN KEY (checkID) REFERENCES ShopDB.ShopSchema.[Check] (checkID) ON DELETE CASCADE ,
  FOREIGN KEY (itemID)  REFERENCES ShopDB.ShopSchema.[Item]  (itemID),
)
  GO

CREATE TABLE ShopDB.ShopSchema.[Store]
(
  shopCode INT NOT NULL,
  FOREIGN KEY (shopCode) REFERENCES ShopDB.ShopSchema.[Shop] (shopCode) ON DELETE CASCADE ,

  itemID INT NOT NULL,
  FOREIGN KEY (itemID)  REFERENCES ShopDB.ShopSchema.[Item]  (itemID) ON DELETE CASCADE ,

  PRIMARY KEY (shopCode, itemID),

  rest INT NOT NULL CHECK (rest >= 0),
  price MONEY NOT NULL CHECK (price > 0)
)
  GO


--чеки с карторй
SELECT [Check].[checkID], [Check].[totalCost] FROM ShopDB.ShopSchema.[Check] WHERE [Check].[checkID] in (SELECT checkID FROM ShopDB.ShopSchema.Card_Subtype)
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

--таблица, где для каждого товара указано количесвто его продаж и выручка с этого, цена > 5000
SELECT T.itemName, T.Count, T.price * T.Count AS [Total Profit]
  FROM (SELECT D.itemName, D.Count, D.price, MAX(D.Count) AS [SMTH]
        FROM (SELECT C.itemName, C.itemID, C.Count, price
              FROM (SELECT itemName, A.Count, B.itemID
                    FROM (SELECT itemID, count(*) as Count
                          FROM ShopSchema.Check_Item_INT GROUP BY itemID) AS A
                      JOIN ShopSchema.Item AS B ON A.itemID = B.itemID) AS C
                JOIN ShopSchema.Store ON C.itemID = ShopSchema.Store.itemID) AS D
        GROUP BY D.itemName, D.Count, D.price HAVING D.price > 5000) AS T
  ORDER BY [Total Profit] DESC
GO

--для каждого города указана максимальнеая продажа
SELECT [SHOPS].city, MAX([SHOPS].maxSale) AS maxSale
  FROM (SELECT S.city, R.maxSale
        FROM ShopSchema.[Shop] AS S, (SELECT MX.shopName, MAX(MX.maxCost) AS maxSale
                                      FROM (SELECT shopName, shopmanCode, maxCost
                                            FROM (SELECT C.shopmanCode, MAX(totalCost) AS maxCost
                                                  FROM (SELECT Shopman.shopmanCode, totalCost
                                                        FROM ShopSchema.Shopman JOIN ShopSchema.[Check] ON Shopman.shopmanCode = [Check].shopmanCode) AS C
  GROUP BY shopmanCode) AS A
  JOIN ShopSchema.Shop AS B ON exists(SELECT D.shopCode FROM ShopSchema.Shopman AS D WHERE D.shopCode = B.shopCode AND D.shopmanCode = A.shopmanCode))
  AS MX GROUP BY MX.shopName) AS R WHERE S.shopName = R.shopName) AS [SHOPS] GROUP BY [SHOPS].city ORDER BY  maxSale DESC
GO

--суммарная прибыль с каждого города с какой-то по какую-то дату
WITH SELLINGS_CTE (City, Cost)
AS
(
  SELECT A.city, [CHECKS].totalCost AS [COST] FROM (SELECT [SHOPS].city, [SALERS].shopmanCode
                                                    FROM ShopSchema.Shop AS [SHOPS], ShopSchema.Shopman AS [SALERS]
                                                    WHERE [SHOPS].shopCode = [SALERS].shopCode) AS A
  JOIN ShopSchema.[Check] AS [CHECKS] ON [CHECKS].shopmanCode = A.shopmanCode and CHECKS.date BETWEEN '2017-06-01' AND '2017-08-31'
)
SELECT SELLINGS_CTE.City, SUM(SELLINGS_CTE.Cost) AS [Total Profit] FROM SELLINGS_CTE GROUP BY SELLINGS_CTE.City ORDER BY [Total Profit] ASC
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

--товары с ценой
SELECT DISTINCT itemName, price FROM ShopSchema.Item JOIN ShopSchema.Store ON Item.itemID = Store.itemID

--чеки со стоимостью от 15000 или до 20000 (с повторениями)
SELECT checkID, totalCost FROM ShopSchema.[Check] WHERE totalCost > 15000
UNION ALL SELECT checkID, totalCost FROM ShopSchema.[Check] WHERE totalCost < 20000

--чеки со стоимостью от 15000 или до 20000 (без повторений)
SELECT checkID, totalCost FROM ShopSchema.[Check] WHERE totalCost > 15000
UNION SELECT checkID, totalCost FROM ShopSchema.[Check] WHERE totalCost < 20000

--чеки со стоимостью >=20000
SELECT checkID, totalCost FROM ShopSchema.[Check] WHERE totalCost > 15000
EXCEPT SELECT checkID, totalCost FROM ShopSchema.[Check] WHERE totalCost < 20000


--чеки со стоимостью от 15000 до 20000
SELECT checkID, totalCost FROM ShopSchema.[Check] WHERE totalCost > 15000
INTERSECT SELECT checkID, totalCost FROM ShopSchema.[Check] WHERE totalCost < 20000
GO

SELECT A.cardID, A.firstName, A.lastName, date, discount, totalCost FROM (SELECT Card.cardID, Card_Subtype.checkID, firstName, lastName
              FROM ShopSchema.Card JOIN ShopSchema.Card_Subtype ON Card.cardID = Card_Subtype.cardID) AS A
  RIGHT JOIN ShopSchema.[Check] ON A.checkID = [Check].checkID
GO

SELECT [Check].checkID, date, totalCost, eventID FROM ShopSchema.[Check] LEFT JOIN ShopSchema.Event_Subtype ON [Check].checkID = Event_Subtype.checkID
GO

SELECT [Check].checkID, date, totalCost, cardID, eventID FROM ShopSchema.[Check] FULL OUTER JOIN ShopSchema.Card_Subtype ON [Check].checkID = Card_Subtype.checkID
FULL OUTER JOIN ShopSchema.Event_Subtype ON [Check].checkID = Event_Subtype.checkID
GO

SELECT AVG(A.totalCost) FROM (SELECT [Check].checkID, date, totalCost, cardID, eventID FROM ShopSchema.[Check] FULL OUTER JOIN ShopSchema.Card_Subtype ON [Check].checkID = Card_Subtype.checkID
FULL OUTER JOIN ShopSchema.Event_Subtype ON [Check].checkID = Event_Subtype.checkID
WHERE eventID IS NULL OR cardID IS NULL) AS A
GO

SELECT MIN(A.totalCost), A.city FROM (SELECT totalCost, S.shopmanCode, city
                            FROM ShopSchema.[Check] JOIN ShopSchema.Shopman AS S ON [Check].shopmanCode = S.shopmanCode
                            JOIN ShopSchema.Shop AS SH ON S.shopCode = SH.shopCode) AS A GROUP BY city

--========================--

CREATE VIEW ShopSchema.[Shopmans' phone numbers] AS
  (SELECT [Shopman].firstName, [Shopman].lastName, [Shopman].phone
  FROM ShopSchema.Shopman AS [Shopman])
GO
CREATE VIEW ShopSchema.[Stores' Profit] WITH SCHEMABINDING
  AS
    (SELECT MX.shopName, MAX(MX.maxCost) AS maxSale
      FROM (SELECT shopName, shopmanCode, maxCost
            FROM (SELECT C.shopmanCode, MAX(totalCost) AS maxCost
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
  RETURN SELECT S.lastName, S.firstName, Shop.shopName, Shop.shopCode FROM ShopSchema.Shopman AS S JOIN ShopSchema.Shop ON S.shopCode = Shop.shopCode
  WHERE Shop.city = @city AND (S.position = 'продавец-консультант' OR S.position = 'администратор' OR S.position = 'старший продавец')
GO

CREATE PROCEDURE ShopSchema.usp_checks_from_data_by_city_cursor
  @date DATE,
  @checks_cursor CURSOR VARYING OUTPUT
AS
  SET @checks_cursor = CURSOR FORWARD_ONLY
                            STATIC
  FOR SELECT DISTINCT A.totalCost, A.discount, A.lastName, A.firstName, CITY.shopName AS [Shop] FROM (SELECT [Check].totalCost, [Check].discount, S.lastName, S.firstName, S.shopCode
  FROM ShopSchema.[Check]
  JOIN ShopSchema.[Shopman] AS S ON [Check].shopmanCode = S.shopmanCode) AS A
  JOIN ShopSchema.fn_sellers_by_city('Moscow') AS CITY ON A.shopCode = CITY.shopCode
  WHERE [Check].date BETWEEN @date AND GETDATE()
  OPEN @checks_cursor
GO

CREATE FUNCTION ShopSchema.search_shopCode_by_shopmanCode(@shopmanCode INT) RETURNS INT WITH SCHEMABINDING
AS
BEGIN
  DECLARE @shopCode INT
  SELECT @shopCode = shopCode FROM ShopSchema.Shopman WHERE @shopmanCode = shopmanCode
  RETURN @shopCode
END
GO

CREATE VIEW ShopSchema.[Items_in_check] WITH SCHEMABINDING
AS
SELECT C.checkID, C.date, C.totalCost, C.typeOfPay, C.discount, C.shopmanCode, I.itemID, I.itemName, I.description, I.country, INT.count, S.price
FROM ShopSchema.[Check] AS C
  JOIN ShopSchema.Check_Item_INT AS INT ON C.checkID = INT.checkID
  JOIN ShopSchema.Item AS I ON INT.itemID = I.itemID
  JOIN ShopSchema.Store AS S ON I.itemID = S.itemID AND ShopSchema.search_shopCode_by_shopmanCode(C.shopmanCode) = S.shopCode
GO


CREATE VIEW ShopSchema.[Checks_with_cards_and_items] WITH SCHEMABINDING
AS
SELECT C.checkID, C.date, C.totalCost, C.typeOfPay, C.discount, C.shopmanCode,
  IT.itemID, IT.itemName, IT.description, IT.country, IT.count, IT.price,
  CD.cardID, CD.type, CD.phone, CD.lastName, CD.firstName FROM ShopSchema.[Check] AS C
JOIN ShopSchema.Card_Subtype AS S ON C.checkID = S.checkID
JOIN ShopSchema.Card AS CD ON CD.cardID = S.cardID
JOIN ShopSchema.Items_in_check AS IT ON IT.checkID = C.checkID
GO

CREATE TRIGGER ShopSchema.tr_insert
ON ShopSchema.Checks_with_cards_and_items
INSTEAD OF INSERT
AS
  BEGIN
    DECLARE @checkID INT
    DECLARE @date DATETIME
    DECLARE @totalCost MONEY
    DECLARE @typeOfPay BIT
    DECLARE @discount SMALLINT
    DECLARE @shopmanCode INT
    DECLARE @itemID INT
    DECLARE @itemName VARCHAR(100)
    DECLARE @description VARCHAR(100)
    DECLARE @country VARCHAR(58)
    DECLARE @count INT
    DECLARE @price MONEY
    DECLARE @cardID INT
    DECLARE @type BIT
    DECLARE @phone CHAR(11)
    DECLARE @lastName VARCHAR(25)
    DECLARE @firstName VARCHAR(25)

    DECLARE @cursor CURSOR
    DECLARE @error_msg VARCHAR(50)

    SET @cursor = CURSOR FORWARD_ONLY STATIC
      FOR SELECT  inserted.checkID, inserted.date, inserted.totalCost, inserted.typeOfPay, inserted.discount, inserted.shopmanCode, inserted.itemID, inserted.itemName, inserted.description,
                  inserted.country, inserted.count, inserted.price, inserted.cardID, inserted.type, inserted.phone, inserted.lastName, inserted.firstName FROM inserted
    OPEN @cursor

    FETCH NEXT FROM @cursor INTO @checkID, @date, @totalCost, @typeOfPay, @discount, @shopmanCode, @itemID, @itemName, @description, @country, @count, @price, @cardID, @type, @phone, @lastName, @firstName

    WHILE (@@FETCH_STATUS = 0)
    BEGIN
      IF @itemID NOT IN (SELECT I.itemID FROM ShopSchema.Item AS I)
        BEGIN
          SET @error_msg = 'It''s forbidden to paste new items in this view. Wrong itemID: ' + CAST(@itemID AS VARCHAR)
          RAISERROR(@error_msg, 10, 1)
        END
      ELSE IF(@itemName NOT IN (SELECT I.itemName FROM ShopSchema.Item AS I))
        BEGIN
          SET @error_msg = 'Item with name: ' + @itemName + ' doesn''t exist'
          RAISERROR(@error_msg, 10, 1)
        END
      ELSE IF (NOT EXISTS(SELECT I.itemID FROM ShopSchema.Item AS I WHERE I.itemName = @itemName AND I.itemID = @itemID))
        BEGIN
          SET @error_msg = 'ItemID: ' + CAST(@itemID AS VARCHAR) + ' doesn''t correspond with ItemName: ' + @itemName
          RAISERROR(@error_msg, 10, 1)
        END
      IF (@checkID IS NULL)
        BEGIN
          IF ((SELECT SUM(inserted.count * inserted.price * (100 - @discount) / 100) FROM inserted WHERE inserted.date = @date) != @totalCost)
            THROW 50000, 'TotalCost in check doesn''t equal to sum of items price', 1

          IF (@date IN (SELECT date FROM ShopSchema.[Check]))
            SELECT @checkID = checkID FROM ShopSchema.[Check] WHERE [Check].date = @date AND [Check].totalCost = @totalCost
          ELSE
            BEGIN
              INSERT INTO ShopSchema.[Check] (date, totalCost, typeOfPay, shopmanCode)
                VALUES (@date, @totalCost, @typeOfPay, @shopmanCode)
              SET @checkID = ident_current('ShopSchema.[Check]')
            END

          INSERT INTO ShopSchema.Check_Item_INT (checkID, itemID) VALUES (@checkID, @itemID)

          IF (@discount != 0)
            BEGIN
              IF (@cardID NOT IN (SELECT cardID FROM ShopSchema.Card))
                BEGIN
                  INSERT INTO ShopSchema.Card (type, phone, firstName, lastName)
                    VALUES (@type, @phone, @firstName, @lastName)
                  SET @cardID = ident_current('ShopSchema.Card')
                END
              INSERT INTO ShopSchema.Card_Subtype (checkID, cardID) VALUES (@checkID, @cardID)
            END
        END
      ELSE
        BEGIN
          IF ((SELECT SUM(inserted.count * inserted.price) FROM inserted WHERE @checkID = inserted.checkID) != @totalCost)
            THROW 50000, 'TotalCost in check doesn''t equal to sum of items price', 1

          INSERT INTO ShopSchema.Check_Item_INT (checkID, itemID) VALUES (@checkID, @itemID)
        END
      FETCH NEXT FROM @cursor INTO @checkID, @date, @totalCost, @typeOfPay, @discount, @shopmanCode, @itemID, @itemName, @description, @country, @count, @price, @cardID, @type, @phone, @lastName, @firstName
    END
    CLOSE @cursor
    DEALLOCATE @cursor
  END
GO

INSERT INTO ShopSchema.Checks_with_cards_and_items (date, totalCost, typeOfPay, shopmanCode, itemID, itemName, description, country, price)
    VALUES ('2017-11-26T15:47:00', 6900, 0, 0, 10, '504 Regular Straight Jeans', 'Live in Levi''s', 'Turkey', 6900)

INSERT INTO ShopSchema.Checks_with_cards_and_items (date, totalCost, typeOfPay, discount, shopmanCode, itemID, itemName, description, country, count, price, cardID, type, phone, lastName, firstName)
    VALUES ('2015-11-26T15:48:00', 6210, 0, 10, 0, 10, '504 Regular Straight Jeans', 'Live in Levi''s', 'Turkey', 1, 6900, 0, 1, '89888432908', 'Копылов', 'Ленур')

CREATE TRIGGER ShopSchema.tr_delete
ON ShopSchema.Checks_with_cards_and_items
INSTEAD OF DELETE
AS
BEGIN
  IF ((SELECT MIN(ShopSchema.calculateAge(deleted.date)) FROM deleted) < 1)
    THROW 50000, 'There are checks, that are dated less than year ago', 1
  DELETE FROM ShopSchema.Check_Item_INT WHERE Check_Item_INT.checkID IN (SELECT deleted.checkID FROM deleted)
  DELETE FROM ShopSchema.Card_Subtype WHERE Card_Subtype.checkID IN (SELECT deleted.checkID FROM deleted)
  DELETE FROM ShopSchema.[Check] WHERE [Check].checkID IN (SELECT deleted.checkID FROM deleted)
END

DELETE FROM ShopSchema.Checks_with_cards_and_items WHERE checkID = 13504

CREATE TRIGGER ShopSchema.tr_update
ON ShopSchema.Checks_with_cards_and_items
INSTEAD OF UPDATE
AS
  BEGIN
    RAISERROR('It''s not allowed to update columns from this view', 10, 1)
  END


--===============================--
--Lab9
--===============================--

CREATE VIEW ShopSchema.[Shops and Shopmans] WITH SCHEMABINDING
AS
SELECT Shop.shopCode, shopName, isOutlet, address, city, shopmanCode, firstName, lastName, middleName, dateOfBirth, phone, position, isFired FROM ShopSchema.Shop JOIN ShopSchema.Shopman
  ON Shop.shopCode = Shopman.shopCode
GO

CREATE TRIGGER ShopSchema.shopman_insert
ON ShopSchema.Shopman
INSTEAD OF INSERT
AS
  BEGIN
  IF (exists(SELECT phone FROM inserted GROUP BY phone HAVING COUNT(phone) > 1))
      THROW 50000, 'Trying to insert same phone numbers', 1
  IF (exists(SELECT inserted.position FROM inserted WHERE inserted.position NOT IN ('уборщик', 'администратор', 'продавец-консультант', 'старший продавец')))
        THROW 50000, 'Invalid position', 1
  ELSE IF (exists(SELECT * FROM inserted WHERE inserted.phone IN (SELECT phone FROM ShopSchema.Shopman)))
        THROW 50000, 'Invalid phone', 1
  ELSE
    INSERT INTO ShopSchema.Shopman (firstName, lastName, middleName, dateOfBirth, phone, position, shopCode)
      SELECT inserted.firstName, inserted.lastName, inserted.middleName, inserted.dateOfBirth, inserted.phone, inserted.position, inserted.shopCode FROM inserted
 END
GO
INSERT ShopSchema.Shopman (firstName, lastName, middleName, dateOfBirth, phone, position, shopCode) VALUES ('a', 'b', 'c', '1993-01-01', '89164472638', 'bellboy', 0)
GO

CREATE TRIGGER ShopSchema.shopman_update
ON ShopSchema.Shopman
INSTEAD OF UPDATE
AS
  BEGIN
    IF (UPDATE(middleName))
      RAISERROR ('Trying to update column ''middleName''', 10, 1)
    IF (UPDATE(dateOfBirth))
      RAISERROR ('Trying to update column ''dateOfBirth''', 10, 1)
    IF (exists(SELECT inserted.position FROM inserted WHERE inserted.position NOT IN ('уборщик', 'администратор', 'продавец-консультант', 'старший продавец')))
      THROW 50000, 'Invalid position', 1

    ELSE IF (NOT UPDATE(middleName) AND NOT UPDATE(dateOfBirth))
      UPDATE ShopSchema.Shopman SET
        firstName  = inserted.firstName,
        lastName   = inserted.lastName,
        middleName = inserted.middleName,
        phone      = inserted.phone,
        position   = inserted.position,
        isFired    = inserted.isFired,
        shopCode   = inserted.shopCode
     FROM inserted
      WHERE Shopman.shopmanCode = inserted.shopmanCode
  END
GO

UPDATE ShopSchema.Shopman SET position = 'администрато' WHERE position = 'администратор'
GO

CREATE TRIGGER ShopSchema.shopman_delete
ON ShopSchema.Shopman
INSTEAD OF DELETE
AS
  UPDATE ShopSchema.Shopman SET isFired = 1 WHERE shopmanCode IN (SELECT shopmanCode FROM deleted)
GO

DELETE FROM ShopSchema.Shopman WHERE shopmanCode = 0
UPDATE ShopSchema.Shopman SET isFired = 0 WHERE shopmanCode = 0

CREATE TRIGGER ShopSchema.shops_and_shopmans_insert
ON ShopSchema.[Shops and Shopmans]
INSTEAD OF INSERT
AS
  BEGIN
    --вставка только по shopName
    IF (EXISTS(SELECT * FROM inserted WHERE shopCode IS NOT NULL))
      THROW 50000, 'Trying to paste shopCode', 1
    ELSE BEGIN

      MERGE ShopSchema.Shop USING inserted ON (Shop.shopName = inserted.shopName)
        WHEN NOT MATCHED BY TARGET THEN INSERT (shopName, isOutlet, address) VALUES (inserted.shopName, inserted.isOutlet, inserted.address);

      INSERT INTO ShopSchema.Shopman (firstName, lastName, middleName, dateOfBirth, phone, position, shopCode)
        SELECT firstName, lastName, middleName, dateOfBirth, phone, position,
        (SELECT shopCode FROM ShopSchema.Shop WHERE Shop.shopName = inserted.shopName) FROM inserted
    END
  END

INSERT INTO ShopSchema.[Shops and Shopmans] (firstName, lastName, middleName, dateOfBirth, phone, isFired, shopName, city)
    VALUES ('asd', 'cvb', 'asd', '1980-10-10', '89548774629', 0, 'Levi''s store Moscow MEGA Belaya Dacha', 'Moscow')

CREATE TRIGGER ShopSchema.shops_and_shopmans_delete
ON ShopSchema.[Shops and Shopmans]
INSTEAD OF DELETE
AS
  DELETE FROM Shopman WHERE shopmanCode IN (SELECT shopmanCode FROM deleted)

CREATE TRIGGER ShopSchema.shops_and_shopmans_update
ON ShopSchema.[Shops and Shopmans]
INSTEAD OF UPDATE
AS
  BEGIN
    IF UPDATE(shopName)
      THROW 50000, 'Trying to update column ''shopName''', 1
    ELSE IF (UPDATE(middleName))
      THROW 50000, 'Trying to update column ''middleName''', 1
    IF (UPDATE(dateOfBirth))
      THROW 50000, 'Trying to update column ''dateOfBirth''', 1
    IF (exists(SELECT inserted.position FROM inserted WHERE inserted.position NOT IN ('уборщик', 'администратор', 'продавец-консультант', 'старший продавец')))
      THROW 50000, 'Invalid position', 1
    ELSE
      BEGIN
        UPDATE Shop SET
          isOutlet = inserted.isOutlet,
          address  = inserted.address
        FROM inserted
        WHERE Shop.shopCode = inserted.shopCode

        UPDATE ShopSchema.Shopman SET
          firstName  = inserted.firstName,
          lastName   = inserted.lastName,
          middleName = inserted.middleName,
          phone      = inserted.phone,
          position   = inserted.position,
          isFired    = inserted.isFired,
          shopCode   = inserted.shopCode
        FROM inserted
        WHERE Shopman.shopmanCode = inserted.shopmanCode
      END
  END

--========--
--Lab11--
--========--
CREATE TRIGGER ShopSchema.tr_insert_check_item_int
ON ShopSchema.Check_Item_INT
AFTER INSERT
AS
  BEGIN
    SELECT Shop.shopCode FROM (SELECT [Check].checkID, shopmanCode FROM [Check] WHERE [Check].checkID IN (SELECT checkID FROM inserted)) AS C
    JOIN Shopman ON C.shopmanCode = Shopman.shopmanCode
    JOIN Shop ON Shopman.shopCode = Shop.shopCode

    UPDATE Store SET rest = rest - 1 WHERE shopCode IN (SELECT Shop.shopCode FROM (SELECT [Check].checkID, shopmanCode FROM [Check] WHERE [Check].checkID IN (SELECT checkID FROM inserted)) AS C
    JOIN Shopman ON C.shopmanCode = Shopman.shopmanCode
    JOIN Shop ON Shopman.shopCode = Shop.shopCode) AND itemID IN (SELECT itemID FROM inserted)
  END
GO

CREATE TRIGGER ShopSchema.tr_insert_items_in_check
ON ShopSchema.Items_in_check
INSTEAD OF INSERT
AS
  BEGIN
    MERGE INTO ShopSchema.[Check] USING inserted ON (inserted.date = [Check].date AND inserted.totalCost = [Check].totalCost)
      WHEN NOT MATCHED BY TARGET THEN INSERT (date, totalCost, typeOfPay, discount, shopmanCode)
      VALUES (inserted.date, inserted.totalCost, inserted.typeOfPay, inserted.discount, inserted.shopmanCode);

    INSERT INTO ShopSchema.Check_Item_INT (checkID, itemID) SELECT (SELECT checkID
                                                                    FROM ShopSchema.[Check]
                                                                    WHERE ([Check].date = inserted.date AND
                                                                          [Check].totalCost = inserted.totalCost)),
                                                              itemID FROM inserted
  END
GO

CREATE VIEW ShopSchema.Items_Store WITH SCHEMABINDING
AS
SELECT Item.itemID, itemName, description, country, rest, price, shopCode FROM ShopSchema.Item JOIN ShopSchema.Store ON Item.itemID = Store.itemID
GO

CREATE TRIGGER ShopSchema.tr_insert_items_store
ON ShopSchema.Items_Store
INSTEAD OF INSERT
AS
  BEGIN
    MERGE INTO ShopSchema.Item USING inserted ON (inserted.itemName = Item.itemName)
      WHEN NOT MATCHED BY TARGET THEN INSERT (itemName, description, country)
      VALUES (inserted.itemName, inserted.description, inserted.country);

    MERGE INTO ShopSchema.Store USING inserted ON (inserted.itemID = Store.itemID AND inserted.shopCode = Store.shopCode)
      WHEN NOT MATCHED BY TARGET THEN INSERT (rest, price) VALUES (inserted.rest, inserted.price)
      WHEN MATCHED THEN UPDATE SET Store.rest = Store.rest + inserted.rest;

  END


SELECT * FROM ShopSchema.[Check] WHERE (4500, 0 NOT IN (SELECT totalCost, shopmanCode FROM [Check]))

CREATE TRIGGER ShopSchema.tr_delete_shop
ON ShopSchema.Shop
AFTER DELETE
AS
  BEGIN
    DELETE FROM Shopman WHERE Shopman.shopCode IN (SELECT shopmanCode FROM deleted)
  END
