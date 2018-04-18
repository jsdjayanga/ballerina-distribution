#!/bin/bash

function pringUsage() {
    echo "Usage:"
    echo "build.sh [options]"
    echo "options:"
    echo "    -v (--version)"
    echo "        version of the balletina distribution"
    echo "    -d (--dist)"
    echo "        balletina distribution type either of the followings"
    echo "        1. balletina-platform"
    echo "        2. ballerina-runtime"
    echo "    --all"
    echo "        build all ballerina distributions"
    echo "        this will OVERRIDE the -d option"
    echo "eg: build.sh -v 1.0.0 -d balletina"
    echo "eg: build.sh -v 1.0.0 --all"
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
    pringUsage
    exit 1
fi

if [ -z "$DISTRIBUTION" ] && [ "$BUILD_ALL_DISTRIBUTIONS" == "false" ]; then
    echo "You have to use either --all or -d [distribution]"
    pringUsage
    exit 1
fi


BALLERINA_DISTRIBUTION_LOCATION=/home/ubuntu/Packs
BALLERINA_PLATFORM=ballerina-platform-linux-$BALLERINA_VERSION
BALLERINA_RUNTIME=ballerina-runtime-linux-$BALLERINA_VERSION
BALLERINA_INSTALL_DIRECTORY=ballerina-$BALLERINA_VERSION
#BALLERINA_PLATFORM_ZIP=$BALLERINA_DISTRIBUTION_LOCATION/$DISTRIBUTION-$BALLERINA_VERSION.zip

#BALLERINA_VERSION=0.970.0-alpha1-SNAPSHOT
#BALZIP=/home/ubuntu/Packs/ballerina-linux-$BALLERINA_VERSION.zip
#BALDIST=ballerina-linux-$BALLERINA_VERSION

echo $BALDIST "build started at" $(date +"%Y-%m-%d %H:%M:%S")

#rm -rf target
#mkdir -p target/original
#unzip $BALZIP -d target/original > /dev/null 2>&1
#mv target/original/$BALDIST target/original/ballerina-linux-$BALLERINA_VERSION

#mkdir -p target/$BALDIST/opt/ballerina
#chmod -R 755 target/$BALDIST/opt/ballerina

###mv target/original/ballerina-linux-$BALLERINA_VERSION target/$BALDIST/opt/ballerina 

#cp -R linux/DEBIAN target/$BALDIST/DEBIAN
#sed -i -e 's/__BALLERINA_VERSION__/'$BALLERINA_VERSION'/g' target/$BALDIST/DEBIAN/postinst
#sed -i -e 's/__BALLERINA_VERSION__/'$BALLERINA_VERSION'/g' target/$BALDIST/DEBIAN/postrm
#sed -i -e 's/__BALLERINA_VERSION__/'$BALLERINA_VERSION'/g' target/$BALDIST/DEBIAN/control

#dpkg-deb --build target/$BALDIST

echo $BALDIST "build completed at" $(date +"%Y-%m-%d %H:%M:%S")

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
    rm -rf target/$BALLERINA_INSTALL_DIRECTORY/opt/ballerina
    mkdir -p target/$BALLERINA_INSTALL_DIRECTORY/opt/ballerina
    chmod -R 755 target/$BALLERINA_INSTALL_DIRECTORY/opt/ballerina
    mv target/original/$BALLERINA_INSTALL_DIRECTORY target/$BALLERINA_INSTALL_DIRECTORY/opt/ballerina
}

function copyDebianDirectory() {
    cp -R resources/DEBIAN target/$BALLERINA_INSTALL_DIRECTORY/DEBIAN
    sed -i -e 's/__BALLERINA_VERSION__/'$BALLERINA_VERSION'/g' target/$BALLERINA_INSTALL_DIRECTORY/DEBIAN/postinst
    sed -i -e 's/__BALLERINA_VERSION__/'$BALLERINA_VERSION'/g' target/$BALLERINA_INSTALL_DIRECTORY/DEBIAN/postrm
    sed -i -e 's/__BALLERINA_VERSION__/'$BALLERINA_VERSION'/g' target/$BALLERINA_INSTALL_DIRECTORY/DEBIAN/control
}

function createBallerinaPlatform() {
    echo "Creating ballerina platform installer"
    #BALLERINA_INSTALL_DIRECTORY=$BALLERINA_PLATFORM
    extractPack "$BALLERINA_DISTRIBUTION_LOCATION/$BALLERINA_PLATFORM.zip" $BALLERINA_PLATFORM
    createPackInstallationDirectory
    copyDebianDirectory
    mv target/$BALLERINA_INSTALL_DIRECTORY target/ballerina-platform-linux-installer-x64-$BALLERINA_VERSION
    dpkg-deb --build target/ballerina-platform-linux-installer-x64-$BALLERINA_VERSION
}

function createBallerinaRuntime() {
    echo "Creating ballerina runtime installer"
    #BALLERINA_INSTALL_DIRECTORY=$BALLERINA_RUNTIME
    extractPack "$BALLERINA_DISTRIBUTION_LOCATION/$BALLERINA_RUNTIME.zip" $BALLERINA_RUNTIME
    createPackInstallationDirectory
    copyDebianDirectory
    mv target/$BALLERINA_INSTALL_DIRECTORY target/ballerina-runtime-linux-installer-x64-$BALLERINA_VERSION
    dpkg-deb --build target/ballerina-runtime-linux-installer-x64-$BALLERINA_VERSION
}

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
