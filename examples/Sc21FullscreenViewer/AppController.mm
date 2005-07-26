/* =============================================================== *
 |                                                                 |
 | This file is part of Sc21, a Cocoa user interface binding for   |
 | the Coin 3D visualization library.                              |
 |                                                                 |
 | Copyright (c) 2003-2005 Systems in Motion. All rights reserved. |
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

#import "AppController.h"
#import <Sc21/Sc21.h>
#import <Sc21/SCDebug.h>
#import <Inventor/SoInput.h>
#import <Inventor/nodes/SoSeparator.h>
#import <Inventor/nodes/SoDirectionalLight.h>
#import <Inventor/SoSceneManager.h>
#import <Inventor/actions/SoGLRenderAction.h>
#import <Inventor/elements/SoGLCacheContextElement.h>
#import <OpenGL/gl.h>
#import <OpenGL/OpenGL.h>

@implementation AppController

#pragma mark -- initialization --

- (id)init
{
  self = [super init];
  return self;
}

- (void)awakeFromNib
{
  [filenametext setStringValue:@"None"];
}


#pragma mark -- SCDrawable conformance --

- (void)display
{
  [coincontroller render];
  [fullScreenContext flushBuffer];
}

- (NSRect)frame
{
  if (fullScreenContext) {
    return NSMakeRect(0, 0, 
                      CGDisplayPixelsWide(displayid), 
                      CGDisplayPixelsHigh(displayid));
  } else {
    return [view frame];
  }
}

#pragma mark -- fullscreen mode --

- (IBAction)enterFullScreenMode:(id)sender
{
  CGLContextObj cglContext;
  CGDisplayErr err;
  long oldSwapInterval;
  long newSwapInterval;

  SCOpenGLPixelFormat * newformat = [[[SCOpenGLPixelFormat alloc] init] autorelease];
  [newformat setAttribute:NSOpenGLPFAAccelerated];
  [newformat setAttribute:NSOpenGLPFADoubleBuffer];
  [newformat setAttribute:NSOpenGLPFADepthSize toValue:16];
  [newformat setAttribute:NSOpenGLPFAFullScreen];

  NSScreen * screen = [[view window] screen];
  displayid = (CGDirectDisplayID)
    [[[screen deviceDescription] objectForKey:@"NSScreenNumber"] intValue];
  CGOpenGLDisplayMask displaymask = CGDisplayIDToOpenGLDisplayMask(displayid);

  [newformat setAttribute:NSOpenGLPFAScreenMask
             toValue:displaymask];
  NSOpenGLPixelFormat *newnsformat = [newformat pixelFormat];

  fullScreenContext = [[NSOpenGLContext alloc] initWithFormat:newnsformat 
                       shareContext:nil];

  // FIXME: We really should share the context here, to "inherit" all
  // OpenGL objects (textures, display lists) etc. Issue: Find "compatible
  // pixelformat. kyrah 20040916
  // fullScreenContext = [[NSOpenGLContext alloc] initWithFormat:newnsformat 
  // shareContext:[view openGLContext]];
  
  if (fullScreenContext == nil) {
    NSRunAlertPanel(@"Error", @"Failed to create fullScreenContext", 
                    @"OK", nil, nil);
    return;
  }
  
  // Take control of the display where we're about to go FullScreen.
  // CGDisplayCapture will do two things:
  // 1. Create a window that lies on a level guaranteed to be higher
  //    than all existing windows.
  // 2  Lock drawing to that window.

  err = CGDisplayCapture(displayid);
  if (err != CGDisplayNoErr) {
    NSRunAlertPanel(@"Error", @"Failed to capture display", 
                    @"OK", nil, nil);
    [fullScreenContext release];
    fullScreenContext = nil;
    return;
  }

  // Enter FullScreen mode and make our FullScreen context the active
  // context for OpenGL commands.
  [fullScreenContext setFullScreen];
  [fullScreenContext makeCurrentContext];

  glEnable(GL_DEPTH_TEST);
  SoGLRenderAction * gra = [coincontroller sceneManager]->getGLRenderAction();
  uint32_t oldcachecontext = gra->getCacheContext();
  gra->setCacheContext(SoGLCacheContextElement::getUniqueCacheContext());

  // Save the current swap interval so we can restore it later, and then set 
  // the new swap interval to lock us to the display's refresh rate.
  cglContext = CGLGetCurrentContext();
  CGLGetParameter(cglContext, kCGLCPSwapInterval, &oldSwapInterval);
  newSwapInterval = 1;
  CGLSetParameter(cglContext, kCGLCPSwapInterval, &newSwapInterval);

  [coincontroller setDrawable:self];

  // Now that we've got the screen, we enter a loop in which we
  // alternately process input events and computer and render the next
  // frame of our animation. The shift here is from a model in which
  // we passively receive events handed to us by the AppKit to one in
  // which we are actively driving event processing.

  BOOL stayInFullScreenMode = YES;
  while (stayInFullScreenMode) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // Check for and process input events.
    NSEvent *event;
    unichar c;
    BOOL handled;
    while (stayInFullScreenMode &&
           (event = [NSApp nextEventMatchingMask:NSAnyEventMask 
                           untilDate:[NSDate distantFuture] 
                           inMode:NSDefaultRunLoopMode 
                           dequeue:YES])) {
      handled = NO;
      switch ([event type]) {
      case NSKeyDown:
        c = [[event charactersIgnoringModifiers] characterAtIndex:0];
        if (c == 27 ||
            c == 'f' && ([event modifierFlags] & NSCommandKeyMask)) {
          stayInFullScreenMode = NO;
          handled = YES;
        }
        else if (c == 'q' && ([event modifierFlags] & NSCommandKeyMask)) {
          [NSApp terminate:self];
        }
        break;
      default:
        break;
      }
      if (stayInFullScreenMode) {
        handled = [coincontroller handleEvent:event];
      }
    }
    
    // Clean up any autoreleased objects that were created this 
    // time through the loop.
    [pool release];
  }
  
  // Clear the front and back framebuffers before switching out of 
  // FullScreen mode (This is not strictly necessary, but avoids an 
  // untidy flash of garbage.)
  glClearColor(0.0, 0.0, 0.0, 0.0);
  glClear(GL_COLOR_BUFFER_BIT);
  [fullScreenContext flushBuffer];
  glClear(GL_COLOR_BUFFER_BIT);
  [fullScreenContext flushBuffer];
  
  // Restore the previously set swap interval.
  CGLSetParameter(cglContext, kCGLCPSwapInterval, &oldSwapInterval);
  
  // Exit fullscreen mode and release our FullScreen NSOpenGLContext.
  [NSOpenGLContext clearCurrentContext];
  [fullScreenContext clearDrawable];
  [fullScreenContext release];
  fullScreenContext = nil;
  
  // Release control of the display.
  CGDisplayRelease(displayid);
  
  [coincontroller setDrawable:view];
  gra->setCacheContext(oldcachecontext);
}

#pragma mark -- menu actions --

- (IBAction)open:(id)sender
{
  NSOpenPanel * panel = [NSOpenPanel openPanel];
  [panel beginSheetForDirectory:nil
         file:nil
         types:[NSArray arrayWithObjects:@"wrl", @"iv", nil]
         modalForWindow:[view window]
         modalDelegate:self
         didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
         contextInfo:nil];
}

- (IBAction)viewAll:(id)sender
{
  [[coincontroller sceneGraph] viewAll];
}

- (IBAction)showDebugInfo:(id)sender
{
  NSString * info = [SCDebug openGLInfo];
  NSWindow * panel = NSGetInformationalAlertPanel(@"Debug info",
                     info, @"Dismiss", nil, nil);
  [NSApp runModalForWindow:panel];
  [panel close];
  NSReleaseAlertPanel(panel);
}

#pragma -- delegate methods -- 

// Delegate method for NSOpenPanel used in open:
// Tries to read scene data from the file and sets the scenegraph to
// the read root node. 

- (void)openPanelDidEnd:(NSOpenPanel*)panel returnCode:(int)rc 
  contextInfo:(void *)ctx
{
  if (rc == NSOKButton) {
    [[coincontroller sceneGraph] readFromFile:[panel filename]];
    [[coincontroller sceneGraph] viewAll];
    [filenametext setStringValue:[panel filename]];
  }
}

// Delegate implementation to quit application when window is closed.

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)nsapp
{
  return YES;
}


@end
