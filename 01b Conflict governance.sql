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

/******************************************************/
/* Write Governance On-Disk Optimistic (Connection 2) */
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



-- Stop execution (because session is blocked)
-- Switch to connection 1



/********************************************************/
/* Write Governance In-Memory Optimistic (Connection 2) */
/********************************************************/
-- Update Last Vegas population In-Memory table
-- (Demonstrate updating the same record)

-- Rollback any open transactions
IF @@TRANCOUNT > 0 ROLLBACK

-- Revert to default isolation level
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

BEGIN TRAN
	UPDATE citiesim 
		WITH (SNAPSHOT)
		SET population = population + 1 
		WHERE [name] = 'Las Vegas'



-- Switch to connection 1



-- Update Last Vegas population In-Memory table
-- (Demonstrate updating the same record at different intervals)
IF @@TRANCOUNT > 0 ROLLBACK
BEGIN TRAN
	UPDATE citiesim 
		WITH (SNAPSHOT)
		SET population = population + 1 
		WHERE [name] = 'Las Vegas'



-- Switch to connection 1



IF @@TRANCOUNT > 0 ROLLBACK