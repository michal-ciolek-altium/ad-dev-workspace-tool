for %%I in (.) do set CurrDirName=%%~nxI
echo %CurrDirName%

set ALTIUM64_HOME=C:\Altium\%CurrDirName%\AD
set ALTIUM_HOME=C:\Altium\%CurrDirName%\AD
set UDM_DEBUG_ROOT=C:\Dev\AD_DDM_Tests
set X2_ROOT=C:\Dev\%CurrDirName%\

"%RIDER_PATH%" "%X2_ROOT%x2\edp\ADVSCH\Source Code\HarnessDesign\Altium.Har.HarnessDesignDev.sln"
