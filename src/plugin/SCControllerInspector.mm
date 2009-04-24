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
 

#import "SCControllerInspector.h"
#import <Sc21/SCController.h>
#import "SCUtil.h"

@implementation SCControllerInspector

- (NSString *)viewNibName {
	return @"SCControllerInspector";
}

// FIXME: Figure out where this actually ends up. kintel 20090326.
//- (NSString *)label {
//	return @"SCControllerInspector";
//}

- (void)ok:(id)sender
{
  SC21_DEBUG(@"SCControllerInspector.ok:");
  SCController *sccontroller = [[self inspectedObjects] lastObject];
  
  // Undo support
//  [self beginUndoGrouping];
 // [self noteAttributesWillChangeForObject:sccontroller];
  
  [sccontroller setClearsColorBuffer:([clearcolorbuffer state] == NSOnState)];
  [sccontroller setClearsDepthBuffer:([cleardepthbuffer state] == NSOnState)];
}

- (void)refresh
{
  SC21_DEBUG(@"SCControllerInspector.revert:");
  SCController *sccontroller = [[self inspectedObjects] lastObject];
  
  [clearcolorbuffer 
   setState:([sccontroller clearsColorBuffer] ? NSOnState : NSOffState)];
  [cleardepthbuffer 
   setState:([sccontroller clearsDepthBuffer] ? NSOnState : NSOffState)];
  
  [super refresh];
}

@end
