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
}

- (void)modeChanged:(id)sender
{
  if ([coincontroller handlesEventsInViewer]) [mode setState:NSOffState];
  else [mode setState:NSOnState];
}

- (IBAction)showDebugInfo:(id)sender
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

- (IBAction)viewAll:(id)sender
{
  [[coincontroller sceneGraph] viewAll];
}

- (IBAction)dumpSceneGraph:(id)sender
{
  SCDumpSceneGraph([coincontroller sceneManager]->getSceneGraph());
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

// Delegate method for NSOpenPanel used in open:
// Tries to read scene data from the file and sets the scenegraph to
// the read root node. 

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

// SCSceneGraph delegate implementation

#if 0
- (void)didCreateSuperSceneGraph:(SoSeparator *)superscenegraph
{
  // just checking that it works....
  NSLog(@"Superscenegraph created.");
}
#endif
@end
