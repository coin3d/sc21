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
 
#import <Sc21/SCView.h>
#import <Sc21/SCController.h>
#import <Sc21/SCExaminerController.h>
#import "SCUtil.h"
#import "SCOpenGLViewP.h"

@interface _SCViewP : NSObject
{
  NSOpenGLView * oldview; /* FIXME: We should remove this after a grace period (say Sc21 V1.0.1) */
  NSCursor * cursor;
}
@end

@implementation _SCViewP
@end

#define PRIVATE(p) ((p)->scviewpriv)
#define SELF PRIVATE(self)

@interface SCView(InternalAPI)
- (void)_SC_commonInit;
@end

@implementation SCView

/*"
  An SCView displays a Coin scene graph.
  
  This class is a subclass of SCOpenGLView, its main purpose being
  forwarding of draw and user events to its controller.

  All actual Coin scene management, rendering, event translation etc.
  is done by the SCController class.
  Connect SCView's !{controller} outlet to a valid SCController instance
  to use SCView.
  "*/

+ (void)initialize
{
  // The version is set to 1 to be able to distinguish between objects
  // created with the public beta (version=0) and newer objects.
  // FIXME: It is expected that we'll stop supporting the public beta
  // from Sc21 V1.0.1 and versioning is probably not needed later since
  // we only support keyed archiving.
  [SCView setVersion:1];
}

/*"
  Designated initializer.
  
  Initializes a newly allocated SCView with rect as its frame
  rectangle. Sets up an OpenGL context with the given pixel format.
  The format parameter is passed on to its superclass.
  "*/
- (id)initWithFrame:(NSRect)rect pixelFormat:(SCOpenGLPixelFormat *)format
{
  if (self = [super initWithFrame:rect pixelFormat:format]) {
    // flush buffer only during the vertical retrace of the monitor
    const long int vals[1] = {1};
    [[self openGLContext] setValues:vals forParameter:NSOpenGLCPSwapInterval];
  }
  return self;
}

/*"
  Initializer.

  Equivalent to calling [self initWithFrame:rect format:nil].
  "*/
- (id)initWithFrame:(NSRect)rect
{
  return [self initWithFrame:rect pixelFormat:nil];
}

- (void)dealloc
{
  SC21_DEBUG(@"SCView.dealloc");
  // Prevent controller from continuing to draw into our view.
  [self->controller setRedrawHandler:nil];
  [self->controller stopTimers];
  [self->controller release];
  [SELF release];
  [super dealloc];
}


/*" 
  Returns the currently used SCController.
  "*/
- (SCController *)controller
{
  return self->controller;  
}


/*" 
  Sets the controller to newcontroller. newcontroller is retained.
  "*/
- (void)setController:(SCController *)newcontroller
{
  [newcontroller retain];
  [self->controller release];
  self->controller = newcontroller;
  // Use [self display] as a redraw handler
  [self->controller setRedrawHandler:self];
  [self->controller setRedrawSelector:@selector(display)];
  [self reshape]; // Initialize viewport
}


/*"
  Renders the current scene graph into frame rectangle rect.

  Calls SCController's #render: method.
  "*/
- (void)drawRect:(NSRect)rect
{
  // SC21_DEBUG(@"SCView.drawRect");
  // Note: As NSView's implementation of this method, #drawRect: is
  // intended to be completely overridden by each subclass that
  // performs drawing, do _not_ invoke [super drawRect] here!
  [self->controller render];
  [[self openGLContext] flushBuffer];
}


/*" 
  Informs the SCView's %controller of the size change by
  calling its #viewSizeChanged: method, and updates the
  OpenGL context.
  "*/
- (void)reshape
{
  [self->controller viewSizeChanged:[self visibleRect]];
  if ([[self openGLContext] view] == self) [[self openGLContext] update];
}


// ----------- Mouse and keyboard event handling --------------------------

/*" 
  Forwards event to %controller by sending it the #handleEvent:inView:
  message. If the event is not handled by the controller, it will
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
  if (![self->controller handleEvent:event inView:self]) {
    [super mouseDown:event];
  }
}

/*" 
  Forwards event to %controller by sending it the #handleEvent:inView:
  message. If the event is not handled by the controller, it will
  be forwarded through the responder chain as usual. 
  "*/
