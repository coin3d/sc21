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
 

#import <Sc21/SCCamera.h>
#import <Sc21/SCController.h>
#import <Sc21/SCExaminerController.h> // for notifications
#import "SCUtil.h"

#import <OpenGL/gl.h> // for GLint

#import <Inventor/SbRotation.h>
#import <Inventor/SbMatrix.h>
#import <Inventor/SoType.h>
#import <Inventor/SoSceneManager.h>
#import <Inventor/actions/SoGLRenderAction.h>
#import <Inventor/actions/SoSearchAction.h>
#import <Inventor/actions/SoGetMatrixAction.h>
#import <Inventor/actions/SoGetBoundingBoxAction.h>
#import <Inventor/nodekits/SoBaseKit.h>
#import <Inventor/nodes/SoCamera.h>
#import <Inventor/nodes/SoGroup.h>
#import <Inventor/nodes/SoPerspectiveCamera.h>
#import <Inventor/nodes/SoOrthographicCamera.h>

#define SELF (self->sccamerapriv)

@interface _SCCameraP : NSObject
{
  SCController * controller;
  SoCamera * camera;
  SoGetBoundingBoxAction * autoclipboxaction;
  BOOL controllerhascreatedcamera;
}
@end

@implementation _SCCameraP
@end

@interface SCCamera (InternalAPI)
  - (BOOL)_SC_convertToType:(SoType)type;
  - (void)_SC_getCameraCoordinateSystem:(SbMatrix &)matrix inverse:(SbMatrix &)inverse;
  - (void)_SC_cloneFromPerspectiveCamera:(SoOrthographicCamera *)orthocam;
  - (void)_SC_cloneFromOrthographicCamera:(SoPerspectiveCamera *)perspectivecam;
  - (float)_SC_bestValueForNearPlane:(float)near farPlane:(float)far;
  - (SoGroup *)_SC_getParentOfNode:(SoNode *)node inSceneGraph:(SoGroup *)root;
@end

@implementation SCCamera

/*" An SCCamera is an abstraction for either an !{SoPerspectiveCamera} or
    an !{SoOrthographicCamera}, enabling easy conversion between these
    the two camera types. It also offers methods for moving and 
    reorienting the camera.

    Note: This class is used internally in Sc21. You probably won't need
    to ever use it yourself.
 "*/

// ---------------- Initialisation and cleanup -------------------------

/*" Initializes a newly allocated SCCamera to use c as its 
    representation in the scenegraph, and use controller for
    Coin interaction.

    This method is the designated initializer for the SCCamera
    class. Returns !{self}.
 "*/

- (id)initWithSoCamera:(SoCamera *)camera controller:(SCController *)controller
{
  if (self = [super init]) {
    SELF = [[_SCCameraP alloc] init];
    SELF->controllerhascreatedcamera = NO;
    SELF->controller = controller;
    SELF->camera = camera;
    if (SELF->camera) SELF->camera->ref();
  }
  return self;
}


/*" Initializes a newly allocated SCCamera. Note that you must set
    the actual camera in the Coin scenegraph and the SCController
    component for Coin handling explicitly using #setController:
    and #setSoCamera: before being able to use the camera.
 "*/
 
- (id)init
{
  return [self initWithSoCamera:NULL controller:nil];
}


- (void)dealloc
{
  if (SELF->camera) SELF->camera->unref();
  if (SELF->autoclipboxaction) delete SELF->autoclipboxaction;
  [SELF release];
  [super dealloc];
}



// ---------- Switching between orthographic and perspective mode -------

/*" Returns !{SCCameraPerspective} if the camera is a perspective camera,
    !{SCCameraOrthographic} if the camera is an orthographic camera, and
    !{SCUnknown} otherwise.
 "*/

- (SCCameraType)type
{
  if (SELF->camera->getTypeId().isDerivedFrom(SoPerspectiveCamera::getClassTypeId()))
    return SCCameraPerspective;
  else if (SELF->camera->getTypeId().isDerivedFrom(SoOrthographicCamera::getClassTypeId()))
    return SCCameraOrthographic;
  else return SCCameraUnknown;
}




/*" Converts from perspective to orthographic camera and vice versa.
    Possible values for type are !{SCCameraPerspective} and
    !{SCCameraOrthographic}.

    A new camera of the intended type is created and initialized
    with the values of the current camera. It is then inserted in
    the scenegraph and set to be the new current camera by calling
    the #setSoCamera: method.

    Returns !{YES} if the camera was changed, and !{NO} if there was
    an error.

    An !{SCCameraTypeChangedNotification} is posted if the camera
    has been converted successfully. Note that even if you
    have an orthographic camera and set it to an orthographic
    camera, you will trigger this notification.

 "*/

