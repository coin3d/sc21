/* ============================================================== *
 |                                                                |
 | This file is part of SC21, a Cocoa user interface binding for  |
 | the Coin 3D visualization library.                             |
 |                                                                |
 | Copyright (c) 2003 Systems in Motion. All rights reserved.     |
 |                                                                |
 | SC21 is free software; you can redistribute it and/or          |
 | modify it under the terms of the GNU General Public License    |
 | ("GPL") version 2 as published by the Free Software            |
 | Foundation.                                                    |
 |                                                                |
 | A copy of the GNU General Public License can be found in the   |
 | source distribution of SC21. You can also read it online at    |
 | http://www.gnu.org/licenses/gpl.txt.                           |
 |                                                                |
 | For using Coin with software that can not be combined with the |
 | GNU GPL, and for taking advantage of the additional benefits   |
 | of our support services, please contact Systems in Motion      |
 | about acquiring a Coin Professional Edition License.           |
 |                                                                |
 | See http://www.coin3d.org/mac/SC21 for more information.       |
 |                                                                |
 | Systems in Motion, Bygdoy Alle 5, 0257 Oslo, Norway.           |
 |                                                                |
 * ============================================================== */
 

#import <SC21/SCController.h>
#import <SC21/SCEventConverter.h>

#import <Inventor/SoDB.h>
#import <Inventor/SoInteraction.h>
#import <Inventor/SoSceneManager.h>
#import <Inventor/SbViewportRegion.h>
#import <Inventor/actions/SoGLRenderAction.h>
#import <Inventor/actions/SoSearchAction.h>
#import <Inventor/actions/SoWriteAction.h>
#import <Inventor/elements/SoGLCacheContextElement.h>
#import <Inventor/nodekits/SoBaseKit.h>
#import <Inventor/nodekits/SoNodeKit.h>
#import <Inventor/nodes/SoCamera.h>
#import <Inventor/nodes/SoLight.h>
#import <Inventor/nodes/SoSeparator.h>

#import <OpenGL/gl.h>

/*" Provide interface for deaction of NSTimer instance.  The
    current implementation sets the timer's fireDate to
    "distantFuture" (cf. NSDate) but hopefully activation and
    deactivation will be supported in the timer itself in the
    future.
 "*/

@interface NSTimer (SC21Extensions)
- (void)deactivate;
- (BOOL)isActive;
@end

@implementation NSTimer (SC21Extensions)

- (void)deactivate
{
  [self setFireDate:[NSDate distantFuture]];
}

- (BOOL)isActive
{
  // A timer is "active" if its fire date is less than 10000 seconds from now.
  // Note that we cannot compare for "== distantFuture" here, since distantFuture
  // is "current time + a high number" (i.e. the actual date changes with time)
  return ([self fireDate] < [NSDate dateWithTimeIntervalSinceNow:10000]);
}
@end

@interface SCController (InternalAPI)
- (void)_timerQueueTimerFired:(NSTimer *)t;
- (void)_sensorQueueChanged;
- (SoLight *)_findLightInSceneGraph:(SoGroup *)root;
- (SoCamera *)_findCameraInSceneGraph:(SoGroup *)root;
- (void)_setInternalSceneGraph:(SoGroup *)root;
- (void)_handleLighting;
- (void)_handleCamera;
- (NSPoint)_normalizePoint:(NSPoint)point;
- (void)_setupRedrawInvocation;
@end  


// -------------------- Callback function ------------------------

static void
redraw_cb(void * user, SoSceneManager *)
{
  SCController * selfp = (SCController *)user; 
  [selfp->_redrawinv invoke];
}

static void
sensorqueuechanged_cb(void * data)
{
  // NSLog(@"sensorqueuechanged_cb");
  SCController * ctrl = (SCController *)data;
  [ctrl _sensorQueueChanged];
}

// ---------------------- Notifications ----------------------------

NSString * SCModeChangedNotification = @"SCModeChangedNotification";
NSString * SCSceneGraphChangedNotification = @"SCSceneGraphChangedNotification";
NSString * SCNoCameraFoundInSceneNotification = @"SCNoCameraFoundInSceneNotification";
NSString * SCNoLightFoundInSceneNotification = @"SCNoLightFoundInSceneNotification";
NSString * SCRedrawNotification = @"SCRedrawNotification";

