CREATE VIEW ShopSchema.[Cards in check] WITH SCHEMABINDING
AS
SELECT phone, type, firstName, lastName, checkID FROM ShopSchema.Card JOIN ShopSchema.Card_Subtype ON Card.cardID = Card_Subtype.cardID
GO

CREATE VIEW ShopSchema.[Events in check] WITH SCHEMABINDING
AS
SELECT description, expDate, Event.eventID, checkID FROM ShopSchema.Event JOIN ShopSchema.Event_Subtype ON Event.eventID = Event_Subtype.eventID
GO

DELETE FROM ShopSchema.[Check] WHERE NOT (discount = 0) AND NOT EXISTS(SELECT * FROM ShopSchema.Event_Subtype WHERE Event_Subtype.checkID = [Check].checkID)
AND NOT EXISTS(SELECT * FROM ShopSchema.Card_Subtype WHERE Card_Subtype.checkID = [Check].checkID)



CREATE VIEW ShopSchema.[Items in check with price and discount] WITH SCHEMABINDING
AS
SELECT [Check].checkID, shopmanCode, typeOfPay, discount, date, totalCost,
  type, phone, firstName, lastName,
  eventID,
  Check_Item_INT.itemID, count, price
FROM ShopSchema.[Check]
  LEFT JOIN ShopSchema.[Cards in check] ON [Cards in check].checkID = [Check].checkID
  LEFT JOIN ShopSchema.[Events in check] ON [Events in check].checkID = [Check].checkID
  JOIN ShopSchema.Check_Item_INT ON [Check].checkID = Check_Item_INT.checkID
  JOIN ShopSchema.Store ON Check_Item_INT.itemID = Store.itemID AND ShopSchema.search_shopCode_by_shopmanCode([Check].shopmanCode) = Store.shopCode
GO

CREATE TRIGGER ShopSchema.tr_insert_check
ON ShopSchema.[Check]
INSTEAD OF INSERT
AS
  BEGIN
    IF ('уборщик' IN (SELECT position FROM ShopSchema.Shopman WHERE Shopman.shopmanCode IN (SELECT shopmanCode FROM inserted)))
      THROW 50000, 'Invalid shopmanCode', 1
    IF (EXISTS(SELECT * FROM inserted WHERE inserted.date > getdate()))
      THROW 50000, 'Invalid date', 1
    IF (EXISTS(SELECT * FROM inserted WHERE inserted.discount > 50))
      THROW 50000, 'Invalid discount', 1
    ELSE
      INSERT INTO ShopSchema.[Check] (date, totalCost, typeOfPay, discount, shopmanCode)
        SELECT date, totalCost, typeOfPay, discount, shopmanCode FROM inserted
  END

--INSERT INTO ShopSchema.[Check] VALUES ('2018-05-05', 9000, 0, 0, 1)

CREATE TRIGGER ShopSchema.tr_update_check
ON ShopSchema.[Check]
INSTEAD OF UPDATE
AS
  RAISERROR ('Checks can''t be updated', 10, 1)

CREATE TRIGGER ShopSchema.tr_update_card_subtype
ON ShopSchema.Card_Subtype
INSTEAD OF UPDATE
AS
  RAISERROR ('Table Card Subtype can''t be updated', 10, 1)

CREATE TRIGGER ShopSchema.card_insert
ON ShopSchema.Card
INSTEAD OF INSERT
AS
  BEGIN
    IF (EXISTS(SELECT * FROM inserted WHERE phone NOT LIKE '8%'))
      THROW 50000, 'Invalid phone', 1

    INSERT INTO ShopSchema.Card (type, phone, firstName, lastName) SELECT inserted.type, inserted.phone, inserted.firstName, inserted.lastName FROM inserted
  END
GO

