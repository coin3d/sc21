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
 

#import "SCController.h"
#import "SCView.h"

#import <Inventor/SoDB.h>
#import <Inventor/SoInteraction.h>
#import <Inventor/SoSceneManager.h>
#import <Inventor/SbViewportRegion.h>
#import <Inventor/actions/SoGLRenderAction.h>
#import <Inventor/actions/SoSearchAction.h>
#import <Inventor/actions/SoWriteAction.h>
#import <Inventor/elements/SoGLCacheContextElement.h>
#import <Inventor/manips/SoHandleBoxManip.h>
#import <Inventor/nodekits/SoNodeKit.h>
#import <Inventor/nodes/SoCamera.h>
#import <Inventor/nodes/SoCone.h>
#import <Inventor/nodes/SoDrawStyle.h>
#import <Inventor/nodes/SoLight.h>
#import <Inventor/nodes/SoTranslation.h>
#import <Inventor/nodes/SoSelection.h>
#import <Inventor/nodes/SoSeparator.h>
#import <Inventor/nodes/SoRotor.h>
#import <Inventor/nodes/SoCylinder.h>
#import <Inventor/nodes/SoSphere.h>

#import <OpenGL/gl.h>

@interface SCController (InternalAPI)
- (void) _processTimerQueue:(NSTimer *) t;
- (void) _processDelayQueue:(NSTimer *) t;
- (SoLight *) _findLightInSceneGraph:(SoGroup *)root;
- (SoCamera *) _findCameraInSceneGraph:(SoGroup *) root;
- (void) _setInternalSceneGraph:(SoGroup *)root;
- (void) _handleLighting;
- (void) _handleCamera;
@end  


// -------------------- Callback function ------------------------

static void
redraw_cb(void * user, SoSceneManager * manager) {
  SCView * view = (SCView *) user;
//FIXME: We should be able to remove this (kintel 20040326)
//Why is it here?
  [view drawRect:[view frame]]; // do actual drawing
  [view setNeedsDisplay:YES];   // needed to get redraw when view is not active
}


// Obj-C does not support class variables, so: static...
static BOOL _coinInitialized = NO;


// ---------------------- Notifications ----------------------------

NSString * SCModeChangedNotification = @"SCModeChangedNotification";
NSString * SCSceneGraphChangedNotification = @"SCSceneGraphChangedNotification";
NSString * SCNoCameraFoundInSceneNotification = @"SCNoCameraFoundInSceneNotification";
NSString * SCNoLightFoundInSceneNotification = @"SCNoLightFoundInSceneNotification";

@implementation SCController

/*" An SCController is the main component for rendering Coin 
    scenegraphs to an SCView. It handles all actual scene management, 
    rendering, event translation etc.
    
    Note that for displaying the rendered scene, you need an SCView.
    Connect SCController's !{view} outlet to a valid SCView instance
    to use SCController.
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

+ (void) initCoin
{
  SoDB::init();
  SoInteraction::init();
  SoNodeKit::init();
  _coinInitialized = YES;
}
 

// ----------------- initialization and cleanup ----------------------

/*" Initializes a newly allocated SCController, and calls #initCoin
    By default, events will be interpreted as viewer events (see 
    #handleEvent: documentation for more information about
    the event handling model).

    This method is the designated initializer for the SCController
    class. Returns !{self}.
 "*/

- (id) init
{
  if (self = [super init]) {
    [self commonInit];
  }
  return self;
}


/*" Shared initialization code that is called both from #init:
    and #initWithCoder: If you override this method, you must
    call !{[super commonInit]} as the first call in your
    implementation to make sure everything is set up properly.
"*/

- (void) commonInit
{
  if (!_coinInitialized) [SCController initCoin];
  _camera = [[SCCamera alloc] init];
  [_camera setController:self];
  _autoclipvalue = 0.6;
  _handleseventsinviewer = YES;
  _eventconverter = [[SCEventConverter alloc] initWithController:self];
}

/*" Sets up and activates the Coin scenemanager and sets up the timers
    for animation.

    Note: You %must call this method, or else things will not work.
    A good place to do this is in your #awakeFromNib or
    #applicationDidFinishLaunching method.
"*/

