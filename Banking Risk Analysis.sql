-- =========================================================
-- BANKING RISK ANALYSIS PROJECT
-- SQL + Power BI Portfolio Project
-- =========================================================

-- =========================================================
-- 1. CREATE TABLES
-- =========================================================

-- Customers table
CREATE TABLE Customers (
Customer_id INT PRIMARY KEY,
Name VARCHAR(30),
Age INT,
Gender VARCHAR(20),
Income DECIMAL(10,2),
Credit_Score INT
);

-- Loans table
CREATE TABLE Loans (
Loan_id INT PRIMARY KEY,
Customer_id INT,
Loan_Amount DECIMAL(10,2),
Loan_Type VARCHAR(30),
Interest_Rate DECIMAL(5,2),
Loan_Status VARCHAR(20),
FOREIGN KEY (Customer_id) REFERENCES Customers(Customer_id)
);

-- Payments table
CREATE TABLE Payments (
Payment_id INT PRIMARY KEY,
Loan_id INT,
Repayment_Date DATE,
Amount_Paid DECIMAL(10,2),
FOREIGN KEY (Loan_id) REFERENCES Loans(Loan_id)
);

-- =========================================================
-- 2. INSERT DATA
-- =========================================================

INSERT INTO Customers VALUES
(1, 'Ravi Kumar', 35, 'Male', 45000, 720),
(2, 'Anita Sharma', 29, 'Female', 30000, 650),
(3, 'Suresh Patil', 42, 'Male', 20000, 580),
(4, 'Meena Joshi', 50, 'Female', 60000, 800),
(5, 'Rajesh Singh', 38, 'Male', 25000, 500);

INSERT INTO Loans VALUES
(101, 1, 200000, 'Home Loan', 7.5, 'Repaid'),
(102, 2, 50000, 'Car Loan', 9.0, 'Defaulted'),
(103, 3, 100000, 'Personal Loan', 12.0, 'Defaulted'),
(104, 4, 300000, 'Home Loan', 6.5, 'Approved'),
(105, 5, 80000, 'Personal Loan', 11.0, 'Defaulted');

INSERT INTO Payments VALUES
(1, 101, '2026-01-15', 200000),
(2, 102, '2026-02-10', 20000),
(3, 103, '2026-03-05', 30000),
(4, 105, '2026-04-01', 20000);

-- =========================================================
-- 3. BASIC DATA VALIDATION
-- =========================================================

SELECT * FROM Customers;

SELECT * FROM Loans;

SELECT * FROM Payments;

-- =========================================================
-- 4. BUSINESS ANALYSIS QUERIES
-- =========================================================

---

-- Query 1: Identify High-Risk Customers
-- Low credit score + defaulted loan

---

SELECT
c.Customer_id,c.Name,c.Credit_Score,l.Loan_Type,l.Loan_Status
FROM Customers c
JOIN Loans l
ON c.Customer_id = l.Customer_id
WHERE c.Credit_Score < 600
AND l.Loan_Status = 'Defaulted';

-- Query 2: Default Count by Loan Type

SELECT Loan_Type, COUNT(*) AS Total_Defaults
FROM Loans
WHERE Loan_Status = 'Defaulted'
GROUP BY Loan_Type
ORDER BY Total_Defaults DESC;

-- Query 3: Average Income and Credit Score of Customers with Defaulted Loans

SELECT
AVG(c.Income) AS Avg_Income,
AVG(c.Credit_Score) AS Avg_Credit_Score
FROM Customers c JOIN Loans l
ON c.Customer_id = l.Customer_id
WHERE l.Loan_Status = 'Defaulted';

-- Query 4: Customers Meeting Selected Criteria

SELECT Customer_id, Name,Income,Credit_Score
FROM Customers
WHERE Credit_Score > 600
AND Income > 25000;


-- Query 5: Customer Risk Classification
-- CASE WHEN

---

