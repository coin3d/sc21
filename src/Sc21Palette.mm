//
//  SC21Palette.m
//  SC21
//
//  Created by Karin Kosina on Wed Jun 18 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "SC21Palette.h"
#import "SCExaminerController.h"

@implementation SC21Palette

- (void)finishInstantiate
{
  scview = [[SCView alloc] initWithFrame:[viewbutton bounds]];
  [self associateObject:scview
                 ofType:IBViewPboardType
               withView:viewbutton];
  
  [self associateObject:[[SCController alloc] init]
                 ofType:IBObjectPboardType
               withView:controllerbutton];

  [self associateObject:[[SCExaminerController alloc] init] 	ofType:IBObjectPboardType
               withView:examinerbutton];

  NSLog(@"Calling reshape");
  [scview reshape];
}
@end

@implementation SCView (SC21PaletteInspector)

- (NSString *)inspectorClassName
{
    return @"SC21Inspector";
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
- (void) drawRect:(NSRect)frame;
@end

@implementation SCView (IBTest)
- (void) drawRect:(NSRect)frame
{
  // "Test Interface" mode in IB - do regular drawRect:
  // FIXME: This should of course be shared code w/drawRect
  if ([NSApp isTestingInterface]) {
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_LIGHTING);
    [controller render];
    [[self openGLContext] flushBuffer];
  // "Design interface" mode - override.
  } else {
    [[NSColor blackColor] set];
    NSRectFill(frame);
  }
}
@end