- (void) activate
{
  _scenemanager = new SoSceneManager;
  _scenemanager->setRenderCallback(redraw_cb, (void*) view);
  _scenemanager->setBackgroundColor(SbColor(0.0f, 0.0f, 0.0f));
  _scenemanager->getGLRenderAction()->setCacheContext(
    SoGLCacheContextElement::getUniqueCacheContext());
  _scenemanager->activate();

  if (_scenegraph == NULL) {
    [self setSceneGraph:NULL];
  } else {
    _scenemanager->setSceneGraph(_scenegraph); 
  }
  
  // FIXME: The timer and delay queue handling here is very
  // primitive and should be re-written. Currently, we are processing
  // the queues even if there are no pending sensors. The problem
  // why it is not straightforward to use the approach in SoQt is
  // NSTimer does not allow you to start/stop the timer - you have
  // to invalidate it and create a new one.
  // Also, there is not really a concept of "application is idle"
  // in cocoa, so the delay queue is currently only processed once
  // every millisecond. (Might be able to use NSNotificationQueue
  // with style NSPostWhenIdle, I'll have to verify that.)
  // kyrah 20030713

  // Setup timers.
  _timerqueuetimer = [[NSTimer scheduledTimerWithTimeInterval:0.001 target:self
    selector:@selector(_processTimerQueue:) userInfo:nil repeats:YES] retain];
  _delayqueuetimer = [[NSTimer scheduledTimerWithTimeInterval:0.001 target:self
    selector:@selector(_processDelayQueue:) userInfo:nil repeats:YES] retain];

  [[NSRunLoop currentRunLoop] addTimer:_timerqueuetimer forMode:NSModalPanelRunLoopMode];
  [[NSRunLoop currentRunLoop] addTimer:_delayqueuetimer forMode:NSModalPanelRunLoopMode];
  [[NSRunLoop currentRunLoop] addTimer:_timerqueuetimer forMode:NSEventTrackingRunLoopMode];
  [[NSRunLoop currentRunLoop] addTimer:_delayqueuetimer forMode:NSEventTrackingRunLoopMode];
  
}

/* Clean up after ourselves. */
- (void) dealloc
{
  // FIXME: release timers. Disabled since it causes a
  // freak crash in IB. kyrah 20030714
  [view release];
  [_eventconverter release];
  [_camera release];
  delete _scenemanager;
  [super dealloc];
}


// ------------ getting the view associated with the controller -------

/*" Set the view to newview. newview is retained by the controller. "*/

- (void) setView:(SCView *)newview
{
  [newview retain];
  [view release];
  view = newview;
}

/*" Returns the SCView the SCController's view outlet is connected to. "*/

