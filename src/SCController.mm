/* =============================================================== *
 |                                                                 |
 | This file is part of Sc21, a Cocoa user interface binding for   |
 | the Coin 3D visualization library.                              |
 |                                                                 |
 | Copyright (c) 2003-2004 Systems in Motion. All rights reserved. |
 |                                                                 |
 | Sc21 is free software; you can redistribute it and/or           |
 | modify it under the terms of the GNU General Public License     |
 | ("GPL") version 2 as published by the Free Software             |
 | Foundation.                                                     |
 |                                                                 |
 | A copy of the GNU General Public License can be found in the    |
 | source distribution of Sc21. You can also read it online at     |
 | http://www.gnu.org/licenses/gpl.txt.                            |
 |                                                                 |
 | For using Coin with software that can not be combined with the  |
 | GNU GPL, and for taking advantage of the additional benefits    |
 | of our support services, please contact Systems in Motion       |
 | about acquiring a Coin Professional Edition License.            |
 |                                                                 |
 | See http://www.coin3d.org/mac/Sc21 for more information.        |
 |                                                                 |
 | Systems in Motion, Bygdoy Alle 5, 0257 Oslo, Norway.            |
 |                                                                 |
 * =============================================================== */
 
#import <Sc21/SCController.h>
#import <Sc21/SCEventHandler.h>
#import "SCEventConverter.h"
#import "SCUtil.h"

#import <Inventor/SbTime.h>
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
#import <Inventor/nodes/SoPerspectiveCamera.h>
#import <Inventor/nodes/SoDirectionalLight.h>
#import <Inventor/nodes/SoSeparator.h>

#import <OpenGL/gl.h>

#import "SCControllerP.h"

@implementation SCControllerP
@end

#define PRIVATE(p) ((p)->_sc_controller)
#define SELF PRIVATE(self)

/*" 
  Provide interface for deaction of NSTimer instance.
  
  The current implementation sets the timer's fireDate to
  "distantFuture" (cf. NSDate) but hopefully activation and
  deactivation will be supported in the timer itself in the
  future.
  "*/
@interface NSTimer (Sc21Extensions)
- (void)_SC_deactivate;
- (BOOL)_SC_isActive;
@end

@implementation NSTimer (Sc21Extensions)

- (void)_SC_deactivate
{
  [self setFireDate:[NSDate distantFuture]];
}

- (BOOL)_SC_isActive
{
  // A timer is "active" if its fire date is less than 10000 seconds from now.
  // Note that we cannot compare for "== distantFuture" here, since
  // distantFuture is "current time + a high number" (i.e. the actual 
  // date changes with time)
  
  return ([self fireDate] < [NSDate dateWithTimeIntervalSinceNow:10000]);
}
@end

// -------------------- Callback functions ------------------------

// This function is the SoSceneManager render callback.
// Will tell our drawable (typically an SCView, but can
// be any SCDrawable maintaining an OpenGL context) to redraw.
// The invoked redraw method usually makes its OpenGL context
// active and calls SCController's -render method, but not necessarily
// synchronously.
static void
redraw_cb(void * user, SoSceneManager *)
{
  SCController * controller = (SCController *)user; 
  [PRIVATE(controller)->drawable display];
}

// This function is the SoSensorManager change callback.
// Note that in a multi-threaded Coin app, this callback
// can be called simultaneously from multiple threads.
// FIXME: Make sure that this function and whatever is called
// is thread-safe and will execute tasks in the correct threads
// (e.g. rendering in the main thread) (kintel 20040616).
static void
sensorqueuechanged_cb(void * data)
{
  SCController * controller = (SCController *)data;
  [controller _SC_sensorQueueChanged];
}

// Internal. Used for triggering delayqueue sensors when idle.
NSString * SCIdleNotification = @"_SC_IdleNotification";

@implementation SCController

/*" 
  An SCController is the main component for rendering Coin scene
  graphs. It handles all actual scene management, rendering, event
  translation etc.

  The simplest use of this class is to connect to it from an SCView
  instance and set a scene graph using -setSceneGraph:.
  
  Since Coin is a data driven API, redraws are usually requested by
  the scene graph itself. To handle these redraws, the controller must
  be given an object and a selector that should called upon such a
  redraw request. This is automatically handled by SCView but if you
  want to use an SCController without having an SCView (e.g. when
  doing fullscreen rendering), you should supply an SCDrawable instead
  and set this using -setDrawble:.
  "*/

#pragma mark --- static methods ----

