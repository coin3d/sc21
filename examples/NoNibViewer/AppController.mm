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
#import <Inventor/SoDB.h>
#import <Inventor/nodes/SoSeparator.h>

@implementation AppController

- (void)awakeFromNib
{
  NSLog(@"AppController.awakeFromNib");
}

// Display a file open panel on start
- (void)applicationDidFinishLaunching:(NSNotification *)notif
{
  NSLog(@"AppController.applicationDidFinishLaunching");
  NSOpenPanel * panel = [NSOpenPanel openPanel];
  [panel beginSheetForDirectory:nil
                           file:nil
                          types:[NSArray arrayWithObjects:@"wrl", @"iv", nil]
                 modalForWindow:[view window]
                  modalDelegate:self
                 didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
                    contextInfo:nil];
}

- (void) openPanelDidEnd:(NSOpenPanel*)panel returnCode:(int)rc contextInfo:(void *) ctx
{
  if (rc == NSOKButton) {
    NSString * path = [panel filename];
    SoInput in;
    if (in.openFile([path cString])) {
      SoSeparator * sg = SoDB::readAll(&in);
      in.closeFile();
      if (sg) {
        // Create an new SCExaminerController
        sccontroller = [[SCExaminerController alloc] init];
        // Create the view<->controller connection
        [sccontroller setView:view];
        [view setController:sccontroller];
        // Set the scene graph
        [sccontroller setSceneGraph:sg];
        // The magic activate
        [sccontroller activate];
        [view reshape]; // FIXME: This must be called in order to set the correct initial viewport.
                        // Should be done somewhere in SC21 instead (kintel 20031112)
        [sccontroller viewAll];

        // Add a "View All" context menu item.
        NSMenuItem * item = [[NSMenuItem alloc] init];
        [item setTitle:@"View All"];
        [item setTarget:sccontroller];
        [item setAction:@selector(viewAll)];
        [[[sccontroller view] menu] addItem:item];
        [item release]; // retained by menu
      }
    }
  }
}

@end
