/* =============================================================== *
 |                                                                 |
 | This file is part of Sc21, a Cocoa user interface binding for   |
 | the Coin 3D visualization library.                              |
 |                                                                 |
 | Copyright (c) 2003-2005 Systems in Motion. All rights reserved. |
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
#import <Sc21/SCController.h>
#import <Sc21/SCExaminerHandler.h>
#import <Sc21/SCCoinHandler.h>
#import <Sc21/SCSceneGraph.h>
#import <Sc21/SCView.h>

@interface Sc21Palette : IBPalette
{
  IBOutlet NSImageView * scviewitem;
  IBOutlet NSTextField * scviewtextfielditem;
  IBOutlet NSImageView * sccontrolleritem;
  IBOutlet NSImageView * scscenegraphitem;
  IBOutlet NSImageView * scexaminerhandleritem;
  IBOutlet NSImageView * sccoinhandleritem;

  SCView * scview;
  SCController * sccontroller;
  SCSceneGraph * scscenegraph;
  SCExaminerHandler * scexaminerhandler;
  SCCoinHandler * sccoinhandler;
}
@end

// -------- IBObjectProtocol ---------

@interface SCOpenGLView (Sc21PaletteInspector)
- (NSString *)inspectorClassName;
@end

@interface SCView (Sc21PaletteInspector)
- (NSString *)inspectorClassName;
@end

@interface SCController (Sc21PaletteInspector)
- (NSString *)inspectorClassName;
- (NSString *)classInspectorClassName;
@end

@interface SCExaminerHandler (Sc21PaletteInspector)
- (NSString *)inspectorClassName;
- (NSString *)classInspectorClassName;
@end

@interface SCCoinHandler (Sc21PaletteInspector)
// - (NSString *)inspectorClassName;
- (NSString *)classInspectorClassName;
@end

@interface SCSceneGraph (Sc21PaletteInspector)
- (NSString *)inspectorClassName;
- (NSString *)classInspectorClassName;
@end
