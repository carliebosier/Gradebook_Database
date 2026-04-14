DROP DATABASE IF EXISTS gradebook_db;
CREATE DATABASE gradebook_db;
USE gradebook_db;

-- Tables and relationships for the grade book

CREATE TABLE Course (
    course_id       INT PRIMARY KEY AUTO_INCREMENT,
    department      VARCHAR(10)  NOT NULL,
    course_num      VARCHAR(10)  NOT NULL,
    course_name     VARCHAR(100) NOT NULL,
    semester        VARCHAR(20)  NOT NULL,
    course_year     INT          NOT NULL,
    perfect_grade   DECIMAL(5,2) NOT NULL DEFAULT 100.00,
    CONSTRAINT uq_course_offering UNIQUE (department, course_num, semester, course_year)
);

CREATE TABLE GradingCategory (
    grading_category_id INT PRIMARY KEY AUTO_INCREMENT,
    course_id           INT          NOT NULL,
    category_name       VARCHAR(40)  NOT NULL,
    weight_percent      DECIMAL(5,2) NOT NULL,
    CONSTRAINT fk_gc_course FOREIGN KEY (course_id)
        REFERENCES Course (course_id) ON DELETE CASCADE,
    CONSTRAINT uq_course_category UNIQUE (course_id, category_name),
    CONSTRAINT chk_gc_weight_range CHECK (weight_percent >= 0 AND weight_percent <= 100)
);

CREATE TABLE Assignment (
    assignment_id       INT PRIMARY KEY AUTO_INCREMENT,
    grading_category_id INT          NOT NULL,
    assignment_name     VARCHAR(100) NOT NULL,
    max_points          DECIMAL(6,2) NOT NULL DEFAULT 100.00,
    CONSTRAINT fk_assign_category FOREIGN KEY (grading_category_id)
        REFERENCES GradingCategory (grading_category_id) ON DELETE CASCADE,
    CONSTRAINT uq_category_assignment UNIQUE (grading_category_id, assignment_name)
);

CREATE TABLE Student (
    student_num INT PRIMARY KEY AUTO_INCREMENT,
    first_name  VARCHAR(40) NOT NULL,
    last_name   VARCHAR(40) NOT NULL,
    email       VARCHAR(120) NULL
);

CREATE TABLE Enrollment (
    enrollment_id INT PRIMARY KEY AUTO_INCREMENT,
    course_id     INT NOT NULL,
    student_num   INT NOT NULL,
    CONSTRAINT fk_enroll_course FOREIGN KEY (course_id)
        REFERENCES Course (course_id) ON DELETE CASCADE,
    CONSTRAINT fk_enroll_student FOREIGN KEY (student_num)
        REFERENCES Student (student_num) ON DELETE CASCADE,
    CONSTRAINT uq_course_student UNIQUE (course_id, student_num)
);

CREATE TABLE AssignmentGrade (
    assignment_grade_id INT PRIMARY KEY AUTO_INCREMENT,
    assignment_id       INT NOT NULL,
    student_num         INT NOT NULL,
    points_earned       DECIMAL(6,2) NOT NULL,
    CONSTRAINT fk_ag_assignment FOREIGN KEY (assignment_id)
        REFERENCES Assignment (assignment_id) ON DELETE CASCADE,
    CONSTRAINT fk_ag_student FOREIGN KEY (student_num)
        REFERENCES Student (student_num) ON DELETE CASCADE,
    CONSTRAINT uq_assignment_student UNIQUE (assignment_id, student_num),
    CONSTRAINT chk_points_nonnegative CHECK (points_earned >= 0)
);

-- CS 340 Fall 2026 with a few students and grades

INSERT INTO Course (department, course_num, course_name, semester, course_year, perfect_grade) VALUES
('CS', '340', 'Database Systems', 'Fall', 2026, 100.00);

INSERT INTO GradingCategory (course_id, category_name, weight_percent) VALUES
(1, 'Participation', 10.00),
(1, 'Homework',      20.00),
(1, 'Tests',         50.00),
(1, 'Projects',      20.00);

INSERT INTO Assignment (grading_category_id, assignment_name, max_points) VALUES
(1, 'Participation Log', 100.00),
(2, 'HW1',               100.00),
(2, 'HW2',               100.00),
(3, 'Midterm',           100.00),
(3, 'Final',             100.00),
(4, 'Course Project',    100.00);

INSERT INTO Student (first_name, last_name, email) VALUES
('Alice',  'Anderson', 'alice.anderson@example.edu'),
('Robert', 'Quincy',   'robert.quincy@example.edu'),
('Carol',  'Smith',    'carol.smith@example.edu');

