-- V002__change_schema.sql

-- Добавление нужных полей
ALTER TABLE product
    ADD COLUMN price DOUBLE PRECISION NOT NULL CHECK (price > 0),
    ADD CONSTRAINT product_pkey PRIMARY KEY (id);

ALTER TABLE orders
    ADD COLUMN date_created DATE NOT NULL,
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);

-- Добавлние связей между таблицами
ALTER TABLE order_product
    ADD CONSTRAINT fk_order
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_product
        FOREIGN KEY (product_id) REFERENCES product(id) ON DELETE CASCADE;

-- Удаление ненужных таблиц
DROP TABLE IF EXISTS product_info;
DROP TABLE IF EXISTS orders_date;