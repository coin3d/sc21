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
#import "SCController.h"

class SbSphereSheetProjector;
class SbRotation;
class SoDirectionalLight;

@interface SCExaminerController : SCController
{
  NSPoint _lastmousepos;
  NSMutableArray * _mouselog;
  SoDirectionalLight * _headlight;  
  SbSphereSheetProjector * _spinprojector;
  SbRotation * _spinrotation;
  SoGroup * _userscenegraph;  // _scenegraph includes camera/headlight
  BOOL _iswaitingforseek;  // currently unused
}

/*" Initializing and encoding/decoding an SCExaminerController "*/
- (id)init;
- (void)commonInit;

/*" Coin rendering and related functionality "*/
- (void)render;
- (void)setCameraType:(SCCameraType)type;
- (void)viewAll;

/*" Automatic headlight configuration "*/
- (SoDirectionalLight *)headlight;
- (BOOL)headlightIsOn;
- (void)setHeadlightIsOn:(BOOL)yn;

/*" Event handling "*/
- (BOOL)handleEventAsViewerEvent:(NSEvent *)event;

/*" Interaction with the viewer. "*/
- (void)startDraggingWithPoint:(NSPoint)point;
- (void)startPanningWithPoint:(NSPoint)point;
- (void)startZoomingWithPoint:(NSPoint)point;
- (void)dragWithPoint:(NSPoint)point;
- (void)panWithPoint:(NSPoint)point;
- (void)zoomWithDelta:(float)delta;
- (void)zoomWithPoint:(NSPoint)point;
- (void)ignore:(NSValue *)v;

@end


/*" Posted whenever the camera has been repositioned so that
    the whole scene can be seen.
 "*/
extern NSString * SCViewAllNotification;

/*" Posted whenever the camera type has been changed, i.e.
    when the camera has been from orthographic to perspective
    or vice versa.
 "*/
extern NSString * SCCameraTypeChangedNotification;

/*" Posted whenever the headlight has been turned on or off. "*/
extern NSString * SCHeadlightChangedNotification;

