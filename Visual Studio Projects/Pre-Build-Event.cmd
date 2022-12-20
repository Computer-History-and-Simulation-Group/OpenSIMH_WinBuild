rem
rem  This script performs several maintenance functions prior to building
rem  simh projects.  Some of these funtions are optional and depend on the
rem  needs of the project being built, and others are generic and are always
rem  performed.
rem
rem  The optional activities are invoked by passing parameters to this 
rem  procedure.  The parameters are:
rem     ROM     To run the BuildROMs program prior to executing a project
rem             build.  This program verifies that the include files containing
rem             ROM images are consistent with the ROM images from which they
rem             are derived.
rem     BUILD   To validate that the required dependent libraries and include
rem             files are available in the directory ..\Windows-Build\
rem             These libraries currently include winpcap, pthreads, SDL
rem             and LIBPCRE.
rem     LIBSDL  To validate that the required dependent SDL libraries and include
rem             files are available in the directory ..\Windows-Build\
rem     LIBPCRE To validate that the required dependent PCRE libraries and include
rem             files are available in the directory ..\..\Windows-Build\
rem
rem  In addition to the optional activities mentioned above, other activities
rem  are also performed.  These include:
rem       - performing the activities which make confirm or generate the git 
rem         repository commit id available in an include file during compiles.
rem
rem

rem 	Windows-Build integration into SIMH Base project - 07-16-2022 - SgC
rem			corrected directory locatiions, 
rem			Windows Build files moved to simh\Windows-Build
rem			General cleanup to improve readability
rem			_X_REQUIRED_WINDOWS_BUILD is now 20220714


rem Everything implicitly requires BUILD to also be set to have 
rem any meaning, it always gets set.

  set _X_BUILD=BUILD
  set _X_REQUIRED_WINDOWS_BUILD=20220714
  call :FindVCVersion _VC_VER

  set _PDB=%~dpn1.pdb
  if exist "%_PDB%" del/q "%_PDB%"
  set _PDB=

:_first_arg

  set _ARG=%~1
  if /i "%_ARG:~-4%" equ ".exe" shift /1
  set _ARG=

:_next_arg

  if "%1" == "" goto _done_args
  set _arg=
  if /I "%1" == "ROM"      set _arg=ROM
  if /I "%1" == "BUILD"    set _arg=BUILD
  if /I "%1" == "LIBSDL"   set _arg=LIBSDL
  if /I "%1" == "LIBPCRE"  set _arg=LIBPCRE
  if /I "%1" == "FINDFONT" set _arg=FINDFONT
  if "%_arg%" == ""        echo *** warning *** unknown parameter %1
  if /I "%1" == "FINDFONT" set _X_FontName=%2
  if /I "%1" == "FINDFONT" set _X_FontIncludeName=%3
  if /I "%_arg%" == "FINDFONT" shift
  if /I "%_arg%" == "FINDFONT" shift
  if not "%_arg%" == ""    set _X_%_arg%=%_arg%
  shift
  goto _next_arg

:_done_args

:_do_rom

  pushd ..
  if "%_X_ROM%" == "" goto _done_rom
  set _BLD=
  if exist BIN\NT\Win32-Debug\BuildTools\BuildROMs.exe   set _BLD=BIN\NT\Win32-Debug\BuildTools\BuildROMs.exe
  if exist BIN\NT\Win32-Release\BuildTools\BuildROMs.exe set _BLD=BIN\NT\Win32-Release\BuildTools\BuildROMs.exe
  if "%_BLD%" == "" echo ************************************************
  if "%_BLD%" == "" echo ************************************************
  if "%_BLD%" == "" echo **  Project dependencies are not correct.     **
  if "%_BLD%" == "" echo **  This project should depend on BuildROMs.  **
  if "%_BLD%" == "" echo ************************************************
  if "%_BLD%" == "" echo ************************************************
  if "%_BLD%" == "" echo error: Review the Output Tab for more details.
  if "%_BLD%" == "" exit 1
  %_BLD%
  if not errorlevel 1 goto _done_rom
  if not exist "BIN\NT\Win32-Release\BuildTools\BuildROMs.exe" exit 1  
  del "BIN\NT\Win32-Release\BuildTools\BuildROMs.exe"
  popd
  goto _do_rom

:_done_rom

  popd

:_check_build

  if "%_X_BUILD%" == "" goto _done_build

