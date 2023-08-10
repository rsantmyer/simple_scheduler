CREATE OR REPLACE PACKAGE BODY PKG_TASK
AS
   c_task_status_new            CONSTANT task.status%TYPE := 'N';
   c_task_status_running        CONSTANT task.status%TYPE := 'R';
   c_task_status_complete       CONSTANT task.status%TYPE := 'C';
   c_task_status_failed         CONSTANT task.status%TYPE := 'F';
   c_job_name_prefix            CONSTANT VARCHAR2(10)     := 'JOB$';

PROCEDURE log_action (ip_task_exec_id IN NUMBER, ip_message IN VARCHAR2)
IS
   PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
   INSERT 
     INTO task_EXEC_LOG
        (task_exec_id, LOG_TS, LOG_MSG)
     VALUES
        (ip_task_exec_id, SYSTIMESTAMP, ip_message);

   COMMIT;
END log_action;



PROCEDURE run_task_p (ip_task_name   IN task.task_name%TYPE
                     ,ip_job_exec_id IN job_exec.job_exec_id%TYPE DEFAULT NULL)
IS
   l_task       task%ROWTYPE;
   l_task_exec  task_exec%ROWTYPE;
   v_stmt       VARCHAR2(32000);
BEGIN
   SELECT *
     INTO l_task
     FROM task
    WHERE task_name = ip_task_name;
    
    assert(l_task.status != c_task_status_running, 'Task is currently running');
    --assert(l_task.status != c_task_status_failed, 'Task failed on previous execution. Must reset before running.');

   INSERT INTO task_exec (task_id, status, job_exec_id)
   VALUES
   (l_task.task_id, c_task_status_running, ip_job_exec_id)
      RETURNING task_exec_id, task_id, status, collection_started, collection_completed, collection_duration, rows_processed
              , notes, job_exec_id
           INTO l_task_exec;

    COMMIT;

    l_task_exec.status := c_task_status_complete;
    
    BEGIN
      CASE l_task.stmt_type
      WHEN 'S' --STATEMENT
      THEN
         l_task.statement := REPLACE(l_task.statement,':task_exec_id:',l_task_exec.task_exec_id);
      
         EXECUTE IMMEDIATE l_task.statement;
         
         l_task_exec.rows_processed := SQL%ROWCOUNT;
      WHEN 'B' --BLOCK
      THEN
         EXECUTE IMMEDIATE l_task.statement 
         USING  IN l_task_exec.task_exec_id
             , OUT l_task_exec.rows_processed;
      WHEN 'N' --PROCEDURE WITH NO PARAMETERS
      THEN
         EXECUTE IMMEDIATE 
Q'{DECLARE
   b_task_exec_id     NUMBER;
BEGIN
   b_task_exec_id := :ip_task_exec_id;
   }'||l_task.statement||Q'{;
END;}'
         USING  IN l_task_exec.task_exec_id;
      
      WHEN 'P' --PROCEDURE
      THEN
         EXECUTE IMMEDIATE 
Q'{DECLARE
   b_task_exec_id     NUMBER;
   v_rowcount         NUMBER;
BEGIN
   b_task_exec_id := :ip_task_exec_id;
   }'||l_task.statement||Q'{ (v_rowcount);
  
   :out_rows_processed := v_rowcount;
END;}'
         USING  IN l_task_exec.task_exec_id
             , OUT l_task_exec.rows_processed;
      
      ELSE
         ASSERT(FALSE,'l_task.stmt_type is: '||l_task.stmt_type);
  
      END CASE;
    EXCEPTION WHEN OTHERS THEN
       ROLLBACK;
       l_task_exec.status := c_task_status_failed;
       PKG_ERROR_UTIL.LogError_p(
          in_process_name   => 'PKG_TASK.run_task_p',
          in_module_name    => ip_task_name,
          in_revision       => '$Rev$',
          in_severity_level => PKG_ERROR_UTIL.C_ERROR,
          in_error_code     => SQLCODE,
          in_error_message  => SQLERRM,
          in_reference_info => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE(),
          in_task_queue_id  => l_task_exec.task_exec_id);
       
    END;

    
    
    UPDATE task_exec
       SET status               = l_task_exec.status
         , collection_completed = CAST(SYSTIMESTAMP AS TIMESTAMP)
         , collection_duration  = CAST(SYSTIMESTAMP AS TIMESTAMP) - collection_started
         , rows_processed       = CASE WHEN l_task_exec.status = 'C' THEN l_task_exec.rows_processed
                                  ELSE 0 END
     WHERE task_exec_id = l_task_exec.task_exec_id;
    
    COMMIT;

    assert(l_task_exec.status != c_task_status_failed, 'run_task_p: Task "'||l_task.task_name||'" has failed; check task_v view.');
END run_task_p;



PROCEDURE run_task_async_p (ip_task_name IN task.task_name%TYPE
                        , ip_instance_id in number default null )
