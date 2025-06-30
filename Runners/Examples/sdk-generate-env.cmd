for %%I in (.) do set CurrDirName=%%~nxI
echo %CurrDirName%

"C:\Dev\%CurrDirName%\x2\tools\InternalSDKGenerator\RunGeneratorAll.cmd"