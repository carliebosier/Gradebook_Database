# Grade Book Database Project

## Authors

Carlie Bosier, Shaniah Smith

## Overview

This project implements a grade book database using MySQL. It tracks courses, students, assignments, and grades, and computes final grades based on weighted categories.

## Requirements

* MySQL 8.0 or higher

## How to Run

1. Open MySQL Workbench (or any MySQL client).
2. Open the file `GradeBookDatabase.sql`.
3. Execute the entire script.

How to Run in Terminal

/usr/local/mysql/bin/mysql -u root -p < "GradeBookDatabase.sql"

The script will:

* Drop and recreate the database
* Create all tables
* Insert sample data
* Run all required queries (Tasks 3–12)

## Files Included

* `GradeBookDatabase.sql` — full database implementation
* `README.md` — project instructions
* ER Diagram (image file)
* Test case outputs (screenshots or PDF)

## Notes

* Category weights sum to 100%
* Final grades are calculated using weighted averages
* Task 12 includes logic to drop the lowest score per category
