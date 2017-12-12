USE master
GO

CREATE DATABASE DB_Shop_1
	ON (
		name = Shop_dat,
		filename = 'E:\Sorry\DBProjects\Lab13\ShopDB1\ShopDB_dat.mdf',
		size = 10,
		maxsize = unlimited,
		filegrowth = 5%
		)
	LOG ON (
		name = Shop_log,
		filename = 'E:\Sorry\DBProjects\Lab13\ShopDB1\ShopDB_log.ldf',
		size = 5,
		maxsize = 25,
		filegrowth = 5
		) ;
GO

CREATE DATABASE DB_Shop_2
	ON (
		name = Shop_dat,
		filename = 'E:\Sorry\DBProjects\Lab13\ShopDB2\ShopDB_dat.mdf',
		size = 10,
		maxsize = unlimited,
		filegrowth = 5%
		)
	LOG ON (
		name = Shop_log,
		filename = 'E:\Sorry\DBProjects\Lab13\ShopDB2\ShopDB_log.ldf',
		size = 5,
		maxsize = 25,
		filegrowth = 5
		) ;
GO

USE DB_Shop_1

CREATE SCHEMA LinkedSchema

CREATE TABLE LinkedSchema.[Shop]
(
    shopCode INT NOT NULL,
    shopName VARCHAR(100) UNIQUE,
    isOutlet BIT NOT NULL,
    address  VARCHAR(100)   NOT NULL,
    city VARCHAR(50) NOT NULL CHECK (city = 'Moscow'),
	  PRIMARY KEY (shopCode, city)
)
 GO

CREATE VIEW LinkedSchema.Shops AS
SELECT * FROM DB_Shop_1.LinkedSchema.Shop
	UNION ALL
SELECT * FROM DB_Shop_2.LinkedSchema.Shop
GO

USE DB_Shop_2

CREATE SCHEMA LinkedSchema

CREATE TABLE LinkedSchema.[Shop]
(
    shopCode INT NOT NULL,
    shopName VARCHAR(100) UNIQUE,
    isOutlet BIT NOT NULL,
    address  VARCHAR(100)   NOT NULL,
    city VARCHAR(50) NOT NULL CHECK (city = 'St. Petersburg'),
		PRIMARY KEY (shopCode, city)
)
 GO

CREATE VIEW LinkedSchema.Shops AS
SELECT * FROM DB_Shop_1.LinkedSchema.Shop
	UNION ALL
SELECT * FROM DB_Shop_2.LinkedSchema.Shop
GO

INSERT INTO DB_Shop_2.LinkedSchema.Shops (shopCode, shopName, isOutlet, address, city) VALUES
	(34,'bauman', 0, 'baumanskaya', 'Moscow'),
	(35,'spgu', 0, 'spgu st', 'St. Petersburg')

SELECT * FROM DB_Shop_2.LinkedSchema.Shops

UPDATE DB_Shop_2.LinkedSchema.Shops SET DB_Shop_2.LinkedSchema.Shops.shopName = 'Bauman Shop'
WHERE DB_Shop_2.LinkedSchema.Shops.address = 'baumanskaya'

DELETE FROM DB_Shop_2.LinkedSchema.Shops WHERE DB_Shop_2.LinkedSchema.Shops.shopCode IN (34, 35)

--=============--
--Lab14--
--=============--

USE DB_Shop_1

CREATE TABLE LinkedSchema.ShopVert
(
	shopCode INT PRIMARY KEY NOT NULL,
	shopName VARCHAR(100) UNIQUE NOT NULL,
)
	GO

INSERT INTO LinkedSchema.ShopVert (shopCode, shopName) SELECT shopCode, shopName FROM LinkedSchema.Shops
GO

CREATE VIEW LinkedSchema.ShopsVertView AS
SELECT A.shopCode, A.shopName, B.isOutlet, B.address, B.city FROM DB_Shop_1.LinkedSchema.ShopVert AS A
	JOIN DB_Shop_2.LinkedSchema.ShopVert AS B ON A.shopCode = B.shopCode
GO

USE DB_Shop_2

CREATE TABLE LinkedSchema.ShopVert
(
	shopCode INT PRIMARY KEY NOT NULL,
	isOutlet BIT NOT NULL,
  address  VARCHAR(100)   NOT NULL,
  city VARCHAR(50) NOT NULL
)
GO

INSERT INTO LinkedSchema.ShopVert (shopCode, isOutlet, address, city)
	SELECT shopCode, isOutlet, address, city FROM LinkedSchema.Shops
