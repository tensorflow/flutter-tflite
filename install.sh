#
# Copyright 2023 The TensorFlow Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#             http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#!/usr/bin/env bash


# Rather than copying .so files to Android, should use 
# the newer gradle dependencies


cd "$(dirname "$(readlink -f "$0")")"

# Available versions
# 2.5, 2.4.1

TF_VERSION=2.5

# This URL doesn't work for either the old repo or this one.
# Will revisit to load new TFLite binaries
URL="https://github.com/tensorflow/flutter-tflite/releases/download/"
# TAG="tf_$TF_VERSION"

ANDROID_DIR="android/app/src/main/jniLibs/"
ANDROID_LIB="libtensorflowlite_c.so"

# Searching for these delegates
# ARM_DELEGATE="libtensorflowlite_c_arm_delegate.so"
# ARM_64_DELEGATE="libtensorflowlite_c_arm64_delegate.so"
ARM="libtensorflowlite_c_arm.so"
ARM_64="libtensorflowlite_c_arm64.so"
X86="libtensorflowlite_c_x86_delegate.so"
X86_64="libtensorflowlite_c_x86_64_delegate.so"

delegate=0

while getopts "d" OPTION
do
	case $OPTION in
		d)  delegate=1;;
	esac
done


download () {
    wget "${URL}/$1" -O "$1"
    mkdir -p "${ANDROID_DIR}$2/"
    mv $1 "${ANDROID_DIR}$2/${ANDROID_LIB}"
}

if [ ${delegate} -eq 1 ]
then

# download ${ARM_DELEGATE} "armeabi-v7a"
# download ${ARM_64_DELEGATE} "arm64-v8a"

else

download ${ARM} "armeabi-v7a"
download ${ARM_64} "arm64-v8a"

fi

download ${X86} "x86"
download ${X86_64} "x86_64"
