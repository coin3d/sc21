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
 

#import <InterfaceBuilder/InterfaceBuilder.h>
#import <Sc21/SCExaminerHandler.h>

@interface SCExaminerHandlerInspector : IBInspector
{
  IBOutlet NSPopUpButton * rotateButton;
  IBOutlet NSPopUpButton * panButton;
  IBOutlet NSPopUpButton * zoomButton;
  
  IBOutlet NSButton * rotate_command;
  IBOutlet NSButton * rotate_alt;
  IBOutlet NSButton * rotate_shift;
  IBOutlet NSButton * rotate_control;
  
  IBOutlet NSButton * pan_command;
  IBOutlet NSButton * pan_alt;
  IBOutlet NSButton * pan_shift;
  IBOutlet NSButton * pan_control;  
  
  IBOutlet NSButton * zoom_command;
  IBOutlet NSButton * zoom_alt;
  IBOutlet NSButton * zoom_shift;
  IBOutlet NSButton * zoom_control;
    
  IBOutlet NSButton * enableSpin;
  IBOutlet NSButton * enableWheel;
    
  IBOutlet NSPopUpButton * middleButtonEmulation;
  IBOutlet NSPopUpButton * rightButtonEmulation;
  
  IBOutlet NSBox * conflictWarning;
  IBOutlet NSTextField * conflictText;
  IBOutlet NSImageView * conflictImage;
  NSImage * img;
  BOOL supportsSetHidden;
}
@end

@interface SCExaminerHandler (IBPalette)
- (NSString *)_SC_conflictDescription;
- (int)_SC_zoomButton;
- (int)_SC_panButton;
- (int)_SC_rotateButton;
- (unsigned int)_SC_zoomModifier;
- (unsigned int)_SC_panModifier;
- (unsigned int)_SC_rotateModifier;
@end
