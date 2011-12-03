/**************************************************************************\
 * Copyright (c) Kongsberg Oil & Gas Technologies AS
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 
 * Neither the name of the copyright holder nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
\**************************************************************************/

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
