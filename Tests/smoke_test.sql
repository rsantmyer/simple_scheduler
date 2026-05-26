SET DEFINE ON
SET SERVEROUTPUT ON
SET VERIFY OFF

WHENEVER SQLERROR EXIT FAILURE
WHENEVER OSERROR EXIT FAILURE

DEFINE SMOKE_TASK_NAME = 'SIMPLE_SCHEDULER_SMOKE_TASK'
DEFINE SMOKE_JOB_NAME = 'SIMPLE_SCHEDULER_SMOKE_JOB'

PROMPT Running SIMPLE_SCHEDULER live database smoke test

DECLARE
   c_task_name CONSTANT task.task_name%TYPE := '&&SMOKE_TASK_NAME';
   c_job_name  CONSTANT job.job_name%TYPE   := '&&SMOKE_JOB_NAME';

   l_task_id        task.task_id%TYPE;
   l_job_id         job.job_id%TYPE;
   l_invalid_count  PLS_INTEGER;
   l_status         VARCHAR2(1);
   l_rows_processed NUMBER;

   PROCEDURE assert_p(ip_condition IN BOOLEAN, ip_message IN VARCHAR2)
   IS
   BEGIN
      IF NOT ip_condition THEN
         RAISE_APPLICATION_ERROR(-20000, ip_message);
      END IF;
   END assert_p;

   PROCEDURE cleanup_p
   IS
   BEGIN
      DELETE FROM task_exec_log
       WHERE task_exec_id IN (
                SELECT task_exec_id
                  FROM task_exec
                 WHERE task_id IN (
                          SELECT task_id
                            FROM task
                           WHERE task_name = c_task_name));

      DELETE FROM task_exec_hist
       WHERE task_id IN (
                SELECT task_id
                  FROM task
                 WHERE task_name = c_task_name);

      DELETE FROM task_exec
       WHERE task_id IN (
                SELECT task_id
                  FROM task
                 WHERE task_name = c_task_name);

      DELETE FROM job_exec
       WHERE job_id IN (
                SELECT job_id
                  FROM job
                 WHERE job_name = c_job_name);

      DELETE FROM job_detail
       WHERE job_name = c_job_name;

      DELETE FROM job
       WHERE job_name = c_job_name;

      DELETE FROM task
       WHERE task_name = c_task_name;

      COMMIT;
   END cleanup_p;
BEGIN
   cleanup_p;

   SELECT COUNT(*)
     INTO l_invalid_count
     FROM user_objects
    WHERE object_name IN (
             'PKG_TASK',
             'PKG_JOB',
             'TASK_V',
             'JOB_DETAIL_V',
             'JOB_V')
      AND status != 'VALID';

   assert_p(l_invalid_count = 0, 'SIMPLE_SCHEDULER has invalid package or view objects');

   SELECT task_seq.NEXTVAL
     INTO l_task_id
     FROM dual;

   SELECT NVL(MAX(job_id), 0) + 1
     INTO l_job_id
     FROM job;

   INSERT INTO task
      ( task_id
      , task_name
      , task_desc
      , db_link
      , src_system_name
      , stmt_type
      , status
      , dest_table
      , dest_schema
      , statement)
   VALUES
      ( l_task_id
      , c_task_name
      , 'Live database smoke test task'
      , 'NONE'
      , 'NONE'
      , 'B'
      , 'N'
      , 'NONE'
      , SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA')
      , Q'{BEGIN
              IF :ip_task_exec_id IS NULL THEN
                 RAISE_APPLICATION_ERROR(-20001, 'Missing task execution id');
              END IF;

              :op_rows_processed := 1;
           END;}');

   INSERT INTO job
      ( job_id
      , job_name
      , job_desc
      , enabled_yn
      , job_status)
   VALUES
      ( l_job_id
      , c_job_name
      , 'Live database smoke test job'
      , 'Y'
      , 'N');

   INSERT INTO job_detail
      ( job_name
      , execution_order
      , task_name
      , enabled_yn
      , expected_duration
      , "COMMENT")
   VALUES
      ( c_job_name
      , 1
      , c_task_name
      , 'Y'
      , NUMTODSINTERVAL(1, 'SECOND')
      , 'Live database smoke test');

   COMMIT;

   pkg_task.run_task_p(ip_task_name => c_task_name);

   SELECT status, rows_processed
     INTO l_status, l_rows_processed
     FROM task_exec
    WHERE task_id = l_task_id
      AND task_exec_id = (
             SELECT MAX(task_exec_id)
               FROM task_exec
              WHERE task_id = l_task_id);

   assert_p(l_status = 'C', 'Smoke task direct run did not complete');
   assert_p(l_rows_processed = 1, 'Smoke task direct run returned unexpected row count');

   pkg_job.wrapper_run_job_p(ip_job_name => c_job_name);

   SELECT job_status
     INTO l_status
     FROM job_exec
    WHERE job_id = l_job_id
      AND job_exec_id = (
             SELECT MAX(job_exec_id)
               FROM job_exec
              WHERE job_id = l_job_id);

   assert_p(l_status = 'C', 'Smoke job run did not complete');

   SELECT status, rows_processed
     INTO l_status, l_rows_processed
     FROM task_exec
    WHERE task_id = l_task_id
      AND task_exec_id = (
             SELECT MAX(task_exec_id)
               FROM task_exec
              WHERE task_id = l_task_id);

   assert_p(l_status = 'C', 'Smoke task job run did not complete');
   assert_p(l_rows_processed = 1, 'Smoke task job run returned unexpected row count');

   cleanup_p;

   DBMS_OUTPUT.PUT_LINE('SIMPLE_SCHEDULER smoke test passed');
EXCEPTION
   WHEN OTHERS THEN
      BEGIN
         cleanup_p;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;

      RAISE;
END;
/

SET VERIFY ON
