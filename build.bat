@echo off
set FILENAME=%1
if "%FILENAME%"=="" set FILENAME=main.asm

echo Assembling %FILENAME%...
nasm -f win64 %FILENAME% -o %FILENAME:.asm=.obj%

if errorlevel 1 goto error

echo Linking object file...
gcc %FILENAME:.asm=.obj% -o %FILENAME:.asm=.exe%

if errorlevel 1 goto error

echo Running executable...
%FILENAME:.asm=.exe%

echo.
echo Success!
goto end

:error
echo.
echo --- Build Failed ---

:end
pause