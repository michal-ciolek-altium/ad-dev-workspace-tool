for %%I in (.) do set CurrDirName=%%~nxI
set /p ApplicationDir=<applicationDir.txt

echo %CurrDirName%
echo %ApplicationDir%

set ALTIUM64_HOME=C:\Altium\%CurrDirName%\AD\
set ALTIUM_HOME=C:\Altium\%CurrDirName%\AD
set UDM_DEBUG_ROOT=C:\Dev\AD_DDM_Tests
set X2_ROOT=C:\Dev\%CurrDirName%\
SET ALTIUM_EXTENSIONS=C:\ProgramData\%ApplicationDir%\Extensions\

"%DELPHI_PATH%" "C:\Dev\%CurrDirName%\x2\plugins\edp\Importers\Importer-xDxDesigner\Source Code\Importer_xDxDesigner.dproj"