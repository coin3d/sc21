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

#import "MyWindowController.h"
#import "MyDocument.h"
#import <Sc21/SCDebug.h>
#import <Inventor/nodes/SoSeparator.h>
#import <Inventor/SoSceneManager.h>

@implementation MyWindowController

- (id)init
{
  NSLog(@"MyWindowController.init");
  if (self = [super initWithWindowNibName:@"MyDocument"]) {

    [[NSNotificationCenter defaultCenter] 
      addObserver:self
      selector:@selector(applicationDidHide:)
      name:NSApplicationDidHideNotification object:nil];    
    
    [[NSNotificationCenter defaultCenter] 
      addObserver:self
      selector:@selector(applicationDidUnhide:)
      name:NSApplicationDidUnhideNotification object:nil];    
  }

  return self;
}

- (void)dealloc
{
  NSLog(@"MyWindowController.dealloc");

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [super dealloc];
}

- (void)awakeFromNib
{
  NSLog(@"MyWindowController.awakeFromNib");
  [self documentChanged:self];
}

- (void)windowWillLoad
{
  NSLog(@"MyWindowController.windowWillLoad");
}

- (void)windowDidLoad
{
  NSLog(@"MyWindowController.windowDidLoad");
}

- (void)windowDidMiniaturize:(NSNotification *)notif
{
  NSLog(@"MyWindowController.windowDidMiniturize");
  [controller sceneManager]->deactivate();
}

- (void)windowDidDeminiaturize:(NSNotification *)notif
{
  NSLog(@"MyWindowController.windowDidDeminiturize");
  [controller sceneManager]->activate();
}

- (IBAction)modeButtonClicked:(id)sender
{
  BOOL viewmode = ([modebutton state] != NSOnState);
  [controller setHandlesEventsInViewer:viewmode];
}

- (IBAction)modeMenuSelected:(id)sender
{
  NSLog(@"MyWindowController.modeMenuSelected");
  NSMenuItem *item = sender;
  BOOL viewmode = ([item state] == NSOnState);
  [controller setHandlesEventsInViewer:viewmode];
  [modebutton setState:viewmode?NSOffState:NSOnState];
}

- (IBAction)dumpScenegraph:(id)sender
{
  NSLog(@"MyWindowController.dumpScenegraph");
  SCDumpSceneGraph([controller sceneManager]->getSceneGraph());
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
  // Set checkmark for "Pick Mode" menu item
  if ([item tag] == 901) {
    [item setState:[modebutton state]];
  }
  return YES;
}

- (IBAction)showDebugInfo:(id)sender
{
  NSString *info = SCOpenGLInfo();
  NSWindow *panel = NSGetInformationalAlertPanel(@"Debug info",
                                                 info, @"Dismiss", nil, nil );
  [NSApp runModalForWindow:panel];
  [panel close];
  NSReleaseAlertPanel(panel);
}

- (IBAction)documentChanged:(id)sender
{
  MyDocument *doc = [self document];
  // FIXME: MyDocument should contain an SCSceneGraph instance
  // instead of an SoGroup. kyrah 20040723.
  SCSceneGraph * sg = [[SCSceneGraph alloc] init];
  [sg setRoot:[doc sceneGraph]];
  [controller setSceneGraph:sg];
  [sg release];
  [controller viewAll];

  [typetext setStringValue:[doc fileType]];
  [sizetext setStringValue:[doc fileSize]];
}

- (void)applicationDidHide:(NSNotification *)notif
{
  NSLog(@"MyWindowController.applicationDidHide");
  [controller sceneManager]->deactivate();
}

- (void)applicationDidUnhide:(NSNotification *)notif
{
  NSLog(@"MyWindowController.applicationDidUnhide");
  if (![[self window] isMiniaturized]) {
    [controller sceneManager]->activate();
  }
}

@end
