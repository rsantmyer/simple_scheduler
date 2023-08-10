CREATE OR REPLACE PACKAGE BODY PKG_JOB
AS
   c_scheduler_job_prefix      CONSTANT VARCHAR2(10)                    := 'JOB$';
   c_job_detail_exec_order_one CONSTANT job_detail.execution_order%TYPE := 1;
   c_job_detail_exec_order_max CONSTANT job_detail.execution_order%TYPE := 9999;
   c_job_status_new            CONSTANT job.job_status%TYPE := 'N';
   c_job_status_running        CONSTANT job.job_status%TYPE := 'R';
   c_job_status_complete       CONSTANT job.job_status%TYPE := 'C';
   c_job_status_failed         CONSTANT job.job_status%TYPE := 'F';
   c_task_exec_id_none         CONSTANT task_exec.task_exec_id%TYPE := -1;
   

PROCEDURE wrapper_run_job_p(ip_job_name        IN job.job_name%TYPE
                           ,ip_start_with_task IN job_detail.task_name%TYPE DEFAULT NULL
                           ,ip_stop_after_task IN job_detail.task_name%TYPE DEFAULT NULL )
IS
   rec_job             job%ROWTYPE;
   rec_job_exec        job_exec%ROWTYPE;
   rec_job_detail      job_detail%ROWTYPE;
   rec_job_detail_last job_detail%ROWTYPE;
   l_exec_start_num    job_detail.execution_order%TYPE;
   l_exec_stop_num     job_detail.execution_order%TYPE;
BEGIN
   SELECT *
     INTO rec_job
     FROM job
    WHERE job_name = ip_job_name;

   assert(rec_job.job_status != c_job_status_running, 'Job is currently running');
   --assert(l_job.job_status != c_job_status_failed, 'Job failed on previous execution. Must reset before running.');

   IF ip_start_with_task IS NULL THEN
      l_exec_start_num := c_job_detail_exec_order_one;

      SELECT *
        INTO rec_job_detail
        FROM job_detail
       WHERE job_name = ip_job_name
         AND execution_order = l_exec_start_num;
   ELSE
      SELECT *
        INTO rec_job_detail
        FROM job_detail
       WHERE job_name = ip_job_name
         AND task_name = ip_start_with_task;

      l_exec_start_num := rec_job_detail.execution_order;
   END IF;
   
   IF ip_stop_after_task IS NULL THEN
      SELECT *
        INTO rec_job_detail_last
        FROM (
               SELECT *
                 FROM job_detail
                WHERE job_name = ip_job_name
                ORDER 
                   BY execution_order DESC
             )
       WHERE ROWNUM <= 1;

   ELSE
      SELECT *
        INTO rec_job_detail_last
        FROM job_detail
       WHERE job_name = ip_job_name
         AND task_name = ip_stop_after_task;
      
   END IF;
   
   l_exec_stop_num := rec_job_detail_last.execution_order;
   
   INSERT INTO job_exec (job_id, job_status, start_with_task_name, stop_after_task_name)
   VALUES
   (rec_job.job_id, c_job_status_running, rec_job_detail.task_name, rec_job_detail_last.task_name)
      RETURNING job_exec_id, job_id, job_status, start_with_task_name, stop_after_task_name
              , job_started, job_completed, job_duration, notes
           INTO rec_job_exec;

    COMMIT;

   rec_job_exec.job_status := c_job_status_complete;
   
   BEGIN
      FOR rec_job_detail 
       IN (SELECT * FROM JOB_DETAIL WHERE JOB_NAME = rec_job.job_name AND EXECUTION_ORDER >= l_exec_start_num ORDER BY EXECUTION_ORDER)
      LOOP
         IF rec_job_detail.enabled_yn = 'Y' THEN
            PKG_TASK.run_task_p(ip_task_name   => rec_job_detail.task_name
                               ,ip_job_exec_id => rec_job_exec.job_exec_id);
         ELSE
            --log that we are skipping a task?
            NULL;
         END IF;
         
         EXIT WHEN rec_job_detail.execution_order = l_exec_stop_num;
         
      END LOOP;
   EXCEPTION WHEN OTHERS THEN
      ROLLBACK;
      rec_job_exec.job_status := c_job_status_failed;
      PKG_ERROR_UTIL.LogError_p(
         in_process_name   => 'PKG_JOB.wrapper_run_job_p',
         in_module_name    => ip_job_name,
         in_revision       => '$Rev$',
         in_severity_level => PKG_ERROR_UTIL.C_ERROR,
         in_error_code     => SQLCODE,
         in_error_message  => SQLERRM,
         in_reference_info => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE(),
         in_task_queue_id  => rec_job_exec.job_exec_id);
   END;

   UPDATE job_exec
      SET job_status       = rec_job_exec.job_status
        , job_completed    = CAST(SYSTIMESTAMP AS TIMESTAMP)
        , job_duration     = CAST(SYSTIMESTAMP AS TIMESTAMP) - job_started
    WHERE job_exec_id      = rec_job_exec.job_exec_id;
   
   COMMIT;

   assert(rec_job_exec.job_status != c_job_status_failed, 'wrapper_run_job_p: job "'||rec_job.job_name||'" has failed; check job_v view.');

