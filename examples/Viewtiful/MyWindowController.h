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

#import <Cocoa/Cocoa.h>
#import <Sc21/Sc21.h>

@interface MyWindowController : NSWindowController
{
  IBOutlet SCController *controller;
  IBOutlet NSTextField *typetext;
  IBOutlet NSTextField *sizetext;
  IBOutlet NSButton *modebutton;
  IBOutlet SCEventHandler *examinerhandler;
  IBOutlet SCEventHandler *coinhandler;
}

- (BOOL)validateMenuItem:(NSMenuItem *)item;
- (IBAction)modeButtonClicked:(id)sender;
- (IBAction)modeMenuSelected:(id)sender;
- (IBAction)dumpScenegraph:(id)sender;
- (IBAction)showDebugInfo:(id)sender;
- (IBAction)documentChanged:(id)sender;
- (IBAction)viewAll:(id)sender;
@end
