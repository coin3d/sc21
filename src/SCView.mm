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
 
#import <SC21/SCView.h>
#import <SC21/SCController.h>
#import <SC21/SCExaminerController.h>
#import <SC21/SCCursors.h>

@implementation SCView

/*" An SCView displays a Coin scene graph. It also provides convenience 
    methods for initializing and re-initializing the OpenGL subsystem
    and querying the current OpenGL state information.

    Note that all actual Coin scene management, rendering, event 
    translation, etc is done by the SCController class and its 
    subclasses. Connect SCView's !{controller} outlet to a valid
    SCController instance to use SCView.
 "*/



// ----------------- initialization and cleanup ----------------------

// A note on Interface Builder archive initialization order
// (from the NSNibAwaking protocol documentation):
//
//   1. initWithCoder:
//   2. initialization with properties specified in IB (using
//      setVariable:)
//   3. awakeFromNib:
//
// When an object receives an awakeFromNib message, it's guaranteed
// to have all its outlet instance variables set -- so don't try to
// messages to other objects in the archive in init: 

+ (void)initialize
{
  [SCView setVersion:1];
}

/*"
  Designated initializer.
 "*/
- (id)initWithFrame:(NSRect)rect pixelFormat:(SCOpenGLPixelFormat *)format
{
  if (self = [super initWithFrame:rect pixelFormat:format]) {
    // flush buffer only during the vertical retrace of the monitor
    const long int vals[1] = {1};
    [[self openGLContext] setValues:vals forParameter:NSOpenGLCPSwapInterval];
    [[self openGLContext] makeCurrentContext];
    [self commonInit];
  }
  return self;
  
}

/*" Initializes a newly allocated SCView with rect as its frame
    rectangle. Sets up an OpenGL context with default values
    32 bit color and 32 bit depth buffer. Override the
    #{createPixelFormat:} method if you need to set custom
    NSOpenGLPixelFormat settings.

    If no valid pixel format could be created, an
    %SCCouldNotCreateValidPixelFormatNotification is posted,
    the object is deallocated, and !{nil} is returned.

    Calls #commonInit, which contains common initialization
    code needed both in #initWithFrame: and #initWithCoder.
 "*/

- (id)initWithFrame:(NSRect)rect
{
  NSLog(@"SCView.initWithFrame:");

  SCOpenGLPixelFormat * pixelFormat = [self createPixelFormat:rect];
  return [self initWithFrame:rect pixelFormat:pixelFormat];
}


/*" Shared initialization code that is called both from #init:
    and #initWithCoder: If you override this method, you must
    call !{[super commonInit]} as the first call in your
    implementation to make sure everything is set up properly.
"*/

- (void)commonInit
{
}


/*" Recreates the OpenGL context if the settings have been changed
    from within Interface builder. Called after the object has been 
    loaded from an Interface Builder archive or nib file. 
 "*/

- (void)awakeFromNib
{
  NSLog(@"SCView.awakeFromNib");
  [self recreateOpenGLContext];
}


- (void)dealloc
{
  NSLog(@"SCView.dealloc");
  // Prevent controller from continuing to draw into our view.
  [controller stopTimers];
  [controller release];
  [super dealloc];
}


// ---------------------- Accessing SCController --------------------

/*" Returns the currently used SCController. "*/
- (SCController *)controller
{
  return controller;  
}


/*" Set the controller to newcontroller. newcontroller is
    retained.
 "*/

- (void)setController:(SCController *)newcontroller
{
  [newcontroller retain];
  [controller release];
  controller = newcontroller;
  // Use [self display] as a redraw handler
  [controller setRedrawHandler:self];
  [self reshape]; // Initialize viewport
}


// ------------------------- OpenGL setup ---------------------------

/*" Recreate OpenGL context with the current settings. Returns
    !{TRUE} if the reinitialization was successful, and !{FALSE}
    if any error occured.

    This method is invoked whenever the color or depth buffer
    settings are changed through the #{setColorBits:} or
    #{setDepthBits:} methods. To change these settings without
    immediately recreating the context, call
    #{setColorBitsNoRecreate:} or #{setDepthBitsNoRecreate:}
    instead.
 "*/
