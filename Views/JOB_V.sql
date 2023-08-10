CREATE OR REPLACE VIEW JOB_V 
AS 
SELECT ROUND( CASE 
                 WHEN JOB_STATUS = 'N' THEN 0
                 WHEN JOB_STATUS = 'C' THEN 1
                 WHEN JOB_STATUS = 'R' AND job_run_duration < estimated_job_duration
                    THEN PKG_INTERVAL.DIVIDE(job_run_duration, estimated_job_duration)
                 ELSE NULL
              END * 100
            , 2
       ) AS PCT_COMPLETE
     , A.*
  FROM (
         SELECT 
           COALESCE(JOB_EXEC.JOB_STATUS, JOB.JOB_STATUS) AS JOB_STATUS
         , job.job_id
         , job.job_name
         , job_exec.job_exec_id
         --, JOB.JOB_DESC
         , running_task.task_name                AS currently_running_task
         , job_exec.start_with_task_name         AS start_with_task
         , job_exec.stop_after_task_name         AS stop_after_task
--         , first_task.execution_order            AS start_task_exec_order
--         , NVL(last_task.execution_order, 9999)  AS stop_task_exec_order
         , job_detail_rollup.duration_all_tasks  AS full_job_expected_duration
         , CASE 
              WHEN job_exec.job_status = 'R' 
                 THEN job_detail_rollup.duration_selected_tasks
              ELSE 
                 job_exec.job_duration  
           END AS estimated_job_duration
         --
         , CASE 
              WHEN JOB_EXEC.JOB_STATUS = 'R' 
                 THEN (CAST(SYSTIMESTAMP AS TIMESTAMP) - JOB_EXEC.JOB_STARTED) 
              ELSE 
                 job_exec.job_duration 
           END AS job_run_duration
         --
         , CASE 
              WHEN job_exec.job_status = 'R' 
                 THEN job_detail_rollup.duration_selected_tasks
                    - ( (CAST(SYSTIMESTAMP AS TIMESTAMP) - job_exec.job_started) ) 
              ELSE 
                 NULL
           END AS estimated_time_to_completion
         , CASE 
              WHEN job.curr_job_exec_id IS NULL 
                 THEN 'Y' 
              WHEN job.curr_job_exec_id = job_exec.job_exec_id 
                 THEN 'Y' 
              ELSE 'N' 
           END AS is_most_current
         , job_exec.job_started
         , job_exec.job_completed
         --, JOB_EXEC.JOB_DURATION
         , job_exec.notes
         , error_log.process_name
         , error_log.module_name
         , error_log.error_code
         , error_log.error_message
         , error_log.reference_info
         FROM job
         LEFT
         JOIN job_exec
           ON job.job_id = job_exec.job_id
         LEFT JOIN ERROR_LOG
           ON ERROR_LOG.PROCESS_NAME = 'PKG_JOB.wrapper_run_job_p'
          AND ERROR_LOG.TASK_QUEUE_ID = JOB_EXEC.JOB_EXEC_ID
         LEFT 
         JOIN (
                SELECT job_name
                     , SUM_INTERVAL( 
                                    COALESCE(
                                              GREATEST( NVL(job_detail_v.most_recent_duration, INTERVAL '0' MINUTE) 
                                                      , NVL(job_detail_v.actual_duration,      INTERVAL '0' MINUTE) )
                                            , job_detail_v.expected_duration )
                       ) AS duration_all_tasks
                     , SUM_INTERVAL( 
                          CASE 
                             WHEN execution_order BETWEEN execution_order_first AND execution_order_last
                                THEN
                                    COALESCE(
                                              GREATEST( NVL(job_detail_v.most_recent_duration, INTERVAL '0' MINUTE) 
                                                      , NVL(job_detail_v.actual_duration,      INTERVAL '0' MINUTE) )
                                            , job_detail_v.expected_duration )
                          END
                       ) AS duration_selected_tasks
                  FROM job_detail_v
                 GROUP BY job_name
              ) job_detail_rollup
           ON job_detail_rollup.job_name = job.job_name
         LEFT JOIN task_v running_task
           ON job.job_status = 'R'
          AND job_exec.job_status = 'R'
          AND job.curr_job_exec_id = running_task.job_exec_id
          AND running_task.STATUS = 'R'
       ) A
 ORDER 
    BY JOB_EXEC_ID DESC
;