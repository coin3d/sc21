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
 

#import "SCExaminerHandlerInspector.h"

#import "SCUtil.h"

@implementation SCExaminerHandlerInspector

- (id)init
{
  SC21_DEBUG(@"SCExaminerHandlerInspector.init");
  self = [super init];
  BOOL ok = [NSBundle loadNibNamed:@"SCExaminerHandlerInspector" owner:self];
  if (ok == NO) {
    SC21_DEBUG(@"SCExaminerHandlerInspector.init: Failed loading nib");
    return nil;
  }
  return self;
}

- (void)ok:(id)sender
{
  NSLog(@"SCExaminerHandlerInspector.ok:");
  SCExaminerHandler * scexaminerhandler = [self object];

  // FIXME: Handle "none" selection - how? kyrah 20040801 
  
  // Note: Settings depend on the order of menu items being 
  // "left - right - middle". I intentionally did not use the title
  // to avoid problems if we ever do localization.
  
  NSLog(@"rotate_command state: %d (NSOnState: %d, NSOffState: %d", 
        [rotate_command state], NSOnState, NSOffState);
  NSLog(@"rotate_alt state: %d (NSOnState: %d, NSOffState: %d", 
        [rotate_alt state], NSOnState, NSOffState);
  NSLog(@"rotate_shift state: %d (NSOnState: %d, NSOffState: %d", 
        [rotate_shift state], NSOnState, NSOffState);
  NSLog(@"rotate_control state: %d (NSOnState: %d, NSOffState: %d", 
        [rotate_control state], NSOnState, NSOffState);
  
  unsigned int rotateflags = 0;
  if ([rotate_command state] ==  NSOnState) rotateflags |= NSCommandKeyMask;
  if ([rotate_alt state] ==  NSOnState) rotateflags |= NSAlternateKeyMask;
  if ([rotate_shift state] ==  NSOnState) rotateflags |= NSShiftKeyMask;
  if ([rotate_control state] ==  NSOnState) rotateflags |= NSControlKeyMask;
  int r  = [rotateButton indexOfSelectedItem];
  if (r >= 0 && r<3) [scexaminerhandler setRotateButton:r modifier:rotateflags];
  
  unsigned int panflags = 0;
  if ([pan_command state] ==  NSOnState) panflags |= NSCommandKeyMask;
  if ([pan_alt state] ==  NSOnState) panflags |= NSAlternateKeyMask;
  if ([pan_shift state] ==  NSOnState) panflags |= NSShiftKeyMask;
  if ([pan_control state] ==  NSOnState) panflags |= NSControlKeyMask;
  int p  = [panButton indexOfSelectedItem];
  if (p >= 0 && p < 3) [scexaminerhandler setPanButton:p modifier:panflags];

  unsigned int zoomflags = 0;
  if ([zoom_command state] ==  NSOnState) zoomflags |= NSCommandKeyMask;
  if ([zoom_alt state] ==  NSOnState) zoomflags |= NSAlternateKeyMask;
  if ([zoom_shift state] ==  NSOnState) zoomflags |= NSShiftKeyMask;
  if ([zoom_control state] ==  NSOnState) zoomflags |= NSControlKeyMask;
  int z  = [zoomButton indexOfSelectedItem];
  if (z >= 0 && z < 3) [scexaminerhandler setZoomButton:z modifier:zoomflags];
  
  [scexaminerhandler setSpinEnabled:([enableSpin state] == NSOnState)];
  [scexaminerhandler setScrollWheelZoomEnabled:([enableWheel state] == NSOnState)];
  
  NSLog(@"rotateflags: %u", rotateflags);
    
  [super ok:sender];
}

- (void)revert:(id)sender
{
  NSLog(@"SCExaminerHandlerInspector.revert:");
  SCExaminerHandler * scexaminerhandler = [self object];
  
  unsigned int rotateflags = [scexaminerhandler _SC_rotateModifier];
  if ((rotateflags & NSCommandKeyMask) == NSCommandKeyMask) 
    [rotate_command setState:NSOnState];
  if ((rotateflags & NSAlternateKeyMask) == NSAlternateKeyMask)
    [rotate_alt setState:NSOnState];
  if ((rotateflags & NSShiftKeyMask) == NSShiftKeyMask)
    [rotate_shift setState:NSOnState];
  if ((rotateflags & NSControlKeyMask) == NSControlKeyMask)
    [rotate_control setState:NSOnState];

  unsigned int panflags = [scexaminerhandler _SC_panModifier];
  if ((panflags & NSCommandKeyMask) == NSCommandKeyMask) 
    [pan_command setState:NSOnState];
  if ((panflags & NSAlternateKeyMask) == NSAlternateKeyMask)
    [pan_alt setState:NSOnState];
  if ((panflags & NSShiftKeyMask) == NSShiftKeyMask)
    [pan_shift setState:NSOnState];
  if ((panflags & NSControlKeyMask) == NSControlKeyMask)
    [pan_control setState:NSOnState];

  unsigned int zoomflags = [scexaminerhandler _SC_zoomModifier];
  if ((zoomflags & NSCommandKeyMask) == NSCommandKeyMask) 
    [zoom_command setState:NSOnState];
  if ((zoomflags & NSAlternateKeyMask) == NSAlternateKeyMask)
    [zoom_alt setState:NSOnState];
  if ((zoomflags & NSShiftKeyMask) == NSShiftKeyMask)
    [zoom_shift setState:NSOnState];
  if ((zoomflags & NSControlKeyMask) == NSControlKeyMask)
    [zoom_control setState:NSOnState];  
    
  [zoomButton selectItemAtIndex:[scexaminerhandler _SC_zoomButton]];
  [panButton selectItemAtIndex:[scexaminerhandler _SC_panButton]];
  [rotateButton selectItemAtIndex:[scexaminerhandler _SC_rotateButton]];
  
  [enableSpin setState:([scexaminerhandler spinEnabled] ? 
                        NSOnState : NSOffState)];
  [enableWheel setState:([scexaminerhandler scrollWheelZoomEnabled] ?
                         NSOnState:NSOffState)];

  [super revert:sender];
}

@end

@implementation SCExaminerHandler (IBPalette)

- (int)_SC_zoomButton
{
  int z;
  unsigned int m;
  [self getZoomButton:&z modifier:&m];
  return z;
}

- (int)_SC_panButton
{
  int p;
  unsigned int m;
  [self getPanButton:&p modifier:&m];
  return p;
}

- (int)_SC_rotateButton
{
  int r;
  unsigned int m;
  [self getRotateButton:&r modifier:&m];
  return r; 
}

- (unsigned int)_SC_zoomModifier
{
  int z;
  unsigned int m;
  [self getZoomButton:&z modifier:&m];
  return m;
}

- (unsigned int)_SC_panModifier
{
  int p;
  unsigned int m;
  [self getPanButton:&p modifier:&m];
  return m;
}

- (unsigned int)_SC_rotateModifier
{
  int r;
  unsigned int m;
  [self getRotateButton:&r modifier:&m];
  return m; 
}

@end

