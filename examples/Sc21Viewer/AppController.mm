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

#import "AppController.h"
#import <SC21/SC21.h>
#import <SC21/SCDebug.h>
#import <Inventor/SoInput.h>
#import <Inventor/nodes/SoSeparator.h>

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

  [mode setTarget:self];
  [mode setAction:@selector(toggleModes:)];

  // Add context meny entries
  [[coincontroller view] setMenu:[[[NSMenu alloc] initWithTitle:@"Context menu"] autorelease]];

  [self  addMenuEntry:@"toggle mode" target:self action:@selector(toggleModes:)];
  [self  addMenuEntry:@"toggle headlight" target:self action:@selector(toggleHeadlight)];
  [self  addMenuEntry:@"toggle camera type" target:self action:@selector(toggleCameraType)];
  [self  addMenuEntry:@"viewAll" target:coincontroller action:@selector(viewAll)];
  [self  addMenuEntry:@"show debug info" target:self action:@selector(showDebugInfo)];
  [self  addMenuEntry:@"dumpSceneGraph" target:coincontroller action:@selector(dumpSceneGraph)];
  
  // Register for notification: we want to know when to mode
  // is changed, so that we can update the UI. (The mode might be changed
  // both from the menu or via the checkbox.)
  [[NSNotificationCenter defaultCenter] addObserver:self
                                        selector:@selector(modeChanged:)
                                        name:SCModeChangedNotification
                                        object:nil];
}


- (void)modeChanged:(id)sender
{
  if ([coincontroller handlesEventsInViewer]) [mode setState:NSOffState];
  else [mode setState:NSOnState];
}

- (void)showDebugInfo
{
  NSString * info = SCOpenGLInfo();
  NSWindow * panel = NSGetInformationalAlertPanel(@"Debug info",
                                                  info, @"Dismiss", nil, nil);
  [NSApp runModalForWindow:panel];
  [panel close];
  NSReleaseAlertPanel(panel);
}

// Toggles whether events should be interpreted as viewer events, i.e.
// if they should be regarded as input for controlling the viewer or
// sent to the scene graph directly.

- (void)toggleModes:(id)sender
{
  [coincontroller 
    setHandlesEventsInViewer:([coincontroller handlesEventsInViewer]?NO:YES)];
}

// Toggles between perspective and orthographic camera.

- (void)toggleCameraType
{
  [coincontroller 
    setCameraType:([coincontroller cameraType] == SCCameraPerspective ? 
                   SCCameraOrthographic : SCCameraPerspective)];
}


// Switches the headlight on and off.

- (void)toggleHeadlight
{
  [coincontroller setHeadlightIsOn:([coincontroller headlightIsOn] ? NO : YES)];
}

// Displays a standard file open dialog. The sender argument is ignored. 

- (IBAction)open:(id)sender
{
  NSOpenPanel * panel = [NSOpenPanel openPanel];
  [panel beginSheetForDirectory:nil
         file:nil
         types:[NSArray arrayWithObjects:@"wrl", @"iv", nil]
         modalForWindow:[[coincontroller view] window]
         modalDelegate:self
         didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
         contextInfo:nil];
}



// Delegate method for NSOpenPanel used in open:
// Tries to read scene data from the file and sets the scenegraph to
// the read root node. If reading fails for some reason, an error message
// is displayed, and the current scene graph is not changed.

- (void)openPanelDidEnd:(NSOpenPanel*)panel returnCode:(int)rc contextInfo:(void *)ctx
{
  if (rc == NSOKButton) {
    NSString * path = [panel filename];
    SoInput in;
    if (in.openFile([path cString])) {
      SoSeparator * sg = SoDB::readAll(&in);
      in.closeFile();
      if (sg) {
        [coincontroller setSceneGraph:sg];
        [filenametext setStringValue:path];
      }
    }
  }
}

// Adds a new menu entry "title" to the view's context menu.

- (NSMenuItem *)addMenuEntry:(NSString *)title target:(id)target action:(SEL)selector
{
  NSMenuItem * item = [[[NSMenuItem alloc] init] autorelease];
  [item setTitle:title];
  [item setTarget:target];
  [item setAction:selector];
  [[[coincontroller view]  menu] addItem:item];
  return item;
}

// Delegate implementation to quit application when window is being closed:
// This is not a document-based implementation, so you cannot close the main
// window and open a new one at will without doing more setup work.

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)nsapp
{
  return YES;
}


@end
