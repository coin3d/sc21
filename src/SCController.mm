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
#import <Sc21/SCEventConverter.h>
#import "SCUtil.h"

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

@implementation _SCControllerP
@end

#define PRIVATE(p) ((p)->sccontrollerpriv)
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
// Will tell our redraw handler (typically an SCView, but can
// be anyone maintaining an OpenGL context) to redraw.
// The invoked redraw method usually makes its OpenGL context
// active and calls SCController's -render method.
static void
redraw_cb(void * user, SoSceneManager *)
{
  SCController * controller = (SCController *)user; 
  [PRIVATE(controller)->redrawinv invoke];
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
NSString * _SCIdleNotification = @"_SCIdleNotification";

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
  doing fullscreen rendering), you should setup this yourself using
  -setRedrawHandler and -setRedrawSelector.
  "*/


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
 
// ----------------- initialization and cleanup ----------------------

+ (void)initialize
{
  // The version is set to 1 to be able to distinguish between objects
  // created with the public beta (version=0) and newer objects.
  // FIXME; It is expected that we'll stop supporting the public beta
  // from Sc21 V1.0.1 and versioning is probably not needed later since
  // we only support keyed archiving.
  [SCController setVersion:1];
}

/*"
  Designated initializer.
  
  Initializes a newly allocated SCController and calls #initCoin.
  "*/
- (id)init
{
  if (self = [super init]) {
    [self _SC_commonInit];
    SELF->autoclipvalue = 0.6;
    SELF->handleseventsinviewer = YES;
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self stopTimers];
  SELF->redrawhandler = nil;
  [self _SC_setupRedrawInvocation]; // will release related objects
  [SELF->eventconverter release];
  [SELF->camera release];
  delete SELF->scenemanager;
  [SELF release];
  [super dealloc];
}

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

// ------------------- rendering and scene management ---------------------

/*"
  Sets the object that should handle redraw messages generated
  by the scene graph.

  This is automatically set by SCView.setController and should only
  need to be set when not rendering into an SCView (e.g. when doing
  fullscreen rendering).

  #{See Also:} #{-redrawHandler}, #{-setRedrawSelector}
  "*/
- (void)setRedrawHandler:(id)handler
{
  SELF->redrawhandler = handler;
  [self _SC_setupRedrawInvocation];
}

/*"
  Returns the redraw handler previously set by -setRedrawHandler:
  or nil if no redraw handler has been set.
  "*/
- (id)redrawHandler
{
  return SELF->redrawhandler;
}

/*"
  Sets the selector to be performed on the object set by -setRedrawHandler.

  This defaults to @selector(display), but can be changed to any selector
  with and optional id argument. If an id argument exists, this controller
  object will be sent.

  If the given selector doesn't conform, an NSInvalidArgumentException
  will be raised.
  "*/
- (void)setRedrawSelector:(SEL)sel
{
  SELF->redrawsel = sel;
  [self _SC_setupRedrawInvocation];
}

/*"
  Returns the redraw selector previously set by -setRedrawSelector or
  nil if no redraw selector has been set.
  "*/
- (SEL)redrawSelector
{
  return SELF->redrawsel;
}

/*"
  Sets the scene graph that shall be rendered.

  If scenegraph is NULL, an empty scenegraph consisting of a single 
  SoSeparator node will be created and set. 

  Before the scene graph is set, the delegate method -willSetSceneGraph:
  will be called. The return value of this method will be used as the
  actual scene graph. This delegate method can be used to set up a
  super scene graph containing lights, cameras etc. If this method
  returns NULL, no scene graph will be set.
  If no delegate has been set for this class or if it doesn't implement
  the -willSetSceneGraph: method, we will fall back to an internal
  implementation which does the following:
  o Adds a headlight.
  o Enables the headlight if no lights are found in the scene graph
  o Create a perspective camera if no cameras are found in the scene graph
  o Use the first found camera as the active camera

  After a scene graph is set, the delegate method -didSetSceneGraph:
  is called with the super scene graph as parameter.



  Both the passed and the actual scene graph will be !{ref()}'ed.
  "*/
