:: 
:: Copyright 2023 The TensorFlow Authors. All Rights Reserved.
:: 
:: Licensed under the Apache License, Version 2.0 (the "License");
:: you may not use this file except in compliance with the License.
:: You may obtain a copy of the License at
:: 
::             http://www.apache.org/licenses/LICENSE-2.0
:: 
:: Unless required by applicable law or agreed to in writing, software
:: distributed under the License is distributed on an "AS IS" BASIS,
:: WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
:: See the License for the specific language governing permissions and
:: limitations under the License.
:: 

:: This will need to be updated to the latest TFLite recommendations
:: https://www.tensorflow.org/lite/android/lite_build
:: https://www.tensorflow.org/lite/guide/build_ios

@echo off
setlocal enableextensions

cd %~dp0

set TF_VERSION=2.5
set URL=https://github.com/tensorflow/flutter-tflite/releases/download/
:: set TAG=tf_%TF_VERSION%

:: Rather than copying .so files, should use gradle dependencies

set ANDROID_DIR=android\app\src\main\jniLibs\
set ANDROID_LIB=libtensorflowlite_c.so

:: Searching for these delegates
:: set ARM_DELEGATE=libtensorflowlite_c_arm_delegate.so
:: set ARM_64_DELEGATE=libtensorflowlite_c_arm64_delegate.so
set ARM=libtensorflowlite_c_arm.so
set ARM_64=libtensorflowlite_c_arm64.so
set X86=libtensorflowlite_c_x86_delegate.so
set X86_64=libtensorflowlite_c_x86_64_delegate.so

SET /A d = 0

:GETOPT
if /I "%1"=="-d" SET /A d = 1

SETLOCAL
:: if %d%==1 CALL :Download %ARM_DELEGATE% armeabi-v7a
:: if %d%==1 CALL :Download %ARM_64_DELEGATE% arm64-v8a
if %d%==0 CALL :Download %ARM% armeabi-v7a
if %d%==0 CALL :Download %ARM_64% arm64-v8a
CALL :Download %X86% x86
CALL :Download %X86_64% x86_64
EXIT /B %ERRORLEVEL%

:Download
curl -L -o %~1 %URL%/%~1
mkdir %ANDROID_DIR%%~2\
move /-Y %~1 %ANDROID_DIR%%~2\%ANDROID_LIB%
EXIT /B 0
