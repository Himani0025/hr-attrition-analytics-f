create database hr_analytics;
use hr_analytics;

create table hr_data (
    Age INT,
    Attrition VARCHAR(10),
    BusinessTravel VARCHAR(50),
    DailyRate INT,
    Department VARCHAR(50),
    DistanceFromHome INT,
    Education INT,
    EducationField VARCHAR(50),
    EmployeeCount INT,
    EmployeeNumber INT PRIMARY KEY,
    EnvironmentSatisfaction INT,
    Gender VARCHAR(10),
    HourlyRate INT,
    JobInvolvement INT,
    JobLevel INT,
    JobRole VARCHAR(100),
    JobSatisfaction INT,
    MaritalStatus VARCHAR(20),
    MonthlyIncome INT,
    MonthlyRate INT,
    NumCompaniesWorked INT,
    Over18 CHAR(1),
    OverTime VARCHAR(10),
    PercentSalaryHike INT,
    PerformanceRating INT,
    RelationshipSatisfaction INT,
    StandardHours INT,
    StockOptionLevel INT,
    TotalWorkingYears INT,
    TrainingTimesLastYear INT,
    WorkLifeBalance INT,
    YearsAtCompany INT,
    YearsInCurrentRole INT,
    YearsSinceLastPromotion INT,
    YearsWithCurrManager INT
);

select * from hr_data limit 10;

# Query 1 - Attrition rate by department
SELECT Department, COUNT(*) AS total_employees,
SUM(CASE WHEN Attrition='Yes' THEN 1 ELSE 0 END) AS left_count,
ROUND(
      SUM(CASE WHEN Attrition='Yes' THEN 1.0 ELSE 0 END) /
	  COUNT(*) * 100, 2
     ) AS attrition_rate_pct
FROM hr_data
GROUP BY Department
ORDER BY attrition_rate_pct DESC;

# Query 2 - CTE: High risk segment identification
WITH salary_stats AS (
    SELECT
        Department,
        ROUND(AVG(MonthlyIncome), 0) AS dept_avg_salary,
        ROUND(AVG(CASE WHEN Attrition='Yes'
              THEN MonthlyIncome END), 0) AS avg_salary_left,
        ROUND(AVG(CASE WHEN Attrition='No'
              THEN MonthlyIncome END), 0) AS avg_salary_stayed
    FROM hr_data
    GROUP BY Department
),
overtime_stats AS (
    SELECT
        Department,
        ROUND(
            SUM(CASE WHEN OverTime='Yes' AND Attrition='Yes'
                THEN 1.0 ELSE 0 END) /
            SUM(CASE WHEN OverTime='Yes'
                THEN 1.0 ELSE 0.001 END) * 100, 2
        ) AS overtime_attrition_pct
    FROM hr_data
    GROUP BY Department
)
SELECT
    s.Department,
    s.dept_avg_salary,
    s.avg_salary_left,
    s.avg_salary_stayed,
    s.avg_salary_stayed - s.avg_salary_left AS salary_gap,
    o.overtime_attrition_pct
FROM salary_stats s
JOIN overtime_stats o ON s.Department = o.Department
ORDER BY salary_gap DESC;


# Query 3 - Window function: Salary rank within department
SELECT EmployeeNumber, Department, JobRole, MonthlyIncome, Attrition,
RANK() OVER (PARTITION BY Department ORDER BY MonthlyIncome DESC) AS salary_rank_in_dept,
ROUND(AVG(MonthlyIncome) OVER (PARTITION BY Department), 0) AS dept_avg_salary,
MonthlyIncome - ROUND(AVG(MonthlyIncome) OVER (PARTITION BY Department), 0) AS salary_vs_avg
FROM hr_data
ORDER BY Department, salary_rank_in_dept;


# Query 4 - Flight risk: high performers not promoted
SELECT EmployeeNumber, Department, JobRole, PerformanceRating, YearsAtCompany, YearsSinceLastPromotion, MonthlyIncome, Attrition
FROM hr_data
WHERE
    PerformanceRating >= 3
    AND YearsSinceLastPromotion >= 3
    AND YearsAtCompany >= 3
ORDER BY YearsSinceLastPromotion DESC;
