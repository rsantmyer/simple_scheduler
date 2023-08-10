SET DEFINE ON
DEFINE APPLICATION_NAME = 'SIMPLE_SCHEDULER'
DEFINE DEPLOY_VERSION = '1.01'

COLUMN CURRENT_SCHEMA       new_value CURRENT_SCHEMA      
SELECT sys_context('USERENV','CURRENT_SCHEMA') AS CURRENT_SCHEMA FROM DUAL;

SPOOL deploy.&&APPLICATION_NAME..&&CURRENT_SCHEMA..log

--PRINT BIND VARIABLE VALUES
SET AUTOPRINT ON                    

--THE START COMMAND WILL LIST EACH COMMAND IN A SCRIPT
REM SET ECHO ON                         

--DISPLAY DBMS_OUTPUT.PUT_LINE OUTPUT
SET SERVEROUTPUT ON                 

--SHOW THE OLD AND NEW SETTINGS OF A SQLPLUS SYSTEM VARIABLE
REM SET SHOWMODE ON                     

--ALLOW BLANK LINES WITHIN A SQL COMMAND OR SCRIPT
--SET SQLBLANKLINES ON                

WHENEVER SQLERROR EXIT FAILURE
WHENEVER OSERROR EXIT FAILURE

EXEC PKG_APPLICATION.delete_application_p(ip_application_name => '&&APPLICATION_NAME', ip_fail_on_not_found => 'N' );
--
EXEC pkg_application.begin_deployment_p     (ip_application_name => '&&APPLICATION_NAME', ip_version => &&DEPLOY_VERSION, ip_deployment_type => pkg_application.c_deploy_type_initial);

--DEPENDENCIES
EXEC pkg_application.add_dependency_p  (ip_application_name => '&&APPLICATION_NAME', ip_depends_on => 'UTL_INTERVAL');
--SYSTEM/OBJECT PRIVILEGES
EXEC pkg_application.add_obj_priv_p  (ip_application_name => '&&APPLICATION_NAME', ip_owner => 'SYS', ip_type => 'VIEW', ip_name => 'GV_$INSTANCE', ip_privilege => 'SELECT');
--DATABASE LINKS
--SEQUENCES
EXEC pkg_application.add_object_p(ip_application_name => '&&APPLICATION_NAME', ip_object_name => 'JOB_EXEC_SEQ'    , ip_object_type => pkg_application.c_object_type_sequence);
EXEC pkg_application.add_object_p(ip_application_name => '&&APPLICATION_NAME', ip_object_name => 'TASK_EXEC_SEQ'   , ip_object_type => pkg_application.c_object_type_sequence);
EXEC pkg_application.add_object_p(ip_application_name => '&&APPLICATION_NAME', ip_object_name => 'TASK_SEQ'        , ip_object_type => pkg_application.c_object_type_sequence);
--TABLES
EXEC pkg_application.add_object_p(ip_application_name => '&&APPLICATION_NAME', ip_object_name => 'JOB'                       , ip_object_type => pkg_application.c_object_type_table);
EXEC pkg_application.add_object_p(ip_application_name => '&&APPLICATION_NAME', ip_object_name => 'JOB_EXEC'                  , ip_object_type => pkg_application.c_object_type_table);
EXEC pkg_application.add_object_p(ip_application_name => '&&APPLICATION_NAME', ip_object_name => 'TASK'                      , ip_object_type => pkg_application.c_object_type_table);
EXEC pkg_application.add_object_p(ip_application_name => '&&APPLICATION_NAME', ip_object_name => 'JOB_DETAIL'                , ip_object_type => pkg_application.c_object_type_table);
EXEC pkg_application.add_object_p(ip_application_name => '&&APPLICATION_NAME', ip_object_name => 'TASK_EXEC'                 , ip_object_type => pkg_application.c_object_type_table);
EXEC pkg_application.add_object_p(ip_application_name => '&&APPLICATION_NAME', ip_object_name => 'TASK_EXEC_HIST'            , ip_object_type => pkg_application.c_object_type_table);
EXEC pkg_application.add_object_p(ip_application_name => '&&APPLICATION_NAME', ip_object_name => 'TASK_EXEC_LOG'             , ip_object_type => pkg_application.c_object_type_table);
--VIEWS
EXEC pkg_application.add_object_p(ip_application_name => '&&APPLICATION_NAME', ip_object_name => 'TASK_V'              , ip_object_type => pkg_application.c_object_type_view);
EXEC pkg_application.add_object_p(ip_application_name => '&&APPLICATION_NAME', ip_object_name => 'JOB_DETAIL_V'        , ip_object_type => pkg_application.c_object_type_view);
EXEC pkg_application.add_object_p(ip_application_name => '&&APPLICATION_NAME', ip_object_name => 'JOB_V'               , ip_object_type => pkg_application.c_object_type_view);
--PACKAGE SPECS / PACKAGE BODIES
EXEC pkg_application.add_object_p(ip_application_name => '&&APPLICATION_NAME', ip_object_name => 'PKG_TASK'              , ip_object_type => pkg_application.c_object_type_package);
EXEC pkg_application.add_object_p(ip_application_name => '&&APPLICATION_NAME', ip_object_name => 'PKG_TASK'              , ip_object_type => pkg_application.c_object_type_package_body);
EXEC pkg_application.add_object_p(ip_application_name => '&&APPLICATION_NAME', ip_object_name => 'PKG_JOB'               , ip_object_type => pkg_application.c_object_type_package);
EXEC pkg_application.add_object_p(ip_application_name => '&&APPLICATION_NAME', ip_object_name => 'PKG_JOB'               , ip_object_type => pkg_application.c_object_type_package_body);
--
EXEC pkg_application.validate_dependencies_p(ip_application_name => '&&APPLICATION_NAME');
EXEC pkg_application.validate_obj_privs_p   (ip_application_name => '&&APPLICATION_NAME');
EXEC pkg_application.validate_sys_privs_p   (ip_application_name => '&&APPLICATION_NAME');

--Sequences
PROMPT Creating Sequences
@@../Sequences/JOB_EXEC_SEQ.sql
@@../Sequences/TASK_EXEC_SEQ.sql
@@../Sequences/TASK_SEQ.sql

--Tables
Prompt Creating Tables
@@../Tables/JOB.sql
@@../Tables/JOB_EXEC.sql
@@../Tables/TASK.sql
@@../Tables/JOB_DETAIL.sql                              -- DEPENDS ON: TASK
@@../Tables/TASK_EXEC.sql
@@../Tables/TASK_EXEC_HIST.sql
@@../Tables/TASK_EXEC_LOG.sql

--Views
Prompt Creating Views
@@../Views/TASK_V.sql
@@../Views/JOB_DETAIL_V.sql
@@../Views/JOB_V.sql                                    -- DEPENDS ON: JOB_DETAIL_V

--Package Specifications
Prompt Creating Package Specifications
@@../Packages/PKG_TASK.pks
@@../Packages/PKG_JOB.pks

--Package Bodies
Prompt Creating Package Bodies
@@../Packages/PKG_TASK.pkb
@@../Packages/PKG_JOB.pkb

EXEC pkg_application.validate_objects_p(ip_application_name => '&&APPLICATION_NAME');
--
EXEC pkg_application.set_deployment_complete_p(ip_application_name => '&&APPLICATION_NAME');

SPOOL OFF