//FIXME: This method should be removed from SCView. context issues should
//be handled by SCOpenGLView.
- (BOOL)recreateOpenGLContext
{
  // FIXME: Shouldn't we inform Coin about the context change?
  // Test with textures and display lists! kyrah 20030616
    
  BOOL success = FALSE;
  SCOpenGLPixelFormat * pixelFormat;
  NSOpenGLContext * newContext;
  success = NO;

  [[self openGLContext] clearDrawable];
  
  pixelFormat = [self createPixelFormat:[self frame]];
  if (pixelFormat) {
    newContext = [[[NSOpenGLContext alloc] initWithFormat:[pixelFormat pixelFormat] shareContext:nil] autorelease];
    if (newContext) {
      const long int vals[1] = {1};
      [super setFrame:[self frame]];
      [super setOpenGLContext:newContext];
      // flush buffer only during the vertical retrace of the monitor
      [newContext setValues:vals forParameter:NSOpenGLCPSwapInterval];
      [newContext makeCurrentContext];
      success = TRUE;
    }
  }
  [self setNeedsDisplay:YES];
  return success;
}

/*" Returns a double buffered, accelerated pixel format. The 
    colordepth and depth are the current values as set by
    #setColorBits: and #setDepthBits: (or #setColorBitsNoRecreate: 
    and #setDepthBitsNoRecreate:) respectively. Override this
    method if you need specific settings.
 "*/
 
- (SCOpenGLPixelFormat *)createPixelFormat:(NSRect)frame
{
  SCOpenGLPixelFormat *pixelFormat = [[SCOpenGLPixelFormat alloc] init];
  [pixelFormat setAttribute:NSOpenGLPFADoubleBuffer];
  [pixelFormat setAttribute:NSOpenGLPFAAccelerated];
  [pixelFormat setAttribute:NSOpenGLPFAAccumSize toValue:32];
  [pixelFormat setAttribute:NSOpenGLPFAColorSize toValue:32];
  [pixelFormat setAttribute:NSOpenGLPFAAlphaSize toValue:8];
  [pixelFormat setAttribute:NSOpenGLPFADepthSize toValue:32];
  [pixelFormat autorelease];
  return pixelFormat;
}


// ------------------ viewing and drawing --------------------------------

/*" Renders the current scene graph into frame rectangle rect by
    setting the OpenGL state (enable lighting and z buffering)
    and then calling SCController's #render: method.

"*/

- (void)drawRect:(NSRect)rect
{
  NSLog(@"SCview.drawRect");
  // Note: As NSView's implementation of this method, #drawRect: is
  // intended to be completely overridden by each subclass that
  // performs drawing, do _not_ invoke [super drawRect] here!
  
  // FIXME: Remove: This is done by SoSceneManager::render()
  // FIXME: Make clearing configurable, as in So@Gui@ ? (kintel 20040406)
  glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT ); 
  // FIXME: do this only once, after creating a context and binding it
  // (kintel 20040323)
  glEnable(GL_DEPTH_TEST);
  glEnable(GL_LIGHTING);
  [controller render];
  [[self openGLContext] flushBuffer];
}


/*" Informs the SCView's %controller of the size change by
    calling its #viewSizeChanged: method, and updates the
    OpenGL context.
 "*/

- (void)reshape
{
  [controller viewSizeChanged:[self visibleRect]];
  if ([[self openGLContext] view] == self) [[self openGLContext] update];
}


// ----------- Mouse and keyboard event handling --------------------------

/*" Forwards event to %controller by sending it the #handleEvent:
    message.  If the event is not handled by the controller, it will
    be forwarded through the responder chain as usual.

    Note that if you press the left mouse button while holding
    down the ctrl key, you will not receive a mouseDown event.
    Instead, the view's default context menu will be shown. (This
    behavior is inherited from NSView.) If you want to handle
    ctrl-click yourself, you have to subclass SCView and override
    #{- (NSMenu *)menuForEvent:(NSEvent *)event} to return nil.
    This will cause the event to be passed on to this function.
 "*/

- (void)mouseDown:(NSEvent *)event
{
  if (![controller handleEvent:event inView:self]) {
    [super mouseDown:event];
  }
}


/*" Forwards event to %controller by sending it the #handleEvent:
    message.  If the event is not handled by the controller, it will
    be forwarded through the responder chain as usual. 
 "*/

