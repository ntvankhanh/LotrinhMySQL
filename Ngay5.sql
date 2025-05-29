CREATE DATABASE HotelBookingDB;
    DEFAULT CHARACTER SET = 'utf8mb4';
USE HotelBookingDB;


-- Tạo bảng Phòng
CREATE TABLE IF NOT EXISTS Rooms (
    room_id INT AUTO_INCREMENT PRIMARY KEY,
    room_number VARCHAR(10) UNIQUE,
    type VARCHAR(20),
    status VARCHAR(20),
    price INT CHECK (price >= 0)
);

-- Tạo bảng Khách hàng
CREATE TABLE IF NOT EXISTS Guests (
    guest_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100),
    phone VARCHAR(20)
);

-- Tạo bảng Đặt phòng
CREATE TABLE IF NOT EXISTS Bookings (
    booking_id INT AUTO_INCREMENT PRIMARY KEY,
    guest_id INT,
    room_id INT,
    check_in DATE,
    check_out DATE,
    status VARCHAR(20),
    FOREIGN KEY (guest_id) REFERENCES Guests(guest_id),
    FOREIGN KEY (room_id) REFERENCES Rooms(room_id)
);

-- Tạo bảng Hóa đơn (cho phần bonus)
CREATE TABLE IF NOT EXISTS Invoices (
    invoice_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT,
    total_amount INT,
    generated_date DATE,
    FOREIGN KEY (booking_id) REFERENCES Bookings(booking_id)
);

-- Thủ tục lưu trữ: Đặt phòng
DELIMITER //
CREATE PROCEDURE MakeBooking(
    IN p_guest_id INT,
    IN p_room_id INT,
    IN p_check_in DATE,
    IN p_check_out DATE
)
BEGIN
    DECLARE room_status VARCHAR(20);
    DECLARE conflicting_count INT;

    -- Kiểm tra trạng thái phòng
    SELECT status INTO room_status FROM Rooms WHERE room_id = p_room_id;

    IF room_status != 'Available' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Phòng không có sẵn';
    END IF;

    -- Kiểm tra trùng thời gian đặt phòng
    SELECT COUNT(*) INTO conflicting_count
    FROM Bookings
    WHERE room_id = p_room_id
      AND status = 'Confirmed'
      AND NOT (p_check_out <= check_in OR p_check_in >= check_out);

    IF conflicting_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Phòng đã được đặt trong khoảng thời gian này';
    END IF;

    -- Tạo bản ghi đặt phòng mới
    INSERT INTO Bookings (guest_id, room_id, check_in, check_out, status)
    VALUES (p_guest_id, p_room_id, p_check_in, p_check_out, 'Confirmed');

    -- Cập nhật trạng thái phòng
    UPDATE Rooms SET status = 'Occupied' WHERE room_id = p_room_id;
END //
DELIMITER ;

-- Trigger: Sau khi hủy đặt phòng
DELIMITER //
CREATE TRIGGER after_booking_cancel
AFTER UPDATE ON Bookings
FOR EACH ROW
BEGIN
    IF NEW.status = 'Cancelled' THEN
        DECLARE future_bookings INT;
        SELECT COUNT(*) INTO future_bookings
        FROM Bookings
        WHERE room_id = NEW.room_id
          AND status = 'Confirmed'
          AND check_in > CURDATE();

        IF future_bookings = 0 THEN
            UPDATE Rooms SET status = 'Available' WHERE room_id = NEW.room_id;
        END IF;
    END IF;
END //
DELIMITER ;

-- Thủ tục lưu trữ: Tạo hóa đơn (Bonus)
DELIMITER //
CREATE PROCEDURE GenerateInvoice(
    IN p_booking_id INT
)
BEGIN
    DECLARE nights INT;
    DECLARE room_price INT;
    DECLARE total INT;

    SELECT DATEDIFF(check_out, check_in) INTO nights FROM Bookings WHERE booking_id = p_booking_id;
    SELECT r.price INTO room_price FROM Rooms r JOIN Bookings b ON r.room_id = b.room_id WHERE b.booking_id = p_booking_id;

    SET total = nights * room_price;

    INSERT INTO Invoices (booking_id, total_amount, generated_date)
    VALUES (p_booking_id, total, CURDATE());
END //
DELIMITER ;
