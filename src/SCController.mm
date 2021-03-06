/**************************************************************************\
 * Copyright (c) Kongsberg Oil & Gas Technologies AS
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 
 * Neither the name of the copyright holder nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
\**************************************************************************/
 
#import <Sc21/SCController.h>

#import "SCControllerP.h"
#import "SCOffscreenRenderer.h"
#import "SCSceneGraphP.h"
#import "SCTimer.h"
#import "SCUtil.h"

#import <OpenGL/gl.h>

#import <Inventor/SbTime.h>
#import <Inventor/SbImage.h>
#import <Inventor/SoDB.h>
#import <Inventor/SoInteraction.h>
#import <Inventor/actions/SoGLRenderAction.h>
#import <Inventor/C/tidbits.h>
#import <Inventor/elements/SoGLCacheContextElement.h>
#import <Inventor/nodekits/SoNodeKit.h>


@implementation SCControllerP
@end


#define PRIVATE(p) ((p)->_sc_controller)
#define SELF PRIVATE(self)


#pragma mark --- internal notifications ---

/*
  Used for triggering delayqueue sensors when idle.
*/

NSString * SCIdleNotification = @"_SC_IdleNotification";


#pragma mark --- static variables ---

/* 
  "global" NSTimer instance used for sensor queue handling. 
  This really should be a "class variable" in SCController, but
  there is no syntax for this in Objective-C.
*/ 
static NSTimer * _sc_timerqueuetimer;


#pragma mark --- callback functions ---

/*
  This function is the SoSceneManager render callback.  Will tell our
  drawable (typically an SCView, but can be any SCDrawable maintaining
  an OpenGL context) to redraw.  The invoked redraw method usually
  makes its OpenGL context active and calls SCController's -render
  method, but not necessarily synchronously.
*/

static void
redraw_cb(void * user, SoSceneManager *)
{
  SCController * controller = (SCController *)user; 
  [controller _SC_redraw];
  // Note that calling [PRIVATE(controller)->drawable display], like 
  // we used to, is not possible since PRIVATE(controller) expands to 
  // controller->_sc_controller, which is protected.
}


/*
  This function is the SoSensorManager change callback.  Note that in
  a multi-threaded Coin app, this callback can be called
  simultaneously from multiple threads.
*/

// FIXME: Make sure that this function and whatever is called
// is thread-safe and will execute tasks in the correct threads
// (e.g. rendering in the main thread) (kintel 20040616).

static void
sensorqueuechanged_cb(void * data)
{
  [SCController _SC_sensorQueueChanged];
}


/*
  Cleanup. This function will be called automatically when the application 
  programmer invokes SoDB::finish(). (A good place to do this is the 
  applicationWillTerminate: delegate function. Usually you do not need to 
  do this though - see the API documentation for SoDB::finish() for more 
  information.)
*/

static void atexit_cb(void)
{
  [SCController _SC_stopTimers]; 
}

/*
 Read an image from an external file into an SbImage instance.
 This the SbImage::addReadImageCB() callback/
 */