INSERT INTO Enrollment (course_id, student_num) VALUES
(1, 1), (1, 2), (1, 3);

INSERT INTO AssignmentGrade (assignment_id, student_num, points_earned) VALUES
-- Alice
(1, 1, 90.00), (2, 1, 88.00), (3, 1, 92.00), (4, 1, 85.00), (5, 1, 91.00), (6, 1, 89.00),
-- Robert Quincy — last name contains Q for testing the targeted curve
(1, 2, 95.00), (2, 2, 70.00), (3, 2, 75.00), (4, 2, 80.00), (5, 2, 82.00), (6, 2, 78.00),
-- Carol
(1, 3, 80.00), (2, 3, 90.00), (3, 3, 95.00), (4, 3, 60.00), (5, 3, 88.00), (6, 3, 92.00);

-- Dump each table so we can see what got loaded

SELECT 'Course' AS tbl;
SELECT * FROM Course;

SELECT 'GradingCategory' AS tbl;
SELECT * FROM GradingCategory;

SELECT 'Assignment' AS tbl;
SELECT * FROM Assignment;

SELECT 'Student' AS tbl;
SELECT * FROM Student;

SELECT 'Enrollment' AS tbl;
SELECT * FROM Enrollment;

SELECT 'AssignmentGrade' AS tbl;
SELECT * FROM AssignmentGrade;

-- Add HW3 under Homework (no grades yet so stats stay sensible)

INSERT INTO Assignment (grading_category_id, assignment_name, max_points)
SELECT gc.grading_category_id, 'HW3', 100.00
FROM GradingCategory gc
JOIN Course c ON c.course_id = gc.course_id
WHERE c.department = 'CS'
  AND c.course_num = '340'
  AND c.semester = 'Fall'
  AND c.course_year = 2026
  AND gc.category_name = 'Homework';

-- Shift 2% from Homework to Tests (still totals 100%)

UPDATE GradingCategory gc
JOIN Course c ON c.course_id = gc.course_id
SET gc.weight_percent = CASE gc.category_name
        WHEN 'Homework' THEN 18.00
        WHEN 'Tests'     THEN 52.00
        ELSE gc.weight_percent
    END
WHERE c.department = 'CS'
  AND c.course_num = '340'
  AND c.semester = 'Fall'
  AND c.course_year = 2026
  AND gc.category_name IN ('Homework', 'Tests');

-- Everyone gets +2 on HW1, capped at the max

UPDATE AssignmentGrade ag
JOIN Assignment a ON a.assignment_id = ag.assignment_id
JOIN GradingCategory gc ON gc.grading_category_id = a.grading_category_id
JOIN Course c ON c.course_id = gc.course_id
SET ag.points_earned = LEAST(ag.points_earned + 2.00, a.max_points)
WHERE c.department = 'CS'
  AND c.course_num = '340'
  AND c.semester = 'Fall'
  AND c.course_year = 2026
  AND gc.category_name = 'Homework'
  AND a.assignment_name = 'HW1';

-- +2 on HW2 only if last name has a Q (case-insensitive)

UPDATE AssignmentGrade ag
JOIN Assignment a ON a.assignment_id = ag.assignment_id
JOIN GradingCategory gc ON gc.grading_category_id = a.grading_category_id
JOIN Course c ON c.course_id = gc.course_id
JOIN Student s ON s.student_num = ag.student_num
SET ag.points_earned = LEAST(ag.points_earned + 2.00, a.max_points)
WHERE LOWER(s.last_name) LIKE '%q%'
  AND c.department = 'CS'
  AND c.course_num = '340'
  AND c.semester = 'Fall'
  AND c.course_year = 2026
  AND gc.category_name = 'Homework'
  AND a.assignment_name = 'HW2';

-- Average / high / low for HW1 (after the curves)

SELECT
    c.department,
    c.course_num,
    c.semester,
    c.course_year,
    gc.category_name,
    a.assignment_name,
    ROUND(AVG(ag.points_earned), 2) AS average_score,
    MAX(ag.points_earned)             AS highest_score,
    MIN(ag.points_earned)             AS lowest_score
FROM Assignment a
JOIN GradingCategory gc ON gc.grading_category_id = a.grading_category_id
JOIN Course c           ON c.course_id = gc.course_id
JOIN AssignmentGrade ag ON ag.assignment_id = a.assignment_id
WHERE c.department = 'CS'
  AND c.course_num = '340'
  AND c.semester = 'Fall'
  AND c.course_year = 2026
  AND gc.category_name = 'Homework'
  AND a.assignment_name = 'HW1'
