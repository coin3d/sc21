//
//  SCCamera.m
//  SCView
//
//  Created by Karin Kosina on Tue May 13 2003.
//  Copyright (c) 2003 Systems in Motion. All rights reserved.
//

#import "SCCamera.h"
#import "SCController.h"
#import "SCExaminerController.h" // for notifications

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
  - (void) _convertToType:(SoType) type;
  - (SoGroup *) getParentOfNode:(SoNode *)node inSceneGraph:(SoGroup *)root;
@end

@implementation SCCamera

/*" An SCCamera is an abstraction for either an SoPerspectiveCamera or
    an SoOrthographicCamera, enabling easy conversion between these
    the two camera types. It also offers methods for moving and 
    reorienting the camera.

    Note: This class is used internally in SC21. You probably won't need
    to ever use it yourself.
 "*/

// ---------------- Initialisation and cleanup -------------------------

/*" Initializes a newly allocated SCCamera to use c as its 
    representation in the scenegraph, and use controller for
    Coin interaction.

    This method is the designated initializer for the SCCamera
    class. Returns !{self}.
 "*/

- (id) initWithSoCamera:(SoCamera *)camera controller:(SCController *)controller
{
  if (self = [super init]) {
    _controllerhascreatedcamera = NO;
    _controller = controller;
    _camera = camera;
    if (_camera) _camera->ref();
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
  if (_camera) _camera->unref();
  if (_autoclipboxaction) delete _autoclipboxaction;
}



// ---------- Switching between orthographic and perspective mode -------

/*" Returns !SCCameraPerspective if the camera is a perspective camera,
    !SCCameraOrthographic if the camera is an orthographic camera, and
    !SCUnknown otherwise.
 "*/

- (SCCameraType) type
{
  if (_camera->getTypeId().isDerivedFrom(SoPerspectiveCamera::getClassTypeId()))
    return SCCameraPerspective;
  else if (_camera->getTypeId().isDerivedFrom(SoOrthographicCamera::getClassTypeId()))
    return SCCameraOrthographic;
  else return SCCameraUnknown;
}


/*" Initializes orthocam to have the same settings as the current camera.
    Note: The current camera must be a perspective camera.
 "*/

- (void) cloneFromPerspectiveCamera:(SoOrthographicCamera *)orthocam
{
  assert(_camera->getTypeId().isDerivedFrom(SoPerspectiveCamera::getClassTypeId()));
  SoPerspectiveCamera * pcam = (SoPerspectiveCamera *) _camera;

  orthocam->aspectRatio.setValue(pcam->aspectRatio.getValue());
  orthocam->focalDistance.setValue(pcam->focalDistance.getValue());
  orthocam->orientation.setValue(pcam->orientation.getValue());
  orthocam->position.setValue(pcam->position.getValue());
  orthocam->viewportMapping.setValue(pcam->viewportMapping.getValue());
  float focaldist = pcam->focalDistance.getValue();
  orthocam->height = 2.0f * focaldist * (float)tan(pcam->heightAngle.getValue() / 2.0);
}


/*" Initializes perspectivecam to have the same settings as the current camera.
    Note: The current camera must be an orthographic camera.
 "*/
 
- (void) cloneFromOrthographicCamera:(SoPerspectiveCamera *) perspectivecam
{
  assert(_camera->getTypeId().isDerivedFrom(SoOrthographicCamera::getClassTypeId()));
  SoOrthographicCamera * ocam = (SoOrthographicCamera *) _camera;

  perspectivecam->aspectRatio.setValue(ocam->aspectRatio.getValue());
  perspectivecam->focalDistance.setValue(ocam->focalDistance.getValue());
  perspectivecam->orientation.setValue(ocam->orientation.getValue());
  perspectivecam->position.setValue(ocam->position.getValue());
  perspectivecam->viewportMapping.setValue(ocam->viewportMapping.getValue());
  float focaldist = ocam->focalDistance.getValue();
  if (focaldist != 0.0f) {
    perspectivecam->heightAngle = 2.0f *
    (float)atan(ocam->height.getValue() / 2.0 / focaldist);
  }
  else { // scene empty -> use default value of 45 degrees.
    perspectivecam->heightAngle = (float)(M_PI / 4.0);
  }
}

/*" Converts from perspective to orthographic camera and vice versa.
    Possible values for type are !SCCameraPerspective and
    !SCCameraOrthographic.

    A new camera of the intended type is created and initialized
    with the values of the current camera. It is then inserted in
    the scenegraph and set to be the new current camera by calling
    the #setSoCamera: method.
 "*/


- (void) convertToType:(SCCameraType)type
{
  switch (type) {
    case SCCameraOrthographic:
      [self _convertToType:SoOrthographicCamera::getClassTypeId()];
      break;
    case SCCameraPerspective:
      [self _convertToType:SoPerspectiveCamera::getClassTypeId()];
      break;
    default:
      NSLog(@"Unknown camera type.");
      break;
  }
}


// -------------- Positioning the camera --------------------------

/*" Zooms in if delta is > 0, else zooms out. "*/

- (void) zoom:(float)delta
{
  // FIXME: Actually use delta to determine zoom distance.
  // kyrah 20030621.
  
  float factor = (delta > 0) ? 1.1 : 0.9;
  if (_camera == NULL) return;
  SoType t = _camera->getTypeId();

  if ([self type] == SCCameraOrthographic) {

    SoOrthographicCamera * orthocam = (SoOrthographicCamera *)_camera;
    orthocam->height = orthocam->height.getValue() * factor;
    
  } else if ([self type] == SCCameraPerspective) {
    
    SbVec3f dir, newpos;
    float newfocaldist, dist;
    const float oldfocaldist = _camera->focalDistance.getValue();
    const SbVec3f oldpos = _camera->position.getValue();
    newfocaldist = oldfocaldist * factor;
    _camera->orientation.getValue().multVec(SbVec3f(0, 0, -1), dir);
    newpos = oldpos + (newfocaldist - oldfocaldist) * -dir;
    dist = newpos.length();

    // Floating point precision sanity check.
    if (dist > float(sqrt(FLT_MAX))) {
      NSLog(@"Zoomed too far: Distance to origo = %f (%e)", dist, dist);
      return;
    }

    _camera->position = newpos;
    _camera->focalDistance = newfocaldist;
    
  } else {
  
    NSLog(@"Unknown camera type in [SCCamera zoom]; no zooming done.");
    
  }
}

/*" Positions the camera so that we can see the whole scene. "*/

- (void) viewAll
{
  if (_camera == NULL || _controller == nil) return;
  _camera->viewAll([_controller sceneGraph],
                  [_controller sceneManager]->getViewportRegion());

  [[NSNotificationCenter defaultCenter]
    postNotificationName:SCViewAllNotification object:self];
}


/*" Updates the near and far clipping plane to optimize depth buffer usage
    (the greater the ratio far/near, the less effective the depth buffer).
 "*/
 
- (void) updateClippingPlanes:(SoGroup *)scenegraph
{
  // FIXME: Need autoclipcb callback function? Investigate.
  // kyrah 20030509
  // Update 20030621: Use notification instead!
  
  SbMatrix cameramatrix, inverse, m;
  SbXfBox3f xbox;
  SbBox3f box;
  const float SLACK = 0.001f;

  if (_camera == NULL) return;

  // Important note: Applying an SoGetBoundingBoxAction here
  // is also important for caching, since applying a getBoundingBox
  // action to the SG creates a valid bounding box cache, needed
  // for caching. kyrah 20030622
  
  if (_autoclipboxaction == NULL)
    _autoclipboxaction = new
      SoGetBoundingBoxAction([_controller viewportRegion]);
  else
    _autoclipboxaction->setViewportRegion([_controller viewportRegion]);

  _autoclipboxaction->apply(scenegraph);
  xbox =  _autoclipboxaction->getXfBoundingBox();
  [self getCameraCoordinateSystem:cameramatrix inverse:inverse];
  xbox.transform(inverse);

  m.setTranslate(-_camera->position.getValue());
  xbox.transform(m);
  m = _camera->orientation.getValue().inverse();
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
  _camera->nearDistance = nearval * (1.0f - SLACK);
  _camera->farDistance = farval * (1.0f + SLACK);
}

// ------------------ Accessor methods ----------------------------

/*" Sets the actual camera in the Coin scene graph to cam. 
    It is first checked if the scenegraph contains a camera created by
    the controller, and if yes, this camera is deleted. 
    
    Note that cam is expected to be part of the scenegraph already;
    it is not inserted into it.
 "*/
 
- (void) setSoCamera:(SoCamera *)camera
{
  if (camera == NULL) return;

  if (_controllerhascreatedcamera) { // delete camera if we created it
    SoGroup * camparent = [self getParentOfNode:_camera
      inSceneGraph:(SoGroup*)[_controller sceneGraph]];
    camparent->removeChild(_camera);
    _controllerhascreatedcamera = NO;
  }
  if (_camera) _camera->unref();
  _camera = camera;
  _camera->ref();
#if 0
  saveHomePosition;
#endif
}


/*" Returns the actual camera used in the scene graph. "*/

- (SoCamera *) soCamera { 
  return _camera; 
}


/*" Set whether the camera was created by the controller component
    (as opposed to being part of the user-supplied scene graph. 
    When setting a new camera, this setting will determine if the
    old camera should be deleted or not.   
 "*/
    
- (void) setControllerHasCreatedCamera:(BOOL)yn { 
  _controllerhascreatedcamera = yn; 
}

/*" Returns YES if the camera was created by the controller 
    component, and NO if the camera is part of the user-supplied
    scene graph.
 "*/
 
- (BOOL) controllerHasCreatedCamera { 
  return _controllerhascreatedcamera; 
}

/*" Sets the SCCamera's SCController component to controller. "*/

- (void) setController:(SCController *)controller
{
  _controller = controller;
}

/*" Returns the SCCamera's SCController component. "*/

- (SCController *) controller
{
  return _controller;
}

/*" Reorients the camera by rot. Note that this does not
    replace the previous values but is accumulative: rot
    will be multiplied together with the previous orientation.
 "*/

- (void) reorient:(SbRotation)rot
{
  SbVec3f dir, focalpt;
  if (_camera == NULL) return;
  
  // Find global coordinates of focal point.
  _camera->orientation.getValue().multVec(SbVec3f(0, 0, -1), dir);
  focalpt = _camera->position.getValue() + _camera->focalDistance.getValue() * dir;
  
  // Set new orientation value by accumulating the new rotation.
  _camera->orientation = rot * _camera->orientation.getValue();
  
  // Reposition camera so we are still pointing at the same old focal point.
  _camera->orientation.getValue().multVec(SbVec3f(0, 0, -1), dir);
  _camera->position = focalpt - _camera->focalDistance.getValue() * dir;
}

/*" Get the camera's object coordinate system. "*/

- (void) getCameraCoordinateSystem: (SbMatrix &)m inverse:(SbMatrix &)inv
{
  SoGroup * root = [_controller sceneGraph];
  SoSearchAction searchaction;
  SoGetMatrixAction matrixaction(SbViewportRegion(100,100));
  
  searchaction.setSearchingAll(TRUE);
  searchaction.setInterest(SoSearchAction::FIRST);
  searchaction.setNode(_camera);
  searchaction.apply(root);
  m = inv = SbMatrix::identity();
  if (searchaction.getPath()) {
    matrixaction.apply(searchaction.getPath());
    m = matrixaction.getMatrix();
    inv = matrixaction.getInverse();
  }
}


// ----------------------- InternalAPI --------------------------

/* Converts from perspective to orthographic camera and vice versa.
   Possible values for type are !{SoPerspectiveCamera::getTypeId()}
   and !{SoOrthographicCamera::getClassTypeId()}.

   A new camera of the intended type is created and initialized
   with the values of the current camera. It is then inserted in
   the scenegraph and set to be the new current camera by calling
   the #setSoCamera: method.
*/

- (void) _convertToType:(SoType)type
{
  // FIXME: Maybe a better solution would be to have a switch
  // node containing both a perspective and an orthographic
  // camera whose fields are connected, and then just change
  // whichChild, instead of inserting and removing cameras every
  // time we change? kyrah 20030713

  if (_camera == NULL) return;

  // FIXME: Check how SoQt handles this - maybe it should be possible to
  // change camera type if even the cam is part of user SG? kyrah 20030711
  if (!_controllerhascreatedcamera) {
    NSLog(@"Camera is part of user scenegraph, cannot convert.");
    return;
  }
  
  // Don't do anything if camera is already requested type.
  BOOL settoperspective = type.isDerivedFrom(SoPerspectiveCamera::getClassTypeId());
  if (([self type] == SCCameraPerspective && settoperspective) ||
      ([self type] == SCCameraOrthographic && !settoperspective)) return;

  SoCamera * newcam = (SoCamera *) type.createInstance();

  if (settoperspective)
    [self cloneFromOrthographicCamera:(SoPerspectiveCamera *)newcam];
  else
    [self cloneFromPerspectiveCamera:(SoOrthographicCamera *)newcam];


  // insert into SG
  SoGroup * camparent = [self getParentOfNode:_camera
                                 inSceneGraph:(SoGroup *)[_controller sceneGraph]];
  camparent->insertChild(newcam, camparent->findChild(_camera));

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
  [self setControllerHasCreatedCamera:YES];

#if 0
  // Restore home position.
  PRIVATE(this)->storedortho->copyContents(homeo, FALSE);
  PRIVATE(this)->storedperspective->copyContents(homep, FALSE);
  homeo->unref();
  homep->unref();
#endif

  [[NSNotificationCenter defaultCenter]
    postNotificationName:SCCameraTypeChangedNotification object:self];

}

- (SoGroup *) getParentOfNode:(SoNode *)node inSceneGraph:(SoGroup *)root
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
  SoGroup * parent = (SoGroup*) ((SoFullPath *)search.getPath())->getNodeFromTail(1);
  assert(parent && "couldn't find parent");

  SoBaseKit::setSearchingChildren(wassearchingchildren);
  return (SoGroup *)parent;
}

@end