/*" 
  Initializes Coin.

  SCController automatically calls this method if needed.

  You need to call this method explicitly only if you want to use Coin
  functionality before actually instantiating an SCController in your
  application (e.g. if you want to read a 3D models using
  SoDB::readAll() and load the nib file containing your SCView and
  SCController only if the file was read successfully).
  

  This method calls !{SoDB::init()}, !{SoInteraction::init()} and
  !{SoNodeKit::init()}.
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
    initialized = YES;
  }
}


+ (void)initialize
{
  // The version is set to 1 to be able to distinguish between objects
  // created with the public beta (version=0) and newer objects.
  // FIXME; It is expected that we'll stop supporting the public beta
  // from Sc21 V1.0.1 and versioning is probably not needed later since
  // we only support keyed archiving.
  [SCController setVersion:1];
}

#pragma mark --- initialization and cleanup ---

/*"
  Designated initializer.
  
  Initializes a newly allocated SCController and calls #initCoin.
  "*/
- (id)init
{
  if (self = [super init]) {
    [self _SC_commonInit];
    SELF->handleseventsinviewer = YES;
    SELF->modifierforcoinevent = NSAlternateKeyMask; //FIXME: -> inspector
    SELF->clearcolorbuffer = YES;
    SELF->cleardepthbuffer = YES;
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self setSceneGraph:nil];
  [self stopTimers];
  [SELF->eventconverter release];
  [self setEventHandler:nil];
  delete SELF->scenemanager;
  [SELF release];
  [super dealloc];
}

#pragma mark --- rendering ---

/*" 
  Renders the scene by calling the current SoSceneManager's render() funtion. 
 "*/

- (void)render
{
//   SC21_DEBUG(@"SCController.render");
  // FIXME: Do clearing here instead of in SoSceneManager to support
  // alpha values? Alternatively, add SbColor4f support the necessary
  // places in Coin (kintel 20040502)
  [self _SC_viewSizeChanged];
  [[self->sceneGraph camera] updateClippingPlanes:self->sceneGraph];
  SELF->scenemanager->render(SELF->clearcolorbuffer, SELF->cleardepthbuffer);
  [self->eventHandler update];
}

#pragma mark --- event handling ---

/*" Handles event by either converting it to an %SoEvent and 
    passes it on to the scenegraph via #handleEventAsCoinEvent:, 
    or handles it in the viewer itself via #handleEventAsViewerEvent:.
    
    Handling events in the viewer will pass it on to the event handler,
    allowing the use to control camera movement; examination of the scene
    or flying through the scene.

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
 
- (BOOL)handleEvent:(NSEvent *)event
{
  SC21_LOG_METHOD;
  if ([self handlesEventsInViewer] == NO ||
      ([event modifierFlags] & [self modifierForCoinEvent])) {
    return [self handleEventAsCoinEvent:event];
  } else {
    return [self handleEventAsViewerEvent:event];
  }
}

/*" Handles event as Coin event, i.e. creates an SoEvent and passes 
    it on to the scenegraph.

    Returns !{YES} if the event has been handled, !{NO} otherwise.
 "*/
 
- (BOOL)handleEventAsCoinEvent:(NSEvent *)event
{
  SC21_DEBUG(@"SCController.handleEventAsCoinEvent:");
  BOOL handled = NO;
  SoEvent * se = [SELF->eventconverter createSoEvent:event 
                      inDrawable:SELF->drawable];
  if (se) {
    handled = SELF->scenemanager->processEvent(se);
    delete se;
  }
  return handled;
}

/*" Handles event as viewer event, i.e. does not send it to the scene
    graph but interprets it as input for controlling the viewer. 

    Returns !{YES} if the event has been handled, !{NO} otherwise.

    The default implementation does nothing and returns !{NO}.
 "*/
 
- (BOOL)handleEventAsViewerEvent:(NSEvent *)event
{
  SC21_DEBUG(@"SCController.handleEventAsViewerEvent:");
  return [self->eventHandler handleEvent:event];
}

/*" 
  Sets whether events should be interpreted as viewer events, i.e.
  are regarded as input for controlling the viewer (yn == YES), or 
  should be sent to the scene graph directly (yn = NO).

  Events are interpreted as viewer events by default.
"*/
 
- (void)setHandlesEventsInViewer:(BOOL)yn
{
  SELF->handleseventsinviewer = yn;
  [[NSNotificationCenter defaultCenter] 
    postNotificationName:SCModeChangedNotification object:self];
}


