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
#import "SCUtil.h"
#import "SCOpenGLViewP.h"
#import <Inventor/actions/SoGLRenderAction.h>
#import <Inventor/misc/SoContextHandler.h>
#import <Inventor/SoSceneManager.h>

@interface SCViewP : NSObject
{
  NSCursor * cursor;
}
@end

@implementation SCViewP
@end

#define PRIVATE(p) ((p)->_sc_view)
#define SELF PRIVATE(self)

@interface SCView(InternalAPI)
- (void)_SC_commonInit;
- (void)_SC_cursorChanged:(NSNotification *)notification;
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

#pragma mark --- static methods ----

+ (void)initialize
{
  // The version is set to 1 to be able to distinguish between objects
  // created with the public beta (version=0) and newer objects.
  // FIXME: It is expected that we'll stop supporting the public beta
  // from Sc21 V1.0.1 and versioning is probably not needed later since
  // we only support keyed archiving.
  [SCView setVersion:1];
}

#pragma mark --- initialization ---

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
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self->controller setDrawable:nil];
  // FIXME: Do we have to manually stop the timers? kyrah 20040809
  // [self->controller _SC_stopTimerss];
  [self setController:nil];
  [SELF release];
  [super dealloc];
}


#pragma mark --- accessor methods ---

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
  if (newcontroller == self->controller) { return; }

  if (self->controller) {
    // Remove ourselves as observer for the existing controller
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                          name:SCCursorChangedNotification 
                                          object:self->controller];
    [self->controller release];
    //FIXME: Remove old drawable? (kintel 20040804)
  }

  self->controller = [newcontroller retain];

  [self->controller setDrawable:self];
  [self reshape]; // Initialize viewport
  [[NSNotificationCenter defaultCenter] 
    addObserver:self selector:@selector(_SC_cursorChanged:) 
    name:SCCursorChangedNotification object:self->controller];
}

#pragma mark --- drawing and resizing ---

/*"
  Renders the current scene graph into frame rectangle rect.

  Calls SCController's #render: method.
  "*/
- (void)drawRect:(NSRect)rect
{
//    SC21_DEBUG(@"SCView.drawRect");
  // draw Interface Builder representation: black filled rectangle
  // FIXME: make sure this actually works on Jaguar too. kyrah 20040705
   if ([[self class] respondsToSelector:@selector(isInInterfaceBuilder)] &&
       [[self class] isInInterfaceBuilder]) {    
    [[NSColor blackColor] set];
    NSRectFill(rect);
    return;
  } 

  // Note: As NSView's implementation of this method, #drawRect: is
  // intended to be completely overridden by each subclass that
  // performs drawing, do _not_ invoke [super drawRect] here!
  [self->controller render];
  [[self openGLContext] flushBuffer];
}


/*" 

  "*/
- (void)reshape
{
  if ([[self openGLContext] view] == self) [[self openGLContext] update];
}

- (void)clearGLContext
{
  [super clearGLContext];
  SoSceneManager * scenemgr = [self->controller sceneManager];
  if (scenemgr) {
    SoGLRenderAction * glra = scenemgr->getGLRenderAction();
    if (glra) {
      SoContextHandler::destructingContext(glra->getCacheContext());
    }
  }
}

#pragma mark --- event handling ---


/*" 
  Forwards event to %controller by sending it the #handleEvent:
  message. If the event is not handled by the controller, it will
  be forwarded through the responder chain as usual.

  Note: NSWindow.setAcceptsMouseMovedEvents: must be called to enable
  NSMouseMoved events.
"*/

- (void)mouseMoved:(NSEvent *)event
{
  if (![self->controller handleEvent:event]) {
    [super mouseMoved:event];
  }
}

/*" 
  Forwards event to %controller by sending it the #handleEvent:
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
  if (![self->controller handleEvent:event]) {
    [super mouseDown:event];
  }
}

/*" 
  Forwards event to %controller by sending it the #handleEvent:
  message. If the event is not handled by the controller, it will
  be forwarded through the responder chain as usual. 
  "*/
- (void)mouseUp:(NSEvent *)event
{
  if (![self->controller handleEvent:event]) {
    [super mouseUp:event];
  }
}

/*" 
  Forwards event to %controller by sending it the #handleEvent: 
  message. If the event is not handled by the controller, it will
  be forwarded through the responder chain as usual.
  
  Note that when processing "mouse dragged" events, Coin does not
  distinguish between left and right mouse button. If you interested
  in that information, you have to evaluate the last mouseDown that
  occured before the dragging.
  "*/
- (void)mouseDragged:(NSEvent *)event
{
  if (![self->controller handleEvent:event]) {
    [super mouseDragged:event];
  }
}

