CREATE DATABASE Ngay3SQL  
DEFAULT CHARACTER SET = 'utf8mb4';



USE Ngay1SQL;


CREATE TABLE IF NOT EXISTS Candidates (
    candidate_id INT PRIMARY KEY,
    full_name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    years_exp INT,
    expected_salary INT
);


CREATE TABLE IF NOT EXISTS Jobs (
    job_id INT PRIMARY KEY,
    title VARCHAR(100),
    department VARCHAR(50),
    min_salary INT,
    max_salary INT
);


CREATE TABLE IF NOT EXISTS Applications (
    app_id INT PRIMARY KEY,
    candidate_id INT,
    job_id INT,
    apply_date DATE,
    status VARCHAR(20),
    FOREIGN KEY (candidate_id) REFERENCES Candidates(candidate_id),
    FOREIGN KEY (job_id) REFERENCES Jobs(job_id)
);


CREATE TABLE IF NOT EXISTS ShortlistedCandidates (
    candidate_id INT,
    job_id INT,
    selection_date DATE,
    PRIMARY KEY (candidate_id, job_id),
    FOREIGN KEY (candidate_id) REFERENCES Candidates(candidate_id),
    FOREIGN KEY (job_id) REFERENCES Jobs(job_id)
);

-- 1. Tìm các ứng viên đã từng ứng tuyển vào ít nhất một công việc thuộc phòng ban "IT"
SELECT DISTINCT c.candidate_id, c.full_name
FROM Candidates c
WHERE EXISTS (
    SELECT 1
    FROM Applications a
    JOIN Jobs j ON a.job_id = j.job_id
    WHERE a.candidate_id = c.candidate_id
      AND j.department = 'IT'
);

-- 2. Liệt kê các công việc mà mức lương tối đa lớn hơn mức lương mong đợi của bất kỳ ứng viên nào
SELECT *
FROM Jobs
WHERE max_salary > ANY (
    SELECT expected_salary FROM Candidates
);

-- 3. Liệt kê các công việc mà mức lương tối thiểu lớn hơn mức lương mong đợi của tất cả ứng viên
SELECT *
FROM Jobs
WHERE min_salary > ALL (
    SELECT expected_salary FROM Candidates
);

-- 4. Chèn vào bảng ShortlistedCandidates những ứng viên có trạng thái ứng tuyển là 'Accepted'
INSERT INTO ShortlistedCandidates (candidate_id, job_id, selection_date)
SELECT candidate_id, job_id, CURDATE()
FROM Applications
WHERE status = 'Accepted';

-- 5. Hiển thị danh sách ứng viên, kèm theo đánh giá mức kinh nghiệm
SELECT candidate_id, full_name, years_exp,
    CASE
        WHEN years_exp < 1 THEN 'Fresher'
        WHEN years_exp BETWEEN 1 AND 3 THEN 'Junior'
        WHEN years_exp BETWEEN 4 AND 6 THEN 'Mid-level'
        ELSE 'Senior'
    END AS experience_level
FROM Candidates;

-- 6. Liệt kê tất cả các ứng viên, nếu phone bị NULL thì thay bằng 'Chưa cung cấp'
SELECT candidate_id, full_name,
       COALESCE(phone, 'Chưa cung cấp') AS phone,
       years_exp, expected_salary
FROM Candidates;

-- 7. Viết truy vấn có chèn comment giải thích các bước
-- Bước 1: Lọc các công việc thuộc phòng ban IT
SELECT *
FROM Jobs
WHERE department = 'IT';

-- 8. Tìm các công việc có mức lương tối đa không bằng mức lương tối thiểu và mức lương tối đa lớn hơn hoặc bằng 1000
SELECT *
FROM Jobs
WHERE max_salary != min_salary
  AND max_salary >= 1000;