- (SCView *) view 
{ 
  return view; 
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

- (void) setSceneGraph:(SoGroup *)scenegraph
{
  if (scenegraph == _scenegraph) return;
  if (scenegraph == NULL) scenegraph = new SoSeparator;

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

- (SoGroup *) sceneGraph 
{ 
  return _scenegraph; 
}

/*" Sets the current scene manager to scenemanager. The scene manager's
    render callback will be set to %redraw_cb (SCController's default
    redraw callback), and it will be activated. Also, if a scenegraph
    has been set earlier, scenemanager's scenegraph will be set to it.

    Note that you should not normally need to call that method, since a
    scene manager is created for you in #activate. 
 "*/

- (void) setSceneManager:(SoSceneManager *) scenemanager
{
  _scenemanager = scenemanager;
  _scenemanager->setRenderCallback(redraw_cb, (void*) view);
  _scenemanager->getGLRenderAction()->setCacheContext(
    SoGLCacheContextElement::getUniqueCacheContext());
  _scenemanager->activate();
  if (_scenegraph) _scenemanager->setSceneGraph(_scenegraph);
}

/*" Returns the current Coin scene manager instance. "*/

- (SoSceneManager *) sceneManager 
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

- (void) setAutoClipValue:(float)autoclipvalue
{
  _autoclipvalue = autoclipvalue;
}

/*" Returns the current autoclipvalue. The default value is 0.6. "*/

- (float) autoClipValue
{
  return _autoclipvalue;
}


/*" Sets the SoCamera used for viewing the scene to cam.
    It is first checked if the scenegraph contains a camera created by
    the controller, and if yes, this camera is deleted.

    Note that cam is expected to be part of the scenegraph already;
    it is not inserted into it.
"*/

- (void) setCamera:(SoCamera *) cam
{
  [_camera setSoCamera:cam deleteOldCamera:YES];
}

/*" Returns the current SoCamera used for viewing. "*/

- (SoCamera *) camera
{
  return [_camera soCamera];
}

/*" Returns !{SCCameraPerspective} if the camera is perspective
    and !{SCCameraOrthographic} if the camera is orthographic.
 "*/

- (SCCameraType) cameraType
{
  return [_camera type];
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

    Note that if you press the left mouse button while holding
    down the ctrl key, you will not receive a mouseDown event.
    Instead, the view's default context menu will be shown. (This
    behavior in SCView is inherited from NSView.) If you want to handle
    ctrl-click yourself, you have to subclass SCView and override
    #{- (NSMenu *)menuForEvent:(NSEvent *)event} to return nil and
    pass on the event to the controller "manually" - 
    !{[controller handleEvent:event]} - so that it can be handled here.
"*/
 
- (BOOL) handleEvent:(NSEvent *) event
{
  if ([self handlesEventsInViewer] == NO) {
    return [self handleEventAsCoinEvent:event];
  } else {
    return [self handleEventAsViewerEvent:event];
  }
}

/*" Handles event as Coin event, i.e. creates an SoEvent and passes 
    it on to the scenegraph.

    Returns !{YES} if the event has been handled, !{NO} otherwise.
 "*/
 
- (BOOL) handleEventAsCoinEvent:(NSEvent *) event
{
  SoEvent * se = [_eventconverter createSoEvent:event];
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

    The default implementation pops up a context menu when the right mouse
    button has been pressed, and does nothing otherwise. Use
    SCExaminerController to get built-in functionality for examining
    the scene (camera control through the mouse etc.).
 "*/
 
- (BOOL) handleEventAsViewerEvent:(NSEvent *) event
{
  if ([event type] == NSRightMouseDown) {
    [NSMenu popUpContextMenu:[view menu] withEvent:event forView:view];
    return YES;
  }
  return NO;
}

/*" Sets whether events should be interpreted as viewer events, i.e.
    are regarded as input for controlling the viewer (yn == YES), or 
    should be sent to the scene graph directly (yn = NO) 
"*/
 
- (void) setHandlesEventsInViewer:(BOOL)yn
{
  _handleseventsinviewer = yn;
  [[NSNotificationCenter defaultCenter] postNotificationName:SCModeChangedNotification object:self];
}


/*" Returns TRUE if events are interpreted as viewer events, i.e.
    are regarded as input for controlling the viewer. Returns 
    FALSE if events are sent to the scene graph directly.
 "*/

- (BOOL) handlesEventsInViewer
{
  return _handleseventsinviewer;
}

// -------------------- Timer management. ----------------------


/*" Stops and releases the timers for timer queue and delay queue
    processing.
 "*/

- (void) stopTimers
{
  if ([_timerqueuetimer isValid]) [_timerqueuetimer invalidate];
  if ([_delayqueuetimer isValid]) [_delayqueuetimer invalidate];
}

/*" Sets the frequency how often we process the timer sensor queue,
    in seconds. Default value is 0.001.
 "*/

- (void) setTimerInterval:(NSTimeInterval) interval
{
  if ([_timerqueuetimer timeInterval] == interval) return;
  if ([_timerqueuetimer isValid]) [_timerqueuetimer invalidate];
  
  _timerqueuetimer = [[NSTimer scheduledTimerWithTimeInterval:interval target:self
    selector:@selector(_processTimerQueue:) userInfo:nil repeats:YES] retain];

  [[NSRunLoop currentRunLoop] addTimer:_timerqueuetimer forMode:NSModalPanelRunLoopMode];
  [[NSRunLoop currentRunLoop] addTimer:_timerqueuetimer forMode:NSEventTrackingRunLoopMode];
}


/*" Returns the frequency how often we process the timer sensor
    queue.
 "*/

- (NSTimeInterval) timerInterval
{
  return [_timerqueuetimer timeInterval];
}


/*" Sets the frequency how often we process the delay sensor queue,
    in seconds. Default value is 0.001.

    Note: Do not use the SoSensorManager::setDelaySensorTimeout()
    method - the value set by that function is ignored. Use this
    function here instead.
"*/

- (void) setDelayQueueInterval:(NSTimeInterval) interval
{
  if ([_delayqueuetimer timeInterval] == interval) return;
  if ([_delayqueuetimer isValid]) [_delayqueuetimer invalidate];

  _delayqueuetimer = [[NSTimer scheduledTimerWithTimeInterval:interval target:self
  selector:@selector(_processDelayQueue:) userInfo:nil repeats:YES] retain];

  [[NSRunLoop currentRunLoop] addTimer:_delayqueuetimer forMode:NSModalPanelRunLoopMode];
  [[NSRunLoop currentRunLoop] addTimer:_delayqueuetimer forMode:NSEventTrackingRunLoopMode];
}


/*" Returns the frequency how often we process the delay sensor 
    queue.
"*/

- (NSTimeInterval) delayQueueInterval
{
  return [_delayqueuetimer timeInterval];
}

// ----------------- Debugging aids ----------------------------

/*" Returns debugging information about the OpenGL implementation
    (vendor, renderer, version, available extensions, limitations),
    the Coin version we are using, and the current OpenGL settings
    (color depth, z buffer, accumulation buffer).
 "*/

- (NSString *) debugInfo;
{
  GLint depth;
  GLint colors[4];
  GLint accum[4];
  GLint maxviewportdims[2];
  GLint maxtexsize, maxlights, maxplanes;

  GLboolean doublebuffered;

  const char * coinversion = SoDB::getVersion();
  
  const GLubyte * vendor = glGetString(GL_VENDOR);
  const GLubyte * renderer = glGetString(GL_RENDERER);
  const GLubyte * version = glGetString(GL_VERSION);
  const GLubyte * extensions = glGetString(GL_EXTENSIONS);

  glGetIntegerv(GL_DEPTH_BITS, &depth);
  glGetIntegerv(GL_RED_BITS, &colors[0]);
  glGetIntegerv(GL_GREEN_BITS, &colors[1]);
  glGetIntegerv(GL_BLUE_BITS, &colors[2]);
  glGetIntegerv(GL_ALPHA_BITS, &colors[3]);
  glGetIntegerv(GL_ACCUM_RED_BITS, &accum[0]);
  glGetIntegerv(GL_ACCUM_GREEN_BITS, &accum[1]);
  glGetIntegerv(GL_ACCUM_BLUE_BITS, &accum[2]);
  glGetIntegerv(GL_ACCUM_ALPHA_BITS, &accum[3]);
  glGetIntegerv(GL_MAX_VIEWPORT_DIMS, maxviewportdims);
  glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxtexsize);
  glGetIntegerv(GL_MAX_LIGHTS, &maxlights);
  glGetIntegerv(GL_MAX_CLIP_PLANES, &maxplanes);
  glGetBooleanv(GL_DOUBLEBUFFER, &doublebuffered);

  NSMutableString * info = [NSMutableString stringWithCapacity:100];
  [info appendFormat:@"Coin version: %s\n", coinversion];
  [info appendFormat:@"OpenGL version: %s\n", (const char *)version];
  [info appendFormat:@"Vendor: %s\n", (const char *)vendor];
  [info appendFormat:@"Renderer: %s\n", (const char *)renderer];
  [info appendFormat:@"Color depth (RGBA): %d, %d, %d, %d\n",
    colors[0], colors[1], colors[2], colors[3]];
  [info appendFormat:@"Accumulation buffer depth (RGBA): %d, %d, %d, %d\n",
    accum[0], accum[1], accum[2], accum[3]];
  [info appendFormat:@"Depth buffer: %d\n", depth];
  [info appendFormat:@"Doublebuffering: %s\n", doublebuffered ? "on" : "off"];
  [info appendFormat:@"Maximum viewport dimensions: <%d, %d>\n",
    maxviewportdims[0], maxviewportdims[1]];
  [info appendFormat:@"Maximum texture size: %d\n", maxtexsize];
  [info appendFormat:@"Maximum number of lights: %d\n", maxlights];
  [info appendFormat:@"Maximum number of clipping planes: %d\n", maxplanes];
  [info appendFormat:@"OpenGL extensions: %s\n", (const char *)extensions];

  return info;
}



/*" Writes the current scenegraph to a file. The filename will be
    XXX-dump.iv, where XXX is a number calculated based on the
    current time. The file will be stored in the current working
    directory. Returns !{NO} if there was an error writing the file,
    !{YES} otherwise.
"*/

- (BOOL) dumpSceneGraph
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
  return NO;
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
    [self commonInit];
  }
  return self;
}