GROUP BY
    c.course_id,
    c.department,
    c.course_num,
    c.semester,
    c.course_year,
    gc.category_name,
    a.assignment_name;

-- Roster for CS 340 Fall 2026

SELECT
    s.student_num,
    s.first_name,
    s.last_name,
    s.email
FROM Enrollment e
JOIN Student s ON s.student_num = e.student_num
JOIN Course c  ON c.course_id = e.course_id
WHERE c.department = 'CS'
  AND c.course_num = '340'
  AND c.semester = 'Fall'
  AND c.course_year = 2026
ORDER BY s.last_name, s.first_name;

-- Every assignment per student (null if no grade entered yet)

SELECT
    s.student_num,
    s.first_name,
    s.last_name,
    gc.category_name,
    a.assignment_name,
    a.max_points,
    ag.points_earned
FROM Enrollment e
JOIN Student s ON s.student_num = e.student_num
JOIN Course c ON c.course_id = e.course_id
JOIN GradingCategory gc ON gc.course_id = c.course_id
JOIN Assignment a ON a.grading_category_id = gc.grading_category_id
LEFT JOIN AssignmentGrade ag
    ON ag.assignment_id = a.assignment_id
   AND ag.student_num = s.student_num
WHERE c.department = 'CS'
  AND c.course_num = '340'
  AND c.semester = 'Fall'
  AND c.course_year = 2026
ORDER BY s.last_name, s.first_name, gc.category_name, a.assignment_name;

-- Weighted final: share of points earned in each category times that category's weight

SELECT
    s.student_num,
    s.first_name,
    s.last_name,
    ROUND(SUM(
        (COALESCE(cat.earned, 0) / NULLIF(cat.possible, 0)) * gc.weight_percent
    ), 2) AS final_grade
FROM Enrollment e
JOIN Student s ON s.student_num = e.student_num
JOIN Course c ON c.course_id = e.course_id
JOIN GradingCategory gc ON gc.course_id = c.course_id
LEFT JOIN (
    SELECT
        ag.student_num,
        gc2.grading_category_id,
        SUM(ag.points_earned) AS earned,
        SUM(a.max_points)     AS possible
    FROM AssignmentGrade ag
    JOIN Assignment a ON a.assignment_id = ag.assignment_id
    JOIN GradingCategory gc2 ON gc2.grading_category_id = a.grading_category_id
    GROUP BY ag.student_num, gc2.grading_category_id
) cat ON cat.student_num = s.student_num
     AND cat.grading_category_id = gc.grading_category_id
WHERE c.department = 'CS'
  AND c.course_num = '340'
  AND c.semester = 'Fall'
  AND c.course_year = 2026
GROUP BY s.student_num, s.first_name, s.last_name
ORDER BY s.last_name, s.first_name;

-- Same idea but drop each student's lowest score per category (skip drop if only one grade there)

WITH base AS (
    SELECT
        ag.student_num,
        gc.grading_category_id,
        gc.category_name,
        gc.weight_percent,
        a.assignment_id,
        ag.points_earned,
        a.max_points,
        COUNT(*) OVER (
            PARTITION BY ag.student_num, gc.grading_category_id
        ) AS assignments_in_category,
        ROW_NUMBER() OVER (
            PARTITION BY ag.student_num, gc.grading_category_id
            ORDER BY ag.points_earned ASC, a.assignment_id ASC
        ) AS rn_lowest_first
    FROM AssignmentGrade ag
    JOIN Assignment a ON a.assignment_id = ag.assignment_id
    JOIN GradingCategory gc ON gc.grading_category_id = a.grading_category_id
    JOIN Course c ON c.course_id = gc.course_id
    WHERE c.department = 'CS'
      AND c.course_num = '340'
      AND c.semester = 'Fall'
      AND c.course_year = 2026
),
filtered AS (
    SELECT *
    FROM base
    WHERE assignments_in_category = 1
       OR rn_lowest_first > 1
),
per_category AS (
    SELECT
        student_num,
        grading_category_id,
        category_name,
        weight_percent,
        SUM(points_earned) AS earned,
        SUM(max_points)   AS possible
    FROM filtered
    GROUP BY student_num, grading_category_id, category_name, weight_percent
)
SELECT
    s.student_num,
    s.first_name,
    s.last_name,
    ROUND(SUM((earned / NULLIF(possible, 0)) * weight_percent), 2) AS final_grade_drop_lowest
FROM per_category pc
JOIN Student s ON s.student_num = pc.student_num
GROUP BY s.student_num, s.first_name, s.last_name
ORDER BY s.last_name, s.first_name;
