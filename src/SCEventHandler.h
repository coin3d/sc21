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

#import <Cocoa/Cocoa.h>
#import <Sc21/SCDefines.h>

@class SCController;
@class SCEventHandlerP;

@interface SCEventHandler : NSObject
{
 @protected
  SCEventHandlerP * _sc_eventhandler;
 @private
  IBOutlet SCEventHandler * nextEventHandler;
}

/*" Actual event handling "*/
- (BOOL)controller:(SCController *)controller handleEvent:(NSEvent *)event;

/*" Support for continuous animation "*/
- (void)update:(SCController *)controller;

/*" Managing the eventhandler chain "*/
- (void)setNextEventHandler:(SCEventHandler *)nexthandler;
- (SCEventHandler *)nextEventHandler;

@end

/*"
  Posted when the cursor has been changed by an event handler. 
  This is automatically picked up by the SCView currently viewing the
  scene graph.
"*/
SC21_EXTERN NSString * SCCursorChangedNotification;
