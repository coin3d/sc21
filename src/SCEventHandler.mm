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

#import <Sc21/SCEventHandler.h>
#import <Sc21/SCController.h>
#import "SCEventHandlerP.h"

@implementation SCEventHandlerP
@end

#define PRIVATE(p) ((p)->_sc_eventhandler)
#define SELF PRIVATE(self)

// FIXME: Document.

@implementation SCEventHandler

- (id)init
{
  if (self = [super init]) {
  }
  return self;
}

- (void)setNextEventHandler:(SCEventHandler *)nexthandler
{
  self->nextEventHandler = nexthandler;
}

- (SCEventHandler *)nextEventHandler
{
  return self->nextEventHandler;
}

- (BOOL)controller:(SCController *)controller handleEvent:(NSEvent *)event
{
  return YES;
}

- (void)update:(SCController *)controller
{
}

@end
