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
#import "MyEventHandler.h"
#import <Sc21/Sc21.h>
#import <Sc21/SCDebug.h>
#import <Inventor/SoInput.h>
#import <Inventor/nodes/SoGroup.h>
#import <Inventor/nodes/SoSelection.h>
#import <Inventor/nodes/SoDirectionalLight.h>
#import <Inventor/nodes/SoPerspectiveCamera.h>
#import <Inventor/nodes/SoSeparator.h>
#import <Inventor/SoSceneManager.h>

// Callback which will be called whenever a node in the scenegraph is
// selected. 
void selection_cb(void *userdata, SoPath *path)
{
  NSLog(@"Selected object!");
  path->getTail()->touch(); // force redraw
}

@implementation AppController

- (id)init
{
  if (self = [super init]) {
    ra = new SoBoxHighlightRenderAction();
  }
  return self;
}

- (void)awakeFromNib
{
  [[NSApp mainWindow] setTitle:@"None"];

  // use highlight renderaction to display bounding boxes of selected items
  ra->setCacheContext([coincontroller sceneManager]->getGLRenderAction()->getCacheContext());
  ra->setTransparencyType(SoGLRenderAction::DELAYED_BLEND);
  [coincontroller sceneManager]->setGLRenderAction(ra);
}

- (void) dealloc
{
  delete ra; 
  [super dealloc];
}

// Toggles whether events should be interpreted as viewer events, i.e.
// if they should be regarded as input for controlling the viewer or
// sent to the scene graph directly.

- (IBAction)toggleModes:(id)sender
{
  if ([[coincontroller eventHandler] respondsToSelector:@selector(toggleModes)]){
    [(MyEventHandler *)[coincontroller eventHandler] toggleModes];
  }
}

// "Wrapper"-action around toggleModes: for use from menu item.
// Necessary to keep the "send events to scenegraph" radiobutton in sync.

- (IBAction)menuToggleModes:(id)sender
{
  [mode setNextState];
  [self toggleModes:sender];
}

// Reposition the camera so that the whole scene can be seen.

- (IBAction)viewAll:(id)sender
{
  [[coincontroller sceneGraph] viewAll];
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

// Delegate method for NSOpenPanel used in open:
// Tries to read scene data from the file and sets the scenegraph to
// the read root node. 

- (void)openPanelDidEnd:(NSOpenPanel*)panel returnCode:(int)rc contextInfo:(void *)ctx
{
  if (rc == NSOKButton) {
    [[coincontroller sceneGraph] readFromFile:[panel filename]];
    [[coincontroller sceneGraph] viewAll];
    [[NSApp mainWindow] setTitle:[panel filename]];
  }
}

// dump scenegraph

- (IBAction)dumpSceneGraph:(id)sender
{
  [SCDebug dumpSceneGraph:[coincontroller sceneManager]->getSceneGraph()];
}

// Delegate implementation to quit application when window is being closed.

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)nsapp
{
  return YES;
}

// SCSceneGraph delegate implementation: add selection node before the
// scenegraph.

- (SoGroup *)createSuperSceneGraph:(SoGroup *)scenegraph
{
  SoSeparator * root = new SoSeparator;
  SoSelection * selection = new SoSelection;
  selection->addSelectionCallback(selection_cb, NULL);
  selection->addChild(scenegraph);
  root->addChild(selection);
  return root;
}

@end
