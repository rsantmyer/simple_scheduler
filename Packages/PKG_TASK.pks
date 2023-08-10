CREATE OR REPLACE PACKAGE PKG_TASK
AS
   PROCEDURE log_action (ip_task_exec_id IN NUMBER, ip_message IN VARCHAR2);

   PROCEDURE run_task_p (ip_task_name   IN task.task_name%TYPE
                        ,ip_job_exec_id IN job_exec.job_exec_id%TYPE DEFAULT NULL);
   
   PROCEDURE run_task_async_p (ip_task_name IN task.task_name%TYPE
                        , ip_instance_id in number default null );
   
   PROCEDURE archive_task_exec_p;

   PROCEDURE wait_p( ip_task_name           task.task_name%TYPE
                   , op_status              OUT task.status%TYPE
                   , op_rows_processed      OUT NUMBER
                   , ip_block               BOOLEAN DEFAULT TRUE
                   , ip_seconds_of_history  number default 64800 );

   PROCEDURE kill_task_p(ip_task_name IN task.task_name%TYPE);

END PKG_TASK;

