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
#import "SCExaminerHandlerP.h"

#import "SCUtil.h"

@interface SCExaminerHandlerInspector (InternalAPI)

- (void)_SC_okWithButton:(int)button index:(int)idx;
- (unsigned int)_SC_flagsForCommand:(NSButton *)cmd alt:(NSButton *)alt
                              shift:(NSButton *)shift ctrl:(NSButton *)ctrl;
- (int)_SC_indexForModifier:(unsigned int)r;
- (void)_SC_revertPopUpButton:(NSPopUpButton *)popup forButton:(int)button;
- (void)_SC_setStateOfCommand:(NSButton *)cmd alt:(NSButton *)alt
  shift:(NSButton *)shift ctrl:(NSButton *)ctrl forFlags:(unsigned int)flags;
@end

@implementation SCExaminerHandlerInspector

- (id)init
{
  SC21_DEBUG(@"SCExaminerHandlerInspector.init");
  if (self = [super init]) {
    img = nil;
    
    BOOL ok = [NSBundle loadNibNamed:@"SCExaminerHandlerInspector" owner:self];
    if (ok == NO) {
      SC21_DEBUG(@"SCExaminerHandlerInspector.init: Failed loading nib");
      return nil;
    }
    
    // Jaguar doesn't support hiding views, so we have to fake hiding by 
    // manually switching between showing either our graphics or nil
    supportsSetHidden = [[NSView class] instancesRespondToSelector:@selector(setHidden:)];
    if (!supportsSetHidden) {
      NSString * imagePath;
      NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
      if (imagePath = [thisBundle pathForResource:@"InspectorError" ofType:@"tiff"]) {
        NSLog(@"Image path: %@", imagePath);
        img = [[NSImage alloc] initWithContentsOfFile:imagePath];    
        if (!img) {
          NSLog(@"Couldn't load image %@", imagePath);
        }
      }
    }
  }
  return self;
}

- (void) dealloc
{
  [img release]; 
}

- (void)ok:(id)sender
{  
  // Note that mouse button emulation settings depends on the order of
  // menu items being "no emulation", "command", "alt", "shift", "control",
  // and modifier settings on the order "command", "alt", "shift", "control".

  SCExaminerHandler * scexaminerhandler = [self object];

  // mouse button emulation
  [self _SC_okWithButton:2 index:[middleButtonEmulation indexOfSelectedItem]];
  [self _SC_okWithButton:1 index:[rightButtonEmulation indexOfSelectedItem]];
    
  // rotate mode
  int r  = [rotateButton indexOfSelectedItem];
  if (r >= 0 && r<3) {
    [scexaminerhandler setRotateButton:r modifier: 
      [self _SC_flagsForCommand:rotate_command alt:rotate_alt 
      shift:rotate_shift ctrl:rotate_control]];
  }
  [scexaminerhandler setSpinEnabled:([enableSpin state] == NSOnState)];
  
   // pan mode
  int p  = [panButton indexOfSelectedItem];
  if (p >= 0 && p<3) {
    [scexaminerhandler setPanButton:p modifier: 
      [self _SC_flagsForCommand:pan_command alt:pan_alt 
      shift:pan_shift ctrl:pan_control]];
  }
  
  // zoom mode
  int z  = [zoomButton indexOfSelectedItem];
  if (z >= 0 && z<3) {
    [scexaminerhandler setZoomButton:z modifier: 
      [self _SC_flagsForCommand:zoom_command alt:zoom_alt 
      shift:zoom_shift ctrl:zoom_control]];
  }
  [scexaminerhandler 
    setScrollWheelZoomEnabled:([enableWheel state] == NSOnState)];
  
  [super ok:sender];
}

