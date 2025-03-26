#!/bin/bash

set -e 

REPO_NAME="cinny"
REPO_URL="https://github.com/cinnyapp/cinny"
APP_TARGET="dist"

REPO_VERSION="4.5.1"
CLICK_VERSION_PREFIX=".2RC"

NODE_VERSION="22.2.0"


walk () {
  echo "Entering $1"
  cd $1
}

cleanup () {
  if [ -d "${ROOT}/${REPO_NAME}" ]; then
    echo "Cleaning up"
    rm -rf "${ROOT}/target"
  fi
}

clone () {
  local repo_dir="${ROOT}/${REPO_NAME}"

  # check if the cinny repository already exists locally with the required version
  if [ -d "$repo_dir" ]; then
    # if the folder exists, check it has got the required version
    echo "'$REPO_NAME' exists locally in '$repo_dir', going to check version"
    pushd "$repo_dir" > /dev/null  # changes into the repo folder
    local current_version=$(git describe --tags --abbrev=0)
    if [ "$current_version" = "v$REPO_VERSION" ]; then
      echo "Repository '$REPO_NAME' in version '$REPO_VERSION' exists locally, skip cloning"
      echo "now clearing all unstaged changes"
      git checkout . # undo all unstaged changes so patches are applied freshly
      popd > /dev/null # changes back to root folder
      return 0
    fi
    rm -rf "${ROOT}/${REPO_NAME}"  # if version does not match, clear existing folder
    popd > /dev/null # changes back to root folder
  fi
  # if its not present or the wrong version, clone it
  echo "Cloning source repo"
  git clone "${REPO_URL}" "${ROOT}/${REPO_NAME}" --recurse-submodules --depth=1 --branch="v${REPO_VERSION}"
}

apply_patches () {
  echo "Patching cinny source code"
  patches_dir="${ROOT}/patches"
  if [ -d "$patches_dir" ]; then
    patch_files=("$patches_dir"/*.patch)
    if [ -e "${patch_files[0]}" ]; then
      for patch in "${patch_files[@]}"; do
        echo "Applying $patch"
        git apply "$patch"
      done
    else
      echo "No patch files found in $patches_dir"
    fi
  else
    echo "No patches directory found at $patches_dir"
  fi
  cp "${ROOT}/svg/cinny_512.svg" "${ROOT}/assets/logo.svg"
  cp "${ROOT}/svg/cinny_18.svg" "${ROOT}/cinny/public/res/svg/cinny.svg"
}

setup_node () {
  echo "Setting up node $NODE_VERSION"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
  export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
  nvm install $NODE_VERSION
}

build () {
  echo "Building cinny"
  npm install
  npm run build
}

package () {
  echo "Packaging cinny"
  cp -r "${APP_TARGET}" "${ROOT}/target"
  sed -i "s/@CLICK_VERSION@/$REPO_VERSION$CLICK_VERSION_PREFIX/g" "${ROOT}/manifest.json.in"
}

cleanup
clone
walk "${ROOT}/${REPO_NAME}"
apply_patches
setup_node
build
package
