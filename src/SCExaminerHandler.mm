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

#import <Sc21/SCExaminerHandler.h>
#import <Sc21/SCCamera.h>
#import "SCRotateMode.h"
#import "SCPanMode.h"
#import "SCZoomMode.h"
#import "SCSpinMode.h"
#import "SCMouseLog.h"
#import "SCUtil.h"
#import <Sc21/SCController.h>

#import <Sc21/SCExaminerHandlerP.h>

@implementation SCExaminerHandlerP
@end

#define SELF self->_sc_examinerhandler

@implementation SCExaminerHandler

/*" 
  SCExaminerHandler allows you to inspect the scene by rotating,
  panning, and zooming in and out. 

  Note that the mouse + modifier key combinations are most easily
  configured through the associated InterfaceBuilder inspector.
"*/

#pragma mark --- initialization and cleanup ---

- (id)init
{
  if (self = [super init]) {
    [self _SC_commonInit];
    [self setRotateButton:0 modifier:0];
    [self setPanButton:2 modifier:0];
    [self setZoomButton:0 modifier:NSShiftKeyMask];
    [self setSpinEnabled:YES];
    [self setScrollWheelZoomEnabled:YES];
    SELF->emulator = [[SCEmulator alloc] init];
  }
  return self;
}

- (void)dealloc
{
  [SELF->emulator release];
  [SELF release];
}

#pragma mark --- mouse- and keybindings --- 

/*" Returns !{YES} if panning by clicking and dragging is enabled. "*/

- (BOOL)panButtonIsEnabled
{
  return SELF->panbuttonenabled;
}

/*" Returns !{YES} if rotating by clicking and dragging is enabled. "*/

- (BOOL)rotateButtonIsEnabled
{
  return SELF->rotatebuttonenabled;
}

/*" 
  Returns !{YES} if zooming by clicking and dragging is enabled. 

  Note that this does not affect zooming via the mouse wheel.
"*/
- (BOOL)zoomButtonIsEnabled
{
  return SELF->zoombuttonenabled;
}

/*" Disable panning by clicking and dragging. "*/

- (void)disablePanButton
{
  SELF->panbuttonenabled = NO;
}

/*" Disable rotating by clicking and dragging. "*/

- (void)disableRotateButton
{
  SELF->rotatebuttonenabled = NO;
}

/*" 
  Disable zooming by clicking and dragging. 

  Note that this does not affect zooming via the mouse wheel.
"*/

- (void)disableZoomButton
{
  SELF->zoombuttonenabled = NO;
}

/*" Set the mouse button and modifier key(s) used for panning. "*/
- (void)setPanButton:(int)buttonNumber modifier:(unsigned int)modifierFlags
{
  SELF->panbutton = buttonNumber;
  SELF->panmodifier = modifierFlags;
  SELF->panbuttonenabled = YES;
}

/*" Set the mouse button and modifier key(s) used for rotating. "*/
- (void)setRotateButton:(int)buttonNumber modifier:(unsigned int)modifierFlags
{
  SELF->rotatebutton = buttonNumber;
  SELF->rotatemodifier = modifierFlags;
  SELF->rotatebuttonenabled = YES;
}

/*" Set the mouse button and modifier key(s) used for zooming. "*/
- (void)setZoomButton:(int)buttonNumber modifier:(unsigned int)modifierFlags
{
  SELF->zoombutton = buttonNumber;
  SELF->zoommodifier = modifierFlags;
  SELF->zoombuttonenabled = YES;  
}

/*" Get the mouse button and modifier key(s) used for panning. "*/
- (void)getPanButton:(int*)button modifier:(unsigned int*)modifierFlags
{
  *button = SELF->panbutton;
  *modifierFlags = SELF->panmodifier;
}

/*" Get the mouse button and modifier key(s) used for rotating. "*/
- (void)getRotateButton:(int*)button modifier:(unsigned int*)modifierFlags
{
  *button = SELF->rotatebutton;
  *modifierFlags = SELF->rotatemodifier; 
}

