//
//  SCCamera.m
//  SCView
//
//  Created by Karin Kosina on Tue May 13 2003.
//  Copyright (c) 2003 Systems in Motion. All rights reserved.
//

#import "SCCamera.h"
#import "SCExaminerController.h"

#import <Inventor/SbRotation.h>
#import <Inventor/SbMatrix.h>
#import <Inventor/SoType.h>
#import <Inventor/SoSceneManager.h>
#import <Inventor/actions/SoSearchAction.h>
#import <Inventor/actions/SoGetMatrixAction.h>
#import <Inventor/actions/SoGetBoundingBoxAction.h>
#import <Inventor/nodekits/SoBaseKit.h>
#import <Inventor/nodes/SoCamera.h>
#import <Inventor/nodes/SoGroup.h>
#import <Inventor/nodes/SoSeparator.h>
#import <Inventor/nodes/SoPerspectiveCamera.h>
#import <Inventor/nodes/SoOrthographicCamera.h>

@interface SCCamera (InternalAPI)
  - (SoGroup *) getParentOfNode:(SoNode *)node inSceneGraph:(SoNode *)root;
@end

@implementation SCCamera

/*" An SCCamera is an abstraction for either an SoPerspectiveCamera or
    an SoOrthographicCamera, enabling easy conversion between these
    the two camera types. It also offers methods for moving and 
    reorienting the camera.
 "*/

// ---------------- Initialisation and cleanup -------------------------

/*" Initializes a newly allocated SCCamera to use c as its 
    representation in the scenegraph, and use controller for
    Coin interaction.

    This method is the designated initializer for the SCCamera
    class. Returns !{self}.
 "*/

- (id) initWithSoCamera:(SoCamera *) c controller:(SCExaminerController *) controller
{
  if (self = [super init]) {
    controllerhascreatedcamera = NO;
    _controller = controller;
    [controller retain];
    camera = c;
    if (camera) camera->ref();
  }
  return self;
}


/*" Initializes a newly allocated SCCamera. Note that you must set
    the actual camera in the Coin scenegraph and the SCController
    component for Coin handling explicitly using #setController:
    and #setSoCamera: before being able to use the camera.
 "*/
 
- (id) init
{
  return [self initWithSoCamera:NULL controller:nil];
}


- (void) dealloc {
  [_controller release];
  if (camera) camera->unref();
  if (autoclipboxaction) delete autoclipboxaction;
}



// ---------- Switching between orthographic and perspective mode -------

/*" Returns !YES if the current camera is a perspective camera. "*/

- (BOOL) isPerspective
{
  return camera->getTypeId().isDerivedFrom(SoPerspectiveCamera::getClassTypeId());
}


/*" Returns !YES if the current camera is an orthographic camera. "*/

- (BOOL) isOrthographic
{
  return camera->getTypeId().isDerivedFrom(SoOrthographicCamera::getClassTypeId());
}


/*" Initializes ocam to have the same settings as the current camera.
    Note: The current camera must be a perspective camera.
 "*/

- (void) cloneFromPerspectiveCamera:(SoOrthographicCamera *)ocam
{
  assert(camera->getTypeId().isDerivedFrom(SoPerspectiveCamera::getClassTypeId()));
  SoPerspectiveCamera * pcam = (SoPerspectiveCamera *) camera;

  ocam->aspectRatio.setValue(pcam->aspectRatio.getValue());
  ocam->focalDistance.setValue(pcam->focalDistance.getValue());
  ocam->orientation.setValue(pcam->orientation.getValue());
  ocam->position.setValue(pcam->position.getValue());
  ocam->viewportMapping.setValue(pcam->viewportMapping.getValue());
  float focaldist = pcam->focalDistance.getValue();
  ocam->height = 2.0f * focaldist * (float)tan(pcam->heightAngle.getValue() / 2.0);
}


/*" Initializes pcam to have the same settings as the current camera.
    Note: The current camera must be an orthographic camera.
 "*/
 
- (void) cloneFromOrthographicCamera:(SoPerspectiveCamera *) pcam
{
  assert(camera->getTypeId().isDerivedFrom(SoOrthographicCamera::getClassTypeId()));
  SoOrthographicCamera * ocam = (SoOrthographicCamera *) camera;

  pcam->aspectRatio.setValue(ocam->aspectRatio.getValue());
  pcam->focalDistance.setValue(ocam->focalDistance.getValue());
  pcam->orientation.setValue(ocam->orientation.getValue());
  pcam->position.setValue(ocam->position.getValue());
  pcam->viewportMapping.setValue(ocam->viewportMapping.getValue());
  float focaldist = ocam->focalDistance.getValue();
  if (focaldist != 0.0f) {
    pcam->heightAngle = 2.0f *
    (float)atan(ocam->height.getValue() / 2.0 / focaldist);
  }
  else { // scene empty -> use default value of 45 degrees.
    pcam->heightAngle = (float)(M_PI / 4.0);
  }
}

