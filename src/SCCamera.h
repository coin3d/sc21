#import <Foundation/Foundation.h>

@class SCController;

class SbRotation;
class SbMatrix;
class SbVec3f;
class SbViewportRegion;
class SoCamera;
class SoType;
class SoGroup;
class SoGetBoundingBoxAction;
class SoPerspectiveCamera;
class SoOrthographicCamera;

typedef enum _SCCameraType {
  SCCameraPerspective   = 0,
  SCCameraOrthographic  = 1
} SCCameraType;

@interface SCCamera : NSObject {
  SCController * _controller;
  SoCamera * _camera;
  SoGetBoundingBoxAction * _autoclipboxaction;
  BOOL _controllerhascreatedcamera;
}

/*" Initializing an SCCamera "*/
- (id) initWithSoCamera:(SoCamera *) camera controller:(SCController *) controller;

/*" Switching between orrthographic and perspective mode "*/
- (BOOL) isPerspective;
- (BOOL) isOrthographic;
- (void) convertToType:(SCCameraType)type;
- (void) cloneFromPerspectiveCamera:(SoOrthographicCamera *)orthocam;
- (void) cloneFromOrthographicCamera:(SoPerspectiveCamera *)perspectivecam;

/*" Positioning the camera "*/
- (void) zoom:(float) delta;
- (void) reorient:(SbRotation)rot;
- (void) viewAll;
- (void) updateClippingPlanes:(SoGroup *)scenegraph;

// internal
- (void) getCameraCoordinateSystem:(SbMatrix &)matrix inverse:(SbMatrix &)inverse;

/*" Accessors "*/ 
- (void) setController:(SCController *)ctrl;
- (SCController *) controller;
- (void) setSoCamera:(SoCamera *)c;
- (SoCamera *) soCamera;
- (void) setControllerHasCreatedCamera:(BOOL)yn;
- (BOOL) controllerHasCreatedCamera;
@end