/*"
  Forwards event to %controller by sending it the #handleEvent: 
  message. If the event is not handled by the controller, it will
  be forwarded through the responder chain as usual.
  
  FIXME: Unhandled right-clicks will usually result in NSView displaying
  a context menu. In this case, the corresponding rightMouseUp: will
  never reach us but be sent to the context menu. This will confuse
  any state machines implemented in the controller (kintel 20040502).
  "*/
- (void)rightMouseDown:(NSEvent *)event
{
  if (![self->controller handleEvent:event]) {
    [super rightMouseDown:event];
  }
}


/*" 
  Forwards event to %controller by sending it the #handleEvent: 
  message. If the event is not handled by the controller, it will
  be forwarded through the responder chain as usual.
  "*/
- (void)rightMouseUp:(NSEvent *)event
{
  if (![self->controller handleEvent:event]) {
    [super rightMouseUp:event];
  }
}

/*"
  Forwards event to %controller by sending it the #handleEvent: 
  message. If the event is not handled by the controller, it will
  be forwarded through the responder chain as usual.
  
  Note that when processing "mouse dragged" events, Coin does not
  distinguish between left and right mouse button. If you interested
  in that information, you have to evaluate the last mouseDown that
  occured before the dragging.
  "*/
- (void)rightMouseDragged:(NSEvent *)event
{
  if (![self->controller handleEvent:event]) {
    [super rightMouseDragged:event];
  }
}

/*" 
  Forwards event to %controller by sending it the #handleEvent: 
  message. If the event is not handled by the controller, it will
  be forwarded through the responder chain as usual 
  "*/
- (void)otherMouseDown:(NSEvent *)event
{
  if (![self->controller handleEvent:event]) {
    [super otherMouseDown:event];
  }
}

/*" 
  Forwards event to %controller by sending it the #handleEvent: 
  message. If the event is not handled by the controller, it will
  be forwarded through the responder chain as usual. 
  "*/
- (void)otherMouseUp:(NSEvent *)event
{
  if (![self->controller handleEvent:event]) {
    [super otherMouseUp:event];
  }
}

/*" 
  Forwards event to %controller by sending it the #handleEvent: 
  message. If the event is not handled by the controller, it will
  be forwarded through the responder chain as usual.
  
  Note that when processing "mouse dragged" events, Coin does not
  distinguish between left and right mouse button. If you interested
  in that information, you have to evaluate the last mouseDown that
  occured before the dragging.
  "*/
- (void)otherMouseDragged:(NSEvent *)event
{
  if (![self->controller handleEvent:event]) {
    [super otherMouseDragged:event];
  }
}

/*" 
  Forwards event to %controller by sending it the #handleEvent: 
  message. If the event is not handled by the controller, it will
  be forwarded through the responder chain as usual.
  "*/
- (void)scrollWheel:(NSEvent *)event
{
  if (![self->controller handleEvent:event]) {
    [super scrollWheel:event];
  }
}

/*" 
  Forwards event to %controller by sending it the #handleEvent:InView:
  message. If the event is not handled by the controller, it will
  be forwarded through the responder chain as usual.
  "*/
- (void)keyDown:(NSEvent *)event 
{
  if ([event isARepeat]) return;
  if (![self->controller handleEvent:event]) {
    [super keyDown:event];
  } 
}


/*" 
  Forwards event to %controller by sending it the #handleEvent:
  message. If the event is not handled by the controller, it will
  be forwarded through the responder chain as usual.
  "*/
- (void)keyUp:(NSEvent *)event 
{
  if (![self->controller handleEvent:event]) {
    [super keyUp:event];
  } 
}

/*" Forwards event to %controller by sending it the #handleEvent:
    message. If the event is not handled by the controller, it will
    be forwarded through the responder chain as usual.
 "*/

- (void)flagsChanged:(NSEvent *)event 
{
  if (![self->controller handleEvent:event]) {
    [super flagsChanged:event];
  } 
}


-(BOOL)acceptsFirstResponder
{
  return YES;
}

#pragma mark --- cursor handling ---

// FIXME: Only used by the event handling scheme. Reconsider this as part
// of redesigning event handling (kintel 20040615).
- (void)resetCursorRects
{
  SC21_DEBUG(@"SCView.resetCursorRects");
  [self addCursorRect:[self visibleRect] cursor:SELF->cursor];
}


#pragma mark --- SCDrawable conformance ---

// Dummy implementations needed to get rid of compiler warning 
// about not fully implementing the protocol.

- (void)display
{
  [super display];
}

- (NSRect)frame
{
  return [super frame];
}

#pragma mark --- NSCoding conformance ---

- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
}

- (id)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder]; // Will call _SC_commonInit
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
  SELF = [[SCViewP alloc] init];
}

/*"
  Used to cache the current cursor so we can use it from -resetCursorRects
  "*/
- (void)_SC_cursorChanged:(NSNotification *)notification;
{
  SC21_LOG_METHOD;
  SELF->cursor = [NSCursor currentCursor];
}

@end
