#import "SCExaminerController.h"
#import "SCView.h"

#import <Inventor/SoSceneManager.h>
#import <Inventor/SbPlane.h>
#import <Inventor/SbViewVolume.h>
#import <Inventor/actions/SoGetBoundingBoxAction.h>
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
  - (void) _spin;
  - (void) _pan;
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

    Pressing the cursor keys on the keyboard will move the camera in a
    similar way.

    Clicking into the scene with the right mouse button brings up a
    context menu. Holding down th CTRL key and clicking with the left
    mouse button is interpreted the same way.

    
    For general information, see also the SCController documentation.
    
    Note that for displaying the rendered scene, you need an SCView.
    Connect SCExaminerController's !{view} outlet to a valid SCView instance
    to use SCExaminerController.
 "*/
 


// ----------------- initialization and cleanup ----------------------

/*" Initializes a newly allocated SCExaminerController.

    Calls #commonInit, which contains common initialization
    code needed both in #init and #initWithCoder.

    This method is the designated initializer for the SCController
    class. Returns !{self}.
 "*/

- (id) init
{
  if (self = [super init]) {
    // Note that commonInit will be called by our superclass'
    // initWithCoder method, so do not call it here.
    ; 
  }
  return self;
}


/*" Initializes a newly allocated SCExaminerController instance from the 
    data in decoder. Returns !{self}

    Calls #commonInit, which contains common initialization
    code needed both in #init and #initWithCoder.
"*/

