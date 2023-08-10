CREATE OR REPLACE VIEW JOB_DETAIL_V 
AS 
SELECT job.job_id
     , job.job_name
     , job.curr_job_exec_id                 AS job_exec_id
     --, job.enabled_yn AS job_enabled_yn
     , job.job_status
     --, job.curr_rundate AS job_start_time
     , job_detail.task_name
     , job.execution_order_first
     , job_detail.execution_order
     , job.execution_order_last
     , job_detail.enabled_yn                AS task_enabled_yn
     , task_v.status                        AS task_status
     , task_v.collection_started
     , job_detail.expected_duration         AS expected_duration
     , COALESCE( task_most_recent.collection_duration
               , task_v.estimated_time_to_completion 
               + task_v.curr_run_duration
               )                            AS most_recent_duration
     , CASE 
          WHEN task_v.status = 'R' 
             THEN task_v.curr_run_duration
          ELSE task_v.collection_duration 
       END                                  AS actual_duration
     , task_v.rows_processed
     , task.statement
  FROM (
         SELECT job.job_id
              , job.job_name
              , job.curr_job_exec_id
              , job.job_status
            --, job_exec.*
              , NVL(first_task.execution_order,1   ) AS execution_order_first
              , NVL(last_task.execution_order ,9999) AS execution_order_last
           FROM job
           LEFT JOIN job_exec
             ON job.job_id = job_exec.job_id
            AND job.curr_job_exec_id = job_exec.job_exec_id
           LEFT JOIN job_detail first_task
             ON first_task.job_name = job.job_name
            AND first_task.task_name = job_exec.start_with_task_name
           LEFT JOIN job_detail last_task
             ON last_task.job_name = job.job_name
           AND last_task.task_name = job_exec.stop_after_task_name
       ) job
  LEFT
  JOIN job_detail
    ON job.job_name = job_detail.job_name
  LEFT
  JOIN task_v
    ON task_v.job_exec_id = job.curr_job_exec_id
   AND task_v.task_name = job_detail.task_name
  LEFT
  JOIN task
    ON task.task_name = job_detail.task_name
  LEFT
  JOIN task_v task_most_recent
    ON task_most_recent.task_name = job_detail.task_name
   AND task_most_recent.is_most_current = 'Y'
   AND task_most_recent.status = 'C'
 ORDER 
    BY job.curr_job_exec_id        DESC
     , job_detail.execution_order  DESC
;