- (void)revert:(id)sender
{
  SCExaminerHandler * scexaminerhandler = [self object];
  
  // mouse button emulation
  [self _SC_revertPopUpButton:rightButtonEmulation forButton:1];
  [self _SC_revertPopUpButton:middleButtonEmulation forButton:2];
  
  // rotate mode: button, modifier flags, spinning?
  [rotateButton selectItemAtIndex:[scexaminerhandler _SC_rotateButton]];
  [self _SC_setStateOfCommand:rotate_command alt:rotate_alt
    shift:rotate_shift ctrl:rotate_control 
    forFlags:[scexaminerhandler _SC_rotateModifier]];
  [enableSpin setState:([scexaminerhandler spinEnabled] ? 
     NSOnState : NSOffState)];
    
  // pan mode: button, modifier flags
  [panButton selectItemAtIndex:[scexaminerhandler _SC_panButton]];
  [self _SC_setStateOfCommand:pan_command alt:pan_alt
    shift:pan_shift ctrl:pan_control 
    forFlags:[scexaminerhandler _SC_panModifier]];
  
  // zoom mode: button, modifier flags, use wheel?
  [zoomButton selectItemAtIndex:[scexaminerhandler _SC_zoomButton]];
  [self _SC_setStateOfCommand:zoom_command alt:zoom_alt
    shift:zoom_shift ctrl:zoom_control 
    forFlags:[scexaminerhandler _SC_zoomModifier]];
  [enableWheel setState:([scexaminerhandler scrollWheelZoomEnabled] ?
    NSOnState:NSOffState)];

  NSString * conflict = [scexaminerhandler _SC_conflictDescription];
  [conflictWarning setToolTip:conflict];
  
  if (supportsSetHidden) {
    [conflictWarning setHidden:!conflict];
  }
  else {
    [conflictImage setImage:(conflict) ? img : nil];
    [conflictText setStringValue:
            (conflict) ? @"Warning: Conflicting bindings." : @""];
  }
  
  [super revert:sender];
}

@end

@implementation SCExaminerHandlerInspector (InternalAPI)

- (void)_SC_okWithButton:(int)button index:(int)idx
{
  unsigned int flags = 0;
  if (idx > 0 && idx <= 4) {
    switch (idx) {
      case 1: 
        flags |= NSCommandKeyMask; break;
      case 2: 
        flags |= NSAlternateKeyMask; break;
      case 3: 
        flags |= NSShiftKeyMask; break;
      case 4: 
        flags |= NSControlKeyMask; break;
      default: break; // just to avoid compiler warning
    }
    [[[self object] _SC_emulator] emulateButton:button usingModifier:flags];
  } else {
    [[[self object] _SC_emulator] removeEmulationForButton:button];  
  } 
}

- (void)_SC_revertPopUpButton:(NSPopUpButton *)popup forButton:(int)button 
{
  SCExaminerHandler * scexaminerhandler = [self object];
  if (![[scexaminerhandler _SC_emulator] emulatesButton:button]) {
    [popup selectItemAtIndex:0];  
  } else {
    [popup selectItemAtIndex:[self _SC_indexForModifier:
      [[scexaminerhandler _SC_emulator] modifierToEmulateButton:button]]];
  }  
}

- (void)_SC_setStateOfCommand:(NSButton *)cmd alt:(NSButton *)alt
    shift:(NSButton *)shift ctrl:(NSButton *)ctrl forFlags:(unsigned int) flags
{
  if ((flags & NSCommandKeyMask) == NSCommandKeyMask) 
    [cmd setState:NSOnState];
  if ((flags & NSAlternateKeyMask) == NSAlternateKeyMask)
    [alt setState:NSOnState];
  if ((flags & NSShiftKeyMask) == NSShiftKeyMask)
    [shift setState:NSOnState];
  if ((flags & NSControlKeyMask) == NSControlKeyMask)
    [ctrl setState:NSOnState];
}

- (unsigned int)_SC_flagsForCommand:(NSButton *)cmd alt:(NSButton *)alt
                              shift:(NSButton *)shift ctrl:(NSButton *)ctrl
{
  unsigned int flags = 0;
  if ([cmd state] ==  NSOnState) flags |= NSCommandKeyMask;
  if ([alt state] ==  NSOnState) flags |= NSAlternateKeyMask;
  if ([shift state] ==  NSOnState) flags |= NSShiftKeyMask;
  if ([ctrl state] ==  NSOnState) flags |= NSControlKeyMask;
  return flags;
}

