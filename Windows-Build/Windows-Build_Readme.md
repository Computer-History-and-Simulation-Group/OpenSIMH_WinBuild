# Windows-Build for SIMH

This directory contains the external dependencies needed to build full
asynchronous, networking and video support for the simh simulators on Windows.

The files provided here are only meant for users who want to build simh 
simulators under various versions of Microsoft Visual Studio.  

It contains five separate packages which the windows simh build depends on:

    * The WinPcap developer Pack                 (npcap / winpcap)
    * Posix threads for Windows                  (pthreads)
    * Simple DirectMedia Layer                   (SDL2)
    * Simple DirectMedia Layer True Type Fonts   (SDL2_ttf)
    * Perl Compatible Regular Expressions        (PCRE)

The Visual Studio Projects in the OpenSIMH source tree presume that 
the directory containing this file should be located in a
sub-directory of the SIMH source code.  The makefile which can
be used by MinGW compiler also presumes the same directory structure.

For Example, the directory structure should look like:

    ...\simh\PDP11\pdp11_cpu.c
    ...\simh\VAX\vax_cpu.c
    ...\simh\scp.c
    ...\simh\makefile
    ...\simh\Visual Studio Projects\simh.sln
    ...\simh\Visual Studio Projects\VAX.vcproj
    ...\simh\Windows-Build\pthreads\pthread.h
    ...\simh\Windows-Build\winpcap\WpdPack\Include\pcap.h
    ...\simh\Windows-Build\winpcap\WpdPack\Include\pcap.h
    ...\simh\Windows-Build\include\SDL2\SDL.h
    ...\simh\Windows-Build\lib\lib-VC2008\Release\SDL2.lib

The build simulators are placed in a BIN subidrectory:

    ...\simh\BIN\NT\Win32-Release\vax.exe

#

The ..\simh\Windows-Build\winpcap directory contains Version 4.1.2 of 
the winpcap developer pack from: 

     http://www.winpcap.org/devel.htm

The **..\simh\Windows-Build\pthreads** directory contains the source to the 
next release of the pthreads-win32 Posix Threads package for the windows 
platform.

The **..\simh\Windows-Build\include\SDL2** directory contains the header files
and the SDL2 library files are in **..simh\Windows-Build\lib\lib-VC20nn\Release** ( or \Debug)

This files are derived from the code in in the zip file: 

     http://www.libsdl.org/release/SDL2-2.0.22.zip.  

The modifications produce SDL libraries which can be statically linked into OpenSIMH simulator
binaries when building with the Microsoft Visual Studio compilers.  These binaries will 
then run without external DLL dependencies.  

The MinGW link libraries are also provided. These have been extracted from:

     http://www.libsdl.org/release/SDL2-devel-2.0.22-mingw.tar.gz 

along with the SDL2.dll file which is required when running a simulator with video 
support if it is compiled with the MinGW gcc compiler.  These have been placed in the **..\simh\Windows-Build\libSDL2\SDL2-32bit-mingw32** directory.

The SDL True Type Font support is also modified to produce a static library 
with the original source from:

     https://www.libsdl.org/projects/SDL_ttf/release/SDL2_ttf-2.0.12.zip

The **..\simh\Windows-Build\PCRE** directory contains the source to PCRE version
8.45 the Perl Compatible Regular Expression library.

#

