#!/bin/sh
#
# Copyright 2004 Systems in Motion AS, All rights reserved.
#
# This script (almost) automatically creates a dmg file for distribution
# from a directory of source files.
# 
# Usage: makedmg.sh -v <volumename> -o <outname> -r <rootdir>
#  -v   Volume name (e.g. -v Coin-2.1.0)
#  -o   Output file name (e.g. -o Coin-2.1.0-no_inst.dmg)
#  -r   Directory with contents of the DMG (e.g. path/to/noinst-dmg-root)
#
#
# FIXME: Automatically set background image of folder (kintel 20040116)
# FIXME: Return error code on error
# Authors:
#   Marius Kintel <kintel@sim.no>

printUsage()
{
  echo "Usage: $0 -v <volumename> -o <outfile> -r <rootdir>"
  echo
  echo "  Example: $0 -v Coin-2.1.0 -o Coin-2.1.0-no_inst.dmg -r path/to/dmg-root"
}

while getopts 'v:o:r:' c
do
  case $c in
    v) VOLNAME=$OPTARG;;
    o) OUTNAME=$OPTARG;;
    r) ROOT=$OPTARG;;
  esac
done

if test -z "$VOLNAME" -o -z "$OUTNAME" -o -z "$ROOT"; then
  printUsage
  exit 1
fi

# Use sparse image to let it grow on demand
hdiutil create "$OUTNAME.tmp" -quiet -size 100m -ov -layout NONE -volname "$VOLNAME" -type SPARSE -fs HFS+

# Mount image and get the corresponding device
DEVICE=`hdiutil attach $OUTNAME.tmp.sparseimage | sed -ne 's|.*/dev/\([^ ]*\).*|\1|p'`

# Use ditto instead of cp to preserve file attributes (e.g. hidden files)
ditto -rsrcFork "$ROOT" /Volumes/$VOLNAME
#FIXME: Make this a parameter?
#echo "--"
#echo "Open $VOLNAME from Desktop and set background to"
#echo "/Volumes/$VOLNAME/background.png. Make sure \"This window only\" is chosen."
#echo "When done, press enter to continue."
#read
# Hide files
/Developer/Tools/SetFile -a V /Volumes/$VOLNAME/.VolumeIcon.icns
/Developer/Tools/SetFile -a V /Volumes/$VOLNAME/.DS_Store
/Developer/Tools/SetFile -a V /Volumes/$VOLNAME/Desktop\ DB
/Developer/Tools/SetFile -a V /Volumes/$VOLNAME/Desktop\ DF
/Developer/Tools/SetFile -a V /Volumes/$VOLNAME/background.png
# We have a custom volume icon
/Developer/Tools/SetFile -a C /Volumes/$VOLNAME

# Convert to a compressed, read-only image
hdiutil detach $DEVICE -quiet
hdiutil resize -sectors min "$OUTNAME.tmp.sparseimage"
hdiutil convert "$OUTNAME.tmp.sparseimage" -quiet -ov -format UDZO -o "$OUTNAME"
rm "$OUTNAME.tmp.sparseimage"