GO

CREATE VIEW LinkedSchema.ShopsVertView AS
SELECT A.shopCode, A.shopName, B.isOutlet, B.address, B.city FROM DB_Shop_1.LinkedSchema.ShopVert AS A
	JOIN DB_Shop_2.LinkedSchema.ShopVert AS B ON A.shopCode = B.shopCode
GO

CREATE TRIGGER LinkedSchema.tr_insert_ShopsVertView
ON LinkedSchema.ShopsVertView
INSTEAD OF INSERT
AS
	BEGIN
		INSERT INTO DB_Shop_1.LinkedSchema.ShopVert (shopCode, shopName)
			SELECT inserted.shopCode, inserted.shopName FROM inserted

		INSERT INTO DB_Shop_2.LinkedSchema.ShopVert (shopCode, isOutlet, address, city)
			SELECT inserted.shopCode, inserted.isOutlet, inserted.address, inserted.city FROM inserted
	END
GO

INSERT INTO LinkedSchema.ShopsVertView (shopCode, shopName, isOutlet, address, city)
		VALUES (34, 'a', 0, 'b', 'c'), (35, 'd', 0, 'e', 'f')

CREATE TRIGGER LinkedSchema.tr_update_ShopsVertView
ON LinkedSchema.ShopsVertView
INSTEAD OF UPDATE
AS
	IF (UPDATE(shopCode))
		THROW 50000, 'Trying to update ''id'' column', 1
	ELSE
	BEGIN
		UPDATE DB_Shop_1.LinkedSchema.ShopVert SET
			shopName = inserted.shopName
		FROM inserted
		WHERE inserted.shopCode = DB_Shop_1.LinkedSchema.ShopVert.shopCode

		UPDATE DB_Shop_2.LinkedSchema.ShopVert SET
			isOutlet = inserted.isOutlet,
			address = inserted.address,
			city = inserted.city
		FROM inserted
		WHERE inserted.shopCode = DB_Shop_2.LinkedSchema.ShopVert.shopCode
	END
GO

UPDATE LinkedSchema.ShopsVertView SET
	address = 'bauman st.',
	shopName = shopName + ' ++'
	WHERE shopCode IN (34, 35)
GO

CREATE TRIGGER LinkedSchema.tr_delete_ShopsVertView
ON LinkedSchema.ShopsVertView
INSTEAD OF DELETE
AS
	BEGIN
		DELETE FROM DB_Shop_1.LinkedSchema.ShopVert WHERE shopCode IN (SELECT deleted.shopCode FROM deleted)
		DELETE FROM DB_Shop_2.LinkedSchema.ShopVert WHERE shopCode IN (SELECT deleted.shopCode FROM deleted)
	END
GO

DELETE FROM LinkedSchema.ShopsVertView WHERE shopCode IN (34, 35)



--===========--
--Lab15
--===========--

USE DB_Shop_1

CREATE SCHEMA LinkedSchema

CREATE TABLE LinkedSchema.Shop
(
    shopCode INT NOT NULL PRIMARY KEY IDENTITY (0, 1),
    shopName VARCHAR(100) UNIQUE,
    isOutlet BIT NOT NULL,
    address  VARCHAR(100)   NOT NULL,
    city VARCHAR(50),
)
 GO

CREATE TRIGGER LinkedSchema.tr_delete_shop
ON LinkedSchema.Shop
AFTER DELETE
AS
	DELETE FROM DB_Shop_2.LinkedSchema.Shopman WHERE Shopman.shopCode IN (SELECT shopCode FROM deleted)
GO

USE DB_Shop_2

CREATE SCHEMA LinkedSchema

CREATE TABLE DB_Shop_2.LinkedSchema.[Shopman]
(
    shopmanCode INT PRIMARY KEY NOT NULL IDENTITY(0, 1),
    firstName VARCHAR(25) NOT NULL,
    lastName VARCHAR(25) NOT NULL,
    middleName VARCHAR(25),
    dateOfBirth DATE NOT NULL,
    phone CHAR(11) NOT NULL UNIQUE,
    position VARCHAR(25),
    isFired BIT DEFAULT 0,

    shopCode INT NOT NULL,
)
  GO

CREATE VIEW LinkedSchema.[Shops and Shopmans]
AS
SELECT A.shopCode, shopName, isOutlet, address, city, shopmanCode, firstName, lastName, middleName, dateOfBirth, phone, position, isFired
FROM DB_Shop_1.LinkedSchema.Shop AS A JOIN DB_Shop_2.LinkedSchema.Shopman AS B
	ON A.shopCode = B.shopCode

