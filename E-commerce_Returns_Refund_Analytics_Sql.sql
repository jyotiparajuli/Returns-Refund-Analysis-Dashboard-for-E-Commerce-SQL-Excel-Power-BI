
-- Create Tables:-
-- Customers
CREATE TABLE customers (
    customer_id VARCHAR(20) PRIMARY KEY,
    customer_name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    city VARCHAR(50),
    state VARCHAR(50),
    signup_date VARCHAR(20)
);

-- Sellers
CREATE TABLE sellers (
    seller_id VARCHAR(20) PRIMARY KEY,
    seller_name VARCHAR(100),
    seller_city VARCHAR(50),
    seller_state VARCHAR(50),
    signup_date VARCHAR(20),
    rating DECIMAL(3,2)
);

-- Products
CREATE TABLE products (
    product_id VARCHAR(20) PRIMARY KEY,
    product_name VARCHAR(150),
    category VARCHAR(100),
    price DECIMAL(10,2),
    weight_kg DECIMAL(10,2),
    seller_id VARCHAR(20),
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
);

-- Orders
CREATE TABLE orders (
    order_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20),
    order_date VARCHAR(20),
    order_status VARCHAR(50),
    return_flag VARCHAR(10),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Order Items
CREATE TABLE order_items (
    order_item_id VARCHAR(20) PRIMARY KEY,
    order_id VARCHAR(20),
    product_id VARCHAR(20),
    quantity INT,
    unit_price DECIMAL(10,2),
    return_reason VARCHAR(255),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Payments
CREATE TABLE payments (
    payment_id VARCHAR(20) PRIMARY KEY,
    order_id VARCHAR(20),
    payment_type VARCHAR(50),
    payment_value DECIMAL(10,2),
    payment_date VARCHAR(20),
    payment_status VARCHAR(50),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- Reviews
CREATE TABLE reviews (
    review_id VARCHAR(20) PRIMARY KEY,
    order_id VARCHAR(20),
    customer_id VARCHAR(20),
    rating INT,
    review_text TEXT,
    review_date VARCHAR(20),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);


-- 1. Products with highest return rate
WITH product_orders AS (
    SELECT 
        oi.product_id,
        p.product_name,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        COUNT(DISTINCT CASE WHEN LOWER(o.return_flag) = 'yes' THEN o.order_id END) AS returned_orders
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY oi.product_id, p.product_name
)
SELECT 
    product_id,
    product_name,
    total_orders,
    returned_orders,
    ROUND(returned_orders * 100.0 / NULLIF(total_orders, 0), 2) AS return_rate
FROM product_orders
ORDER BY return_rate DESC;


-- 2. Categories causing most refund losses
SELECT 
    p.category,
    SUM(oi.quantity * oi.unit_price) AS total_loss
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE LOWER(o.return_flag) = 'yes'
GROUP BY p.category
ORDER BY total_loss DESC;


-- 3. Sellers generating most returns
SELECT 
    s.seller_id,
    s.seller_name,
    COUNT(DISTINCT o.order_id) AS returned_orders
FROM sellers s
JOIN products p ON s.seller_id = p.seller_id
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE LOWER(o.return_flag) = 'yes'
GROUP BY s.seller_id, s.seller_name
ORDER BY returned_orders DESC;


-- 4. States with highest return rates
SELECT 
    c.state,
    COUNT(o.order_id) AS total_orders,
    COUNT(CASE WHEN LOWER(o.return_flag) = 'yes' THEN 1 END) AS returned_orders,
    ROUND(
        COUNT(CASE WHEN LOWER(o.return_flag) = 'yes' THEN 1 END) * 100.0 / COUNT(o.order_id),
        2
    ) AS return_rate
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.state
ORDER BY return_rate DESC;


-- 5. Total refund amount
SELECT 
    SUM(payment_value) AS total_refund_amount
FROM payments
WHERE LOWER(payment_status) = 'refunded';


-- 6. Payment methods with most refunds
SELECT 
    payment_type,
    COUNT(*) AS refund_count,
    SUM(payment_value) AS total_refunded
FROM payments
WHERE LOWER(payment_status) = 'refunded'
GROUP BY payment_type
ORDER BY refund_count DESC;


-- 7. Top return reasons
SELECT 
    return_reason,
    COUNT(*) AS total_returns
FROM order_items
WHERE return_reason IS NOT NULL
GROUP BY return_reason
ORDER BY total_returns DESC;


-- 8. Product Categories causing most returns
SELECT 
    p.category,
    COUNT(*) AS total_returns
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE LOWER(o.return_flag) = 'yes'
GROUP BY p.category
ORDER BY total_returns DESC;

-- 9. Customers returning most frequently
SELECT 
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id) AS total_returns
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE LOWER(o.return_flag) = 'yes'
GROUP BY c.customer_id, c.customer_name
ORDER BY total_returns DESC;


-- 10. High revenue but high return products
SELECT 
    p.product_id,
    p.product_name,
    SUM(oi.quantity * oi.unit_price) AS revenue,
    SUM(CASE WHEN LOWER(o.return_flag) = 'yes' 
             THEN oi.quantity * oi.unit_price 
             ELSE 0 END) AS return_loss
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
GROUP BY p.product_id, p.product_name
HAVING SUM(oi.quantity * oi.unit_price) > 0
ORDER BY return_loss DESC, revenue DESC;


-- 11. VIEW for dashboard
CREATE OR REPLACE VIEW return_dashboard AS
SELECT 
    o.order_id,
    c.customer_name,
    p.product_name,
    p.category,
    o.order_date,
    o.return_flag,
    oi.return_reason,
    pay.payment_value,
    pay.payment_type
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = o.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN payments pay ON o.order_id = pay.order_id;

Select * from return_dashboard;