static SbBool readimage_cb(const SbString & filename, SbImage * image, void * closure)
{
  assert(image);
  
  NSImage *img = [[[NSImage alloc] initWithContentsOfFile:[NSString stringWithUTF8String:filename.getString()]] autorelease];
  if (!img) {
    SC21_DEBUG(@"NSImage initWithContentsOfFile: failed");
    return FALSE;
  }

  [img setFlipped:YES]; // To force image into Coin's format
  NSSize imgsize = [img size]; 
  [img lockFocus];
  NSBitmapImageRep* rep = [[[NSBitmapImageRep alloc] initWithFocusedViewRect: 
                            NSMakeRect(0, 0, imgsize.width, imgsize.height)] autorelease]; 
  [img unlockFocus]; 
  if (!rep) {
    SC21_DEBUG(@"NSBitmapImageRep initWithFocusedViewRect: failed");
    return FALSE;
  }
  
  SC21_DEBUG(@"NSBitmapImageRep created: %s %d %d %d %d %d %d %d", filename.getString(),
             [rep bitmapFormat],
             [rep bitsPerPixel],
             [rep bytesPerPlane],
             [rep bytesPerRow],
             [rep isPlanar],
             [rep numberOfPlanes],
             [rep samplesPerPixel]);
  
  int spp = [rep samplesPerPixel];
  int alpha = [rep hasAlpha] ? 1 : 0;
  
  int c;
  if (spp < 3) c = 1; // Grayscale
  else c = 3 + alpha;
  
  // FIXME: consider if we should detect grayscale with alpha (c = 2)
  
  SbVec2s imagesize(imgsize.width, imgsize.height);
  image->setValue(imagesize, c, NULL);
  unsigned char * imagebuffer = image->getValue(imagesize, c);
  
  if (c > 1 && [rep isPlanar]) {
    SC21_DEBUG(@"Planar images not supported for RGB(A) images");
    return FALSE;
  }
  
  unsigned char * repdata =  [rep bitmapData];
  if ([rep bytesPerRow] == imgsize.width * c) {
    // Copy image directly
    memcpy(imagebuffer, repdata, [rep bytesPerPlane]);
  }
  else {
    // Iterate over rowa
    SC21_DEBUG(@"Row size > width * components not supported");
    return FALSE;
  }
  
  return TRUE;
}

@implementation SCController

#if 0 // FIXME: Hold back property implementation until this can be done properly. kintel 20090326.
@dynamic clearsColorBuffer;
@dynamic clearsDepthBuffer;
@dynamic sceneGraph;
@synthesize eventHandler;
// FIXME: How do we document synthesized properties? kintel 20090325
/*" 
 Set the receiver's eventhandler, which will be the start of the
 eventhandler chain.(See handleEvent: for more information.)
 "*/
/*" 
 Returns the first eventhandler in the receiver's eventhandler chain. 
 "*/
#endif

/*" 
  An SCController is the main component for rendering Coin scene
  graphs. It handles all actual scene management and rendering,
  and passes events on to the eventhandler chain.

  The most basic setup of using an SCController is to have an
  SCSceneGraph, an SCView, and an SCController instance, connecting
  the SCView's !{controller} outlet to the SCController and the
  SCController's !{sceneGraph} outlet to the SCSceneGraph.

  Since Coin is a data driven API, redraws are usually requested by
  the scene graph itself. To handle these redraws, the controller must
  be given a "drawable" (an object conforming to the !{SCDrawable}
  protocol) that should called upon such a redraw request. See the
  SCDrawable and SCView documentation for more information.
"*/


#pragma mark --- static methods ----

/*" 
  Initializes Coin.

  SCController automatically calls this method if needed.

  You need to call this method explicitly only if you want to use Coin
  functionality before actually instantiating an SCController in your
  application (e.g. if you want to read a 3D model from disk and load
  the nib file containing your SCView and SCController only if the
  file was read successfully).

  This method calls !{SoDB::init()}, !{SoInteraction::init()} and
  !{SoNodeKit::init()}.
"*/

+ (void)initCoin
{       
  // This is _not_ done in +initialize since we want to allow people
  // to do smth. before initializing Coin.
  static BOOL initialized = NO;
  if (!initialized) {
    // FIXME: We should call the appropriate cleanup methods when we're done. kintel 20090325.
    SoDB::init();
    SoInteraction::init();
    SoNodeKit::init();
    SbImage::addReadImageCB(readimage_cb, NULL);
    [SCController _SC_startTimers]; 
    [SCOffscreenRenderer initialize];
#if 0
    // FIXME: Disabled until state of this function in Coin-2
    // has been resolved. 20050726 kyrah.
    cc_coin_atexit(atexit_cb);
#endif
    initialized = YES;
  }
}

#pragma mark --- initialization and cleanup ---

/*"
  Designated initializer.
  
  Initializes a newly allocated SCController and calls !{initCoin}.
"*/

