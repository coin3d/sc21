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
  BOOL _iswaitingforseek;  // currently unused
}

/*" Initializing and encoding/decoding an SCExaminerController "*/
- (id) init;
- (void) commonInit;
- (id) initWithCoder:(NSCoder *) coder;
- (void) encodeWithCoder:(NSCoder *) coder;

/*" Coin rendering and related functionality "*/
- (void) render;
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
- (void) performMove:(NSValue *)v;
- (void) ignore:(NSValue *)v;

@end


/*" Posted whenever the camera has been repositioned so that
    the whole scene can be seen.
 "*/
extern NSString * SCViewAllNotification;

/*" Posted whenever the camera type has been changed, i.e.
    when the camera has been from orthographic to perspective
    or vice versa.
 "*/
extern NSString * SCCameraTypeChangedNotification;

/*" Posted whenever the headlight has been turned on or off. "*/
extern NSString * SCHeadlightChangedNotification;

