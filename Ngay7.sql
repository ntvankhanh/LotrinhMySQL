CREATE DATABASE Ngay7SQL  
    DEFAULT CHARACTER SET = 'utf8mb4';
USE Ngay7SQL;
-- 1. Tạo bảng
drop database Ngay7SQL  ;


-- Giải pháp tối ưu hóa truy vấn cho Hệ thống Thương Mại Điện Tử

-- Tạo bảng Categories
CREATE TABLE IF NOT EXISTS Categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

-- Tạo bảng Products
CREATE TABLE IF NOT EXISTS Products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category_id INT,
    price DECIMAL(15,2) NOT NULL,
    stock_quantity INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES Categories(category_id)
);

-- Tạo bảng Orders
CREATE TABLE IF NOT EXISTS Orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL
);

-- Tạo bảng OrderItems
CREATE TABLE IF NOT EXISTS OrderItems (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT NOT NULL,
    unit_price DECIMAL(15,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- Dữ liệu mẫu cho bảng Categories
INSERT INTO Categories (category_id, name) VALUES
(1, 'Electronics'),
(2, 'Books'),
(3, 'Clothing');

-- Dữ liệu mẫu cho bảng Products
INSERT INTO Products (product_id, name, category_id, price, stock_quantity, created_at) VALUES
(1, 'Smartphone', 1, 12000000, 50, '2024-05-20 10:00:00'),
(2, 'Laptop', 1, 25000000, 30, '2024-05-25 09:30:00'),
(3, 'Novel', 2, 150000, 100, '2024-06-01 14:00:00'),
(4, 'T-shirt', 3, 200000, 200, '2024-06-02 08:00:00'),
(5, 'Headphones', 1, 2000000, 80, '2024-06-03 11:00:00');

-- Dữ liệu mẫu cho bảng Orders
INSERT INTO Orders (order_id, user_id, order_date, status) VALUES
(1, 101, '2024-06-01 12:00:00', 'Shipped'),
(2, 102, '2024-06-02 15:30:00', 'Pending'),
(3, 103, '2024-06-03 16:45:00', 'Shipped'),
(4, 104, '2024-06-04 09:20:00', 'Cancelled');

-- Dữ liệu mẫu cho bảng OrderItems
INSERT INTO OrderItems (order_item_id, order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 1, 12000000),
(2, 1, 5, 2, 2000000),
(3, 2, 3, 3, 150000),
(4, 3, 2, 1, 25000000),
(5, 3, 4, 2, 200000),
(6, 4, 1, 1, 12000000);




-- 1. Phân tích truy vấn bằng EXPLAIN và đề xuất cải tiến
EXPLAIN
SELECT * FROM Orders
JOIN OrderItems ON Orders.order_id = OrderItems.order_id
WHERE status = 'Shipped'
ORDER BY order_date DESC;

-- Đề xuất:
-- - Tạo chỉ mục trên cột status và order_date của bảng Orders để tăng tốc lọc và sắp xếp
-- - Tạo composite index trên OrderItems (order_id, product_id) để hỗ trợ JOIN hiệu quả
-- - Tránh dùng SELECT * thay bằng chỉ chọn các cột cần thiết

-- 2. Tạo chỉ mục phù hợp
CREATE INDEX idx_orders_status_orderdate ON Orders(status, order_date);
CREATE INDEX idx_orderitems_orderid_productid ON OrderItems(order_id, product_id);

-- 3. Sửa truy vấn chỉ chọn cột cần thiết
SELECT Orders.order_id, Orders.user_id, Orders.order_date, Orders.status,
       OrderItems.order_item_id, OrderItems.product_id, OrderItems.quantity, OrderItems.unit_price
FROM Orders
JOIN OrderItems ON Orders.order_id = OrderItems.order_id
WHERE Orders.status = 'Shipped'
ORDER BY Orders.order_date DESC;

-- 4. So sánh hiệu suất giữa JOIN và Subquery

-- Truy vấn 1: JOIN giữa Products và Categories
SELECT p.product_id, p.name, c.name AS category_name, p.price
FROM Products p
JOIN Categories c ON p.category_id = c.category_id;

-- Truy vấn 2: Subquery lấy tên category từ Products
SELECT p.product_id, p.name,
       (SELECT name FROM Categories WHERE category_id = p.category_id) AS category_name,
       p.price
FROM Products p;

-- 5. Lấy 10 sản phẩm mới nhất trong danh mục "Electronics" có stock_quantity > 0
SELECT p.product_id, p.name, p.price, p.stock_quantity, p.created_at
FROM Products p
JOIN Categories c ON p.category_id = c.category_id
WHERE c.name = 'Electronics' AND p.stock_quantity > 0
ORDER BY p.created_at DESC
LIMIT 10;

-- 6. Tạo Covering Index cho truy vấn thường xuyên
CREATE INDEX idx_products_category_price ON Products(category_id, price, product_id, name);

-- 7. Tối ưu truy vấn tính doanh thu theo tháng

-- Truy vấn gốc (có thể dùng hàm trong WHERE, không tối ưu)
-- SELECT DATE_FORMAT(order_date, '%Y-%m') AS month, SUM(quantity * unit_price) AS revenue
-- FROM Orders o
-- JOIN OrderItems oi ON o.order_id = oi.order_id
-- WHERE DATE_FORMAT(order_date, '%Y-%m') = '2024-06'
-- GROUP BY month;

-- Truy vấn tối ưu tránh dùng hàm trong WHERE, dùng điều kiện thời gian chuẩn
SELECT DATE_FORMAT(o.order_date, '%Y-%m') AS month, SUM(oi.quantity * oi.unit_price) AS revenue
FROM Orders o
JOIN OrderItems oi ON o.order_id = oi.order_id
WHERE o.order_date >= '2024-06-01 00:00:00' AND o.order_date < '2024-07-01 00:00:00'
GROUP BY month;

-- 8. Tách truy vấn lớn thành nhiều bước nhỏ

-- Bước 1: Lọc đơn hàng có nhiều sản phẩm đắt tiền (>1,000,000)
CREATE TEMPORARY TABLE ExpensiveOrders AS
SELECT DISTINCT o.order_id
FROM Orders o
JOIN OrderItems oi ON o.order_id = oi.order_id
WHERE oi.unit_price > 1000000;

-- Bước 2: Tính tổng số lượng bán ra của các đơn hàng trên
SELECT SUM(oi.quantity) AS total_quantity
FROM OrderItems oi
JOIN ExpensiveOrders eo ON oi.order_id = eo.order_id;

-- 9. Liệt kê top 5 sản phẩm bán chạy nhất trong 30 ngày gần nhất
SELECT p.product_id, p.name, SUM(oi.quantity) AS total_sold
FROM OrderItems oi
JOIN Products p ON oi.product_id = p.product_id
JOIN Orders o ON oi.order_id = o.order_id
WHERE o.order_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY p.product_id, p.name
ORDER BY total_sold DESC
LIMIT 5;