- (id)init
{
  SC21_DEBUG(@"SCController.init");
  if (self = [super init]) {
    [self _SC_commonInit];
    SELF->clearcolorbuffer = YES;
    SELF->cleardepthbuffer = YES;
  }
  return self;
}


- (void)dealloc
{
  SC21_DEBUG(@"SCController.dealloc");
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self setSceneGraph:nil];
  [self setDrawable:nil];
  [self setEventHandler:nil];
  delete SELF->scenemanager;
  [SELF release];
  [super dealloc];
}


#pragma mark --- rendering ---

/*" 
  Renders the scene by calling the receiver's SoSceneManager's
  !{render()} funtion.  After rendering, an !{update:} message is sent
  to each eventhandler in the event handler chain, starting at the
  receiver's !{eventHandler}.
"*/

- (void)render
{
  // FIXME: Do clearing here instead of in SoSceneManager to support
  // alpha values? Alternatively, add SbColor4f support the necessary
  // places in Coin (kintel 20040502)

  if (SELF->drawable) {
    NSRect frame = [SELF->drawable frame];
    SELF->scenemanager->
      setViewportRegion(SbViewportRegion((short)frame.size.width,
                                         (short)frame.size.height));
    [[self->sceneGraph camera] updateClippingPlanes:self->sceneGraph];
    SELF->scenemanager->render(SELF->clearcolorbuffer, SELF->cleardepthbuffer);
    SCEventHandler * currenthandler = self->eventHandler;
    while (currenthandler) {
      [currenthandler update:self];
      currenthandler = [currenthandler nextEventHandler];
    }
  }
}


#pragma mark --- event handling ---

/*"
  Handle event by sending it down the eventhandler chain, starting at
  the receiver's !{eventHandler}. If !{eventHandler} returns !{NO},
  event is sent to the !{eventHandler}'s !{nextEventHandler}, and so
  on.

  Note that the Sc21 way of handling events is different from the one
  taken in Cocoa (where events are normally handled by NSView
  subclasses) - SCView just passes on all events to this method. (See
  the SCEventHandler documentation for more information on
  eventhandling in Sc21.)

  For overriding the default behavior of ctrl-clicks (context menu),
  see the documentation for SCView's !{-mouseDown:} method.
 
  Returns !{YES} if the event has been handled, !{NO} otherwise. 
"*/
 
- (BOOL)handleEvent:(NSEvent *)event
{
  SC21_LOG_METHOD;
  BOOL handled = NO;
  SCEventHandler * currenthandler = self->eventHandler;
  while (currenthandler &&
         !(handled = [currenthandler controller:self handleEvent:event])) {
    currenthandler = [currenthandler nextEventHandler];
  }
  return handled;
}

/*" 
 Set the receiver's eventhandler, which will be the start of the
 eventhandler chain.(See handleEvent: for more information.)
 "*/

- (void)setEventHandler:(SCEventHandler *)handler
{
  if (handler != self->eventHandler) {
    [self->eventHandler release];
    self->eventHandler = [handler retain];
  }
}


/*" 
 Returns the first eventhandler in the receiver's eventhandler chain. 
 "*/

- (SCEventHandler *)eventHandler
{
  return self->eventHandler;
}

#pragma mark --- accessor methods ---

/*" 
  Set the receiver's drawable. Note that you do not have to call this 
  method if you are using an SCView.
"*/

- (void)setDrawable:(id<SCDrawable>)newdrawable
{
  SELF->drawable = newdrawable;

  if (SELF->drawable) {
    [self sceneManager]->scheduleRedraw();
  }
}

/*" 
  Returns the receiver's drawable. 
"*/

- (id<SCDrawable>)drawable
{
  return SELF->drawable;
}


/*" 
  Sets the scene graph that shall be rendered. 
"*/