// internal
NSString * _SCIdleNotification = @"_SCIdleNotification";

@implementation SCController

/*" An SCController is the main component for rendering Coin 
    scenegraphs. It handles all actual scene management, 
    rendering, event translation etc.

    Note that since Coin is a data driven API, redraws can be
    requested by the scene graph itself. To handle these redraws,
    the controller must be given an object and a selector that should
    called upon such a redraw request. This is automatically handled
    by SCView but if you want to use an SCController without having 
    an SCView (e.g. when doing fullscreen rendering), you should 
    setup this yourself using -setRedrawHandler and -setRedrawSelector.
 "*/


/*" Initializes Coin by calling !{SoDB::init()},
    !{SoInteraction::init()} and !{SoNodeKit::init()}.

    Call this method if you want to use Coin
    functionality before actually instantiating an SCController in your
    application (e.g. if you want to read a 3D models using SoDB::readAll()
    and load the nib file containing your SCView and SCController only
    if the file was read successfully). SCController's initializer
    automatically calls this function if needed. 
"*/
+ (void)initCoin
{       
  // This is _not_ done in +initialize since we want to allow people
  // to do smth. before initializing Coin.
  static BOOL initialized = NO;
  if (!initialized) {
    SoDB::init();
    SoInteraction::init();
    SoNodeKit::init();
    SoDB::setRealTimeInterval(SbTime(1/60.0));
    initialized = YES;
  }
}
 
// ----------------- initialization and cleanup ----------------------

/*" Initializes a newly allocated SCController, and calls #initCoin
    By default, events will be interpreted as viewer events (see 
    #handleEvent: documentation for more information about
    the event handling model).

    This method is the designated initializer for the SCController
    class. Returns !{self}.
 "*/

- (id)init
{
  if (self = [super init]) {
    _autoclipvalue = 0.6;
    _handleseventsinviewer = YES;
    [self commonInit];
  }
  return self;
}


/*" Shared initialization code that is called both from #init:
    and #initWithCoder: If you override this method, you must
    call !{[super commonInit]} as the first call in your
    implementation to make sure everything is set up properly.
"*/
//FIXME: We should be able to move most of the contents of this method
// to -init and archive/unarchive the aggregated instance variables.
// (kintel 20040406)
- (void)commonInit
{
  [SCController initCoin];
  _camera = [[SCCamera alloc] init];
  [_camera setController:self];
  _eventconverter = [[SCEventConverter alloc] init];
  _redrawsel = @selector(display);

  [self setSceneManager:new SoSceneManager];

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
    selector:@selector(_idle:) name:_SCIdleNotification
    object:self];

  [self _sensorQueueChanged];
}

/* Clean up after ourselves. */
- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self stopTimers];
  _redrawhandler = nil;
  [self _setupRedrawInvocation];
  [_eventconverter release];
  [_camera release];
  delete _scenemanager;
  [super dealloc];
}

/*!
  Sets the object that should handle redraw messages generated
  by the scene graph.

  This is automatically set by SCView.setController and should only
  need to be set when not rendering into an SCView (e.g. when doing
  fullscreen rendering).
*/
- (void)setRedrawHandler:(id)handler
{
  _redrawhandler = handler;
  [self _setupRedrawInvocation];
}

/*!
  Sets the selector to be performed on the object set by -setRedrawHandler.

  This defaults to @selector(display), but can be changed to any selector
  with and optional id argument. If an id argument exists, this controller
  object will be sent.

  If the given selector doesn't conform, an NSInvalidArgumentException
  will be raised.
*/
- (void)setRedrawSelector:(SEL)sel
{
  _redrawsel = sel;
  [self _setupRedrawInvocation];
}

// ------------------- rendering and scene management ---------------------

/*" Sets the scene graph that shall be rendered. You do not need to 
    !{ref()} the node before passing it to this method. If sg is NULL,
    an empty scenegraph consisting of a single SoSeparator node will
    be created and set. 

    Note that the scenegraph is not modified in any way, i.e. you must
    set up your own headlight and camera to be able to see anything. For
    automatic setup of a camera and headlight if needed, use the
    #SCExaminerController class.

    If no light is found in the scenegraph, an
    %SCNoLightFoundInSceneNotification notification is posted. If no
    camera is found in the scenegraph, an
    %SCNoCameraFoundInSceneNotification is posted. Register for these
    notifications if you want to warn your users that they will not be
    able to see anything.
 "*/