// ----------------------- InternalAPI -------------------------

/* Timer callback function: process the timer sensor queue. */

- (void) _processTimerQueue:(NSTimer *)t
{
  SoDB::getSensorManager()->processTimerQueue();
}

/* Timer callback function: process the delay queue. */

- (void) _processDelayQueue:(NSTimer *)t
{
  SoDB::getSensorManager()->processDelayQueue(FALSE);
}


- (void) _setInternalSceneGraph:(SoGroup *)root
{
  _scenegraph = root;
}

- (void) _handleLighting
{
  if (![self _findLightInSceneGraph:_scenegraph]) {
    [[NSNotificationCenter defaultCenter]
      postNotificationName:SCNoLightFoundInSceneNotification object:self];
  }
}


/* Find light in root. Returns a pointer to the light, if found,
    otherwise NULL.
 */

- (SoLight *) _findLightInSceneGraph:(SoGroup *) root
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
    SoFullPath * fullpath = (SoFullPath *)sa.getPath();
    light = (SoLight *)fullpath->getTail();
  }
  return light;
}


/*" Find camera in root. Returns a pointer to the camera, if found,
    otherwise NULL.
"*/

- (SoCamera *) _findCameraInSceneGraph:(SoGroup *) root
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
    SoFullPath * fullpath = (SoFullPath *)sa.getPath();
    scenecamera = (SoCamera *)fullpath->getTail();
  }
  return scenecamera;
}

- (void) _handleCamera
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

@end



