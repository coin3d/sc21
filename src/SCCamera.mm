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
#import <Sc21/SCSceneGraph.h>

#import "SCCameraP.h"
#import "SCSceneGraphP.h"
#import "SCUtil.h"

#import <OpenGL/gl.h> // for GLint

#import <Inventor/SoType.h>
#import <Inventor/SoSceneManager.h>
#import <Inventor/actions/SoSearchAction.h>
#import <Inventor/actions/SoGetMatrixAction.h>
#import <Inventor/nodekits/SoBaseKit.h>
#import <Inventor/nodes/SoGroup.h>

#define SELF (self->_sc_camera)

@implementation _SCCameraP
@end

@implementation SCCamera

/*" An SCCamera is an abstraction for either an !{SoPerspectiveCamera} or
    an !{SoOrthographicCamera}, enabling easy conversion between these
    the two camera types. It also offers methods for moving and 
    reorienting the camera.
 "*/

#pragma mark --- initialization and cleanup ---

/*" Initializes a newly allocated SCCamera.
    Note that you must set the actual camera in the Coin scenegraph explicitly 
    using the #setSoCamera: method before being able to use the camera.

    This method is the designated initializer for the SCCamera
    class. Returns !{self}.
 "*/

- (id)init
{
  if (self = [super init]) {
    [self _SC_commonInit];
    SELF->autoclipvalue = 0.6;
  }
  return self;
}


- (void)dealloc
{
  if (SELF->camera) SELF->camera->unref();
  delete SELF->autoclipboxaction;
  [SELF release];
  [super dealloc];
}


#pragma mark --- positioning the camera ---

/*" 
  Reorients the camera by rot. Note that this does not replace the previous 
  values but is accumulative: rot will be multiplied together with the 
  previous orientation.
"*/

- (void)reorient:(SbRotation)rot
{
  SbVec3f dir, focalpt;
  if (SELF->camera == NULL) return;
  
  // Find global coordinates of focal point.
  SELF->camera->orientation.getValue().multVec(SbVec3f(0, 0, -1), dir);
  focalpt = SELF->camera->position.getValue() + 
    SELF->camera->focalDistance.getValue() * dir;
  
  // Set new orientation value by accumulating the new rotation.
  SELF->camera->orientation = rot * SELF->camera->orientation.getValue();
  
  // Reposition camera so we are still pointing at the same old focal point.
  SELF->camera->orientation.getValue().multVec(SbVec3f(0, 0, -1), dir);
  SELF->camera->position = focalpt - SELF->camera->focalDistance.getValue()*dir;
}

/*"
Translate camera relative to its own coordinate system.
 
 In its own coordinate system, the camera is pointing in negative
 Z direction with the Y axis being up.
 "*/
- (void)translate:(SbVec3f)v
{
  if (SELF->camera == NULL) return;
  
  SbVec3f pos = SELF->camera->position.getValue();
  SbRotation r = SELF->camera->orientation.getValue();
  r.multVec(v, v);
  SELF->camera->position = SELF->camera->position.getValue() + v;
  pos = SELF->camera->position.getValue();
}

/*" Zooms in if delta is > 0, else zooms out. "*/

- (void)zoom:(float)delta
{
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

- (void)viewAll:(SCSceneGraph *)sceneGraph
{
  if (SELF->camera == NULL || sceneGraph == nil) return;
  SELF->camera->viewAll((SoNode *)([sceneGraph root]),
                        [sceneGraph sceneManager]->getViewportRegion());

  [[NSNotificationCenter defaultCenter]
    postNotificationName:SCViewAllNotification object:self];
}


/*" Updates the near and far clipping plane to optimize depth buffer usage
    (the greater the ratio far/near, the less effective the depth buffer).
 "*/
 
- (void)updateClippingPlanes:(SCSceneGraph *)sceneGraph
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

  assert ([sceneGraph sceneManager]);
  
  SbViewportRegion viewport = [sceneGraph sceneManager]->getViewportRegion();
  if (SELF->autoclipboxaction == NULL) {
    SELF->autoclipboxaction = new 
    SoGetBoundingBoxAction(viewport);
  } else { 
    SELF->autoclipboxaction->setViewportRegion(viewport);
  }
  
  SELF->autoclipboxaction->apply([sceneGraph root]);
  xbox =  SELF->autoclipboxaction->getXfBoundingBox();
  [self _SC_getCoordinateSystem:cameramatrix inverse:inverse 
    inSceneGraph:sceneGraph];
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

#pragma mark --- accessor methods ---


/*" 
  Returns !{SCCameraPerspective} if the camera is a perspective camera,
  !{SCCameraOrthographic} if the camera is an orthographic camera, and
  !{SCUnknown} otherwise.
"*/

// FIXME: Since we don't do type conversion anymore, maybe we should
// remove the SCCameraType concept altogether. kyrah 20040801.

- (SCCameraType)type
{
  SoCamera * cam = SELF->camera;
  
  if (cam == NULL) { return SCCameraNone; }
  
  if (cam->getTypeId().isDerivedFrom(SoPerspectiveCamera::getClassTypeId())) {
    return SCCameraPerspective;
  } 
  
  if (cam->getTypeId().isDerivedFrom(SoOrthographicCamera::getClassTypeId())) {
    return SCCameraOrthographic;
  } 
  
  return SCCameraUnknown;
}


/*" Sets the actual camera in the Coin scene graph to cam. 
    
    Note that cam is expected to be part of the scenegraph already;
    it is not inserted into it.
 "*/

- (void)setSoCamera:(SoCamera *)camera 
{
  if (camera == NULL) return;
  if (SELF->camera) SELF->camera->unref();
  SELF->camera = camera;
  SELF->camera->ref();
}


/*" Returns the actual camera used in the scene graph. "*/

- (SoCamera *)soCamera
{
  return SELF->camera; 
}

// FIXME: Do we really need this? I mean, it's a very internal
// implementation detail... I doubt that anybody can make sense 
// from this... kyrah 20040717

- (void)setAutoClipValue:(float)autoclipvalue
{
  SELF->autoclipvalue = autoclipvalue;
}

/*" Returns the current autoclipvalue. The default value is 0.6. "*/

- (float)autoClipValue
{
  return SELF->autoclipvalue;
}
@end

@implementation SCCamera (InternalAPI)

- (void)_SC_commonInit
{
  SELF = [[_SCCameraP alloc] init];
}

/* Get the camera's object coordinate system. */

- (void)_SC_getCoordinateSystem: (SbMatrix &)m inverse:(SbMatrix &)inv 
  inSceneGraph:(SCSceneGraph *)sg
{
  SoGroup * root = [sg root];
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
  usebits = (int) (float(depthbits[0]) * (1.0f - SELF->autoclipvalue));
  r = (float) pow(2.0, (double) usebits);
  nearlimit = far / r;

  // If we end up with a bogus value, use an empirically determined
  // magic value that's supposed to work will (taken from SoQtViewer.cpp).
  if (nearlimit >= far) {nearlimit = far / 5000.0f;}

  if (near < nearlimit) return nearlimit;
  else return near;
}

@end
