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
 
#import <SC21/SCExaminerController.h>
#import <SC21/SCCursors.h>

#import <Inventor/SoSceneManager.h>
#import <Inventor/SbMatrix.h>
#import <Inventor/SbPlane.h>
#import <Inventor/SbViewVolume.h>
#import <Inventor/SoPickedPoint.h>
#import <Inventor/actions/SoGetBoundingBoxAction.h>
#import <Inventor/actions/SoRayPickAction.h>
#import <Inventor/actions/SoGLRenderAction.h>
#import <Inventor/actions/SoSearchAction.h>
#import <Inventor/actions/SoGetMatrixAction.h>
#import <Inventor/nodekits/SoBaseKit.h>
#import <Inventor/nodes/SoDirectionalLight.h>
#import <Inventor/nodes/SoOrthographicCamera.h>
#import <Inventor/nodes/SoPerspectiveCamera.h>
#import <Inventor/nodes/SoSeparator.h>
#import <Inventor/projectors/SbSphereSheetProjector.h>


// ---------------------- Notifications ----------------------------

NSString * SCViewAllNotification = @"SCViewAllNotification";
NSString * SCCameraTypeChangedNotification = @"SCCameraTypeChangedNotification";
NSString * SCHeadlightChangedNotification =@"SCHeadlightChangedNotification";


@interface SCExaminerController (InternalAPI)
- (void)_setInternalSceneGraph:(SoGroup *)root;
- (SoLight *)_findLightInSceneGraph:(SoGroup *)root;    // impl in super
- (SoCamera *)_findCameraInSceneGraph:(SoGroup *)root;  // impl in super
- (NSPoint)_normalizePoint:(NSPoint)point;              // impl in super
@end

@implementation SCExaminerController

/*" The SCExaminerController class adds functionality to "examine" the scene
    to the SCController.

    Supported interactions are:

    Clicking into the scene with the left mouse button and dragging
    rotates the camera around the scene.

    Clicking into the scene with the middle mouse button and dragging
    "pans" the camera, i.e. moves it in the plane that is parallel to
    the screen. Holding down the ALT key and clicking with the left
    mouse button is interpreted the same way.

    Clicking into the scene with the right mouse button brings up a
    context menu. Holding down the CTRL key and clicking with the left
    mouse button is interpreted the same way.

    For general information, see also the SCController documentation.
 "*/
 


// ----------------- initialization and cleanup ----------------------

/*" Initializes a newly allocated SCExaminerController.

    Calls #commonInit, which contains common initialization
    code needed both in #init and #initWithCoder.

    This method is the designated initializer for the SCController
    class. Returns !{self}.
 "*/

- (id)init
{
  if (self = [super init]) {
    // Note that commonInit will be called by our superclass'
    // initWithCoder method, so do not call it here.
    ; 
  }
  return self;
}


/*" Shared initialization code that is called both from #init:
    and #initWithCoder: If you override this method, you must
    call [super commonInit] as the first call in your
    implementation to make sure everything is set up properly.
 "*/

- (void)commonInit
{
  [super commonInit];
  _headlight = NULL;
  SbViewVolume volume;
  _mouselog = [[NSMutableArray alloc] init];
  _spinprojector = new SbSphereSheetProjector(SbSphere(SbVec3f(0,0,0),0.8f));
  volume.ortho(-1, 1, -1, 1, -1, 1);
  _spinprojector->setViewVolume(volume);
  _spinrotation = new SbRotation;
  _spinrotation->setValue(SbVec3f(0, 0, -1), 0);
  _iswaitingforseek = NO;  
}


/*" Clean up after ourselves. "*/

- (void)dealloc
{
  NSLog(@"SCExaminerController.dealloc");
  [_mouselog release];
  delete _spinprojector;
  delete _spinrotation;
  [super dealloc];
}

// ------------------- rendering and scene management ---------------------

/*" Updates the current camera's clipping planes before
    rendering the scene.
 "*/
 
- (void)render
{
  [_camera updateClippingPlanes:_userscenegraph];
  [super render];
}


 /* Sets the scene graph that shall be rendered. You do not need to
     !{ref()} the node before passing it to this method.  If sg is
     NULL, an empty scenegraph consisting of a single SoSeparator node will
     be created and set.

     A headlight is added before the scenegraph. If a light is present in the
     scenegraph, this headlight will be turned off by default; you can enable
     it by calling #setHeadlightIsOn:

     A camera is added before the scenegraph, if it does not contain one.
 */

