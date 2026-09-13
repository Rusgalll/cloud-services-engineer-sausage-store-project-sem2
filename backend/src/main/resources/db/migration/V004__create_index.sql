-- V004__create_index.sql

--Создание индекса для поля order_id, по которому происходит объединение таблицы order_product с таблицей orders
CREATE INDEX order_product_order_id_idx ON order_product(order_id);

-- Создание композитного индекса для полей status и date_created
CREATE INDEX orders_status_date_idx ON orders(status, date_created); 