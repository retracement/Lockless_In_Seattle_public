/************************************************************
*   All scripts contained within are Copyright © 2015 of    *
*   SQLCloud Limited, whether they are derived or actual    *
*   works of SQLCloud Limited or its representatives        *
*************************************************************
*   All rights reserved. No part of this work may be        *
*   reproduced or transmitted in any form or by any means,  *
*   electronic or mechanical, including photocopying,       *
*   recording, or by any information storage or retrieval   *
*   system, without the prior written permission of the     *
*   copyright owner and the publisher.                      *
************************************************************/

/****************/
/* Enable XTP   */
/****************/
USE [master]
GO
ALTER DATABASE Lockless_In_Seattle ADD FILEGROUP imoltp_mod
CONTAINS MEMORY_OPTIMIZED_DATA
USE [master]
GO



/***********************************************/
/* Add files (IMOLTP containers to filegroups) */
/***********************************************/
-- Add container1 - note: you cannot specify Initial size or autogrow settings.
ALTER DATABASE [Lockless_In_Seattle] 
	ADD FILE ( NAME = N'Lockless_In_Seattle_1', 
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\Lockless_In_Seattle_1') -- path for my SQL 2017 instance
	TO FILEGROUP [imoltp_mod]
GO

-- Add container2 - note: you cannot specify Initial size or autogrow settings.
ALTER DATABASE [Lockless_In_Seattle] 
	ADD FILE ( NAME = N'Lockless_In_Seattle_2', 
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\Lockless_In_Seattle_2') -- path for my SQL 2017 instance
	TO FILEGROUP [imoltp_mod]
GO
/* Presenters note: It used to be important to have an uneven # */
/* of containers for performance purposes since round-robin     */
/* could mean all data operations in one container and all delta*/
/* operations in another! This has now been fixed in 2016       */


-- Look at database properties/ Filegroups (note MEMORY OPTIMIZED DATA PANE)


-- Look at database properties/ file (note file type)


-- Manually add file (and notice initial size
-- AND max size/ autogrowth settings)
-- FILE ( NAME = N'Lockless_In_Seattle_3', 
-- FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\Lockless_In_Seattle_3') -- path to my SQL 2017 instance

	
-- Look at Process Explorer (on host) and search for term XTP
-- See anything? Why/ Why not?


/***************************/
/* Create In-Memory Tables */
/***************************/
USE [Lockless_In_Seattle]
GO

--create hash and range indexes
CREATE TABLE CharactersIM 
(CharacterID INT PRIMARY KEY NONCLUSTERED HASH 
	WITH (BUCKET_COUNT=8000) NOT NULL --bucket size compromises performance
	-- Bucket count (power of two), so 2^13 = 8192
,[Firstname] VARCHAR(50) COLLATE Latin1_General_100_BIN2 NOT NULL 
,[Surname] VARCHAR(50) COLLATE Latin1_General_100_BIN2 NOT NULL --collation requirement of columns in SQL2014 indexes
INDEX [idxFirstnameSurname] NONCLUSTERED (Firstname,Surname), --nci 1
INDEX [idxSurname] NONCLUSTERED (Surname) --nci 2
) WITH (MEMORY_OPTIMIZED=ON, --in-memory table
	DURABILITY = SCHEMA_AND_DATA) --default (or SCHEMA_ONLY)
GO

CREATE TABLE CitiesIM 
	(CityID INT PRIMARY KEY NONCLUSTERED HASH 
		WITH (BUCKET_COUNT=150) NOT NULL
	, [Name] VARCHAR(25), [State] VARCHAR(25)
	, [Population] BIGINT)
	WITH (MEMORY_OPTIMIZED=ON) 
GO

CREATE TABLE LandmarksIM 
	(LandMarkID INT PRIMARY KEY NONCLUSTERED HASH 
	WITH (BUCKET_COUNT=16) NOT NULL
	, Title VARCHAR(25), IsDestination bit) WITH (MEMORY_OPTIMIZED=ON) 
GO




/**********************************************/
/* Create Native Compilation Stored Procedure */
/**********************************************/
USE Lockless_In_Seattle
GO

CREATE PROCEDURE dbo.UpdateCharacter 
	@CurrentFName VARCHAR(50), @CurrentLName VARCHAR(50),
	@NewFName VARCHAR(50), @NewLName VARCHAR(50)
	WITH NATIVE_COMPILATION, -- native proc
	SCHEMABINDING, -- prevent drop
	EXECUTE AS OWNER -- execution context required either OWNER/SELF/USER
AS
	BEGIN ATOMIC WITH -- Create tran if no open or create savepoint
	(TRANSACTION ISOLATION LEVEL = SNAPSHOT, -- SERIALIZABLE or REPEATABLE READ
	LANGUAGE = N'british', -- language required
	DELAYED_DURABILITY = OFF, -- not required
	DATEFIRST = 7, -- not required
	DATEFORMAT = 'dmy' -- not required
	)
	UPDATE dbo.CharactersIM 
		SET Firstname = @NewFName, Surname = @NewLName
		WHERE Firstname = @CurrentFName AND Surname = @NewLName;
	END
GO
/* Presenters note: Delayed durability can be forced or allowed on database    */
/* via ALTER DATABASE … SET DELAYED_DURABILITY = { DISABLED | ALLOWED | FORCED */
/* using allowed means that native compilation procedure can use it through    */
/* DELAYED_DURABILITY = ON                                                     */



/***************/
/* Linked DLLS */
/***************/
-- Now look at Process Explorer on SQL Host & search for term XTP
-- Find anything? Notice the new DLLs!
-- There is 1 per IM table (3) & 1 per Native Comp SP (1)



-- Look at source
SELECT '\\server1\c$\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\xtp\5' AS SourceCode -- path for my SQL 2017 instance
-- Open file path 
-- Open C files in notepad++. See the obfuscation


-- Look at the three containers
-- See Lockless_In_Seattle_1, Lockless_In_Seattle_2 
-- and Lockless_In_Seattle_3 directories
SELECT '\\server1\c$\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\'  AS ContainerRoot -- path for my SQL 2017 instance
-- Open file path 


-- Look at checkpoint files
SELECT  *
FROM    sys.dm_db_xtp_checkpoint_files
--WHERE   state = 1
ORDER BY file_type_desc ,
        upper_bound_tsn;
/*
PRECREATED (available but no data),
UNDER CONSTRUCTION (being populated but no current chkpnt),
ACTIVE (populated closed container with inserts/deletes/chkpnts),
MERGE TARGET (consolidation target from other containers),
WAITING FOR LOG TRUNCATION (can be removed once log truncated)
*/


-- Load up data (required only for further demo)
EXEC  usp_PopulateLandmarksIM
EXEC  usp_PopulateCharactersIM
EXEC  usp_PopulateCities
EXEC  usp_PopulateCitiesIM 