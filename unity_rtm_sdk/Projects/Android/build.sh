#!/bin/bash
## ==============================================================================
## build script for RTM plugin for Android on Unity
##
## required environmental variables:
##   $RTM_VERSION
## ==============================================================================
PLATFORM="Android"

CURDIR=$(pwd)

function download_library {
    DOWNLOAD_URL=$1
    DOWNLOAD_FILE="Android_Native.zip"

    if [[ ! -e $DOWNLOAD_FILE ]]; then
        wget $DOWNLOAD_URL -O $DOWNLOAD_FILE
    fi
    #unzip
    unzip -o $DOWNLOAD_FILE
}

function copy_source_code {
    echo "Copy source code start"
    local SOURCE_CODE_PATH="${CURDIR}/../../sourceCode/"
    local DST_PATH="${CURDIR}/jni/"
    cp -r ${SOURCE_CODE_PATH}* $DST_PATH
    echo "Copy source code end"
}

function make_unity_plugin {
    rm -rf sdk

    SDKDIR="sdk/AgoraRtmEngineKit.plugin"
    mkdir -p $SDKDIR/libs
    cp AndroidManifest.xml $SDKDIR
    cp project.properties $SDKDIR
    cp -a bin/arm64-v8a $SDKDIR/libs
    cp -a bin/armeabi-v7a $SDKDIR/libs
    cp -a bin/x86 $SDKDIR/libs
    cp -a bin/agora-rtm-sdk.jar $SDKDIR/libs
}

function Clean {
    if [ -e prebuilt ]; then
	echo "clean ndk lib build..."
	ndk-build -C jni/ clean
    fi
    echo "removing Android build intermitten files..."
    rm -rf sdk *.zip Agora_RTM_SDK_for_$PLATFORM
    rm -rf obj libs bin prebuilt
}


if [ "$1" == "clean" ]; then
    Clean
    exit 0
fi

#download
download_library $1
mkdir prebuilt
cp -r Agora_RTM_SDK_for_Android/libs/* prebuilt/

# Copy sourceCode
copy_source_code

COMMITNR=`git log --pretty="%h" | head -n 1`
dirty=`[[ $(git diff --shortstat 2> /dev/null | tail -n1) != "" ]] && echo "*"`
if [ "$dirty" == "*" ]; then
    COMMITNR=${COMMITNR}-dirty
fi

EXTRACFLAGS=APP_CFLAGS=-DGIT_SRC_VERSION=${COMMITNR}
# clean
#rm -r libs/ || exit 1
ndk-build -C jni/ clean || exit 1

# create shared library
ndk-build V=1 $EXTRACFLAGS -C jni/ || exit 1


rm -rf bin
mkdir bin || exit 1
cp -r prebuilt/ bin/ || exit 1
cp -r libs/ bin/ || exit 1
cp AndroidManifest.xml bin/example-AndroidManifest.xml || exit 1

# sdk
make_unity_plugin

echo "------ FINISHED --------"
echo "#cp -r bin/ /Users/Shared/Agora/apps/Unity3D/VideoTexture/Assets/Plugins/Android/libs"
echo
echo "Success! => Android RTM plugin is created in $PWD/sdk"
exit 0


