@if defined TRACEON (@echo on) else (@echo off)

  REM  If this batch file works, then it was written by Fish.
  REM  If it doesn't then I don't know who the heck wrote it.

  goto :init

::-----------------------------------------------------------------------------
::                            RUNTEST.CMD
::-----------------------------------------------------------------------------
:help

  echo.
  echo     NAME
  echo.
  echo         %~n0:    Run Hercules automated test(s).
  echo.
  echo     SYNOPSIS
  echo.
  echo         %~n0     [ -d tdir ]  [-n tname]  [-f ftype]  [-t factor]
  echo                     [-64 ^| -32 ]  [-b build]  [-r [rpts[:fails]]]
  echo                     [{-v QUIET ^| name:value} ... ]  [--noexit]
  echo.
  echo     EXAMPLE
  echo.
  echo         ..\herc\tests\%~n0   -d ..\herc\tests -n *bsf -v quiet
  echo.
  echo     ARGUMENTS
  echo.
  echo         -d tdir     The path from the current directory to the 'tests'
  echo                     subdirectory. The path must not contain any blanks.
  echo                     The default value is "..\hyperion\tests".
  echo.
  echo         -n tname    File name of test file omitting the file extension
  echo                     ^(see -f option^) or the default "*" ^(without the
  echo                     quotes^) to run all tests in the -d directory.
  echo.
  echo         -f ftype    File type of the test files. The default is "tst".
  echo.
  echo         -t factor   Is an optional test timeout factor between 1.0
  echo                     and %mttof%. The test timeout factor is used to
  echo                     increase each test script's timeout value so as
  echo                     to compensate for the speed of your own system
  echo                     compared to the speed of the system the tests
  echo                     were designed for. See NOTES for more info.
  echo.
  echo         -64, -32    Which host architecture of Hercules binaries should
  echo                     be used: the 64-bit version or the 32-bit version.
  echo                     Optional. The default is -64.
  echo.
  echo         -b build    Either 'DEBUG' or 'RETAIL' indicating which build
  echo                     of Hercules should be used: the unoptimized debug
  echo                     build or the optimized release build.  Optional.
  echo                     The default is to use the optimized release build.
  echo.
  echo         -r          Optional repeat switch. When specified, %~n0
  echo                     will re-run the specified test^(s^) rpts times or
  echo                     until fails failures occur. The default if neither
  echo                     is specified is "%defrpts%:%deffail%". The --noexit option is
  echo                     ignored when the -r repeat option is specified.
  echo.
  echo         -v var...   Optional variable^(s^) to pass to the redtest.rexx
  echo                     script such as QUIET or name:value. You may repeat
  echo                     this option as many times as neeed.
  echo.
  echo         --noexit    Specify --noexit to suppress the exit command that
  echo                     normally terminates the test cases. This will allow
  echo                     you to poke around with console commands after the
  echo                     test script has run. Note: the --noexit option is
  echo                     ignored when the -r repeat option is specified.
  echo.
  echo     NOTES
  echo.
  echo         %~nx0 requires Open Rexx or Regina Rexx to be installed
  echo         with Open Rexx being the preferred choice.
  echo.
  echo         The 'tests' subdirectory is expected to be a subdirectory
  echo         of the main Hercules source code directory. That is to say
  echo         the parent directory of the directory specified in the -d
  echo         option is presumed to be the Hercules source code directory
  echo         where the "msvc..." subdirectories containing the binaries
  echo         used by the -64/-32/-b options are expected to exist.
  echo.
  echo         Use a test timeout factor value greater than 1.0 on slower
  echo         systems to give each test a slightly longer period of time
  echo         to complete.  Test timeout factor values (used internally
  echo         on special 'runtest' test script statements) are a safety
  echo         feature designed to prevent runaway tests from never ending.
  echo         Normally tests always end automatically the very moment they
  echo         are done.
  echo.
  echo         Only the '-v' option may be specified multiple times which
  echo         are passed to redtest.rexx in the order specified. For all
  echo         other options only the last value specified is used.
  echo.
  echo         %~nx0 uses "%wfn%" as the base name for all of its
  echo         work files. Therefore all "%wfn%.*" files in the current
  echo         directory may be deleted and/or modified as a result of
  echo         invoking %~n0.
  echo.
  echo         The results of the test runs are directed into a Hercules
  echo         logfile called %wfn%.out in the current directory. If any
  echo         tests fail you should begin your investigation there.
  echo.
  echo     EXIT STATUS
  echo.
  echo         n           Number of tests which have failed: 0 if all
  echo                     tests passed (success). Non-zero otherwise.
  echo.
  echo     AUTHOR
  echo.
  echo         "Fish"      (David B. Trout)
  echo.
  echo     VERSION
  echo.
  echo         3.0         (December 13, 2015)
  echo.

  set "hlp=1"
  set /a "rc=1"
  %exit%


