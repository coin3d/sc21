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
 

// --------------------- actions -----------------------------

/*" Repositions the camera so that we can se the whole scene. "*/

- (IBAction) viewAll:(id)sender
{
  [camera viewAll];
}

/*" Toggles between perspective and orthographic camera. "*/

- (IBAction) toggleCameraType:(id)sender
{
  SoType persp = SoPerspectiveCamera::getClassTypeId();
  SoType ortho = SoOrthographicCamera::getClassTypeId();
  [camera convertToType: ([camera isPerspective] ? ortho : persp)];
}

/*" Switches the headlight on and off. "*/

- (IBAction) toggleHeadlight:(id)sender
{
  [self setHeadlightIsOn:([self headlightIsOn] ? NO : YES)];
}



// ----------------- initialization and cleanup ----------------------

/*" Initializes a newly allocated SCExaminerController.

    This method is the designated initializer for the SCController
    class. Returns !{self}.
 "*/

- (id) init
{
  if (self = [super init]) {
    camera = [[SCCamera alloc] init];
    [camera setController:self];
    autoclipstrategy = VARIABLE_NEAR_PLANE;
    autoclipvalue = 0.6;
    SbViewVolume volume;
    mouselog = [[NSMutableArray alloc] init];
    spinprojector = new SbSphereSheetProjector(SbSphere(SbVec3f(0,0,0),0.8f));
    volume.ortho(-1, 1, -1, 1, -1, 1);
    spinprojector->setViewVolume(volume);
    spinrotation = new SbRotation;
    spinrotation->setValue(SbVec3f(0, 0, -1), 0);
    iswaitingforseek = NO;
  }
  return self;
}


/*" Initializes a newly allocated SCExaminerController instance from the 
    data in decoder. Returns !{self} "*/

- (id) initWithCoder:(NSCoder *) coder
{
  // FIXME: Move shared code to commonInit: kyrah 20030621
  if (self = [super initWithCoder:coder]) {
    camera = [[SCCamera alloc] init];
    [camera setController:self];
    autoclipstrategy = VARIABLE_NEAR_PLANE;
    autoclipvalue = 0.6;
    SbViewVolume volume;
    mouselog = [[NSMutableArray alloc] init];
    spinprojector = new SbSphereSheetProjector(SbSphere(SbVec3f(0,0,0),0.8f));
    volume.ortho(-1, 1, -1, 1, -1, 1);
    spinprojector->setViewVolume(volume);
    spinrotation = new SbRotation;
    spinrotation->setValue(SbVec3f(0, 0, -1), 0);
    iswaitingforseek = NO;
  }
  return self;
}

/*" Calls SCController #awakeFromNib and adds context menu
    entries for the functionality added by SCExaminerController.
    If you override this method, you must send a !{[super init]}
    message to ensure proper setup of the Coin subsystem.
    
    Called after the object has been loaded from an Interface 
    Builder archive or nib file. 
"*/

- (void) awakeFromNib
{
  [super awakeFromNib];

  [view addMenuEntry:@"view all" target:self action:@selector(viewAll:)];
  [view addMenuEntry:@"toggle camera type" target:self action:@selector(toggleCameraType:)];
  [view addMenuEntry:@"toggle headlight" target:self action:@selector(toggleHeadlight:)];
     }

/* Clean up after ourselves. */

- (void) dealloc
{
  [mouselog release];
  [camera release];
  delete spinprojector;
  delete spinrotation;
  [super dealloc];
}

// ------------------- rendering and scene management ---------------------

/*" Updates the current camera's clipping planes before
    rendering the scene.
 "*/
 
- (void) render
{
  [camera updateClippingPlanes:userscenegraph];
  [super render];
}
 
 /*" Sets the scene graph that shall be rendered. The reference count of
    sg will be increased by 1 before use, so you there is no need to 
    !{ref()} the node before passing it to this method.
    A headlight is added before the scenegraph.    
    If sg does not contain a camera, one will be added automatically.
 "*/
 
