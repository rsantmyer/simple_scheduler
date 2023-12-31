CREATE OR REPLACE FORCE VIEW TASK_V 
AS 
SELECT 
  CASE WHEN TASK_EXEC.STATUS = 'R' 
   AND PREVIOUS_TASK_EXEC.COLLECTION_DURATION IS NOT NULL
     THEN PREVIOUS_TASK_EXEC.COLLECTION_DURATION - ( (CAST(SYSTIMESTAMP AS TIMESTAMP) - TASK_EXEC.COLLECTION_STARTED) ) 
  ELSE 
     NULL 
  END AS ESTIMATED_TIME_TO_COMPLETION
, CASE WHEN TASK_EXEC.STATUS = 'R' THEN (CAST(SYSTIMESTAMP AS TIMESTAMP) - TASK_EXEC.COLLECTION_STARTED) ELSE NULL END AS CURR_RUN_DURATION
, TASK.TASK_ID
, TASK.TASK_NAME
, TASK.TASK_DESC
, TASK.SRC_SYSTEM_NAME
, TASK_EXEC.STATUS
, TASK.DEST_TABLE
, TASK.DEST_SCHEMA
, TASK_EXEC.TASK_EXEC_ID
, CASE WHEN TASK.CURR_TASK_EXEC_ID = TASK_EXEC.TASK_EXEC_ID THEN 'Y' ELSE 'N' END AS IS_MOST_CURRENT
, TASK_EXEC.COLLECTION_STARTED
, TASK_EXEC.COLLECTION_COMPLETED
, TASK_EXEC.COLLECTION_DURATION
, TASK_EXEC.ROWS_PROCESSED
, TASK_EXEC.NOTES
, TASK_EXEC.JOB_EXEC_ID
, TASK.STATEMENT
, ERROR_LOG.PROCESS_NAME
, ERROR_LOG.MODULE_NAME
, ERROR_LOG.ERROR_CODE
, ERROR_LOG.ERROR_MESSAGE
, ERROR_LOG.REFERENCE_INFO
FROM TASK
JOIN TASK_EXEC
  ON TASK.TASK_ID = TASK_EXEC.TASK_ID
LEFT JOIN ERROR_LOG
  ON ERROR_LOG.PROCESS_NAME = 'PKG_TASK.run_task_p'
 AND ERROR_LOG.TASK_QUEUE_ID = TASK_EXEC.TASK_EXEC_ID
LEFT JOIN TASK_EXEC PREVIOUS_TASK_EXEC
  ON TASK.PREV_TASK_EXEC_ID = PREVIOUS_TASK_EXEC.TASK_EXEC_ID
 AND PREVIOUS_TASK_EXEC.STATUS = 'C'
ORDER BY TASK_EXEC.TASK_EXEC_ID DESC
;