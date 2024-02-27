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
ALTER TABLE clean_data CHANGE COLUMN `id_empleado` id_employee varchar(20) null;
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
SELECT id_empleado, COUNT(*) AS number_duplicates FROM clean_data 
GROUP BY id_empleado  -- Group by the column id_employee
HAVING COUNT(*) > 1;  -- Aplicar condicion de mostrar grupos con +1 id_empleado duplicado 

-- 2. Apply condition to show groups with +1 duplicate id_employee
SELECT COUNT(*) as total_data
 FROM (SELECT id_empleado, COUNT(*) AS number_duplicates FROM clean_data 
 GROUP BY id_empleado  
 HAVING COUNT(*) > 1) as total_data 
  
-- 3. Creo una tabla temporal sin duplicados
CREATE TEMPORARY TABLE clean_data_temp AS
SELECT DISTINCT *
FROM clean_data;

-- 4. Creo tabla nueva sin duplicados
CREATE TABLE clean_data_noduplicates AS SELECT * FROM clean_data_temp;

-- 5. Verificamos que nuestra nueva tabla no tenga duplicados
SELECT id_empleado, COUNT(*) AS number_duplicates FROM clean_data_noduplicates
GROUP BY id_empleado  -- Agrupar por la columna id_empleado
HAVING COUNT(*) > 1; 

-- 6. Contamos el numero de total nuevo 
SELECT COUNT(*) from clean_data_noduplicates; -- Antes: 22,223 Ahora: 22,214

-- 7. Eliminamos la tabla anterior (En este caso omitimos esto para guardarla para el caso de estudio)
-- DROP TABLE clean_data;

call sample_data;

-- ----------------------------------------------------------------
--             Eliminar espacios antes y despues del texto
-- ----------------------------------------------------------------
--               <CONDICION ANTES DE ACTUALIZAR EN REAL> 

-- 1. Probamos condicion para mostrar nombres con espacios
-- Condicion, LENGTH(name): Numero de letras contando espacios 
-- Condicion, LENGTH(TRIM(name)): Numero de letras sin espacios ya 
-- Condicion, WHERE (...)> 0  = Total - Total sin espacios > 0 = Habia espacios asi que imprimes ese nombre
SELECT name, TRIM(name) AS clean_name      -- Me muestra dos columna, name y la nueva Name
FROM clean_data_noduplicates               -- Toma datos desde tabla sin duplicados
WHERE LENGTH(name) - LENGTH(TRIM(name)) > 0;  


-- 2. Condicion, probada, actualizamos nuevo columna sin espacios
SET sql_safe_updates = 0;                            -- Quitamos modo seguro
UPDATE clean_data_noduplicates SET name = TRIM(name) -- SET: Selecciona la columana modificar 
WHERE LENGTH(name) - LENGTH(TRIM(name)) > 0;  

-- 3. Verificamos que se hayan eliminados los espacios
SELECT name, TRIM(name) AS clean_name      
FROM clean_data_noduplicates               
WHERE LENGTH(name) - LENGTH(TRIM(name)) > 0; 

-- 4. Realizamos lo mismo con las demas columnas
SELECT name, TRIM(name) AS clean_last_name     
FROM clean_data_noduplicates               
WHERE LENGTH(last_name) - LENGTH(TRIM(last_name)) > 0;  

SET sql_safe_updates = 0;                           
UPDATE clean_data_noduplicates SET last_name = TRIM(last_name) 
WHERE LENGTH(last_name) - LENGTH(TRIM(last_name)) > 0;  

SELECT * FROM clean_data_noduplicates -- Connsulta final para verificar


-- ----------------------------------------------------------------
--           Remplazar nombre de datos en la columna 
-- ----------------------------------------------------------------
--               <CONDICION ANTES DE ACTUALIZAR EN REAL> 
-- 1. Probamos condicion de remplazo
SELECT gender,     -- Especificamos las dos columnas a mostrar, "gender" y "clean_gener" (Que es el resultado del case)
CASE
    WHEN gender = 'hombre' THEN 'Male'
    WHEN gender = 'mujer' THEN 'Female'
    ELSE 'Other'
