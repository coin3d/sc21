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

#import "AppController.h"
#import <Sc21/Sc21.h>
#import <Sc21/SCDebug.h>
#import <Inventor/SoInput.h>
#import <Inventor/nodes/SoSeparator.h>
#import <Inventor/SoSceneManager.h>
#import <Inventor/actions/SoGLRenderAction.h>
#import <Inventor/elements/SoGLCacheContextElement.h>
#import <OpenGL/OpenGL.h>

// Redeclare "private" debugging method to avoid compiler warning. 
@interface SCDebug (InternalAPI)
+ (NSString *)infoForSCOpenGLPixelFormat:(SCOpenGLPixelFormat *)scpformat 
                     NSOpenGLPixelFormat:(NSOpenGLPixelFormat *)nspformat;
@end

@implementation AppController

- (id)init
{
  self = [super init];
  return self;
}

- (void)awakeFromNib
{
  // Display current status.
  [self modeChanged:nil];
  [filenametext setStringValue:@"None"];

  // Register for notification: we want to know when to mode
  // is changed, so that we can update the UI. (The mode might be changed
  // both from the menu or via the checkbox.)
  [[NSNotificationCenter defaultCenter] addObserver:self
                                        selector:@selector(modeChanged:)
                                        name:SCModeChangedNotification
                                        object:nil];
  [self->coincontroller setEventHandler:[[[SCExaminerHandler alloc] init] autorelease]];
}


- (void)modeChanged:(id)sender
{
  if ([coincontroller handlesEventsInViewer]) [mode setState:NSOffState];
  else [mode setState:NSOnState];
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

// Toggles whether events should be interpreted as viewer events, i.e.
// if they should be regarded as input for controlling the viewer or
// sent to the scene graph directly.

- (IBAction)toggleModes:(id)sender
{
  [coincontroller 
    setHandlesEventsInViewer:([coincontroller handlesEventsInViewer]?NO:YES)];
}


// Switches the headlight on and off.

- (IBAction)toggleHeadlight:(id)sender
{
  SoLight * light = [[coincontroller sceneGraph] headlight];
  if (light) {
    NSLog(@"Toggling headlight");
    light->on.setValue(!light->on.getValue());
  } else {
    NSLog(@"Tried to toggle headlight, but there is no headlight in scene.");
  }
  
}

// Displays a standard file open dialog. The sender argument is ignored. 

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

- (IBAction)dumpSceneGraph:(id)sender
{
  [SCDebug dumpSceneGraph:[coincontroller sceneManager]->getSceneGraph()];
}

// Delegate method for NSOpenPanel used in open:
// Tries to read scene data from the file and sets the scenegraph to
// the read root node. If reading fails for some reason, an error message
// is displayed, and the current scene graph is not changed.

- (void)openPanelDidEnd:(NSOpenPanel*)panel returnCode:(int)rc contextInfo:(void *)ctx
{
  if (rc == NSOKButton) {
    [[coincontroller sceneGraph] readFromFile:[panel filename]];
    [[coincontroller sceneGraph] viewAll];
    [filenametext setStringValue:[panel filename]];
  }
}

// Delegate implementation to quit application when window is being closed:
// This is not a document-based implementation, so you cannot close the main
// window and open a new one at will without doing more setup work.

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)nsapp
{
  return YES;
}

//FIXME:
// CGShieldingWindowLevel()
// screenRect = [[NSScreen mainScreen] frame];

- (IBAction)fullScreen:(id)sender
{
  CGLContextObj cglContext;
  CGDisplayErr err;
  long oldSwapInterval;
  long newSwapInterval;

  SCOpenGLPixelFormat * oldformat = [view pixelFormat];
  NSOpenGLPixelFormat * oldnsformat = [oldformat pixelFormat];
  NSLog([SCDebug infoForSCOpenGLPixelFormat:oldformat 
                        NSOpenGLPixelFormat:oldnsformat]);
  
  SCOpenGLPixelFormat * newformat = [[oldformat copy] autorelease];
  [newformat setAttribute:NSOpenGLPFAFullScreen];

  NSScreen * screen = [[view window] screen];
  _displayid = (CGDirectDisplayID)
    [[[screen deviceDescription] objectForKey:@"NSScreenNumber"] intValue];
  CGOpenGLDisplayMask displaymask = CGDisplayIDToOpenGLDisplayMask(_displayid);

  [newformat setAttribute:NSOpenGLPFAScreenMask
             toValue:displaymask];
//   [newformat setAttribute:NSOpenGLPFAScreenMask
//              toValue:displaymask];
  NSOpenGLPixelFormat *newnsformat = [newformat pixelFormat];

  NSLog([SCDebug infoForSCOpenGLPixelFormat:newformat 
                        NSOpenGLPixelFormat:newnsformat]);

  
  // Create an NSOpenGLContext with the FullScreen pixel format.  By specifying the non-FullScreen context as our "shareContext", we automatically inherit all of the textures, display lists, and other OpenGL objects it has defined.
  _fullScreenContext = [[NSOpenGLContext alloc] initWithFormat:newnsformat 
                                                shareContext:nil];
  
//   _fullScreenContext = 
//     [[NSOpenGLContext alloc] initWithFormat:newnsformat 
//                              shareContext:[view openGLContext]];
  
  if (_fullScreenContext == nil) {
    NSLog(@"Failed to create fullScreenContext");
    return;
  }
  
  // Take control of the display where we're about to go FullScreen.
  err = CGDisplayCapture(_displayid);
  if (err != CGDisplayNoErr) {
    [_fullScreenContext release];
    _fullScreenContext = nil;
    return;
  }

  // Enter FullScreen mode and make our FullScreen context the active 
  // context for OpenGL commands.
  [_fullScreenContext setFullScreen];
  [_fullScreenContext makeCurrentContext];

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

  // Now that we've got the screen, we enter a loop in which we alternately 
  // process input events and computer and render the next frame of our 
  // animation.  The shift here is from a model in which we passively receive 
  // events handed to us by the AppKit to one in which we are actively driving 
  // event processing.
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
      if (!handled) {
        NSLog(@"Event: %d", [event type]);
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
  [_fullScreenContext flushBuffer];
  glClear(GL_COLOR_BUFFER_BIT);
  [_fullScreenContext flushBuffer];
  
  // Restore the previously set swap interval.
  CGLSetParameter(cglContext, kCGLCPSwapInterval, &oldSwapInterval);
  
  // Exit fullscreen mode and release our FullScreen NSOpenGLContext.
  [NSOpenGLContext clearCurrentContext];
  [_fullScreenContext clearDrawable];
  [_fullScreenContext release];
  _fullScreenContext = nil;
  
  // Release control of the display.
  CGDisplayRelease(_displayid);
  
  [coincontroller setDrawable:view];
  gra->setCacheContext(oldcachecontext);
}

  // Render a frame, and swap the front and back buffers.
- (void)display
{
  [coincontroller render];
  [_fullScreenContext flushBuffer];
}

- (NSRect)frame
{
  if (_fullScreenContext) {
    return NSMakeRect(0, 0, 
                      CGDisplayPixelsWide(_displayid), 
                      CGDisplayPixelsHigh(_displayid));
  } else {
    return [view frame];
  }
}

@end