- (void)setSceneGraph:(SoGroup*)root
{
  [super setSceneGraph:root];
  
  if ([_camera controllerHasCreatedCamera] && _scenemanager) {
    [self viewAll];
    _scenemanager->scheduleRedraw();  
  }  
}


/*" Sets the type of the camera we are using for viewing the scene.
    Currently supported types are %SCCameraPerspective and
    %SCCameraOrthographic (see SCCamera.h).
 "*/

- (void)setCameraType:(SCCameraType)type
{
  [_camera convertToType:type];
}


/*" Repositions the camera so that we can se the whole scene. "*/

- (void)viewAll
{
  [_camera viewAll]; // SCViewAllNotification sent by _camera
}

// ----------------- Automatic headlight configuration -----------------

/*" Returns !{YES} if the headlight is on, and !{NO} if it is off. "*/

- (BOOL)headlightIsOn
{
  if (_headlight == NULL) return FALSE;
  return (_headlight->on.getValue() == TRUE) ? YES : NO;
}


/*" Turns the headlight on or off. "*/

- (void)setHeadlightIsOn:(BOOL)yn
{
  if (_headlight == NULL) return;
  _headlight-> on = yn ? TRUE : FALSE;
  
  [[NSNotificationCenter defaultCenter]
    postNotificationName:SCHeadlightChangedNotification object:self];
}

/*" Returns the headlight of the current scene graph. "*/

- (SoDirectionalLight *)headlight
{
  return _headlight;
}

// -------------------- Event handling -----------------------

/*" Handles event as viewer event, i.e. does not send it to the scene
    graph but interprets it as input for controlling the viewer. 

    Returns !{YES} if the event has been handled, !{NO} otherwise.

    Clicking into the scene with the left mouse button and dragging
    rotates the camera around the scene.

    Clicking into the scene with the middle mouse button and dragging
    "pans" the camera, i.e. moves it in the plane that is parallel to
    the screen. Holding down the ALT key and clicking with the left
    mouse button is interpreted the same way.

    Pressing the cursor keys on the keyboard will move the camera in a
    similar way.
    
    The mouse wheel zooms in and out. Dragging the mouse while holding
    down the SHIFT key also zooms in and out. 

    Clicking into the scene with the right mouse button brings up a
    context menu if the application programmer has set up menu items. 
    Holding down th CTRL key and clicking with the left
    mouse button is interpreted the same way.

"*/

- (BOOL)handleEventAsViewerEvent:(NSEvent *)event inView:(NSView *)view
{
  BOOL handled = NO;
  NSEventType type = [event type];
  unsigned int flags = [event modifierFlags];
  NSPoint p = [view convertPoint:[event locationInWindow] fromView:nil];

  switch (type) {
    case NSLeftMouseUp:
    case NSRightMouseUp:
    case NSOtherMouseUp:
      //FIXME: notification
      //      [delegate setCursor:[NSCursor rotateCursor]];
      break;

    case NSLeftMouseDown:
      // Note that we will never see ctrl-click -- this is translated
      // into a menuForEvent: message and not forwarded here unless
      // the app developer overrides menuForEvent: In that latter case,
      // they probably specifically do _not_ want to get the menu on
      // ctrl-click, so do not explicitly show the menu here!
      if (flags & NSAlternateKeyMask) [self startPanningWithPoint:p];
      else if (flags & NSShiftKeyMask) [self startZoomingWithPoint:p];
      else [self startDraggingWithPoint:p];
      handled = YES;
      break;

    case NSLeftMouseDragged:
      if (flags & NSAlternateKeyMask) [self panWithPoint:p];
      else if (flags & NSShiftKeyMask) [self zoomWithPoint:p];
      else [self dragWithPoint:p];
      handled = YES;
      break;

      // Pass through right mouse -> used for context menu by NSView
//     case NSRightMouseDown:
//       handled = NO;
//       break;

    case NSOtherMouseDown:
      [self startPanningWithPoint:p];
      handled = YES;
      break;
      
    case NSOtherMouseDragged:
      [self panWithPoint:p];
      handled = YES;
      break;

    case NSScrollWheel:
      [self zoomWithDelta:[event deltaY]];
      handled = YES;
      break;
      
    default:
      break;
  }
  return handled;
}