- (BOOL)convertToType:(SCCameraType)type
{
  BOOL ok = NO;
  switch (type) {
    case SCCameraOrthographic:
      ok = [self _SC_convertToType:SoOrthographicCamera::getClassTypeId()];
      break;
    case SCCameraPerspective:
      ok =[self _SC_convertToType:SoPerspectiveCamera::getClassTypeId()];
      break;
    default:
      SC21_DEBUG(@"Unknown camera type.");
      break;
  }
  if (ok) {
    [[NSNotificationCenter defaultCenter]
      postNotificationName:SCCameraTypeChangedNotification object:self];
    return YES;
  }
  return NO;
}


// -------------- Positioning the camera --------------------------

/*" Zooms in if delta is > 0, else zooms out. "*/

- (void)zoom:(float)delta
{
  NSLog(@"SCCamera.zoom: %f", delta);

  if (delta == 0 || SELF->camera == NULL) return;
  
  float factor = float(exp(delta * 20.0f)); // Multiply by 20 to get a good
                                            // sensitivity.
  SoType t = SELF->camera->getTypeId();

  if ([self type] == SCCameraOrthographic) {

    SoOrthographicCamera * orthocam = (SoOrthographicCamera *)SELF->camera;
    orthocam->height = orthocam->height.getValue() * factor;
    
  } else if ([self type] == SCCameraPerspective) {
    
    const float oldfocaldist = SELF->camera->focalDistance.getValue();
    const float newfocaldist = oldfocaldist * factor;
    const SbVec3f oldpos = SELF->camera->position.getValue();
    SbVec3f dir;
    SELF->camera->orientation.getValue().multVec(SbVec3f(0, 0, -1), dir);
    const SbVec3f newpos = oldpos + (newfocaldist - oldfocaldist) * -dir;

    // Floating point precision sanity check.
    float dist = newpos.length();
    if (dist > float(sqrt(FLT_MAX))) {
      SC21_DEBUG(@"SCCamera.zoom: Zoomed too far: Distance to origo = %f (%e)",
                 dist, dist);
    }
    else {
      SELF->camera->position = newpos;
      SELF->camera->focalDistance = newfocaldist;
    }
  } else {
    
    SC21_DEBUG(@"SCCamera.zoom: Unknown camera type in [SCCamera zoom]; "
               "no zooming done.");
  }
}

/*" Positions the camera so that we can see the whole scene. "*/

- (void)viewAll
{
  if (SELF->camera == NULL || SELF->controller == nil) return;
  SELF->camera->viewAll((SoNode *)([[SELF->controller sceneGraph] root]),
                  [SELF->controller sceneManager]->getViewportRegion());

  [[NSNotificationCenter defaultCenter]
    postNotificationName:SCViewAllNotification object:self];
}


/*" Updates the near and far clipping plane to optimize depth buffer usage
    (the greater the ratio far/near, the less effective the depth buffer).
 "*/
 
- (void)updateClippingPlanes:(SoGroup *)scenegraph
{
  // FIXME: Need autoclipcb callback function? Investigate.
  // kyrah 20030509
  // Update 20030621: Use notification instead!
  
  SbMatrix cameramatrix, inverse, m;
  SbXfBox3f xbox;
  SbBox3f box;
  const float SLACK = 0.001f;

  if (SELF->camera == NULL) return;

  // Important note: Applying an SoGetBoundingBoxAction here
  // is also important for caching, since applying a getBoundingBox
  // action to the SG creates a valid bounding box cache, needed
  // for caching. kyrah 20030622

  assert ([SELF->controller sceneManager]);
  SoGLRenderAction * renderaction = [SELF->controller sceneManager]->getGLRenderAction();
  
  if (SELF->autoclipboxaction == NULL)
    SELF->autoclipboxaction = new
      SoGetBoundingBoxAction(renderaction->getViewportRegion());
  else
    SELF->autoclipboxaction->setViewportRegion(renderaction->getViewportRegion());

  SELF->autoclipboxaction->apply(scenegraph);
  xbox =  SELF->autoclipboxaction->getXfBoundingBox();
  [self _SC_getCameraCoordinateSystem:cameramatrix inverse:inverse];
  xbox.transform(inverse);

  m.setTranslate(-SELF->camera->position.getValue());
  xbox.transform(m);
  m = SELF->camera->orientation.getValue().inverse();
  xbox.transform(m);
  box = xbox.project();

  // Flip the box. (The bounding box was calculated in camera space,
  // with the camera pointing in (0,0,-1) direction from origo).
  float nearval = -box.getMax()[2];
  float farval = -box.getMin()[2];

  if (farval <= 0.0f) return; 	// scene completely behind us

  // Disallow negative and very small near clipping plane distance
  nearval = [self _SC_bestValueForNearPlane:nearval farPlane:farval];

  // Add some slack around bounding box in case the scene fits exactly
  // inside it, to avoid artifacts like the near clipping plane cutting
  // into the model's corners when it is rotated.
  SELF->camera->nearDistance = nearval * (1.0f - SLACK);
  SELF->camera->farDistance = farval * (1.0f + SLACK);
}

