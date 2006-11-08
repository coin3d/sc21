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
