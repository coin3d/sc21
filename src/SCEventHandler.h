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

@class SCMode;
@class SCCamera;
@class SCEventHandlerP;

typedef int SCOperation;
#define SCNoOperation 0

@interface SCEventHandler : NSObject <NSCoding, SCEventHandling>
{
 @protected
  SCEventHandlerP * _sc_eventhandler;
}

- (void)enableOperation:(SCOperation)operation forButton:(int)buttonNumber withModifier:(unsigned int)modifierFlags;
- (void)getButton:(int *)buttonbuffer andModifier:(unsigned int *)modifierbuffer forOperation:(SCOperation)operation;
- (SCOperation)operationForButton:(int)buttonNumber andModifier:(unsigned int)modifierFlags;

- (void)emulateButton:(int)button usingModifier:(unsigned int)modifierFlags;
- (unsigned int)modifierForEmulatedButton:(int)buttonNumber;

@end

