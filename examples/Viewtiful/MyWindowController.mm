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

#import "MyWindowController.h"
#import "MyDocument.h"
#import <SC21/SCView.h>
#import <Inventor/nodes/SoSeparator.h>

@implementation MyWindowController

- (id)init
{
  NSLog(@"MyWindowController.init");
  self = [super initWithWindowNibName:@"MyDocument"];
  return self;
}

- (void)dealloc
{
  NSLog(@"MyWindowController.dealloc");
  [super dealloc];
}

- (void)awakeFromNib
{
  NSLog(@"MyWindowController.awakeFromNib");
  [self documentChanged:self];
  [[self window] makeFirstResponder:[controller view]];
}

- (void)windowWillLoad
{
  NSLog(@"MyWindowController.windowWillLoad");
}

- (void)windowDidLoad
{
  NSLog(@"MyWindowController.windowDidLoad");
  
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
  [controller dumpSceneGraph];
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
  NSString *info = [controller debugInfo];
  NSWindow *panel = NSGetInformationalAlertPanel(@"Debug info",
                                                 info, @"Dismiss", nil, nil );
  [NSApp runModalForWindow:panel];
  [panel close];
  NSReleaseAlertPanel(panel);
}

- (IBAction)documentChanged:(id)sender
{
  MyDocument *doc = [self document];
  [controller setSceneGraph:[doc sceneGraph]];
  [controller viewAll];

  [typetext setStringValue:[doc fileType]];
  [sizetext setStringValue:[doc fileSize]];
}

@end