- (void)mouseUp:(NSEvent *)event
{
  if (![self->controller handleEvent:event inView:self]) {
    [super mouseUp:event];
  }
}

/*" 
  Forwards event to %controller by sending it the #handleEvent:inView: 
  message. If the event is not handled by the controller, it will
  be forwarded through the responder chain as usual.
  
  Note that when processing "mouse dragged" events, Coin does not
  distinguish between left and right mouse button. If you interested
  in that information, you have to evaluate the last mouseDown that
  occured before the dragging.
  "*/
- (void)mouseDragged:(NSEvent *)event
{
  if (![self->controller handleEvent:event inView:self]) {
    [super mouseDragged:event];
  }
}

/*"
  Forwards event to %controller by sending it the #handleEvent:inView: 
  message. If the event is not handled by the controller, it will
  be forwarded through the responder chain as usual.
  
  FIXME: Unhandled right-clicks will usually result in NSView displaying
  a context menu. In this case, the corresponding rightMouseUp: will
  never reach us but be sent to the context menu. This will confuse
  any state machines implemented in the controller (kintel 20040502).
  "*/
- (void)rightMouseDown:(NSEvent *)event
{
  if (![self->controller handleEvent:event inView:self]) {
    [super rightMouseDown:event];
  }
}


/*" 
  Forwards event to %controller by sending it the #handleEvent:inView: 
  message. If the event is not handled by the controller, it will
  be forwarded through the responder chain as usual.
  "*/
- (void)rightMouseUp:(NSEvent *)event
{
  if (![self->controller handleEvent:event inView:self]) {
    [super rightMouseUp:event];
  }
}

/*"
  Forwards event to %controller by sending it the #handleEvent:inView: 
  message. If the event is not handled by the controller, it will
  be forwarded through the responder chain as usual.
  
  Note that when processing "mouse dragged" events, Coin does not
  distinguish between left and right mouse button. If you interested
  in that information, you have to evaluate the last mouseDown that
  occured before the dragging.
  "*/
- (void)rightMouseDragged:(NSEvent *)event
{
  if (![self->controller handleEvent:event inView:self]) {
    [super rightMouseDragged:event];
  }
}

/*" 
  Forwards event to %controller by sending it the #handleEvent:inView: 
  message.  If the event is not handled by the controller, it will
  be forwarded through the responder chain as usual 
  "*/
- (void)otherMouseDown:(NSEvent *)event
{
  if (![self->controller handleEvent:event inView:self]) {
    [super otherMouseDown:event];
  }
}

/*" 
  Forwards event to %controller by sending it the #handleEvent:inView: 
  message.  If the event is not handled by the controller, it will
  be forwarded through the responder chain as usual. 
  "*/
- (void)otherMouseUp:(NSEvent *)event
{
  if (![self->controller handleEvent:event inView:self]) {
    [super otherMouseUp:event];
  }
}

/*" 
  Forwards event to %controller by sending it the #handleEvent:inView: 
  message. If the event is not handled by the controller, it will
  be forwarded through the responder chain as usual.
  
  Note that when processing "mouse dragged" events, Coin does not
  distinguish between left and right mouse button. If you interested
  in that information, you have to evaluate the last mouseDown that
  occured before the dragging.
  "*/
- (void)otherMouseDragged:(NSEvent *)event
{
  if (![self->controller handleEvent:event inView:self]) {
    [super otherMouseDragged:event];
  }
}

/*" 
  Forwards event to %controller by sending it the #handleEvent:inView: 
  message.  If the event is not handled by the controller, it will
  be forwarded through the responder chain as usual.
  "*/
- (void)scrollWheel:(NSEvent *)event
{
  if (![self->controller handleEvent:event inView:self]) {
    [super scrollWheel:event];
  }
}

/*" 
  Forwards event to %controller by sending it the #handleEvent:InView:
  message.  If the event is not handled by the controller, it will
  be forwarded through the responder chain as usual.
  "*/
- (void)keyDown:(NSEvent *)event 
{
  if (![self->controller handleEvent:event inView:self]) {
    [super keyDown:event];
  } 
}


/*" 
  Forwards event to %controller by sending it the #handleEvent:inView:
  message.  If the event is not handled by the controller, it will
  be forwarded through the responder chain as usual.
  "*/
