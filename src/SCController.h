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

/*" Actions "*/
- (IBAction) open:(id)sender; 
- (IBAction) toggleModes:(id)sender;
- (IBAction) dumpSceneGraph:(id)sender;


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
- (void) setCamera:(SoCamera *) camera;
- (SoCamera *) camera;
- (SoCamera *) findCameraInSceneGraph: (SoGroup *) root;
- (SoLight *) findLightInSceneGraph:(SoGroup *) root;

/*" Debugging aids. "*/

- (NSString *) coinVersion;

/*" Event handling "*/
- (void) handleEvent:(NSEvent *) event;
- (void) handleEventAsCoinEvent:(NSEvent *) event;
- (void) handleEventAsViewerEvent:(NSEvent *) event;
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

/*" Delegate methods implemented by SCController "*/
- (void) openPanelDidEnd:(NSOpenPanel*)panel returnCode:(int)rc contextInfo:(void *) ctx;

@end


/*" Notifications posted by SCController. "*/

extern NSString * SCModeChangedNotification;
extern NSString * SCSceneGraphChangedNotification;


