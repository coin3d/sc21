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
 

#import <Cocoa/Cocoa.h>
#import <SC21/SC21.h>

@interface AppController : NSObject
{
  IBOutlet SCExaminerController * coincontroller;
  IBOutlet SCView * view;
  IBOutlet NSButton * mode;
  IBOutlet NSTextField * filenametext;
}
- (IBAction)open:(id) sender;
- (void)toggleModes:(id) sender;
- (void)toggleHeadlight;
- (void)toggleCameraType;
- (void)modeChanged:(id) sender;
- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)rc contextInfo:(void *)ctx;
- (NSMenuItem *)addMenuEntry:(NSString *)title target:(id)target action:(SEL)selector;
@end