- (void)setSceneGraph:(SoGroup *)scenegraph
{
  if (scenegraph == SELF->scenegraph) return;

  // Clean up existing scene graph
  if (SELF->scenegraph) SELF->scenegraph->unref();
  if (SELF->superscenegraph) SELF->superscenegraph->unref();
  SELF->scenegraph = SELF->superscenegraph = NULL;
  SELF->headlight = NULL;
  [self setHeadlightIsOn:NO];

  if (scenegraph == NULL) {
    [self stopTimers];   // Don't waste cycles by animating an empty scene
    // Create an empty scene graph
    // Why do we create an SoSeparator instead of keeping the scenegraph
    // as NULL? (kintel 20040616)
    SELF->superscenegraph = SELF->scenegraph = new SoSeparator;
    SELF->superscenegraph->ref();
    SELF->scenegraph->ref();
  }
  else {
    scenegraph->ref();

    // super scene graph creation
    if (self->delegate && 
        [self->delegate respondsToSelector:@selector(willSetSceneGraph:)]) {
      SELF->superscenegraph = (SoGroup *)[self->delegate willSetSceneGraph:scenegraph];
    }
    else {
      SELF->superscenegraph = [self _SC_createSuperSceneGraph:scenegraph];
    }

    // Successful super scene graph creation
    if (SELF->superscenegraph) {
      SELF->scenegraph = scenegraph;
      SELF->superscenegraph->ref();
      
      if (SELF->scenemanager) {
        SELF->scenemanager->setSceneGraph(SELF->superscenegraph);
        [SELF->camera updateClippingPlanes:SELF->scenegraph];
      }
      if (self->delegate && 
          [self->delegate respondsToSelector:@selector(didSetSceneGraph:)]) {
        [self->delegate didSetSceneGraph:SELF->superscenegraph];
      }
      if ([SELF->camera controllerHasCreatedCamera]) {
        [SELF->camera viewAll];
        SELF->scenemanager->scheduleRedraw(); //FIXME: Do we need this? (kintel 20040604)
      }
      [self startTimers];
    }
    else {
      // NULL super scene graph => leave everything at NULL
      scenegraph->unrefNoDelete();
      if (SELF->scenemanager) SELF->scenemanager->setSceneGraph(NULL);
    }
  }

  [[NSNotificationCenter defaultCenter]
    postNotificationName:SCSceneGraphChangedNotification object:self];
}

/*" Returns the current scene graph used for rendering.
  FIXME: Write not about how to get superscenegraph"*/

- (SoGroup *)sceneGraph 
{ 
  return SELF->scenegraph; 
}

/*" Sets the current scene manager to scenemanager. The scene manager's
    render callback will be set to %redraw_cb (SCController's default
    redraw callback), and it will be activated. Also, if a scenegraph
    has been set earlier, scenemanager's scenegraph will be set to it.

    Note that you should not normally need to call that method, since a
    scene manager is created for you while initializing.
 "*/

- (void)setSceneManager:(SoSceneManager *)scenemanager
{
  //FIXME: Keep old background color if set? (kintel 20040406)
  SELF->scenemanager = scenemanager;
  SELF->scenemanager->setRenderCallback(redraw_cb, (void *)self);
  SoGLRenderAction * glra = SELF->scenemanager->getGLRenderAction();
  glra->setCacheContext(SoGLCacheContextElement::getUniqueCacheContext());
  glra->setTransparencyType(SoGLRenderAction::DELAYED_BLEND);
  SELF->scenemanager->activate();
  if (SELF->superscenegraph) SELF->scenemanager->setSceneGraph(SELF->superscenegraph);
}

/*" Returns the current Coin scene manager instance. "*/

- (SoSceneManager *)sceneManager 
{ 
  return SELF->scenemanager; 
}

/*" Sets the autoclip value to value.

    This value influences the automatic setting of the near and
    far clipping plane. The default should be good enough in most 
    cases, so if you do not know what this means, don't worry.
    If you are interested, check out the code in
    !{- (float) _bestValueForNearPlane:(float)near farPlane:(float) far}
    in SCCamera.

    The default value is 0.6.
 "*/

- (void)setAutoClipValue:(float)autoclipvalue
{
  SELF->autoclipvalue = autoclipvalue;
}

/*" Returns the current autoclipvalue. The default value is 0.6. "*/

- (float)autoClipValue
{
  return SELF->autoclipvalue;
}


/*" Sets the SoCamera used for viewing the scene to cam.
    It is first checked if the scenegraph contains a camera created by
    the controller, and if yes, this camera is deleted.

    Note that cam is expected to be part of the scenegraph already;
    it is not inserted into it.
"*/

- (void)setCamera:(SoCamera *)cam
{
  [SELF->camera setSoCamera:cam deleteOldCamera:YES];
}