/*" Converts from perspective to orthographic camera and vice versa.
    Possible values for type are !{SoPerspectiveCamera::getTypeId()}
    and !{SoOrthographicCamera::getClassTypeId()}.
    
    A new camera of the intended type is created and initialized 
    with the values of the current camera. It is then inserted in 
    the scenegraph and set to be the new current camera by calling 
    the #setSoCamera: method.
 "*/

- (void) convertToType:(SoType) type
{
  if (camera == NULL) return;

  BOOL settoperspective = type.isDerivedFrom(SoPerspectiveCamera::getClassTypeId());
  
  if (([self isPerspective] && settoperspective) ||
      (![self isPerspective] && !settoperspective)) return;

  SoCamera * newcam = (SoCamera *) type.createInstance();
  
  if (settoperspective)
    [self cloneFromOrthographicCamera:(SoPerspectiveCamera *)newcam];
  else
    [self cloneFromPerspectiveCamera:(SoOrthographicCamera *)newcam];

  
  // insert into SG
  SoGroup * camparent = [self getParentOfNode:camera
    inSceneGraph:(SoNode *)[_controller sceneGraph]];
  camparent->insertChild(newcam, camparent->findChild(camera));

#if 0
  // Store the current home position, as it will be implicitly reset
  // by setCamera().
  SoOrthographicCamera * homeo = new SoOrthographicCamera;
  SoPerspectiveCamera * homep = new SoPerspectiveCamera;
  homeo->ref();
  homep->ref();
  homeo->copyContents(PRIVATE(this)->storedortho, FALSE);
  homep->copyContents(PRIVATE(this)->storedperspective, FALSE);
#endif

  [self setSoCamera:newcam];

#if 0
  // Restore home position.
  PRIVATE(this)->storedortho->copyContents(homeo, FALSE);
  PRIVATE(this)->storedperspective->copyContents(homep, FALSE);
  homeo->unref();
  homep->unref();
#endif

}


// -------------- Positioning the camera --------------------------

/*" Zooms in if delta is > 0, else zooms out. "*/

- (void) zoom:(float) delta
{
  // FIXME: Actually use delta to determine zoom distance.
  // kyrah 20030621.
  
  float factor = (delta > 0) ? 1.1 : 0.9;
  if (camera == NULL) return;
  SoType t = camera->getTypeId();

  if ([self isOrthographic]) {

    SoOrthographicCamera * orthocam = (SoOrthographicCamera *)camera;
    orthocam->height = orthocam->height.getValue() * factor;
    
  } else if ([self isPerspective]) {
    
    SbVec3f dir, newpos;
    float newfocaldist, dist;
    const float oldfocaldist = camera->focalDistance.getValue();
    const SbVec3f oldpos = camera->position.getValue();
    newfocaldist = oldfocaldist * factor;
    camera->orientation.getValue().multVec(SbVec3f(0, 0, -1), dir);
    newpos = oldpos + (newfocaldist - oldfocaldist) * -dir;
    dist = newpos.length();

    // Floating point precision sanity check.
    if (dist > float(sqrt(FLT_MAX))) {
      NSLog(@"Zoomed too far: Distance to origo = %f (%e)", dist, dist);
      return;
    }

    camera->position = newpos;
    camera->focalDistance = newfocaldist;
    
  } else {
  
    NSLog(@"Unknown camera type in [SCCamera zoom]; no zooming done.");
    
  }
}

/*" Positions the camera so that we can see the whole scene. "*/

- (void) viewAll
{
  if (camera == NULL || _controller == nil) return;
  camera->viewAll([_controller sceneGraph],
                  [_controller sceneManager]->getViewportRegion());
}


/*" Updates the near and far clipping plane to optimize depth buffer usage
    (the greater the ratio far/near, the less effective the depth buffer).
 "*/
 
- (void) updateClippingPlanes:(SoSeparator *) scenegraph
{
  // FIXME: Need autoclipcb callback function? Investigate.
  // kyrah 20030509
  // Update 20030621: Use notification instead!
  
  SbMatrix cameramatrix, inverse, m;
  SbXfBox3f xbox;
  SbBox3f box;
  const float SLACK = 0.001f;

  if (camera == NULL) return;

  // Important note: Applying an SoGetBoundingBoxAction here
  // is also important for caching, since applying a getBoundingBox
  // action to the SG creates a valid bounding box cache, needed
  // for caching. kyrah 20030622
  
  if (autoclipboxaction == NULL)
    autoclipboxaction = new
      SoGetBoundingBoxAction([_controller viewportRegion]);
  else
    autoclipboxaction->setViewportRegion([_controller viewportRegion]);

  autoclipboxaction->apply(scenegraph);
  xbox =  autoclipboxaction->getXfBoundingBox();
  [self getCameraCoordinateSystem:cameramatrix inverse:inverse];
  xbox.transform(inverse);

  m.setTranslate(-camera->position.getValue());
  xbox.transform(m);
  m = camera->orientation.getValue().inverse();
  xbox.transform(m);
  box = xbox.project();

  // Flip the box. (The bounding box was calculated in camera space,
  // with the camera pointing in (0,0,-1) direction from origo).
  float nearval = -box.getMax()[2];
  float farval = -box.getMin()[2];

  if (farval <= 0.0f) return; 	// scene completely behind us

  // Disallow negative and very small near clipping plane distance
  nearval = [_controller bestValueForNearPlane:nearval farPlane:farval];

  // Add some slack around bounding box in case the scene fits exactly
  // inside it, to avoid artifacts like the near clipping plane cutting
  // into the model's corners when it is rotated.
  camera->nearDistance = nearval * (1.0f - SLACK);
  camera->farDistance = farval * (1.0f + SLACK);

}

