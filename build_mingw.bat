@echo off
rem Compile all of SIMH using MINGW make and gcc environment
rem
rem The makefile will determine if the needed WinPcap build 
rem components are available and the resulting simulators will
rem run with networking support when the WinPcap environment 
rem is installed on the running system.
rem
rem Individual simulator sources are in .\simulator_name
rem Individual simulator executables are to .\BIN
rem

rem		Add additional checks in case MinGW64, etal are installed	12/03/2022	SgC

    @setlocal enableextensions enabledelayedexpansion

rem		is MinGW installed?

    if not exist "C:\MinGW\bin" (
		echo  MinGW Environment is Unavailable - Exiting.
		exit /B 1
	) else (
		echo MinGW Environment located.
	)
	
rem		make sure MinGW is first in Path, just in case other packages
rem		like mingw64 or msys64 are also installed

	PATH=C:\MinGW\bin;%path%

rem		try to invoke gcc and mingw32-make

	gcc -v 1>NUL 2>NUL
	if ERRORLEVEL 1 (
		echo Unable to invoke gcc - Exiting.
		exit /B 1
	) 
	mingw32-make -v 1>NUL 2>NUL
	if ERRORLEVEL 1 (
		echo Unable to invoke mingw32-make - Exiting.
		exit /B 1
	) 

rem		MinGW Environment checks passed; start the build

	echo Building simulators...
	echo.

    if not exist BIN mkdir BIN
    mingw32-make -f makefile %*

	echo.
	echo Build_MinGW processing completed.
