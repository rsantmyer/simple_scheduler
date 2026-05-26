SET DEFINE ON
DEFINE APPLICATION_NAME = 'SIMPLE_SCHEDULER'
DEFINE DEPLOY_VERSION_MAJOR = '1'
DEFINE DEPLOY_VERSION_MINOR = '1'
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
Q'{1.1.0
* Update deployment metadata for Core 3 semantic versioning and commit hash tracking.
* Replace Core 2 ERROR_LOG/PKG_ERROR_UTIL usage with Core 3 SYSTEM_LOG/PKG_SYSLOG.
1.0.1
* Legacy initial deploy}'
      );
END;
/

--DEPENDENCIES
EXEC pkg_application.add_dependency_p  (ip_application_name => '&&APPLICATION_NAME', ip_depends_on => 'CORE', ip_version_min => pkg_application.serialize_version_f('3.3.0'));
EXEC pkg_application.add_dependency_p  (ip_application_name => '&&APPLICATION_NAME', ip_depends_on => 'UTL_INTERVAL', ip_version_min => pkg_application.serialize_version_f('1.0.0'));
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
