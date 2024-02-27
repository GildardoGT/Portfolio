-- ----------------------------------------------------------------
--                      Database Creation
-- ----------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS data_standardization;
USE data_standardization;
SET sql_safe_updates = 0;  -- Safe mode for future updates | 0 = ON | 1 = OFF
-- ----------------------------------------------------------------
--                      Clean table creation
-- ----------------------------------------------------------------
CREATE TABLE clean_data AS SELECT * FROM raw_data;

-- ----------------------------------------------------------------
--                 Stored procedure creation
-- ----------------------------------------------------------------
DELIMITER //
CREATE PROCEDURE sample_data()
BEGIN SELECT * FROM clean_data Limit 5; END //
DELIMITER ;
CALL sample_data;  -- Function to call procedure:

-- ----------------------------------------------------------------
--                      Rename columns
-- ----------------------------------------------------------------
DESCRIBE clean_data;                                                      -- View data type
ALTER TABLE clean_data_noduplicates CHANGE COLUMN `id_empleado` id_emp varchar(20) null;
ALTER TABLE clean_data MODIFY COLUMN `name` TEXT NULL;                    -- Format modification
ALTER TABLE clean_data CHANGE COLUMN `name` name TEXT NULL;               -- Name modification
ALTER TABLE clean_data CHANGE COLUMN `Apellido` last_name TEXT NULL;
ALTER TABLE clean_data CHANGE COLUMN `gÃ©nero` gender TEXT NULL;
ALTER TABLE clean_data CHANGE COLUMN `star_date` start_date TEXT NULL;
CALL sample_data;

-- ----------------------------------------------------------------
--                     Duplicate verification
-- ----------------------------------------------------------------
-- 1. To know which ids are duplicated
SELECT id_emp, COUNT(*) AS number_duplicates FROM clean_data 
GROUP BY id_emp  -- Group by the column id_employee
HAVING COUNT(*) > 1;  -- Apply condition to show groups with +1 duplicated id_emp

-- 2. Apply condition to show groups with +1 duplicate id_employee
SELECT COUNT(*) as total_data
 FROM (SELECT id_emp, COUNT(*) AS number_duplicates FROM clean_data 
 GROUP BY id_emp
 HAVING COUNT(*) > 1) as total_data 
  
-- 3. Create a temporary table without duplicates
CREATE TEMPORARY TABLE clean_data_temp AS
SELECT DISTINCT *
FROM clean_data;

-- 4. Create a new table without duplicates
CREATE TABLE clean_data_noduplicates AS SELECT * FROM clean_data_temp;

-- 5. Verify that our new table does not have duplicates
SELECT id_emp, COUNT(*) AS number_duplicates FROM clean_data_noduplicates
GROUP BY id_emp  -- Agrupar por la columna id_empleado
HAVING COUNT(*) > 1; 

-- 6. Count the total new number 
SELECT COUNT(*) from clean_data_noduplicates; -- Before: 22,223 Now: 22,214

-- Drop the previous table (In this case, we omit this to save it for further study)
-- DROP TABLE clean_data;

call sample_data;

-- ----------------------------------------------------------------
--             Remove spaces before and after the text
-- ----------------------------------------------------------------
--               <CONDITION BEFORE UPDATING IN REAL>

-- 1. Testing condition to show names with spaces
-- Condition, LENGTH(name): Number of letters including spaces
-- Condition, LENGTH(TRIM(name)): Number of letters without spaces
-- Condition, WHERE (...)> 0 = Total - Total without spaces > 0 = There were spaces so print that name
SELECT name, TRIM(name) AS clean_name      --  It shows two columns, name and the new Name
FROM clean_data_noduplicates               --  Takes data from table without duplicates
WHERE LENGTH(name) - LENGTH(TRIM(name)) > 0;  


-- 2. Condition tested, we update new column without spaces
SET sql_safe_updates = 0;                           -- Disable safe mode
                         
UPDATE clean_data_noduplicates SET name = TRIM(name) -- SET: Select the column to modify
WHERE LENGTH(name) - LENGTH(TRIM(name)) > 0;  

-- 3. Verify that the spaces have been removed
SELECT name, TRIM(name) AS clean_name      
FROM clean_data_noduplicates               
WHERE LENGTH(name) - LENGTH(TRIM(name)) > 0; 

