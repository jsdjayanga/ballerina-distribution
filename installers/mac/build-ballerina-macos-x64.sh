#!/bin/bash

function printUsage() {
    echo "Usage:"
    echo "build.sh [options]"
    echo "options:"
    echo "    -v (--version)"
    echo "        version of the ballerina distribution"
    echo "    -d (--dist)"
    echo "        ballerina distribution type either of the followings"
    echo "        1. ballerina-platform"
    echo "        2. ballerina-runtime"
    echo "    --all"
    echo "        build all ballerina distributions"
    echo "        this will OVERRIDE the -d option"
    echo "eg: $0 -v 1.0.0 -d ballerina-platform"
    echo "eg: $0 -v 1.0.0 --all"
}

BUILD_ALL_DISTRIBUTIONS=false
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -v|--version)
    BALLERINA_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
    -d|--dist)
    DISTRIBUTION="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done

for i in "${POSITIONAL[@]}"
do
    if [ "$i" == "--all" ]; then
        BUILD_ALL_DISTRIBUTIONS=true
    fi
done

if [ -z "$BALLERINA_VERSION" ]; then
    echo "Please enter the version of the ballerina pack"
    printUsage
    exit 1
fi

if [ -z "$DISTRIBUTION" ] && [ "$BUILD_ALL_DISTRIBUTIONS" == "false" ]; then
    echo "You have to use either --all or -d [distribution]"
    printUsage
    exit 1
fi

BALLERINA_DISTRIBUTION_LOCATION=/Users/jayanga/Documents/Ballerina-12APR2018
BALLERINA_PLATFORM=ballerina-platform-macos-$BALLERINA_VERSION
BALLERINA_RUNTIME=ballerina-runtime-macos-$BALLERINA_VERSION
BALLERINA_INSTALL_DIRECTORY=ballerina-$BALLERINA_VERSION

function deleteTargetDirectory() {
    echo "Deleting target directory"
    rm -rf target
}

function extractPack() {
    echo "Extracting the ballerina distribution, " $1
    rm -rf target/original
    mkdir -p target/original
    unzip $1 -d target/original > /dev/null 2>&1
    mv target/original/$2 target/original/$BALLERINA_INSTALL_DIRECTORY
}

function createPackInstallationDirectory() {
    rm -rf target/darwin
    cp -r darwin target/darwin

    sed -i -e 's/__BALLERINA_VERSION__/'$BALLERINA_VERSION'/g' target/darwin/scripts/postinstall
    chmod -R 755 target/darwin/scripts/postinstall

    sed -i -e 's/__BALLERINA_VERSION__/'$BALLERINA_VERSION'/g' target/darwin/Distribution
    chmod -R 755 target/darwin/Distribution

    rm -rf target/darwinpkg
    mkdir -p target/darwinpkg
    chmod -R 755 target/darwinpkg

    mkdir -p target/darwinpkg/etc/paths.d
    chmod -R 755 target/darwinpkg/etc/paths.d

    echo "/Library/Ballerina/ballerina-$BALLERINA_VERSION/bin" >> target/darwinpkg/etc/paths.d/ballerina
    chmod -R 644 target/darwinpkg/etc/paths.d/ballerina

    mkdir -p target/darwinpkg/Library/Ballerina
    chmod -R 755 target/darwinpkg/Library/Ballerina

    mv target/original/$BALLERINA_INSTALL_DIRECTORY target/darwinpkg/Library/Ballerina/

    rm -rf target/package
    mkdir -p target/package
    chmod -R 755 target/package

    mkdir -p target/pkg
    chmod -R 755 target/pkg
}

function buildPackage() {
    pkgbuild --identifier org.ballerina.$BALLERINA_VERSION \
    --version $BALLERINA_VERSION \
    --scripts target/darwin/scripts \
    --root target/darwinpkg \
    target/package/ballerina.pkg > /dev/null 2>&1
}

function buildProduct() {
    productbuild --distribution target/darwin/Distribution \
    --resources target/darwin/Resources \
    --package-path target/package \
    target/pkg/$1 > /dev/null 2>&1
}

function createBallerinaPlatform() {
    echo "Creating ballerina platform installer"
    extractPack "$BALLERINA_DISTRIBUTION_LOCATION/$BALLERINA_PLATFORM.zip" $BALLERINA_PLATFORM
    createPackInstallationDirectory
    buildPackage
    buildProduct ballerina-platform-macos-installer-x64-$BALLERINA_VERSION.pkg
    #mv target/$BALLERINA_INSTALL_DIRECTORY target/ballerina-platform-linux-installer-x64-$BALLERINA_VERSION
    #dpkg-deb --build target/ballerina-platform-linux-installer-x64-$BALLERINA_VERSION
}

function createBallerinaRuntime() {
    echo "Creating ballerina runtime installer"
    extractPack "$BALLERINA_DISTRIBUTION_LOCATION/$BALLERINA_RUNTIME.zip" $BALLERINA_RUNTIME
    createPackInstallationDirectory
    buildPackage
    buildProduct ballerina-runtime-macos-installer-x64-$BALLERINA_VERSION.pkg
    #mv target/$BALLERINA_INSTALL_DIRECTORY target/ballerina-runtime-linux-installer-x64-$BALLERINA_VERSION
    #dpkg-deb --build target/ballerina-runtime-linux-installer-x64-$BALLERINA_VERSION
}

echo "Build started at" $(date +"%Y-%m-%d %H:%M:%S")

deleteTargetDirectory

if [ "$BUILD_ALL_DISTRIBUTIONS" == "true" ]; then
    echo "Creating all distributions"
    createBallerinaPlatform
    createBallerinaRuntime
else
    if [ "$DISTRIBUTION" == "ballerina-platform" ]; then
        echo "Creating Ballerina Platform"
        createBallerinaPlatform
    elif [ "$DISTRIBUTION" == "ballerina-runtime" ]; then
        echo "Creating Ballerina Runtime"
        createBallerinaRuntime
    else
        echo "Error"
    fi
fi

echo "Build completed at" $(date +"%Y-%m-%d %H:%M:%S")
