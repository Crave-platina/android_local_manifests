#!/usr/bin/env bash

########################################
# SOURCE SETUP
########################################

echo "==> Resetting manifests and toolchain..."
rm -rf .repo/local_manifests prebuilts/clang/host/linux-x86

echo "==> Initializing repo..."
repo init -u https://github.com/ExampleROM/android.git -b rom-branch --git-lfs
git clone https://github.com/Crave-platina/android_local_manifests -b main .repo/local_manifests

########################################
# SYNC SOURCE
########################################

echo "==> Syncing source..."
/opt/crave/resync.sh
/opt/crave/resync.sh
/opt/crave/resync.sh

########################################
# BUILD SETUP
########################################

echo "==> Preparing environment..."
. build/envsetup.sh

export BUILD_USERNAME=username
export BUILD_HOSTNAME=hostname
export TZ=Region/District
export KBUILD_USERNAME="$BUILD_USERNAME"
export KBUILD_HOSTNAME="$BUILD_HOSTNAME"

echo "==> Lunching target..."
lunch examplerom_device-buildtype

echo "==> Cleaning previous build outputs..."
m installclean

########################################
# BUILD EXECUTION
########################################

echo "==> Starting target-files build..."
if m target-files-package otatools; then
    echo "==> Build completed successfully"
    echo "==> Running sign_script.sh..."
    bash sign_script.sh
else
    echo "Build failed — signing skipped!"
    exit 1
fi

echo "==> All tasks completed successfully!"
