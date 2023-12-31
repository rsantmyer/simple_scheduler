SELECT *
FROM TASK
;
SELECT *
FROM TASK_V;

--RUNS THE TASK SYNCRONOUSLY. SESSION WILL REMAIN BUSY UNTIL TASK COMPLETES.
BEGIN
   PKG_TASK.RUN_TASK_P(:TASK_NAME);
END;
/

--RUNS THE TASK ASYNCRONOUSLY. TASK WILL RUN VIA A DBMS_SCHEDULER JOB
BEGIN
   PKG_TASK.RUN_TASK_ASYNC_P(:TASK_NAME);
END;
/

--JOBS ALWAYS RUN ASYNCH.
EXEC PKG_JOB.RUN_JOB_P('JOB_TASK_DEMO_01');

SELECT * FROM JOB_V;
SELECT * FROM JOB_DETAIL_V;
SELECT * FROM TASK_V;

SELECT *
FROM USER_SCHEDULER_JOB_RUN_DETAILS
ORDER BY LOG_ID DESC;
