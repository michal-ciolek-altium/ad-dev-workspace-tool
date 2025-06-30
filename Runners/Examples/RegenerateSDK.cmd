for %%I in (.) do set CurrDirName=%%~nxI
echo %CurrDirName%

cd C:\Dev\%CurrDirName%\x2\tools\SDKCompiler\GeneratorRunner\

RegenerateSDK.exe