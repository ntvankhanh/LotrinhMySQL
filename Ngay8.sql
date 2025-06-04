CREATE DATABASE Ngay8SQL  
DEFAULT CHARACTER SET = 'utf8mb4';
USE Ngay8SQL;
-- 1. Tạo bảng
drop database Ngay8SQL  ;

-- 1. Tạo bảng

-- Tạo bảng Users
CREATE TABLE IF NOT EXISTS Users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tạo bảng Posts
CREATE TABLE IF NOT EXISTS Posts (
    post_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    likes INT DEFAULT 0,
    hashtags VARCHAR(255),
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

-- Tạo bảng Follows
CREATE TABLE IF NOT EXISTS Follows (
    follower_id INT NOT NULL,
    followee_id INT NOT NULL,
    PRIMARY KEY (follower_id, followee_id),
    FOREIGN KEY (follower_id) REFERENCES Users(user_id),
    FOREIGN KEY (followee_id) REFERENCES Users(user_id)
);

-- Tạo bảng PostViews
CREATE TABLE IF NOT EXISTS PostViews (
    view_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    viewer_id INT NOT NULL,
    view_time DATETIME NOT NULL,
    FOREIGN KEY (post_id) REFERENCES Posts(post_id),
    FOREIGN KEY (viewer_id) REFERENCES Users(user_id)
);

-- 1. Bộ nhớ đệm: Truy vấn lấy 10 bài viết được thích nhiều nhất hôm nay
SELECT post_id, user_id, content, created_at, likes
FROM Posts
WHERE DATE(created_at) = CURDATE()
ORDER BY likes DESC
LIMIT 10;

-- Đề xuất: Cache kết quả này ở tầng ứng dụng hoặc tạo bảng MEMORY để lưu trữ kết quả này nhằm truy cập nhanh.

-- 2. EXPLAIN ANALYZE cho truy vấn tìm kiếm hashtag
EXPLAIN ANALYZE
SELECT * FROM Posts
WHERE hashtags LIKE '%fitness%'
ORDER BY created_at DESC
LIMIT 20;

-- Điểm nghẽn: Quét toàn bộ bảng do wildcard ở đầu LIKE '%fitness%'
-- Đề xuất: Sử dụng full-text index trên cột hashtags hoặc chuẩn hóa hashtags thành bảng riêng để tìm kiếm hiệu quả.

-- 3. Phân vùng bảng PostViews theo tháng dựa trên view_time
ALTER TABLE PostViews
PARTITION BY RANGE (YEAR(view_time) * 100 + MONTH(view_time)) (
    PARTITION p202301 VALUES LESS THAN (202302),
    PARTITION p202302 VALUES LESS THAN (202303),
    PARTITION p202303 VALUES LESS THAN (202304),
    PARTITION p202304 VALUES LESS THAN (202305),
    PARTITION p202305 VALUES LESS THAN (202306),
    PARTITION p202306 VALUES LESS THAN (202307),
    PARTITION pMax VALUES LESS THAN MAXVALUE
);

-- Truy vấn thống kê số lượt xem mỗi tháng trong 6 tháng gần nhất
SELECT DATE_FORMAT(view_time, '%Y-%m') AS month, COUNT(*) AS view_count
FROM PostViews
WHERE view_time >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY month
ORDER BY month DESC;

-- 4. Chuẩn hóa & Phi chuẩn hóa

-- Tạo bảng PostHashtags chuẩn hóa hashtags
CREATE TABLE PostHashtags (
    post_id INT NOT NULL,
    hashtag VARCHAR(100) NOT NULL,
    PRIMARY KEY (post_id, hashtag),
    FOREIGN KEY (post_id) REFERENCES Posts(post_id)
);

-- Tạo bảng PopularPostsDaily phi chuẩn hóa để lưu tổng hợp theo ngày
CREATE TABLE PopularPostsDaily (
    post_id INT NOT NULL,
    date DATE NOT NULL,
    total_likes INT NOT NULL,
    total_views INT NOT NULL,
    PRIMARY KEY (post_id, date)
);

-- 5. Tối ưu kiểu dữ liệu

-- Chuyển view_id từ BIGINT sang INT nếu số bản ghi < 2 tỷ
-- ALTER TABLE PostViews MODIFY view_id INT NOT NULL AUTO_INCREMENT;

-- Điều chỉnh độ dài VARCHAR (ví dụ)
-- ALTER TABLE Posts MODIFY hashtags VARCHAR(100);

-- Chuyển DATETIME sang TIMESTAMP nếu phù hợp
-- ALTER TABLE Posts MODIFY created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- 6. Hàm cửa sổ: Tổng lượt xem mỗi ngày và xếp hạng

WITH DailyViews AS (
    SELECT
        post_id,
        DATE(view_time) AS view_date,
        COUNT(*) AS total_views
    FROM PostViews
    GROUP BY post_id, view_date
),
RankedViews AS (
    SELECT
        post_id,
        view_date,
        total_views,
        RANK() OVER (PARTITION BY view_date ORDER BY total_views DESC) AS rank
    FROM DailyViews
)
SELECT post_id, view_date, total_views, rank
FROM RankedViews
WHERE rank <= 3
ORDER BY view_date DESC, rank;

-- 7. Thủ tục lưu trữ cập nhật lượt thích khi người dùng like

DELIMITER //
CREATE PROCEDURE UpdatePostLike(IN p_post_id INT, IN p_user_id INT)
BEGIN
    DECLARE already_liked INT DEFAULT 0;

    START TRANSACTION;

    SELECT COUNT(*) INTO already_liked
    FROM PostLikes
    WHERE post_id = p_post_id AND user_id = p_user_id;

    IF already_liked = 0 THEN
        INSERT INTO PostLikes(post_id, user_id) VALUES (p_post_id, p_user_id);
        UPDATE Posts SET likes = likes + 1 WHERE post_id = p_post_id;
    END IF;

    COMMIT;
END //
DELIMITER ;

-- 8. Bật Slow Query Log

-- SET GLOBAL slow_query_log = 'ON';
-- SET GLOBAL slow_query_log_file = '/var/log/mysql/mysql-slow.log';
-- SET GLOBAL long_query_time = 1; -- Ghi lại truy vấn chạy lâu hơn 1 giây

-- Phân tích truy vấn chậm bằng mysqldumpslow hoặc pt-query-digest
-- Ví dụ cải thiện: Thêm index trên Posts(hashtags) hoặc viết lại truy vấn tránh quét toàn bộ bảng

-- 9. Bật OPTIMIZER_TRACE và phân tích kế hoạch truy vấn

-- SET optimizer_trace="enabled=on";
-- SELECT * FROM Posts p JOIN Users u ON p.user_id = u.user_id WHERE p.likes > 100 ORDER BY p.created_at DESC LIMIT 10;
-- SELECT @@optimizer_trace;
-- SET optimizer_trace="enabled=off";

-- Dữ liệu mẫu cho bảng Users
INSERT INTO Users (user_id, username, created_at) VALUES
(1, 'alice', '2024-06-01 08:00:00'),
(2, 'bob', '2024-06-01 09:00:00'),
(3, 'charlie', '2024-06-02 10:00:00');

-- Dữ liệu mẫu cho bảng Posts
INSERT INTO Posts (post_id, user_id, content, created_at, likes, hashtags) VALUES
(1, 1, 'Hello world! #welcome', '2024-06-03 08:30:00', 5, 'welcome'),
(2, 2, 'Fitness is life! #fitness #health', '2024-06-03 09:00:00', 10, 'fitness,health'),
(3, 1, 'Reading books #books', '2024-06-04 10:00:00', 3, 'books'),
(4, 3, 'Morning run #fitness', '2024-06-04 06:00:00', 8, 'fitness');

-- Dữ liệu mẫu cho bảng Follows
INSERT INTO Follows (follower_id, followee_id) VALUES
(1, 2),
(2, 1),
(3, 1);

-- Dữ liệu mẫu cho bảng PostViews
INSERT INTO PostViews (view_id, post_id, viewer_id, view_time) VALUES
(1, 1, 2, '2024-06-03 09:10:00'),
(2, 1, 3, '2024-06-03 10:00:00'),
(3, 2, 1, '2024-06-03 11:00:00'),
(4, 2, 3, '2024-06-03 12:00:00'),
(5, 3, 2, '2024-06-04 11:00:00'),
(6, 4, 1, '2024-06-04 07:00:00'),
(7, 4, 2, '2024-06-04 08:00:00');

