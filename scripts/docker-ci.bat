@echo off
REM Script pour executer le pipeline CI localement avec Docker
REM Usage: scripts\docker-ci.bat [command]
REM
REM Commands:
REM   ci          - Run full CI pipeline (analyze + format + test)
REM   analyze     - Run code analysis only
REM   format      - Check formatting only
REM   format-fix  - Fix formatting issues
REM   test        - Run tests only
REM   test-cov    - Run tests with coverage
REM   build       - Build Android APK (debug)
REM   shell       - Open interactive shell
REM   clean       - Remove Docker containers and volumes

setlocal

if "%1"=="" (
    echo Usage: scripts\docker-ci.bat [command]
    echo.
    echo Commands:
    echo   ci          - Run full CI pipeline
    echo   analyze     - Run code analysis
    echo   format      - Check formatting
    echo   format-fix  - Fix formatting
    echo   test        - Run tests
    echo   test-cov    - Run tests with coverage
    echo   build       - Build Android APK
    echo   shell       - Interactive shell
    echo   clean       - Cleanup Docker
    exit /b 1
)

if "%1"=="ci" (
    echo Running full CI pipeline...
    docker-compose run --rm ci
    exit /b %ERRORLEVEL%
)

if "%1"=="analyze" (
    echo Running code analysis...
    docker-compose run --rm analyze
    exit /b %ERRORLEVEL%
)

if "%1"=="format" (
    echo Checking code formatting...
    docker-compose run --rm format
    exit /b %ERRORLEVEL%
)

if "%1"=="format-fix" (
    echo Fixing code formatting...
    docker-compose run --rm format-fix
    exit /b %ERRORLEVEL%
)

if "%1"=="test" (
    echo Running tests...
    docker-compose run --rm test
    exit /b %ERRORLEVEL%
)

if "%1"=="test-cov" (
    echo Running tests with coverage...
    docker-compose run --rm test-coverage
    exit /b %ERRORLEVEL%
)

if "%1"=="build" (
    echo Building Android APK...
    docker-compose run --rm build-android
    exit /b %ERRORLEVEL%
)

if "%1"=="shell" (
    echo Opening interactive shell...
    docker-compose run --rm shell
    exit /b %ERRORLEVEL%
)

if "%1"=="clean" (
    echo Cleaning up Docker resources...
    docker-compose down -v --remove-orphans
    docker system prune -f
    exit /b %ERRORLEVEL%
)

echo Unknown command: %1
exit /b 1
