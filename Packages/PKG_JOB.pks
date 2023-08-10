CREATE OR REPLACE PACKAGE PKG_JOB
AS
   /* run_job_p
   ** Note: Runs a job asynchronously
   */
   PROCEDURE run_job_p(ip_job_name        IN job.job_name%TYPE
                      ,ip_start_with_task IN job_detail.task_name%TYPE DEFAULT NULL
                      ,ip_stop_after_task IN job_detail.task_name%TYPE DEFAULT NULL
                      ,ip_start_date      IN TIMESTAMP WITH TIME ZONE DEFAULT NULL);

PROCEDURE kill_p(ip_job_name IN job.job_name%TYPE);


   --WRAPPER PROCEDURES - run by refresh procedures
   --DO NOT RUN THESE PROCEDURES INTERACTIVELY ---------------------------------
   PROCEDURE wrapper_run_job_p(ip_job_name        IN job.job_name%TYPE
                              ,ip_start_with_task IN job_detail.task_name%TYPE DEFAULT NULL
                              ,ip_stop_after_task IN job_detail.task_name%TYPE DEFAULT NULL );

END PKG_JOB;