/*" Get the mouse button and modifier key(s) used for zooming. "*/
- (void)getZoomButton:(int*)button modifier:(unsigned int*)modifierFlags
{
  *button = SELF->zoombutton;
  *modifierFlags = SELF->zoommodifier;  
}

#pragma mark --- additional settings ---

/*" 
  Pass !{YES} to enable "spinning" (i.e. starting a continuous
  animation by dragging and then releasing). 
"*/
- (void)setSpinEnabled:(BOOL)enabled
{
  SELF->spinenabled = enabled;
}

/*" Returns !{YES} if spinning is enabled, and !{NO} otherwise. "*/

- (BOOL)spinEnabled
{
  return SELF->spinenabled;
}

/*" 
  Pass !{YES} to enable scrolling by using the mouse wheel (if 
  present).
"*/
- (void)setScrollWheelZoomEnabled:(BOOL)enabled
{
  SELF->scrollwheelzoomenabled = enabled;
}

/*" 
  Returns !{YES} if the mouse wheel can be used for zooming, and !{NO}
  otherwise.

  Note that this only reports whether Sc21 is %{set up} to use the
  mouse wheel. You cannot use this method to check if a mouse wheel is
  present at runtime or not.
"*/

- (BOOL)scrollWheelZoomEnabled
{
  return SELF->scrollwheelzoomenabled;
}

#pragma mark --- SCEventHandler conformance ---

- (BOOL)controller:(SCController *)controller handleEvent:(NSEvent *)event
{ 
  SC21_LOG_METHOD;
  NSRect frame = [[controller drawable] frame];
  NSPoint p = [event locationInWindow];
  NSPoint pn;
  pn.x = (p.x - frame.origin.x) / frame.size.width;
  pn.y = (p.y - frame.origin.y) / frame.size.height;

  BOOL handled = NO;
  int eventtype = [event type];
  
  if (![self _SC_usesEvent:event]) {
    if([event type] == NSScrollWheel && SELF->scrollwheelzoomenabled) {
      [[[controller sceneGraph] camera] zoom:[event deltaY]/500.0f];
    }
    return NO;
  }
  
  if (eventtype == NSLeftMouseDragged || 
      eventtype == NSRightMouseDragged ||
      eventtype == NSOtherMouseDragged) {
    SCMode * currentmode = [self _SC_currentMode];
    if (currentmode) {
      if (![currentmode isActive]) {
        [self _SC_activateMode:currentmode camera:
          [[controller sceneGraph] camera] event:event point:&pn];
      } else {
        [[SCMouseLog defaultMouseLog] appendPoint:&pn 
                                      timestamp:[event timestamp]];
      }
      handled = [currentmode modifyCamera:[[controller sceneGraph] camera]
                             withValue:[currentmode valueForEvent:event]];
    }
    return handled;
  }
  
  unsigned int modifierflags = [event modifierFlags];

  Class mode = [[self _SC_currentMode] class];
  if (eventtype == NSLeftMouseUp ||
      eventtype == NSRightMouseUp ||
      eventtype == NSOtherMouseUp) {
    if (mode) {
      if (SELF->spinenabled && mode == [SCRotateMode class]) {
        //FIXME: Check contents of mouselog before enabling spin
        mode = [SCSpinMode class];
      }
      else {
        mode = Nil;
      }
      [[NSCursor arrowCursor] set];
      [[NSNotificationCenter defaultCenter]
        postNotificationName:SCCursorChangedNotification object:self];  
      //handled = YES;
    }
  } 
  else if (eventtype == NSLeftMouseDown ||
           eventtype == NSRightMouseDown ||
           eventtype == NSOtherMouseDown) {    
    // Check for emulations
    int effectivebutton = [event buttonNumber];
    if (SELF->emulator) {
      effectivebutton = [SELF->emulator emulatedButtonForButton:effectivebutton
                             modifier:modifierflags];
    }
    Class newmode = [self _SC_modeForButton:effectivebutton 
                                   modifier:modifierflags];
    if (newmode != Nil) mode = newmode;
  }

  if (mode != [[self _SC_currentMode] class]) {
    [[self _SC_currentMode] deactivate];
    if (mode) {
      SCMode * newmode = [[[mode alloc] init] autorelease];
      [self _SC_setCurrentMode:newmode];
      [self _SC_activateMode:newmode camera:[[controller sceneGraph] camera] 
                       event:event point:&pn];
    }
    else [self _SC_setCurrentMode:nil];
    handled = YES;
  }

  if (!handled &&
      [event type] == NSScrollWheel && 
      SELF->scrollwheelzoomenabled) {
    [[[controller sceneGraph] camera] zoom:[event deltaY]/500.0f];
    handled = YES;
  }

  return handled;
}

