/* =============================================================== *
 |                                                                 |
 | This file is part of Sc21, a Cocoa user interface binding for   |
 | the Coin 3D visualization library.                              |
 |                                                                 |
 | Copyright (c) 2003-2006 Systems in Motion. All rights reserved. |
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

#import <Cocoa/Cocoa.h>

/*
  Viewtiful is a slightly more involved example showing how to create
  a Document-Based Application with Sc21. It includes features such as:

  o Double-click on 3D model to open it
  o Drag and Drop files to the viewer icon
  o Copy to pasteboard
  o New from pasteboard
  o Refresh model
  o Connection to services
*/

@interface AppController : NSObject
{
  // FIXME: Added since we want to connect this to a non-standard selector and
  // IB doesn't let us do this (kintel 20030814)
  IBOutlet NSMenuItem *refreshItem;
}

- (BOOL)newDocumentFromPasteboard:(NSPasteboard *)pb;

@end