CREATE TRIGGER LinkedSchema.tr_insert_shopman
ON LinkedSchema.Shopman
INSTEAD OF INSERT
AS
	IF (EXISTS(SELECT * FROM inserted WHERE inserted.shopCode NOT IN (SELECT shopCode FROM DB_Shop_1.LinkedSchema.Shop)))
			THROW 50000, 'Parent can''t be found', 1
	ELSE
		INSERT INTO LinkedSchema.Shopman (firstName, lastName, middleName, dateOfBirth, phone, position, shopCode)
			SELECT firstName, lastName, middleName, dateOfBirth, phone, position, shopCode FROM inserted
GO

INSERT INTO LinkedSchema.Shopman (firstName, lastName, middleName, dateOfBirth, phone, position, shopCode)
		VALUES ('a', 'b', 'c', '1997-02-02', '89635569874', 'продавец-консультант', 0)

CREATE TRIGGER LinkedSchema.tr_update_shopman
ON LinkedSchema.Shopman
INSTEAD OF UPDATE
AS
	IF (EXISTS(SELECT * FROM inserted WHERE inserted.shopCode NOT IN (SELECT shopCode FROM DB_Shop_1.LinkedSchema.Shop)))
		THROW 50000, 'Parent can''t be found', 1
	ELSE IF (UPDATE(middleName))
		THROW 50000, 'Trying to update column ''middleName''', 1
  ELSE IF (UPDATE(dateOfBirth))
		THROW 50000, 'Trying to update column ''dateOfBirth''', 1
  ELSE IF (exists(SELECT inserted.position FROM inserted WHERE inserted.position NOT IN ('уборщик', 'администратор', 'продавец-консультант', 'старший продавец')))
		THROW 50000, 'Invalid position', 1
  ELSE
    UPDATE LinkedSchema.Shopman SET
			firstName  = inserted.firstName,
			lastName   = inserted.lastName,
			middleName = inserted.middleName,
			phone      = inserted.phone,
			position   = inserted.position,
			isFired    = inserted.isFired,
			shopCode   = inserted.shopCode
     FROM inserted
     WHERE Shopman.shopmanCode = inserted.shopmanCode
GO

UPDATE LinkedSchema.Shopman SET shopCode = 1 WHERE firstName = 'a'

DELETE FROM LinkedSchema.Shopman WHERE firstName = 'a'

CREATE TRIGGER LinkedSchema.shops_and_shopmans_insert
ON LinkedSchema.[Shops and Shopmans]
INSTEAD OF INSERT
AS
  BEGIN
    	INSERT INTO DB_Shop_1.LinkedSchema.Shop (shopName, isOutlet, address, city)
				SELECT DISTINCT shopName, isOutlet, address, city FROM inserted

    	INSERT INTO LinkedSchema.Shopman (firstName, lastName, middleName, dateOfBirth, phone, position, shopCode)
      	SELECT firstName, lastName, middleName, dateOfBirth, phone, position,
					(SELECT shopCode FROM DB_Shop_1.LinkedSchema.Shop WHERE DB_Shop_1.LinkedSchema.Shop.shopName = inserted.shopName) FROM inserted
  END
GO

CREATE TRIGGER LinkedSchema.shops_and_shopmans_delete
ON LinkedSchema.[Shops and Shopmans]
INSTEAD OF DELETE
AS
	DELETE FROM DB_Shop_2.LinkedSchema.Shopman WHERE shopmanCode IN (SELECT shopmanCode FROM deleted)
GO

CREATE TRIGGER LinkedSchema.shops_and_shopmans_update
ON LinkedSchema.[Shops and Shopmans]
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
        UPDATE DB_Shop_1.LinkedSchema.Shop SET
          isOutlet = inserted.isOutlet,
          address  = inserted.address
        FROM inserted
        WHERE Shop.shopCode = inserted.shopCode

        UPDATE DB_Shop_2.LinkedSchema.Shopman SET
          firstName  = inserted.firstName,
          lastName   = inserted.lastName,
          middleName = inserted.middleName,
          phone      = inserted.phone,
          position   = inserted.position,
          isFired    = inserted.isFired,
          shopCode   = inserted.shopCode
        FROM inserted
        WHERE DB_Shop_2.LinkedSchema.Shopman.shopmanCode = inserted.shopmanCode
      END
  END
GO