::-----------------------------------------------------------------------------
::                              INIT
::-----------------------------------------------------------------------------
:init

  setlocal
  pushd .

  set "TRACE=if defined DEBUG echo"
  set "return=goto :EOF"
  set "exit=goto :exit"
  set "maxrc=0"
  set "rc=0"
  set "hlp="

  set "tool1=rexx.exe"

  set "tdir="
  set "tname="
  set "noexit="
  set "ftype="
  if "%PROCESSOR_ARCHITECTURE%" == "AMD64" set "vars=ptrsize=8"
  if "%PROCESSOR_ARCHITECTURE%" == "IA64"  set "vars=ptrsize=8"
  if "%PROCESSOR_ARCHITECTURE%" == "x86"   set "vars=ptrsize=4"
  set "bitness="
  set "build="
  set "repeat="
  set "maxruns="
  set "maxfail="
  set "ttof="
  call :calc_mttof

  set "deftdir=..\hyperion\tests"
  set "deftname=*"
  set "defftype=tst"
  set "defbitness=64"
  set "defbuild=retail"
  set "defrepeat="
  set "defrpts=100"
  set "deffail=3"

  set "wfn=allTests"
  set "cfg=tests.conf"

  set "cmdargs=%*"
  goto :parse_args


::-----------------------------------------------------------------------------
::                           calc_mttof
::-----------------------------------------------------------------------------
:calc_mttof

  @REM  'mttof' is the maximum test timeout factor (runtest script statement)
  @REM  'msto' is the maximum scripting timeout (i.e. script pause statement)

  setlocal
  set "mttof="
  set "msto=300.0"
  echo WScript.Echo Eval(WScript.Arguments(0)) > %wfn%.vbs
  for /f %%i in ('cscript //nologo %wfn%.vbs "(((4.0 * 1024.0 * 1024.0 * 1024.0) - 1.0) / 1000000.0 / %msto%)"') do set mttof=%%i
  for /f %%i in ('cscript //nologo %wfn%.vbs "Int(10.0 * %mttof%) / 10.0"') do set mttof=%%i
  del %wfn%.vbs
  endlocal && set "mttof=%mttof%"
  %return%


::-----------------------------------------------------------------------------
::                           load_tools
::-----------------------------------------------------------------------------
:load_tools

  call :findtool "%tool1%"
  if not defined # (
    echo ERROR: required tool "%tool1%" not found. 1>&2
    set /a "rc=1"
  )

  %return%


::-----------------------------------------------------------------------------
::                           findtool
::-----------------------------------------------------------------------------
:findtool

  set "@=%path%"
  set "path=.;%path%"
  set "#=%~$PATH:1"
  set "path=%@%"
  %return%


::-----------------------------------------------------------------------------
::                            isfile
::-----------------------------------------------------------------------------
:isfile

  if not exist "%~1" (
    set "isfile="
    %return%
  )
  set "isfile=%~a1"
  if defined isfile (
    if /i "%isfile:~0,1%" == "d" set "isfile="
  )
  %return%


::-----------------------------------------------------------------------------
::                            isdir
::-----------------------------------------------------------------------------
:isdir

  if not exist "%~1" (
    set "isdir="
    %return%
  )
  set "isdir=%~a1"
  if defined isdir (
    if /i not "%isdir:~0,1%" == "d" set "isdir="
  )
  %return%


