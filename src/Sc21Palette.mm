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
 

#import "SC21Palette.h"
#import <Inventor/SoDB.h>

@implementation SC21Palette

- (void)dealloc
{
  [scview release];
  [sccontroller release];
  [scexaminercontroller release];
  [super dealloc];
}

- (void)finishInstantiate
{
  NSLog(@"SC21Palette.finishInstantiate");
  scview = [[SCView alloc] initWithFrame:[scviewitem bounds]];
  sccontroller = [[SCController alloc] init];
  scexaminercontroller = [[SCExaminerController alloc] init];
  
  [self associateObject:scview
        ofType:IBViewPboardType
        withView:scviewitem];
  
  [self associateObject:sccontroller
        ofType:IBObjectPboardType
        withView:sccontrolleritem];
  
  [self associateObject:scexaminercontroller
        ofType:IBObjectPboardType
        withView:scexaminercontrolleritem];

  [self associateObject:scexaminercontroller
        ofType:IBObjectPboardType
        withView:testitem];

  [scview reshape];
}

@end

// ---------- IBObjectProtocol -----------

@implementation SCOpenGLView (SC21PaletteInspector)

- (NSString *)inspectorClassName
{
  return @"SCOpenGLViewInspector";
}

@end

@implementation SCView (SC21PaletteInspector)

- (NSString *)inspectorClassName
{
  return [super inspectorClassName];
}
@end

@implementation SCController (SC21PaletteInspector)

- (NSString *)inspectorClassName
{
  return nil;
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

@implementation SCExaminerController (SC21PaletteInspector)

- (NSString *)inspectorClassName
{
  return [super inspectorClassName];
}

- (NSString *)classInspectorClassName
{
  return [super classInspectorClassName];
}

@end

// Due to a bug in Interface Builder, custom NSOpenGLViews are not
// displayed in IB's "design" mode (they are shown in the same
// gray as the window background, basically making them invisible
// when not selected.
// The following is a workaround for this problem. When loaded from
// the palette, the drawRect implementation from the category below
// will be used instead of SCView's drawRect, allowing us to do our
// own custom drawing when running in IB.
// Note: "Overriding" class methods in categories is a generally
// discouraged practice (see Hillegrass et al.) but Ken (Apple
// OpenGL group) actually suggested this workaround and says we
// can assume that the category method will be called instead of
// class' regular implementation in all cases.

@interface SCView (IBTest)
- (void) drawRect:(NSRect) frame;
@end

@implementation SCView (IBTest)
- (void) drawRect:(NSRect) frame
{
  NSLog(@"SC21Palette: SCView.drawRect:");
  [[NSColor blackColor] set];
  NSRectFill(frame);

  // FIXME: figure out how to draw string centered
  //[@"SCView" drawInRect:frame withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
  //  [NSColor grayColor], NSForegroundColorAttributeName,
  //  [NSFont systemFontOfSize:24], NSFontAttributeName,
  //  nil]];
}
@end


// Another hack: For some reason, IB crashes if we are trying to
// render while not in test-interface mode. Weird, but until I find
// out what's going on, I'll just disable rendering unless we
// are in test interface mode.

@interface SCController (IBTest)
- (void) _idle:(NSTimer *) t;
@end

@implementation SCController (IBTest)
- (void) _idle:(NSTimer *) t
{
  if ([NSApp isTestingInterface]) {
    SoDB::getSensorManager()->processTimerQueue();
    SoDB::getSensorManager()->processDelayQueue(TRUE);
  } else {
    // do nothing
  }
}
@end
