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
 

#import <Foundation/Foundation.h>

@class SCController;

class SbRotation;
class SoCamera;
class SoGroup;
class SoGetBoundingBoxAction;

/*" Possible camera types in the scene graph.
    !{SCCameraPerspective} describes an !{SoPerspectiveCamera},
    and !{SCCameraOrthographic} means an !{SoOrthographicCamera}.
    All other camera types are currently !{SCCameraUnknown}.
 "*/

typedef enum _SCCameraType {
  SCCameraUnknown 	= -1,
  SCCameraPerspective   =  0,
  SCCameraOrthographic  =  1
} SCCameraType;

@interface SCCamera : NSObject {
  SCController * _controller;
  SoCamera * _camera;
  SoGetBoundingBoxAction * _autoclipboxaction;
  BOOL _controllerhascreatedcamera;
}

/*" Initializing an SCCamera "*/
- (id)initWithSoCamera:(SoCamera *)camera controller:(SCController *)controller;

/*" Switching between orthographic and perspective mode "*/
- (SCCameraType)type;
- (BOOL)convertToType:(SCCameraType)type;

/*" Positioning the camera "*/
- (void)zoom:(float)delta;
- (void)reorient:(SbRotation)rot;
- (void)viewAll;
- (void)updateClippingPlanes:(SoGroup *)scenegraph;

/*" Accessors "*/ 
- (void)setController:(SCController *)controller;
- (SCController *)controller;
- (void)setSoCamera:(SoCamera *)c deleteOldCamera:(BOOL)deletecamera;
- (SoCamera *)soCamera;
- (void)setControllerHasCreatedCamera:(BOOL)yn;
- (BOOL)controllerHasCreatedCamera;
@end