::-----------------------------------------------------------------------------
::                            isnum
::-----------------------------------------------------------------------------
:isnum

  set "@=%~1"
  set "isnum="
  for /f "delims=0123456789" %%i in ("%@%\") do if "%%i" == "\" set "isnum=1"
  %return%


::-----------------------------------------------------------------------------
::                            timesecs
::-----------------------------------------------------------------------------
:timesecs

  @REM   Converts the passed time-of-day value in %time% format
  @REM   to the number of seconds since midnight.

  setlocal enabledelayedexpansion
  for /f "tokens=1,2,3,4 delims=:,. " %%a in ("%~1") do (
    @REM Must prevent values starting with '0' from being treated as octal!
    set /a "#=((1%%a - 100) * 60 * 60) + ((1%%b - 100) * 60) + (1%%c - 100) + (((1%%d - 100) + 50) / 100)"
  )
  endlocal && set "#=%#%"
  %return%


::-----------------------------------------------------------------------------
::                            difftime
::-----------------------------------------------------------------------------
:difftime

  @REM   Calculate difference between two %time% values:
  @REM
  @REM      difftime  {begtime}  {endtime}
  @REM
  @REM   If the endtime is less than begtime it is presumed to have
  @REM   crossed a day boundary. Only durations of less than 2 days
  @REM   is supported. The returned value is in number of seconds.

  call :timesecs "%~1"
  set /a "t1=%#%"
  call :timesecs "%~2"
  set /a "t2=%#%"
  if %t2% LSS %t1% set /a "t2=%t2% + 86400"
  set /a "#= %t2% - %t1%"
  %return%


::-----------------------------------------------------------------------------
::                            dureng
::-----------------------------------------------------------------------------
:dureng

  @REM   Format a duration value in number of seconds to long format.
  @REM   E.g. "1 day, 2 hours, 34 minutes, 56 seconds"

  set /a "sd=60 * 60 * 24"
  set /a "sh=60 * 60"
  set /a "sm=60"
  set /a "ss=%~1"
  set /a "dd=(ss             ) / sd"
  set /a "hh=(ss -= (dd * sd)) / sh"
  set /a "mm=(ss -= (hh * sh)) / sm"
  set /a "ss=(ss -= (mm * sm))"
  set "#="
  if   %dd% GTR 0 (
    if %dd% GTR 1 (
      set "#=%dd% days, "
    ) else (
      set "#=%dd% day, "
    )
  )
  if   %hh% GTR 0 (
    if %hh% GTR 1 (
      set "#=%#%%hh% hours, "
    ) else (
      set "#=%#%%hh% hour, "
    )
  )
  if   %mm% GTR 0 (
    if %mm% GTR 1 (
      set "#=%#%%mm% minutes, "
    ) else (
      set "#=%#%%mm% minute, "
    )
  )
  if   %ss% GTR 0 (
    if %ss% GTR 1 (
      set "#=%#%%ss% seconds, "
    ) else (
      set "#=%#%%ss% second, "
    )
  )
  if defined # (
    set "#=%#:~0,-2%"
  ) else (
    set "#=less than 1 second"
  )
  %return%


::-----------------------------------------------------------------------------
::                              stndrdth
::-----------------------------------------------------------------------------
:stndrdth

  @REM  1st, 2nd, 3rd, 4th, ... 120th, 121st, 122nd, 123rd, etc...

  set       "@=%~1"
  if        %@:~-1% EQU 1 (set "#=st"
  ) else if %@:~-1% EQU 2 (set "#=nd"
  ) else if %@:~-1% EQU 3 (set "#=rd"
  ) else                   set "#=th"
  %return%


::-----------------------------------------------------------------------------
::                              logmsg
::-----------------------------------------------------------------------------
:logmsg

  @REM  Use this function when leading blanks are NOT important
  @REM  but everything else IS important:
  @REM
  @REM            call :logmsg Hello World!
  @REM
  @REM  PROGRAMMING NOTE: we need to use "enabledelayedexpansion" so
  @REM  the entire arguments string gets printed exactly as it was
  @REM  passed, with all embedded (but not leading) blanks and quoted
  @REM  variables exactly as they were passed on the command line.

  setlocal ENABLEDELAYEDEXPANSION
  set @=%*
  echo %time%: !@!
  endlocal
  %return%


::-----------------------------------------------------------------------------
::                           parse_args
::-----------------------------------------------------------------------------
:parse_args

  set /a "rc=0"

  if /i "%~1" == ""        goto :help
  if /i "%~1" == "?"       goto :help
  if /i "%~1" == "/?"      goto :help
  if /i "%~1" == "-?"      goto :help
  if /i "%~1" == "-h"      goto :help
  if /i "%~1" == "--help"  goto :help

  call :load_tools
  if not "%rc%" == "0" %exit%

  goto :parse_options_loop


