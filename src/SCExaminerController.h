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
#import <Sc21/SCController.h>

class SbSphereSheetProjector;
class SbRotation;
class SoDirectionalLight;

@interface SCExaminerController : SCController
{
  NSPoint _lastmousepos;
  NSMutableArray * _mouselog;
  SbSphereSheetProjector * _spinprojector;
  SbRotation * _spinrotation;
  BOOL _iswaitingforseek;  // currently unused
}

/*" Initializing and encoding/decoding an SCExaminerController "*/
- (id)init;
- (void)_SC_commonInit;

/*" Coin rendering and related functionality "*/
- (void)render;
- (void)setCameraType:(SCCameraType)type;

#if 0
/*" Interaction with the viewer. "*/
- (void)startDraggingWithPoint:(NSPoint)point;
- (void)startPanningWithPoint:(NSPoint)point;
- (void)startZoomingWithPoint:(NSPoint)point;
- (void)dragWithPoint:(NSPoint)point;
- (void)panWithPoint:(NSPoint)point;
- (void)zoomWithDelta:(float)delta;
- (void)zoomWithPoint:(NSPoint)point;
- (void)ignore:(NSValue *)v;
#endif

@end


