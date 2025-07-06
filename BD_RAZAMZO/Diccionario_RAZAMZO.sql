
USE ISSSTE_CUE_DSBB -- BD a usar para generar el diccionario.


SELECT
		a.name [tabla], -- Nombre de la tabla 
		c.name [Columna], -- Nombre de la columna
		t.name [tipo], -- Tipo de dato que ocupa la columna

		-- Hacemos CASE, para averiguar si la columna almacena Int,Float..etc
		CASE
			WHEN t.name = 'int' OR t.name = 'bigint' OR t.name = 'smallint' OR t.name = 'tinyint' OR t.name = 'bit' OR t.name = 'decimal' OR t.name = 'numeric' OR t.name = 'float' THEN c.precision
			ELSE NULL
		END [Detalle],
		c.max_length, -- El maximo de longuitud de la columna

		-- Hacemos CASE, para averiguar si acepta NULL o No
		CASE
			WHEN c.is_nullable = 0 THEN 'NO'
			ELSE 'SI'
		END [Permite Nulls],

		--Hacemos CASE, para averiguar si el campo es auto incremental
		CASE
			when c.is_identity = 0 THEN 'NO'
			ELSE 'SI'
		END [Es Autoincremental],

		--Ocuparemos sys.extended_properties, para ver si hay alguna descripción de alguna de las columnas
		ep.value [Descripción],

		--Verificaremos si la tabla tiene relación con las otros
		f.ForeignKey, 
		f.ReferenceTableName, 
		f.ReferenceColumnName,

		--Subconsulta para traer SPs relacionados
		 (
			 SELECT STRING_AGG(o.name, ', ')
			 FROM sys.objects o
				JOIN sys.sql_modules m ON o.object_id = m.object_id
				WHERE o.type = 'P'
				AND m.definition LIKE '%' + a.name + '%'
		 ) AS [Procedimientos que usan la tabla],

		     -- Subconsulta para traer Vistas relacionadas
		 (
			SELECT STRING_AGG(v.name, ', ')
			FROM sys.views v
				JOIN sys.sql_modules m ON v.object_id = m.object_id
				WHERE m.definition LIKE '%' + a.name + '%'
		) AS [Vistas que usan la tabla]

		FROM sys.tables a   
		INNER JOIN sys.columns c on a.object_id= c.object_id 
		INNER JOIN sys.systypes t on c.system_type_id= t.xtype 
		INNER JOIN sys.objects d on a.object_id= d.object_id
		LEFT JOIN sys.extended_properties ep ON d.object_id = ep.major_id AND c.column_Id = ep.minor_id
		LEFT JOIN (SELECT 
				f.name AS ForeignKey,
				OBJECT_NAME(f.parent_object_id) AS TableName,
				COL_NAME(fc.parent_object_id,fc.parent_column_id) AS ColumnName,
				OBJECT_NAME (f.referenced_object_id) AS ReferenceTableName,
				COL_NAME(fc.referenced_object_id,fc.referenced_column_id) AS ReferenceColumnName
				FROM sys.foreign_keys AS f
				INNER JOIN sys.foreign_key_columns AS fc ON f.OBJECT_ID = fc.constraint_object_id) 	f ON f.TableName =a.name AND f.ColumnName =c.name
WHERE a.name <> 'sysdiagrams' 
ORDER BY a.name,c.column_Id

SELECT * FROM Campos


USE COLIMAACT;

SELECT 
    o.object_id,
    s.name AS esquema,
    o.name AS objeto,
    o.type_desc AS tipo_objeto,
    ep.value AS descripcion
FROM sys.objects o
INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
LEFT JOIN sys.extended_properties ep 
    ON o.object_id = ep.major_id AND ep.minor_id = 0 AND ep.name = 'MS_Description'
WHERE o.type IN ('U', 'V', 'P') -- 'U' = Tabla, 'V' = Vista, 'P' = Procedimiento almacenado
ORDER BY o.type_desc, s.name, o.name;