// --------------- Interaction with the viewer -------------------


/*" Prepares for dragging operation. Dragging is done depending on the
    user's mouse movements. The NSPoint corresponding to the initial
    mouseDown event is passed in point, and stored in an internal log
    of mouse positions used in #dragWithPoint:
"*/

- (void)startDraggingWithPoint:(NSPoint)point
{
  NSValue * v = [NSValue valueWithPoint:point];
  // Clear log and project to the last position we stored.
  [_mouselog removeAllObjects];
  _spinprojector->project(SbVec2f(_lastmousepos.x, _lastmousepos.y));
  [_mouselog insertObject:v atIndex:0];  
}

/*" Prepares for panning operation. Panninging is done depending on the
    user's mouse movements. The NSPoint corresponding to the initial
    mouseDown event is passed in point, and stored in an internal log
    of mouse positions used in #panWithPoint:
"*/

- (void)startPanningWithPoint:(NSPoint)point
{
  SbViewVolume vv;
  NSValue * v = [NSValue valueWithPoint:point];
  [_mouselog removeAllObjects];
  [_mouselog insertObject:v atIndex:0];
  //FIXME: notification
  //  [delegate setCursor:[NSCursor panCursor]];
}


/*" Prepares for zooming operation. Zooming is done depending on the
    user's mouse movements. The NSPoint corresponding to the initial
    mouseDown event is passed in point, and stored in an internal log
    of mouse positions used in #zoomWithPoint:
 "*/

- (void)startZoomingWithPoint:(NSPoint)point
{
  NSValue * v = [NSValue valueWithPoint:point];
  // Clear log and project to the last position we stored.
  [_mouselog removeAllObjects];
  [_mouselog insertObject:v atIndex:0];
  //FIXME: notification
  //  [delegate setCursor:[NSCursor zoomCursor]];
}


/*" Performs dragging operation. This method is revoked repeatedly
    while the user is dragging the mouse, with the current mouse
    position passed in point. This value is stored in an internal log
    of mouse positions, and compared with earlier values to determine
    the extent of the dragging.
 "*/

- (void)dragWithPoint:(NSPoint)point
{
  NSPoint p, q, qn, pn;
  SbRotation r;
  NSValue * v = [NSValue valueWithPoint:point];
    
  [_mouselog insertObject:v atIndex:0];

  if ([_mouselog count] < 2) return;
  assert (_spinprojector);

  p = [[_mouselog objectAtIndex:0] pointValue];
  q = [[_mouselog objectAtIndex:1] pointValue];
  qn = [self _normalizePoint:q];
  pn = [self _normalizePoint:p];

  _spinprojector->project(SbVec2f(qn.x, qn.y));
  _spinprojector->projectAndGetRotation(SbVec2f(pn.x, pn.y), r);
  r.invert();

  [_camera reorient:r];
}


/*" Performs panning operation. This method is revoked repeatedly
    while the user is dragging the mouse while holding down the ALT key
    (or dragging with the middle mouse button pressed), with the current
    mouse position passed in point. This value is stored in an internal log
    of mouse positions, and compared with earlier values to determine
    the extent of the panning.
"*/

- (void)panWithPoint:(NSPoint)point
{
  NSPoint p, q, pn, qn;
  SbLine line;
  SbVec3f curplanepoint, prevplanepoint;
  SoCamera * cam = [_camera soCamera];
  NSValue * v = [NSValue valueWithPoint:point];

  [_mouselog insertObject:v atIndex:0];
  
  if ([_mouselog count] < 2) return;
  if (cam == NULL) return;

  p = [[_mouselog objectAtIndex:0] pointValue];
  q = [[_mouselog objectAtIndex:1] pointValue];
  qn = [self _normalizePoint:q];
  pn = [self _normalizePoint:p];

  // Find projection points for the last and current mouse coordinates.
  // Don't worry about about camera's viewportMapping since it wouldn't 
  // affect the panplane.
  SbViewVolume vv = cam->getViewVolume(0.0f);
  SbPlane panplane = vv.getPlane(cam->focalDistance.getValue());
  vv.projectPointToLine(SbVec2f(pn.x, pn.y), line);
  panplane.intersect(line, curplanepoint);
  vv.projectPointToLine(SbVec2f(qn.x, qn.y), line);
  panplane.intersect(line, prevplanepoint);

  // Reposition camera according to the vector difference between the
  // projected points.
  cam->position = cam->position.getValue() - (curplanepoint - prevplanepoint);    
}