-- 4. do the same with the other columns.
SELECT name, TRIM(name) AS clean_last_name     
FROM clean_data_noduplicates               
WHERE LENGTH(last_name) - LENGTH(TRIM(last_name)) > 0;  

SET sql_safe_updates = 0;      
                     
UPDATE clean_data_noduplicates SET last_name = TRIM(last_name) 
WHERE LENGTH(last_name) - LENGTH(TRIM(last_name)) > 0;  

SELECT * FROM clean_data_noduplicates -- Final query to verify


-- ----------------------------------------------------------------
--           Replace data name in the column.
-- ----------------------------------------------------------------
--          <CONDITION BEFORE UPDATING IN REAL>
-- 1. We test the replacement condition.
SELECT gender,     -- We specify the two columns to display, "gender" and "clean_gender" (which is the result of the case).
CASE
    WHEN gender = 'hombre' THEN 'Male'
    WHEN gender = 'mujer' THEN 'Female'
    ELSE 'Other'
END AS clean_gender
FROM clean_data_noduplicates;

-- 2. Condition tested, now we replace.
UPDATE clean_data_noduplicates SET gender = CASE -- We select the only column to be modified, "gender".
    WHEN gender = 'hombre' THEN 'Male'
    WHEN gender = 'mujer' THEN 'Female'
    ELSE 'Other'
END;

-- 3. We review the modification.
SELECT * FROM clean_data_noduplicates;

-- ----------------------------------------------------------------
--       Replace meaningless information with meaningful one 
-- ----------------------------------------------------------------
-- type: 1: Remote  2: Hybrid

-- 1. We review the data type to be modified.
DESCRIBE clean_data_noduplicates;

-- 2. We modify the data type from integer to text
ALTER TABLE clean_data_noduplicates MODIFY COLUMN type TEXT;

-- 3. We test the replacement condition.
SELECT type,       -- We specify the two columns to display, "type" and "clean_type" (which is the result of the case).
CASE
    WHEN type = 1 THEN 'Remote'
    WHEN gender = 0 THEN 'Hybrid'
    ELSE 'Other'
END AS clean_type   -- This only serves to name the result of the case.
FROM clean_data_noduplicates;

-- 4. Condition tested, we replace in the original table.
UPDATE clean_data_noduplicates SET type = CASE
    WHEN type = 1 THEN 'Remote'
    WHEN gender = 0 THEN 'Hybrid'
    ELSE 'Other'
END;
-- We verify the change
SELECT * FROM clean_data_noduplicates;

-- ----------------------------------------------------------------
--       Adjustment of number/text format.
-- ----------------------------------------------------------------

-- 1. How it should be in text to modify the numbers, we verify that the data type is TEXT, in case
-- it is not, modify from INT to TEXT
DESCRIBE clean_data_noduplicates;

-- 2. We test the condition once we are sure it is of text type
SELECT salary, CAST(TRIM(REPLACE(REPLACE(salary, '$', ''), ',', '')) AS DECIMAL(15, 2)) AS clean_salary from clean_data_noduplicates;
-- 2.1 Replace the '$' in the column with a space
-- 2.2 Replace the ',' in the column with a space
-- 2.3 Verify that there are no leading or trailing spaces
-- 2.4 Give it a format of up to 15 numbers with two decimals
-- 2.5 Save the result in another column named "clean salary"
-- 2.6 With the select, we specify that we will print salary, clean salary (new column)

-- 3. We update the table with the tested condition.
UPDATE clean_data_noduplicates  -- For the salary column, we will set the condition = ...
SET salary = CAST(TRIM(REPLACE(REPLACE(salary, '$', ''), ',', '')) AS DECIMAL(15, 2));  -- It doesn't require a FROM clause because it's an UPDATE.

-- 4. We convert to data type INT.
ALTER TABLE clean_data_noduplicates MODIFY COLUMN salary INT NULL;

-- 5. We verify the new data type.
DESCRIBE clean_data_noduplicates 

-- 6. We verify that the new information is updated.
SELECT * FROM clean_data_noduplicates;

