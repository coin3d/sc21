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

#import <Sc21/SCEventHandler.h>

@class SCExaminerHandlerP;

@interface SCExaminerHandler : SCEventHandler <NSCoding>
/*" NSObject "*/
{
 @protected
  SCExaminerHandlerP * _sc_examinerhandler;
}

/*" Mouse- and keybindings for rotate mode "*/
- (void)setRotateButton:(int)buttonNr modifier:(unsigned int)modifierFlags;
- (void)getRotateButton:(int*)buttonNr modifier:(unsigned int*)modifierFlags;
- (void)disableRotateButton;
- (BOOL)rotateButtonIsEnabled;

/*" Mouse- and keybindings for pan mode "*/
- (void)setPanButton:(int)buttonNr modifier:(unsigned int)modifierFlags;
- (void)getPanButton:(int*)buttonNr modifier:(unsigned int*)modifierFlags;
- (void)disablePanButton;
- (BOOL)panButtonIsEnabled;

/*" Mouse- and keybindings for zoom mode "*/
- (void)setZoomButton:(int)buttonNr modifier:(unsigned int)modifierFlags;
- (void)getZoomButton:(int*)buttonNr modifier:(unsigned int*)modifierFlags;
- (void)disableZoomButton;
- (BOOL)zoomButtonIsEnabled;

/*" Controlling "spin" animation "*/
- (void)setSpinEnabled:(BOOL)enabled;
- (BOOL)spinEnabled;

/*" Controlling the mouse wheel "*/
- (void)setScrollWheelZoomEnabled:(BOOL)enabled;
- (BOOL)scrollWheelZoomEnabled;

@end
