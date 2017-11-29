--«грязное» чтение(dirty read) – чтение транзакцией записи, измененной другой транзакцией,
    --при этом эти изменения еще не зафиксированы;

--–невоспроизводимое чтение(non-repeatable read) – при повторном чтении транзакция обнаруживает
    --измененные или удаленные данные, зафиксированные другой завершенной транзакцией; (update/delete)

--–фантомное чтение(phantom read) – при повторном чтении транзакция обнаруживает новые строки,
    --вставленные другой завершенной транзакцией; (insert)
DISABLE TRIGGER ShopSchema.card_delete ON ShopSchema.Card
DISABLE TRIGGER ShopSchema.card_insert ON ShopSchema.Card
DISABLE TRIGGER ShopSchema.card_update ON ShopSchema.Card
GO

--============================================================
--READ UNCOMMITED
--читатели могут считывать данные незваршенной транзакции
--процесса-писателя
--возможны все три вида проблем
--============================================================

BEGIN TRANSACTION
    SELECT * FROM ShopSchema.Card WHERE cardID = 0
    UPDATE ShopSchema.Card
        SET phone = '89269413358'
        WHERE cardID = 0
    WAITFOR DELAY '00:00:07'
    ROLLBACK
    SELECT * FROM ShopSchema.Card WHERE cardID = 0

--============================================================
--READ COMMITED
--Подтвержденное чтение
--читатели не могут считывать данные незавершенной транзакции,
--но писатели могут изменять уже прочитанные данные.
--Если таблица захвачена, то прочитать данные
--можно только полсле коммита
-->предотвращает грязное чтение
--============================================================

BEGIN TRANSACTION
    SELECT * FROM ShopSchema.Card WHERE cardID = 0
    UPDATE ShopSchema.Card
        SET phone = '89819413759'
        WHERE cardID = 0
    WAITFOR DELAY '00:00:07'
    ROLLBACK
SELECT * FROM ShopSchema.Card WHERE cardID = 0

--============================================================
--REPEATABLE READ
--Повторяемое чтение
--повторное чтение данных вернет те же значения,
--что были и в начале транзакции.
--При этом писатели могут вставлять новые записи,
--имеющие статус фантома при незавершенной транзакции.
-->предотвращает невоспроизводимое чтение и "грязное" чтение
--============================================================

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
BEGIN TRANSACTION
    SELECT * FROM ShopSchema.Card WHERE cardID = 0
    WAITFOR DELAY '00:00:05'
    SELECT * FROM ShopSchema.Card WHERE cardID = 0
    COMMIT
SELECT * FROM ShopSchema.Card WHERE cardID = 0
--============================================================
--SERIALIZABLE
--Сериализуемость
--максимальный уровень изоляции,
--гарантирует неизменяемость данных другими процессами
--до завершения транзакции.
-->предотвращает все виды проблем
--============================================================

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
BEGIN TRANSACTION
    SELECT * FROM ShopSchema.Card WHERE cardID > 2776
    WAITFOR DELAY '00:00:05'
    SELECT * FROM ShopSchema.Card WHERE cardID > 2776
    COMMIT
SELECT * FROM ShopSchema.Card WHERE cardID > 2776

ENABLE TRIGGER ShopSchema.card_delete ON ShopSchema.Card
ENABLE TRIGGER ShopSchema.card_insert ON ShopSchema.Card
ENABLE TRIGGER ShopSchema.card_update ON ShopSchema.Card
GO
