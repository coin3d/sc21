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
 

#import "SCView.h"
#import "SCController.h"
#import "SCExaminerController.h"

// ---------------------- Notifications ----------------------------

NSString * SCCouldNotCreateValidPixelFormatNotification =
  @"SCCouldNotCreateValidPixelFormatNotification";


@interface SCView (InternalAPI)
- (void) _initMenu;
- (NSSize) _size;
- (float) _width;
- (float) _height;
@end

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

    This method is the designated initializer for the SCView
    class. Returns !{self}.
 "*/

- (id) initWithFrame:(NSRect)rect
{
  NSOpenGLPixelFormat * pixelFormat;
  _colorbits = 32;
  _depthbits = 32;
  if ((pixelFormat = [self createPixelFormat:rect]) != nil) {
    if (self = [super initWithFrame:rect pixelFormat:pixelFormat]) {
      // flush buffer only during the vertical retrace of the monitor
      const long int vals[1] = {1};
      [[self openGLContext] setValues:vals forParameter:NSOpenGLCPSwapInterval];
      [[self openGLContext] makeCurrentContext];
      [self commonInit];
    }
    [pixelFormat release];
  } else {
    [[NSNotificationCenter defaultCenter]
      postNotificationName:SCCouldNotCreateValidPixelFormatNotification object:self];
    [self dealloc];
    self = nil;
  }
  return self;
}


/*" Initializes a newly allocated SCView instance from the data
    in decoder. Returns !{self}.

    Calls #commonInit, which contains common initialization
    code needed both in #init and #initWithCoder.
 "*/

- (id) initWithCoder:(NSCoder *)coder
{
  if (self = [super initWithCoder:coder]) {
    [coder decodeValueOfObjCType:@encode(int) at:&_colorbits];
    [coder decodeValueOfObjCType:@encode(int) at:&_depthbits];
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
  [self _initMenu];
}


/*" Recreates the OpenGL context if the settings have been changed
    from within Interface builder. Called after the object has been 
    loaded from an Interface Builder archive or nib file. 
 "*/

- (void) awakeFromNib
{
  [self recreateOpenGLContext];
}


/*" Encodes the SCView using encoder coder "*/

- (void) encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
  [coder encodeValueOfObjCType:@encode(int) at:&_colorbits];
  [coder encodeValueOfObjCType:@encode(int) at:&_depthbits];
}


- (void) dealloc
{
  // Prevent controller from continuing to draw into our view.
  [controller stopTimers];
  [controller release];
  [super dealloc];  
}


// ---------------------- Accessing SCController --------------------

/*" Returns the currently used SCController. "*/
- (SCController *) controller
{
  return controller;  
}


/*" Set the controller to newcontroller. newcontroller is
    retained.
 "*/