- (void) setSceneGraph:(SoSeparator *)sg
{
  SoSeparator * root;
  SoCamera * scenecamera = NULL;

  // Check if somebody passes the scenegraph that is already set.
  if (root != NULL && root == scenegraph) {
    NSLog(@"setSceneGraph called with the same root as already set");
    return;
  }

  userscenegraph = sg;     // store user-supplied SG

  headlight = new SoDirectionalLight;
  root = new SoSeparator;
  // FIXME: only add headlight if needed? kyrah 20030621
  root->addChild(headlight);       
  root->addChild(userscenegraph);
  
  // Search for camera in user-supplied scenegraph
  SbBool oldsearch = SoBaseKit::isSearchingChildren();
  SoBaseKit::setSearchingChildren(TRUE);
  SoSearchAction sa;
  sa.reset();
  sa.setType(SoCamera::getClassTypeId());
  sa.apply(userscenegraph);
  SoBaseKit::setSearchingChildren(oldsearch);
  if (sa.getPath() != NULL) {
    SoFullPath * fullpath = (SoFullPath *) sa.getPath();
    scenecamera = (SoCamera *)fullpath->getTail();
  }
  NSLog(@"Camera %sfound in scene", scenecamera ? "" : "not ");

  // Make our camera if there was none.
  if (!scenecamera) {
    scenecamera = new SoPerspectiveCamera;
    [camera setSoCamera:scenecamera];
    [camera setControllerHasCreatedCamera:YES];
    root->insertChild(scenecamera, 1);
  } else {
    [camera setSoCamera:scenecamera];
    [camera setControllerHasCreatedCamera:NO];
  }

  [super setSceneGraph:root];
  
  if ([camera controllerHasCreatedCamera]) [self viewAll:nil];

}


/*" Sets the SoCamera used for viewing the scene to cam.
    It is first checked if the scenegraph contains a camera created by
    the controller, and if yes, this camera is deleted.

    Note that cam is expected to be part of the scenegraph already;
    it is not inserted into it.
"*/

- (void) setCamera:(SoCamera *) cam
{
  [camera setSoCamera:cam];
}

/*" Returns the current SoCamera used for viewing. "*/

- (SoCamera *) camera
{
  return [camera soCamera];
}


// ----------------- Automatic headlight configuration -----------------

/*" Returns YES if the headlight is on, and NO if it is off. "*/

- (BOOL) headlightIsOn
{
  return (headlight->on.getValue() == TRUE) ? YES : NO;
}


/*" Turns the headlight on or off. "*/

- (void) setHeadlightIsOn:(BOOL) yn
{
  headlight-> on = yn ? TRUE : FALSE;
}

/*" Returns the headlight of the current scene graph. "*/

- (SoDirectionalLight *) headlight
{
  return headlight;
}

// -------------------- Event handling -----------------------

/*" Handles event as viewer event, i.e. does not send it to the scene
    graph but interprets it as input for controlling the viewer. 


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

- (void) handleEventAsViewerEvent:(NSEvent *) event
{
  SEL action;
  NSEventType type = [event type];
  unsigned int flags = [event modifierFlags];
  NSPoint p;
  NSValue * v;
  float delta;

  switch (type) {
    
    case NSLeftMouseDown:

      // show pop-up menu on ctrl-click
      if ([event modifierFlags] & NSControlKeyMask) {
        [NSMenu popUpContextMenu:[view menu] withEvent:event forView:view];
        action = @selector(ignore:);
        break;
      }

      p = [view convertPoint:[event locationInWindow] fromView:nil];
      v = [NSValue valueWithPoint:p];
      if (iswaitingforseek) action = @selector(performSeek:);
      else if (flags & NSAlternateKeyMask) action = @selector(startPanning:);
      else action = @selector(startDragging:);
      break;
      
    case NSLeftMouseDragged:
      p = [view convertPoint:[event locationInWindow] fromView:nil];
      v = [NSValue valueWithPoint:p];
      if (flags & NSAlternateKeyMask) action = @selector(performPanning:);
      else action = @selector(performDragging:); 
      break;

    case NSOtherMouseDown:
      p = [view convertPoint:[event locationInWindow] fromView:nil];
      v = [NSValue valueWithPoint:p];
      action = @selector(startPanning:);
      break;
      
    case NSOtherMouseDragged:
      p = [view convertPoint:[event locationInWindow] fromView:nil];
      v = [NSValue valueWithPoint:p];
      action = @selector(performPanning:);
      break;

    case NSScrollWheel:
      delta = [event deltaY];
      v = [NSValue value:&delta withObjCType:@encode(float)];
      action = @selector(performZoom:);
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
            break;
          case NSDownArrowFunctionKey:
            v = [NSValue valueWithPoint:NSMakePoint(0.0, -0.01)];
            action = @selector(performMove:);
            break;
          case NSLeftArrowFunctionKey:
            v = [NSValue valueWithPoint:NSMakePoint(-0.01, 0.0)];
            action = @selector(performMove:);
            break;
          case NSRightArrowFunctionKey:
            v = [NSValue valueWithPoint:NSMakePoint(0.01, 0.0)];
            action = @selector(performMove:);
            break;
          case 's':
            NSLog(@"Waiting to seek...");
            iswaitingforseek = YES;
            action = @selector(ignore:);
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
}

// --------------- Interaction with the viewer -------------------


/*" Prepares for dragging operation. "*/

