for %%I in (.) do set CurrDirName=%%~nxI
echo %CurrDirName%

set ALTIUM64_HOME=C:\Altium\%CurrDirName%\AD
set ALTIUM_HOME=C:\Altium\%CurrDirName%\AD
set UDM_DEBUG_ROOT=C:\Dev\AD_DDM_Tests
"%RIDER_PATH%" "C:\Dev\%CurrDirName%\x2\edp\DesignReuse\Source Code\Altium.DesignReuse.sln"
