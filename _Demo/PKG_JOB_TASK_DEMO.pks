CREATE OR REPLACE PACKAGE PKG_JOB_TASK_DEMO
AS
  --PACKAGE CONSTANTS

  --PROCEDURES
   PROCEDURE setup_p;
   --
   PROCEDURE job_task_demo_tab01_p(op_rows_processed OUT NUMBER);
   PROCEDURE job_task_demo_tab02_p(op_rows_processed OUT NUMBER);
   PROCEDURE job_task_demo_tab03_p(op_rows_processed OUT NUMBER);
   PROCEDURE job_task_demo_tab04_p(op_rows_processed OUT NUMBER);
   PROCEDURE job_task_demo_tab05_p(op_rows_processed OUT NUMBER);
   PROCEDURE job_task_demo_tab06_p(op_rows_processed OUT NUMBER);
   PROCEDURE job_task_demo_tab07_p(op_rows_processed OUT NUMBER);
   
END PKG_JOB_TASK_DEMO;
/