IS
   l_task       task%ROWTYPE;
   l_nodes      number;
BEGIN
   SELECT *
     INTO l_task
     FROM task
    WHERE task_name = ip_task_name;

   -- Are we running on RAC?
   SELECT count(1)
     INTO l_nodes
     FROM gv$instance;

   assert(l_task.status != c_task_status_running, 'Task is currently running');
   --assert(l_task.status != c_task_status_failed, 'Task failed on previous execution. Must reset before running.');

   DBMS_SCHEDULER.CREATE_JOB (
      job_name   => c_job_name_prefix||ip_task_name,
      job_type   => 'PLSQL_BLOCK',
      job_action => Q'{PKG_TASK.run_task_p('}'||ip_task_name||Q'{');}' );

   IF l_nodes > 1 and ip_instance_id is not null
   THEN
      DBMS_SCHEDULER.SET_ATTRIBUTE( 
         name => c_job_name_prefix||ip_task_name,
         attribute => 'INSTANCE_ID', value => ip_instance_id );         
   END IF;

   DBMS_SCHEDULER.ENABLE( name => c_job_name_prefix||ip_task_name );

END run_task_async_p;



PROCEDURE archive_task_exec_p 
IS
BEGIN
  FOR REC IN
  (
  SELECT TE.*
       , ROW_NUMBER() OVER (PARTITION BY TASK_ID ORDER BY TASK_EXEC_ID DESC) AS RN_NEW_TO_OLD
    FROM TASK_EXEC TE
   WHERE STATUS != c_task_status_running
  )
  LOOP
     IF REC.STATUS = c_task_status_failed
     OR (REC.STATUS = c_task_status_complete AND REC.RN_NEW_TO_OLD > 1)
     THEN
        INSERT INTO TASK_EXEC_HIST SELECT * FROM TASK_EXEC WHERE TASK_EXEC_ID = REC.TASK_EXEC_ID;
        DELETE FROM TASK_EXEC WHERE TASK_EXEC_ID = REC.TASK_EXEC_ID;
     END IF;
  
  END LOOP;
  
  COMMIT;

END archive_task_exec_p;



PROCEDURE wait_p( ip_task_name          task.task_name%TYPE
                , op_status             OUT task.status%TYPE
                , op_rows_processed     OUT NUMBER
                , ip_block              BOOLEAN DEFAULT TRUE
                , ip_seconds_of_history number default 64800 )
IS
    con_startup_seconds CONSTANT NUMBER := 60;
    v_cnt               NUMBER;
    l_wait_start_time   DATE;
BEGIN

    select  count(1)
    into    v_cnt
    from    task
    where   task_name = ip_task_name;

    assert(v_cnt = 1, 'No task named ' || ip_task_name);

    l_wait_start_time := SYSDATE;
    LOOP
       BEGIN
          DBMS_SESSION.Sleep(5);
       
          select  status, NVL(rows_processed,0)
          into    op_status, op_rows_processed
          from  ( select  t.status, te.rows_processed, rownum rn
                  from    task_exec te
                          inner join task t
                          on  t.curr_task_exec_id = te.task_exec_id
                  where   t.task_name = ip_task_name
                      and te.collection_started > sysdate - (ip_seconds_of_history/86400)
                  order by te.collection_started desc )
          where rn = 1;
       
          EXIT WHEN op_status in (c_task_status_complete, c_task_status_failed) or ip_block != TRUE;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
             IF SYSDATE - (con_startup_seconds/86400) > l_wait_start_time THEN
                RAISE;
             END IF;
       END;
    END LOOP;

END wait_p;



PROCEDURE kill_task_p(ip_task_name IN task.task_name%TYPE)
IS
   rec_task           task%ROWTYPE;
   rec_task_exec      task_exec%ROWTYPE;
BEGIN

   SELECT *
     INTO rec_task
     FROM task
    WHERE task_name = ip_task_name
      AND status = c_task_status_running;

   SELECT *
     INTO rec_task_exec
     FROM task_exec
    WHERE task_exec_id = rec_task.curr_task_exec_id
      AND status = c_task_status_running;

   assert(rec_task_exec.job_exec_id IS NULL, 'This task is part of a running job; use the kill functionality in PKG_JOB.');

   BEGIN
      DBMS_SCHEDULER.stop_job( job_name => c_job_name_prefix||ip_task_name );
   END;
   
   UPDATE task_exec
      SET status               = c_task_status_failed
        , collection_completed = CAST(SYSTIMESTAMP AS TIMESTAMP)
        , collection_duration  = CAST(SYSTIMESTAMP AS TIMESTAMP) - collection_started
        , rows_processed       = 0
        , notes                = 'killed by: '||SYS_CONTEXT('USERENV','OS_USER')||'@'||SYS_CONTEXT('USERENV','HOST')
    WHERE task_exec_id = rec_task.curr_task_exec_id;
   
   COMMIT;

END;


END PKG_TASK;
/

