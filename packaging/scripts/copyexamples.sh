#!/bin/sh
#
# Copyright 2003-2005 Systems in Motion AS, All rights reserved.
#

mkdir -p $INSTALL_ROOT$INSTALL_PATH/$PRODUCT_NAME
tar c -C examples \
README.txt \
Models/README.txt Models/basic/2cubes.iv Models/basic/cube.iv Models/basic/enginecube.iv Models/basic/rotorcube.iv Models/watch.wrl Models/textures/Watch2.jpg Models/textures/leather.jpg \
Sc21Viewer/main.m Sc21Viewer/AppController.h Sc21Viewer/AppController.mm Sc21Viewer/Sc21Viewer_Prefix.pch Sc21Viewer/Info.plist Sc21Viewer/version.plist Sc21Viewer/English.lproj/MainMenu.xib Sc21Viewer/Sc21Viewer.xcodeproj/project.pbxproj Sc21Viewer/Sc21_app.icns \
Sc21FullscreenViewer/main.m Sc21FullscreenViewer/AppController.h Sc21FullscreenViewer/AppController.mm Sc21FullscreenViewer/Sc21FullscreenViewer_Prefix.pch Sc21FullscreenViewer/Info.plist Sc21FullscreenViewer/version.plist Sc21FullscreenViewer/English.lproj/MainMenu.xib Sc21FullscreenViewer/Sc21FullscreenViewer.xcodeproj/project.pbxproj Sc21FullscreenViewer/Sc21_app.icns \
NoNibViewer/main.mm NoNibViewer/AppController.h NoNibViewer/AppController.mm NoNibViewer/NoNibViewer_Prefix.pch NoNibViewer/NoNibViewer.xcodeproj/project.pbxproj NoNibViewer/build.sh \
Viewtiful/main.mm Viewtiful/MyDocument.h Viewtiful/MyDocument.mm Viewtiful/MyWindowController.h Viewtiful/MyWindowController.mm Viewtiful/AppController.h Viewtiful/AppController.mm Viewtiful/Viewtiful_Prefix.pch Viewtiful/Sc21_app.icns Viewtiful/Info.plist Viewtiful/version.plist Viewtiful/English.lproj/InfoPlist.strings Viewtiful/English.lproj/MainMenu.xib Viewtiful/English.lproj/MyDocument.xib Viewtiful/Viewtiful.xcodeproj/project.pbxproj \
CustomEventHandling/AppController.h CustomEventHandling/AppController.mm CustomEventHandling/CustomEventHandling.xcodeproj/project.pbxproj CustomEventHandling/CustomEventHandling_Prefix.pch CustomEventHandling/English.lproj/MainMenu.xib CustomEventHandling/Info.plist CustomEventHandling/main.m CustomEventHandling/MyEventHandler.h CustomEventHandling/MyEventHandler.mm CustomEventHandling/Sc21_app.icns CustomEventHandling/version.plist \
| tar x -C $INSTALL_ROOT$INSTALL_PATH/$PRODUCT_NAME
if [ $? -ne 0 ]; then
  exit 1
fi
chown -R $INSTALL_OWNER:$INSTALL_GROUP $INSTALL_ROOT$INSTALL_PATH/$PRODUCT_NAME
chmod -R $INSTALL_MODE_FLAG $INSTALL_ROOT$INSTALL_PATH/$PRODUCT_NAME
