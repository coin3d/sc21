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
#import "SCDefines.h"
#import <Sc21/SCEventHandling.h>
#import "SCEmulator.h"

@class SCExaminerHandlerP;

@interface SCExaminerHandler : NSObject <NSCoding, SCEventHandling>
{
 @protected
  SCExaminerHandlerP * _sc_examinerhandler;
}

/*" Mouse- and keybindings for examiner modes "*/
- (void)setPanButton:(int)buttonNumber modifier:(unsigned int)modifierFlags;
- (void)setRotateButton:(int)buttonNumber modifier:(unsigned int)modifierFlags;
- (void)setZoomButton:(int)buttonNumber modifier:(unsigned int)modifierFlags;

- (void)getPanButton:(int*)buttonNumber modifier:(unsigned int*)modifierFlags;
- (void)getRotateButton:(int*)buttonNumber modifier:(unsigned int*)modifierFlags;
- (void)getZoomButton:(int*)buttonNumber modifier:(unsigned int*)modifierFlags;

/*" Additional settings "*/
- (void)setSpinEnabled:(BOOL)enabled;
- (BOOL)spinEnabled;
- (void)setScrollWheelZoomEnabled:(BOOL)enabled;
- (BOOL)scrollWheelZoomEnabled;

/*" SCEventHandling conformance "*/
- (BOOL)handleEvent:(NSEvent *)event;
- (void)update;
- (void)drawableDidChange:(NSNotification *)notification;
- (void)sceneGraphDidChange:(NSNotification *)notification;
@end
