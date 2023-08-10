CREATE TABLE JOB_DETAIL 
(
  JOB_NAME             VARCHAR2(30)              NOT NULL
, EXECUTION_ORDER      NUMBER(*,0)               NOT NULL
, TASK_NAME            VARCHAR2(100)             NOT NULL
, ENABLED_YN           VARCHAR2(1)   DEFAULT 'Y' NOT NULL
, EXPECTED_DURATION    INTERVAL DAY(2) TO SECOND(6) DEFAULT NUMTODSINTERVAL(60,'SECOND')
, "COMMENT"            VARCHAR2(200)
--  
, CONSTRAINT JOB_DETAIL_PK 
     PRIMARY KEY (JOB_NAME, TASK_NAME)
, CONSTRAINT JOB_DETAIL_CK01 CHECK (JOB_NAME = UPPER(JOB_NAME) )
, CONSTRAINT JOB_DETAIL_CK02 CHECK (EXECUTION_ORDER >= 1)
, CONSTRAINT JOB_DETAIL_CK03 CHECK (ENABLED_YN IN ('Y','N') )
, CONSTRAINT JOB_DETAIL_FK1
     FOREIGN KEY (JOB_NAME)
     REFERENCES JOB (JOB_NAME)
     ON DELETE CASCADE
, CONSTRAINT JOB_DETAIL_FK2
     FOREIGN KEY (TASK_NAME)
     REFERENCES TASK (TASK_NAME)
     ON DELETE CASCADE
)
;