::-----------------------------------------------------------------------------
::                   ( parse_options_loop helper )
::-----------------------------------------------------------------------------
:isopt

  @REM  Examines first character of passed value to determine
  @REM  whether it's the next option or not. If it starts with
  @REM  a '/' or '-' then it's the next option. Else it's not.

  set "isopt=%~1"
  if not defined isopt %return%
  set "isopt=%isopt:~0,1%"
  if "%isopt%" == "/" %return%
  if "%isopt%" == "-" %return%
  set "isopt="
  %return%


::-----------------------------------------------------------------------------
::                   ( parse_options_loop helper )
::-----------------------------------------------------------------------------
:parseopt

  @REM    opt:        The current option as-is (e.g. "-d")
  @REM    optname:    Just the characters following the '-' (e.g. "d")

  set "opt=%~1"
  set "optname=%opt:~1%"
  %return%


::-----------------------------------------------------------------------------
::                   ( parse_options_loop helper )
::-----------------------------------------------------------------------------
:parse_opt_value

  @REM  First passed argument is the name of the option variable.
  @REM  The second passed argument is the value to be parsed.

  @REM  If the value to be parsed isn't actually a value (but is
  @REM  instead the next option), the specified option variable
  @REM  is set to empty/undefined. Otherwise the specified option
  @REM  variable is set to the unparsed value.

  set "opt_varname=%~1"
  set "opt_varvalue=%~2"
  set "%opt_varname%="
  call :isopt "%opt_varvalue%"
  if not defined isopt set "%opt_varname%=%opt_varvalue%"
  %return%


::-----------------------------------------------------------------------------
::                        parse_options_loop
::-----------------------------------------------------------------------------
:parse_options_loop

  if "%~1" == "" goto :options_loop_end
  call :isopt "%~1"
  if not defined isopt goto :parse_positional_opts
  call :parseopt "%~1"
  shift /1

  if /i "%optname%" == "d" goto :parse_d_opt
  if /i "%optname%" == "n" goto :parse_n_opt
  if /i "%optname%" == "f" goto :parse_f_opt
  if /i "%optname%" == "t" goto :parse_t_opt
  if /i "%optname%" == "b" goto :parse_b_opt
  if /i "%optname%" == "r" goto :parse_r_opt
  if /i "%optname%" == "v" goto :parse_v_opt

  if /i "%optname%" == "32" goto :parse_3264_opt
  if /i "%optname%" == "64" goto :parse_3264_opt

  @REM  Determine if --xxxx option
  call :isopt "%optname%"
  if not defined isopt goto :parse_unknown_opt
  call :parseopt "%optname%"

  if /i "%optname%" == "noexit" goto :parse_noexit_opt

  goto :parse_unknown_opt

:parse_d_opt

  call :parse_opt_value tdir "%~1"
  if not defined    tdir goto :parse_missing_argument
  shift /1
  goto :parse_options_loop

:parse_n_opt

  call :parse_opt_value tname "%~1"
  if not defined    tname goto :parse_missing_argument
  shift /1
  goto :parse_options_loop

:parse_f_opt

  call :parse_opt_value ftype "%~1"
  if not defined    ftype goto :parse_missing_argument
  shift /1
  goto :parse_options_loop

:parse_b_opt

  call :parse_opt_value build "%~1"
  if not defined    build goto :parse_missing_argument
  shift /1
  goto :parse_options_loop

:parse_t_opt

  call :parse_opt_value ttof "%~1"
  if not defined    ttof goto :parse_missing_argument
  shift /1
  goto :parse_options_loop

:parse_v_opt

  call :parse_opt_value var "%~1"
  if not defined    var goto :parse_missing_argument

  @REM  Parse ':' delimited argument value...
  for /f "tokens=1,2* delims=:" %%a in ("%var%") do (
    set "a=%%a"
    set "b=%%b"
  )

  if defined b (
    set "vars=%vars% %a%=%b%"
  ) else (
    set "vars=%vars% %a%"
  )

  shift /1
  goto :parse_options_loop

