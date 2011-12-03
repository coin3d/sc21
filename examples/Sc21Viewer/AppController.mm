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
