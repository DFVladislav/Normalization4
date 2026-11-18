-- ============================================================
-- Шаг 3. Нормализация до 3NF: создание 4 таблиц
--   representatives — справочник представителей (rep_id → rep_name)
--   products        — справочник товаров      (product_id → product_name, price)
--   orders          — шапки заказов           (order_id → order_date, customer_id,
--                     rep_id; один заказ ведёт ровно один представитель)
--   order_items     — позиции заказов         ((order_id, product_id) → quantity)
-- ============================================================

USE orders_norm;

-- Справочник представителей (PK: rep_id)
CREATE TABLE representatives (
    rep_id   INT          NOT NULL,
    rep_name VARCHAR(100) NOT NULL,
    PRIMARY KEY (rep_id)
);

-- Справочник товаров (PK: product_id)
CREATE TABLE products (
    product_id   INT           NOT NULL,
    product_name VARCHAR(100)  NOT NULL,
    price        DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (product_id)
);

-- Шапки заказов (PK: order_id; FK: rep_id -> representatives)
-- Код клиента хранится прямо в шапке: имя клиента в исходной таблице
-- отсутствует, поэтому отдельный справочник клиентов не нужен.
-- rep_id — одиночный атрибут заказа: один заказ = один представитель.
CREATE TABLE orders (
    order_id    INT  NOT NULL,
    order_date  DATE NOT NULL,
    customer_id INT  NOT NULL,
    rep_id      INT  NOT NULL,
    PRIMARY KEY (order_id),
    FOREIGN KEY (rep_id) REFERENCES representatives (rep_id)
);

-- Позиции заказов (PK составной: (order_id, product_id))
CREATE TABLE order_items (
    order_id   INT NOT NULL,
    product_id INT NOT NULL,
    quantity   INT NOT NULL,
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id)   REFERENCES orders    (order_id),
    FOREIGN KEY (product_id) REFERENCES products (product_id)
);

-- ------------------------------------------------------------
-- Перенос данных из «плохой» таблицы (INSERT ... SELECT)
-- ------------------------------------------------------------

-- 1. Уникальные представители -> representatives
INSERT INTO representatives (rep_id, rep_name)
SELECT DISTINCT rep_id, rep_name
FROM orders_bad
WHERE rep_id IS NOT NULL;

-- 2. Уникальные товары -> products
INSERT INTO products (product_id, product_name, price)
SELECT DISTINCT product_id, product_name, price
FROM orders_bad
WHERE product_id IS NOT NULL;

-- 3. Уникальные шапки заказов -> orders
INSERT INTO orders (order_id, order_date, customer_id, rep_id)
SELECT DISTINCT order_id, order_date, customer_id, rep_id
FROM orders_bad
WHERE order_id IS NOT NULL;

-- 4. Позиции заказов -> order_items
INSERT INTO order_items (order_id, product_id, quantity)
SELECT order_id, product_id, quantity
FROM orders_bad
WHERE order_id IS NOT NULL AND product_id IS NOT NULL;

-- Что получилось
SELECT 'representatives' AS table_name, COUNT(*) AS rows_cnt FROM representatives
UNION ALL SELECT 'products',    COUNT(*) FROM products
UNION ALL SELECT 'orders',      COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items;