- (id) initWithCoder:(NSCoder *) coder
{
  if (self = [super initWithCoder:coder]) {
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

- (void) commonInit
{
  [super commonInit];
  NSLog(@"SCExaminerController commonInit");
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

- (void) dealloc
{
  [_mouselog release];
  delete _spinprojector;
  delete _spinrotation;
  [super dealloc];
}

// ------------------- rendering and scene management ---------------------

/*" Updates the current camera's clipping planes before
    rendering the scene.
 "*/
 
- (void) render
{
  [_camera updateClippingPlanes:_userscenegraph];
  [super render];
}


 /*" Sets the scene graph that shall be rendered. You do not need to
     !{ref()} the node before passing it to this method.  If sg is
     NULL, an empty scenegraph consisting of a single SoSeparator node will
     be created and set.

     A headlight is added before the scenegraph. If a light is present in the
     scenegraph, this headlight will be turned off by default; you can enable
     it by calling #setHeadlightIsOn:

     A camera is added before the scenegraph, if it does not contain one.
 "*/

- (void) setSceneGraph:(SoGroup *)sg
{
  // Check if somebody passes the scenegraph that is already set.
  if (sg != NULL && sg == _userscenegraph) {
    NSLog(@"setSceneGraph called with the same root as already set");
    return;
  }

  // Do not insert camera and headlight if scenegraph is NULL.
  if (sg == NULL) [super setSceneGraph:NULL];

  _userscenegraph = sg;     // store user-supplied SG
  
  SoSeparator * root = new SoSeparator;
  _headlight = new SoDirectionalLight;
  root->ref();
  root->addChild(_headlight);
  root->addChild(_userscenegraph);
  
  // If there was a light in the user scenegraph, turn off headlight
  // by default. We are adding one anyway, since you might want to
  // be able to view the whole model (regardless if lights are present
  // or not.
  [self setHeadlightIsOn: ([self findLightInSceneGraph:_userscenegraph]) ? NO : YES];

  // Look for camera in scengraph. Make our own if we find none
  SoCamera * scenecamera = [self findCameraInSceneGraph:_userscenegraph];
  if (!scenecamera) {
    scenecamera = new SoPerspectiveCamera;
    [_camera setSoCamera:scenecamera];
    [_camera setControllerHasCreatedCamera:YES];
    root->insertChild(scenecamera, 1);
  } else {
    [_camera setSoCamera:scenecamera];
    [_camera setControllerHasCreatedCamera:NO];
  }

  if (_scenemanager) _scenemanager->setSceneGraph(root);
  root->unref(); // ref'ed by scenemanager
  _scenegraph = root;

  if (_scenemanager) && [_camera controllerHasCreatedCamera]) [self viewAll];
  [view setNeedsDisplay:YES];
  
  [[NSNotificationCenter defaultCenter]
    postNotificationName:SCSceneGraphChangedNotification object:self];
}

/*" Sets the type of the camera we are using for viewing the scene.
    Currently supported types are %SCCameraPerspective and
    %SCCameraOrthographic (see SCCamera.h).
 "*/

- (void) setCameraType:(SCCameraType) type
{
  [_camera convertToType:type];
}


/*" Repositions the camera so that we can se the whole scene. "*/

- (void) viewAll
{
  [_camera viewAll]; // SCViewAllNotification sent by _camera
}

// ----------------- Automatic headlight configuration -----------------

/*" Returns YES if the headlight is on, and NO if it is off. "*/

- (BOOL) headlightIsOn
{
  if (_headlight == NULL) return FALSE;
  return (_headlight->on.getValue() == TRUE) ? YES : NO;
}


/*" Turns the headlight on or off. "*/

- (void) setHeadlightIsOn:(BOOL) yn
{
  if (_headlight == NULL) return;
  _headlight-> on = yn ? TRUE : FALSE;

  [[NSNotificationCenter defaultCenter]
    postNotificationName:SCHeadlightChangedNotification object:self];
}

/*" Returns the headlight of the current scene graph. "*/

- (SoDirectionalLight *) headlight
{
  return _headlight;
}

// -------------------- Event handling -----------------------

/*" Handles event as viewer event, i.e. does not send it to the scene
    graph but interprets it as input for controlling the viewer. 

    Returns YES if the event has been handled, NO otherwise.

    Clicking into the scene with the left mouse button and dragging
    rotates the camera around the scene.

    Clicking into the scene with the middle mouse button and dragging
    "pans" the camera, i.e. moves it in the plane that is parallel to
    the screen. Holding down the ALT key and clicking with the left
    mouse button is interpreted the same way.

    Pressing the cursor keys on the keyboard will move the camera in a
    similar way.

    Clicking into the scene with the right mouse button brings up a
    context menu. Holding down th CTRL key and clicking with the left
    mouse button is interpreted the same way.

"*/

- (BOOL) handleEventAsViewerEvent:(NSEvent *) event
{
  BOOL handled = NO;
  SEL action;
  NSEventType type = [event type];
  unsigned int flags = [event modifierFlags];
  NSPoint p;
  NSValue * v;
  float delta;

  switch (type) {
    
    case NSLeftMouseDown:

      // Note that we will never see ctrl-click -- this is translated
      // into a menuForEvent: message and not forwarded here unless
      // the app developer overrides menuForEvent: In that latter case,
      // they probably specifically do _not_ want to get the menu on
      // ctrl-click, so do not explicitly show the menu here!

      p = [view convertPoint:[event locationInWindow] fromView:nil];
      v = [NSValue valueWithPoint:p];
      if (_iswaitingforseek) action = @selector(performSeek:);
      else if (flags & NSAlternateKeyMask) action = @selector(startPanning:);
      else action = @selector(startDragging:);
      handled = YES;
      break;
      
    case NSLeftMouseDragged:
      p = [view convertPoint:[event locationInWindow] fromView:nil];
      v = [NSValue valueWithPoint:p];
      if (flags & NSAlternateKeyMask) action = @selector(performPanning:);
      else action = @selector(performDragging:);
      handled = YES;
      break;

    case NSRightMouseDown:
      [NSMenu popUpContextMenu:[view menu] withEvent:event forView:view];
      action = @selector(ignore:);
      handled = YES;
      break;

    case NSOtherMouseDown:
      p = [view convertPoint:[event locationInWindow] fromView:nil];
      v = [NSValue valueWithPoint:p];
      action = @selector(startPanning:);
      handled = YES;
      break;
      
    case NSOtherMouseDragged:
      p = [view convertPoint:[event locationInWindow] fromView:nil];
      v = [NSValue valueWithPoint:p];
      action = @selector(performPanning:);
      handled = YES;
      break;

    case NSScrollWheel:
      delta = [event deltaY];
      v = [NSValue value:&delta withObjCType:@encode(float)];
      action = @selector(performZoom:);
      handled = YES;
      break;

    case NSKeyDown:
      unsigned int i;
      NSString * characters;
      characters = [event charactersIgnoringModifiers];
      for (i = 0; i < [characters length]; i++) {
        unichar c = [characters characterAtIndex:i];
        switch (c) {
          case NSUpArrowFunctionKey:
            v = [NSValue valueWithPoint:NSMakePoint(0.0, 0.01)];
            action = @selector(performMove:);
            handled = YES;
            break;
          case NSDownArrowFunctionKey:
            v = [NSValue valueWithPoint:NSMakePoint(0.0, -0.01)];
            action = @selector(performMove:);
            handled = YES;
            break;
          case NSLeftArrowFunctionKey:
            v = [NSValue valueWithPoint:NSMakePoint(-0.01, 0.0)];
            action = @selector(performMove:);
            handled = YES;
            break;
          case NSRightArrowFunctionKey:
            v = [NSValue valueWithPoint:NSMakePoint(0.01, 0.0)];
            action = @selector(performMove:);
            handled = YES;
            break;
          case 's':
            NSLog(@"Waiting to seek...");
            _iswaitingforseek = YES;
            action = @selector(ignore:);
            handled = YES;
            break;
          default:
            action = @selector(ignore:);
            break;
        }
      }
      break;
      
    default:
      action = @selector(ignore:);
      break;
  }
  [self performSelector:action withObject:v];
  return handled;
}

// --------------- Interaction with the viewer -------------------


/*" Prepares for dragging operation. "*/

- (void) startDragging:(NSValue *) v
{
  // Clear log and project to the last position we stored.
  [_mouselog removeAllObjects];
  _spinprojector->project(SbVec2f(_lastmousepos.x, _lastmousepos.y));
  [_mouselog insertObject:v atIndex:0];  
}


/*" Prepares for panning operation. "*/

- (void) startPanning:(NSValue *) v
{
  SbViewVolume vv;
  [_mouselog removeAllObjects];
  [_mouselog insertObject:v atIndex:0];
}

/*" Performs dragging operation. "*/

- (void) performDragging:(NSValue *) v
{
  [_mouselog insertObject:v atIndex:0];
  [self _spin];
}

/*" Performs panning operation. "*/

- (void) performPanning:(NSValue *) v
{
  [_mouselog insertObject:v atIndex:0];
  [self _pan];
}

/*" Zooms into the scene by sending the #zoom: message to SCCamera. "*/

- (void) performZoom:(NSValue *) v
{
  float f;
  [v getValue:&f];
  [_camera zoom:f];
}

/*" Currently unimplemented. "*/
- (void) performSeek:(NSValue *) v
{
  NSLog(@"Seeking.");
  _iswaitingforseek = NO;
  // FIXME: Implement. kyrah 20030621.
}

/*" Move the camera in the plane that is parallel to the screen. "*/

- (void) performMove:(NSValue *) v
{
  // FIXME: This is the same as pan -> Reuse code!
  // kyrah 20030515
  
  NSPoint p = [v pointValue];
  SbLine line;
  SbVec3f curplanepoint, prevplanepoint;
  SoCamera * cam = [_camera soCamera];
  if (cam == NULL) return;
  
  SbViewVolume vv = cam->getViewVolume([view aspectRatio]);
  SbPlane panplane = vv.getPlane(cam->focalDistance.getValue());
  vv.projectPointToLine(SbVec2f(p.x, p.y) + SbVec2f(0.5, 0.5f), line);
  panplane.intersect(line, curplanepoint);
  vv.projectPointToLine(SbVec2f(0.5f, 0.5f), line);
  panplane.intersect(line, prevplanepoint);
  cam->position = cam->position.getValue() - (curplanepoint - prevplanepoint);
}

/*" Does nothing. Used as default action for unhandled events. "*/

- (void) ignore:(NSValue *) v
{
  // Do nothing.
}



// ---------------- NSCoder conformance -------------------------------

/*" Encodes the SCController using encoder coder "*/

- (void) encodeWithCoder:(NSCoder *) coder
{
  [super encodeWithCoder:coder];
  // FIXME: Encode members. kyrah 20030618
}


// ------------------------- InternalAPI --------------------------------

- (void) _pan
{
  NSPoint p, q, pn, qn;
  SbLine line;
  SbVec3f curplanepoint, prevplanepoint;
  SoCamera * cam = [_camera soCamera];

  if ([_mouselog count] < 2) return;
  if (cam == NULL) return;

  p = [[_mouselog objectAtIndex:0] pointValue];
  q = [[_mouselog objectAtIndex:1] pointValue];
  qn = [view normalizePoint:q];
  pn = [view normalizePoint:p];

  // Find projection points for the last and current mouse coordinates.
  SbViewVolume vv = cam->getViewVolume([view aspectRatio]);
  SbPlane panplane = vv.getPlane(cam->focalDistance.getValue());
  vv.projectPointToLine(SbVec2f(pn.x, pn.y), line);
  panplane.intersect(line, curplanepoint);
  vv.projectPointToLine(SbVec2f(qn.x, qn.y), line);
  panplane.intersect(line, prevplanepoint);

  // Reposition camera according to the vector difference between the
  // projected points.
  cam->position = cam->position.getValue() - (curplanepoint - prevplanepoint);

}

- (void) _spin
{
  NSPoint p, q, qn, pn;
  SbRotation r;

  if ([_mouselog count] < 2) return;
  assert (_spinprojector);

  p = [[_mouselog objectAtIndex:0] pointValue];
  q = [[_mouselog objectAtIndex:1] pointValue];
  qn = [view normalizePoint:q];
  pn = [view normalizePoint:p];

  _spinprojector->project(SbVec2f(qn.x, qn.y));
  _spinprojector->projectAndGetRotation(SbVec2f(pn.x, pn.y), r);
  r.invert();

  [_camera reorient:r];
}

@end
