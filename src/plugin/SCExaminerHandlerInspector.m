/* =============================================================== *
 |                                                                 |
 | This file is part of Sc21, a Cocoa user interface binding for   |
 | the Coin 3D visualization library.                              |
 |                                                                 |
 | Copyright (c) 2003-2009 Kongsberg SIM AS . All rights reserved. |
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
 | of our support services, please contact Kongsberg SIM AS        |
 | about acquiring a Coin Professional Edition License.            |
 |                                                                 |
 | See http://www.coin3d.org/mac/Sc21 for more information.        |
 |                                                                 |
 | Kongsberg SIM AS , Bygdoy Alle 5, 0257 Oslo, Norway.            |
 |                                                                 |
 * =============================================================== */
 

#import "SCExaminerHandlerInspector.h"
#import "SCExaminerHandlerP.h"

#import "SCUtil.h"

@interface SCExaminerHandlerInspector (InternalAPI)

- (void)_SC_okWithButton:(int)button index:(int)idx;
- (unsigned int)_SC_flagsForCommand:(NSButton *)cmd alt:(NSButton *)alt
                              shift:(NSButton *)shift;
- (int)_SC_indexForModifier:(unsigned int)r;
- (void)_SC_revertPopUpButton:(NSPopUpButton *)popup forButton:(int)button;
- (void)_SC_setStateOfCommand:(NSButton *)cmd alt:(NSButton *)alt
  shift:(NSButton *)shift forFlags:(unsigned int)flags;
@end

@implementation SCExaminerHandlerInspector

/*
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
        img = [[NSImage alloc] initWithContentsOfFile:imagePath];    
        if (!img) {
          SC21_DEBUG(@"Couldn't load image %@", imagePath);
        }
      }
    }
  }
  return self;
}

- (void) dealloc
{
  [img release]; 
  [super dealloc];
}
*/

- (NSString *)viewNibName {
	return @"SCExaminerHandlerInspector";
}

- (void)ok:(id)sender
{  
  // Note that mouse button emulation settings depends on the order of
  // menu items being "no emulation", "command", "alt", "shift";
  // order of buttons being "left", "right", "middle", "none";
  // and modifier settings on the order "command", "alt", "shift".
  
  // FIXME: Use tags instead of relying on order. kyrah 20040807

  SCExaminerHandler * scexaminerhandler = [[self inspectedObjects] lastObject];
  
  // Undo support
//  [self beginUndoGrouping];
//  [self noteAttributesWillChangeForObject:scexaminerhandler];  
  
  // FIXME: For some reason, undo works, except for the modifiers.
  // It is possible to undo "unsetting" the checkbox, but not to
  // undo setting it. Huh??? kyrah 20040827.

  // mouse button emulation
  [self _SC_okWithButton:2 index:[middleButtonEmulation indexOfSelectedItem]];
  [self _SC_okWithButton:1 index:[rightButtonEmulation indexOfSelectedItem]];
    
  // rotate mode
  int r  = [rotateButton indexOfSelectedItem];
  if (r >= 0 && r<3) {
    [scexaminerhandler setRotateButton:r modifier: 
      [self _SC_flagsForCommand:rotate_command alt:rotate_alt 
      shift:rotate_shift]];
  } else [scexaminerhandler disableRotateButton];
  [scexaminerhandler setSpinEnabled:([enableSpin state] == NSOnState)];
  
   // pan mode
  int p  = [panButton indexOfSelectedItem];
  if (p >= 0 && p<3) {
    [scexaminerhandler setPanButton:p modifier: 
      [self _SC_flagsForCommand:pan_command alt:pan_alt 
      shift:pan_shift]];
  } else [scexaminerhandler disablePanButton];
  
  // zoom mode
  int z  = [zoomButton indexOfSelectedItem];
  if (z >= 0 && z<3) {
    [scexaminerhandler setZoomButton:z modifier: 
      [self _SC_flagsForCommand:zoom_command alt:zoom_alt 
      shift:zoom_shift]];
  } else [scexaminerhandler disableZoomButton];
  [scexaminerhandler 
    setScrollWheelZoomEnabled:([enableWheel state] == NSOnState)];
  
}