- (void)setSceneGraph:(SoGroup *)scenegraph
{
  NSLog(@"SetSceneGraph called with %p", scenegraph);
  if (scenegraph == _scenegraph) return;
  if (scenegraph == NULL) {
    scenegraph = new SoSeparator;
    [self stopTimers];   // Don't waste cycles by animating an empty scene. 
  } else {
    [self startTimers];
  }

  [self _setInternalSceneGraph:scenegraph];
  [self _handleLighting];
  [self _handleCamera];

  if (_scenemanager) {
    _scenemanager->setSceneGraph(_scenegraph);
    [_camera updateClippingPlanes:_scenegraph];
  }

  [[NSNotificationCenter defaultCenter]
    postNotificationName:SCSceneGraphChangedNotification object:self];
}

/*" Returns the current scene graph used for rendering. "*/

- (SoGroup *)sceneGraph 
{ 
  return _scenegraph; 
}

/*" Sets the current scene manager to scenemanager. The scene manager's
    render callback will be set to %redraw_cb (SCController's default
    redraw callback), and it will be activated. Also, if a scenegraph
    has been set earlier, scenemanager's scenegraph will be set to it.

    Note that you should not normally need to call that method, since a
    scene manager is created for you in #commonInit
 "*/

- (void)setSceneManager:(SoSceneManager *)scenemanager
{
  //FIXME: Keep old background color if set? (kintel 20040406)
  _scenemanager = scenemanager;
  _scenemanager->setRenderCallback(redraw_cb, (void *)self);
  SoGLRenderAction * glra = _scenemanager->getGLRenderAction();
  glra->setCacheContext(SoGLCacheContextElement::getUniqueCacheContext());
  glra->setTransparencyType(SoGLRenderAction::DELAYED_BLEND);
  _scenemanager->activate();
  if (_scenegraph) _scenemanager->setSceneGraph(_scenegraph);
}

/*" Returns the current Coin scene manager instance. "*/

- (SoSceneManager *)sceneManager 
{ 
  return _scenemanager; 
}

/*" Sets the autoclip value to value. The default value is 0.6.

    This value influences the automatic setting of the near and
    far clipping plane. The default should be good enough in most 
    cases, so if you do not know what this means, don't worry.
    If you are interested, check out the code in
    !{- (float) _bestValueForNearPlane:(float)near farPlane:(float) far}
    in SCCamera.
 "*/

- (void)setAutoClipValue:(float)autoclipvalue
{
  _autoclipvalue = autoclipvalue;
}

/*" Returns the current autoclipvalue. The default value is 0.6. "*/

- (float)autoClipValue
{
  return _autoclipvalue;
}


/*" Sets the SoCamera used for viewing the scene to cam.
    It is first checked if the scenegraph contains a camera created by
    the controller, and if yes, this camera is deleted.

    Note that cam is expected to be part of the scenegraph already;
    it is not inserted into it.
"*/

- (void)setCamera:(SoCamera *)cam
{
  [_camera setSoCamera:cam deleteOldCamera:YES];
}

/*" Returns the current SoCamera used for viewing. "*/

- (SoCamera *)camera
{
  return [_camera soCamera];
}

/*" Returns !{SCCameraPerspective} if the camera is perspective
    and !{SCCameraOrthographic} if the camera is orthographic.
 "*/

- (SCCameraType)cameraType
{
  return [_camera type];
}

/*" Renders the scene. "*/

- (void)render
{
  //FIXME: Make clearing of color and depth buffer configurable?
  //(kintel 20040429)
  //FIXME: Do clearing here instead of in SoSceneManager to support
  // alpha values? (kintel 20040502)
  _scenemanager->render();
}

/*" Sets the background color of the scene to color. Raises an exception if
    color cannot be converted to an RGB color.
 "*/

