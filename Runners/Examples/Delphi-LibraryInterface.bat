for %%I in (.) do set CurrDirName=%%~nxI
echo %CurrDirName%

set ALTIUM64_HOME=C:\Altium\%CurrDirName%\AD\
set ALTIUM_HOME=C:\Altium\%CurrDirName%\AD
set UDM_DEBUG_ROOT=C:\Dev\AD_DDM_Tests
set X2_ROOT=C:\Dev\%CurrDirName%\

"%DELPHI_PATH%" "C:\Dev\%CurrDirName%\x2\edp\LibraryInterface\Source Code\LibraryInterface.dproj"