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

#import <Sc21/SCFlyHandler.h>
#import <Sc21/SCCamera.h>
#import "SCFlyMode.h"
#import "SCMouseLog.h"
#import "SCUtil.h"
#import <Sc21/SCEventHandlerP.h>

@interface SCFlyHandlerP : NSObject
{
  NSTimeInterval _prevtime;
  SCFlyMode * flymode;
  BOOL inversepitch;
  BOOL uparrow;
  BOOL downarrow;
  BOOL leftarrow;
  BOOL rightarrow;
}
@end

@implementation SCFlyHandlerP
@end

@interface SCFlyHandler (InternalAPI)
- (Class)_SC_modeForOperation:(SCOperation)operation;
@end

#define SUPER self->_sc_eventhandler
#define SELF self->_sc_flyhandler

@implementation SCFlyHandler

#pragma mark --- initialization and cleanup ---

- (id)init
{
  self = [super init];
  SELF = [[SCFlyHandlerP alloc] init];
  SELF->flymode = [[SCFlyMode alloc] init];
  return self;
}

- (void)dealloc
{
#if 0 // disabled, caused crash in IB. kyrah 20040728
  [SELF->flymode release];
  [SELF release];
#endif
}

#pragma mark --- accessor methods --- 

- (void)setInversePitch:(BOOL)yesno
{
  SELF->inversepitch = yesno;
}

- (BOOL)isInversePitch
{
  return SELF->inversepitch;
}

#pragma mark --- SCEventHandler conformance ---

- (BOOL)handleEvent:(NSEvent *)event
{ 
  SC21_LOG_METHOD;
  BOOL handled = NO;

  NSRect frame = [SUPER->currentdrawable frame];
  NSPoint p = [event locationInWindow];
  NSPoint pn;
  pn.x = (p.x - frame.origin.x) / frame.size.width;
  pn.y = (p.y - frame.origin.y) / frame.size.height;

  int eventtype = [event type];
  if (eventtype == NSLeftMouseDragged || 
      eventtype == NSRightMouseDragged ||
      eventtype == NSOtherMouseDragged) {
    if (![SELF->flymode isActive]) {
      [self _SC_activateMode:SELF->flymode event:event point:&pn];
    } else {
      [[SCMouseLog defaultMouseLog] appendPoint:&pn 
                                    timestamp:[event timestamp]];
    }
    handled = [SELF->flymode modifyCamera:SUPER->currentcamera withValue:[SELF->flymode valueForEvent:event]];
  }

#if 0
  unsigned int modifierflags = [event modifierFlags];
  // Check if this event will trigger an operation change
  SCOperation operation = [self _SC_currentOperation];
  if (eventtype == NSLeftMouseUp ||
      eventtype == NSRightMouseUp ||
      eventtype == NSOtherMouseUp) {
    operation = SCNoOperation;
  }
  else if (eventtype == NSLeftMouseDown ||
           eventtype == NSRightMouseDown ||
           eventtype == NSOtherMouseDown) {
    // Check for emulations
    int effectivebutton = [self _SC_emulatedButton:[event buttonNumber] 
                                forModifier:modifierflags];
    
    SCOperation newoperation = [self operationForButton:effectivebutton andModifier:modifierflags];
    if (newoperation != SCNoOperation) operation = newoperation;
  }

  if (operation != [self _SC_currentOperation]) {
    [self _SC_setCurrentOperation:operation];
    [[self _SC_currentMode] deactivate];
    Class modeclass = [self _SC_modeForOperation:operation];
    if (modeclass) {
      SCMode * newmode = [[[modeclass alloc] init] autorelease];
      [self _SC_setCurrentMode:newmode];
      [self _SC_activateMode:newmode event:event point:&pn];
    }
    else [self _SC_setCurrentMode:nil];
  }
#endif

  if (!handled) {
    NSEventType type = [event type];
    if ((type == NSKeyUp) || (type == NSKeyDown)) {
      BOOL keydown = NO;
      if (type == NSKeyDown) keydown = YES;
      switch ([[event characters] characterAtIndex:0]) {
      case NSUpArrowFunctionKey:
        SELF->uparrow = keydown;
        handled = YES;
        break;
      case NSDownArrowFunctionKey:
        SELF->downarrow = keydown;
        handled = YES;
        break;
      case NSLeftArrowFunctionKey:
        SELF->leftarrow = keydown;
        handled = YES;
        break;
      case NSRightArrowFunctionKey:
        SELF->rightarrow = keydown;
        handled = YES;
        break;
      default:
        break;
      }
    }
  }

  if (handled) {
    [SUPER->currentcamera soCamera]->touch();
  }
  return handled;
}

- (void)update
{
  SC21_LOG_METHOD;
  NSTimeInterval currtime = [NSDate timeIntervalSinceReferenceDate];
  NSTimeInterval dt = currtime - SELF->_prevtime;
  SELF->_prevtime = currtime;

  float throttle = (SELF->uparrow)?1.0f:0.0f + (SELF->downarrow)?-1.0f:0.0f;
  [SELF->flymode setThrottle:throttle];

  [SELF->flymode modifyCamera:SUPER->currentcamera withTimeInterval:currtime];
}

#pragma mark --- NSCoding conformance ---

@end

@implementation SCFlyHandler (InternalAPI)

- (Class)_SC_modeForOperation:(SCOperation)operation
{
//   switch (operation) {
//   case SCRotate: 
//     return [SCRotateMode class];
//     break;
//   case SCPan: 
//     return [SCPanMode class];
//     break;
//   case SCZoom:
//     return [SCZoomMode class];
//     break;
//   case SCNoOperation: 
//   default:
//     return Nil;
//     break;
//   }
  return Nil;
}

@end