-- ----------------------------------------------------------------
--                   Time format adjustment.
-- ----------------------------------------------------------------
CALL sample_data;
-- 1. We verify that it has TEXT format before adjusting the format to date type.
DESCRIBE clean_data_noduplicates;

-- 2. We verify that our conditional function works.
SELECT 
    birth_date,                                                                  -- We print two columns, birthday and the result of the case.
    CASE 
        WHEN INSTR(birth_date, '-') > 0 THEN STR_TO_DATE(birth_date, '%m-%d-%Y') -- Check if the date contains '-' or '/'.
        WHEN INSTR(birth_date, '/') > 0 THEN STR_TO_DATE(birth_date, '%m/%d/%Y') -- If it contains '-', or '/', convert it to MySQL format 'YYYY-MM-DD' with STR_TO_DATE().
        ELSE 'Unrecognized format'
    END AS fecha_convertida
FROM 
    clean_data_noduplicates;
    
-- 3. Once the condition is verified, we update it in the original table.
SET sql_safe_updates = 0;                                                         -- We turn off strict mode for updating.
UPDATE clean_data_noduplicates SET birth_date =  CASE                             -- We set the birth_date column to be updated with the result of the case.
        WHEN INSTR(birth_date, '-') > 0 THEN STR_TO_DATE(birth_date, '%m-%d-%Y') 
        WHEN INSTR(birth_date, '/') > 0 THEN STR_TO_DATE(birth_date, '%m/%d/%Y') 
        ELSE 'Unrecognized format'
    END;
-- 4. We verify the new change.
SELECT * FROM clean_data_noduplicates;

-- 5. We perform the same procedure for the other dates.
-- 5.1 We test the condition. 
SELECT start_date,                                                                 
    CASE 
        WHEN INSTR(start_date, '-') > 0 THEN STR_TO_DATE(start_date, '%m-%d-%Y') 
        WHEN INSTR(start_date, '/') > 0 THEN STR_TO_DATE(start_date, '%m/%d/%Y') 
        ELSE 'Unrecognized format'
    END AS clean_start_date
FROM 
    clean_data_noduplicates;
-- 5.2 We update the table permanently.
UPDATE clean_data_noduplicates SET start_date =  CASE                             
        WHEN INSTR(start_date, '-') > 0 THEN STR_TO_DATE(start_date, '%m-%d-%Y') 
        WHEN INSTR(start_date, '/') > 0 THEN STR_TO_DATE(start_date, '%m/%d/%Y') 
        ELSE 'Unrecognized format'
    END;
-- 5.3 We verify the change.
SELECT * FROM clean_data_noduplicates;


-- ----------------------------------------------------------------
--       Time format adjustment WITH H,M,S.
-- ----------------------------------------------------------------
-- This time, the exact time when the contract ended is irrelevant, so we only keep the date.
-- If there's no end date, it means the employee is still working, so we fill in the information.

-- 1. Verify that the format type is TEXT.
DESCRIBE clean_data_noduplicates;

-- 2. We test the settings for removing blanks by NULL and date correction. 
SELECT  finish_date,                                    -- We show two columns 
    CASE 
        WHEN finish_date IS NULL THEN NULL             -- If there is a space with NULL then it is set to NULL
        WHEN TRIM(finish_date) = '' THEN NULL          -- If there is an empty space, TRIM deletes it, and then deleted it with NULL 
        ELSE DATE_FORMAT(finish_date, '%Y-%m-%d')      -- If there are no blanks or NULL, then it means there is a date, we convert to the correct format with DATE_FORMAT(finish_date, '%Y-%m-%d')
    END AS clean_finish_date
FROM 
    clean_data_noduplicates;

-- 3. We apply the condition: Before the update, the text we want to transform must be extracted.

UPDATE clean_data_noduplicates                         -- Select the table to be modified
SET finish_date =                                      -- Column to be modified with the result of the case
    CASE                                               
        WHEN finish_date IS NULL THEN NULL
        WHEN TRIM(finish_date) = '' THEN NULL
        -- We extract from the finish_date column the string before the space ' ', and give it the format Y-M-D
        ELSE DATE_FORMAT(SUBSTRING_INDEX(finish_date, ' ', 1), '%Y-%m-%d')  
    END;
    
SELECT * FROM clean_Data_noduplicates;	
SELECT * FROM raw_data;
