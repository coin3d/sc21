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
 
#import <Foundation/Foundation.h>

#import <Sc21/SCDefines.h>

#import <Inventor/SbLinear.h>
#import <Inventor/SbRotation.h>
#import <Inventor/nodes/SoCamera.h>
#import <Inventor/nodes/SoSeparator.h>

@class SCSceneGraph;
@class SCCameraP;

/*" Possible camera types in the scene graph.
    !{SCCameraPerspective} describes an !{SoPerspectiveCamera},
    and !{SCCameraOrthographic} means an !{SoOrthographicCamera}.
 "*/

typedef enum _SCCameraType {
  SCCameraUnknown       = -1,
  SCCameraNone          =  0,
  SCCameraPerspective   =  1,
  SCCameraOrthographic  =  2
} SCCameraType;

@interface SCCamera : NSObject
{
 @protected
  SCCameraP * _sc_camera;
 @private
  id delegate;
}

/*" Initializing an SCCamera "*/
- (id)init;

/*" Positioning the camera "*/
- (void)reorient:(SbRotation)rot;
- (void)translate:(SbVec3f)v;
- (void)zoom:(float)delta;
- (void)viewAll:(SCSceneGraph *)scenegraph;

/*" Adjusting the clipping planes "*/
- (void)updateClippingPlanes:(SCSceneGraph *)scenegraph;
- (BOOL)updatesClippingPlanes;
- (void)setUpdatesClippingPlanes:(BOOL)yn;

/*" Accessors "*/ 
- (SCCameraType)type;
- (void)setSoCamera:(SoCamera *)camera;
- (SoCamera *)soCamera;

  /*" Delegate handling. "*/
- (void)setDelegate:(id)newdelegate;
- (id)delegate;
@end

//   SbVec2f myfunc(void * data, const SbVec2f & nearfar);
@interface NSObject (SCCameraDelegate)
- (void)adjustNearClippingPlane:(float *)near 
  farClippingPlane:(float *)far;
@end

/*" Posted whenever the camera has been repositioned so that
    the whole scene can be seen.
"*/
SC21_EXTERN NSString * SCViewAllNotification;

/*" Posted whenever the camera type has been changed.
"*/
SC21_EXTERN NSString * SCCameraTypeChangedNotification;