- (void) setController:(SCController *) newcontroller
{
  [newcontroller retain];
  [controller release];
  controller = newcontroller;
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

- (BOOL) recreateOpenGLContext
{
  // FIXME: Shouldn't we inform Coin about the context change?
  // Test with textures and display lists! kyrah 20030616
    
  BOOL success = FALSE;
  NSOpenGLPixelFormat * pixelFormat;
  NSOpenGLContext * newContext;
  success = NO;

  [[self openGLContext] clearDrawable];
  
  pixelFormat = [self createPixelFormat:[self frame]];
  if (pixelFormat != nil) {
    newContext = [[NSOpenGLContext alloc] initWithFormat:pixelFormat
                                            shareContext:nil ];
    if (newContext != nil) {
      const long int vals[1] = {1};
      [super setFrame:[self frame]];
      [super setOpenGLContext:newContext];
      // flush buffer only during the vertical retrace of the monitor
      [newContext setValues:vals forParameter:NSOpenGLCPSwapInterval];
      [newContext makeCurrentContext];
      success = TRUE;
    }
    [pixelFormat release];
  }
  [self setNeedsDisplay:YES];
  return success;
}


/*" Sets the current color depth and re-initializes the SCView's
    OpenGL context by calling #recreateOpenGLContext:
    
    To change this setting without immediately recreating the 
    context, call #{setColorBitsNoRecreate:} instead. This is
    advisable if you want to do several changes at the same time,
    to avoid multiple re-initalisation.
    
    Example:
    
    !{// Not good.
    [self setColorBits:32;  // recreate context with new color and old depth
    [self setDepthBits:16;  // recreate context with new color and new depth}
    
    !{// Good.
    [self setColorBitsNoRecreate:32;  // do not recreate OpenGL context
    [self setDepthBits:16;            // recreate context with new color and new depth}
 "*/

- (void) setColorBits:(int)n
{
  [self setColorBitsNoRecreate:n];
  [self recreateOpenGLContext];
}


/*" Sets the current color depth, but does not re-initialize the SCView's
    OpenGL context. To change this setting and immediately recreate the 
    context, call #{setColorBits:} instead.
 "*/
    
- (void) setColorBitsNoRecreate:(int)n
{
  _colorbits = n;
}

/*" Returns the current color depth. 

    Note that this returns the value as set by the last 
    #setColorBits: or #setColorBitsNoRecreate: call. In the latter case,
    the actual color depth of the OpenGL context might be different
    from the returned value.
"*/

- (int) colorBits
{
  return _colorbits;
}

/*" Sets the current depth buffer resolution and re-initializes the 
    SCView's OpenGL context by calling #recreateOpenGLContext:
    
    To change this setting without immediately recreating the 
    context, call #{setDepthBitsNoRecreate:} instead. See the 
    documentation of #setColorBits: for usage information.
 "*/

- (void) setDepthBits:(int)n
{
  [self setDepthBitsNoRecreate:n];
  [self recreateOpenGLContext];
}

/*" Sets the current depth buffer resolution, but does not re-initialize 
    the SCView's OpenGL context. To change this setting and 
    immediately recreate the context, call #{setDepthBits:} instead.
 "*/
 
- (void) setDepthBitsNoRecreate:(int)n
{
  _depthbits = n;
}

/*" Returns the depth buffer resolution. 

    Note that this returns the value as set by the last 
    #setDepthBits: or #setDepthBitsNoRecreate: call. In the latter case,
    the actual depth buffer resolution of the OpenGL context might
    be different from the returned value.
"*/

- (int) depthBits
{
  return _depthbits;
}


/*" Returns a double buffered, accelerated pixel format. The 
    colordepth and depth are the current values as set by
    #setColorBits: and #setDepthBits: (or #setColorBitsNoRecreate: 
    and #setDepthBitsNoRecreate:) respectively. Override this
    method if you need specific settings.
 "*/
 
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame
{
  NSOpenGLPixelFormatAttribute att[16];
  NSOpenGLPixelFormat *pixelFormat;
  int i = 0;
  att[i++] = NSOpenGLPFADoubleBuffer;
  att[i++] = NSOpenGLPFAAccelerated;
  att[i++] = NSOpenGLPFAAccumSize;
  att[i++] = (NSOpenGLPixelFormatAttribute)32;
  att[i++] = NSOpenGLPFAColorSize;
  att[i++] = (NSOpenGLPixelFormatAttribute)_colorbits;
  att[i++] = NSOpenGLPFADepthSize;
  att[i++] = (NSOpenGLPixelFormatAttribute)_depthbits;
  att[i++] = NSOpenGLPFAScreenMask;
  att[i++] = (NSOpenGLPixelFormatAttribute)
    CGDisplayIDToOpenGLDisplayMask(kCGDirectMainDisplay);
  att[i] = (NSOpenGLPixelFormatAttribute)0;
  pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:att];
  return pixelFormat;
}


// ------------------ viewing and drawing --------------------------------

/*" Renders the current scene graph into frame rectangle rect by
    setting the OpenGL state (enable lighting and z buffering)
    and then calling SCController's #render: method.

"*/

- (void) drawRect:(NSRect)rect
{
  // Note: As NSView's implementation of this method, #drawRect: is
  // intended to be completely overridden by each subclass that
  // performs drawing, do _not_ invoke [super drawRect] here!
  
  [[self openGLContext] makeCurrentContext];
  glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT ); // FIXME: needed?
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

- (void) reshape
{
  [controller viewSizeChanged:[self visibleRect]];
  [[self openGLContext] update];
}


/*" Returns the point p normalized so that its values lie in
    [0;1] relative to the size of the SCView. (Example: 
    The point (100, 50) in a view of size (200,200) would 
    be (0.5, 0,25) in normalized coordinates.)
  "*/
  
