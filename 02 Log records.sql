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
 
 --insert 151 cities ondisk table
USE Lockless_In_Seattle
GO
EXEC  usp_PopulateCities



-- you will see that SQL Server logged 151 log records
USE Lockless_In_Seattle
GO
SELECT  *
FROM    sys.fn_dblog(NULL, NULL)
WHERE   PartitionId IN ( SELECT partition_id
                         FROM   sys.partitions
                         WHERE  object_id = OBJECT_ID('Cities') )
ORDER BY [Current LSN] ASC;
GO



--insert 151 cities in-memory table
USE Lockless_In_Seattle
GO
EXEC  usp_PopulateCitiesIM 



-- Note that SQL Server logged 3 log records this time
-- look at the log and return topmost In-Memory OLTP transaction
DECLARE @TransactionID NVARCHAR(14)
DECLARE @CurrentLSN NVARCHAR(23)

-- Find [Transaction ID] & [Current LSN] for most recent LOP_HK record
SELECT TOP 1 @TransactionID =
        [Transaction ID], @CurrentLSN = [Current LSN]
FROM    sys.fn_dblog(NULL, NULL)
WHERE   Operation = 'LOP_HK' --the hekaton logical op record
ORDER BY [Current LSN] DESC;

-- Show those log records for transaction id of the LOP_HK
SELECT  *
FROM    sys.fn_dblog(NULL, NULL)
WHERE   [Transaction ID] = @TransactionID;

-- Break open log record for Hekaton log record LSN
SELECT  [Current LSN] ,
        [Transaction ID] ,
        Operation ,
        operation_desc ,
        tx_end_timestamp ,
        total_size ,
        OBJECT_NAME(table_id) AS TableName
FROM    sys.fn_dblog_xtp(NULL, NULL)
WHERE   [Current LSN] = @CurrentLSN; 
GO
