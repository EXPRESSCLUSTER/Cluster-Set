rem ***************************************
rem *              stop.bat               *
rem *                                     *
rem * title   : stop script file sample   *
rem * date    : 2022/12/31                *
rem ***************************************

echo %date% %time%

rem ***************************************
rem Check startup attributes
rem ***************************************
IF "%CLP_EVENT%" == "START" GOTO NORMAL
IF "%CLP_EVENT%" == "FAILOVER" GOTO FAILOVER

rem Cluster Server is not started
GOTO no_clp


rem ***************************************
rem Process for normal quitting program
rem ***************************************
:NORMAL
clplogcmd -m "Normal stop process %CLP_EVENT%" -l INFO

IF "%CLP_FACTOR%" EQU "" (
echo "The script was stopped"
)
IF "%CLP_FACTOR%" == "GROUPSTOP" (
echo "The group was stopped"
)
IF "%CLP_FACTOR%" == "GROUPMOVE" (
echo "The group was moved"
cd "%CLP_SCRIPT_PATH%"
)

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
rem Process for failover
rem ***************************************
:FAILOVER

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