- (void)keyUp:(NSEvent *)event 
{
  if (![self->controller handleEvent:event inView:self]) {
    [super keyUp:event];
  } 
}

// --------------------------------------------------------------------

// FIXME: Only used by the event handling scheme. Reconsider this as part
// of redesigning event handling (kintel 20040615).
- (void)resetCursorRects
{
  SC21_DEBUG(@"SCView.resetCursorRects");
  [self addCursorRect:[self visibleRect] cursor:SELF->cursor];
}

/*"
  Associates the given cursor with this view and makes the cursor active.

  FIXME: Only used by the event handling scheme. Reconsider this as part
  of redesigning event handling (kintel 20040615).
  "*/
- (void)setCursor:(NSCursor *)cursor
{
  SELF->cursor = cursor;
  [SELF->cursor set];
}

-(BOOL)acceptsFirstResponder
{
  return YES;
}


// ---------------- NSCoding conformance -------------------------------

- (void)encodeWithCoder:(NSCoder *)coder
{
  SC21_DEBUG(@"SCView.encodeWithCoder:");
  [super encodeWithCoder:coder];
}

/*!
  This method is here only to support reading nib files created with
  Sc21 public beta.

  Here we decode the old instance variables, colorbits and depthbits,
  and copy all relevant settings from the old view.

  FIXME: We somehow still lose outlet connections and size settings when
  reading old nib files...

  FIXME: We should remove this after a grace period (say Sc21 V1.0.1)
  (kintel 20040404)
*/
- (id)awakeAfterUsingCoder:(NSCoder *)coder
{
  SC21_DEBUG(@"SCView.awakeAfterUsingCoder:");
  if (SELF->oldview) {
    SC21_DEBUG(@"  upgrading old instance.");
    int colorbits, depthbits;
    [coder decodeValueOfObjCType:@encode(int) at:&colorbits];
    [coder decodeValueOfObjCType:@encode(int) at:&depthbits];
    SC21_DEBUG(@"  colorbits: %d, depthbits: %d", colorbits, depthbits);
    //FIXME: Copy these as well:
    // colorbits, depthbits, pixel format attributes
    // (kintel 20040404)
    if (self = [self initWithFrame:[SELF->oldview frame]]) {
      NSView * superview = [SELF->oldview superview];
      [superview replaceSubview:SELF->oldview with:self];
      [self setMenu:[SELF->oldview menu]];
      [self setInterfaceStyle:[SELF->oldview interfaceStyle]];
      [self setHidden:[SELF->oldview isHidden]];
      [self setNextKeyView:[SELF->oldview nextKeyView]];
      [self setBounds:[SELF->oldview bounds]];
      if ([SELF->oldview isRotatedFromBase]) {
        [self setFrameRotation:[SELF->oldview frameRotation]];
        [self setBoundsRotation:[SELF->oldview boundsRotation]];
      }
      [self setPostsFrameChangedNotifications:[SELF->oldview postsFrameChangedNotifications]];
      [self setPostsBoundsChangedNotifications:[SELF->oldview postsBoundsChangedNotifications]];
      [self setAutoresizingMask:[SELF->oldview autoresizingMask]];
      [self setToolTip:[SELF->oldview toolTip]];
      [SELF->oldview release];
      SELF->oldview = nil;
    }
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
  SC21_DEBUG(@"SCView.initWithCoder:");
  // This is support for reading archives from Sc21 public beta
  // FIXME: We should remove this after a grace period (say Sc21 V1.0.1)
  // (kintel 20040404)
  if ([coder versionForClassName:@"SCView"] == 0) {
    [self _SC_commonInit];
    SELF->oldview = [[NSOpenGLView alloc] initWithCoder:coder];
    return self;
  } else {
    self = [super initWithCoder:coder]; // Will call _SC_commonInit
  }  
  return self;
}

@end

@implementation SCView(InternalAPI)

/*" 
  Shared initialization code that is called both from 
  #initWithFrame:pixelFormat and #initWithCoder:.
  
  NB! If you override this method, you must:
  o call [super _SC_commonInit] as the first call in your
    implementation to make sure everything is set up properly.
  o _not_ call this method from init or initWithCoder in the subclass
  "*/
- (void)_SC_commonInit
{
  [super _SC_commonInit];
  SELF = [[_SCViewP alloc] init];
}

@end
