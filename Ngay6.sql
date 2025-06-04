-- Kịch bản SQL Hệ thống Ngân hàng Số
CREATE DATABASE Ngay6SQL  
    DEFAULT CHARACTER SET = 'utf8mb4';
USE Ngay6SQL;
-- 1. Tạo bảng
drop database Ngay6SQL  ;
-- Bảng Accounts sử dụng InnoDB để hỗ trợ giao dịch và khóa ngoại
CREATE TABLE IF NOT EXISTS Accounts (
    account_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    balance DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    status VARCHAR(20) NOT NULL CHECK (status IN ('Active', 'Frozen', 'Closed'))
) ENGINE=InnoDB;

-- Bảng Transactions sử dụng InnoDB để hỗ trợ giao dịch và khóa ngoại
CREATE TABLE IF NOT EXISTS Transactions (
    txn_id INT AUTO_INCREMENT PRIMARY KEY,
    from_account INT NOT NULL,
    to_account INT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    txn_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL CHECK (status IN ('Success', 'Failed', 'Pending')),
    FOREIGN KEY (from_account) REFERENCES Accounts(account_id),
    FOREIGN KEY (to_account) REFERENCES Accounts(account_id)
) ENGINE=InnoDB;

-- Bảng TxnAuditLogs sử dụng MyISAM để ghi nhật ký audit nhanh, không hỗ trợ giao dịch
CREATE TABLE IF NOT EXISTS TxnAuditLogs (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    txn_id INT NOT NULL,
    log_message VARCHAR(255) NOT NULL,
    log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=MyISAM;

-- Bảng Referrals dùng cho truy vấn CTE đệ quy
CREATE TABLE IF NOT EXISTS Referrals (
    referrer_id INT NOT NULL,
    referee_id INT NOT NULL,
    PRIMARY KEY (referrer_id, referee_id),
    FOREIGN KEY (referrer_id) REFERENCES Accounts(account_id),
    FOREIGN KEY (referee_id) REFERENCES Accounts(account_id)
) ENGINE=InnoDB;

-- 2. Giải thích về các engine lưu trữ (dưới dạng comment)
-- InnoDB: Hỗ trợ giao dịch, khóa ngoại, khóa ở mức dòng, và MVCC để kiểm soát đồng thời.
-- MyISAM: Không hỗ trợ giao dịch hay khóa ngoại, sử dụng khóa ở mức bảng, nhanh hơn cho các tác vụ đọc nhiều.
-- MEMORY: Lưu dữ liệu trong RAM để truy cập rất nhanh, nhưng dữ liệu mất khi khởi động lại server, không hỗ trợ giao dịch.

-- 3. Thủ tục lưu trữ TransferMoney
DELIMITER //
CREATE PROCEDURE TransferMoney(
    IN p_from_account INT,
    IN p_to_account INT,
    IN p_amount DECIMAL(15,2)
)
BEGIN
    DECLARE v_from_status VARCHAR(20);
    DECLARE v_to_status VARCHAR(20);
    DECLARE v_from_balance DECIMAL(15,2);
    DECLARE exit handler for sqlexception
    BEGIN
        -- Rollback khi có lỗi
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Giao dịch thất bại và đã rollback';
    END;

    START TRANSACTION;

    -- Khóa hai tài khoản theo thứ tự nhất quán để tránh deadlock
    IF p_from_account < p_to_account THEN
        SELECT status, balance INTO v_from_status, v_from_balance FROM Accounts WHERE account_id = p_from_account FOR UPDATE;
        SELECT status INTO v_to_status FROM Accounts WHERE account_id = p_to_account FOR UPDATE;
    ELSE
        SELECT status INTO v_to_status FROM Accounts WHERE account_id = p_to_account FOR UPDATE;
        SELECT status, balance INTO v_from_status, v_from_balance FROM Accounts WHERE account_id = p_from_account FOR UPDATE;
    END IF;

    -- Kiểm tra cả hai tài khoản đều Active
    IF v_from_status != 'Active' OR v_to_status != 'Active' THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Một hoặc cả hai tài khoản không ở trạng thái Active';
    END IF;

    -- Kiểm tra số dư đủ
    IF v_from_balance < p_amount THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Số dư tài khoản gửi không đủ';
    END IF;

    -- Trừ tiền tài khoản gửi
    UPDATE Accounts SET balance = balance - p_amount WHERE account_id = p_from_account;

    -- Cộng tiền tài khoản nhận
    UPDATE Accounts SET balance = balance + p_amount WHERE account_id = p_to_account;

    -- Ghi vào bảng Transactions
    INSERT INTO Transactions (from_account, to_account, amount, status)
    VALUES (p_from_account, p_to_account, p_amount, 'Success');

    -- Lấy txn_id vừa tạo
    SET @last_txn_id = LAST_INSERT_ID();

    -- Ghi vào bảng TxnAuditLogs (MyISAM, không hỗ trợ giao dịch)
    INSERT INTO TxnAuditLogs (txn_id, log_message)
    VALUES (@last_txn_id, CONCAT('Chuyển ', p_amount, ' từ tài khoản ', p_from_account, ' sang tài khoản ', p_to_account, ' thành công.'));

    COMMIT;
END //
DELIMITER ;

-- 4. Truy vấn minh họa MVCC

-- a) Hiển thị số dư tài khoản (ví dụ account_id = 1)
SELECT balance FROM Accounts WHERE account_id = 1;

-- b) Mô phỏng giao dịch đồng thời ở session khác:
-- (Chạy trong session khác)
-- SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- START TRANSACTION;
-- CALL TransferMoney(1, 2, 100.00);
-- COMMIT;

-- 5. Truy vấn CTE

-- a) CTE đệ quy liệt kê tất cả cấp dưới nhiều tầng của khách hàng (ví dụ referrer_id = 1)
WITH RECURSIVE MultiLevelReferrals AS (
    SELECT referee_id FROM Referrals WHERE referrer_id = 1
    UNION ALL
    SELECT r.referee_id
    FROM Referrals r
    INNER JOIN MultiLevelReferrals mlr ON r.referrer_id = mlr.referee_id
)
SELECT DISTINCT referee_id FROM MultiLevelReferrals;

-- b) CTE phức tạp gán nhãn giao dịch dựa trên số tiền so với trung bình
WITH AvgAmount AS (
    SELECT AVG(amount) AS avg_amount FROM Transactions
),
LabeledTransactions AS (
    SELECT
        txn_id,
        from_account,
        to_account,
        amount,
        txn_date,
        CASE
            WHEN amount > (SELECT avg_amount FROM AvgAmount) THEN 'High'
            WHEN amount = (SELECT avg_amount FROM AvgAmount) THEN 'Normal'
            ELSE 'Low'
        END AS amount_label
    FROM Transactions
)
SELECT * FROM LabeledTransactions ORDER BY txn_date DESC;

