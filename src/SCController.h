#import <Cocoa/Cocoa.h>
#import "SCEventConverter.h"
#import "SCCamera.h"

@class SCView;

class SoCamera;
class SoGroup;
class SoEvent;
class SoLight;
class SoSeparator;
class SoSceneManager;
class SoGetBoundingBoxAction;

@interface SCController : NSResponder
{
  IBOutlet SCView * view;

  SCCamera * _camera;
  SCEventConverter * _eventconverter;
  NSTimer * _timerqueuetimer;
  NSTimer * _delayqueuetimer;
  NSRect _viewframe;
  SoGroup * _scenegraph;	  // the whole scenegraph
  SoSceneManager * _scenemanager;
  BOOL _handleseventsinviewer;
  float _autoclipvalue;
  enum AutoClipStrategy {
    CONSTANT_NEAR_PLANE,
    VARIABLE_NEAR_PLANE
  } _autoclipstrategy;
}

/*" Static methods "*/
+ (void) initCoin;

/*" Initializing an SCController "*/
- (id) init;
- (void) awakeFromNib;

/*" Getting the view associated with the controller "*/
- (SCView *) view;

/*" Coin rendering and related functionality "*/
- (void) setSceneGraph:(SoGroup *)sg;
- (SoGroup *) sceneGraph;
- (SoSceneManager *) sceneManager;
- (void) render;
- (void) setBackgroundColor:(NSColor *) color;
- (NSColor *) backgroundColor;
- (void) viewSizeChanged:(NSRect)size;
- (const SbViewportRegion &) viewportRegion;
- (SoLight *) findLightInSceneGraph:(SoGroup *) root;

/*" Camera handling. "*/
- (void) setCamera:(SoCamera *) camera;
- (SoCamera *) camera;
- (SCCameraType) cameraType;
- (SoCamera *) findCameraInSceneGraph: (SoGroup *) root;

/*" Debugging aids. "*/
- (NSString *) coinVersion;
- (void) debugInfo;
- (void) dumpSceneGraph;

/*" Event handling "*/
- (BOOL) handleEvent:(NSEvent *) event;
- (BOOL) handleEventAsCoinEvent:(NSEvent *) event;
- (BOOL) handleEventAsViewerEvent:(NSEvent *) event;
- (void) setHandlesEventsInViewer:(BOOL)yn;
- (BOOL) handlesEventsInViewer;

/*" Timer management. "*/
- (void) stopTimers;
- (void) setTimerInterval:(NSTimeInterval)interval;
- (NSTimeInterval) timerInterval;
- (void) setDelayQueueInterval:(NSTimeInterval)interval;
- (NSTimeInterval) delayQueueInterval;

/*" NSCoding conformance "*/
- (void) encodeWithCoder:(NSCoder *) coder;
- (id) initWithCoder:(NSCoder *) coder;

  /*" Autoclipping "*/
- (void) setAutoClippingStrategy:(AutoClipStrategy)strategy value:(float)v;
- (float) bestValueForNearPlane:(float)near farPlane:(float) far;

@end


/*" Notifications posted by SCController. "*/

extern NSString * SCModeChangedNotification;
extern NSString * SCSceneGraphChangedNotification;
extern NSString * SCNoCameraFoundInSceneNotification;
extern NSString * SCNoLightFoundInSceneNotification;


