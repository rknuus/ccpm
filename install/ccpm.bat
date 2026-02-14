@echo off
setlocal enabledelayedexpansion

:: CCPM Installation Script for Windows
:: Installs Claude Code Project Manager into .claude directory
:: Usage: ccpm.bat [--version TAG] [--third-party] [--help]

set "REPO_URL=https://github.com/rknuus/ccpm"
set "REPO_API=https://api.github.com/repos/rknuus/ccpm"
set "PROJECT_ROOT=%CD%"
set "VERSION="
set "THIRD_PARTY=false"
set "VERSION_FILE=.claude\ccpm\.version"

:: Parse arguments
:parse_args
if "%~1"=="" goto :args_done
if "%~1"=="--help" goto :show_help
if "%~1"=="--version" (
    if "%~2"=="" (
        echo Error: --version requires a tag argument
        exit /b 1
    )
    set "VERSION=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="--third-party" (
    set "THIRD_PARTY=true"
    shift
    goto :parse_args
)
echo Unknown option: %~1
goto :show_help
:args_done

echo.
echo ========================================
echo   CCPM Installation Script
echo   Claude Code Project Manager
echo ========================================
echo.
echo Installation directory: %PROJECT_ROOT%
echo.

:: Resolve version
if not defined VERSION (
    echo Step 1/5: Resolving latest release...
    for /f "tokens=*" %%i in ('powershell -NoProfile -Command "(Invoke-RestMethod -Uri '%REPO_API%/releases/latest').tag_name" 2^>nul') do set "VERSION=%%i"
    if not defined VERSION (
        echo    No releases found; falling back to main branch
        set "VERSION=main"
    )
)
echo    Target version: %VERSION%

:: Check existing installation
if exist "%PROJECT_ROOT%\%VERSION_FILE%" (
    set /p INSTALLED=<"%PROJECT_ROOT%\%VERSION_FILE%"
    if "!INSTALLED!"=="%VERSION%" (
        echo.
        echo CCPM !INSTALLED! is already installed.
        set /p CHOICE="   [S]kip / [O]verwrite? (s/o): "
        if /i "!CHOICE!"=="o" (
            echo    Overwriting...
        ) else (
            echo    Skipping installation.
            exit /b 0
        )
    ) else (
        echo.
        echo CCPM !INSTALLED! is currently installed.
        echo    Available version: %VERSION%
        set /p CHOICE="   [U]pgrade / [S]kip / [O]verwrite? (u/s/o): "
        if /i "!CHOICE!"=="u" (
            echo    Proceeding with installation...
        ) else if /i "!CHOICE!"=="o" (
            echo    Proceeding with installation...
        ) else (
            echo    Skipping installation.
            exit /b 0
        )
    )
)

:: Download
echo.
echo Step 1/5: Downloading CCPM...
set "TEMP_DIR=%TEMP%\ccpm_install_%RANDOM%"
mkdir "%TEMP_DIR%" 2>nul

if "%VERSION%"=="main" (
    echo    Cloning main branch...
    git clone --quiet --depth 1 "%REPO_URL%.git" "%TEMP_DIR%"
    if %ERRORLEVEL% NEQ 0 (
        echo Error: Failed to clone repository
        rd /s /q "%TEMP_DIR%" 2>nul
        exit /b 1
    )
) else (
    echo    Downloading release %VERSION%...
    set "ARCHIVE=%TEMP_DIR%\ccpm.tar.gz"
    powershell -NoProfile -Command "Invoke-WebRequest -Uri '%REPO_URL%/archive/refs/tags/%VERSION%.tar.gz' -OutFile '!ARCHIVE!'"
    if %ERRORLEVEL% NEQ 0 (
        echo Error: Failed to download release %VERSION%
        rd /s /q "%TEMP_DIR%" 2>nul
        exit /b 1
    )
    :: Extract using tar (available on Windows 10+)
    tar -xzf "!ARCHIVE!" -C "%TEMP_DIR%"
    del /q "!ARCHIVE!"
    :: Move contents from extracted subdirectory
    for /d %%d in ("%TEMP_DIR%\*") do (
        if exist "%%d\ccpm" (
            xcopy "%%d\*" "%TEMP_DIR%\" /s /e /y /q >nul 2>&1
            rd /s /q "%%d" 2>nul
        )
    )
)
echo    Download complete
echo.

:: Step 2: Create directory structure
echo Step 2/5: Creating directory structure...
if not exist "%PROJECT_ROOT%\.claude\ccpm" mkdir "%PROJECT_ROOT%\.claude\ccpm"
if not exist "%PROJECT_ROOT%\.claude\commands" mkdir "%PROJECT_ROOT%\.claude\commands"
echo    Directory structure created
echo.

:: Step 3: Copy CCPM files
echo Step 3/5: Installing CCPM files...
xcopy "%TEMP_DIR%\ccpm\*" "%PROJECT_ROOT%\.claude\ccpm\" /s /e /y /q >nul
echo    CCPM files installed to .claude\ccpm\
echo.

