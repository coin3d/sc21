#!/bin/sh
#
# Copyright 2004 Systems in Motion AS, All rights reserved.
#

mkdir -p $INSTALL_ROOT$INSTALL_PATH/$PRODUCT_NAME
tar c -C examples \
README.txt \
Models/README.txt Models/basic/2cubes.iv Models/basic/cube.iv Models/basic/enginecube.iv Models/basic/rotorcube.iv Models/watch.wrl Models/textures/Watch2.jpg Models/textures/leather.jpg \
Sc21Viewer/main.m Sc21Viewer/AppController.h Sc21Viewer/AppController.mm Sc21Viewer/Sc21Viewer_Prefix.pch Sc21Viewer/Info.plist Sc21Viewer/version.plist Sc21Viewer/English.lproj/MainMenu.nib/classes.nib Sc21Viewer/English.lproj/MainMenu.nib/data.dependency Sc21Viewer/English.lproj/MainMenu.nib/info.nib Sc21Viewer/English.lproj/MainMenu.nib/keyedobjects.nib Sc21Viewer/Sc21Viewer.xcode/project.pbxproj Sc21Viewer/Sc21_app.icns \
Sc21FullscreenViewer/main.m Sc21FullscreenViewer/AppController.h Sc21FullscreenViewer/AppController.mm Sc21FullscreenViewer/Sc21FullscreenViewer_Prefix.pch Sc21FullscreenViewer/Info.plist Sc21FullscreenViewer/version.plist Sc21FullscreenViewer/English.lproj/MainMenu.nib/classes.nib Sc21FullscreenViewer/English.lproj/MainMenu.nib/data.dependency Sc21FullscreenViewer/English.lproj/MainMenu.nib/info.nib Sc21FullscreenViewer/English.lproj/MainMenu.nib/keyedobjects.nib Sc21FullscreenViewer/Sc21FullscreenViewer.xcode/project.pbxproj Sc21FullscreenViewer/Sc21_app.icns \
NoNibViewer/main.mm NoNibViewer/AppController.h NoNibViewer/AppController.mm NoNibViewer/NoNibViewer_Prefix.pch NoNibViewer/NoNibViewer.xcode/project.pbxproj NoNibViewer/build.sh \
Viewtiful/main.mm Viewtiful/MyDocument.h Viewtiful/MyDocument.mm Viewtiful/MyWindowController.h Viewtiful/MyWindowController.mm Viewtiful/AppController.h Viewtiful/AppController.mm Viewtiful/Viewtiful_Prefix.pch Viewtiful/Sc21_app.icns Viewtiful/Info.plist Viewtiful/version.plist Viewtiful/English.lproj/InfoPlist.strings Viewtiful/English.lproj/MainMenu.nib/classes.nib Viewtiful/English.lproj/MainMenu.nib/info.nib Viewtiful/English.lproj/MainMenu.nib/keyedobjects.nib Viewtiful/English.lproj/MyDocument.nib/classes.nib Viewtiful/English.lproj/MyDocument.nib/data.dependency Viewtiful/English.lproj/MyDocument.nib/info.nib Viewtiful/English.lproj/MyDocument.nib/keyedobjects.nib Viewtiful/Viewtiful.xcode/project.pbxproj \
CustomEventHandling/AppController.h CustomEventHandling/AppController.mm CustomEventHandling/CustomEventHandling.xcode/project.pbxproj CustomEventHandling/CustomEventHandling_Prefix.pch CustomEventHandling/English.lproj/MainMenu.nib/classes.nib CustomEventHandling/English.lproj/MainMenu.nib/data.dependency CustomEventHandling/English.lproj/MainMenu.nib/info.nib CustomEventHandling/English.lproj/MainMenu.nib/keyedobjects.nib CustomEventHandling/Info.plist CustomEventHandling/main.m CustomEventHandling/MyEventHandler.h CustomEventHandling/MyEventHandler.mm CustomEventHandling/Sc21_app.icns CustomEventHandling/version.plist \
| tar x -C $INSTALL_ROOT$INSTALL_PATH/$PRODUCT_NAME
chown -R $INSTALL_OWNER:$INSTALL_GROUP $INSTALL_ROOT$INSTALL_PATH/$PRODUCT_NAME
chmod -R $INSTALL_MODE_FLAG $INSTALL_ROOT$INSTALL_PATH/$PRODUCT_NAME