SELECT
Customer_id, Name, Credit_Score,
CASE
WHEN Credit_Score < 600 THEN 'High Risk'
WHEN Credit_Score BETWEEN 600 AND 700 THEN 'Medium Risk'
ELSE 'Low Risk'
END AS Risk_Category
FROM Customers;

---

-- Query 6: Loan Amount Compared with Average
-- Loan Amount by Loan Type
-- Window Function

---

SELECT Loan_id, Customer_id, Loan_Type, Loan_Amount,
AVG(Loan_Amount) OVER (PARTITION BY Loan_Type) AS Avg_Loan_By_Type,
Loan_Amount - 
AVG(Loan_Amount) OVER (PARTITION BY Loan_Type) AS Deviation_From_Average
FROM Loans;

---

-- Query 7: Default Rate by Loan Type
-- CTE

---

WITH DefaultedLoans AS (
SELECT
Loan_Type, COUNT(*) AS Default_Count
FROM Loans
WHERE Loan_Status = 'Defaulted'
GROUP BY Loan_Type
),

TotalLoans AS (
SELECT Loan_Type, COUNT(*) AS Total_Loans
FROM Loans
GROUP BY Loan_Type
)

SELECT t.Loan_Type,
COALESCE(d.Default_Count, 0) AS Default_Count, 

t.Total_Loans,
COALESCE(d.Default_Count, 0) * 100.0
/ NULLIF(t.Total_Loans, 0) AS Default_Rate


FROM TotalLoans t
LEFT JOIN DefaultedLoans d
ON t.Loan_Type = d.Loan_Type

ORDER BY Default_Rate DESC;

---

-- Query 8: Total Payments by Loan
-- COALESCE

---

SELECT l.Loan_id, c.Name, l.Loan_Amount,

COALESCE(SUM(p.Amount_Paid),0) AS Total_Paid
FROM Loans l JOIN Customers c
ON c.Customer_id = l.Customer_id
LEFT JOIN Payments p
ON l.Loan_id = p.Loan_id

GROUP BY l.Loan_id, c.Name, l.Loan_Amount;

---

-- Query 9: Recovery Rate by Loan

---

SELECT l.Loan_id, l.Loan_Amount,
COALESCE(SUM(p.Amount_Paid),0) AS Total_Paid,
COALESCE(SUM(p.Amount_Paid) * 100.0/ NULLIF(l.Loan_Amount, 0),0) AS Recovery_Rate
FROM Loans l
LEFT JOIN Payments p
ON l.Loan_id = p.Loan_id

GROUP BY
l.Loan_id, l.Loan_Amount;

---

-- Query 10: Payment Activity for Defaulted Loans

---

-- NOTE:
-- This is payment activity by month, NOT the month
-- in which a loan became defaulted because the dataset
-- does not contain a Default_Date column.

---

SELECT
YEAR(p.Repayment_Date) AS Payment_Year,
MONTH(p.Repayment_Date) AS Payment_Month,
COUNT(*) AS Payment_Count
FROM Loans l JOIN Payments p
ON l.Loan_id = p.Loan_id

WHERE l.Loan_Status = 'Defaulted'

GROUP BY
YEAR(p.Repayment_Date),
MONTH(p.Repayment_Date)

ORDER BY
Payment_Year,
Payment_Month;

---

-- Query 11: Overall Default Rate

---

SELECT COUNT(*) AS Total_Loans,

SUM(CASE WHEN Loan_Status = 'Defaulted' THEN 1 ELSE 0 END) AS Defaulted_Loans,
SUM(CASE WHEN Loan_Status = 'Defaulted' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) AS Default_Rate

FROM Loans;

---

-- Query 12: Average Loan Amount

---

SELECT AVG(Loan_Amount) AS Average_Loan_Amount
FROM Loans;

-- =========================================================
-- 5. ADVANCED / RECRUITER-FOCUSED ANALYSIS
-- =========================================================

---

-- Query 13: Outstanding Loan Amount

---

SELECT l.Loan_id, c.Name, l.Loan_Amount,
COALESCE(SUM(p.Amount_Paid),0) AS Total_Paid,