CREATE TRIGGER ShopSchema.card_update
ON ShopSchema.Card
INSTEAD OF UPDATE
AS
  IF UPDATE(type)
        RAISERROR('Columns type is tried to update', 10, 1)
  ELSE
    UPDATE ShopSchema.Card SET
      phone = inserted.phone,
      firstName = inserted.firstName,
      lastName = inserted.lastName
    FROM inserted
    WHERE Card.cardID = inserted.cardID
GO

CREATE TRIGGER ShopSchema.tr_update_event_subtype
ON ShopSchema.Event_Subtype
INSTEAD OF UPDATE
AS
  RAISERROR ('Table Event Subtype can''t be updated', 10, 1)
GO

CREATE TRIGGER ShopSchema.tr_insert_event
ON ShopSchema.Event
INSTEAD OF INSERT
AS
  IF (EXISTS(SELECT * FROM inserted WHERE expDate < getdate()))
      THROW 50000, 'Invalid date', 1
  ELSE
    INSERT INTO ShopSchema.Event (description, expDate) SELECT description, expDate FROM inserted
GO

CREATE TRIGGER ShopSchema.tr_update_check_item_int
ON ShopSchema.Check_Item_INT
INSTEAD OF UPDATE
AS
  THROW 50000, 'Table Check_Item_INT can''t be updated', 1
GO

CREATE TRIGGER ShopSchema.tr_delete_check_item_int
ON ShopSchema.Check_Item_INT
AFTER DELETE
AS
  IF (EXISTS(SELECT * FROM deleted WHERE deleted.checkID IN (SELECT checkID FROM [Check])))
      BEGIN
        RAISERROR ('Trying to delete items in check', 10, 1)
        ROLLBACK
      END
GO

CREATE TRIGGER ShopSchema.tr_update_item
ON ShopSchema.Item
INSTEAD OF UPDATE
AS
  IF (UPDATE(itemName))
      THROW 50000, 'Trying to update itemName', 1
  ELSE
    UPDATE ShopSchema.Item SET
      description = inserted.description,
      country = inserted.country
    FROM inserted
    WHERE Item.itemID = inserted.itemID
GO

CREATE TRIGGER ShopSchema.tr_delete_item
ON ShopSchema.Item
INSTEAD OF DELETE
AS
  IF (EXISTS(SELECT * FROM deleted WHERE deleted.itemID IN (SELECT itemID FROM Store WHERE rest != 0)))
      THROW 50000, 'Trying to delete not null count of item', 1
  ELSE
  IF (EXISTS(SELECT * FROM deleted WHERE itemID IN (SELECT itemID FROM ShopSchema.Check_Item_INT)))
      THROW 50000, 'Trying to delete item that exists in check', 1
  ELSE
    DELETE FROM ShopSchema.Item WHERE itemID IN (SELECT itemID FROM deleted)
GO

CREATE VIEW ShopSchema.[Price of items] WITH SCHEMABINDING
AS
SELECT Item.itemID, shopCode, price, rest FROM ShopSchema.Item JOIN ShopSchema.Store ON Item.itemID = Store.itemID
GO

CREATE FUNCTION ShopSchema.fn_search_price (@itemID INT, @shopmanCode INT)
RETURNS MONEY
AS
  BEGIN
    DECLARE @shopCode INT
    SET @shopCode = ShopSchema.search_shopCode_by_shopmanCode(@shopmanCode)

    DECLARE @price MONEY
    SELECT @price = price FROM ShopSchema.Store WHERE itemID = @itemID AND shopCode = @shopCode
    RETURN @price
  END
GO

CREATE FUNCTION ShopSchema.fn_search_checkID (@date DATETIME, @totalcost MONEY)
RETURNS INT
AS
  BEGIN
    DECLARE @res INT
    SELECT @res = checkID FROM ShopSchema.[Check] WHERE [Check].date = @date AND totalCost = @totalCost
    RETURN @res
  END
GO