- (void)refresh
{
  SCExaminerHandler * handler = [[self inspectedObjects] lastObject];
  
  // mouse button emulation
  [self _SC_revertPopUpButton:rightButtonEmulation forButton:1];
  [self _SC_revertPopUpButton:middleButtonEmulation forButton:2];
  
  // rotate mode: button, modifier flags, spinning?
  int idx = [handler rotateButtonIsEnabled] ? [handler rotateButton] : 3;
  [rotateButton selectItemAtIndex:idx];
  [self _SC_setStateOfCommand:rotate_command alt:rotate_alt shift:rotate_shift 
    forFlags:[handler rotateModifier]];
  [enableSpin setState:([handler spinEnabled] ? NSOnState : NSOffState)];
    
  // pan mode: button, modifier flags
  idx = [handler panButtonIsEnabled] ? [handler panButton] : 3;
  [panButton selectItemAtIndex:idx];
  [self _SC_setStateOfCommand:pan_command alt:pan_alt shift:pan_shift 
    forFlags:[handler panModifier]];
  
  // zoom mode: button, modifier flags, use wheel?
  idx = [handler zoomButtonIsEnabled] ? [handler zoomButton] : 3;
  [zoomButton selectItemAtIndex:idx];
  [self _SC_setStateOfCommand:zoom_command alt:zoom_alt shift:zoom_shift 
    forFlags:[handler zoomModifier]];
  [enableWheel setState:([handler scrollWheelZoomEnabled] ?
    NSOnState:NSOffState)];

  NSString * conflict = [handler _SC_conflictDescription];
  [conflictWarning setToolTip:conflict];
  
  if (supportsSetHidden) {
    [conflictWarning setHidden:!conflict];
  }
  else {
    [conflictImage setImage:(conflict) ? img : nil];
    [conflictText setStringValue:
            (conflict) ? @"Warning: Conflicting bindings." : @""];
  }
  
  [super refresh];
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
      default: break; // just to avoid compiler warning
    }
    [[[[self inspectedObjects] lastObject] _SC_emulator] emulateButton:button usingModifier:flags];
  } else {
    [[[[self inspectedObjects] lastObject] _SC_emulator] removeEmulationForButton:button];  
  } 
}

- (void)_SC_revertPopUpButton:(NSPopUpButton *)popup forButton:(int)button 
{
  SCExaminerHandler * scexaminerhandler = [[self inspectedObjects] lastObject];
  if (![[scexaminerhandler _SC_emulator] emulatesButton:button]) {
    [popup selectItemAtIndex:0];  
  } else {
    [popup selectItemAtIndex:[self _SC_indexForModifier:
      [[scexaminerhandler _SC_emulator] modifierToEmulateButton:button]]];
  }  
}

- (void)_SC_setStateOfCommand:(NSButton *)cmd alt:(NSButton *)alt
    shift:(NSButton *)shift forFlags:(unsigned int) flags
{
  if ((flags & NSCommandKeyMask) == NSCommandKeyMask) 
    [cmd setState:NSOnState];
  if ((flags & NSAlternateKeyMask) == NSAlternateKeyMask)
    [alt setState:NSOnState];
  if ((flags & NSShiftKeyMask) == NSShiftKeyMask)
    [shift setState:NSOnState];
}

- (unsigned int)_SC_flagsForCommand:(NSButton *)cmd alt:(NSButton *)alt
                              shift:(NSButton *)shift
{
  unsigned int flags = 0;
  if ([cmd state] ==  NSOnState) flags |= NSCommandKeyMask;
  if ([alt state] ==  NSOnState) flags |= NSAlternateKeyMask;
  if ([shift state] ==  NSOnState) flags |= NSShiftKeyMask;
  return flags;
}

- (int)_SC_indexForModifier:(unsigned int)r
{
  int idx = 0;  
  if ((r & NSCommandKeyMask) == NSCommandKeyMask) idx = 1;
  else if ((r & NSAlternateKeyMask) == NSAlternateKeyMask) idx = 2;
  else if ((r & NSShiftKeyMask) == NSShiftKeyMask) idx = 3;
  return idx;
}

@end

@implementation SCExaminerHandler (IBPalette)