:parse_r_opt

  @REM  NOTE: The repeat option's argument is OPTIONAL
  call :parse_opt_value repeat "%~1"
  if not defined repeat (
    set "repeat=1"
    goto :parse_options_loop
  )

  @REM  Parse ':' delimited argument value...
  for /f "tokens=1,2* delims=:" %%a in ("%repeat%") do (
    set "maxruns=%%a"
    set "maxfail=%%b"
  )
  shift /1
  goto :parse_options_loop

:parse_3264_opt

  set "bitness=%optname%"
  goto :parse_options_loop

:parse_noexit_opt

  set "noexit=1"
  goto :parse_options_loop

:parse_positional_opts

  @REM  We no longer support any positional arguments
  goto :parse_unknown_opt

  @REM  But if we did, this is how we would parse them...

:checkif_positional_argument_1

  if defined positional_argument_1 goto :checkif_positional_argument_2
  set "positional_argument_1=%~1"
  goto :parse_options_loop

:checkif_positional_argument_2

  if defined positional_argument_2 goto :checkif_positional_argument_3
  set "positional_argument_2=%~1"
  goto :parse_options_loop

:checkif_positional_argument_3

  if defined positional_argument_1 goto :checkif_positional_argument_4
  set "positional_argument_3=%~1"
  goto :parse_options_loop

:checkif_positional_argument_4

  @REM There is no positional argument 4!
  goto :parse_unknown_opt

:parse_unknown_opt

  echo ERROR: Unknown/unsupported option '%opt%'. 1>&2
  shift /1
  set /a "rc=1"
  goto :parse_options_loop

:parse_missing_argument

  echo ERROR: Missing '%opt%' argument. 1>&2
  set /a "rc=1"
  goto :parse_options_loop

:options_loop_end

goto :skip
  @REM  Debug: values after parsing
  echo.
  echo tdir     = %tdir%
  echo tname    = %tname%
  echo ftype    = %ftype%
  echo build    = %build%
  echo ttof     = %ttof%
  echo vars     = %vars%
  echo bitness  = %bitness%
  echo.
  echo noexit   = %noexit%
  echo repeat   = %repeat%
  echo maxruns  = %maxruns%
  echo maxfail  = %maxfail%
  echo.
:skip

  goto :validate_args


::-----------------------------------------------------------------------------
::                          validate_args
::-----------------------------------------------------------------------------
:validate_args

  if not defined tdir    set "tdir=%deftdir%"
  if not defined tname   set "tname=%deftname%"
  if not defined ftype   set "ftype=%defftype%"
  if not defined bitness set "bitness=%defbitness%"
  if not defined build   set "build=%defbuild%"
  if not defined repeat  set "repeat=%defrepeat%"
  if not defined maxruns set "maxruns=%defrpts%"
  if not defined maxfail set "maxfail=%deffail%"


  @REM Validate path to tests directory

  call :isdir "%tdir%"
  if not defined isdir (
    echo ERROR: tests directory "%tdir%" does not exist. 1>&2
    set /a "rc=1"
  )


  @REM Validate test(s) name and file type

  if not exist "%tdir%\%tname%.%ftype%" (
    echo ERROR: Test^(s^) "%tdir%\%tname%.%ftype%" not found. 1>&2
    set /a "rc=1"
  )


  @REM Validate retail/debug build option (only first char is checked)

  set "dbg=%build%"
  if defined dbg (
    if /i not "%dbg:~0,1%" == "d" (
      if /i not "%dbg:~0,1%" == "r" (
        echo ERROR: Build must be either 'Retail' or 'Debug'. 1>&2
        set /a "rc=1"
      )
    )
    if /i "%dbg:~0,1%" == "d" set "dbg=debug."
    if /i "%dbg:~0,1%" == "r" set "dbg="
  )


  @REM Validate which herc binaries to use (64-bit or 32-bit)

  if "%bitness%" == "64" (
    set "hdir=msvc.%dbg%AMD64.bin"
  ) else if "%bitness%" == "32" (
    set "hdir=msvc.%dbg%dllmod.bin"
  ) else (
    echo ERROR: Which binaries to use must be either '64' or'32' 1>&2
    set /a "rc=1"
  )

  if defined hdir (
    call :isdir "%tdir%\..\%hdir%"
    if not defined isdir (
      if defined dbg set "xxx=debug "
      echo ERROR: %bitness%-bit %xxx%directory "%tdir%\..\%hdir%" does not exist. 1>&2
      set /a "rc=1"
    ) else (
      call :isfile "%tdir%\..\%hdir%\hercules.exe"
      if not defined isfile (
        echo ERROR: Hercules executable "%tdir%\..\%hdir%\hercules.exe" not found. 1>&2
        set /a "rc=1"
      )
    )
  )


  @REM Validate repeat option arguments

  if not defined repeat goto :skip

  set "noexit="

  call :isnum "%maxruns%"
  if not defined isnum (
    echo ERROR: Repeats value '%maxruns%' is not numeric. 1>&2
    set /a "rc=1"
  )

  call :isnum "%maxfail%"
  if not defined isnum (
    echo ERROR: Fails value '%maxfail%' is not numeric. 1>&2
    set /a "rc=1"
  )
