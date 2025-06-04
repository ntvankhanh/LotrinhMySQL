
USE Ngay1SQL;

CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100),
    city VARCHAR(50),
    email VARCHAR(100)
);


CREATE TABLE Orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    total_amount INT,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);


CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    name VARCHAR(100),
    price INT
);

INSERT IGNORE INTO Customers (customer_id, name, city, email) VALUES
    (1, 'Nguyen An', 'Hanoi', 'an.nguyen@email.com'),
    (2, 'Tran Binh', 'Ho Chi Minh', NULL),
    (3, 'Le Cuong', 'Da Nang', 'cuong.le@email.com'),
    (4, 'Hoang Duong', 'Hanoi', 'duong.hoang@email.com');

INSERT IGNORE INTO Orders (order_id, customer_id, order_date, total_amount) VALUES
    (101, 1, '2023-01-15', 500000),
    (102, 3, '2023-02-10', 800000),
    (103, 2, '2023-03-05', 300000),
    (104, 1, '2023-04-01', 450000);

INSERT IGNORE INTO Products (product_id, name, price) VALUES
    (1, 'Laptop Dell', 15000000),
    (2, 'Mouse Logitech', 300000),
    (3, 'Keyboard Razer', 1200000),
    (4, 'Laptop HP', 14000000);

-- ============================================
-- Practice Queries
-- ============================================

-- 1. Lấy danh sách khách hàng đến từ Hà Nội
SELECT *FROM Customers
WHERE city = 'Hanoi';

-- 2. Tìm các đơn hàng có giá trị trên 400.000 đồng và được đặt sau ngày 31/01/2023
SELECT *
FROM Orders
WHERE total_amount > 400000
  AND order_date > '2023-01-31';

-- 3. Lọc ra các khách hàng chưa có địa chỉ email
SELECT *
FROM Customers
WHERE email IS NULL;

-- 4. Xem toàn bộ đơn hàng, sắp xếp theo tổng tiền từ cao xuống thấp
SELECT *
FROM Orders
ORDER BY total_amount DESC;

-- 5. Thêm khách hàng mới tên "Pham Thanh", sống tại Cần Thơ, email để trống
-- Lưu ý: Nếu customer_id là AUTO_INCREMENT, không cần chèn giá trị customer_id
INSERT INTO Customers (name, city, email)
VALUES ('Pham Thanh', 'Can Tho', NULL);

-- 6. Cập nhật địa chỉ email của khách hàng có mã là 2 thành “binh.tran@email.com”
UPDATE Customers
SET email = 'binh.tran@email.com'
WHERE customer_id = 2;

-- 7. Xóa đơn hàng có mã là 103 vì bị nhập nhầm
DELETE FROM Orders
WHERE order_id = 103;

-- 8. Lấy danh sách 2 khách hàng đầu tiên trong bảng (theo customer_id)
SELECT *
FROM Customers
ORDER BY customer_id
LIMIT 2;

-- 9. Đơn hàng có giá trị lớn nhất và nhỏ nhất hiện tại là bao nhiêu
SELECT MAX(total_amount) AS max_order_value,
       MIN(total_amount) AS min_order_value
FROM Orders;

-- 10. Tính tổng số lượng đơn hàng, tổng số tiền đã bán ra và trung bình giá trị một đơn hàng
SELECT COUNT(*) AS total_orders,
       SUM(total_amount) AS total_sales,
       AVG(total_amount) AS average_order_value
FROM Orders;

-- 11. Tìm những sản phẩm có tên bắt đầu bằng chữ “Laptop”
SELECT *
FROM Products
WHERE name LIKE 'Laptop%';

-- ============================================
-- Mô tả ngắn gọn về RDBMS và vai trò của các mối quan hệ giữa các bảng:
-- ============================================
-- Hệ quản trị cơ sở dữ liệu quan hệ (RDBMS) là phần mềm quản lý dữ liệu được lưu trữ trong các bảng (quan hệ) gồm các hàng và cột.
-- Nó cho phép định nghĩa các mối quan hệ giữa các bảng thông qua các khóa chính (primary key) và khóa ngoại (foreign key),
-- giúp duy trì tính toàn vẹn dữ liệu và cho phép truy vấn phức tạp.
-- Trong hệ thống này, các mối quan hệ giữa bảng Khách hàng, Đơn hàng và Sản phẩm cho phép liên kết thông tin khách hàng với các đơn hàng và sản phẩm họ đã mua,
-- giúp việc truy xuất và quản lý dữ liệu hiệu quả hơn.