- (void)update:(SCController *)controller
{
  NSTimeInterval currtime = [NSDate timeIntervalSinceReferenceDate];
  [SELF->currentmode modifyCamera:[[controller sceneGraph] camera] 
                 withTimeInterval:currtime];
}

#pragma mark --- NSCoding conformance ---

- (void)encodeWithCoder:(NSCoder *)coder
{
  if ([coder allowsKeyedCoding]) {
    [coder encodeInt:SELF->panbutton forKey:@"SC_panbutton"];
    [coder encodeInt:SELF->rotatebutton forKey:@"SC_rotatebutton"];
    [coder encodeInt:SELF->zoombutton forKey:@"SC_zoombutton"];
    // FIXME: Is encodeInt: the right method to use for unsigned int? 
    // kyrah 20040801.
    [coder encodeInt:SELF->panmodifier forKey:@"SC_panmodifier"];
    [coder encodeInt:SELF->rotatemodifier forKey:@"SC_rotatemodifier"];
    [coder encodeInt:SELF->zoommodifier forKey:@"SC_zoommodifier"];
    [coder encodeBool:SELF->panbuttonenabled forKey:@"SC_panbuttonenabled"];
    [coder encodeBool:SELF->rotatebuttonenabled 
               forKey:@"SC_rotatebuttonenabled"];
    [coder encodeBool:SELF->zoombuttonenabled forKey:@"SC_zoombuttonenabled"];
    [coder encodeBool:SELF->spinenabled forKey:@"SC_spinenabled"];
    [coder encodeBool:SELF->scrollwheelzoomenabled 
               forKey:@"SC_scrollwheelzoomenabled"];
    [coder encodeObject:SELF->emulator forKey:@"SC_emulator"];
  }
}

- (id)initWithCoder:(NSCoder *)coder
{
  if (self = [super init]) {
    [self _SC_commonInit];
    if ([coder allowsKeyedCoding]) {
      SELF->panbutton = [coder decodeIntForKey:@"SC_panbutton"];
      SELF->rotatebutton = [coder decodeIntForKey:@"SC_rotatebutton"];
      SELF->zoombutton = [coder decodeIntForKey:@"SC_zoombutton"];
      SELF->panmodifier = [coder decodeIntForKey:@"SC_panmodifier"];
      SELF->rotatemodifier = [coder decodeIntForKey:@"SC_rotatemodifier"];
      SELF->zoommodifier = [coder decodeIntForKey:@"SC_zoommodifier"];
      SELF->panbuttonenabled = [coder decodeBoolForKey:@"SC_panbuttonenabled"];
      SELF->rotatebuttonenabled = 
        [coder decodeBoolForKey:@"SC_rotatebuttonenabled"];
      SELF->zoombuttonenabled = 
        [coder decodeBoolForKey:@"SC_zoombuttonenabled"];
      SELF->spinenabled = [coder decodeBoolForKey:@"SC_spinenabled"];
      SELF->scrollwheelzoomenabled = 
        [coder decodeBoolForKey:@"SC_scrollwheelzoomenabled"];
      SELF->emulator = [[coder decodeObjectForKey:@"SC_emulator"] retain];
      NSLog(@"emulator: %@", SELF->emulator);
    }
  }
  return self;
}

@end

@implementation SCExaminerHandler (InternalAPI)

- (void)_SC_commonInit
{
  SELF = [[SCExaminerHandlerP alloc] init];
}

- (void)_SC_setCurrentMode:(SCMode *)mode
{
  [mode retain];
  [SELF->currentmode release];
  SELF->currentmode = mode;
}

