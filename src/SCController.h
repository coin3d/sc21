#import <Cocoa/Cocoa.h>
#import "SCEventConverter.h"
#import "SCCamera.h"

@class SCView;

class SoCamera;
class SoGroup;
class SoLight;
class SoSceneManager;

@interface SCController : NSResponder
{
  IBOutlet SCView * view;
  SCCamera * _camera;
  SCEventConverter * _eventconverter;
  NSTimer * _timerqueuetimer;
  NSTimer * _delayqueuetimer;
  SoGroup * _scenegraph;	  // the whole scenegraph
  SoSceneManager * _scenemanager;
  BOOL _handleseventsinviewer;
  float _autoclipvalue;
}

/*" Static initialization "*/
+ (void) initCoin;

/*" Initializing and encoding/decoding an SCController "*/
- (id) init;
- (id) initWithCoder:(NSCoder *)coder;
- (void) commonInit;
- (void) awakeFromNib;
- (void) encodeWithCoder:(NSCoder *)coder;

/*" Getting the view associated with the controller "*/
- (void) setView:(SCView *) view;
- (SCView *) view;

/*" Coin rendering and related functionality "*/
- (void) render;
- (void) setSceneGraph:(SoGroup *)scenegraph;
- (SoGroup *) sceneGraph;
- (SoSceneManager *) sceneManager;
- (void) setBackgroundColor:(NSColor *)color;
- (NSColor *) backgroundColor;
- (void) viewSizeChanged:(NSRect)size;
- (const SbViewportRegion &)viewportRegion;
- (SoLight *) findLightInSceneGraph:(SoGroup *)root;

/*" Camera handling. "*/
- (void) setCamera:(SoCamera *)camera;
- (SoCamera *) camera;
- (SCCameraType) cameraType; // see SCCamera.h for SCCameraType enum
- (SoCamera *) findCameraInSceneGraph:(SoGroup *)root;

/*" Debugging aids. "*/
- (NSString *) debugInfo;
- (BOOL) dumpSceneGraph;

/*" Event handling "*/
- (BOOL) handleEvent:(NSEvent *)event;
- (BOOL) handleEventAsCoinEvent:(NSEvent *)event;
- (BOOL) handleEventAsViewerEvent:(NSEvent *)event;
- (void) setHandlesEventsInViewer:(BOOL)yn;
- (BOOL) handlesEventsInViewer;

/*" Timer management. "*/
- (void) stopTimers;
- (void) setTimerInterval:(NSTimeInterval)interval;
- (NSTimeInterval) timerInterval;
- (void) setDelayQueueInterval:(NSTimeInterval)interval;
- (NSTimeInterval) delayQueueInterval;


  /*" Autoclipping "*/
- (float) bestValueForNearPlane:(float)near farPlane:(float)far;

@end


/*" Notifications posted by SCController. "*/

extern NSString * SCModeChangedNotification;
extern NSString * SCSceneGraphChangedNotification;
extern NSString * SCNoCameraFoundInSceneNotification;
extern NSString * SCNoLightFoundInSceneNotification;
