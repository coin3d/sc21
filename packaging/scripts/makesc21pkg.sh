#!/bin/sh
#
# Copyright 2004 Systems in Motion AS, All rights reserved.
#
# This script creates an installer package from Xcode.
# 
# Usage: makesc21pkg.sh [-v]
#  -v   verbose
#
# All other parameters are passed as environment variables:
#   
#  SRCROOT                 This is the base location of project sources.
#                          This variable is set by Xcode.
#  TARGET_BUILD_DIR        This is the location of the target being built
#                          This variable is set by Xcode.
#  PRODUCT_NAME            Filename without path of the .pkg file to be
#                          built.
#  PRODUCT_ROOT            Full path to the package contents.
#  RESOURCE_DIR            Full path to the package resources.
#  INFOPLIST_FILE          Full path to the package Info.plist file.
#  DESCRIPTION_PLIST_FILE  Full path to the package Description.plist file.
#
# Authors:
#   Marius Kintel <kintel@sim.no>
#

while getopts 'v' c
do
  case $c in
    v) VERBOSE=-v ;;
  esac
done

if [ $VERBOSE ]; then
  set -x
fi

# Validate required input variables
abort=0
for var in SRCROOT TARGET_BUILD_DIR PRODUCT_NAME PRODUCT_ROOT RESOURCE_DIR \
           INFOPLIST_FILE DESCRIPTION_PLIST_FILE
do
  eval val=\$$var
  echo $val
  if [ -z "$val" ]; then
    echo "$0:$LINENO: Expected non-empty variable \$$var"
    abort=1
  fi
done

# Abort on missing variables
if [ $abort -ne 0 ]; then
  exit 1
fi

# Package creation using PackageMaker.app
if [ -z $VERBOSE ]; then
  REDIRECT='> /dev/null 2>&1'
fi
#FIXME: Path is different on Jaguar
eval "/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker -build -p \"$TARGET_BUILD_DIR/$PRODUCT_NAME\" -f \"$PRODUCT_ROOT\" -r \"$SRCROOT/$RESOURCE_DIR\" -i \"$SRCROOT/$INFOPLIST_FILE\" -d \"$SRCROOT/$DESCRIPTION_PLIST_FILE\" $REDIRECT"
#FIXME: How to handle errors from PackageMaker? It seems to always return 2
echo "PackageMaker returned $?"

exit 0;