- (void) startDragging:(NSValue *) v
{
  // Clear log and project to the last position we stored.
  [mouselog removeAllObjects];
  spinprojector->project(SbVec2f(lastmousepos.x, lastmousepos.y));
  [mouselog insertObject:v atIndex:0];  
}


/*" Prepares for panning operation. "*/

- (void) startPanning:(NSValue *) v
{
  SbViewVolume vv;
  [mouselog removeAllObjects];
  [mouselog insertObject:v atIndex:0];
}

/*" Performs dragging operation. "*/

- (void) performDragging:(NSValue *) v
{
  [mouselog insertObject:v atIndex:0];
  [self _spin];
}

/*" Performs panning operation. "*/

- (void) performPanning:(NSValue *) v
{
  [mouselog insertObject:v atIndex:0];
  [self _pan];
}

/*" Zooms into the scene by sending the #zoom: message to SCCamera. "*/

- (void) performZoom:(NSValue *) v
{
  float f;
  [v getValue:&f];
  [camera zoom:f];
}

/*" Currently unimplemented. "*/
- (void) performSeek:(NSValue *) v
{
  NSLog(@"Seeking.");
  iswaitingforseek = NO;
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
  SoCamera * cam = [camera soCamera];
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


// ------------------------ Autoclipping -------------------------------------

/*" Set the autoclipping strategy. Possible values for strategy are:

      !{CONSTANT_NEAR_PLANE 
      VARIABLE_NEAR_PLANE}

    The default strategy is VARIABLE_NEAR_PLANE.
 "*/
- (void) setAutoClippingStrategy:(AutoClipStrategy)strategy value:(float)v
{

  // FIXME: Make it possible to turn autoclipping off. kyrah 20030621.
  // NSLog(@"setting autoclip strategy");
  autoclipstrategy = strategy;
  autoclipvalue = v;
  [self render];
}


/*" Determines the best value for the near clipping plane. Negative and very 
    small near clipping plane distances are disallowed.
  "*/
- (float) bestValueForNearPlane:(float)near farPlane:(float) far
{
  // FIXME: Send notification when doing plane calculation, instead of
  // using strategy. kyrah 20030621.
  float nearlimit, r;
  int usebits;
  GLint _depthbits[1];

  if (![camera isPerspective]) return near;
   
  switch (autoclipstrategy) {
    case CONSTANT_NEAR_PLANE:
      nearlimit = autoclipvalue;
      break;
    case VARIABLE_NEAR_PLANE:
      glGetIntegerv(GL_DEPTH_BITS, _depthbits);
      usebits = (int) (float(_depthbits[0]) * (1.0f - autoclipvalue));
      r = (float) pow(2.0, (double) usebits);
      nearlimit = far / r;
      break;
    default:
      NSLog(@"Unknown autoclip strategy: %d", autoclipstrategy);
      break;
  }
  
  // If we end up with a bogus value, use an empirically determined
  // magic value that's supposed to work will (taken from SoQtViewer.cpp).
  if (nearlimit >= far) {nearlimit = far / 5000.0f;}

  if (near < nearlimit) return nearlimit;
  else return near;
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
  SoCamera * cam = [camera soCamera];

  if ([mouselog count] < 2) return;
  if (cam == NULL) return;

  p = [[mouselog objectAtIndex:0] pointValue];
  q = [[mouselog objectAtIndex:1] pointValue];
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

  if ([mouselog count] < 2) return;
  assert (spinprojector);

  p = [[mouselog objectAtIndex:0] pointValue];
  q = [[mouselog objectAtIndex:1] pointValue];
  qn = [view normalizePoint:q];
  pn = [view normalizePoint:p];

  spinprojector->project(SbVec2f(qn.x, qn.y));
  spinprojector->projectAndGetRotation(SbVec2f(pn.x, pn.y), r);
  r.invert();

  [camera reorient:r];
}

@end