/*" 
  Returns TRUE if events are interpreted as viewer events, i.e.
  are regarded as input for controlling the viewer. Returns 
  FALSE if events are sent to the scene graph directly.

  Events are interpreted as viewer events by default.
  "*/

- (BOOL)handlesEventsInViewer
{
  return SELF->handleseventsinviewer;
}

- (void)setModifierForCoinEvent:(unsigned int)modifier
{
  SELF->modifierforcoinevent = modifier;
}

- (unsigned int)modifierForCoinEvent
{
  return SELF->modifierforcoinevent;
}

- (void)setEventHandler:(id<SCEventHandling>)handler
{
  if (handler != self->eventHandler) {
    [self->eventHandler release];
    self->eventHandler = [handler retain];
    NSNotification * notification = [NSNotification notificationWithName:SCDrawableChangedNotification object:self];
    [self->eventHandler drawableDidChange:notification];
    notification = [NSNotification notificationWithName:SCSceneGraphChangedNotification object:self];
    [self->eventHandler sceneGraphDidChange:notification];

    [[NSNotificationCenter defaultCenter] addObserver:self->eventHandler selector:@selector(drawableDidChange:) name:SCDrawableChangedNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self->eventHandler selector:@selector(sceneGraphDidChange:) name:SCSceneGraphChangedNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_SC_cursorDidChange:) name:SCCursorChangedNotification object:self->eventHandler];
  }
}

- (id<SCEventHandling>)eventHandler
{
  return self->eventHandler;
}

#pragma mark --- timer management ---

- (void)startTimers
{
  if (SELF->timerqueuetimer != nil) return;
  
  // The timer will be controller from _SC_sensorQueueChanged,
  // so don't activate it yet.
  SELF->timerqueuetimer = [NSTimer scheduledTimerWithTimeInterval:1000
                                                           target:self
                                                         selector:@selector(_SC_timerQueueTimerFired:) 
                                                         userInfo:nil 
                                                          repeats:YES];
  [SELF->timerqueuetimer _SC_deactivate];
  [[NSRunLoop currentRunLoop] addTimer:SELF->timerqueuetimer 
                               forMode:NSModalPanelRunLoopMode];
  [[NSRunLoop currentRunLoop] addTimer:SELF->timerqueuetimer 
                               forMode:NSEventTrackingRunLoopMode];
  
  SoDB::getSensorManager()->setChangedCallback(sensorqueuechanged_cb, self);
}

/*" Stops and releases the timers for timer queue and delay queue
    processing.
 "*/

- (void)stopTimers
{
  if (SELF->timerqueuetimer && [SELF->timerqueuetimer isValid]) {
    [SELF->timerqueuetimer invalidate];
    SELF->timerqueuetimer = nil;
  }
  SoDB::getSensorManager()->setChangedCallback(NULL, NULL);
}

#pragma mark --- accessor methods ---

- (void)setDrawable:(id<SCDrawable>)newdrawable
{
  SELF->drawable = newdrawable;

  // Force a redraw - otherwise the display wouldn't be refreshed 
  // until the first event or scene change.
  [self sceneManager]->scheduleRedraw();
  
  [[NSNotificationCenter defaultCenter]
    postNotificationName:SCDrawableChangedNotification object:self];
}

- (id<SCDrawable>)drawable
{
  return SELF->drawable;
}

/*" Sets the scene graph that shall be rendered. 
"*/
- (void)setSceneGraph:(SCSceneGraph *)sg
{
  if (sg == sceneGraph) { return; }
  
  [sceneGraph release];
  sceneGraph = [sg retain];
   
  // Don't waste cycles by animating an empty scene
  if (sceneGraph == nil) { [self stopTimers]; }
  else { [self startTimers]; }
  
  // We want to be informed whenever the scenegraph's root node changes.
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(_SC_sceneGraphChanged:)
                                               name:SCRootChangedNotification
                                             object:sceneGraph];

  [self _SC_sceneGraphChanged:nil];
}

- (SCSceneGraph *)sceneGraph 
{ 
  return sceneGraph; 
}

/*"
  Sets the current scene manager to scenemanager. The scene manager's
  render callback will be set to %redraw_cb (SCController's default
  redraw callback), and it will be activated. Also, if a scenegraph
  has been set earlier, scenemanager's scenegraph will be set to it.
  
  Note that you should not normally need to call that method, since a
  scene manager is created for you while initializing.
"*/

