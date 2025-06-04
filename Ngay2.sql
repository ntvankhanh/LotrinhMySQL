CREATE DATABASE Ngay2SQL  
    DEFAULT CHARACTER SET = 'utf8mb4';

USE Ngay2SQL;

CREATE TABLE IF NOT EXISTS Users (
    user_id INT PRIMARY KEY,
    full_name VARCHAR(100),
    city VARCHAR(50),
    referrer_id INT,
    created_at DATE,
    FOREIGN KEY (referrer_id) REFERENCES Users(user_id)
);

CREATE TABLE IF NOT EXISTS Products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price INT,
    is_active BOOLEAN
);

CREATE TABLE IF NOT EXISTS Orders (
    order_id INT PRIMARY KEY,
    user_id INT,
    order_date DATE,
    status VARCHAR(20),
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE IF NOT EXISTS OrderItems (
    order_id INT,
    product_id INT,
    quantity INT,
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

INSERT INTO Users (user_id, full_name, city, referrer_id, created_at) VALUES
(1, 'Nguyen Van A', 'Hanoi', NULL, '2023-01-01'),
(2, 'Tran Thi B', 'HCM', 1, '2023-01-10'),
(3, 'Le Van C', 'Hanoi', 1, '2023-01-12'),
(4, 'Do Thi D', 'Da Nang', 2, '2023-02-05'),
(5, 'Hoang E', 'Can Tho', NULL, '2023-02-10');

INSERT INTO Products (product_id, product_name, category, price, is_active) VALUES
(1, 'iPhone 13', 'Electronics', 20000000, 1),
(2, 'MacBook Air', 'Electronics', 28000000, 1),
(3, 'Coffee Beans', 'Grocery', 250000, 1),
(4, 'Book: SQL Basics', 'Books', 150000, 1),
(5, 'Xbox Controller', 'Gaming', 1200000, 0);


INSERT INTO Orders (order_id, user_id, order_date, status) VALUES
(1001, 1, '2023-02-01', 'completed'),
(1002, 2, '2023-02-10', 'cancelled'),
(1003, 3, '2023-02-12', 'completed'),
(1004, 4, '2023-02-15', 'completed'),
(1005, 1, '2023-03-01', 'pending');


INSERT INTO OrderItems (order_id, product_id, quantity) VALUES
(1001, 1, 1),
(1001, 3, 3),
(1003, 2, 1),
(1003, 4, 2),
(1004, 3, 5),
(1005, 2, 1);

-- Các truy vấn thực hành nâng cao

-- 1. Tổng doanh thu từ các đơn hàng đã hoàn thành, nhóm theo danh mục sản phẩm
SELECT p.category AS Danh_mục_sản_phẩm,
       SUM(p.price * oi.quantity) AS Tổng_doanh_thu
FROM Orders o
JOIN OrderItems oi ON o.order_id = oi.order_id
JOIN Products p ON oi.product_id = p.product_id
WHERE o.status = 'completed'
GROUP BY p.category
ORDER BY Tổng_doanh_thu DESC;

-- 2. Danh sách người dùng kèm theo tên người giới thiệu (self join)
SELECT u.user_id AS Mã_người_dùng,
       u.full_name AS Tên_người_dùng,
       r.full_name AS Tên_người_giới_thiệu
FROM Users u
LEFT JOIN Users r ON u.referrer_id = r.user_id
ORDER BY u.user_id;

-- 3. Sản phẩm không còn bán nhưng đã từng được đặt mua
SELECT DISTINCT p.product_id AS Mã_sản_phẩm,
                p.product_name AS Tên_sản_phẩm,
                p.category AS Danh_mục,
                p.price AS Giá
FROM Products p
JOIN OrderItems oi ON p.product_id = oi.product_id
WHERE p.is_active = 0;

-- 4. Người dùng chưa từng đặt đơn hàng nào
SELECT u.user_id AS Mã_người_dùng,
       u.full_name AS Tên_người_dùng,
       u.city AS Thành_phố,
       u.created_at AS Ngày_tạo
FROM Users u
LEFT JOIN Orders o ON u.user_id = o.user_id
WHERE o.order_id IS NULL;

-- 5. Đơn hàng đầu tiên của từng người dùng
SELECT user_id AS Mã_người_dùng,
       MIN(order_id) AS Đơn_hàng_đầu_tiên
FROM Orders
GROUP BY user_id;

-- 6. Tổng chi tiêu của mỗi người dùng (chỉ tính đơn hàng đã hoàn thành)
SELECT u.user_id AS Mã_người_dùng,
       u.full_name AS Tên_người_dùng,
       COALESCE(SUM(p.price * oi.quantity), 0) AS Tổng_chi_tiêu
FROM Users u
LEFT JOIN Orders o ON u.user_id = o.user_id AND o.status = 'completed'
LEFT JOIN OrderItems oi ON o.order_id = oi.order_id
LEFT JOIN Products p ON oi.product_id = p.product_id
GROUP BY u.user_id, u.full_name
ORDER BY Tổng_chi_tiêu DESC;

-- 7. Lọc người dùng có tổng chi tiêu > 25 triệu
SELECT user_id AS Mã_người_dùng,
       full_name AS Tên_người_dùng,
       Tổng_chi_tiêu
FROM (
    SELECT u.user_id,
           u.full_name,
           COALESCE(SUM(p.price * oi.quantity), 0) AS Tổng_chi_tiêu
    FROM Users u
    LEFT JOIN Orders o ON u.user_id = o.user_id AND o.status = 'completed'
    LEFT JOIN OrderItems oi ON o.order_id = oi.order_id
    LEFT JOIN Products p ON oi.product_id = p.product_id
    GROUP BY u.user_id, u.full_name
) AS spending
WHERE Tổng_chi_tiêu > 25000000
ORDER BY Tổng_chi_tiêu DESC;

-- 8. So sánh tổng số đơn hàng và tổng doanh thu theo thành phố
SELECT u.city AS Thành_phố,
       COUNT(DISTINCT o.order_id) AS Tổng_số_đơn_hàng,
       COALESCE(SUM(p.price * oi.quantity), 0) AS Tổng_doanh_thu
FROM Users u
LEFT JOIN Orders o ON u.user_id = o.user_id AND o.status = 'completed'
LEFT JOIN OrderItems oi ON o.order_id = oi.order_id
LEFT JOIN Products p ON oi.product_id = p.product_id
GROUP BY u.city
ORDER BY Tổng_doanh_thu DESC;

-- 9. Người dùng có ít nhất 2 đơn hàng đã hoàn thành
SELECT u.user_id AS Mã_người_dùng,
       u.full_name AS Tên_người_dùng,
       COUNT(o.order_id) AS Số_đơn_hàng_hoàn_thành
FROM Users u
JOIN Orders o ON u.user_id = o.user_id AND o.status = 'completed'
GROUP BY u.user_id, u.full_name
HAVING COUNT(o.order_id) >= 2
ORDER BY Số_đơn_hàng_hoàn_thành DESC;

-- 10. Đơn hàng có sản phẩm thuộc nhiều hơn 1 danh mục
SELECT o.order_id AS Mã_đơn_hàng,
       COUNT(DISTINCT p.category) AS Số_danh_mục
FROM Orders o
JOIN OrderItems oi ON o.order_id = oi.order_id
JOIN Products p ON oi.product_id = p.product_id
GROUP BY o.order_id
HAVING COUNT(DISTINCT p.category) > 1;

-- 11. Kết hợp danh sách người dùng đã từng đặt hàng và người dùng được người khác giới thiệu
SELECT DISTINCT u.user_id AS Mã_người_dùng,
                u.full_name AS Tên_người_dùng,
                'placed_order' AS Nguồn_đến
FROM Users u
JOIN Orders o ON u.user_id = o.user_id

UNION

SELECT DISTINCT u.user_id AS Mã_người_dùng,
                u.full_name AS Tên_người_dùng,
                'referred' AS Nguồn_đến
FROM Users u
WHERE u.referrer_id IS NOT NULL

ORDER BY Mã_người_dùng;