- (void)setSceneGraph:(SCSceneGraph *)sg
{
  if (sg == sceneGraph) { return; }
  
  if (sceneGraph) {
    // Remove ourselves as observer for the existing scenegraph
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                          name:SCRootChangedNotification
                                          object:sceneGraph];
    [sceneGraph release];
  }

  sceneGraph = [sg retain];

  if (sceneGraph) {
    // We want to be informed whenever the scenegraph's root node changes.
    [[NSNotificationCenter defaultCenter] addObserver:self
     selector:@selector(_SC_sceneGraphChanged:)
     name:SCRootChangedNotification
     object:sceneGraph];
  }
  [self _SC_sceneGraphChanged:nil];
}


/*" 
  Returns the receiver's scenegraph 
"*/

- (SCSceneGraph *)sceneGraph 
{ 
  return sceneGraph; 
}


/*" 
  Sets the receiver's scene manager to scenemanager. The scene manager's
  render callback will be set to SCController's internal redraw
  callback implementation; and scenemanager will be activated. Also,
  if a scenegraph has been set earlier, scenemanager's scenegraph will
  be set to it.
  
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
      SELF->scenemanager->setSceneGraph([sceneGraph _SC_superSceneGraph]);
      [sceneGraph _SC_setSceneManager:SELF->scenemanager];
    }
  }
}


/*" 
  Returns the receiver's Coin scene manager instance. 
"*/

- (SoSceneManager *)sceneManager 
{ 
  return SELF->scenemanager; 
}


/*" 
  Sets the background color of the scene to color. Raises an exception
  if color cannot be converted to an RGB color.
"*/

