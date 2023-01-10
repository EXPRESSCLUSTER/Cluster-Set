rem ***************************************
rem *              start.bat              *
rem *                                     *
rem * title   : start script file sample  *
rem * date    : 2022/12/31                *
rem ***************************************


rem ***************************************
rem Check startup attributes
rem ***************************************
IF "%CLP_EVENT%" == "START" GOTO NORMAL
IF "%CLP_EVENT%" == "FAILOVER" GOTO FAILOVER
IF "%CLP_EVENT%" == "RECOVER" GOTO RECOVER

rem Cluster Server is not started
GOTO no_clp


rem ***************************************
rem Normal Startup process
rem ***************************************
:NORMAL
clplogcmd -m "Normal startup process %CLP_EVENT%" -l INFO
echo %date% %time%
echo "Normal startup on %CLP_SERVER% server"
cd "%CLP_SCRIPT_PATH%"
rem echo Current directory is %cd%
if "%CLP_SERVER_PREV%" EQU "" echo Variable CLP_SERVER_PREV is not defined
if "%CLP_EVENT%" NEQ "" echo Variable CLP_EVENT IS defined

call SetEnvironment.bat
PowerShell -ExecutionPolicy ByPass -File .\changeprimary.ps1 -noprofile
set ret=%ERRORLEVEL%
echo Start.bat return value: %ret%
if %ret% == 0 GOTO CONTINUE
clplogcmd -m "Failed to enable replication. Stop script and start again." -l ERR
:CONTINUE

rem Check Disk
IF "%CLP_DISK%" == "FAILURE" GOTO ERROR_DISK


rem *************
rem Routine procedure
rem *************


rem Priority check
IF "%CLP_SERVER%" == "OTHER" GOTO ON_OTHER1

rem *************
rem Highest Priority Process
rem *************
GOTO EXIT


:ON_OTHER1
rem *************
rem Other Process
rem *************
GOTO EXIT


rem ***************************************
rem Recovery process
rem ***************************************
:RECOVER
clplogcmd -m "Recover startup process %CLP_EVENT%" -l INFO
echo %date% %time%
echo "Recover startup on %CLP_SERVER% server"
call SetEnvironment.bat
PowerShell -ExecutionPolicy ByPass -File .\changeprimary.ps1 -noprofile
set ret=%ERRORLEVEL%
echo Start.bat return value: %ret%
if %ret% == 0 GOTO CONTINUE2
clplogcmd -m "Failed to enable replication. Stop script and start again." -l ERR
:CONTINUE2

rem *************
rem Recovery process after return to the cluster
rem *************

GOTO EXIT


rem ***************************************
rem Process for failover
rem ***************************************
:FAILOVER
clplogcmd -m "Failover startup process %CLP_EVENT%" -l INFO
echo %date% %time%
echo "Failover startup on %CLP_SERVER% server"
call SetEnvironment.bat
PowerShell -ExecutionPolicy ByPass -File .\changeprimary.ps1 -noprofile
set ret=%ERRORLEVEL%
echo Start.bat return value: %ret%
if %ret% == 0 GOTO CONTINUE3
clplogcmd -m "Failed to enable replication. Stop script and start again." -l ERR
:CONTINUE3

rem Check Disk
IF "%CLP_DISK%" == "FAILURE" GOTO ERROR_DISK


rem *************
rem Starting applications/services and recovering process after failover
rem *************


rem Priority check
IF "%CLP_SERVER%" == "OTHER" GOTO ON_OTHER2

rem *************
rem Highest Priority Process
rem *************
GOTO EXIT


:ON_OTHER2
rem *************
rem Other Process
rem *************
GOTO EXIT


rem ***************************************
rem Irregular process
rem ***************************************

rem Process for disk errors
:ERROR_DISK
GOTO EXIT


rem Cluster Server is not started
:no_clp


:EXIT
