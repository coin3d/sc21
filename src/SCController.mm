#import "SCController.h"
#import "SCView.h"

#import <Inventor/SoDB.h>
#import <Inventor/SoInteraction.h>
#import <Inventor/SoSceneManager.h>
#import <Inventor/SbViewportRegion.h>
#import <Inventor/actions/SoGLRenderAction.h>
#import <Inventor/actions/SoWriteAction.h>
#import <Inventor/manips/SoHandleBoxManip.h>
#import <Inventor/nodekits/SoNodeKit.h>
#import <Inventor/nodes/SoCone.h>
#import <Inventor/nodes/SoDrawStyle.h>
#import <Inventor/nodes/SoTranslation.h>
#import <Inventor/nodes/SoSelection.h>
#import <Inventor/nodes/SoSeparator.h>
#import <Inventor/nodes/SoRotor.h>
#import <Inventor/nodes/SoCylinder.h>
#import <Inventor/nodes/SoSphere.h>

#import <OpenGL/gl.h>

@interface SCController (InternalAPI)
- (void) _idle:(NSTimer *)t; 	// _timer callback function
@end  


// -------------------- Callback function ------------------------

static void
redraw_cb(void * user, SoSceneManager * manager) {
  SCView * view = (SCView *) user;
  [view drawRect:[view frame]];
  // FIXME: according to the Apple docs, I should not call drawRect but
  // rather setNeedsDisplay:YES. If I do that, I get an "invalid drawable"
  // error and a black screen. Cocoa bug? Investigate. kyrah 20030529
}

              
              
@implementation SCController

/*" An SCController is the main component for rendering Coin 
    scenegraphs to an SCView. It handles all actual scene management, 
    rendering, event translation etc.
    
    Note that for displaying the rendered scene, you need an SCView.
    Connect SCController's !{view} outlet to a valid SCView instance
    to use SCController.
 "*/
 
 
 
// --------------------- actions -----------------------------


/*" Toggles whether events should be interpreted as viewer events, i.e.
    if they should be regarded as input for controlling the viewer or 
    sent to the scene graph directly. Calls #setHandlesEventsInViewer:
"*/

- (IBAction) toggleModes:(id)sender
{
  [self setHandlesEventsInViewer:([self handlesEventsInViewer] ? NO : YES)];
}


/*" Displays a standard file open dialog. "*/

- (IBAction)open:(id)sender
{
  NSOpenPanel * panel = [NSOpenPanel openPanel];
  [panel beginSheetForDirectory:nil
                           file:nil
                          types:nil
                 modalForWindow:[view window]
                  modalDelegate:self
                 didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
                    contextInfo:nil];
}


// ----------------- initialization and cleanup ----------------------

/*" Initializes a newly allocated SCController, and calls #initCoin:
    By default, events will be interpreted as viewer events (see 
    #handleEvent: documentation for more information about
    the event handling model).

    This method is the designated initializer for the SCController
    class. Returns !{self}.
 "*/

- (id) init
{
  if (self = [super init]) {
    _handleseventsinviewer = YES;
    _eventconverter = [[SCEventConverter alloc] initWithController:self];
    [self initCoin];
  }
  return self;
}

/*" Initalizes Coin. "*/

- (void) initCoin
{
  SoDB::init();
  SoInteraction::init();
  SoNodeKit::init();
}

/*" Sets up and activates a Coin scene manager. Sets up and schedules
    a timer for animation. Adds default entries to the context menu.
    Registers the SCController object as delegate to NSApp.
    Called after the object has been 
    loaded from an Interface Builder archive or nib file. 
"*/

- (void) awakeFromNib
{
  _scenemanager = new SoSceneManager;
  _scenemanager->setRenderCallback(redraw_cb, (void*) view);
  _scenemanager->setBackgroundColor(SbColor(0.0f, 0.0f, 0.0f));
  _scenemanager->activate();

  // Register ourselves as delegate. Needed to be able to quit the 
  // application when the last window is closed.
  [NSApp setDelegate:self];  
     
  if (scenegraph == NULL) {
    SoSeparator * root = new SoSeparator;
    [self setSceneGraph:root];
  }
    
  _timer = [[NSTimer scheduledTimerWithTimeInterval:0 target:self
    selector:@selector(_idle:) userInfo:nil repeats:YES] retain];
  [[NSRunLoop currentRunLoop] addTimer:_timer
                               forMode:NSModalPanelRunLoopMode];
  [[NSRunLoop currentRunLoop] addTimer:_timer
                               forMode:NSEventTrackingRunLoopMode];

  [view addMenuEntry:@"open file" target:self action:@selector(open:)];
  [view addMenuEntry:@"toggle mode" target:self action:@selector(toggleModes:)];
  [view addMenuEntry:@"show debug info" target:view action:@selector(debugInfo:)];
  
}