- (void)setBackgroundColor:(NSColor *)color
{
  NSColor * rgb = [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
  if (!rgb) {
    [NSException raise:NSInternalInconsistencyException
                format:@"setBackgroundColor: Color not convertible to RGB"];
  }
  
  CGFloat red, green, blue;
  [color getRed:&red green:&green blue:&blue alpha:NULL];
  
  SELF->scenemanager->setBackgroundColor(SbColor(red, green, blue));
  SELF->scenemanager->scheduleRedraw();  
}


/*"   
  Returns the scene's background color. 
"*/

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
  Controls whether the receiver should clear the color buffer before
  rendering. The default value is YES.
"*/

- (void)setClearsColorBuffer:(BOOL)yesno
{
  SELF->clearcolorbuffer = yesno;
}


/*"
  Returns YES if the receiver clears the color buffer before
  rendering. The default value is YES.
"*/

- (BOOL)clearsColorBuffer
{
  return SELF->clearcolorbuffer;
}


/*"
  Controls whether the receiver should clear the depth buffer before
  rendering. The default value is YES.
"*/

- (void)setClearsDepthBuffer:(BOOL)yesno
{
  SELF->cleardepthbuffer = yesno;
}


/*"
  Returns YES if the receiver clears the depth buffer before
  rendering. The default value is YES.
"*/

- (BOOL)clearsDepthBuffer
{
  return SELF->cleardepthbuffer;
}


#pragma mark --- NSCoding conformance ---

/*" 
  Encodes the receiver using encoder coder 
"*/

- (void)encodeWithCoder:(NSCoder *)coder
{
  if ([coder allowsKeyedCoding]) {
    [coder encodeBool:SELF->clearcolorbuffer 
           forKey:@"SC_clearcolorbuffer"];
    [coder encodeBool:SELF->cleardepthbuffer 
           forKey:@"SC_cleardepthbuffer"];
  }
}

/*" 
  Initializes a newly allocated SCController instance from the data in
  decoder. Returns !{self}
"*/
    
- (id)initWithCoder:(NSCoder *)coder
{
  if (self = [super init]) {
    [self _SC_commonInit];
    if ([coder allowsKeyedCoding]) {
      // We don't need to check for existence since these two keys
      // will always exist.
      SELF->clearcolorbuffer = [coder decodeBoolForKey:@"SC_clearcolorbuffer"];
      SELF->cleardepthbuffer = [coder decodeBoolForKey:@"SC_cleardepthbuffer"];
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
  
  [self setSceneManager:new SoSceneManager];
  SELF->hascreatedscenemanager = YES;

  [[NSNotificationCenter defaultCenter] 
    addObserver:[SCController class]
    selector:@selector(_SC_idle:) name:SCIdleNotification
    object:[SCController class]];

  [SCController _SC_sensorQueueChanged];
}

/*
  Timer callback function: process the timer sensor queue.
*/

+ (void)_SC_timerQueueTimerFired:(NSTimer *)t
{
  // SC21_DEBUG(@"_SC_timerQueueTimerFired:");
  SoDB::getSensorManager()->processTimerQueue();
  [SCController _SC_sensorQueueChanged];
}

/* 
  Process delay queue when application is idle. 
*/

+ (void)_SC_idle:(NSNotification *)notification
{
  SoDB::getSensorManager()->processTimerQueue();
  SoDB::getSensorManager()->processDelayQueue(TRUE);
  [SCController _SC_sensorQueueChanged];
}

/*
  Will reschedule timer sensors to trigger at the time of the first pending
  timer sensor in SoSensorManager (or deactivated if there are no pending 
  sensors).

  Will initiate idle processing if there are pending delay queue sensors.
*/

// FIXME: Rename to something more appropriate... ;)

+ (void)_SC_sensorQueueChanged
{
  SoSensorManager * sm = SoDB::getSensorManager();

  // If there are any pending SoTimerQueueSensors
  SbTime nexttimeout;
  if (sm->isTimerSensorPending(nexttimeout)) {
    SbTime interval = nexttimeout - SbTime::getTimeOfDay();
    [_sc_timerqueuetimer 
      setFireDate:[NSDate dateWithTimeIntervalSinceNow:interval.getValue()]];
  } else {
    [_sc_timerqueuetimer _SC_deactivate];
  }
  
  // If there are any pending SoDelayQueueSensors
  if (sm->isDelaySensorPending()) {
    [[NSNotificationQueue defaultQueue]
      enqueueNotification:
        [NSNotification notificationWithName:SCIdleNotification object:[SCController class]]
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
  
  [sceneGraph _SC_setSceneManager:SELF->scenemanager];
  if (SELF->scenemanager) {
    SELF->scenemanager->setSceneGraph([sceneGraph _SC_superSceneGraph]);
  }
    
  [[NSNotificationCenter defaultCenter]
    postNotificationName:SCSceneGraphChangedNotification object:self];
}


+ (void)_SC_startTimers
{
  // The timer will be controller from _SC_sensorQueueChanged,
  // so don't activate it yet.
  _sc_timerqueuetimer = [NSTimer scheduledTimerWithTimeInterval:1000
                                   target:self
                                   selector:@selector(_SC_timerQueueTimerFired:)
                                   userInfo:nil 
                                   repeats:YES];
  [_sc_timerqueuetimer _SC_deactivate];
  [[NSRunLoop currentRunLoop] addTimer:_sc_timerqueuetimer 
                               forMode:NSModalPanelRunLoopMode];
  [[NSRunLoop currentRunLoop] addTimer:_sc_timerqueuetimer 
                               forMode:NSEventTrackingRunLoopMode];
  
  SoDB::getSensorManager()->setChangedCallback(sensorqueuechanged_cb, NULL);
}


/* 
  Stops and releases the timers for timer queue and delay queue
  processing.
*/

+ (void)_SC_stopTimers
{
  if (_sc_timerqueuetimer && [_sc_timerqueuetimer isValid]) {
    // Note that the NSRunLoop will remove and release the timer, 
    // so we should not release the timer ourselves here. 
    [_sc_timerqueuetimer invalidate];
    _sc_timerqueuetimer = nil;
  }
  // At this point, all Coin resources have been cleaned up already, so 
  // don't try to set the SoSensorManager's changedCallback back to 
  // (NULL, NULL) here!
}


/* 
  Redraw the scene by calling the drawable's display method. 
*/

- (void)_SC_redraw
{
  [SELF->drawable display];
}

@end
