-- ============================================================
-- Шаг 4. Проверка, что данные не потерялись и не исказились
-- ============================================================

USE orders_norm;

-- ------------------------------------------------------------
-- Проверка 1. Сравнение общей суммы SUM(price * quantity)
-- до нормализации (плохая таблица) и после (соединение таблиц)
-- ------------------------------------------------------------
SELECT 'до нормализации (плохая таблица)' AS source,
       SUM(price * quantity) AS total_sum,
       COUNT(*)              AS rows_cnt
FROM orders_bad
UNION ALL
SELECT 'после нормализации (3NF)',
       SUM(p.price * i.quantity),
       COUNT(*)
FROM order_items i
JOIN products p ON p.product_id = i.product_id;

-- ------------------------------------------------------------
-- Проверка 2. Число уникальных заказов / товаров / представителей
-- ------------------------------------------------------------
SELECT 'orders'          AS what, COUNT(DISTINCT order_id) AS cnt FROM orders_bad WHERE order_id IS NOT NULL
UNION ALL SELECT 'orders (3NF)',          COUNT(*) FROM orders
UNION ALL SELECT 'products',              COUNT(DISTINCT product_id) FROM orders_bad WHERE product_id IS NOT NULL
UNION ALL SELECT 'products (3NF)',        COUNT(*) FROM products
UNION ALL SELECT 'representatives',       COUNT(DISTINCT rep_id) FROM orders_bad WHERE rep_id IS NOT NULL
UNION ALL SELECT 'representatives (3NF)', COUNT(*) FROM representatives
UNION ALL SELECT 'items rows',            COUNT(*) FROM orders_bad WHERE order_id IS NOT NULL AND product_id IS NOT NULL
UNION ALL SELECT 'items rows (3NF)',      COUNT(*) FROM order_items;

-- ------------------------------------------------------------
-- Проверка 3. Потери и лишние записи (сравнение ключей)
-- ------------------------------------------------------------
SELECT
  (SELECT COUNT(*) FROM
     (SELECT order_id, product_id FROM orders_bad
      WHERE order_id IS NOT NULL AND product_id IS NOT NULL) b
     LEFT JOIN order_items i
       ON i.order_id = b.order_id AND i.product_id = b.product_id
     WHERE i.order_id IS NULL) AS missing_from_3nf,
  (SELECT COUNT(*) FROM order_items i
     LEFT JOIN
     (SELECT order_id, product_id FROM orders_bad
      WHERE order_id IS NOT NULL AND product_id IS NOT NULL) b
       ON i.order_id = b.order_id AND i.product_id = b.product_id
     WHERE b.order_id IS NULL) AS extra_in_3nf;

-- ------------------------------------------------------------
-- Проверка 4. Полное «собранное» представление (JOIN четырёх таблиц)
-- ------------------------------------------------------------
SELECT o.order_id,
       o.order_date,
       o.customer_id,
       r.rep_id,
       r.rep_name,
       p.product_id,
       p.product_name,
       p.price,
       i.quantity
FROM orders o
JOIN representatives r ON r.rep_id     = o.rep_id
JOIN order_items i     ON i.order_id   = o.order_id
JOIN products p        ON p.product_id = i.product_id
ORDER BY o.order_id, p.product_id;

-- ------------------------------------------------------------
-- Тестовые запросы на новой схеме
-- ------------------------------------------------------------

-- 1. Один код заказа = один представитель (дублей в шапках нет)
SELECT o.order_id, r.rep_name
FROM orders o
JOIN representatives r ON r.rep_id = o.rep_id
ORDER BY o.order_id;

-- 2. Кто и сколько заказов вёл
SELECT r.rep_name,
       COUNT(*) AS orders_cnt
FROM orders o
JOIN representatives r ON r.rep_id = o.rep_id
GROUP BY r.rep_id, r.rep_name
ORDER BY orders_cnt DESC;

-- 3. Сумма каждого заказа
SELECT o.order_id,
       SUM(p.price * i.quantity) AS order_total
FROM orders o
JOIN order_items i  ON i.order_id   = o.order_id
JOIN products p     ON p.product_id = i.product_id
GROUP BY o.order_id
ORDER BY o.order_id;

-- 4. Какой представитель продал больше всех (по сумме)
SELECT r.rep_name,
       SUM(p.price * i.quantity) AS total_sales
FROM representatives r
JOIN orders o        ON o.rep_id     = r.rep_id
JOIN order_items i   ON i.order_id   = o.order_id
JOIN products p      ON p.product_id = i.product_id
GROUP BY r.rep_id, r.rep_name
ORDER BY total_sales DESC
LIMIT 1;

-- ------------------------------------------------------------
-- Шаг 5 (после успешной проверки). Переименуем исходную таблицу
-- (не удаляем — на случай повторной проверки преподавателем)
-- ------------------------------------------------------------
RENAME TABLE orders_bad TO orders_bad_archive;

SHOW TABLES;
