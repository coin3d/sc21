#!/bin/sh
#
# Copyright 2004 Systems in Motion AS, All rights reserved.
#
# This script creates an installer package from Xcode.
# 
# Usage: makesc21pkg.sh [-v]
#  -v   verbose
#
# Authors:
#   Marius Kintel <kintel@sim.no>
#
# FIXME: Return error code on error
# FIXME: Document input parameters/env. variables

echo "*** makesc21pkg.sh: $@"

while getopts 'v' c
do
  case $c in
    v) VERBOSE=-v ;;
  esac
done

if test $VERBOSE; then
  set -x
fi

if test -z $SRCROOT -o -z $DSTROOT -o -z $TARGET_BUILD_DIR -o -z $PRODUCT_NAME; then
  echo "Error: This script should be run from Xcode."
  exit 1
fi

# Package creation using PackageMaker
if test x$VERBOSE = x; then
  REDIRECT='> /dev/null 2>&1'
fi
#FIXME: Path is different on Jaguar
eval "/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker -build -p $TARGET_BUILD_DIR/$PRODUCT_NAME -f $DSTROOT -r $SRCROOT/packaging/pkgresources -i $SRCROOT/packaging/SC21_Info.plist -d $SRCROOT/packaging/SC21_Description.plist $REDIRECT"

echo "PackageMaker returned $?"