:: Step 4: Copy commands
echo Step 4/5: Setting up slash commands...
if exist "%PROJECT_ROOT%\.claude\ccpm\commands" (
    xcopy "%PROJECT_ROOT%\.claude\ccpm\commands\*" "%PROJECT_ROOT%\.claude\commands\" /s /e /y /q >nul
    echo    Slash commands installed to .claude\commands\
) else (
    echo    Warning: No commands directory found in CCPM
)
echo.

:: Step 5: Settings
echo Step 5/5: Configuring permissions...
if exist "%PROJECT_ROOT%\.claude\ccpm\settings.local.json" (
    copy /y "%PROJECT_ROOT%\.claude\ccpm\settings.local.json" "%PROJECT_ROOT%\.claude\settings.local.json" >nul
    echo    Settings configured
) else (
    echo    No default settings found, skipping
)
echo.

:: Update exclusions
if "%THIRD_PARTY%"=="true" (
    echo Updating .git\info\exclude (third-party mode^)...
    if exist "%PROJECT_ROOT%\.git\info" (
        findstr /c:"# CCPM" "%PROJECT_ROOT%\.git\info\exclude" >nul 2>&1
        if %ERRORLEVEL% NEQ 0 (
            echo.>> "%PROJECT_ROOT%\.git\info\exclude"
            echo # CCPM - Third-party installation>> "%PROJECT_ROOT%\.git\info\exclude"
            echo .claude/>> "%PROJECT_ROOT%\.git\info\exclude"
            echo .pm/>> "%PROJECT_ROOT%\.git\info\exclude"
            echo    .git\info\exclude updated with CCPM exclusions
        ) else (
            echo    .git\info\exclude already contains CCPM exclusions
        )
    ) else (
        echo    Warning: .git\info directory not found; is this a git repo?
    )
) else (
    echo Updating .gitignore...
    if not exist "%PROJECT_ROOT%\.gitignore" (
        echo # CCPM - Local workspace files> "%PROJECT_ROOT%\.gitignore"
        echo .claude/epics/>> "%PROJECT_ROOT%\.gitignore"
        echo.>> "%PROJECT_ROOT%\.gitignore"
        echo # Local settings>> "%PROJECT_ROOT%\.gitignore"
        echo .claude/settings.local.json>> "%PROJECT_ROOT%\.gitignore"
        echo    .gitignore created
    ) else (
        findstr /c:".claude/epics/" "%PROJECT_ROOT%\.gitignore" >nul 2>&1
        if %ERRORLEVEL% NEQ 0 (
            echo.>> "%PROJECT_ROOT%\.gitignore"
            echo # CCPM - Local workspace files>> "%PROJECT_ROOT%\.gitignore"
            echo .claude/epics/>> "%PROJECT_ROOT%\.gitignore"
            echo .claude/settings.local.json>> "%PROJECT_ROOT%\.gitignore"
            echo    .gitignore updated with CCPM exclusions
        ) else (
            echo    .gitignore already contains CCPM exclusions
        )
    )
)
echo.

:: Write version file
echo %VERSION%> "%PROJECT_ROOT%\%VERSION_FILE%"
echo Version %VERSION% recorded in %VERSION_FILE%
echo.

:: Cleanup
rd /s /q "%TEMP_DIR%" 2>nul

:: Success
echo ========================================
echo   CCPM Installation Complete!
echo ========================================
echo.
echo Installation Summary:
echo    CCPM files: .claude\ccpm\
echo    Commands:   .claude\commands\
echo    Settings:   .claude\settings.local.json
echo    Version:    %VERSION%
echo.
echo Next Steps:
echo.
echo    1. Initialize CCPM:
echo       bash .claude\ccpm\scripts\pm\init.sh
echo.
echo    2. Restart Claude Code to load slash commands
echo.
echo    3. Verify installation: /pm:help
echo.
echo    4. Create your first PRD: /pm:prd-new ^<feature-name^>
echo.
echo    IMPORTANT: You must restart Claude Code for slash
echo    commands to be recognized!
echo.
echo Documentation: https://github.com/rknuus/ccpm
echo.

exit /b 0

:show_help
echo.
echo CCPM Installation Script - Claude Code Project Manager
echo.
echo USAGE:
echo   ccpm.bat [OPTIONS]
echo.
echo OPTIONS:
echo   --version ^<tag^>   Install a specific release version (e.g. v1.0.0).
echo                     Without this flag, the latest release is installed.
echo   --third-party     Use .git\info\exclude instead of .gitignore for
echo                     exclusions. Use this when installing CCPM into a
echo                     project you do not own.
echo   --help            Show this help message and exit.
echo.
echo EXAMPLES:
echo   ccpm.bat
echo   ccpm.bat --version v1.2.0
echo   ccpm.bat --third-party
echo   ccpm.bat --version v1.2.0 --third-party
echo.
exit /b 0