// ------------------ Accessor methods ----------------------------

/*" Sets the actual camera in the Coin scene graph to cam. 
    It is first checked if the scenegraph contains a camera created by
    the controller, and if yes, this camera is deleted. 
    
    Note that cam is expected to be part of the scenegraph already;
    it is not inserted into it.
 "*/

- (void)setSoCamera:(SoCamera *)camera deleteOldCamera:(BOOL)deletecamera
{
  if (camera == NULL) return;

  // delete camera if we created it and if requested
  if (SELF->controllerhascreatedcamera && deletecamera) { 
    SoSceneManager * sm = [SELF->controller sceneManager];
    SoGroup * superscenegraph = (SoGroup *)(sm?sm->getSceneGraph():NULL);
    SoGroup * camparent = 
      [self _SC_getParentOfNode:SELF->camera 
            inSceneGraph:superscenegraph];
    camparent->removeChild(SELF->camera);
    SELF->controllerhascreatedcamera = NO;
  }
  if (SELF->camera) SELF->camera->unref();
  SELF->camera = camera;
  SELF->camera->ref();
#if 0
  saveHomePosition;
#endif
}


/*" Returns the actual camera used in the scene graph. "*/

- (SoCamera *)soCamera { 
  return SELF->camera; 
}


/*" Set whether the camera was created by the controller component
    (as opposed to being part of the user-supplied scene graph). 
    When setting a new camera, this setting will determine if the
    old camera should be deleted or not.   
 "*/
    
- (void)setControllerHasCreatedCamera:(BOOL)yn { 
  SELF->controllerhascreatedcamera = yn; 
}

/*" Returns !{YES} if the camera was created by the controller
    component, and !{NO} if the camera is part of the user-supplied
    scene graph.
 "*/
 
- (BOOL)controllerHasCreatedCamera { 
  return SELF->controllerhascreatedcamera; 
}

/*" Sets the SCCamera's SCController component to controller. "*/

- (void)setController:(SCController *)controller
{
  // We intentionally do not retain controller here, to avoid
  // circular references.
  SELF->controller = controller;
}

/*" Returns the SCCamera's SCController component. "*/

- (SCController *)controller
{
  return SELF->controller;
}

/*" Reorients the camera by rot. Note that this does not
    replace the previous values but is accumulative: rot
    will be multiplied together with the previous orientation.
 "*/