/*" Returns the current SoCamera used for viewing. "*/

- (SoCamera *)camera
{
  return [SELF->camera soCamera];
}

/*" Returns !{SCCameraPerspective} if the camera is perspective
    and !{SCCameraOrthographic} if the camera is orthographic.
 "*/

- (SCCameraType)cameraType
{
  return [SELF->camera type];
}

/*"
  Repositions the camera so that we can se the whole scene.
  "*/
- (void)viewAll
{
  [PRIVATE(self)->camera viewAll]; // SCViewAllNotification sent by _camera
}

/*" Renders the scene. "*/

- (void)render
{
  //FIXME: Do clearing here instead of in SoSceneManager to support
  // alpha values? (kintel 20040502)
  SELF->scenemanager->render(SELF->clearcolorbuffer, SELF->cleardepthbuffer);
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
- (void)setClearColorBuffer:(BOOL)yesno
{
  SELF->clearcolorbuffer = yesno;
}

/*"
  Returns YES if the color buffer is automatically cleared
  before rendering.
  
  The default value is YES.
  "*/
- (BOOL)clearColorBuffer
{
  return SELF->clearcolorbuffer;
}

/*"
  Controls whether the depth buffer is automatically cleared
  before rendering.
  
  The default value is YES.
  "*/
- (void)setClearDepthBuffer:(BOOL)yesno
{
  SELF->cleardepthbuffer = yesno;
}

/*"
  Returns YES if the depth buffer is automatically cleared
  before rendering.
  
  The default value is YES.
  "*/
- (BOOL)clearDepthBuffer
{
  return SELF->cleardepthbuffer;
}


/*" This method is called when %view's size has been changed. 
    It makes the necessary adjustments for the new size in 
    the Coin subsystem.
 "*/

- (void)viewSizeChanged:(NSRect)rect
{
  SELF->viewrect = rect;
  if (!SELF->scenemanager) return;
  int w = (GLint)(rect.size.width);
  int h = (GLint)(rect.size.height);
  SELF->scenemanager->setViewportRegion(SbViewportRegion(w, h));
  SELF->scenemanager->scheduleRedraw();  
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
  SoEvent * se = [SELF->eventconverter createSoEvent:event inView:view];
  if (se) {
    BOOL handled = SELF->scenemanager->processEvent(se);
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

// -------------------- Timer management. ----------------------


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

// ---------------- NSCoding conformance -------------------------------

/*" Encodes the SCController using encoder coder "*/

- (void)encodeWithCoder:(NSCoder *)coder
{
  if ([coder allowsKeyedCoding]) {
    [coder encodeBool:SELF->handleseventsinviewer 
           forKey:@"SC_handleseventsinviewer"];
    [coder encodeFloat:SELF->autoclipvalue 
           forKey:@"SC_autoclipvalue"];
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
  if ([coder versionForClassName:@"SCController"] == 0) {
    [self _SC_commonInit];
    SELF->oldcontroller = [[NSResponder alloc] initWithCoder:coder];
    return self;
  }
  else if (self = [super init]) {
    [self _SC_commonInit];
    if ([coder allowsKeyedCoding]) {
      // We don't need to check for existence since these four keys
      // will always exist.
      SELF->handleseventsinviewer = 
        [coder decodeBoolForKey:@"SC_handleseventsinviewer"];
      SELF->autoclipvalue = [coder decodeFloatForKey:@"SC_autoclipvalue"];
      SELF->clearcolorbuffer = [coder decodeBoolForKey:@"SC_clearcolorbuffer"];
      SELF->cleardepthbuffer = [coder decodeBoolForKey:@"SC_cleardepthbuffer"];
    }
  }
  return self;
}

/*!
  This method is here only to support reading nib files created with
  Sc21 public beta.

  FIXME: We should remove this after a grace period (say Sc21 V1.0.1)
  (kintel 20040404)
*/
- (id)awakeAfterUsingCoder:(NSCoder *)coder
{
  SC21_DEBUG(@"SCController.awakeAfterUsingCoder:");
  if (SELF->oldcontroller) {
    SC21_DEBUG(@"  upgrading old instance.");

    if (self = [self init]) {
      SELF->autoclipvalue = 0.6;
      SELF->handleseventsinviewer = YES;
      if ([coder allowsKeyedCoding]) {
        if ([coder containsValueForKey:@"SC_handleseventsinviewer"]) {
          SELF->handleseventsinviewer = 
            [coder decodeBoolForKey:@"SC_handleseventsinviewer"];
        }
        if ([coder containsValueForKey:@"SC_autoclipvalue"]) {
          SELF->autoclipvalue = [coder decodeFloatForKey:@"SC_autoclipvalue"];
        }
      }
    }

    [SELF->oldcontroller release];
    SELF->oldcontroller = nil;
  }
  return self;
}

// ----------------- Automatic headlight configuration -----------------

/*" Returns !{YES} if the headlight is on, and !{NO} if it is off. "*/

- (BOOL)headlightIsOn
{
  if (SELF->headlight == NULL) return FALSE;
  return (SELF->headlight->on.getValue() == TRUE) ? YES : NO;
}


/*" Turns the headlight on or off. "*/

- (void)setHeadlightIsOn:(BOOL)yn
{
  if (SELF->headlight == NULL) return;
  SELF->headlight-> on = yn ? TRUE : FALSE;
  
  [[NSNotificationCenter defaultCenter]
    postNotificationName:SCHeadlightChangedNotification object:self];
}

/*" Returns the headlight of the current scene graph. "*/

- (SoDirectionalLight *)headlight
{
  return SELF->headlight;
}

@end

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
  SELF = [[_SCControllerP alloc] init];
  SELF->camera = [[SCCamera alloc] init];
  [SELF->camera setController:self];
  SELF->eventconverter = [[SCEventConverter alloc] init];
  SELF->redrawsel = @selector(display);
  SELF->clearcolorbuffer = YES;
  SELF->cleardepthbuffer = YES;

  [self setSceneManager:new SoSceneManager];

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
    selector:@selector(_SC_idle:) name:_SCIdleNotification
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
  if (!SELF->redrawinv) return; 
  SoDB::getSensorManager()->processTimerQueue();
  [self _SC_sensorQueueChanged];
}

/* process delay queue when application is idle. */

- (void)_SC_idle:(NSNotification *)notification
{
  // SC21_DEBUG(@"_idle:");
  // We might get the notification after the view has
  // already been destroyed...
  if (!SELF->redrawinv) return; 
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

/* Find light in root. Returns a pointer to the light, if found,
    otherwise NULL.
 */

- (SoLight *)_SC_findLightInSceneGraph:(SoGroup *)root
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

- (SoCamera *)_SC_findCameraInSceneGraph:(SoGroup *)root
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

- (NSPoint)_SC_normalizePoint:(NSPoint)point
{
  NSPoint normalized;
  NSSize size = SELF->viewrect.size;
  normalized.x = point.x / size.width;
  normalized.y = point.y / size.height;
  return normalized;
}

- (void)_SC_setupRedrawInvocation
{
  [SELF->redrawinv release];
  SELF->redrawinv = nil;
  
  if (SELF->redrawhandler && SELF->redrawsel) {
    NSMethodSignature *sig = 
      [SELF->redrawhandler methodSignatureForSelector:SELF->redrawsel];

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

    SELF->redrawinv = [[NSInvocation invocationWithMethodSignature:sig] retain];
    [SELF->redrawinv setSelector:SELF->redrawsel];
    [SELF->redrawinv setTarget:SELF->redrawhandler];
    if ([sig numberOfArguments] == 3) [SELF->redrawinv setArgument:self atIndex:2];
  }
 }
 
- (SoGroup *)_SC_createSuperSceneGraph:(SoGroup *)scenegraph
{
  SoGroup *superscenegraph = new SoSeparator;

  // Handle lighting
  if (![self _SC_findLightInSceneGraph:scenegraph]) {
    [self setHeadlightIsOn:YES];
  } else {
    [self setHeadlightIsOn:NO];
  }
  SELF->headlight = new SoDirectionalLight;
  superscenegraph->addChild(SELF->headlight);

  // Handle camera
  SoCamera * scenecamera  = [self _SC_findCameraInSceneGraph:scenegraph];
  if (scenecamera == NULL) {
    scenecamera = new SoPerspectiveCamera;
    [SELF->camera setSoCamera:scenecamera deleteOldCamera:NO];
    [SELF->camera setControllerHasCreatedCamera:YES];
    superscenegraph->addChild(scenecamera);
  } else {
    [SELF->camera setSoCamera:scenecamera deleteOldCamera:NO];
    [SELF->camera setControllerHasCreatedCamera:NO];
  }
  
  superscenegraph->addChild(scenegraph);

  return superscenegraph;
}

@end
