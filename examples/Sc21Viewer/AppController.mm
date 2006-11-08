/* =============================================================== *
 |                                                                 |
 | This file is part of Sc21, a Cocoa user interface binding for   |
 | the Coin 3D visualization library.                              |
 |                                                                 |
 | Copyright (c) 2003-2006 Systems in Motion. All rights reserved. |
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

@implementation AppController

- (id)init
{
  self = [super init];
  return self; 
}

- (void)awakeFromNib
{
  [filenametext setStringValue:@"None"];
  
  // Register for notifications so that we can show an alert panel
  // if a file cannot be read.
  [[NSNotificationCenter defaultCenter] 
    addObserver:self selector:@selector(reportError:) 
    name:SCReadErrorNotification object:[coincontroller sceneGraph]];
}

// Display information about OpenGL version and pixelformat settings.

- (IBAction)showDebugInfo:(id)sender
{
  NSString * info = [SCDebug openGLInfo];
  NSWindow * panel = NSGetInformationalAlertPanel(@"Debug info",
                                                  info, @"Dismiss", nil, nil);
  [NSApp runModalForWindow:panel];
  [panel close];
  NSReleaseAlertPanel(panel);
}

// Switches the headlight on and off. ("Headlight" refers to the
// lightsource that is automatically inserted as part of the
// "superscenegraph" if a scene without any lights is loaded. See the
// SCSceneGraph documentation for more information.)

- (IBAction)toggleHeadlight:(id)sender
{
  SoLight * light = [[coincontroller sceneGraph] headlight];
  if (light) {
    light->on.setValue(!light->on.getValue());
  } else {
    NSLog(@"Tried to toggle headlight, but there is no headlight in scene.");
  }
}

// Position the camera so that the whole scene is visible.

- (IBAction)viewAll:(id)sender
{
  [[coincontroller sceneGraph] viewAll];
}

// Debug: Save the whole scenegraph to disk. (See the SCDebug
// documentation for more information.)

- (IBAction)dumpSceneGraph:(id)sender
{
  [SCDebug dumpSceneGraph:[coincontroller sceneManager]->getSceneGraph()];
}

// Displays a standard file open dialog. The sender argument is ignored. 

- (IBAction)open:(id)sender
{
  NSOpenPanel * panel = [NSOpenPanel openPanel];
  [panel beginSheetForDirectory:nil
                           file:nil
                          types:[NSArray arrayWithObjects:@"wrl", @"iv", nil]
                 modalForWindow:[NSApp mainWindow]
                  modalDelegate:self
                 didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
                    contextInfo:nil];
}

// Delegate method for NSOpenPanel used in open: Tries to read scene
// data from the file and sets the scenegraph to the read root node.

- (void)openPanelDidEnd:(NSOpenPanel*)panel returnCode:(int)rc contextInfo:(void *)ctx
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

// Display an alert if the file cannot be read (called when an
// SCCouldNotReadSceneNotification is received).

- (void)reportError:(NSNotification *)notification;
{
  NSString * errorstr = [[notification userInfo] valueForKey:@"description"];
  NSRunAlertPanel(@"Error", errorstr, @"OK", nil, nil);
  NSLog(@"An error occured: %@", errorstr);
}

@end
