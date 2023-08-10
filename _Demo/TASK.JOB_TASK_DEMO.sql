SET DEFINE ON;

DECLARE
   TYPE t_TASK IS TABLE OF TASK%ROWTYPE INDEX BY BINARY_INTEGER;
   l_TASK t_TASK;
   i PLS_INTEGER := -1;
   v_first_id PLS_INTEGER := 100;

BEGIN
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
   i := i +1;
   l_TASK(i).task_id         := v_first_id + i;
   l_TASK(i).task_name       := 'JOB_TASK_DEMO_TAB01';
   l_TASK(i).task_desc       := 'POPULATE JOB_TASK_DEMO_TAB01';
   l_TASK(i).db_link         := 'NONE';
   l_TASK(i).src_system_name := 'NONE';
   l_TASK(i).stmt_type       := 'P';
   l_TASK(i).status          := 'N';
   l_TASK(i).DEST_TABLE      := 'JOB_TASK_DEMO_TAB01';
   l_TASK(i).DEST_SCHEMA     := SYS_CONTEXT('USERENV','CURRENT_USER');
   l_TASK(i).STATEMENT       := 'PKG_JOB_TASK_DEMO.JOB_TASK_DEMO_TAB01_P';
--------------------------------------------------------------------------------
   i := i +1;
   l_TASK(i).task_id         := v_first_id + i;
   l_TASK(i).task_name       := 'JOB_TASK_DEMO_TAB02';
   l_TASK(i).task_desc       := 'POPULATE JOB_TASK_DEMO_TAB02';
   l_TASK(i).db_link         := 'NONE';
   l_TASK(i).src_system_name := 'NONE';
   l_TASK(i).stmt_type       := 'P';
   l_TASK(i).status          := 'N';
   l_TASK(i).DEST_TABLE      := 'JOB_TASK_DEMO_TAB02';
   l_TASK(i).DEST_SCHEMA     := SYS_CONTEXT('USERENV','CURRENT_USER');
   l_TASK(i).STATEMENT       := 'PKG_JOB_TASK_DEMO.JOB_TASK_DEMO_TAB02_P';
--------------------------------------------------------------------------------
   i := i +1;
   l_TASK(i).task_id         := v_first_id + i;
   l_TASK(i).task_name       := 'JOB_TASK_DEMO_TAB03';
   l_TASK(i).task_desc       := 'POPULATE JOB_TASK_DEMO_TAB03';
   l_TASK(i).db_link         := 'NONE';
   l_TASK(i).src_system_name := 'NONE';
   l_TASK(i).stmt_type       := 'P';
   l_TASK(i).status          := 'N';
   l_TASK(i).DEST_TABLE      := 'JOB_TASK_DEMO_TAB03';
   l_TASK(i).DEST_SCHEMA     := SYS_CONTEXT('USERENV','CURRENT_USER');
   l_TASK(i).STATEMENT       := 'PKG_JOB_TASK_DEMO.JOB_TASK_DEMO_TAB03_P';
--------------------------------------------------------------------------------
   i := i +1;
   l_TASK(i).task_id         := v_first_id + i;
   l_TASK(i).task_name       := 'JOB_TASK_DEMO_TAB04';
   l_TASK(i).task_desc       := 'POPULATE JOB_TASK_DEMO_TAB04';
   l_TASK(i).db_link         := 'NONE';
   l_TASK(i).src_system_name := 'NONE';
   l_TASK(i).stmt_type       := 'P';
   l_TASK(i).status          := 'N';
   l_TASK(i).DEST_TABLE      := 'JOB_TASK_DEMO_TAB04';
   l_TASK(i).DEST_SCHEMA     := SYS_CONTEXT('USERENV','CURRENT_USER');
   l_TASK(i).STATEMENT       := 'PKG_JOB_TASK_DEMO.JOB_TASK_DEMO_TAB04_P';
--------------------------------------------------------------------------------
   i := i +1;
   l_TASK(i).task_id         := v_first_id + i;
   l_TASK(i).task_name       := 'JOB_TASK_DEMO_TAB05';
   l_TASK(i).task_desc       := 'POPULATE JOB_TASK_DEMO_TAB05';
   l_TASK(i).db_link         := 'NONE';
   l_TASK(i).src_system_name := 'NONE';
   l_TASK(i).stmt_type       := 'P';
   l_TASK(i).status          := 'N';
   l_TASK(i).DEST_TABLE      := 'JOB_TASK_DEMO_TAB05';
   l_TASK(i).DEST_SCHEMA     := SYS_CONTEXT('USERENV','CURRENT_USER');
   l_TASK(i).STATEMENT       := 'PKG_JOB_TASK_DEMO.JOB_TASK_DEMO_TAB05_P';
--------------------------------------------------------------------------------
   i := i +1;
   l_TASK(i).task_id         := v_first_id + i;
   l_TASK(i).task_name       := 'JOB_TASK_DEMO_TAB06';
   l_TASK(i).task_desc       := 'POPULATE JOB_TASK_DEMO_TAB06';
   l_TASK(i).db_link         := 'NONE';
   l_TASK(i).src_system_name := 'NONE';
   l_TASK(i).stmt_type       := 'P';
   l_TASK(i).status          := 'N';
   l_TASK(i).DEST_TABLE      := 'JOB_TASK_DEMO_TAB06';
   l_TASK(i).DEST_SCHEMA     := SYS_CONTEXT('USERENV','CURRENT_USER');
   l_TASK(i).STATEMENT       := 'PKG_JOB_TASK_DEMO.JOB_TASK_DEMO_TAB06_P';
--------------------------------------------------------------------------------
   i := i +1;
   l_TASK(i).task_id         := v_first_id + i;
   l_TASK(i).task_name       := 'JOB_TASK_DEMO_TAB07';
   l_TASK(i).task_desc       := 'POPULATE JOB_TASK_DEMO_TAB07';
   l_TASK(i).db_link         := 'NONE';
   l_TASK(i).src_system_name := 'NONE';
   l_TASK(i).stmt_type       := 'P';
   l_TASK(i).status          := 'N';
   l_TASK(i).DEST_TABLE      := 'JOB_TASK_DEMO_TAB07';
   l_TASK(i).DEST_SCHEMA     := SYS_CONTEXT('USERENV','CURRENT_USER');
   l_TASK(i).STATEMENT       := 'PKG_JOB_TASK_DEMO.JOB_TASK_DEMO_TAB07_P';
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
   FORALL x IN l_TASK.FIRST .. l_TASK.LAST
   MERGE INTO TASK t
   USING (SELECT NULL FROM DUAL)
      ON (t.task_id = l_TASK(x).task_id )
   WHEN MATCHED THEN
      UPDATE SET 
           --t.task_id = l_TASK(x).task_id
           t.task_name        = l_TASK(x).task_name
         , t.task_desc        = l_TASK(x).task_desc
         , t.db_link          = l_TASK(x).db_link
         , t.src_system_name  = l_TASK(x).src_system_name
         , t.stmt_type        = l_TASK(x).stmt_type
--         , t.status           = l_TASK(x).status
         , t.dest_table       = l_TASK(x).dest_table
         , t.dest_schema      = l_TASK(x).dest_schema
         , t.statement        = l_TASK(x).statement
   WHEN NOT MATCHED
   THEN
      INSERT VALUES l_TASK(x);
   
   COMMIT;
   --ROLLBACK;
EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      RAISE;
END;
/

SET DEFINE OFF;
