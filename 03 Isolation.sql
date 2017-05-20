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
/*
-- ensure this is turned off
ALTER DATABASE Lockless_In_Seattle SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = OFF
*/

--We are going to look at using in-memory tables under different isolation levels


-- Can we run an autocommit transaction
USE [Lockless_In_Seattle]
GO
SELECT * FROM LandmarksIM
GO



-- Lets try this as an explicit transaction
-- Will this work?
USE [Lockless_In_Seattle]
GO
BEGIN TRAN
	SELECT * FROM LandmarksIM
ROLLBACK



-- Lets repeat as an explicit transaction
-- by setting the session isolation level to snapshot
-- Will this work?
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
USE [Lockless_In_Seattle]
GO
BEGIN TRAN
	SELECT * FROM LandmarksIM
ROLLBACK
GO
SET TRANSACTION ISOLATION LEVEL READ COMMITTED



-- Lets try as an explicit transaction with SNAPSHOT HINT
-- Will this work?
USE [Lockless_In_Seattle]
GO
BEGIN TRAN
	--lock hint only used on imoltp
	SELECT * FROM LandmarksIM WITH (SNAPSHOT)
ROLLBACK
/* Presenters note: Interesting that the use of the SNAPSHOT  */
/* hint might indicate that snapshot duration is only for     */
/* the statement duration. This clearly would not make sense  */
/* for SNAPSHOT tran, & scope *is* for the duration of the    */
/* transaction. Scope similar to statement Serializable hints */
/* e.g.
-- Transaction1
BEGIN TRAN
	SELECT * FROM LandmarksIM WITH (SNAPSHOT) --returns result set 1
	-- (Another transaction) Transaction2 updates a row (in new connection)
	SELECT * FROM LandmarksIM WITH (SNAPSHOT) --returns SAME result set 1
COMMIT
*/



-- Lets also try this as an explicit transaction
-- with the REPEATABLEREAD HINT and SERIALIZABLE HINT
USE [Lockless_In_Seattle]
GO
BEGIN TRAN
	SELECT * FROM LandmarksIM WITH (REPEATABLEREAD)
	SELECT * FROM LandmarksIM WITH (SERIALIZABLE)
ROLLBACK



-- Lets try through an implicit transaction
SET IMPLICIT_TRANSACTIONS ON;
GO
SELECT  *
FROM    LandmarksIM;
GO
SET IMPLICIT_TRANSACTIONS OFF;
IF @@TRANCOUNT > 0
    ROLLBACK;
SELECT  @@trancount;



-- Turn on MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT
-- When this option is set to ON, access to a memory-optimized table under a lower 
-- isolation level is automatically elevated to SNAPSHOT isolation.
ALTER DATABASE Lockless_In_Seattle SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = ON

-- Lets now try this as an explicit transaction again
-- Will it still fail?
USE [Lockless_In_Seattle]
GO
BEGIN TRAN
	SELECT * FROM LandmarksIM
ROLLBACK

-- ensure this is turned back off
ALTER DATABASE Lockless_In_Seattle SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = OFF