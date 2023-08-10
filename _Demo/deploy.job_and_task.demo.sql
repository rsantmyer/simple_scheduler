SET DEFINE ON
DEFINE APPLICATION_NAME = 'SIMPLE_SCHEDULER_DEMO'
DEFINE DEPLOY_VERSION = '1'

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

EXEC pkg_application.add_object_p(ip_application_name => '&&APPLICATION_NAME', ip_object_name => 'PKG_JOB_TASK_DEMO'  , ip_object_type => pkg_application.c_object_type_package);
EXEC pkg_application.add_object_p(ip_application_name => '&&APPLICATION_NAME', ip_object_name => 'PKG_JOB_TASK_DEMO'  , ip_object_type => pkg_application.c_object_type_package_body);


@./PKG_JOB_TASK_DEMO.pks
@./PKG_JOB_TASK_DEMO.pkb
@./TASK.JOB_TASK_DEMO.sql
@./JOB.JOB_TASK_DEMO.sql
@./JOB_DETAIL.JOB_TASK_DEMO.sql

SET DEFINE ON
EXEC pkg_application.validate_objects_p(ip_application_name => '&&APPLICATION_NAME');
--
EXEC pkg_application.set_deployment_complete_p(ip_application_name => '&&APPLICATION_NAME');

PAUSE JOB_AND_TASK demo for SIMPLE_SCHEDULER deploy complete. Press RETURN to run setup.
EXEC PKG_JOB_TASK_DEMO.SETUP_P;

SPOOL OFF
