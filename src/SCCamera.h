#import <Foundation/Foundation.h>

@class SCController;

class SbRotation;
class SbMatrix;
class SbVec3f;
class SbViewportRegion;
class SoCamera;
class SoType;
class SoSeparator;
class SoGetBoundingBoxAction;
class SoPerspectiveCamera;
class SoOrthographicCamera;

@interface SCCamera : NSObject {
  SCController * _controller;
  SoCamera * camera;
  SoGetBoundingBoxAction * autoclipboxaction;
  BOOL controllerhascreatedcamera;
}


/*" Initializing an SCCamera "*/
- (id) initWithSoCamera:(SoCamera *) camera controller:(SCController *) controller;

/*" Switching between orrthographic and perspective mode "*/
- (BOOL) isPerspective;
- (BOOL) isOrthographic;
- (void) convertToType:(SoType)type;
- (void) cloneFromPerspectiveCamera:(SoOrthographicCamera *) ocam;
- (void) cloneFromOrthographicCamera:(SoPerspectiveCamera *) pcam;

/*" Positioning the camera "*/
- (void) zoom:(float) delta;
- (void) reorient:(SbRotation)rot;
- (void) viewAll;
- (void) updateClippingPlanes:(SoSeparator *) scenegraph;

// internal

- (void) getCameraCoordinateSystem:(SbMatrix &)matrix inverse:(SbMatrix &) inverse;

/*" Accessors "*/ 
- (void) setController:(SCController *) ctrl;
- (SCController *) controller;
- (void) setSoCamera:(SoCamera *) c;
- (SoCamera *) soCamera;
- (void) setControllerHasCreatedCamera:(BOOL) yn;
- (BOOL) controllerHasCreatedCamera;
@end
