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
 

#import "SCSceneGraphInspector.h"
#import <Sc21/SCSceneGraph.h>
#import "SCSceneGraphP.h"
#import "SCUtil.h"

@implementation SCSceneGraphInspector

- (id)init
{
  SC21_DEBUG(@"SCControllerInspector.init");
  if (self = [super init]) {
    BOOL ok = [NSBundle loadNibNamed:@"SCSceneGraphInspector" owner:self];
    if (ok == NO) SC21_DEBUG(@"SCSceneGraphInspector.init: Failed loading nib");
  }
  return self;
}

- (void)ok:(id)sender
{
  SC21_DEBUG(@"SCSceneGraphInspector.ok:");
  SCSceneGraph * scscenegraph = [self object];
  [scscenegraph _SC_setCreatesSuperSceneGraph:([createsuperscenegraph state] == NSOnState)];
  [super ok:sender];
}

- (void)revert:(id)sender
{
  SC21_DEBUG(@"SCSceneGraphInspector.revert:");
  SCSceneGraph * scscenegraph = [self object];
  [createsuperscenegraph setState:
    ([scscenegraph _SC_createsSuperSceneGraph] ? NSOnState:NSOffState)];
  [super revert:sender];
}

@end