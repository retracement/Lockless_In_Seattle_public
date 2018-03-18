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

-- Transition database to allow SNAPSHOT isolation (on-disk)
USE master;
GO
ALTER DATABASE [Lockless_In_Seattle] 
	SET ALLOW_SNAPSHOT_ISOLATION ON --Note this is only needed for on-disk snapshot!
GO



/******************************************************/
/* Write Governance On-Disk Optimistic (Connection 1) */
/******************************************************/
-- Update Last Vegas population On-Disk table
USE Lockless_In_Seattle
GO
IF @@TRANCOUNT > 0 ROLLBACK
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
BEGIN TRAN
	UPDATE cities
		SET population = population + 1 
		WHERE [name] = 'Las Vegas'


-- Switch to connection 2



/********************************************************/
/* Write Governance In-Memory Optimistic (Connection 1) */
/********************************************************/
-- Update Last Vegas population In-Memory table
-- (Demonstrate updating the same record)

-- Rollback any open transactions
IF @@TRANCOUNT > 0 ROLLBACK

-- Revert to default isolation level
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRAN
	UPDATE citiesim -- in memory oltp table
		WITH (SNAPSHOT) -- note this hint only valid syntax for upd with IM tables
		SET population = population + 1
		WHERE [name] = 'Las Vegas'



-- Switch to connection 2



-- Update Texas population In-Memory table
-- (Demonstrate updating the same record at different intervals)
IF @@TRANCOUNT > 0 ROLLBACK
BEGIN TRAN
	UPDATE citiesim 
		WITH (SNAPSHOT)
		SET population = population + 1
		WHERE State = 'Texas' --19 rows updated


-- Switch to connection 2


	-- Now update the already updated record!
	UPDATE citiesim 
		WITH (SNAPSHOT)
		SET population = population + 1 
		WHERE [name] = 'Las Vegas'

/* Presenters note: Very quick and efficient termination of conflicted */
/* transaction, however is obviously important to avoid write conflict */
/* (especially if you have large number of transactional changes!)     */
/* In other-words transaction that did the most work doesn't           */
/* necessarily win! */