l.Loan_Amount -
COALESCE(SUM(p.Amount_Paid),0) AS Outstanding_Amount
FROM Loans l
JOIN Customers c
ON l.Customer_id = c.Customer_id
LEFT JOIN Payments p
ON l.Loan_id = p.Loan_id
GROUP BY l.Loan_id, c.Name,l.Loan_Amount
ORDER BY Outstanding_Amount DESC;

---

-- Query 14: Total Default Exposure

---

SELECT SUM(
CASE WHEN Loan_Status = 'Defaulted'THEN Loan_Amount ELSE 0 END) AS Total_Default_Exposure
FROM Loans;

---

-- Query 15: Default Rate by Gender

---

SELECT c.Gender, COUNT(l.Loan_id) AS Total_Loans,

SUM( CASE WHEN l.Loan_Status = 'Defaulted' THEN 1 ELSE 0 END) AS Defaulted_Loans,
SUM( CASE WHEN l.Loan_Status = 'Defaulted' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(l.Loan_id), 0) AS Default_Rate
FROM Customers c JOIN Loans l 
ON c.Customer_id = l.Customer_id
GROUP BY c.Gender;

---

-- Query 16: Default Rate by Credit Score Band
-- CTE + CASE + JOIN

---

WITH CustomerRisk AS (
SELECT Customer_id,

    CASE
        WHEN Credit_Score < 600 THEN 'Below 600'
        WHEN Credit_Score BETWEEN 600 AND 699 THEN '600-699'
        WHEN Credit_Score BETWEEN 700 AND 749 THEN '700-749'
        ELSE '750+'
    END AS Credit_Band

FROM Customers )

SELECT cr.Credit_Band,

COUNT(l.Loan_id) AS Total_Loans,

SUM(CASE WHEN l.Loan_Status = 'Defaulted' THEN 1 ELSE 0
 END) AS Defaulted_Loans,

SUM(CASE WHEN l.Loan_Status = 'Defaulted' THEN 1 ELSE 0 END) * 100.0
/ NULLIF(COUNT(l.Loan_id), 0) AS Default_Rate


FROM CustomerRisk cr

JOIN Loans l
ON cr.Customer_id = l.Customer_id

GROUP BY cr.Credit_Band

ORDER BY cr.Credit_Band;

---

-- Query 17: Rank Customers by Total Loan Exposure
-- RANK Window Function

---

SELECT c.Customer_id, c.Name,
SUM(l.Loan_Amount) AS Total_Loan_Exposure,
RANK() OVER (ORDER BY SUM(l.Loan_Amount) DESC) AS Exposure_Rank
FROM Customers c
JOIN Loans l ON c.Customer_id = l.Customer_id

GROUP BY c.Customer_id, c.Name;

---

-- Query 18: Highest-Value Loan by Loan Type
-- ROW_NUMBER Window Function

---

WITH RankedLoans AS (


SELECT
    Loan_id,
    Customer_id,
    Loan_Type,
    Loan_Amount,

    ROW_NUMBER() OVER (
        PARTITION BY Loan_Type
        ORDER BY Loan_Amount DESC
    ) AS Loan_Rank

FROM Loans


)

SELECT
Loan_id,
Customer_id,
Loan_Type,
Loan_Amount

FROM RankedLoans

WHERE Loan_Rank = 1;

---

-- Query 19: Customer-Level Risk Profile
-- Useful for Power BI

---

SELECT
c.Customer_id,
c.Name,
c.Income,
c.Credit_Score,


COUNT(l.Loan_id) AS Total_Loans,

COALESCE(
    SUM(l.Loan_Amount),
    0
) AS Total_Loan_Amount,

SUM(
    CASE
        WHEN l.Loan_Status = 'Defaulted'
        THEN 1
        ELSE 0
    END
) AS Defaulted_Loans


FROM Customers c

LEFT JOIN Loans l
ON c.Customer_id = l.Customer_id

GROUP BY
c.Customer_id,
c.Name,
c.Income,
c.Credit_Score;