/*" Performs zoom operation. This method is revoked repeatedly
    while the user is moving the mouse wheel, with the floating
    point value corresponding to the current change passed in delta. 

    Zooming can also be done by dragging while holding down the
    shift key. In this case, #zoomWithPoint: is called instead of this
    method.
 "*/

- (void)zoomWithDelta:(float)delta
{
  [_camera zoom:delta];
}


/*" Performs zoom operation. This method is revoked repeatedly
    while the user is dragging the mouse while holding down the SHIFT
    key, with the current mouse position passed in point. This value
    is stored in an internal log of mouse positions, and compared with
    earlier values to determine whether to zoom in (mouse moved up)
    or zoom out (mouse moved down).

    Zooming can also be done by using the wheel on a wheel mouse.
    In this case, #zoomWithDelta: is called instead of this method.
"*/

- (void)zoomWithPoint:(NSPoint)point
{
  NSValue * v = [NSValue valueWithPoint:point];
  NSPoint p, q, qn, pn;
  [_mouselog insertObject:v atIndex:0];
  if ([_mouselog count] < 2) return;
  p = [[_mouselog objectAtIndex:0] pointValue];
  q = [[_mouselog objectAtIndex:1] pointValue];
  qn = [self _normalizePoint:q];
  pn = [self _normalizePoint:p];
  [_camera zoom:(pn.y - qn.y)];
}


/*" Does nothing. Used as default action for unhandled events. "*/

- (void)ignore:(NSValue *)v
{
  // Do nothing.
}



// ---------------- NSCoder conformance -------------------------------

/*" Initializes a newly allocated SCExaminerController instance from the 
    data in decoder. Returns !{self}

    Calls #commonInit, which contains common initialization
    code needed both in #init and #initWithCoder.
"*/

- (id)initWithCoder:(NSCoder *)coder
{
  NSLog(@"SCExaminerController.initWithCoder:");
  if (self = [super initWithCoder:coder]) {
    // Note that commonInit will be called by our superclass'
    // initWithCoder method, so do not call it here.
    ; 
  }
  return self;
}


/*" Encodes the SCController using encoder coder "*/

- (void)encodeWithCoder:(NSCoder *)coder
{
  NSLog(@"SCExaminerController.encodeWithCoder:");
  [super encodeWithCoder:coder];
  // FIXME: Encode members. kyrah 20030618
}


// ------------------------- InternalAPI --------------------------------


// Methods below are called by setSceneGraph

- (void)_setInternalSceneGraph:(SoGroup *)scenegraph
{
  if (_scenegraph) _scenegraph->unref();
  _userscenegraph = scenegraph;
  _scenegraph = new SoSeparator;
  _headlight = new SoDirectionalLight;
  _scenegraph->ref();
  _scenegraph->addChild(_headlight);
  _scenegraph->addChild(_userscenegraph);
}


- (void)_handleLighting
{
  if (![self _findLightInSceneGraph:_userscenegraph]) {
    [self setHeadlightIsOn:YES];
  } else {
    [self setHeadlightIsOn:NO];
  }
}

- (void)_handleCamera
{
  SoCamera * scenecamera  = [self _findCameraInSceneGraph:_scenegraph];
  if (scenecamera == NULL) {
    scenecamera = new SoPerspectiveCamera;
    [_camera setSoCamera:scenecamera deleteOldCamera:NO];
    [_camera setControllerHasCreatedCamera:YES];
    _scenegraph->insertChild(scenecamera, 1);
  } else {
    [_camera setSoCamera:scenecamera deleteOldCamera:NO];
    [_camera setControllerHasCreatedCamera:NO];
  }
}

@end