:_check_files

  call :FindVCVersion _VC_VER
  
  set _X_WINDOWS_BUILD=
  for /F "usebackq tokens=2" %%i in (`findstr /C:"WINDOWS-BUILD" ..\Windows-Build\Windows-Build_Versions.txt`) do SET _X_WINDOWS_BUILD=%%i
  set _X_LAST_WINDOWS_BUILD=
  if exist Pre-Build-Event.last-windows-build-version.txt for /F "usebackq tokens=2" %%i in (`findstr /C:"WINDOWS-BUILD" Pre-Build-Event.last-windows-build-version.txt`) do SET _X_LAST_WINDOWS_BUILD=%%i
  if "%_X_WINDOWS_BUILD%" EQU "%_X_LAST_WINDOWS_BUILD%" goto _new_or_same_windows_build
  
  echo Library support has been updated, forcing clean version determination
  if exist ..\Windows-Build\lib\Debug   rmdir/s/q ..\Windows-Build\lib\Debug
  if exist ..\Windows-Build\lib\Release rmdir/s/q ..\Windows-Build\lib\Release
  if exist ..\Windows-Build\lib\VisualCVersionSupport.txt del ..\Windows-Build\lib\VisualCVersionSupport.txt
  echo "WINDOWS-BUILD           %_X_WINDOWS_BUILD%" > Pre-Build-Event.last-Windows-Build-version.txt

:_new_or_same_windows_build

  set _X_WINDOWS_BUILD=
  set _X_LAST_WINDOWS_BUILD=
  if not exist ..\Windows-Build\lib\VisualCVersionSupport.txt goto _find_vc_support

  set _X_VC_VER=
  for /F "usebackq tokens=2*" %%i in (`findstr /C:"_VC_VER=%_VC_VER% " ..\Windows-Build\lib\VisualCVersionSupport.txt`) do set _X_VC_VER=%%i %%j
  if "%_X_VC_VER%" neq "" echo Library support for %_X_VC_VER% is available
  if "%_X_VC_VER%" neq "" goto _done_check_files
  
:_find_vc_support

  set _X_VC_VER_DIR=
  for /d %%i in ("..\Windows-Build\lib\*") do call :CheckDirectoryVCSupport _X_VC_VER_DIR %%i "..\Windows-Build\lib\"
  if "%_X_VC_VER_DIR%" equ "" goto _VC_VER_notice
  rem  echo "[_find_vc_support] Done _find_vc_support"
  rem  echo.

:_make_vc_support_active

  rem  echo "[_make_vc_support_active] _X_VC_VER_DIR       = %_X_VC_VER_DIR%"
  rem  echo "[_make_vc_support_active] _VC_VER             = %_VC_VER%"
  
  for /F "usebackq tokens=2*" %%i in (`findstr /C:"_VC_VER=%_VC_VER% " "%_X_VC_VER_DIR%\VisualCVersionSupport.txt"`) do set _X_VC_VER=%%i %%j
  echo Enabling Library support for %_X_VC_VER%
  
  rem  echo "[_make_vc_support_active] Calling procedure:    %_X_VC_VER_DIR%\Install-Library-Support.cmd"
  
  call "%_X_VC_VER_DIR%\Install-Library-Support.cmd"

  rem  echo "[_make_vc_support_active] Done _make_vc_support_active"

:_done_check_files
  rem  echo "[done_check_files] Done done_check_files"


  if "%_X_FINDFONT%" == "" goto _done_findfont
  if "%_X_FontName%" == "" goto _done_findfont
  echo. >%_X_FontIncludeName%.temp
  set FONTFILE=%windir%\Fonts\%_X_FontName%
  if not exist "%FONTFILE%" echo Can't find font %_X_FontName%
  if not exist "%FONTFILE%" goto _done_findfont
  set FONTFILE=%FONTFILE:\=/%
  echo #define FONTFILE %FONTFILE% >>%_X_FontIncludeName%.temp
  if not exist %_X_FontIncludeName% goto _found_font                                                                                                                                                                                                                                 
  fc %_X_FontIncludeName%.temp %_X_FontIncludeName% >NUL
  if NOT ERRORLEVEL 1 goto _done_findfont
  
:_found_font

  echo Found: %FONTFILE%
  move /Y %_X_FontIncludeName%.temp %_X_FontIncludeName% >NUL

:_done_findfont

  if exist %_X_FontIncludeName%.temp del %_X_FontIncludeName%.temp
  
:_done_build

