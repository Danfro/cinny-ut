#!/bin/bash

set -e 

REPO_NAME="cinny"
REPO_URL="https://github.com/cinnyapp/cinny"
APP_TARGET="dist"
REPO_DIR=${ROOT}/${REPO_NAME}

REPO_VERSION="4.10.0"
CLICK_VERSION_PREFIX=".2"

NODE_VERSION=22.15.1
NPM_DIR="${HOME}/.npm"
NVM_VERSION=0.40.3
NVM_DIR="${HOME}/.nvm"

walk () {
    echo "Entering $1"
    cd $1
}

cleanup () {
    if [ -d "${ROOT}/${REPO_NAME}" ]; then
        echo "Cleaning up"
        rm -rf "${ROOT}/target"
    fi
    #   drop code changes to manifest.json.in, logo.svg and .pot file that are generated with every build
    git checkout ${ROOT}/manifest.json.in
    git checkout ${ROOT}//assets/logo.svg
    git checkout ${ROOT}//po/cinny.danfro.pot
}

clone () {
    # check if the cinny repository already exists locally with the required version
    if [ -d "${REPO_DIR}" ]; then
        pushd "${REPO_DIR}" > /dev/null  # changes into the repo folder
        local current_version=$(git describe --tags --abbrev=0)
    if [ "$current_version" = "v$REPO_VERSION" ]; then
        echo "Repository '$REPO_NAME' in version '$REPO_VERSION' exists locally, skip cloning"
        echo "now clearing all unstaged changes"
        git checkout . # undo all unstaged changes so patches are applied freshly
        popd > /dev/null # changes back to root folder
        return 0
    fi
        rm -rf "${REPO_DIR}"  # if version does not match, clear existing folder
        popd > /dev/null # changes back to root folder
    fi
    # if its not present or the wrong version, clone it
    echo "Cloning source repo"
    git clone "${REPO_URL}" "${REPO_DIR}" --recurse-submodules --depth=1 --branch="v${REPO_VERSION}"
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
    # # Check if running in GitHub Actions, then skip this step, becaus node is installed in the workflow file
    # if [ "$GITHUB_ACTIONS" = "true" ]; then
    #     echo "Running in GitHub Actions environment. Skipping Node.js setup."
    #     return 0
    # fi
    echo "Setting up node $NODE_VERSION"
    local npmlocaldir="${ROOT}/npm"
    if [ -d "$npmlocaldir" ]; then
        pushd "$npmlocaldir" > /dev/null  # changes into the npm folder
        # copy and setup first, otherwise hard to check the version number
        cp -r "$npmlocaldir" $NPM_DIR
        export PATH="$NPM_DIR/bin:$PATH" # Add the copied npm directory to the PATH
        local current_version=$(node -v)
        if [ "$current_version" = "v$NODE_VERSION" ]; then
            echo "node in version '$NODE_VERSION' exists locally, using this instead of downloading"
            popd > /dev/null # changes back to root folder
        else
            # otherwise download and install
            echo "node locally present, but in version $current_version and required is $NODE_VERSION"
            echo "installing node via nvm"
            echo "Setting up nvm $NVM_VERSION"
            local nvmlocaldir="${ROOT}/nvm"
            # check if nvm already exists locally
            if [ -d "$nvmlocaldir" ]; then
                pushd "$nvmlocaldir" > /dev/null  # changes into the nvm folder
                local current_version=$(git describe --tags --abbrev=0)
                if [ "$current_version" = "v$NVM_VERSION" ]; then
                    echo "nvm in version '$NVM_VERSION' exists locally, copying instead of downloading"
                    cp -r "$nvmlocaldir" $NVM_DIR
                    popd > /dev/null # changes back to root folder
                else
                    # otherwise download and install nvm
                    echo "installing nvm"
                    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v$NVM_VERSION/install.sh | bash
                fi
            else
                # otherwise download and install
                echo "installing nvm"
                curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v$NVM_VERSION/install.sh | bash
            fi
            echo "initialize nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
            nvm install $NODE_VERSION
            export PATH="$NPM_DIR/bin:$PATH" # Add the copied npm directory to the PATH
        fi
    else
        # otherwise download and install nvm and node
        echo "installing nvm"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v$NVM_VERSION/install.sh | bash
        export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
        echo "installing node"
        nvm install $NODE_VERSION
        export PATH="$NPM_DIR/bin:$PATH" # Add the copied npm directory to the PATH
    fi
}

build () {
    cd ${REPO_DIR}
    echo "Building cinny"
    #   replace repo version with current cinny-ut version in about page, version value taken from cons.js
    sed -i "s/$REPO_VERSION/$REPO_VERSION$CLICK_VERSION_PREFIX/g" "${REPO_DIR}/src/app/features/settings/about/About.tsx"
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