- (void)reorient:(SbRotation)rot
{
  SbVec3f dir, focalpt;
  if (SELF->camera == NULL) return;
  
  // Find global coordinates of focal point.
  SELF->camera->orientation.getValue().multVec(SbVec3f(0, 0, -1), dir);
  focalpt = SELF->camera->position.getValue() + SELF->camera->focalDistance.getValue() * dir;
  
  // Set new orientation value by accumulating the new rotation.
  SELF->camera->orientation = rot * SELF->camera->orientation.getValue();
  
  // Reposition camera so we are still pointing at the same old focal point.
  SELF->camera->orientation.getValue().multVec(SbVec3f(0, 0, -1), dir);
  SELF->camera->position = focalpt - SELF->camera->focalDistance.getValue() * dir;
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

- (BOOL)_SC_convertToType:(SoType)type
{
  // FIXME: Maybe a better solution would be to have a switch
  // node containing both a perspective and an orthographic
  // camera whose fields are connected, and then just change
  // whichChild, instead of inserting and removing cameras every
  // time we change? kyrah 20030713

  if (SELF->camera == NULL) return NO;

  // FIXME: Check how SoQt handles this - maybe it should be possible to
  // change camera type if even the cam is part of user SG? kyrah 20030711
  if (!SELF->controllerhascreatedcamera) {
    SC21_DEBUG(@"Camera is part of user scenegraph, cannot convert.");
    return NO;
  }
  
  // Don't do anything if camera is already requested type.
  // Note that we still return YES, since !{NO} would indicate an error
  // in the conversion.
  BOOL settoperspective = type.isDerivedFrom(SoPerspectiveCamera::getClassTypeId());
  if (([self type] == SCCameraPerspective && settoperspective) ||
      ([self type] == SCCameraOrthographic && !settoperspective)) return YES;

  SoCamera * newcam = (SoCamera *) type.createInstance();
  if (settoperspective)
    [self _SC_cloneFromOrthographicCamera:(SoPerspectiveCamera *)newcam];
  else
    [self _SC_cloneFromPerspectiveCamera:(SoOrthographicCamera *)newcam];

  // insert into SG
  SoSceneManager * sm = [SELF->controller sceneManager];
  SoGroup * superscenegraph = (SoGroup *)(sm?sm->getSceneGraph():NULL);
  SoGroup * camparent = [self _SC_getParentOfNode:SELF->camera
                              inSceneGraph:superscenegraph];
  camparent->insertChild(newcam, camparent->findChild(SELF->camera));

  [self setSoCamera:newcam deleteOldCamera:YES];
  [self setControllerHasCreatedCamera:YES];
  return YES;
}

/*" Initializes orthocam to have the same settings as the current camera.
    Note: The current camera must be a perspective camera.
"*/

- (void)_SC_cloneFromPerspectiveCamera:(SoOrthographicCamera *)orthocam
{
  assert(SELF->camera->getTypeId().isDerivedFrom(SoPerspectiveCamera::getClassTypeId()));
  SoPerspectiveCamera * pcam = (SoPerspectiveCamera *) SELF->camera;

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

- (void)_SC_cloneFromOrthographicCamera:(SoPerspectiveCamera *)perspectivecam
{
  assert(SELF->camera->getTypeId().isDerivedFrom(SoOrthographicCamera::getClassTypeId()));
  SoOrthographicCamera * ocam = (SoOrthographicCamera *)SELF->camera;

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

/* Get the camera's object coordinate system. */

- (void)_SC_getCameraCoordinateSystem: (SbMatrix &)m inverse:(SbMatrix &)inv
{
  SoSeparator * root = [[SELF->controller sceneGraph] root];
  SoSearchAction searchaction;
  SoGetMatrixAction matrixaction(SbViewportRegion(100,100));

  searchaction.setSearchingAll(TRUE);
  searchaction.setInterest(SoSearchAction::FIRST);
  searchaction.setNode(SELF->camera);
  searchaction.apply(root);
  m = inv = SbMatrix::identity();
  if (searchaction.getPath()) {
    matrixaction.apply(searchaction.getPath());
    m = matrixaction.getMatrix();
    inv = matrixaction.getInverse();
  }
}


/* Determines the best value for the near clipping plane. Negative and very
   small near clipping plane distances are disallowed.
 */

- (float)_SC_bestValueForNearPlane:(float)near farPlane:(float)far
{
  // FIXME: Use delegate for doing plane calculation, instead of
  // using strategy. kyrah 20030621.
  float nearlimit, r;
  int usebits;
  GLint depthbits[1];

  if ([self type] == SCCameraOrthographic) return near;

  // For simplicity, we are using what SoQt calls the
  // VARIABLE_NEAR_PLANE strategy. As stated in the FIXME above,
  // we should have a delegate for this in general.
  glGetIntegerv(GL_DEPTH_BITS, depthbits);
  usebits = (int) (float(depthbits[0]) * (1.0f - [SELF->controller autoClipValue]));
  r = (float) pow(2.0, (double) usebits);
  nearlimit = far / r;

  // If we end up with a bogus value, use an empirically determined
  // magic value that's supposed to work will (taken from SoQtViewer.cpp).
  if (nearlimit >= far) {nearlimit = far / 5000.0f;}

  if (near < nearlimit) return nearlimit;
  else return near;
}


/* Get the parent node of node */

- (SoGroup *)_SC_getParentOfNode:(SoNode *)node inSceneGraph:(SoGroup *)root
{
  if (!node) {
    SC21_DEBUG(@"_SC_getParentOfNode called with NULL argument");
    return NULL;
  }
  SbBool wassearchingchildren = SoBaseKit::isSearchingChildren();
  SoBaseKit::setSearchingChildren(TRUE);
  SoSearchAction search;
  search.setSearchingAll(TRUE);
  search.setNode(node);
  search.apply(root);
  if (search.getPath() == NULL) return NULL;
  SoGroup * parent = (SoGroup*) ((SoFullPath *)search.getPath())->getNodeFromTail(1);
  SoBaseKit::setSearchingChildren(wassearchingchildren);
  return (SoGroup *)parent;
}

/*"
  Translate camera relative to its own coordinate system.

  In its own coordinate system, the camera is pointing in negative
  Z direction with the Y axis being up.
  "*/
- (void)translate:(SbVec3f)v
{
  SbVec3f pos = SELF->camera->position.getValue();
  SbRotation r = SELF->camera->orientation.getValue();
  r.multVec(v, v);
  SELF->camera->position = SELF->camera->position.getValue() + v;
  pos = SELF->camera->position.getValue();
}

@end