:_CheckGit

  if not exist ..\.git goto _done_id
  call :FindGit _GIT_GIT
  if "%_GIT_GIT%" neq "" goto _SetId
  echo ** ERROR ** ERROR ** ERROR ** ERROR ** ERROR ** ERROR **
  echo ** ERROR ** ERROR ** ERROR ** ERROR ** ERROR ** ERROR **
  echo **                                                    **
  echo **  Your local simh code is in a git repository,      **
  echo **  however, the git program executable can not be    **
  echo **  readily found on your system.                     **
  echo **                                                    **
  echo **  You should download and install git from:         **
  echo **                                                    **
  echo **        https://git-scm.com/download/win            **
  echo **                                                    **
  echo **  while installing git for windows, be sure to      **
  echo **  select the option to 'Use Git from the Windows    **
  echo **  Command Prompt'                                   **
  echo **                                                    **
  echo **  You should logout and login again after initally  **
  echo **  installing git to be sure that the installation   **
  echo **  location is properly visible in your search path. **
  echo **                                                    **
  echo ** ERROR ** ERROR ** ERROR ** ERROR ** ERROR ** ERROR **
  echo ** ERROR ** ERROR ** ERROR ** ERROR ** ERROR ** ERROR **
  echo.
  echo error: Review the Output Tab for more details.
  echo.
  exit 1

:_done_git

:_SetId

  rem A race condition exists while creating the .git-commit-id.h file.
  rem This race can happen at the beginning of a parallel build where 
  rem several projects can start execution at almost the same time.

  set ACTUAL_GIT_COMMIT_ID=
  set ACTUAL_GIT_COMMIT_TIME=
  set ACTUAL_GIT_COMMIT_EXTRAS=
  set GIT_COMMIT_ID=
  set GIT_COMMIT_TIME=
  for /F "usebackq tokens=1" %%i in (`git update-index --refresh --`) do set ACTUAL_GIT_COMMIT_EXTRAS=+uncommitted-changes
  for /F "usebackq tokens=1" %%i in (`git log -1 "--pretty=%%H"`) do set ACTUAL_GIT_COMMIT_ID=%%i%ACTUAL_GIT_COMMIT_EXTRAS%
  for /F "usebackq tokens=1" %%i in (`git log -1 "--pretty=%%aI"`) do set ACTUAL_GIT_COMMIT_TIME=%%i
  if exist ..\.git-commit-id for /F "usebackq tokens=2" %%i in (`findstr /C:SIM_GIT_COMMIT_ID ..\.git-commit-id`) do set GIT_COMMIT_ID=%%i
  if exist ..\.git-commit-id for /F "usebackq tokens=2" %%i in (`findstr /C:SIM_GIT_COMMIT_TIME ..\.git-commit-id`) do set GIT_COMMIT_TIME=%%i
  if "%ACTUAL_GIT_COMMIT_ID%" neq "%GIT_COMMIT_ID%" "%_GIT_GIT%" log -1 --pretty="SIM_GIT_COMMIT_ID %%H%%%%ACTUAL_GIT_COMMIT_EXTRAS%%%%%%nSIM_GIT_COMMIT_TIME %%aI" >..\.git-commit-id
  set GIT_COMMIT_ID=%ACTUAL_GIT_COMMIT_ID%
  set GIT_COMMIT_TIME=%ACTUAL_GIT_COMMIT_TIME%
  set ACTUAL_GIT_COMMIT_ID=
  set ACTUAL_GIT_COMMIT_TIME=

:_VerifyGitCommitId.h

  set OLD_GIT_COMMIT_ID=
  if not exist .git-commit-id.h echo.>.git-commit-id.h
  for /F "usebackq tokens=3" %%i in (`findstr /C:SIM_GIT_COMMIT_ID .git-commit-id.h`) do set OLD_GIT_COMMIT_ID=%%i
  if "%GIT_COMMIT_ID%" equ "%OLD_GIT_COMMIT_ID%" goto _IdGood
  echo Generating updated .git-commit-id.h containing id %GIT_COMMIT_ID%
  echo #define SIM_GIT_COMMIT_ID %GIT_COMMIT_ID% >.git-commit-id.h
  echo #define SIM_GIT_COMMIT_TIME %GIT_COMMIT_TIME% >>.git-commit-id.h
  if errorlevel 1 echo Retrying...
  if errorlevel 1 goto _SetId

:_IdGood
:_done_id

  if not exist .git-commit-id.h echo. >.git-commit-id.h


goto End_Procedure




!	-------------------- Subroutines --------------------


