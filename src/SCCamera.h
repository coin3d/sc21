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

/*" Possible camera types in the scene graph.
    !{SCCameraPerspective} describes an !{SoPerspectiveCamera},
    and !{SCCameraOrthographic} means an !{SoOrthographicCamera}.
    All other camera types are currently !{SCCameraUnknown}.
 "*/

typedef enum _SCCameraType {
  SCCameraUnknown 	= -1,
  SCCameraPerspective   =  0,
  SCCameraOrthographic  =  1
} SCCameraType;

@interface SCCamera : NSObject {
  SCController * _controller;
  SoCamera * _camera;
  SoGetBoundingBoxAction * _autoclipboxaction;
  BOOL _controllerhascreatedcamera;
}

/*" Initializing an SCCamera "*/
- (id) initWithSoCamera:(SoCamera *) camera controller:(SCController *) controller;

/*" Switching between orthographic and perspective mode "*/
- (SCCameraType) type;
- (BOOL) convertToType:(SCCameraType)type;

/*" Positioning the camera "*/
- (void) zoom:(float) delta;
- (void) reorient:(SbRotation)rot;
- (void) viewAll;
- (void) updateClippingPlanes:(SoGroup *)scenegraph;

/*" Accessors "*/ 
- (void) setController:(SCController *)controller;
- (SCController *) controller;
- (void) setSoCamera:(SoCamera *)c deleteOldCamera:(BOOL)deletecamera;
- (SoCamera *) soCamera;
- (void) setControllerHasCreatedCamera:(BOOL)yn;
- (BOOL) controllerHasCreatedCamera;
@end