END wrapper_run_job_p;



PROCEDURE run_job_p(ip_job_name        IN job.job_name%TYPE
                   ,ip_start_with_task IN job_detail.task_name%TYPE DEFAULT NULL
                   ,ip_stop_after_task IN job_detail.task_name%TYPE DEFAULT NULL
                   ,ip_start_date      IN TIMESTAMP WITH TIME ZONE DEFAULT NULL)
IS
   l_job        job%ROWTYPE;
   l_nodes      number;
BEGIN
   SELECT *
     INTO l_job
     FROM job
    WHERE job_name = ip_job_name;

   -- Are we running on RAC?
   SELECT count(1)
     INTO l_nodes
     FROM gv$instance;

   assert(l_job.job_status != c_job_status_running, 'Job is currently running');
   --assert(l_job.job_status != c_job_status_failed, 'Job failed on previous execution. Must reset before running.');

   DBMS_SCHEDULER.CREATE_JOB (
      job_name   => c_scheduler_job_prefix||ip_job_name,
      job_type   => 'PLSQL_BLOCK',
      job_action => Q'{PKG_JOB.wrapper_run_job_p(ip_job_name => '}'||ip_job_name||''''
                                          ||case when ip_start_with_task is not null then Q'{,ip_start_with_task => '}'||ip_start_with_task||'''' end
                                          ||case when ip_stop_after_task is not null then Q'{,ip_stop_after_task => '}'||ip_stop_after_task||'''' end
                                          ||');',
      start_date => ip_start_date );

   IF l_nodes > 1 and l_job.instance_id is not null
   THEN
      DBMS_SCHEDULER.SET_ATTRIBUTE( 
         name => c_scheduler_job_prefix||ip_job_name,
         attribute => 'INSTANCE_ID', value => l_job.instance_id );         
   END IF;

   DBMS_SCHEDULER.ENABLE( name => c_scheduler_job_prefix||ip_job_name );

END run_job_p;



PROCEDURE kill_p(ip_job_name        IN job.job_name%TYPE)
IS
   rec_job         job%ROWTYPE;
   l_task_exec_id  task_exec.task_exec_id%TYPE;
BEGIN
   SELECT *
     INTO rec_job
     FROM job
    WHERE job_name = ip_job_name
      AND job_status = c_job_status_running;
   
   BEGIN
      dbms_scheduler.stop_job(c_scheduler_job_prefix||ip_job_name);
   END;
   
   SELECT NVL(MAX(task_exec_id), c_task_exec_id_none) AS task_exec_id
     INTO l_task_exec_id
     FROM task_exec
    WHERE job_exec_id = rec_job.curr_job_exec_id
      AND status = c_job_status_running; --same as task running

   IF l_task_exec_id != c_task_exec_id_none THEN
      UPDATE task_exec
         SET status               = c_job_status_failed  --same as task
           , collection_completed = CAST(SYSTIMESTAMP AS TIMESTAMP)
           , collection_duration  = CAST(SYSTIMESTAMP AS TIMESTAMP) - collection_started
           , rows_processed       = 0
           , notes                = 'killed by: '||SYS_CONTEXT('USERENV','OS_USER')||'@'||SYS_CONTEXT('USERENV','HOST')
       WHERE task_exec_id = l_task_exec_id;
   END IF;

   UPDATE job_exec
      SET job_status       = c_job_status_failed
        , job_completed    = CAST(SYSTIMESTAMP AS TIMESTAMP)
        , job_duration     = CAST(SYSTIMESTAMP AS TIMESTAMP) - job_started
        , notes            = 'killed by: '||SYS_CONTEXT('USERENV','OS_USER')||'@'||SYS_CONTEXT('USERENV','HOST')
    WHERE job_exec_id      = rec_job.curr_job_exec_id;

   COMMIT;

END kill_p;


END PKG_JOB;