END AS clean_gender
FROM clean_data_noduplicates;

-- 2. Condcion probada, ahora remplazamos
UPDATE clean_data_noduplicates SET gender = CASE -- Seleccionamos la unica columna que se modificara "gender"
    WHEN gender = 'hombre' THEN 'Male'
    WHEN gender = 'mujer' THEN 'Female'
    ELSE 'Other'
END;

-- 3. Revisamos la modificacion
SELECT * FROM clean_data_noduplicates;

-- ----------------------------------------------------------------
--       Remplazar informacion sin sentido con una con sentido 
-- ----------------------------------------------------------------
-- type: 1: Contrato Remoto  2: 

-- 1. Revisamos el tipo de dato a modificar
DESCRIBE clean_data_noduplicates;

-- 2. Modificamos el tipo de dato int --> texto-
ALTER TABLE clean_data_noduplicates MODIFY COLUMN type TEXT;

-- 3. Probamos condicion de remplazo 
SELECT type,       -- Especificamos las dos columnas a mostrar, "type" y "clean_type" (Que es el resultado del case)
CASE
    WHEN type = 1 THEN 'Remote'
    WHEN gender = 0 THEN 'Hybrid'
    ELSE 'Other'
END AS clean_type   -- Esto solo nos sirve para nombrar el resultado del case 
FROM clean_data_noduplicates;

-- 4. Probada la condicion, remplazamos en tabla original
UPDATE clean_data_noduplicates SET type = CASE
    WHEN type = 1 THEN 'Remote'
    WHEN gender = 0 THEN 'Hybrid'
    ELSE 'Other'
END;
-- 5. Verificamos el cambio
SELECT * FROM clean_data_noduplicates;

-- ----------------------------------------------------------------
--       Ajuste de formato de numeros/texto
-- ----------------------------------------------------------------

-- 1. Como debe estar en texto para modificar los numeros, verificamos que el tipo de dato es TEXTO, en caso
-- de que no, modificar a de INT a TEXTO
DESCRIBE clean_data_noduplicates;

-- 2. Probamos la condicion una ves al tener certeza que es tipo texto
SELECT salary, CAST(TRIM(REPLACE(REPLACE(salary, '$', ''), ',', '')) AS DECIMAL(15, 2)) AS clean_salary from clean_data_noduplicates;
-- 2.1 Remplaza los $ de la columna con espacio 
-- 2.2 Remplaza las ',' de la columna con espacio
-- 2.3 Verifica que no haya espacio al incio o al final 
-- 2.4 Le da un formato de hasta 15 numeros con dos decimales
-- 2.5 Guardamos el resultado en otra columna llamada "clean salary"
-- 2.6 Con el select especificamos que imprimiremos salary, clean salary (columna nueva)

-- 3.Acualizamos la tabla con la condicion probada
UPDATE clean_data_noduplicates  -- De la columna salary, pondremos la condicion = ...
SET salary = CAST(TRIM(REPLACE(REPLACE(salary, '$', ''), ',', '')) AS DECIMAL(15, 2));  -- No lleva FROM porque es un UPDATE

-- 4. Convertimos a datos tipo INT
ALTER TABLE clean_data_noduplicates MODIFY COLUMN salary INT NULL;

-- 5. Verificamos el nuevo tipo de dato
DESCRIBE clean_data_noduplicates 

-- 6. Verificamos que la informacion nueva este actualizada
SELECT * FROM clean_data_noduplicates;

-- ----------------------------------------------------------------
--       Ajuste de formato de tiempo 
-- ----------------------------------------------------------------
CALL sample_data;
-- 1. Verificamos que tenga formato TEXT antes de el ajuste de formato a tipo fecha
DESCRIBE clean_data_noduplicates;

-- 2. Verificamos que nuestra funcion condicion funcione 
SELECT 
    birth_date,                                                                  -- Imprimimos dos columnas, birthday y el resultado del case
    CASE 
        WHEN INSTR(birth_date, '-') > 0 THEN STR_TO_DATE(birth_date, '%m-%d-%Y') -- Verificar si la fecha contiene '-' o '/'.
        WHEN INSTR(birth_date, '/') > 0 THEN STR_TO_DATE(birth_date, '%m/%d/%Y') -- Si contiene '-', o '/' convertir al formato MySQL 'YYYY-MM-DD' con STR_TO_DATE().
        ELSE 'Unrecognized format'
    END AS fecha_convertida