- (NSString *)_SC_conflictDescription
{
  BOOL emulatesright = NO, emulatesmiddle = NO;
  BOOL enabled [3];
  enabled[0] = [self rotateButtonIsEnabled];
  enabled[1] = [self panButtonIsEnabled];
  enabled[2] = [self zoomButtonIsEnabled];
  
  int count = 0;
  
  if (enabled[0]) count ++;
  if (enabled[1]) count ++;
  if (enabled[2]) count ++;
  
  if ([[self _SC_emulator] emulatesButton:1]) { 
    emulatesright = YES; count++;
    if (enabled[0] && [self rotateButton] == 1) count++;
    if (enabled[1] && [self panButton] == 1) count++;
    if (enabled[2] && [self zoomButton] == 1) count++;
  }
  
  if ([[self _SC_emulator] emulatesButton:2]) { 
    emulatesmiddle = YES; count++;
    if (enabled[0] && [self rotateButton] == 2) count++;
    if (enabled[1] && [self panButton] == 2) count++;
    if (enabled[2] && [self zoomButton] == 2) count++;
  }
  
  int buttons[count];
  unsigned int modifiers[count];
  NSMutableArray * names = [NSMutableArray arrayWithCapacity:5];  
  NSArray * rotatepanzoom = 
    [NSArray arrayWithObjects:@"Rotate", @"Pan", @"Zoom", nil];
  int idx = 0;  
  
  if (enabled[0]) {
    [self getRotateButton:&buttons[idx] modifier:&modifiers[idx]];
    [names addObject:[rotatepanzoom objectAtIndex:idx]]; 
    idx++;
  }
  
  if (enabled[1]) {
    [self getPanButton:&buttons[idx] modifier:&modifiers[idx]]; 
    [names addObject:[rotatepanzoom objectAtIndex:idx]]; 
    idx++;
  }
  
  if (enabled[2]) {
    [self getZoomButton:&buttons[idx] modifier:&modifiers[idx]];
    [names addObject:[rotatepanzoom objectAtIndex:idx]]; 
    idx++;
  }
    
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
      if (enabled[i] && buttons[i] == 1 && modifiers[i] != 0) {
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
      if (enabled[i] && buttons[i] == 2  && modifiers[i] != 0) {
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
  for (i = 0; i < idx; i++) {
    for (j = 0; j < idx; j++) {
      if (i == j) continue;
      if (buttons[i] == buttons[j] && modifiers[i] == modifiers[j]) {
        SC21_DEBUG(@"conflict between (%d %u) and (%d %u)",
                   buttons[i], modifiers[i], buttons[j], modifiers[j]);
        return [NSString stringWithFormat:@"%@ and %@", 
          [names objectAtIndex:i], 
          [names objectAtIndex:j]];
      }
    }
  }
  
  return nil;
}

- (int)zoomButton
{
  int z;
  unsigned int m;
  [self getZoomButton:&z modifier:&m];
  return z;
}

- (int)panButton
{
  int p;
  unsigned int m;
  [self getPanButton:&p modifier:&m];
  return p;
}

- (int)rotateButton
{
  int r;
  unsigned int m;
  [self getRotateButton:&r modifier:&m];
  return r; 
}

- (unsigned int)zoomModifier
{
  int z;
  unsigned int m;
  [self getZoomButton:&z modifier:&m];
  return m;
}

- (unsigned int)panModifier
{
  int p;
  unsigned int m;
  [self getPanButton:&p modifier:&m];
  return m;
}

- (unsigned int)rotateModifier
{
  int r;
  unsigned int m;
  [self getRotateButton:&r modifier:&m];
  return m; 
}

- (void)setRotateModifier:(unsigned int)modifier
{
  [self setRotateButton:[self rotateButton] modifier:modifier];
}

- (void)setRotateButton:(int)button
{
  [self setRotateButton:button modifier:[self rotateModifier]];
}

- (void)setZoomModifier:(unsigned int)modifier
{
  [self setZoomButton:[self zoomButton] modifier:modifier];
}

- (void)setZoomButton:(int)button
{
  [self setZoomButton:button modifier:[self zoomModifier]];
}

- (void)setPanModifier:(unsigned int)modifier
{
  [self setPanButton:[self panButton] modifier:modifier];
}

- (void)setPanButton:(int)button
{
  [self setPanButton:button modifier:[self panModifier]];
}

@end