CREATE FUNCTION ShopSchema.fn_search_cardID (@phone CHAR(11))
RETURNS INT
AS
  BEGIN
    DECLARE @res INT
    SELECT @res = cardID FROM ShopSchema.Card WHERE phone = @phone
    RETURN @res
  END
GO

CREATE TRIGGER ShopSchema.tr_insert_items_in_check
ON ShopSchema.[Items in check with price and discount]
INSTEAD OF INSERT
AS
  --нельзя вставлять чек (его части) в разных пакетах
  BEGIN
    IF (EXISTS(SELECT * FROM (SELECT
          checkID,
          totalCost,
          SUM(ShopSchema.fn_search_price(itemID, shopmanCode) * count * (100 - discount) / 100) AS sum
        FROM inserted
        GROUP BY checkID, totalCost) AS prices WHERE prices.totalCost != prices.sum))
      THROW 50000, 'TotalCost IN CHECK doesn''t equal to sum of items price', 1
    ELSE
      BEGIN
        INSERT INTO ShopSchema.[Check] (date, totalCost, typeOfPay, discount, shopmanCode)
          SELECT DISTINCT date, totalCost, typeOfPay, discount, shopmanCode FROM inserted

        INSERT INTO ShopSchema.Card (type, phone, firstName, lastName)
          SELECT DISTINCT type, phone, firstName, lastName FROM inserted WHERE phone NOT IN (SELECT phone FROM ShopSchema.Card)

        INSERT INTO ShopSchema.Card_Subtype (checkID, cardID)
          SELECT DISTINCT
            (SELECT checkID FROM ShopSchema.[Check] WHERE [Check].date = inserted.date AND [Check].totalCost = inserted.totalCost),
            (SELECT cardID FROM ShopSchema.Card WHERE Card.phone = inserted.phone)
          FROM inserted WHERE phone IS NOT NULL

        INSERT INTO ShopSchema.Event_Subtype (checkID, eventID)
          SELECT DISTINCT
            (SELECT checkID FROM ShopSchema.[Check] WHERE [Check].date = inserted.date AND [Check].totalCost = inserted.totalCost),
            inserted.eventID
          FROM inserted WHERE eventID IS NOT NULL

        INSERT INTO ShopSchema.Check_Item_INT (checkID, itemID, count)
          SELECT
            (SELECT checkID FROM ShopSchema.[Check] WHERE [Check].date = inserted.date AND [Check].totalCost = inserted.totalCost),
            inserted.itemID,
            inserted.count
          FROM inserted;

        WITH ITEM_CTE(itemID , shopmanCode, count)
        AS (
            SELECT itemID, shopmanCode, count FROM inserted
        )
        MERGE ShopSchema.Store USING ITEM_CTE
        ON Store.itemID = ITEM_CTE.itemID AND Store.shopCode = ShopSchema.search_shopCode_by_shopmanCode(ITEM_CTE.shopmanCode)
        WHEN MATCHED THEN UPDATE SET Store.rest = Store.rest - ITEM_CTE.count;
      END
  END
GO

INSERT INTO ShopSchema.[Items in check with price and discount] (shopmanCode, typeOfPay, discount, date, totalCost, itemID, count, price)
    VALUES (0, 0, 0, '2016-01-02', 13800, 0, 1, 6900), (0, 0, 0, '2016-01-02', 13800, 1, 1, 6900)

INSERT INTO ShopSchema.[Items in check with price and discount]
(shopmanCode, typeOfPay, discount, date, totalCost, type, phone, firstName, lastName, itemID, count, price)
    VALUES (0, 0, 10, '2016-01-04', 12420, 0, '89634456984', 'a', 'b', 0, 1, 6900),
      (0, 0, 10, '2016-01-04', 12420, 0, '89634456984', 'a', 'b', 1, 1, 6900)

CREATE TRIGGER ShopSchema.tr_delete_items_in_check
ON ShopSchema.[Items in check with price and discount]
INSTEAD OF DELETE
AS
  BEGIN
    DELETE FROM [Check] WHERE checkID IN (SELECT checkID FROM deleted)
  END