/* Clean up after ourselves. */
- (void) dealloc
{
  [_timer invalidate];
  [_timer release];
  [_eventconverter release];
  scenegraph->unref();
  delete _scenemanager;
  [super dealloc];
}


// ------------ getting the view associated with the controller -------

/*" Returns the SCView the SCController's view outlet is connected to. "*/

- (SCView *) view 
{ 
  return view; 
}


// ------------------- rendering and scene management ---------------------

/*" Sets the scene graph that shall be rendered. The reference count of
    sg will be increased by 1 before use, so you there is no need to 
    !{ref()} the node before passing it to this method.
 "*/
    
- (void) setSceneGraph:(SoSeparator *)sg
{
  sg->ref();
  if (scenegraph) scenegraph->unref();
  scenegraph = sg;
  _scenemanager->setSceneGraph(scenegraph);
  [view setNeedsDisplay:YES];
}

/*" Returns the current scene graph used for rendering. "*/

- (SoNode *) sceneGraph 
{ 
  return scenegraph; 
}

/*" Returns the current Coin scene manager instance. "*/

- (SoSceneManager *) sceneManager 
{ 
  return _scenemanager; 
}


/*" Returns the viewport region used by Coin's GL render action. "*/

- (const SbViewportRegion &) viewportRegion
{
  assert (_scenemanager);
  SoGLRenderAction * a = _scenemanager->getGLRenderAction();
  return a->getViewportRegion();
}


/*" Renders the scene. "*/

- (void) render
{
  _scenemanager->render();
}

/*" Sets the background color of the scene to color. Raises an exception if
    color is not an RGB color.
 "*/

- (void) setBackgroundColor:(NSColor *) color
{
  float red = [color redComponent];
  float green = [color greenComponent];
  float blue = [color blueComponent];

  _scenemanager->setBackgroundColor(SbColor(red, green, blue));
  [view setNeedsDisplay:YES];
}

/*" Returns the scene's background color. "*/

- (NSColor *) backgroundColor
{
  SbColor sbcolor = _scenemanager->getBackgroundColor();
  float red = sbcolor[0];
  float green = sbcolor[1];
  float blue = sbcolor[2];
  
  NSColor * color = [NSColor colorWithDeviceRed:red
                                        green:green
                                         blue:blue
                                        alpha:1];
  return color;	
}

/*" This method is called when %view's size has been changed. 
    It makes the necessary adjustments for the new size in 
    the Coin subsystem.
 "*/

- (void) viewSizeChanged:(NSRect)rect
{
  // FIXME: Shouldn't we use notifications here? kyrah 20030614
  int w = (GLint)(rect.size.width);
  int h = (GLint)(rect.size.height);
  _scenemanager->setWindowSize(SbVec2s(w, h));
  _scenemanager->setSize(SbVec2s(w, h));
  _scenemanager->setViewportRegion(SbViewportRegion(w, h));
  _scenemanager->scheduleRedraw();  
}



// ------------------------ event handling -------------------------

/*" Handles event by either converting it to an %SoEvent and 
    passing it on to the scenegraph via #handleEventAsCoinEvent:, 
    or handle it in the viewer itself via #handleEventAsViewerEvent: 
    to allow examination of the scene (spinning, panning, zoom etc.)
    
    How events are treated can be controlled via the 
    #setHandlesEventsInViewer: method.
    
    All events are sent from %view to the controller via the
    #handleEvent: message. 
    Note that this is a different approach from the one taken in
    NSView and its subclasses, which handle events directly. 
"*/
 
- (void) handleEvent:(NSEvent *) event
{
  if ([self handlesEventsInViewer] == NO) {
    [self handleEventAsCoinEvent:event];
  } else {
    [self handleEventAsViewerEvent:event];
  }
}

/*" Handles event as Coin event, i.e. creates an SoEvent and passes 
    it on to the scenegraph. 
 "*/
 
