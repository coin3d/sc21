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
 
#import "SCSceneGraphInspector.h"
#import <Sc21/SCSceneGraph.h>
#import "SCSceneGraphP.h"
#import "SCUtil.h"

@implementation SCSceneGraphInspector

- (NSString *)viewNibName {
	return @"SCSceneGraphInspector";
}

- (void)ok:(id)sender
{
  SC21_DEBUG(@"SCSceneGraphInspector.ok:");
  SCSceneGraph * scscenegraph = [[self inspectedObjects] lastObject];
  
  // Undo support
//  [self beginUndoGrouping];
//  [self noteAttributesWillChangeForObject:scscenegraph];
  
  [scscenegraph _SC_setCreatesSuperSceneGraph:([createsuperscenegraph state] == NSOnState)];
}

- (void)refresh
{
  SC21_DEBUG(@"SCSceneGraphInspector.refresh");
  SCSceneGraph * scscenegraph = [[self inspectedObjects] lastObject];
  [createsuperscenegraph setState:
    ([scscenegraph _SC_createsSuperSceneGraph] ? NSOnState:NSOffState)];
  [super refresh];
}

@end

// Undo support workaround:
// IB wants a standard accessor method - it does not accept our _SC_xxx one.
// FIXME: Maybe there's a way to tell IB what accessor to use? Investigate.
// kyrah 20040827

@interface SCSceneGraph (UndoSupport)
- (void)setCreatesSuperSceneGraph:(BOOL)yn;
- (BOOL)createsSuperSceneGraph;
@end

@implementation SCSceneGraph (UndoSupport)
- (void)setCreatesSuperSceneGraph:(BOOL)yn
{
  [self _SC_setCreatesSuperSceneGraph:yn]; 
}

- (BOOL)createsSuperSceneGraph
{
  return [self _SC_createsSuperSceneGraph];
}
@end