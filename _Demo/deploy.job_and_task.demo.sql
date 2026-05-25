SET DEFINE ON
DEFINE APPLICATION_NAME = 'SIMPLE_SCHEDULER_DEMO'
DEFINE DEPLOY_VERSION_MAJOR = '1'
DEFINE DEPLOY_VERSION_MINOR = '0'
DEFINE DEPLOY_VERSION_PATCH = '0'
DEFINE DEPLOY_COMMIT_HASH = '&&1'

COLUMN CURRENT_SCHEMA       new_value CURRENT_SCHEMA      
SELECT sys_context('USERENV','CURRENT_SCHEMA') AS CURRENT_SCHEMA FROM DUAL;

SPOOL deploy.&&APPLICATION_NAME..&&CURRENT_SCHEMA..&&DEPLOY_VERSION_MAJOR..&&DEPLOY_VERSION_MINOR..&&DEPLOY_VERSION_PATCH..log

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

BEGIN
   pkg_application.begin_deployment_p
      ( ip_deploy_commit_hash => '&&DEPLOY_COMMIT_HASH'
      , ip_application_name   => '&&APPLICATION_NAME'
      , ip_major_version      => &&DEPLOY_VERSION_MAJOR
      , ip_minor_version      => &&DEPLOY_VERSION_MINOR
      , ip_patch_version      => &&DEPLOY_VERSION_PATCH
      , ip_deployment_type    => pkg_application.c_deploy_type_initial
      );
END;
/

BEGIN
   pkg_application.set_deploy_notes_p
      ( ip_application_name => '&&APPLICATION_NAME'
      , ip_notes =>
Q'{1.0.0
* SIMPLE_SCHEDULER demo deploy}'
      );
END;
/

EXEC pkg_application.add_dependency_p(ip_application_name => '&&APPLICATION_NAME', ip_depends_on => 'CORE', ip_version_min => pkg_application.serialize_version_f('3.0.0'));
EXEC pkg_application.add_dependency_p(ip_application_name => '&&APPLICATION_NAME', ip_depends_on => 'SIMPLE_SCHEDULER', ip_version_min => pkg_application.serialize_version_f('1.1.0'));

EXEC pkg_application.add_object_p(ip_application_name => '&&APPLICATION_NAME', ip_object_name => 'PKG_JOB_TASK_DEMO'  , ip_object_type => pkg_application.c_object_type_package);
EXEC pkg_application.add_object_p(ip_application_name => '&&APPLICATION_NAME', ip_object_name => 'PKG_JOB_TASK_DEMO'  , ip_object_type => pkg_application.c_object_type_package_body);


@./PKG_JOB_TASK_DEMO.pks
@./PKG_JOB_TASK_DEMO.pkb
@./TASK.JOB_TASK_DEMO.sql
@./JOB.JOB_TASK_DEMO.sql
@./JOB_DETAIL.JOB_TASK_DEMO.sql

SET DEFINE ON
EXEC pkg_application.validate_dependencies_p(ip_application_name => '&&APPLICATION_NAME');
EXEC pkg_application.validate_objects_p(ip_application_name => '&&APPLICATION_NAME');
--
EXEC pkg_application.set_deployment_complete_p(ip_application_name => '&&APPLICATION_NAME');

PAUSE JOB_AND_TASK demo for SIMPLE_SCHEDULER deploy complete. Press RETURN to run setup.
EXEC PKG_JOB_TASK_DEMO.SETUP_P;

SPOOL OFF
