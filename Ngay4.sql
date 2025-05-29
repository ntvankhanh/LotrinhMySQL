-- Tạo cơ sở dữ liệu OnlineLearning
CREATE DATABASE OnlineLearning
    DEFAULT CHARACTER SET = 'utf8mb4';

USE OnlineLearning;

Drop database OnlineLearning

-- Xóa cơ sở dữ liệu OnlineLearning nếu không còn dùng nữa
-- DROP DATABASE IF EXISTS OnlineLearning;

-- Tạo bảng Students
CREATE TABLE IF NOT EXISTS Students (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    join_date DATE DEFAULT (CURRENT_DATE)
);

-- Tạo bảng Courses
CREATE TABLE IF NOT EXISTS Courses (
    course_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    price INT CHECK (price >= 0)
);

-- Tạo bảng Enrollments
CREATE TABLE IF NOT EXISTS Enrollments (
    enrollment_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT,
    course_id INT,
    enroll_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'active',
    FOREIGN KEY (student_id) REFERENCES Students(student_id),
    FOREIGN KEY (course_id) REFERENCES Courses(course_id)
)

-- Xóa bảng Enrollments nếu không còn cần nữa
-- DROP TABLE IF EXISTS Enrollments;

-- Tạo VIEW StudentCourseView hiển thị danh sách sinh viên và tên khóa học họ đã đăng ký
CREATE OR REPLACE VIEW StudentCourseView AS
SELECT s.student_id, s.full_name, c.title AS course_title
FROM Students s
JOIN Enrollments e ON s.student_id = e.student_id
JOIN Courses c ON e.course_id = c.course_id;

-- Tạo chỉ mục trên cột title của bảng Courses để tối ưu tìm kiếm
CREATE INDEX idx_course_title ON Courses(title);