- (int)_SC_indexForModifier:(unsigned int)r
{
  int idx = 0;  
  if ((r & NSCommandKeyMask) == NSCommandKeyMask) idx = 1;
  else if ((r & NSAlternateKeyMask) == NSAlternateKeyMask) idx = 2;
  else if ((r & NSShiftKeyMask) == NSShiftKeyMask) idx = 3;
  else if ((r & NSControlKeyMask) == NSControlKeyMask) idx = 4;
  return idx;
}

@end

@implementation SCExaminerHandler (IBPalette)

- (NSString *)_SC_conflictDescription
{
  BOOL conflict = NO;
  BOOL emulatesright = NO, emulatesmiddle = NO;
  
  int count = 3; // rotate, zoom, pan
  if ([[self _SC_emulator] emulatesButton:1]) { 
    emulatesright = YES; count++;
    if ([self _SC_rotateButton] == 1) count++;
    if ([self _SC_panButton] == 1) count++;
    if ([self _SC_zoomButton] == 1) count++;
  }
  
  if ([[self _SC_emulator] emulatesButton:2]) { 
    emulatesmiddle = YES; count++;
    if ([self _SC_rotateButton] == 2) count++;
    if ([self _SC_panButton] == 2) count++;
    if ([self _SC_zoomButton] == 2) count++;
  }
  
  int buttons[count];
  unsigned int modifiers[count];
  NSMutableArray * names = [NSMutableArray arrayWithCapacity:5];  
  NSArray * rotatepanzoom = 
    [NSArray arrayWithObjects:@"Rotate", @"Pan", @"Zoom", nil];
  int idx = 0;  
  
  [self getRotateButton:&buttons[idx] modifier:&modifiers[idx]];
  [names addObject:[rotatepanzoom objectAtIndex:idx]]; 
  idx++;
  
  [self getPanButton:&buttons[idx] modifier:&modifiers[idx]]; 
  [names addObject:[rotatepanzoom objectAtIndex:idx]]; 
  idx++;
  
  [self getZoomButton:&buttons[idx] modifier:&modifiers[idx]];
  [names addObject:[rotatepanzoom objectAtIndex:idx]]; 
  idx++;
    
  if (emulatesright) {
    unsigned int emulationmodifier = 
    [[self _SC_emulator] modifierToEmulateButton:1];

    buttons[idx] = 0;
    modifiers[idx] = emulationmodifier;
    [names addObject:@"Right mouse emulation"]; 
    idx++;    
    
    // Add combinations for mouse emulation being used, to cover cases like
    // zoom: left + alt + command
    // pan: middle + alt
    // middle button: left + command  
    int i;
    for (i = 0; i < 3; i++) {
      if (buttons[i] == 1) {
        buttons[idx] = 0;
        modifiers[idx] = modifiers[i] | emulationmodifier;
        [names addObject:[NSString 
          stringWithFormat:@"%@ with emulated right button", 
          [rotatepanzoom objectAtIndex:i]]];
        idx++;
      }
    }    
  }
  
  if (emulatesmiddle) {
    unsigned int emulationmodifier = 
      [[self _SC_emulator] modifierToEmulateButton:2];
    
    buttons[idx] = 0;
    modifiers[idx] = emulationmodifier;
    [names addObject:@"Middle mouse emulation"]; 
    idx++;

    // see comment above
    int i;
    for (i = 0; i < 3; i++) {
      if (buttons[i] == 2) {
        buttons[idx] = 0;
        modifiers[idx] = modifiers[i] | emulationmodifier;        
        [names addObject:[NSString 
          stringWithFormat:@"%@ with emulated middle button", 
          [rotatepanzoom objectAtIndex:i]]];        
        idx++;
      }
    }        
  }
        
  // actual conflict check
  int i, j;
  for (i = 0; i < count; i++) {
    for (j = 0; j < count; j++) {
      if (i == j) continue;
      if (buttons[i] == buttons[j] && modifiers[i] == modifiers[j]) {
        return [NSString stringWithFormat:@"%@ and %@", 
          [names objectAtIndex:i], 
          [names objectAtIndex:j]];
      }
    }
  }
  
  return nil;
}

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