- (void)mouseUp:(NSEvent *)event
{
  if (![controller handleEvent:event inView:self]) {
    [super mouseUp:event];
  }
}


/*" Forwards event to %controller by sending it the #handleEvent: 
    message. If the event is not handled by the controller, it will
    be forwarded through the responder chain as usual.

    Note that when processing "mouse dragged" events, Coin does not
    distinguish between left and right mouse button. If you interested
    in that information, you have to evaluate the last mouseDown that
    occured before the dragging.
 "*/

- (void)mouseDragged:(NSEvent *)event
{
  if (![controller handleEvent:event inView:self]) {
    [super mouseDragged:event];
  }
}


/*" Forwards event to %controller by sending it the #handleEvent: 
    message. If the event is not handled by the controller, it will
    be forwarded through the responder chain as usual.
 "*/

- (void)rightMouseDown:(NSEvent *)event
{
  if (![controller handleEvent:event inView:self]) {
    [super rightMouseDown:event];
  }
}


/*" Forwards event to %controller by sending it the #handleEvent: 
    message. If the event is not handled by the controller, it will
    be forwarded through the responder chain as usual.
 "*/

- (void)rightMouseUp:(NSEvent *)event
{
  if (![controller handleEvent:event inView:self]) {
    [super rightMouseUp:event];
  }
}

/*" Forwards event to %controller by sending it the #handleEvent: 
    message. If the event is not handled by the controller, it will
    be forwarded through the responder chain as usual.

    Note that when processing "mouse dragged" events, Coin does not
    distinguish between left and right mouse button. If you interested
    in that information, you have to evaluate the last mouseDown that
    occured before the dragging.
 "*/

- (void)rightMouseDragged:(NSEvent *)event
{
  if (![controller handleEvent:event inView:self]) {
    [super rightMouseDragged:event];
  }
}


/*" Forwards event to %controller by sending it the #handleEvent: 
    message.  If the event is not handled by the controller, it will
    be forwarded through the responder chain as usual 
 "*/

- (void)otherMouseDown:(NSEvent *)event
{
  if (![controller handleEvent:event inView:self]) {
    [super otherMouseDown:event];
  }
}


/*" Forwards event to %controller by sending it the #handleEvent: 
    message.  If the event is not handled by the controller, it will
    be forwarded through the responder chain as usual. 
 "*/

- (void)otherMouseUp:(NSEvent *)event
{
  if (![controller handleEvent:event inView:self]) {
    [super otherMouseUp:event];
  }
}


/*" Forwards event to %controller by sending it the #handleEvent: 
    message. If the event is not handled by the controller, it will
    be forwarded through the responder chain as usual.

    Note that when processing "mouse dragged" events, Coin does not
    distinguish between left and right mouse button. If you interested
    in that information, you have to evaluate the last mouseDown that
    occured before the dragging.
 "*/

- (void)otherMouseDragged:(NSEvent *)event
{
  if (![controller handleEvent:event inView:self]) {
    [super otherMouseDragged:event];
  }
}

/*" Forwards event to %controller by sending it the #handleEvent: 
    message.  If the event is not handled by the controller, it will
    be forwarded through the responder chain as usual.
 "*/

- (void)scrollWheel:(NSEvent *)event
{
  if (![controller handleEvent:event inView:self]) {
    [super scrollWheel:event];
  }
}


/*" Forwards event to %controller by sending it the #handleEvent:
    message.  If the event is not handled by the controller, it will
    be forwarded through the responder chain as usual.
 "*/

- (void)keyDown:(NSEvent *)event 
{
  if (![controller handleEvent:event inView:self]) {
    [super keyDown:event];
  } 
}


/*" Forwards event to %controller by sending it the #handleEvent:
    message.  If the event is not handled by the controller, it will
    be forwarded through the responder chain as usual.
 "*/

- (void)keyUp:(NSEvent *)event 
{
  if (![controller handleEvent:event inView:self]) {
    [super keyUp:event];
  } 
}

/*" Returns !{YES} to accept becoming first responder.
    Needed to receive keyboard events
 "*/

-(BOOL)acceptsFirstResponder
{
  return YES;
}

// -------- Cursor handling ----------
- (void)resetCursorRects
{
  NSLog(@"SCView.resetCursorRects");
  [self addCursorRect:[self visibleRect] cursor:_cursor];
}

