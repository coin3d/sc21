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

#import <Sc21/SCCoinhandler.h>
#import <Sc21/SCController.h>
#import "SCEventConverter.h"
#import "SCUtil.h"

@interface SCCoinHandlerP : NSObject
{
  SCEventConverter * eventconverter;
}
@end

@implementation SCCoinHandlerP
@end

@interface SCCoinHandler (InternalAPI)
- (void)_SC_commonInit;
@end

#define SELF self->_sc_coinhandler

@implementation SCCoinHandler

- (id)init
{
  if (self = [super init]) {
    [self _SC_commonInit];
  }
  return self;
}

- (void)dealloc
{
  [SELF->eventconverter release];
  [SELF release];
  [super dealloc];
}

- (BOOL)controller:(SCController *)controller handleEvent:(NSEvent *)event
{
  SC21_DEBUG(@"SCController.handleEventAsCoinEvent:");
  BOOL handled = NO;
  SoEvent * se = [SELF->eventconverter createSoEvent:event 
                      inDrawable:[controller drawable]];
  if (se) {
    handled = [controller sceneManager]->processEvent(se);
    delete se;
  }
  return handled;
}

#pragma mark --- NSCoding conformance ---

- (void)encodeWithCoder:(NSCoder *)coder
{
}

- (id)initWithCoder:(NSCoder *)coder
{
  if (self = [super init]) {
    [self _SC_commonInit];
  }
  return self;
}

@end

@implementation SCCoinHandler (InternalAPI)

- (void)_SC_commonInit
{
  SELF = [[SCCoinHandlerP alloc] init];
  SELF->eventconverter = [[SCEventConverter alloc] init];
}

@end