:_VC_VER_notice

  echo *********************************
  echo *********************************
  echo **  Visual Studio Version: %_VC_VER%  **
  echo **  Visual Studio Version: %_VC_VER%  **
  echo **  Visual Studio Version: %_VC_VER%  **
  echo **  Visual Studio Version: %_VC_VER%  **
  echo **********************************************************
  echo **********************************************************
  echo **  Windows Build support for your Microsoft            **
  echo **  Visual Studio version is not available yet.         **
  echo **  Please create a new issue at:                       **
  echo **  https://github.com/open-simh/simh/issues describing **
  echo **  what you've done and support should be added soon.  **
  echo **  Otherwise, you can install an earlier version       **
  echo **  of Microsoft Visual Studio and use that.            **
  echo **********************************************************
  echo **********************************************************
  goto _ProjectInfo

:_ProjectInfo

  echo **********************************************************
  echo ****************** 0ReadMe_Projects.txt ******************
  type 0ReadMe_Projects.txt
  echo **********************************************************
  echo error: %_exit_reason%
  echo error: Review the Output Tab for more details.
  echo **********************************************************
  exit 1
  
	rem		Should never get here...
	
  goto End_Prodcedure

!	--------------------


:WhereInPath

  if "%~$PATH:1" NEQ "" exit /B 0
  exit /B 1

!	--------------------

:WhichInPath

  if "%~$PATH:1" EQU "" exit /B 1
  set %2=%~$PATH:1
  exit /B 0

!	--------------------

:FindGit

  set _GIT_TMP=%1
  call :WhichInPath git.exe _GIT_TMP_
  if "%_GIT_TMP_%" neq "" goto GitFound
  call :WhichInPath cl.exe _VC_CL_
  for /f "tokens=1-4 delims=\" %%a in ("%_VC_CL_%") do set _GIT_BASE_="%%a\%%b\%%c\%%d\"
  for /r %_GIT_BASE_% %%a in (git.exe) do if exist "%%a" set _GIT_TMP_=%%a

:GitFound

  set %_GIT_TMP%=%_GIT_TMP_%
  set _VC_CL_=
  set _GIT_BASE_=
  set _GIT_TMP_=
  set _GIT_TMP=
  exit /B 0


!	--------------------

:FindVCVersion

  call :WhichInPath cl.exe _VC_CL_
  for /f "tokens=3-9 delims=\" %%a in ("%_VC_CL_%") do call :VCCheck _VC_VER_NUM_ "%%a" "%%b" "%%c" "%%d" "%%e" "%%f" "%%g"
  for /f "delims=." %%a in ("%_VC_VER_NUM_%") do set %1=%%a
  set _VC_CL=
  exit /B 0

!	--------------------

:VCCheck

  set _VC_TMP=%1

:_VCCheck_Next

  shift
  set _VC_TMP_=%~1
  if "%_VC_TMP_%" equ "" goto _VCCheck_Done
  if "%_VC_TMP_:~0,24%" EQU "Microsoft Visual Studio " set %_VC_TMP%=%_VC_TMP_:Microsoft Visual Studio =%
  call :IsNumeric _VC_NUM_ %_VC_TMP_%
  if "%_VC_NUM_%" neq "" set %_VC_TMP%=%~1
  if "%_VC_NUM_%" neq "" goto _VCCheck_Done
  goto _VCCheck_Next

:_VCCheck_Done

  set _VC_TMP_=
  set _VC_TMP=
  set _VC_NUM_=
  exit /B 0

!	--------------------

:CheckDirectoryVCSupport

  rem set _VC_Check_Path=%~3%~2/
  rem echo "[CheckDirectoryVCSupport] original _VC_Check_Path = %_VC_Check_Path%"
  rem set _VC_Check_Path=%_VC_Check_Path:/=\%
  rem echo "[CheckDirectoryVCSupport] original _VC_Check_Path = %_VC_Check_Path%"
  
  set _VC_Check_Path=%~2
  set _VC_Check_Filespec=%_VC_Check_Path%\VisualCVersionSupport.txt
  rem echo "[CheckDirectoryVCSupport] _VC_Check_Path      = %_VC_Check_Path%"
  rem echo "[CheckDirectoryVCSupport] _VC_Check_Filespec  = %_VC_Check_Filespec%"
  rem echo "[CheckDirectoryVCSupport] Variable ~2 = %~2"
  rem echo "[CheckDirectoryVCSupport] Variable ~3 = %~3"
  if not exist "%_VC_Check_Filespec%" (
	echo "[CheckDirectoryVCSupport] VisualCVersionSupport.txt MISSING"
	exit /B 1
  )
  for /F "usebackq tokens=2*" %%k in (`findstr /C:"_VC_VER=%_VC_VER% " "%_VC_Check_Filespec%"`) do set %1=%_VC_Check_Path%
  rem echo "[CheckDirectoryVCSupport] _VC_Check_Path      = %_VC_Check_Path%"
  rem echo.
  exit /B 0