// ------------------ Accessor methods ----------------------------

/*" Sets the actual camera in the Coin scene graph to cam. 
    It is first checked if the scenegraph contains a camera created by
    the controller, and if yes, this camera is deleted. 
    
    Note that cam is expected to be part of the scenegraph already;
    it is not inserted into it.
 "*/
 
- (void) setSoCamera:(SoCamera *)cam
{
  if (cam == NULL) return;

  if (controllerhascreatedcamera) { // delete camera if we created it
    SoGroup * camparent = [self getParentOfNode:camera
      inSceneGraph:(SoNode*)[_controller sceneGraph]];
    camparent->removeChild(camera);
    controllerhascreatedcamera = NO;
  }
  if (camera) camera->unref();
  camera = cam;
  camera->ref();
#if 0
  saveHomePosition;
#endif
  controllerhascreatedcamera = YES;
}


/*" Returns the actual camera used in the scene graph. "*/

- (SoCamera *) soCamera { 
  return camera; 
}


/*" Set whether the camera was created by the controller component
    (as opposed to being part of the user-supplied scene graph. 
    When setting a new camera, this setting will determine if the
    old camera should be deleted or not.   
 "*/
    
- (void) setControllerHasCreatedCamera:(BOOL) yn { 
  controllerhascreatedcamera = yn; 
}

/*" Returns YES if the camera was created by the controller 
    component, and NO if the camera is part of the user-supplied
    scene graph.
 "*/
 
- (BOOL) controllerHasCreatedCamera { 
  return controllerhascreatedcamera; 
}

/*" Sets the SCCamera's SCController component to controller. "*/

- (void) setController:(SCExaminerController *) controller
{
  [controller retain];
  [_controller release];
  _controller = controller;
}

/*" Returns the SCCamera's SCController component. "*/

- (SCExaminerController *) controller { return _controller; }

/*" Reorients the camera by rot. Note that this does not
    replace the previous values but is accumulative: rot
    will be multiplied together with the previous orientation.
 "*/

- (void) reorient:(SbRotation)rot
{
  SbVec3f dir, focalpt;
  if (camera == NULL) return;
  
  // Find global coordinates of focal point.
  camera->orientation.getValue().multVec(SbVec3f(0, 0, -1), dir);
  focalpt = camera->position.getValue() + camera->focalDistance.getValue() * dir;
  
  // Set new orientation value by accumulating the new rotation.
  camera->orientation = rot * camera->orientation.getValue();
  
  // Reposition camera so we are still pointing at the same old focal point.
  camera->orientation.getValue().multVec(SbVec3f(0, 0, -1), dir);
  camera->position = focalpt - camera->focalDistance.getValue() * dir;
}

/*" Get the camera's object coordinate system. "*/

- (void) getCameraCoordinateSystem: (SbMatrix &)m inverse:(SbMatrix &)inv
{
  SoNode * root = [_controller sceneGraph];
  SoSearchAction searchaction;
  SoGetMatrixAction matrixaction(SbViewportRegion(100,100));
  
  searchaction.setSearchingAll(TRUE);
  searchaction.setInterest(SoSearchAction::FIRST);
  searchaction.setNode(camera);
  searchaction.apply(root);
  m = inv = SbMatrix::identity();
  if (searchaction.getPath()) {
    matrixaction.apply(searchaction.getPath());
    m = matrixaction.getMatrix();
    inv = matrixaction.getInverse();
  }
}


// ----------------------- InternalAPI --------------------------

- (SoGroup *) getParentOfNode:(SoNode *)node inSceneGraph:(SoNode *)root
{
  SbBool wassearchingchildren = SoBaseKit::isSearchingChildren();
  SoBaseKit::setSearchingChildren(TRUE);
  assert(node && root && "getParentOfNode called with NULL argument");

  SoSearchAction search;
  search.setSearchingAll(TRUE);
  search.setNode(node);
  search.apply(root);

  // FIXME: Shouldn't I rather just return NULL here? kyrah 20030513
  assert(search.getPath() && "node not found in scenegraph");
  SoNode * parent = ((SoFullPath *)search.getPath())->getNodeFromTail(1);
  assert(parent && "couldn't find parent");

  SoBaseKit::setSearchingChildren(wassearchingchildren);
  return (SoGroup *)parent;
}

@end
