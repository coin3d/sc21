#import <Cocoa/Cocoa.h>
#import "SCEventConverter.h"

@class SCView;

class SoEvent;
class SoNode;
class SoSeparator;
class SoSceneManager;

@interface SCController : NSResponder
{
  IBOutlet SCView * view;
 
  SCEventConverter * _eventconverter;
  NSTimer * _timer;
  NSRect _viewframe;
  SoSeparator * scenegraph;	  // the whole scenegraph
  SoSceneManager * _scenemanager;
  BOOL _handleseventsinviewer;
}

/*" Static methods "*/
+ (void) initCoin;

/*" Actions "*/
- (IBAction) open:(id)sender; 
- (IBAction) toggleModes:(id)sender;


/*" Initializing an SCController "*/
- (id) init;
- (void) awakeFromNib;

/*" Getting the view associated with the controller "*/
- (SCView *) view;

/*" Coin rendering and related functionality "*/
- (void) setSceneGraph:(SoSeparator *)sg;
- (SoNode *) sceneGraph;
- (SoSceneManager *) sceneManager;
- (void) render;
- (void) setBackgroundColor:(NSColor *) color;
- (NSColor *) backgroundColor;
- (void) viewSizeChanged:(NSRect)size;
- (const SbViewportRegion &) viewportRegion;

/*" Debugging aids. "*/

- (NSString *) coinVersion;
- (void) dumpSceneGraph;

/*" Event handling "*/
- (void) handleEvent:(NSEvent *) event;
- (void) handleEventAsCoinEvent:(NSEvent *) event;
- (void) handleEventAsViewerEvent:(NSEvent *) event;
- (void) setHandlesEventsInViewer:(BOOL)yn;
- (BOOL) handlesEventsInViewer;

/*" NSCoding conformance "*/
- (void) encodeWithCoder:(NSCoder *) coder;
- (id) initWithCoder:(NSCoder *) coder;

/*" Delegate methods implemented by SCController "*/
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *) application;
- (void) openPanelDidEnd:(NSOpenPanel*)panel returnCode:(int)rc contextInfo:(void *) ctx;

@end

