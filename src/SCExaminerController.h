/* SCExaminerController */

#import <Cocoa/Cocoa.h>
#import "SCController.h"

class SbSphereSheetProjector;
class SbRotation;
class SoDirectionalLight;

@interface SCExaminerController : SCController
{
  NSPoint _lastmousepos;
  NSMutableArray * _mouselog;
  SoDirectionalLight * _headlight;  
  SbSphereSheetProjector * _spinprojector;
  SbRotation * _spinrotation;
  SoGroup * _userscenegraph;  // _scenegraph includes camera/headlight
  BOOL _iswaitingforseek;  
}

/*" Initializing an SCExaminerController "*/
- (id) init;
- (void) awakeFromNib;

/*" Coin rendering and related functionality "*/
- (void) render;
- (void) setSceneGraph:(SoGroup *)scenegraph;
- (void) setCameraType:(SCCameraType)type;
- (void) viewAll;

/*" Automatic headlight configuration "*/
- (SoDirectionalLight *) headlight;
- (BOOL) headlightIsOn;
- (void) setHeadlightIsOn:(BOOL)yn;

/*" Event handling "*/
- (BOOL) handleEventAsViewerEvent:(NSEvent *)event;

/*" Interaction with the viewer. "*/
- (void) startDragging:(NSValue *)v;
- (void) startPanning:(NSValue *)v;
- (void) performDragging:(NSValue *)v;
- (void) performPanning:(NSValue *)v;
- (void) performZoom:(NSValue *)v;
- (void) performSeek:(NSValue *)v;
- (void) performMove:(NSValue *)v;
- (void) ignore:(NSValue *)v;


/*" NSCoding conformance "*/
- (void) encodeWithCoder:(NSCoder *) coder;
- (id) initWithCoder:(NSCoder *) coder;


@end

/*" Notifications posted by SCExaminerController. "*/

extern NSString * SCViewAllNotification;
extern NSString * SCCameraTypeChangedNotification;
extern NSString * SCHeadlightChangedNotification;



