/* =============================================================== *
 |                                                                 |
 | This file is part of Sc21, a Cocoa user interface binding for   |
 | the Coin 3D visualization library.                              |
 |                                                                 |
 | Copyright (c) 2003-2005 Systems in Motion. All rights reserved. |
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

#import <OpenGL/gl.h>

#import <Inventor/SoType.h>
#import <Inventor/actions/SoGetBoundingBoxAction.h>
#import <Inventor/actions/SoGetMatrixAction.h>
#import <Inventor/actions/SoSearchAction.h>
#import <Inventor/nodes/SoPerspectiveCamera.h>
#import <Inventor/nodes/SoOrthographicCamera.h>

#define SELF (self->_sc_camera)

@implementation SCCameraP
@end

@implementation SCCamera

/*" 
  An SCCamera encapsulates an SoCamera. The purpose of this
  abstraction is to provide convenience methods for moving and
  reorienting the camera and for adjusting the clipping planes to
  optimize z buffer usage.

  In a typical Sc21 application, you will never need to create an
  SCCamera yourself, since SCSceneGraph automatically initializes
  one. Use SCSceneGraph's !{camera:} method to access that SCCamera.
"*/

#pragma mark --- initialization and cleanup ---

/*" 
  Initializes a newly allocated SCCamera. This method is the
  designated initializer for the SCCamera class. Returns !{self}.

"*/