- (void)setSceneManager:(SoSceneManager *)scenemanager
{
  if (scenemanager != SELF->scenemanager) {
    if (SELF->hascreatedscenemanager) {
      delete SELF->scenemanager;
      SELF->hascreatedscenemanager = NO;
    }
    SELF->scenemanager = scenemanager;
    //FIXME: Keep old background color if set? (kintel 20040406)
    SELF->scenemanager->setRenderCallback(redraw_cb, (void *)self);
    SoGLRenderAction * glra = SELF->scenemanager->getGLRenderAction();
    glra->setCacheContext(SoGLCacheContextElement::getUniqueCacheContext());
    glra->setTransparencyType(SoGLRenderAction::DELAYED_BLEND);
    SELF->scenemanager->activate();
    if (sceneGraph) {
      SELF->scenemanager->setSceneGraph([sceneGraph superSceneGraph]);
      [sceneGraph setSceneManager:SELF->scenemanager];
    }
  }
}

/*" Returns the current Coin scene manager instance. "*/

- (SoSceneManager *)sceneManager 
{ 
  return SELF->scenemanager; 
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
  
  SELF->scenemanager->setBackgroundColor(SbColor(red, green, blue));
  SELF->scenemanager->scheduleRedraw();  
}

/*" Returns the scene's background color. "*/

- (NSColor *)backgroundColor
{
  SbColor sbcolor = SELF->scenemanager->getBackgroundColor();
  NSColor * color = [NSColor colorWithCalibratedRed:sbcolor[0]
                                              green:sbcolor[1] 
                                               blue:sbcolor[2] 
                                              alpha:0.0f];
  return color;	
}

/*"
Controls whether the color buffer is automatically cleared
 before rendering.
 
 The default value is YES.
 "*/
- (void)setClearsColorBuffer:(BOOL)yesno
{
  SELF->clearcolorbuffer = yesno;
}

/*"
Returns YES if the color buffer is automatically cleared
 before rendering.
 
 The default value is YES.
 "*/
- (BOOL)clearsColorBuffer
{
  return SELF->clearcolorbuffer;
}

/*"
Controls whether the depth buffer is automatically cleared
 before rendering.
 
 The default value is YES.
 "*/
- (void)setClearsDepthBuffer:(BOOL)yesno
{
  SELF->cleardepthbuffer = yesno;
}

/*"
Returns YES if the depth buffer is automatically cleared
 before rendering.
 
 The default value is YES.
 "*/
- (BOOL)clearsDepthBuffer
{
  return SELF->cleardepthbuffer;
}

#pragma mark --- delegate handling ---

/*"
Makes newdelegate the receiver's delegate.
 
 FIXME: Document what notifications the delegate automatically will
 be registered for (kintel 20040616).
 
 The delegate doesn't need to implement all of the delegate methods.
 "*/
- (void)setDelegate:(id)newdelegate
{
  SC21_DEBUG(@"SCController.setDelegate");
  self->delegate = newdelegate;
}

/*"
Returns the receiver's delegate.
 "*/
- (id)delegate
{
  return self->delegate;
}

#pragma mark --- NSCoding conformance ---

/*" Encodes the SCController using encoder coder "*/

- (void)encodeWithCoder:(NSCoder *)coder
{
  if ([coder allowsKeyedCoding]) {
    [coder encodeBool:SELF->handleseventsinviewer 
           forKey:@"SC_handleseventsinviewer"];
    [coder encodeInt:SELF->modifierforcoinevent 
           forKey:@"SC_modifierforcoinevent"];
    [coder encodeBool:SELF->clearcolorbuffer 
           forKey:@"SC_clearcolorbuffer"];
    [coder encodeBool:SELF->cleardepthbuffer 
           forKey:@"SC_cleardepthbuffer"];
  }
}

/*" Initializes a newly allocated SCController instance from the data
    in decoder. Returns !{self} "*/
    
- (id)initWithCoder:(NSCoder *)coder
{
  if (self = [super init]) {
    [self _SC_commonInit];
    if ([coder allowsKeyedCoding]) {
      // We don't need to check for existence since these four keys
      // will always exist.
      SELF->handleseventsinviewer = 
        [coder decodeBoolForKey:@"SC_handleseventsinviewer"];
      SELF->clearcolorbuffer = [coder decodeBoolForKey:@"SC_clearcolorbuffer"];
      SELF->cleardepthbuffer = [coder decodeBoolForKey:@"SC_cleardepthbuffer"];
      SELF->modifierforcoinevent = 
        [coder decodeIntForKey:@"SC_modifierforcoinevent"];
    }
  }
  return self;
}

@end

#pragma mark --- internal API ---

@implementation SCController (InternalAPI)

