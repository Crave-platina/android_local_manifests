#!/usr/bin/env bash

########################################
# SOURCE SETUP
########################################

echo "==> Resetting manifests and toolchain..."
rm -rf .repo/local_manifests prebuilts/clang/host/linux-x86

echo "==> Initializing repo..."
repo init -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-12.1
git clone https://github.com/Crave-platina/android_local_manifests -b twrp .repo/local_manifests

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

export BUILD_USERNAME=han
export BUILD_HOSTNAME=crave
export TZ=Asia/Jakarta
export KBUILD_USERNAME="$BUILD_USERNAME"
export KBUILD_HOSTNAME="$BUILD_HOSTNAME"
export ALLOW_MISSING_DEPENDENCIES=true

########################################
# TWRP VARIANTS
########################################

DEVICE_CODENAME="platina"
DEVICE_PATH="device/xiaomi/${DEVICE_CODENAME}"
GIT_REPO="https://github.com/Crave-platina/android_device_xiaomi_platina.git"

BRANCHES=(
  "twrp-12.1-4.4-legacy"
  "twrp-12.1-4.4-dynamic"
)

OUT_BASE="$PWD/twrp_builds"
mkdir -p "$OUT_BASE"

########################################
# BUILD LOOP
########################################

for BRANCH in "${BRANCHES[@]}"; do
  echo "================================================="
  echo " Building TWRP for branch: ${BRANCH}"
  echo "================================================="

  echo "==> Switching device tree to ${BRANCH}"
  pushd "${DEVICE_PATH}"
  if ! git fetch "${GIT_REPO}" "${BRANCH}" --depth=1; then
    echo "Failed to fetch ${BRANCH}, skipping"
    popd
    continue
  fi
  git checkout -B "${BRANCH}" FETCH_HEAD
  popd

  echo "==> Lunching target..."
  lunch "twrp_${DEVICE_CODENAME}-eng"

  echo "==> Cleaning previous outputs..."
  m clean

  echo "==> Building recovery image..."
  if ! m recoveryimage; then
  echo "Build failed for ${BRANCH}"
  exit 1
  fi

  ########################################
  # VERSIONED ARTIFACT OUTPUT
  ########################################

  VERSION_FILE="bootable/recovery/variables.h"

  if [[ -f "$VERSION_FILE" ]]; then
    version=$(grep 'define TW_MAIN_VERSION_STR' "$VERSION_FILE" | cut -d '"' -f2)
  else
    echo "variables.h not found, using unknown version"
    version="unknown"
  fi

  if [[ "$BRANCH" == *legacy* ]]; then
    VARIANT="4.4-legacy"
  elif [[ "$BRANCH" == *dynamic* ]]; then
    VARIANT="4.4-dynamic"
  else
    VARIANT="unknown"
  fi

  DATE="$(date +%Y%m%d)"

  IMG_SRC="out/target/product/${DEVICE_CODENAME}/recovery.img"
  IMG_DST="${OUT_BASE}/TWRP-${version}-${VARIANT}-${DEVICE_CODENAME}-${DATE}.img"

  if [[ -f "$IMG_SRC" ]]; then
    cp "$IMG_SRC" "$IMG_DST"
    echo "==> Saved: $(basename "$IMG_DST")"
  else
    echo "recovery.img not found for ${BRANCH}, skipping"
    continue
  fi

done

echo "=============================================="
echo " All TWRP builds completed successfully!"
echo "=============================================="
