#!/bin/sh
#
# Copyright 2004 Systems in Motion AS, All rights reserved.
#
# This script creates the main SC21-x.x.x.dmg image.
# The dmg file will be put in the current directory.
# 
# Usage: makeinstdmg.sh [-v] -c <SC21-version>
#  -v   verbose
#  -c   SC21 version string including name, e.g. "-c SC21-1.0.0"
#
# Authors:
#   Marius Kintel <kintel@sim.no>

printUsage()
{
  echo "Usage: $0 [-v] -c <SC21-version>"
  echo
  echo "  Example: $0 -c SC21-2.1.0"
}

echo "*** makesc21dmg.sh $@"

while getopts 'vc:' c
do
  case $c in
    v) VERBOSE=-v ;;
    c) VOLNAME=$OPTARG;;
  esac
done

if test -z "$VOLNAME"; then
  printUsage
  exit 1
fi

if test $VERBOSE; then
  set -x
fi

if test -z $SRCROOT -o -z $DSTROOT -o -z $TARGET_BUILD_DIR; then
  echo "Error: This script should be run from Xcode."
  exit 1
fi

if test -e /Volumes/$VOLNAME; then
  echo "/Volumes/SC21-$VOLNAME already exists. Please unmount before running this script."
  exit 1
fi

# Create dmgroot from template dir
ditto -rsrcFork "$SRCROOT/packaging/sc21-dmg-files" "$TEMP_DIR/sc21-dmg-root"

# Copy dist files
#FIXME: How do we know what OS version we're on (@MACOSX_NAME@)?
ditto -rsrcFork "$SRCROOT/packaging/SC21-README-@MACOSX_NAME@.txt" "$TEMP_DIR/sc21-dmg-root/README.txt"
ditto -rsrcFork "$TARGET_BUILD_DIR/SC21.pkg" "$TEMP_DIR/sc21-dmg-root/SC21.pkg"

# Build dmg file from dmgroot
sh "$SRCROOT/packaging/makedmg.sh" -v $VOLNAME -o "$TARGET_BUILD_DIR/$VOLNAME.dmg" -r "$TEMP_DIR/sc21-dmg-root"