/*"
  Shared initialization code that is called both from #init: and
  #initWithCoder:.
  
  If you override this method, you must call [super _SC_commonInit]
  as the first call in your implementation to make sure everything
  is set up properly.
  "*/
- (void)_SC_commonInit
{
  [SCController initCoin];
  SELF = [[SCControllerP alloc] init];
  sceneGraph = nil;
  
  SELF->eventconverter = [[SCEventConverter alloc] init];
//   SELF->redrawselector = @selector(display);

  [self setSceneManager:new SoSceneManager];
  SELF->hascreatedscenemanager = YES;

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
    selector:@selector(_SC_idle:) name:SCIdleNotification
    object:self];

  [self _SC_sensorQueueChanged];
}

/*!
  Timer callback function: process the timer sensor queue.
*/
- (void)_SC_timerQueueTimerFired:(NSTimer *)t
{
  // SC21_DEBUG(@"timerQueueTimerFired:");
  // The timer might fire after the view has
  // already been destroyed...
  if (!SELF->drawable) return; 
  SoDB::getSensorManager()->processTimerQueue();
  [self _SC_sensorQueueChanged];
}

/* process delay queue when application is idle. */

- (void)_SC_idle:(NSNotification *)notification
{
  // SC21_DEBUG(@"_idle:");
  // We might get the notification after the view has
  // already been destroyed...
  if (!SELF->drawable) return; 
  SoDB::getSensorManager()->processTimerQueue();
  SoDB::getSensorManager()->processDelayQueue(TRUE);
  [self _SC_sensorQueueChanged];
}

/*!
  Will reschedule timer sensors to trigger at the time of the first pending
  timer sensor in SoSensorManager (or deactivated if there are no pending 
  sensors).

  Will initiate idle processing if there are pending delay queue sensors.
*/
// FIXME: Rename to something more appropriate... ;)
- (void)_SC_sensorQueueChanged
{
  // SC21_DEBUG(@"_sensorQueueChanged");
  // Create timers at first invocation
  if (!SELF->timerqueuetimer) [self startTimers];

  SoSensorManager * sm = SoDB::getSensorManager();

  // If there are any pending SoTimerQueueSensors
  SbTime nexttimeout;
  if (sm->isTimerSensorPending(nexttimeout)) {
    SbTime interval = nexttimeout - SbTime::getTimeOfDay();
    [SELF->timerqueuetimer 
      setFireDate:[NSDate dateWithTimeIntervalSinceNow:interval.getValue()]];
  } else {
    [SELF->timerqueuetimer _SC_deactivate];
  }
  
  // If there are any pending SoDelayQueueSensors
  if (sm->isDelaySensorPending()) {
    [[NSNotificationQueue defaultQueue]
      enqueueNotification:
        [NSNotification notificationWithName:SCIdleNotification object:self]
      postingStyle:NSPostWhenIdle 
      coalesceMask:NSNotificationCoalescingOnName
      forModes: [NSArray arrayWithObjects: 
                           NSDefaultRunLoopMode, 
                           NSModalPanelRunLoopMode, 
                           NSEventTrackingRunLoopMode, 
                           nil]];
  }
}

- (void)_SC_cursorDidChange:(NSNotification *)notification
{
  [[NSNotificationCenter defaultCenter] 
    postNotificationName:SCCursorChangedNotification object:self];
}

/* This method is called when %view's size has been changed. 
    It makes the necessary adjustments for the new size in 
    the Coin subsystem.
 */
- (void)_SC_viewSizeChanged
{
  if (!SELF->scenemanager || !SELF->drawable) return;
  NSRect frame = [SELF->drawable frame];
  SELF->scenemanager->
    setViewportRegion(SbViewportRegion((short)frame.size.width,
                                       (short)frame.size.height));
}

/*
  Called when the scenegraph, or the scenegraph's root node, has changed.
  This is done so that we have one common notification for both cases.
 */

- (void)_SC_sceneGraphChanged:(id)sender
{  
  // Make sure the scenegraph <-> scenemanager connection is valid.
  // Note that this cannot be moved to setSceneGraph: since the 
  // SoSceneManager must know the the SCSceneGraph's superscenegraph,
  // which might have changed in SCSceneGraph's setRoot: 
  
  [sceneGraph setSceneManager:SELF->scenemanager];
  if (SELF->scenemanager) {
    SELF->scenemanager->setSceneGraph([sceneGraph superSceneGraph]);
  }
    
  [[NSNotificationCenter defaultCenter]
    postNotificationName:SCSceneGraphChangedNotification object:self];
}

@end