:skip


  @REM Validate /t factor option

  if not defined ttof goto :skip

  echo If %ttof% ^< 1.0 Or %ttof% ^> %mttof% Then   >  %wfn%.vbs
  echo Wscript.Echo "0"                             >> %wfn%.vbs
  echo Else                                         >> %wfn%.vbs
  echo Wscript.Echo "1"                             >> %wfn%.vbs
  echo End If                                       >> %wfn%.vbs

  for /f %%i in ('cscript //nologo %wfn%.vbs 2^>^&1') do set ok=%%i
  del %wfn%.vbs
  %TRACE% "mttof=%mttof%, ttof=%ttof%: ok=%ok%"

  if not "%ok%" == "1" (
    echo ERROR: Test timeout factor '%ttof%' not within valid range of 1.0 to %mttof%. 1>&2
    set /a "rc=1"
  )
:skip


  @REM Add validation of other arguments here...

  goto :validate_args_done


:validate_args_done

  if not "%rc%" == "0" %exit%

goto :skip
  @REM  Debug: values after validation
  echo.
  echo tdir     = %tdir%
  echo tname    = %tname%
  echo ftype    = %ftype%
  echo build    = %build%
  echo ttof     = %ttof%
  echo vars     = %vars%
  echo bitness  = %bitness%
  echo.
  echo noexit   = %noexit%
  echo repeat   = %repeat%
  echo maxruns  = %maxruns%
  echo maxfail  = %maxfail%
  echo.
  goto :exitnow
:skip

  goto :begin


::-----------------------------------------------------------------------------
::                              BEGIN
::-----------------------------------------------------------------------------
:begin

  set "begin=1"

  echo.
  if defined repeat (
    if defined cmdargs (
      call :logmsg Begin: "%~n0 %cmdargs%" ...
    ) else (
      call :logmsg Begin: "%~n0" ...
    )
  ) else (
    if defined cmdargs (
      echo Begin: "%~n0 %cmdargs%" ...
    ) else (
      echo Begin: "%~n0" ...
    )
    echo.
  )


  @REM Delete any leftover work files from previous run

  if exist %wfn%.tst  del /f %wfn%.tst
  if exist %wfn%.rc   del /f %wfn%.rc
  if exist %wfn%.out  del /f %wfn%.out
  if exist %wfn%.txt  del /f %wfn%.txt


  @REM Build test script consisting of all *.tst files concatenated together

  echo defsym testpath %tdir%     >> %wfn%.tst
  for %%a in (%tdir%\%tname%.%ftype%) do (
    echo msglvl -debug +emsgloc   >> %wfn%.tst
    echo ostailor null            >> %wfn%.tst
    echo numcpu 1                 >> %wfn%.tst
    echo mainsize 2               >> %wfn%.tst
    type "%%a"                    >> %wfn%.tst
  )
  if not defined noexit echo exit >> %wfn%.tst


  @REM Build startup .rc file which invokes the test script

  echo script %wfn%.tst >> %wfn%.rc


  @REM Initialize counters

  set /a "runs=0"
  set /a "totruns=0"
  set /a "totfail=0"
  set /a "failtimes=0"
  set "begtime=%time%"


  @REM Get started!

  if defined repeat call :logmsg
  goto :repeat_loop