---

-- Query 20: Payment Performance by Loan

---

SELECT
l.Loan_id,
l.Loan_Status,
l.Loan_Amount,


COALESCE(
    SUM(p.Amount_Paid),
    0
) AS Total_Paid,

l.Loan_Amount -
COALESCE(
    SUM(p.Amount_Paid),
    0
) AS Outstanding_Amount,

COALESCE(
    SUM(p.Amount_Paid) * 100.0
    / NULLIF(l.Loan_Amount, 0),
    0
) AS Recovery_Rate


FROM Loans l

LEFT JOIN Payments p
ON l.Loan_id = p.Loan_id

GROUP BY
l.Loan_id,
l.Loan_Status,
l.Loan_Amount;

-- =========================================================
-- 6. DATA QUALITY ANALYSIS
-- =========================================================

---

-- Query 21: Check for Duplicate Customers

---

SELECT
Customer_id,
COUNT(*) AS Record_Count

FROM Customers

GROUP BY Customer_id

HAVING COUNT(*) > 1;

---

-- Query 22: Check for Orphan Payments
-- Payments without a matching loan

---

SELECT
p.Payment_id,
p.Loan_id

FROM Payments p

LEFT JOIN Loans l
ON p.Loan_id = l.Loan_id

WHERE l.Loan_id IS NULL;

---

-- Query 23: Find Customers Without Loans

---

SELECT
c.Customer_id,
c.Name

FROM Customers c

LEFT JOIN Loans l
ON c.Customer_id = l.Customer_id

WHERE l.Loan_id IS NULL;

---

-- Query 24: Check for Loans Without Payments

---

SELECT
l.Loan_id,
l.Customer_id,
l.Loan_Amount,
l.Loan_Status

FROM Loans l

LEFT JOIN Payments p
ON l.Loan_id = p.Loan_id

WHERE p.Payment_id IS NULL;

---

-- Query 25: Check for Payments Greater Than Loan Amount
-- Potential data-quality / business-rule exception

---

SELECT
l.Loan_id,
l.Loan_Amount,
COALESCE(
SUM(p.Amount_Paid),
0
) AS Total_Paid

FROM Loans l

LEFT JOIN Payments p
ON l.Loan_id = p.Loan_id

GROUP BY
l.Loan_id,
l.Loan_Amount

HAVING COALESCE(
SUM(p.Amount_Paid),
0
) > l.Loan_Amount;

-- =========================================================
-- 7. FINAL POWER BI DATASET
-- Customer + Loan + Payment Performance
-- =========================================================

SELECT
c.Customer_id,
c.Name,
c.Age,
c.Gender,
c.Income,
c.Credit_Score,


l.Loan_id,
l.Loan_Type,
l.Loan_Amount,
l.Interest_Rate,
l.Loan_Status,

COALESCE(
    SUM(p.Amount_Paid),
    0
) AS Total_Paid,

l.Loan_Amount -
COALESCE(
    SUM(p.Amount_Paid),
    0
) AS Outstanding_Amount,

COALESCE(
    SUM(p.Amount_Paid) * 100.0
    / NULLIF(l.Loan_Amount, 0),
    0
) AS Recovery_Rate,

CASE
    WHEN c.Credit_Score < 600
        THEN 'High Risk'

    WHEN c.Credit_Score BETWEEN 600 AND 700
        THEN 'Medium Risk'

    ELSE 'Low Risk'
END AS Risk_Category


FROM Customers c

JOIN Loans l
ON c.Customer_id = l.Customer_id

LEFT JOIN Payments p
ON l.Loan_id = p.Loan_id

GROUP BY
c.Customer_id,
c.Name,
c.Age,
c.Gender,
c.Income,
c.Credit_Score,
l.Loan_id,
l.Loan_Type,
l.Loan_Amount,
l.Interest_Rate,
l.Loan_Status;

-- =========================================================
-- END OF BANKING RISK ANALYSIS PROJECT
-- =========================================================
