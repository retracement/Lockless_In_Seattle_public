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
ALTER DATABASE [Lockless_In_Seattle] 
	SET ALLOW_SNAPSHOT_ISOLATION ON --Note this is only needed for on-disk snapshot!
GO


/******************************************************/
/* Write Governance On-disk Optimistic (Connection 1) */
/******************************************************/
-- Update Last Vegas population On-Disk table
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
-- Revert to default
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

-- Update Last Vegas population In-Memory table
IF @@TRANCOUNT > 0 ROLLBACK
BEGIN TRAN
	UPDATE citiesim 
		WITH (SNAPSHOT) -- note this hint only valid syntax for upd with IM tables
		SET population = population + 1
		WHERE [name] = 'Las Vegas'



-- Switch to connection 2



-- Update Last Vegas population In-Memory table
IF @@TRANCOUNT > 0 ROLLBACK
BEGIN TRAN
	UPDATE citiesim 
		WITH (SNAPSHOT)
		SET population = population + 1
		WHERE State = 'Texas'



-- Switch to connection 2



	-- Now update the already updated record!
	UPDATE citiesim 
		WITH (SNAPSHOT)
		SET population = population + 1 
		WHERE [name] = 'Las Vegas'



/* Presenters note: Very quick and efficient termination     */
/* of conflicted transaction, however is obviously important */
/* to avoid write conflicts (especially if you have large    */
/* number of transactions                                    */