- (NSPoint) normalizePoint:(NSPoint)point
{
  NSPoint normalized;
  NSSize size = [self _size];
  normalized.x = point.x / size.width;
  normalized.y = point.y / size.height;
  return normalized;
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
    #{- (NSMenu *)menuForEvent:(NSEvent *)event} to return nil and
    pass on the event to the controller:
    %{[controller handleEvent:event]}.
 "*/

- (void) mouseDown:(NSEvent *)event
{
  if (![controller handleEvent:event]) {
    [[self nextResponder] mouseDown:event];
  }
}


/*" Forwards event to %controller by sending it the #handleEvent:
    message.  If the event is not handled by the controller, it will
    be forwarded through the responder chain as usual. 
 "*/

- (void) mouseUp:(NSEvent *)event
{
  if (![controller handleEvent:event]) {
    [[self nextResponder] mouseUp:event];
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

- (void) mouseDragged:(NSEvent *)event
{
  if (![controller handleEvent:event]) {
    [[self nextResponder] mouseDragged:event];
  }
}


/*" Forwards event to %controller by sending it the #handleEvent: 
    message. If the event is not handled by the controller, it will
    be forwarded through the responder chain as usual.
 "*/

- (void) rightMouseDown:(NSEvent *)event
{
  if (![controller handleEvent:event]) {
    [[self nextResponder] rightMouseDown:event];
  }
}


/*" Forwards event to %controller by sending it the #handleEvent: 
    message. If the event is not handled by the controller, it will
    be forwarded through the responder chain as usual.
 "*/

- (void) rightMouseUp:(NSEvent *)event
{
  if (![controller handleEvent:event]) {
    [[self nextResponder] rightMouseUp:event];
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

- (void) rightMouseDragged:(NSEvent *)event
{
  if (![controller handleEvent:event]) {
    [[self nextResponder] rightMouseDragged:event];
  }
}


/*" Forwards event to %controller by sending it the #handleEvent: 
    message.  If the event is not handled by the controller, it will
    be forwarded through the responder chain as usual 
 "*/

- (void) otherMouseDown:(NSEvent *)event
{
  if (![controller handleEvent:event]) {
    [[self nextResponder] otherMouseDown:event];
  }
}


/*" Forwards event to %controller by sending it the #handleEvent: 
    message.  If the event is not handled by the controller, it will
    be forwarded through the responder chain as usual. 
 "*/

- (void) otherMouseUp:(NSEvent *)event
{
  if (![controller handleEvent:event]) {
    [[self nextResponder] otherMouseUp:event];
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

- (void) otherMouseDragged:(NSEvent *)event
{
  if (![controller handleEvent:event]) {
    [[self nextResponder] otherMouseDragged:event];
  }
}

/*" Forwards event to %controller by sending it the #handleEvent: 
    message.  If the event is not handled by the controller, it will
    be forwarded through the responder chain as usual.
 "*/

- (void) scrollWheel:(NSEvent *)event
{
  if (![controller handleEvent:event]) {
    [[self nextResponder] scrollWheel:event];
  }
}


/*" Forwards event to %controller by sending it the #handleEvent:
    message.  If the event is not handled by the controller, it will
    be forwarded through the responder chain as usual.
 "*/

- (void) keyDown:(NSEvent *)event {
  if (![controller handleEvent:event]) {
    [[self nextResponder] keyDown:event];
  } 
}


/*" Returns !{YES} to confirm becoming first responder.
    Needed to receive keyboard events
 "*/

// FIXME: The doc says this is the default.  Check if this
// is true, and remove method if not needed. kyrah 20030714

- (BOOL)becomeFirstResponder
{
  return YES;
}


/*" Returns !{YES} to accept becoming first responder.
    Needed to receive keyboard events
 "*/

- (BOOL)acceptsFirstResponder
{
  return YES;
}

// --------------- Convenience methods --------------------

/*" Returns the aspect ratio of the SCView. "*/

- (float) aspectRatio
{
  NSSize s = [self _size];
  return s.width/s.height;
}


// ----------------------- InternalAPI -------------------------

/* Initalizes and sets the contextual menu. */
- (void) _initMenu
{
  NSMenu * menu;
  menu = [[NSMenu alloc] initWithTitle:@"Menu"];
  [self setMenu:menu];  // retained by the view
  [menu release];
}

/* Returns the size of the SCView. */

- (NSSize) _size
{
  NSSize s = [self bounds].size;
  return s;
}

/*" Returns the width of the SCView. "*/

- (float) _width
{
  return [self bounds].size.width;
}

/*" Returns the height of the SCView. "*/

- (float) _height
{
  return [self bounds].size.height;
}



@end
