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

/*************************/
/* In-Memory Table Types */
/*************************/

USE Lockless_In_Seattle
GO
CREATE TYPE dbo.Extras AS TABLE  
(  
   extra_id INT NOT NULL,  
   agent_id INT NOT NULL,  
   salaryprice MONEY NOT NULL,  

   PRIMARY KEY NONCLUSTERED (extra_id,agent_id),
   INDEX [IX_extra_id] HASH ([extra_id]) WITH ( BUCKET_COUNT = 8)
) WITH (MEMORY_OPTIMIZED=ON)    
GO  


-- Create a in-memory table variable and use it
DECLARE @sales Extras
INSERT INTO @sales VALUES (1,1,1000),(2,5,1011),(3,1,500),(4,7,6101),(5,9,789)

SELECT * FROM @sales