- (SCMode *)_SC_currentMode
{
  return SELF->currentmode;
}

- (void)_SC_activateMode:(SCMode *)newmode camera:(SCCamera *)camera
                   event:(NSEvent *)event point:(NSPoint *)pn
{
  [newmode activate:event point:pn camera:camera];
  [[SCMouseLog defaultMouseLog] setStartPoint:pn timestamp:[event timestamp]];
  [[newmode cursor] set];
  [[NSNotificationCenter defaultCenter]
    postNotificationName:SCCursorChangedNotification object:self];  
}

- (Class)_SC_modeForButton:(int)buttonNumber modifier:(unsigned int)modifierFlags
{
  unsigned int matchedflags = 0;
  Class matchedmode = Nil;
  
  if (SELF->rotatebuttonenabled && 
      SELF->rotatebutton == buttonNumber && 
      (SELF->rotatemodifier & modifierFlags) == SELF->rotatemodifier &&
      SELF->rotatemodifier >= matchedflags) {
    matchedflags = SELF->rotatemodifier;
    matchedmode = [SCRotateMode class];    
  }
  
  if (SELF->zoombuttonenabled && 
      SELF->zoombutton  == buttonNumber && 
      (SELF->zoommodifier & modifierFlags) == SELF->zoommodifier &&
      SELF->zoommodifier >= matchedflags) {
    matchedflags = SELF->zoommodifier;
    matchedmode = [SCZoomMode class];  
  }
  
  if (SELF->panbuttonenabled && 
      SELF->panbutton  == buttonNumber && 
      (SELF->panmodifier & modifierFlags) == SELF->panmodifier &&
      SELF->panmodifier >= matchedflags)  {
    matchedflags = SELF->panmodifier;
    matchedmode = [SCPanMode class];
  }
  
  return matchedmode;
}

#pragma mark --- mouse button emulation ---

- (SCEmulator *)_SC_emulator
{
  return SELF->emulator;
}

- (void)_SC_setEmulator:(SCEmulator *)emulator
{
  if (emulator != SELF->emulator) [SELF->emulator release];
  SELF->emulator = [emulator retain];
}

#pragma mark --- other stuff ---

- (BOOL)_SC_usesEvent:(NSEvent *)event
{
  int nr = [event buttonNumber];
  
  // It is not guaranteed that modifierflags == 0 when no modifier keys are
  // pressed, so it is not possible to compare 
  //   if (modifierflags == SELF->panmodifier)
  // However, we can mask out the modifiers that _could_ be present, and 
  // compare against those.
  
  // FIXME: This does of course not cover any additional modifiers that might 
  // be added in the future (the rest of SCExaminerHandler is not using any 
  // specific modifier flags... only the IB palette does). kyrah 20040827
  
  // Known modifiermasks as of AppKit version C (AppKit library
  // compatibility version 45.0.0, current version 743.0.0)
  unsigned int flags = [event modifierFlags] & 
    (NSAlphaShiftKeyMask | NSShiftKeyMask | NSControlKeyMask | 
     NSAlternateKeyMask | NSCommandKeyMask | NSNumericPadKeyMask | 
     NSHelpKeyMask | NSFunctionKeyMask);
  
  // Check for emulation
  if (SELF->emulator) {
      nr = [SELF->emulator emulatedButtonForButton:nr modifier:flags];
      // Remove modifier for emulation from the modifiers we look at.
      // (e.g. if shift + click emulates rightclick, and we get
      // shift + alt + click, we want to process this as
      // alt + rightclick (not shift + alt + rightclick)!)
      flags ^= [SELF->emulator modifierToEmulateButton:nr];
  }
  
  // Actual check whether the event matches a known combination
   if ((nr == SELF->panbutton && (flags == SELF->panmodifier)) || 
       (nr == SELF->rotatebutton && (flags == SELF->rotatemodifier)) ||
       (nr == SELF->zoombutton && (flags == SELF->zoommodifier))) {
    return YES;
  } else {
    return NO;
  }
}

@end
