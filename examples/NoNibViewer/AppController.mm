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
#import <Inventor/SoDB.h>
#import <Inventor/nodes/SoSeparator.h>

@implementation AppController

- (void)applicationWillFinishLaunching:(NSNotification *)notif
{
  view = [[SCView alloc] initWithFrame:NSMakeRect(0.0f, 0.0f, 640.0f, 512.0f)];
  window = [[NSWindow alloc] 
             initWithContentRect:NSMakeRect(100.0f, 100.0f, 640.0f, 512.0f)
             styleMask:NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask|NSResizableWindowMask
             backing:NSBackingStoreBuffered
             defer:NO];

  [window setContentView:view];
  [view release];
  [window makeKeyAndOrderFront:nil];
  [window setInitialFirstResponder:view];
}

// Display a file open panel on start
- (void)applicationDidFinishLaunching:(NSNotification *)notif
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

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)rc contextInfo:(void *)ctx
{
  if (rc == NSOKButton) {
    SCSceneGraph * scenegraph = [[SCSceneGraph alloc] initWithContentsOfFile:[panel filename]];
    SCController * sccontroller = [[[SCController alloc] init] autorelease];
    [view setController:sccontroller]; // retained by view
    [sccontroller setSceneGraph:scenegraph];
    [sccontroller setEventHandler:[[[SCExaminerHandler alloc] init] autorelease]];
    [scenegraph viewAll];

    // Add a "View All" context menu item.
    [view setMenu:[[[NSMenu alloc] initWithTitle:@"Context menu"] autorelease]];
    NSMenuItem * item = [[[NSMenuItem alloc] init] autorelease];
    [item setTitle:@"View All"];
    [item setTarget:sccontroller];
    [item setAction:@selector(viewAll)];
    [[view menu] addItem:item];
  }
}

// Delegate implementation to quit application when window is being closed:
// This is not a document-based implementation, so you cannot close the main
// window and open a new one at will without doing more setup work.

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)nsapp
{
  return YES;
}
@end