FROM 
    clean_data_noduplicates;
    
-- 3. Comprobada la condicion, actualizamos en la tabla original 
SET sql_safe_updates = 0;                                                         -- Apagamos el modo seguro para actualizar 
UPDATE clean_data_noduplicates SET birth_date =  CASE                             -- Establecemos que la columna birth_date sea actualizara con el resultado del case 
        WHEN INSTR(birth_date, '-') > 0 THEN STR_TO_DATE(birth_date, '%m-%d-%Y') 
        WHEN INSTR(birth_date, '/') > 0 THEN STR_TO_DATE(birth_date, '%m/%d/%Y') 
        ELSE 'Unrecognized format'
    END;
-- 4. Verificamos el nuevo cambio
SELECT * FROM clean_data_noduplicates;

-- 5. Realizamos el mismo procedimiento para las demas fechas 
-- 5.1 Probamos condicion 
SELECT start_date,                                                                 
    CASE 
        WHEN INSTR(start_date, '-') > 0 THEN STR_TO_DATE(start_date, '%m-%d-%Y') 
        WHEN INSTR(start_date, '/') > 0 THEN STR_TO_DATE(start_date, '%m/%d/%Y') 
        ELSE 'Unrecognized format'
    END AS clean_start_date
FROM 
    clean_data_noduplicates;
-- 5.2 Actualizamos tabla permanentemente 
UPDATE clean_data_noduplicates SET start_date =  CASE                             
        WHEN INSTR(start_date, '-') > 0 THEN STR_TO_DATE(start_date, '%m-%d-%Y') 
        WHEN INSTR(start_date, '/') > 0 THEN STR_TO_DATE(start_date, '%m/%d/%Y') 
        ELSE 'Unrecognized format'
    END;
-- 5.3 Verificamos el cambio
SELECT * FROM clean_data_noduplicates;


-- ----------------------------------------------------------------
--       Ajuste de formato de tiempo CON H,M,S
-- ----------------------------------------------------------------
-- En esta ocacion la hora es irrelevante de cuando fue la hora del contrato terminado, asi que solo nos quedamos con la fecha
-- Quien no tenga fecha de salida, signficia que esta trabajando aun, asi que rellenamos la infomacion

-- 1. Verificamos que el tipo de formato sea TEXT
DESCRIBE clean_data_noduplicates;

-- 2. Probamos la conficion de eliminar espacios vacios por NULL y correccion de fechas 
SELECT  finish_date,                                    -- Mostramos dos columnas 
    CASE 
        WHEN finish_date IS NULL THEN NULL             -- Si hay un espacio con NULL entonces le pone un NULL 
        WHEN TRIM(finish_date) = '' THEN NULL          -- Si hay un espacio vacio, TRIM lo elimina, y luego eliminado le pone un NULL 
        ELSE DATE_FORMAT(finish_date, '%Y-%m-%d')      -- Si no hay espacios vacios o NULL, entonces signifca que hay una fecha, convertimos al formato correcto con  DATE_FORMAT(finish_date, '%Y-%m-%d')
    END AS clean_finish_date
FROM 
    clean_data_noduplicates;

-- 3. Aplicamos la condicionn: Antes de la actualizacion se debe extraer el texto que queremos transformar

UPDATE clean_data_noduplicates                         -- Elegimos tabla a modificar
SET finish_date =                                      -- Columna a modificar con el resultado del case
    CASE                                               
        WHEN finish_date IS NULL THEN NULL
        WHEN TRIM(finish_date) = '' THEN NULL
        -- Extraemos de la columna finish_date la cadena antes del espacio ' ', y le damos el formato Y-M-D
        ELSE DATE_FORMAT(SUBSTRING_INDEX(finish_date, ' ', 1), '%Y-%m-%d')  
    END;
    
SELECT * FROM clean_Data_noduplicates;
SELECT * FROM raw_data;