- (void)setBackgroundColor:(NSColor *)color
{
  NSColor * rgb = [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
  if (!rgb) {
    [NSException raise:NSInternalInconsistencyException
                 format:@"setBackgroundColor: Color not convertible to RGB"];
  }
  
  float red, green, blue;
  [color getRed:&red green:&green blue:&blue alpha:NULL];
  
  _scenemanager->setBackgroundColor(SbColor(red, green, blue));
  _scenemanager->scheduleRedraw();  
}

/*" Returns the scene's background color. "*/

- (NSColor *)backgroundColor
{
  SbColor sbcolor = _scenemanager->getBackgroundColor();
  NSColor * color = [NSColor colorWithCalibratedRed:sbcolor[0]
                             green:sbcolor[1] 
                             blue:sbcolor[2] 
                             alpha:0.0f];
  return color;	
}

/*" This method is called when %view's size has been changed. 
    It makes the necessary adjustments for the new size in 
    the Coin subsystem.
 "*/

- (void)viewSizeChanged:(NSRect)rect
{
  _viewrect = rect;
  if (!_scenemanager) return;
  int w = (GLint)(rect.size.width);
  int h = (GLint)(rect.size.height);
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

    Returns !{YES} if the event has been handled, !{NO} otherwise. 

    All events are sent from %view to the controller via the
    #handleEvent: message. 
    Note that this is a different approach from the one taken in
    NSView and its subclasses, which handle events directly.

    For overriding the default behavior of ctrl-clicks (context menu),
    see -SCView.mouseDown:
"*/
 
- (BOOL)handleEvent:(NSEvent *)event inView:(NSView *)view
{
  if ([self handlesEventsInViewer] == NO) {
    return [self handleEventAsCoinEvent:event inView:view];
  } else {
    return [self handleEventAsViewerEvent:event inView:view];
  }
}

/*" Handles event as Coin event, i.e. creates an SoEvent and passes 
    it on to the scenegraph.

    Returns !{YES} if the event has been handled, !{NO} otherwise.
 "*/
 
- (BOOL)handleEventAsCoinEvent:(NSEvent *)event inView:(NSView *)view
{
  SoEvent * se = [_eventconverter createSoEvent:event inView:view];
  if (se) {
    BOOL handled = _scenemanager->processEvent(se);
    delete se;
    return handled;
  }
  return NO;
}

/*" Handles event as viewer event, i.e. does not send it to the scene
    graph but interprets it as input for controlling the viewer. 

    Returns !{YES} if the event has been handled, !{NO} otherwise.

    The default implementation does nothing and returns !{NO}.
 "*/
 
- (BOOL)handleEventAsViewerEvent:(NSEvent *)event inView:(NSView *)view
{
  return NO;
}

/*" Sets whether events should be interpreted as viewer events, i.e.
    are regarded as input for controlling the viewer (yn == YES), or 
    should be sent to the scene graph directly (yn = NO) 
"*/
 
- (void)setHandlesEventsInViewer:(BOOL)yn
{
  _handleseventsinviewer = yn;
  [[NSNotificationCenter defaultCenter] 
    postNotificationName:SCModeChangedNotification object:self];
}


/*" Returns TRUE if events are interpreted as viewer events, i.e.
    are regarded as input for controlling the viewer. Returns 
    FALSE if events are sent to the scene graph directly.
 "*/

- (BOOL)handlesEventsInViewer
{
  return _handleseventsinviewer;
}

// -------------------- Timer management. ----------------------


/*" Stops and releases the timers for timer queue and delay queue
    processing.
 "*/

- (void)stopTimers
{
  if (_timerqueuetimer && [_timerqueuetimer isValid]) {
    [_timerqueuetimer invalidate];
    _timerqueuetimer = nil;
  }
  SoDB::getSensorManager()->setChangedCallback(NULL, NULL);
}

- (void)startTimers
{
  if (_timerqueuetimer != nil) return;

  // The timer will be controller from _sensorQueueChanged,
  // so don't activate it yet.
  _timerqueuetimer = [NSTimer scheduledTimerWithTimeInterval:1000
                              target:self
                              selector:@selector(_timerQueueTimerFired:) 
                              userInfo:nil 
                              repeats:YES];
  [_timerqueuetimer deactivate];
  [[NSRunLoop currentRunLoop] addTimer:_timerqueuetimer 
                              forMode:NSModalPanelRunLoopMode];
  [[NSRunLoop currentRunLoop] addTimer:_timerqueuetimer 
                              forMode:NSEventTrackingRunLoopMode];
  
  SoDB::getSensorManager()->setChangedCallback(sensorqueuechanged_cb, self);
}

// ----------------- Debugging aids ----------------------------

/*" Writes the current scenegraph to a file. The filename will be
    XXX-dump.iv, where XXX is a number calculated based on the
    current time. The file will be stored in the current working
    directory. Returns !{NO} if there was an error writing the file,
    !{YES} otherwise.
"*/

- (BOOL)dumpSceneGraph
{
  SoOutput out;
  SbString filename = SbTime::getTimeOfDay().format();
  filename += "-dump.iv";
  SbBool ok = out.openFile(filename.getString());
  if (ok) {
    SoWriteAction wa(&out);
    wa.apply(_scenegraph);
    return YES;
  }
  // FIXME: Shouldn't we post a notification about the error?
  // In general, we should have a consistent strategy for
  // exception handling
  return NO;
}

// ---------------- NSCoder conformance -------------------------------

/*" Encodes the SCController using encoder coder "*/

- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
  // FIXME: exception or smth. if !keyeed coding? (kintel 20040408)
  if ([coder allowsKeyedCoding]) {
    [coder encodeBool:_handleseventsinviewer 
           forKey:@"SC_handleseventsinviewer"];
    [coder encodeFloat:_autoclipvalue 
           forKey:@"SC_autoclipvalue"];
  }
}

/*" Initializes a newly allocated SCController instance from the data
    in decoder. Returns !{self} "*/
    
- (id)initWithCoder:(NSCoder *)coder
{
  if (self = [super initWithCoder:coder]) {
    // FIXME: exception or smth. if !keyeed coding? (kintel 20040408)
    if ([coder allowsKeyedCoding]) {
      // Manually checks for existance of keys to be able to read
      // archives from the public beta.
      // FIXME: We should disable this after a grace period (say SC21 V1.0.1)
      // (kintel 20040408)
      if ([coder containsValueForKey:@"SC_handleseventsinviewer"]) {
        _handleseventsinviewer = 
          [coder decodeBoolForKey:@"SC_handleseventsinviewer"];
      }
      else {
        _handleseventsinviewer = YES;
      }
      if ([coder containsValueForKey:@"SC_autoclipvalue"]) {
        _autoclipvalue = [coder decodeFloatForKey:@"SC_autoclipvalue"];
      }
      else {
        _autoclipvalue = 0.6f;
      }
    }
    [self commonInit];
  }
  return self;
}


// ----------------------- InternalAPI -------------------------

/*!
  Timer callback function: process the timer sensor queue.
*/
- (void)_timerQueueTimerFired:(NSTimer *)t
{
  // NSLog(@"timerQueueTimerFired:");
  // The timer might fire after the view has
  // already been destroyed...
  if (!_redrawinv) return; 
  SoDB::getSensorManager()->processTimerQueue();
  [self _sensorQueueChanged];
}

/* process delay queue when application is idle. */

- (void)_idle:(NSNotification *)notification
{
  // NSLog(@"_idle:");
  // We might get the notification after the view has
  // already been destroyed...
  if (!_redrawinv) return; 
  SoDB::getSensorManager()->processTimerQueue();
  SoDB::getSensorManager()->processDelayQueue(TRUE);
  [self _sensorQueueChanged];
}

/*!
  Will reschedule timer sensors to trigger at the time of the first pending
  timer sensor in SoSensorManager (or deactivated if there are no pending 
  sensors).

  Will initiate idle processing if there are pending delay queue sensors.
*/
// FIXME: Rename to something more appropriate... ;)
- (void)_sensorQueueChanged
{
  // NSLog(@"_sensorQueueChanged");
  // Create timers at first invocation
  if (!_timerqueuetimer) [self startTimers];

  SoSensorManager * sm = SoDB::getSensorManager();

  // If there are any pending SoTimerQueueSensors
  SbTime nexttimeout;
  if (sm->isTimerSensorPending(nexttimeout)) {
    SbTime interval = nexttimeout - SbTime::getTimeOfDay();
    [_timerqueuetimer 
      setFireDate:[NSDate dateWithTimeIntervalSinceNow:interval.getValue()]];
  } else {
    [_timerqueuetimer deactivate];
  }
  
  // If there are any pending SoDelayQueueSensors
  if (sm->isDelaySensorPending()) {
    [[NSNotificationQueue defaultQueue] 
      enqueueNotification:
        [NSNotification notificationWithName:_SCIdleNotification object:self]
      postingStyle:NSPostWhenIdle 
      coalesceMask:NSNotificationCoalescingOnName
      forModes: [NSArray arrayWithObjects: 
                           NSDefaultRunLoopMode, 
                           NSModalPanelRunLoopMode, 
                           NSEventTrackingRunLoopMode, 
                           nil]];
  }
}

- (void)_setInternalSceneGraph:(SoGroup *)root
{
  if (_scenegraph) _scenegraph->unref();
  _scenegraph = root;
  _scenegraph->ref();
}

- (void)_handleLighting
{
  if (![self _findLightInSceneGraph:_scenegraph]) {
    [[NSNotificationCenter defaultCenter]
      postNotificationName:SCNoLightFoundInSceneNotification object:self];
  }
}

/* Find light in root. Returns a pointer to the light, if found,
    otherwise NULL.
 */

- (SoLight *)_findLightInSceneGraph:(SoGroup *)root
{
  if (root == NULL) return NULL;

  SoLight * light = NULL;
  SbBool oldsearch = SoBaseKit::isSearchingChildren();
  SoBaseKit::setSearchingChildren(TRUE);
  SoSearchAction sa;
  sa.reset();
  sa.setType(SoLight::getClassTypeId());
  sa.apply(root);
  SoBaseKit::setSearchingChildren(oldsearch);
  if (sa.getPath() != NULL) {
    SoFullPath * fullpath = (SoFullPath *) sa.getPath();
    light = (SoLight *)fullpath->getTail();
  }
  return light;
}


/*" Find camera in root. Returns a pointer to the camera, if found,
    otherwise NULL.
"*/

- (SoCamera *)_findCameraInSceneGraph:(SoGroup *)root
{
  SoCamera * scenecamera = NULL;
  SbBool oldsearch = SoBaseKit::isSearchingChildren();
  SoBaseKit::setSearchingChildren(TRUE);
  SoSearchAction sa;
  sa.reset();
  sa.setType(SoCamera::getClassTypeId());
  sa.apply(root);
  SoBaseKit::setSearchingChildren(oldsearch);
  if (sa.getPath() != NULL) {
    SoFullPath * fullpath = (SoFullPath *) sa.getPath();
    scenecamera = (SoCamera *)fullpath->getTail();
  }
  return scenecamera;
}

- (void)_handleCamera
{  
  SoCamera * scenecamera  = [self _findCameraInSceneGraph:_scenegraph];
  if (scenecamera == NULL) {
    [[NSNotificationCenter defaultCenter]
      postNotificationName:SCNoCameraFoundInSceneNotification object:self];
  } else {
    [_camera setSoCamera:scenecamera deleteOldCamera:NO];
    [_camera setControllerHasCreatedCamera:NO]; 
  }
}

- (NSPoint)_normalizePoint:(NSPoint)point
{
  NSPoint normalized;
  NSSize size = _viewrect.size;
  normalized.x = point.x / size.width;
  normalized.y = point.y / size.height;
  return normalized;
}

- (void)_setupRedrawInvocation
{
  [_redrawinv release];
  _redrawinv = nil;
  
  if (_redrawhandler && _redrawsel) {
    NSMethodSignature *sig = 
      [_redrawhandler methodSignatureForSelector:_redrawsel];

    if ([sig numberOfArguments] != 2 ||
        [sig numberOfArguments] == 3 &&
        [sig getArgumentTypeAtIndex:2] != @encode(id)) {

      NSException * argException = 
        [NSException exceptionWithName:NSInvalidArgumentException
                     reason:@"Wrong format or number of selector arguments"
                     userInfo:nil];
      [argException raise];
      return;
    }

    _redrawinv = [[NSInvocation invocationWithMethodSignature:sig] retain];
    [_redrawinv setSelector:_redrawsel];
    [_redrawinv setTarget:_redrawhandler];
    if ([sig numberOfArguments] == 3) [_redrawinv setArgument:self atIndex:2];
  }
}

@end
