/* SCExaminerController */

#import <Cocoa/Cocoa.h>
#import "SCController.h"

class SoCamera;
class SoGroup;
class SbSphereSheetProjector;
class SbRotation;
class SbPlane;

class SbMatrix;
class SoType;
class SoDirectionalLight;


@interface SCExaminerController : SCController
{
  // Note that [super scenegraph] is the total scenegraph,
  // including a potential added camera and headlight,
  // while userscenegraph is the user supplied SG.

  NSPoint _lastmousepos;
  NSMutableArray * _mouselog;
  SoDirectionalLight * _headlight;  
  SbSphereSheetProjector * _spinprojector;
  SbRotation * _spinrotation;
  SoGroup * _userscenegraph;  
  BOOL _iswaitingforseek;  
}

/*" Initializing an SCExaminerController "*/
- (id) init;
- (void) awakeFromNib;

/*" Coin rendering and related functionality "*/
- (void) render;
- (void) setSceneGraph:(SoGroup *)sg;
- (void) setCameraType:(SCCameraType) type;
- (void) viewAll;

/*" Automatic headlight configuration "*/
- (SoDirectionalLight *) headlight;
- (BOOL) headlightIsOn;
- (void) setHeadlightIsOn:(BOOL) yn;

/*" Event handling "*/
- (BOOL) handleEventAsViewerEvent:(NSEvent *) event;

/*" Interaction with the viewer. "*/
- (void) startDragging:(NSValue *) v;
- (void) startPanning:(NSValue *) v;
- (void) performDragging:(NSValue *) v;
- (void) performPanning:(NSValue *) v;
- (void) performZoom:(NSValue *) v;
- (void) performSeek:(NSValue *) v;
- (void) performMove:(NSValue *) v;
- (void) ignore:(NSValue *) v;


/*" NSCoding conformance "*/
- (void) encodeWithCoder:(NSCoder *) coder;
- (id) initWithCoder:(NSCoder *) coder;


@end

/*" Notifications posted by SCExaminerController. "*/

extern NSString * SCViewAllNotification;
extern NSString * SCCameraTypeChangedNotification;
extern NSString * SCHeadlightChangedNotification;