- (id)init
{
  if (self = [super init]) {
    [self _SC_commonInit];
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
  Reorients the receiver's SoCamera camera by rotation. 

  Note that this does not replace the previous values but is
  accumulative: the current orientation will be multiplied with
  rotation.
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
  Translates the receiver's SoCamera by vector relative to its own
  coordinate system.(In its own coordinate system, the camera is
  pointing in negative Z direction with the Y axis being up.)
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


/*" 
  Zooms in if delta is > 0, else zoom out.

  This method is designed so it can easily be connected to mouse
  movement, using the difference between normalized mouse coordinates
  as input. Therefore, typical delta values are expected to be in the
  area of 0.001 - 0.005; the actual zoom factor is calculated based on
  delta.
"*/

- (void)zoom:(float)delta
{
  if (delta == 0 || SELF->camera == NULL) return;
  
  float factor = float(exp(delta * 20.0f)); // Multiply by 20 to get a good
                                            // sensitivity.

  SoType cameratype = SELF->camera->getTypeId();

  if (cameratype.isDerivedFrom(SoOrthographicCamera::getClassTypeId())) {

    SoOrthographicCamera * orthocam = (SoOrthographicCamera *)SELF->camera;
    orthocam->height = orthocam->height.getValue() * factor;
    
  } else if (cameratype.isDerivedFrom(SoPerspectiveCamera::getClassTypeId())) {
    
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


/*" 
  Positions the receiver's SoCamera so the whole scene in scenegraph
  is visible. The SoCamera must be part of the scenegraph.
"*/

- (void)viewAll:(SCSceneGraph *)sceneGraph
{
  assert ([sceneGraph _SC_sceneManager]);
  
  if (SELF->camera == NULL || sceneGraph == nil) return;
  SELF->camera->viewAll((SoNode *)([sceneGraph root]),
                        [sceneGraph _SC_sceneManager]->getViewportRegion());
}


/*" 
  Positions the near and far clipping planes just in front of and
  behind the scene's bounding box to optimize depth buffer usage.

  If present, the delegate method
  !{adjustNearClippingPlane:farClippingPlane:} will be called with the
  internally calculated near and far clipping plane values to allow
  for final fine-tuning. (See the NSObject(SCCameraDelegate)
  documentation for more information.)

  You can set !{updatesClippingPlanes} to !{NO} to disable automatic
  clipping plane adjustment. In this case, the delegate method
  !{adjustNearClippingPlane:farClippingPlane:} (if present) will be
  called with the current (unmodified) near and far clipping plane
  values, allowing you to do your own custom modifications.
"*/
 
- (void)updateClippingPlanes:(SCSceneGraph *)sceneGraph
{
  if (SELF->camera == NULL) return;
  assert ([sceneGraph _SC_sceneManager]);

  // Temporarily turn off notification when changing near and far
  // clipping planes, to avoid latency.
  const SbBool wasnotifyenabled = SELF->camera->isNotifyEnabled();
  SELF->camera->enableNotify(FALSE);

  // Important note: Applying an SoGetBoundingBoxAction here is also
  // important for culling, since applying a getBoundingBox action to
  // the SG creates a valid bounding box cache. Thus we do this even
  // if the actual updating of clipping planes is disabled. 
  SbViewportRegion viewport = 
    [sceneGraph _SC_sceneManager]->getViewportRegion();
  if (SELF->autoclipboxaction == NULL) {
    SELF->autoclipboxaction = new SoGetBoundingBoxAction(viewport);
  } else {
    SELF->autoclipboxaction->setViewportRegion(viewport);
  }
  SELF->autoclipboxaction->apply([sceneGraph _SC_superSceneGraph]);

  if (SELF->updatesclippingplanes) {

    SbXfBox3f xbox =  SELF->autoclipboxaction->getXfBoundingBox();

    SbMatrix cameramatrix, inverse;
    [self _SC_getCoordinateSystem:cameramatrix inverse:inverse 
      inSceneGraph:sceneGraph];
    xbox.transform(inverse);
  
    SbMatrix m;
    m.setTranslate(-SELF->camera->position.getValue());
    xbox.transform(m);
    m = SELF->camera->orientation.getValue().inverse();
    xbox.transform(m);
    SbBox3f box = xbox.project();
    
    // Flip the box. (The bounding box was calculated in camera space,
    // with the camera pointing in (0,0,-1) direction from origo).
    float nearval = -box.getMax()[2];
    float farval = -box.getMin()[2];
    
    if (farval > 0.0f) { // make sure scene is not completely behind us
    
      nearval = [self _SC_bestValueForNearPlane:nearval farPlane:farval];
    
      // Add some slack around bounding box in case the scene fits exactly
      // inside it, to avoid artifacts like the near clipping plane cutting
      // into the model's corners when it is rotated.
      const float SLACK = 0.001f;
      nearval *= (1.0f - SLACK);
      farval *= (1.0f + SLACK);
    
      // let the delegate method adjust the values calculated internally
      if (self->delegate) {
        if ([self->delegate respondsToSelector:
             @selector(adjustNearClippingPlane:farClippingPlane:)]) {
          
          [self->delegate adjustNearClippingPlane:&nearval 
           farClippingPlane:&farval];
        }
      }
    
      SELF->camera->nearDistance = nearval;
      SELF->camera->farDistance = farval;
    } 
    
  } else {
    // Do not do any internal calculations, but let the user-supplied
    // delegate method do the adjustment.
    if (self->delegate && [self->delegate respondsToSelector:
        @selector(adjustNearClippingPlane:farClippingPlane:)]) {     

        float nearval = SELF->camera->nearDistance.getValue();
        float farval = SELF->camera->farDistance.getValue();
        [self->delegate adjustNearClippingPlane:&nearval 
                        farClippingPlane:&farval];
        SELF->camera->nearDistance = nearval;
        SELF->camera->farDistance = farval;
    }
  }

  // Restore camera's notification settings.
  SELF->camera->enableNotify(wasnotifyenabled);
}


/*" 
  Returns !{YES} if the receiver automatically updates the clipping
  planes to optimzie z-buffer usage, and !{NO} otherwise. 
  The default is !{YES}
"*/

- (BOOL)updatesClippingPlanes
{
  return SELF->updatesclippingplanes;
}


/*" 
  Sets whether the receiver should automatically update the clipping
  planes to optimzie z-buffer usage. The default is !{YES}.
"*/

- (void)setUpdatesClippingPlanes:(BOOL)yn
{
  SELF->updatesclippingplanes = yn;
}


#pragma mark --- accessor methods ---

/*" 
  Sets the receiver's SoCamera to newcamera. 
"*/

- (void)setSoCamera:(SoCamera *)newcamera 
{
  if (newcamera == NULL) return;
  if (SELF->camera) SELF->camera->unref();
  SELF->camera = newcamera;
  SELF->camera->ref();
}


/*" Returns the receiver's SoCamera. "*/

- (SoCamera *)soCamera
{
  return SELF->camera; 
}


#pragma mark --- delegate handling ---

/*" Makes newdelegate the receiver's delegate. "*/

- (void)setDelegate:(id)newdelegate
{
  self->delegate = newdelegate;
}


/*" Returns the receiver's delegate. "*/

- (id)delegate
{
  return self->delegate;
}

@end


@implementation SCCamera (InternalAPI)

- (void)_SC_commonInit
{
  SELF = [[SCCameraP alloc] init];
  SELF->updatesclippingplanes = YES;
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


/* 
  Determines the best value for the near clipping plane. Negative and
  very small near clipping plane distances are disallowed.
*/

- (float)_SC_bestValueForNearPlane:(float)near farPlane:(float)far
{
  float nearlimit, r;
  int usebits;
  GLint depthbits[1];
  const float autoclipvalue = 0.6f;
 
  SoType cameratype = SELF->camera->getTypeId();
  if (cameratype.isDerivedFrom(SoOrthographicCamera::getClassTypeId()))
    return near;

  // For simplicity, we are using what SoQt calls the
  // VARIABLE_NEAR_PLANE strategy.

  glGetIntegerv(GL_DEPTH_BITS, depthbits);
  usebits = (int) (float(depthbits[0]) * (1.0f - autoclipvalue));
  r = (float) pow(2.0, (double) usebits);
  nearlimit = far / r;

  // If we end up with a bogus value, use an empirically determined
  // magic value that's supposed to work will (taken from SoQtViewer.cpp).
  if (nearlimit >= far) {nearlimit = far / 5000.0f;}

  if (near < nearlimit) return nearlimit;
  else return near;
}

@end


#if FOR_AUTODOC_ONLY 

// Dummy implementations to force AutoDoc to generate documentation for 
// delegate methods.

@implementation NSObject (SCCameraDelegate)

/*" 
  The SCCamera delegate allows you to fine-tune the values for the
  near and far clipping planes, as automatically calculated by
  SCController/SCCamera to optimize depth buffer usage.
"*/


/*" 
  Implementing this delegate method allows you to adjust the values
  for the distance of the near and far clipping plane from the camera
  as calculated by !{updateClippingPlanes:}. This lets you control the
  tradeoff between z-buffer resolution and clipping of geometry at the
  near or far plane specifically for your application. The adjusted
  values will be used unmodified.

  Note that the internal calculations should work well with most
  scenes. You should only have to make adjustments for very special
  cases, such as scenes with a large world space, but where one would
  still like to be able to get up extremely close on details in some
  parts of the scene.
"*/

- (void)adjustNearClippingPlane:(float *)near 
                 farClippingPlane:(float *)far
{
}
@end

#endif // FOR_AUTODOC_ONLY 
