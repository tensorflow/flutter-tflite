@echo off
setlocal enableextensions

cd %~dp0

set TF_VERSION=2.5
set URL=https://github.com/am15h/tflite_flutter_plugin/releases/download/
set TAG=tf_%TF_VERSION%

set ANDROID_DIR=android\app\src\main\jniLibs\
set ANDROID_LIB=libtensorflowlite_c.so

set ARM_DELEGATE=libtensorflowlite_c_arm_delegate.so
set ARM_64_DELEGATE=libtensorflowlite_c_arm64_delegate.so
set ARM=libtensorflowlite_c_arm.so
set ARM_64=libtensorflowlite_c_arm64.so
set X86=libtensorflowlite_c_x86_delegate.so
set X86_64=libtensorflowlite_c_x86_64_delegate.so

SET /A d = 0

:GETOPT
if /I "%1"=="-d" SET /A d = 1

SETLOCAL
if %d%==1 CALL :Download %ARM_DELEGATE% armeabi-v7a
if %d%==1 CALL :Download %ARM_64_DELEGATE% arm64-v8a
if %d%==0 CALL :Download %ARM% armeabi-v7a
if %d%==0 CALL :Download %ARM_64% arm64-v8a
CALL :Download %X86% x86
CALL :Download %X86_64% x86_64
EXIT /B %ERRORLEVEL%

:Download
curl -L -o %~1 %URL%%TAG%/%~1
mkdir %ANDROID_DIR%%~2\
move /-Y %~1 %ANDROID_DIR%%~2\%ANDROID_LIB%
EXIT /B 0
