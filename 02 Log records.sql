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

/*******************/
/* On-Disk Logging */
/*******************/
-- See how many log records exist in the SQL Server transaction log
-- for the on-disk Cities table
USE Lockless_In_Seattle
GO
-- Clear on-disk table and re-load to generate log records
TRUNCATE TABLE Cities
-- Insert 151 records into the ondisk table
EXEC usp_PopulateCities 

DECLARE @TransactionID NVARCHAR(14)
DECLARE @CurrentLSN NVARCHAR(23)

-- Look at the log and return topmost on-disk transaction
-- Find [Transaction ID] for most recent LOP_INSERT_ROWS record
SELECT TOP 1 @TransactionID =
        [Transaction ID], @CurrentLSN = [Current LSN]
	FROM    sys.fn_dblog(NULL, NULL)
	WHERE   Operation = 'LOP_INSERT_ROWS' --the on-disk logical insert record
	ORDER BY [Current LSN] DESC;

SELECT  *
	FROM    sys.fn_dblog(NULL, NULL)
	WHERE   [Transaction ID] = @TransactionID
	ORDER BY [Current LSN] DESC;
GO



/*********************/
/* In-Memory Logging */
/*********************/
-- See how many log records exist in the SQL Server transaction log
-- for the in-memory CitiesIM table

-- Clear in-memory table and re-load to generate log records
DELETE FROM CitiesIM
-- Insert 151 records into the in-memory table
EXEC  usp_PopulateCitiesIM

DECLARE @TransactionID NVARCHAR(14)
DECLARE @CurrentLSN NVARCHAR(23)

-- Look at the log and return topmost In-Memory OLTP transaction
-- Find [Transaction ID] & [Current LSN] for most recent LOP_HK record
SELECT TOP 1 @TransactionID =
        [Transaction ID], @CurrentLSN = [Current LSN]
	FROM    sys.fn_dblog(NULL, NULL)
	WHERE   Operation = 'LOP_HK' --the hekaton logical op record
	ORDER BY [Current LSN] DESC;

SELECT 
	@TransactionID AS '[Transaction ID]',
	@CurrentLSN AS '[Current LSN]'

-- Show those log records for [Transaction ID] of the LOP_HK
SELECT  *
	FROM    sys.fn_dblog(NULL, NULL)
	WHERE   [Transaction ID] = @TransactionID;

-- Break open log record for Hekaton log record LSN
SELECT  
	[Current LSN],
	[Transaction ID],
	Operation,
	operation_desc,
	tx_end_timestamp,
	total_size,
	OBJECT_NAME(table_id) AS TableName
	FROM    sys.fn_dblog_xtp(NULL, NULL)
	WHERE   [Current LSN] = @CurrentLSN; 
GO
