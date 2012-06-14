#!/bin/bash

PROJECT_NAME=AppBlade

XCODE_PROJECT_NAME=${PROJECT_NAME}.xcodeproj

SCHEME=AppBladeUniversal

CONFIGURATION=Release_Production

BUILD_DIR=build

###
# Begin Build Script
###
#cd ${WORKSPACE}/iOS/Framework

# clean all targets to be safe
xcodebuild -project ${XCODE_PROJECT_NAME} -alltargets clean

# remove previous root build directory, set manually
rm -rf ${BUILD_DIR}

# build the Distribution configuration of the library
xcodebuild -workspace ${XCODE_PROJECT_NAME}/project.xcworkspace -scheme ${SCHEME} -configuration ${CONFIGURATION} SYMROOT=${BUILD_DIR}

# Package compiled AppBlade library and resources
ARCHIVE_DIR=AppBlade

cd ${BUILD_DIR}
rm -rf ${ARCHIVE_DIR}
mkdir -p ${ARCHIVE_DIR}/AppBlade

# Copy source and resources into /AppBlade, license and readme belong in ARCHIVE_DIR.
cd ${CONFIGURATION}-universal
cp *.a *.h ../${ARCHIVE_DIR}/AppBlade/
# cp ${WORKSPACE}/iOS/Framework/AppBlade/*.config ../${ARCHIVE_DIR}/AppBlade/ # TODO: restore config
cp $../../README.mdown ../${ARCHIVE_DIR}/
cd ..

zip -r AppBlade.zip ${ARCHIVE_DIR}