::-----------------------------------------------------------------------------
::                           Run the test
::-----------------------------------------------------------------------------
:repeat_loop

  @REM  Start Hercules using specified .rc file which calls our test script.
  @REM  Note: Test option must be "-t" (dash/hypen T), not "/t" (slash T)!
  @REM  Hercules doesn't understand "/" options. Furthermore, it must also
  @REM  be speified as all one argument too: e.g. -t2.0, not -t 2.0.

  if defined noexit (
    "%tdir%\..\%hdir%\hercules.exe" -t%ttof% -f %tdir%\%cfg% -r %wfn%.rc > %wfn%.out
  ) else (
    "%tdir%\..\%hdir%\hercules.exe" -t%ttof% -f %tdir%\%cfg% -r %wfn%.rc > %wfn%.out 2>&1
  )


  @REM Call rexx script to parse the log lines and generate the report

  rexx.exe "%tdir%\redtest.rexx" %wfn%.out %vars% > %wfn%.txt 2>&1
  set /a "rc=%errorlevel%"


  @REM  If the repeat option wasn't specified then we're done
  @REM  Otherwise update the counters and check for failure

  if not defined repeat %exit%

  set /a "runs=runs+1"
  set /a "totruns=totruns+1"

  if %rc% NEQ 0 (
    set /a "totfail=totfail+1"
    if %rc% GTR %maxrc% (
      set /a "maxrc=%rc%"
    )
  )


  @REM  Report any failure
  @REM  Stop repeating once limit is reached
  @REM  Otherwise repeat the same test over again

  if %rc% NEQ 0 call :report_failure

  if %totruns% GEQ %maxruns% %exit%
  if %totfail% GEQ %maxfail% %exit%

  goto :repeat_loop


::-----------------------------------------------------------------------------
::                            report_failure
::-----------------------------------------------------------------------------
:report_failure


  @REM Accumulate elapsed times since each preceding failure

  if %totfail% LEQ 1 set "begfail=%begtime%"
  set "endfail=%time%"
  call :difftime %begfail% %endfail%
  set /a "failtimes=failtimes + #"
  set "begfail=%endfail%"


  @REM Show them the failure...

  echo.
  type %wfn%.txt
  echo.


  @REM Report on which run the failure occurred...

  call :stndrdth %runs%
  call :logmsg ** FAILURE #%totfail% on %runs%%#% run **


  @REM Reset the 'runs' counter and return

  set /a "runs=0"
  %return%


::-----------------------------------------------------------------------------
::                               EXIT
::-----------------------------------------------------------------------------
:exit


  @REM Quick exit if syntax error...

  if not defined begin (
    set /a "maxrc=%rc%"
    if not defined hlp echo INFO:  Use "%~n0 /?" to get help. 1>&2
    goto :exitnow
  )

  @REM Exit now if normal non-repeat run...

  if not defined repeat (
    type %wfn%.txt
    echo.
    if %rc% EQU 0 (
      echo End: ** Success! **
    ) else (
      echo End: ** FAILURE! **
    )
    goto :exitnow
  )


  @REM Display ending repeat run report...

  if %totfail% EQU 0 (
    call :logmsg ** Successfully completed %maxruns% runs in a row without any failures! **
  )

  set "endtime=%time%"
  call :difftime %begtime% %endtime%
  set /a "totsecs=%#%"
  if %totfail% EQU 0 goto :skip


  @REM Report failure rate/frequency...

  set /a "pct=((totfail*1000)+5)/totruns"
  if %pct% GTR 1000 set /a "pct=1000"
  if %pct% LSS   10 set    "pct=0%pct%"
  set "pct=%pct:~0,-1%.%pct:~-1%"
  echo.
  call :logmsg ** %totfail% FAILURES in %totruns% runs (%pct%%%%% FAILURE rate) **

  set /a "every=totruns/totfail"
  call :stndrdth %every%
  call :logmsg ** On average a failure occurred every %every%%#% run **

  set /a "every=failtimes/totfail"
  call :dureng %every%
  call :logmsg ** On average a failure occurred every %#% **

:skip


  call :dureng %totsecs%
  call :logmsg
  call :logmsg Duration: %#%


:exitnow

  popd
  endlocal && exit /b %maxrc%


::-----------------------------------------------------------------------------
::                              (( EOF ))
::-----------------------------------------------------------------------------