!	--------------------

:IsNumeric

  set _Numeric_TMP_=%~1
  set _Numeric_Test_=%2
  set _Numeric_Test_=%_Numeric_Test_:~0,1%
  set %_Numeric_TMP_%=
  if "%_Numeric_Test_%"=="0" set %_Numeric_TMP_%=1
  if "%_Numeric_Test_%"=="1" set %_Numeric_TMP_%=1
  if "%_Numeric_Test_%"=="2" set %_Numeric_TMP_%=1
  if "%_Numeric_Test_%"=="3" set %_Numeric_TMP_%=1
  if "%_Numeric_Test_%"=="4" set %_Numeric_TMP_%=1
  if "%_Numeric_Test_%"=="5" set %_Numeric_TMP_%=1
  if "%_Numeric_Test_%"=="6" set %_Numeric_TMP_%=1
  if "%_Numeric_Test_%"=="7" set %_Numeric_TMP_%=1
  if "%_Numeric_Test_%"=="8" set %_Numeric_TMP_%=1
  if "%_Numeric_Test_%"=="9" set %_Numeric_TMP_%=1
  set _Numeric_TMP_=
  set _Numeric_Test_=
  exit /B 0

!	--------------------

rem		Alternate code to:     call "%_X_VC_VER_DIR%\Install-Library-Support.cmd"
rem		This code not implemented 

:_Windows-Build_library
  
  call :FindVCVersion _VC_VER		! should already have this
  
  if not exist "..\Windows-Build\lib\Release" goto _setup_library
  if not exist "..\Windows-Build\lib\Release\VisualC.version" set _LIB_VC_VER=9
  if exist     "..\Windows-Build\lib\Release\VisualC.version" for /f "usebackq delims=." %%v in (`type "..\Windows-Build\lib\Release\VisualC.version"`) do set _LIB_VC_VER=%%v
  if %_LIB_VC_VER% EQU %_VC_VER% goto _done_library
  if %_VC_VER%     GEQ 14        goto _check_new_library
  if %_LIB_VC_VER% LSS 14        goto _done_library
  goto _setup_library

:_check_new_library

  if %_LIB_VC_VER% GEQ 14 goto _done_library

:_setup_library
	
  if %_VC_VER% LSS 14 set _VCLIB_DIR_="lib-VC2008"
  if %_VC_VER% GEQ 14 set _VCLIB_DIR_="lib-VC%_VC_VER%"
  
  if exist  "..\Windows-Build\lib\Release" rmdir/s/q "..\Windows-Build\lib\Release"
  if exist  "..\Windows-Build\lib\Debug"   rmdir/s/q "..\Windows-Build\lib\Debug"

  if exist "..\Windows-Build\lib\lib-VC2008\Debug"       xcopy /S /I /Y   "..\Windows-Build\lib\lib-VC2008\Debug\*"       "..\Windows-Build\lib\Debug\     > NUL 2>&1
  if exist "..\Windows-Build\lib\lib-VC2008\Release"     xcopy /S /I /Y   "..\Windows-Build\lib\lib-VC2008\Release\*"     "..\Windows-Build\lib\Release\"  > NUL 2>&1
  if exist "..\Windows-Build\lib\lib-VC2008\VisualCVersionSupport.txt"     copy /y "..\Windows-Build\lib\lib-VC2008\VisualCVersionSupport.txt" "..\Windows-Build\lib"  > NUL 2>&1

  if %_VC_VER% LSS 14 goto _done_filecopy  
  
  if exist "..\Windows-Build\lib\%_VCLIB_DIR_%\Debug     xcopy /S /I /Y   "..\Windows-Build\lib\%_VCLIB_DIR_%\Release\*"  "..\Windows-Build\lib\Debug\"    > NUL 2>&1
  if exist "..\Windows-Build\lib\%_VCLIB_DIR_%\Release   xcopy /S /I /Y   "..\Windows-Build\lib\%_VCLIB_DIR_%\Debug\*"    "..\Windows-Build\lib\Release\"  > NUL 2>&1
  if exist "..\Windows-Build\lib\%_VCLIB_DIR_%\VisualCVersionSupport.txt"  copy /y "..\Windows-Build\lib\%_VCLIB_DIR_%\VisualCVersionSupport.txt" "..\Windows-Build\lib"  > NUL 2>&1
  
:_done_filecopy  
  
  set _VCLIB_DIR_=
  set _LIB_VC_VER=

:_done_library


!	--------------------






:End_Procedure

exit 
exit