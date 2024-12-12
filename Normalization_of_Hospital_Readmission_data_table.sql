CREATE DATABASE ANAlyticsProject;
USE AnalyticsProjec;
SELECT * FROM hospital_visits;

-- CREATING NEW TABLE TO KEEP RAW DATA UNCHANGED
CREATE TABLE Hospital_Visits_CLean LIKE hospital_visits;
SELECT * FROM Hospital_Visits_CLean;

-- INSERTING DATA INTO NEWLY CREATED TABLE
INSERT Hospital_Visits_Clean SELECT * FROM hospital_visits;
SELECT * FROM Hospital_Visits_CLean;
SHOW COLUMNS FROM Hospital_Visits_CLean;


-- FILTERING DATA FOR HOSPITAL OF MICHIGAN ONLY AND HANDLING NULL VALUES
-- FILTERING MEASURE BASED ON 30-DAY READMISSION RATE

CREATE TABLE michigan_hospital_readmission_2024 AS
SELECT *
FROM Hospital_Visits_CLean
WHERE `Facility ID` IS NOT NULL
  AND TRIM(`Facility ID`) IN ('230017', '230020', '230038', '230058', '230081', '230097', '230110', '230156', '230222', '231320', '233300', '230059', '231322')
  AND `Measure Name` LIKE '%30-Day Readmission%';

SELECT * FROM michigan_hospital_readmission_2024;

-- NORMALIZING TABLE INTO 4NF
-- Create Hospitals Table
CREATE TABLE Michigan_Hospitals (
    Hospital_ID INT PRIMARY KEY,
    Hospital_Name VARCHAR(255),
    Address VARCHAR(255),
    City VARCHAR(100),
    State VARCHAR(2),
    Zip_Code VARCHAR(10),
    County VARCHAR(100),
    Phone_Number VARCHAR(15)
);



-- Create Conditions Table
CREATE TABLE Conditions (
    Condition_Code VARCHAR(50) PRIMARY KEY,
    Condition_Name VARCHAR(255)
);

-- Create Readmission_Rates Table
CREATE TABLE Readmission_Rates (
    Hospital_ID INT,
    Condition_Code VARCHAR(50),
    Readmission_Status VARCHAR(255),
    National_Rate DECIMAL(5, 2),
    Lower_Estimate DECIMAL(5, 2),
    Higher_Estimate VARCHAR(50),
    Data_Availability VARCHAR(50),
    Start_Date DATE,
    End_Date DATE,
    FOREIGN KEY (Hospital_ID) REFERENCES Michigan_Hospitals(Hospital_ID),
    FOREIGN KEY (Condition_Code) REFERENCES Conditions(Condition_Code)
);

SELECT 
    Hospital_ID,
    Readmission_Status,
    COUNT(*) AS Status_Count
FROM 
    Readmission_Rates
GROUP BY 
    Hospital_ID, Readmission_Status
ORDER BY 
    Hospital_ID, Status_Count DESC;



-- INSERTING DATA BASED ON SOURCE TABLE
INSERT INTO Michigan_Hospitals(Hospital_ID, Hospital_Name, Address, City, State, Zip_Code, County, Phone_Number)
SELECT DISTINCT 
`Facility ID`, 
`Facility Name`, 
Address, 
`City/Town`, 
State, 
`ZIP Code`, 
`County/Parish`, 
`Telephone Number`
FROM michigan_hospital_readmission_2024;

INSERT INTO Conditions (Condition_Code, Condition_Name)
SELECT DISTINCT `Measure Id`, `Measure Name`
FROM michigan_hospital_readmission_2024;


INSERT INTO Readmission_Rates (Hospital_ID, Condition_Code, Readmission_Status, National_Rate, Lower_Estimate, Higher_Estimate, Data_Availability, Start_Date, End_Date)
SELECT 
    s.`Facility ID`, 
    s.`Measure ID`, 
    s.`Compared to National`, 
    -- Handling empty or invalid values for decimal conversion
    CASE 
        WHEN TRIM(s.`Score`) = '' OR s.`Score` = '0' OR NOT s.`Score` REGEXP '^[0-9]+(\.[0-9]+)?$' THEN NULL
        ELSE CAST(s.`Score` AS DECIMAL(5, 2))
    END, 
    -- Handling empty or invalid values for decimal conversion
    CASE 
        WHEN TRIM(s.`Lower Estimate`) = '' OR s.`Lower Estimate` = '0' OR NOT s.`Lower Estimate` REGEXP '^[0-9]+(\.[0-9]+)?$' THEN NULL
        ELSE CAST(s.`Lower Estimate` AS DECIMAL(5, 2))
    END, 
    s.`Higher Estimate`, 
    s.`Footnote`, 
    STR_TO_DATE(s.`Start Date`, '%m/%d/%Y'), 
    STR_TO_DATE(s.`End Date`, '%m/%d/%Y')
FROM `michigan_hospital_readmission_2024` s
JOIN Michigan_Hospitals h ON s.`Facility ID` = h.Hospital_ID
JOIN Conditions c ON s.`Measure ID` = c.Condition_Code;

SELECT * FROM Michigan_Hospitals;
SELECT * FROM Conditions;
SELECT * FROM Readmission_Rates;
SELECT * FROM Michigan_Hospitals;

