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
 
#import <Cocoa/Cocoa.h>
#import <Inventor/SoDB.h>
#import "Sc21Palette.h"
#import "SCUtil.h"

@implementation Sc21Palette

- (void)dealloc
{
  [scview release];
  [sccontroller release];
  [scexaminerhandler release];
  [sccoinhandler release];
  [scscenegraph release];
  [super dealloc];
}

- (void)finishInstantiate
{
  SC21_DEBUG(@"Sc21Palette.finishInstantiate");
  scview = [[SCView alloc] initWithFrame:[scviewitem bounds]];
  sccontroller = [[SCController alloc] init];
  scexaminerhandler = [[SCExaminerHandler alloc] init];
  sccoinhandler = [[SCCoinHandler alloc] init];
  scscenegraph = [[SCSceneGraph alloc] init];
  
  [self associateObject:scview
        ofType:IBViewPboardType
        withView:scviewitem];

  [self associateObject:scview
        ofType:IBViewPboardType
        withView:scviewtextfielditem];
  
  [self associateObject:sccontroller
        ofType:IBObjectPboardType
        withView:sccontrolleritem];
  
  [self associateObject:scexaminerhandler
        ofType:IBObjectPboardType
        withView:scexaminerhandleritem];
 
  [self associateObject:sccoinhandler
        ofType:IBObjectPboardType
        withView:sccoinhandleritem];

 [self associateObject:scscenegraph
        ofType:IBObjectPboardType
        withView:scscenegraphitem];
}

@end

// ---------- IBObjectProtocol -----------

@implementation SCView (Sc21PaletteInspector)

- (NSString *)inspectorClassName
{
  return [super inspectorClassName];
}
@end

@implementation SCOpenGLView (Sc21PaletteInspector)

- (NSString *)inspectorClassName
{
  return @"SCOpenGLViewInspector";
}
@end

@implementation SCController (Sc21PaletteInspector)

- (NSString *)inspectorClassName
{
  return @"SCControllerInspector";
}

- (NSString *)classInspectorClassName
{
  // FIXME: This is not documented or mentioned _anywhere_,
  // but some guesswork and testing suggests that it should work.
  // FIXME: Test this by instantiating some common objects
  // from within IB and call this method.
  // (kintel 20040407)
  return @"IBCustomClassInspector";
}
@end

@implementation SCExaminerHandler (Sc21PaletteInspector)

- (NSString *)inspectorClassName
{
  return  @"SCExaminerHandlerInspector";
}

- (NSString *)classInspectorClassName
{
  return @"IBCustomClassInspector";
}
@end

@implementation SCCoinHandler (Sc21PaletteInspector)

// - (NSString *)inspectorClassName
// {
//   return  @"SCCoinHandlerInspector";
// }

- (NSString *)classInspectorClassName
{
  return @"IBCustomClassInspector";
}
@end

@implementation SCSceneGraph (Sc21PaletteInspector)

- (NSString *)inspectorClassName
{
  return  @"SCSceneGraphInspector";
}
// FIXME: What on Earth is this, and do I need it? kyrah 20040719
- (NSString *)classInspectorClassName
{
  return @"IBCustomClassInspector";
}
@end


// --------------- IB workarounds --------------

// FIXME: Another hack: For some reason, IB crashes if we are trying to
// render while not in test-interface mode. Weird, but until I find
// out what's going on, I'll just disable rendering unless we
// are in test interface mode.

@interface SCController (IBTest)
+ (void)_SC_idle:(NSNotification *)n;
@end

@implementation SCController (IBTest)
+ (void)_SC_idle:(NSNotification *)n
{
  if ([NSApp isTestingInterface]) {
    SoDB::getSensorManager()->processTimerQueue();
    SoDB::getSensorManager()->processDelayQueue(TRUE);
  } else {
    // do nothing
  }
}
@end
