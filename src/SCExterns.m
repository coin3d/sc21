/* =============================================================== *
 |                                                                 |
 | This file is part of Sc21, a Cocoa user interface binding for   |
 | the Coin 3D visualization library.                              |
 |                                                                 |
 | Copyright (c) 2003-2004 Systems in Motion. All rights reserved. |
 |                                                                 |
 | Sc21 is free software; you can redistribute it and/or           |
 | modify it under the terms of the GNU General Public License     |
 | ("GPL") version 2 as published by the Free Software             |
 | Foundation.                                                     |
 |                                                                 |
 | A copy of the GNU General Public License can be found in the    |
 | source distribution of Sc21. You can also read it online at     |
 | http://www.gnu.org/licenses/gpl.txt.                            |
 |                                                                 |
 | For using Coin with software that can not be combined with the  |
 | GNU GPL, and for taking advantage of the additional benefits    |
 | of our support services, please contact Systems in Motion       |
 | about acquiring a Coin Professional Edition License.            |
 |                                                                 |
 | See http://www.coin3d.org/mac/Sc21 for more information.        |
 |                                                                 |
 | Systems in Motion, Bygdoy Alle 5, 0257 Oslo, Norway.            |
 |                                                                 |
 * =============================================================== */

// Notification names in SCSceneGraph
NSString * SCCouldNotReadFileNotification = @"SCCouldNotReadFileNotification";
NSString * SCCouldNotWriteFileNotification = @"SCCouldNotWriteFileNotification";
NSString * SCNoCameraFoundInSceneNotification = @"SCNoCameraFoundInSceneNotification";
NSString * SCNoLightFoundInSceneNotification = @"SCNoLightFoundInSceneNotification";

// Notification names in SCController and SCSceneGraph
NSString * SCSceneGraphChangedNotification = @"SCSceneGraphChangedNotification";

// Notification names in SCCamera
NSString * SCViewAllNotification = @"SCViewAllNotification";
NSString * SCCameraTypeChangedNotification = @"SCCameraTypeChangedNotification";

// Notification names in SCEventHandling
NSString * SCCursorChangedNotification = @"SCCursorChangedNotification";

// Internally used notifications
// Note that the variable name is intentionally not starting with _ since
// C++ reserves '_' usage in the global namespace. 
NSString * SCRootChangedNotification = @" _SC_RootChangedNotification";