GO

DELETE FROM ShopSchema.[Items in check with price and discount] WHERE firstName = 'a'

CREATE TRIGGER ShopSchema.tr_update_items_in_check
ON ShopSchema.[Items in check with price and discount]
INSTEAD OF UPDATE
AS
  THROW 50000, 'Can''t be updated', 1
GO

CREATE VIEW ShopSchema.[Items in shop] WITH SCHEMABINDING
AS
SELECT itemName, description, country, rest, price, Store.shopCode FROM ShopSchema.Item
  JOIN ShopSchema.Store ON Item.itemID = Store.itemID
GO

CREATE TRIGGER ShopSchema.tr_update_shop
ON ShopSchema.Shop
INSTEAD OF UPDATE
AS
  THROW 50000, 'Table Shop can''t be updated', 1
GO

CREATE TRIGGER ShopSchema.tr_delete_store
ON ShopSchema.Store
AFTER DELETE
AS
  IF (EXISTS(SELECT * FROM deleted WHERE deleted.rest != 0))
      BEGIN
        RAISERROR ('Trying to delete not empty count of items', 10, 1)
        ROLLBACK
      END
  ELSE IF (EXISTS(SELECT * FROM deleted WHERE deleted.itemID IN (SELECT itemID FROM Item)))
      BEGIN
        RAISERROR ('Trying item in store, that exists', 10, 1)
        ROLLBACK
      END
GO

CREATE TRIGGER ShopSchema.tr_insert_items_in_shop
ON ShopSchema.[Items in shop]
INSTEAD OF INSERT
AS
  BEGIN
    INSERT INTO Item (itemName, description, country)
      SELECT DISTINCT inserted.itemName, inserted.description, inserted.country FROM inserted

    INSERT INTO Store (shopCode, itemID, rest, price)
      SELECT
        inserted.shopCode,
        (SELECT itemID FROM Item WHERE Item.itemName = inserted.itemName),
        inserted.rest,
        inserted.price
      FROM inserted
  END

INSERT INTO ShopSchema.[Items in shop] (itemName, description, country, rest, price, shopCode)
    VALUES ('a', 'b', 'c', 0, 10, 0)
GO

ALTER TABLE ShopSchema.Store ADD CONSTRAINT CK_REST CHECK (rest >= 0)
ALTER TABLE ShopSchema.Store ADD CONSTRAINT CK_PRICE CHECK (price > 0)
GO

CREATE TRIGGER ShopSchema.tr_delete_items_in_shop
ON ShopSchema.[Items in shop]
INSTEAD OF DELETE
AS
  MERGE ShopSchema.Store USING deleted ON deleted.shopCode = Store.shopCode AND
                                          (SELECT itemID FROM Item WHERE deleted.itemName = Item.itemName) = Store.itemID
  WHEN MATCHED THEN DELETE;
GO

DELETE FROM ShopSchema.[Items in shop] WHERE itemName = 'a'

CREATE TRIGGER ShopSchema.tr_update_items_in_shop
ON ShopSchema.[Items in shop]
INSTEAD OF UPDATE
AS
  BEGIN
    IF (UPDATE(itemName))
      THROW 50000, 'Trying to update itemName', 1
    ELSE UPDATE Item SET
      description = inserted.description,
      country = inserted.country
    FROM inserted
    WHERE Item.itemName = inserted.itemName

    UPDATE Store SET
      rest = inserted.rest,
      price = inserted.price
    FROM inserted
    WHERE Store.itemID = (SELECT itemID FROM Item WHERE inserted.itemName = Item.itemName) AND Store.shopCode = inserted.shopCode
  END
GO

UPDATE ShopSchema.[Items in shop]
    SET rest = rest + 1
WHERE itemName = '512 Slim Taper Fit Stretch Jeans'