- (void) handleEventAsCoinEvent:(NSEvent *) event
{
  SoEvent * se = [_eventconverter createSoEvent:event];
  if (se) {
    _scenemanager->processEvent(se);
    delete se;
  }
}

/*" Handles event as viewer event, i.e. does not send it to the scene
    graph but interprets it as input for controlling the viewer. 
 
    The default implementation does nothing. Use SCExaminerController
    to get built-in functionality for examining the scene (camera
    control through the mouse etc.).
 "*/
 
- (void) handleEventAsViewerEvent:(NSEvent *) event
{
  // default does nothing
}

/*" Sets whether events should be interpreted as viewer events, i.e.
    are regarded as input for controlling the viewer (yn == YES), or 
    should be sent to the scene graph directly (yn = NO) 
"*/
 
- (void) setHandlesEventsInViewer:(BOOL)yn
{
  _handleseventsinviewer = yn;
}


/*" Returns TRUE if events are interpreted as viewer events, i.e.
    are regarded as input for controlling the viewer. Returns 
    FALSE if events are sent to the scene graph directly.
 "*/

- (BOOL) handlesEventsInViewer
{
  return _handleseventsinviewer;
}



// ----------------- Debugging aids ----------------------------

/*" Returns a human-readable string describing the version of
    Coin we are using. Note: This information is determined at run-time,
    not at link-time.
 "*/

- (NSString *) coinVersion
{
  const char * versionstring = SoDB::getVersion();
  return [NSString stringWithCString:versionstring];
}


/*" Writes the current scenegraph to a file. The filename will be
    XXX-dump.iv, where XXX is a number calculated based on the
    current time. The file will be stored in the current working
    directory.
"*/

- (void) dumpSceneGraph
{
  SoOutput out;
  SbString filename = SbTime::getTimeOfDay().format();
  filename += "-dump.iv";
  SbBool ok = out.openFile(filename.getString());
  if (!ok) {
    NSString * error = [NSString stringWithFormat:@"Could not open file '%s'",
      filename.getString()];
    [view displayError:error];
    return;
  }
  SoWriteAction wa(&out);
  wa.apply(scenegraph);
  NSString * info = [NSString stringWithFormat:@"Dumped scene to file '%s'",
    filename.getString()];
  [view displayInfo:info];
}


// ------------------------ NSApp delegate methods -------------------------


/*" Delegate implementation: Returns YES to make the application quit 
    when its last window is closed. 
 "*/
- (BOOL)applicationShouldTerminateAfterLastWindowClosed: (NSApplication *)application
{
  return YES;
}

/*" Delegate method for NSOpenPanel used in #open: 
    Tries to read scene data from the file and sets the scenegraph to 
    the read root node. If reading fails for some reason, an error message
    is displayed, and the current scene graph is not changed.
 "*/
 
- (void) openPanelDidEnd:(NSOpenPanel*)panel returnCode:(int)rc contextInfo:(void *) ctx
{

  if (rc == NSOKButton) {
    NSString * path = [panel filename];
    SoInput in;
    if (!in.openFile([path cString])) {
      [view displayError:[NSString stringWithFormat:@"Could not open file %@", path]];
      return;
    }
    SoSeparator * sg = SoDB::readAll(&in);
    in.closeFile();
    if (!sg) {
      [view displayError:[NSString stringWithFormat:@"Could not read file %@", path]];
    } else {
       [self setSceneGraph:sg];    
    }
  }
}


// ---------------- NSCoder conformance -------------------------------

/*" Encodes the SCController using encoder coder "*/

- (void) encodeWithCoder:(NSCoder *) coder
{
  [super encodeWithCoder:coder];
  // FIXME: Encode members. kyrah 20030618
}

/*" Initializes a newly allocated SCController instance from the data
    in decoder. Returns !{self} "*/
    
- (id) initWithCoder:(NSCoder *) coder
{
  if (self = [super initWithCoder:coder]) {
    _handleseventsinviewer = YES;
    _eventconverter = [[SCEventConverter alloc] initWithController:self];
    [self initCoin];
  }
  return self;
}


// ----------------------- InternalAPI -------------------------

/* Timer callback function: process the sensor manager queues. */

- (void) _idle:(NSTimer *)t
{
  SoDB::getSensorManager()->processTimerQueue();
  SoDB::getSensorManager()->processDelayQueue(TRUE);
}



@end



