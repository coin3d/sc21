/* SCExaminerController */

#import <Cocoa/Cocoa.h>
#import "SCController.h"
#import "SCCamera.h"

class SoSeparator;
class SoCamera;
class SbSphereSheetProjector;
class SbRotation;
class SbPlane;
class SoGetBoundingBoxAction;
class SbMatrix;
class SoType;
class SoDirectionalLight;


@interface SCExaminerController : SCController
{
  // Note that [super scenegraph] is the total scenegraph,
  // including a potential added camera and headlight,
  // while userscenegraph is the user supplied SG.

  SCCamera * camera;
  NSPoint lastmousepos;
  NSMutableArray * mouselog;

  SoDirectionalLight * headlight;  
  SbSphereSheetProjector * spinprojector;
  SbRotation * spinrotation;
  SoSeparator * userscenegraph;  

  BOOL iswaitingforseek;  
  float autoclipvalue;
  enum AutoClipStrategy {
    CONSTANT_NEAR_PLANE,
    VARIABLE_NEAR_PLANE
  } autoclipstrategy;
}

/*" Actions "*/
- (IBAction) viewAll:(id)sender;
- (IBAction) toggleCameraType:(id)sender;
- (IBAction) toggleHeadlight:(id)sender;

/*" Initializing an SCExaminerController "*/
- (id) init;
- (void) awakeFromNib;

/*" Coin rendering and related functionality "*/
- (void) render;
- (void) setSceneGraph:(SoSeparator *)sg;
- (void) setCamera:(SoCamera *) camera;
- (SoCamera *) camera;

/*" Automatic headlight configuration "*/
- (SoDirectionalLight *) headlight;
- (BOOL) headlightIsOn;
- (void) setHeadlightIsOn:(BOOL) yn;

/*" Event handling "*/
- (void) handleEventAsViewerEvent:(NSEvent *) event;

/*" Interaction with the viewer. "*/
- (void) startDragging:(NSValue *) v;
- (void) startPanning:(NSValue *) v;
- (void) performDragging:(NSValue *) v;
- (void) performPanning:(NSValue *) v;
- (void) performZoom:(NSValue *) v;
- (void) performSeek:(NSValue *) v;
- (void) performMove:(NSValue *) v;
- (void) ignore:(NSValue *) v;

/*" Autoclipping "*/
- (void) setAutoClippingStrategy:(AutoClipStrategy)strategy value:(float)v;
- (float) bestValueForNearPlane:(float)near farPlane:(float) far;

/*" NSCoding conformance "*/
- (void) encodeWithCoder:(NSCoder *) coder;
- (id) initWithCoder:(NSCoder *) coder;


@end