- (void)setCursor:(NSCursor *)cursor
{
  _cursor = cursor;
  [_cursor set];
}


// ----------------------- NSCoding -------------------------
// FIXME: Rewrite to use keyed archiving (kintel 20030324)
// FIXME: Also support old 10.1 style archiving? (kintel 20030324)

/*" Encodes the SCView using encoder coder "*/

- (void)encodeWithCoder:(NSCoder *)coder
{
  NSLog(@"SCView.encodeWithCoder:");
  [super encodeWithCoder:coder];
}

/*!
  This method is here only to support reading nib files created with
  SC21 public beta.

  Here we decode the old instance variables, colorbits and depthbits,
  and copy all relevant settings from the old view.

  FIXME: We should remove this after a grace period (say SC21 V1.0.1)
  (kintel 20040404)
*/
- (id)awakeAfterUsingCoder:(NSCoder *)coder
{
  NSLog(@"SCView.awakeAfterUsingCoder:");
  if (_oldview) {
    NSLog(@"  upgrading old instance.");
    int colorbits, depthbits;
    [coder decodeValueOfObjCType:@encode(int) at:&colorbits];
    [coder decodeValueOfObjCType:@encode(int) at:&depthbits];
    NSLog(@"  colorbits: %d, depthbits: %d", colorbits, depthbits);
    //FIXME: Copy these as well:
    // colorbits, depthbits, pixel format attributes
    // (kintel 20040404)
    if (self = [self initWithFrame:[_oldview frame]]) {
      _superview = [_oldview superview];
      [self setMenu:[_oldview menu]];
      [self setInterfaceStyle:[_oldview interfaceStyle]];
      [self setHidden:[_oldview isHidden]];
      [self setNextKeyView:[_oldview nextKeyView]];
      [self setBounds:[_oldview bounds]];
      if ([_oldview isRotatedFromBase]) {
        [self setFrameRotation:[_oldview frameRotation]];
        [self setBoundsRotation:[_oldview boundsRotation]];
      }
      [self setPostsFrameChangedNotifications:[_oldview postsFrameChangedNotifications]];
      [self setPostsBoundsChangedNotifications:[_oldview postsBoundsChangedNotifications]];
      [self setAutoresizingMask:[_oldview autoresizingMask]];
      [self setToolTip:[_oldview toolTip]];
      [_oldview release];
      _oldview = nil;
      [self commonInit];
    }
  }
  return self;
}

/*" Initializes a newly allocated SCView instance from the data
    in decoder. Returns !{self}.

    Calls #commonInit, which contains common initialization
    code needed both in #init and #initWithCoder.
 "*/

- (id)initWithCoder:(NSCoder *)coder
{
  NSLog(@"SCView.initWithCoder:");
  // This is support for reading archives from SC21 public beta
  // FIXME: We should remove this after a grace period (say SC21 V1.0.1)
  // (kintel 20040404)
  if ([coder versionForClassName:@"SCView"] == 0) {
    _oldview = [[NSOpenGLView alloc] initWithCoder:coder];
    return self;
#if 0 
    // Old try that didn't work. Keep here until we know that the
    // new code works.
    NSOpenGLView * oldview = 
      [[[NSOpenGLView alloc] initWithCoder:coder] autorelease];

    if (oldview) {
      // Enable initialization of an NSView from a coder also containing
      // an NSOpenGLView without having to initialize the NSOpenGLView
      NSData * data = [NSArchiver archivedDataWithRootObject:oldview];
      NSCoder * oldcoder = 
        [[[NSUnarchiver alloc] initForReadingWithData:data] autorelease];
      if (self = [self _compatInitWithCoder:oldcoder]) {
        int colorbits, depthbits;
        [coder decodeValueOfObjCType:@encode(int) at:&colorbits];
        [coder decodeValueOfObjCType:@encode(int) at:&depthbits];
        NSLog(@"  colorbits: %d, depthbits: %d", colorbits, depthbits);
        //FIXME: Convert to new scheme:
        // colorbits, depthbits, pixel format attributes, hidden
        // (kintel 20040404)
        [self initWithFrame:[self frame]];
      }
    }
#endif
  }
  else if (self = [super initWithCoder:coder]) {
    [self commonInit];
  }
  return self;
}

@end

