/* ============================================================== *
 |                                                                |
 | This file is part of SC21, a Cocoa user interface binding for  |
 | the Coin 3D visualization library.                             |
 |                                                                |
 | Copyright (c) 2003 Systems in Motion. All rights reserved.     |
 |                                                                |
 | SC21 is free software; you can redistribute it and/or          |
 | modify it under the terms of the GNU General Public License    |
 | ("GPL") version 2 as published by the Free Software            |
 | Foundation.                                                    |
 |                                                                |
 | A copy of the GNU General Public License can be found in the   |
 | source distribution of SC21. You can also read it online at    |
 | http://www.gnu.org/licenses/gpl.txt.                           |
 |                                                                |
 | For using Coin with software that can not be combined with the |
 | GNU GPL, and for taking advantage of the additional benefits   |
 | of our support services, please contact Systems in Motion      |
 | about acquiring a Coin Professional Edition License.           |
 |                                                                |
 | See http://www.coin3d.org/mac/SC21 for more information.       |
 |                                                                |
 | Systems in Motion, Bygdoy Alle 5, 0257 Oslo, Norway.           |
 |                                                                |
 * ============================================================== */
 

#import "SCControllerInspector.h"
#import <SC21/SCController.h>

@implementation SCControllerInspector

- (id)init
{
  NSLog(@"SCControllerInspector.init");
  self = [super init];
  BOOL ok = [NSBundle loadNibNamed:@"SCControllerInspector" owner:self];
  if (ok == NO) NSLog(@"SCControllerInspector.init: Failed loading nib");
  //FIXME: Return nil on error? (kintel 20030324)
  return self;
}

- (void)ok:(id)sender
{
  NSLog(@"SCControllerInspector.ok:");
  SCController *sccontroller = [self object];

  [sccontroller 
    setHandlesEventsInViewer:([handleEventsInViewer state] == NSOnState)];
  [sccontroller setAutoClipValue:[autoClipValue floatValue]];

  [super ok:sender];
}

- (void)revert:(id)sender
{
  NSLog(@"SCControllerInspector.revert:");
  SCController *sccontroller = [self object];

  [handleEventsInViewer 
    setState:[sccontroller handlesEventsInViewer]?NSOnState:NSOffState];
  [autoClipValue setFloatValue:[sccontroller autoClipValue]];

  [super revert:sender];
}

@end
