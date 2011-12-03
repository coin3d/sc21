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
 
#import <Sc21/SCView.h>
#import <Sc21/SCController.h>

#import "SCViewP.h"
#import "SCUtil.h"
#import "SCOpenGLViewP.h"

#import <Inventor/actions/SoGLRenderAction.h>
#import <Inventor/misc/SoContextHandler.h>

/* 
  Private method used by Apple to determine whether we are running
  within IB. This allows us to draw a different representation of the
  widget in "design GUI" mode. Declared here to kill compiler warning.
*/
@interface NSObject (PrivateAPI)
+(BOOL)isInInterfaceBuilder;
@end

@implementation SCViewP
@end


#define PRIVATE(p) ((p)->_sc_view)
#define SELF PRIVATE(self)


@implementation SCView

/*"
  #{SCView and SCDrawable} 

  SCView conforms to the SCDrawable protocol, which means it can be
  used by an SCController to display a Coin scenegraph. 

  Note that when connecting SCView's !{controller} outlet, the
  controller's drawable will automatically be set to the SCView.

  #{Event handling}

  Instead of handling events directly, SCView forwards them to its
  SCController's !{handleEvent:} method. Refer to the SCEventHandler
  documentation for more information.

"*/


#pragma mark --- initialization ---

/*"
  Designated initializer.
  
  Initializes a newly allocated SCView with rect as its frame
  rectangle and sets up an OpenGL context with the pixelformat
  format. Returns !{self}.
"*/

- (id)initWithFrame:(NSRect)rect pixelFormat:(SCOpenGLPixelFormat *)format
{
  if (self = [super initWithFrame:rect pixelFormat:format]) {
    // flush buffer only during the vertical retrace of the monitor
    const GLint vals[1] = {1};
    [[self openGLContext] setValues:vals forParameter:NSOpenGLCPSwapInterval];
  }
  return self;
}


/*"
  Equivalent to calling !{[self initWithFrame:rect format:nil]}.
"*/

- (id)initWithFrame:(NSRect)rect
{
  return [self initWithFrame:rect pixelFormat:nil];
}


- (void)dealloc
{
  SC21_DEBUG(@"SCView.dealloc");
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self setController:nil];
  [SELF release];
  [super dealloc];
}


#pragma mark --- accessor methods ---

/*" 
  Returns the receiver's SCController.
"*/
- (SCController *)controller
{
  return self->controller;  
}


/*" 
  Sets the receiver's SCController to newcontroller. newcontroller is retained.
"*/

- (void)setController:(SCController *)newcontroller
{
  if (newcontroller == self->controller) { return; }

  if (self->controller) {
    // Remove ourselves as observer for the existing controller
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                          name:SCCursorChangedNotification 
                                          object:self->controller];
    [self->controller setDrawable:nil];
    [self->controller release];
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
  // Draw Interface Builder representation: black filled rectangle
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
  Forwards event to the controller. If the event is not handled by the
  controller, it will be sent on through the responder chain as usual.

  Note: You have to send !{setAcceptsMouseMovedEvents:YES} to the
  receiver's parent NSWindow to enable NSMouseMoved events.
"*/

- (void)mouseMoved:(NSEvent *)event
{
  if (![self->controller handleEvent:event]) {
    [super mouseMoved:event];
  }
}


/*" 
  Forwards event to the controller. If the event is not handled by the
  controller, it will be sent on through the responder chain as usual.

  Note that if you press the left mouse button while holding
  down the ctrl key, you will not receive a mouseDown event.
  Instead, the view's default context menu will be shown. (This
  behavior is inherited from NSView.) If you want to handle
  ctrl-click yourself, you have to subclass SCView and override
  !{- (NSMenu *)menuForEvent:(NSEvent *)event} to return nil.
  This will cause the event to be passed on to this function.
"*/

- (void)mouseDown:(NSEvent *)event
{
  if (![self->controller handleEvent:event]) {
    [super mouseDown:event];
  }
}


/*" 
  Forwards event to the controller. If the event is not handled by the
  controller, it will be sent on through the responder chain as usual.
"*/

- (void)mouseUp:(NSEvent *)event
{
  if (![self->controller handleEvent:event]) {
    [super mouseUp:event];
  }
}


/*" 
  Forwards event to the controller. If the event is not handled by the
  controller, it will be sent on through the responder chain as usual.

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
  Forwards event to the controller. If the event is not handled by the
  controller, it will be sent on through the responder chain as usual.
"*/

// FIXME: Unhandled right-clicks will usually result in NSView displaying
// a context menu. In this case, the corresponding rightMouseUp: will
// never reach us but be sent to the context menu. This will confuse
// any state machines implemented in the controller (kintel 20040502).

- (void)rightMouseDown:(NSEvent *)event
{
  if (![self->controller handleEvent:event]) {
    [super rightMouseDown:event];
  }
}


/*" 
  Forwards event to the controller. If the event is not handled by the
  controller, it will be sent on through the responder chain as usual.
"*/

- (void)rightMouseUp:(NSEvent *)event
{
  if (![self->controller handleEvent:event]) {
    [super rightMouseUp:event];
  }
}


/*"
  Forwards event to the controller. If the event is not handled by the
  controller, it will be sent on through the responder chain as usual.

  Note that when processing "mouse dragged" events, Coin does not
  distinguish between left and right mouse button. If you are interested
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
  Forwards event to the controller. If the event is not handled by the
  controller, it will be sent on through the responder chain as usual.
"*/

- (void)otherMouseDown:(NSEvent *)event
{
  if (![self->controller handleEvent:event]) {
    [super otherMouseDown:event];
  }
}


/*" 
  Forwards event to the controller. If the event is not handled by the
  controller, it will be sent on through the responder chain as usual.
"*/

- (void)otherMouseUp:(NSEvent *)event
{
  if (![self->controller handleEvent:event]) {
    [super otherMouseUp:event];
  }
}


/*" 
  Forwards event to the controller. If the event is not handled by the
  controller, it will be sent on through the responder chain as usual.

  Note that when processing "mouse dragged" events, Coin does not
  distinguish between left and right mouse button. If you are interested
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
  Forwards event to the controller. If the event is not handled by the
  controller, it will be sent on through the responder chain as usual.
"*/

- (void)scrollWheel:(NSEvent *)event
{
  if (![self->controller handleEvent:event]) {
    [super scrollWheel:event];
  }
}


/*" 
  Forwards event to the controller. If the event is not handled by the
  controller, it will be sent on through the responder chain as usual.
"*/

- (void)keyDown:(NSEvent *)event 
{
  if ([event isARepeat]) return;
  if (![self->controller handleEvent:event]) {
    [super keyDown:event];
  } 
}


/*" 
  Forwards event to the controller. If the event is not handled by the
  controller, it will be sent on through the responder chain as usual.
"*/

- (void)keyUp:(NSEvent *)event 
{
  if (![self->controller handleEvent:event]) {
    [super keyUp:event];
  } 
}


/*" 
  Forwards event to the controller. If the event is not handled by the
  controller, it will be sent on through the responder chain as usual.
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

/* 
  Shared initialization code that is called both from 
  #initWithFrame:pixelFormat and #initWithCoder:.
  
  NB! If you override this method, you must:
  o call [super _SC_commonInit] as the first call in your
    implementation to make sure everything is set up properly.
  o _not_ call this method from init or initWithCoder in the subclass
*/
- (void)_SC_commonInit
{
  [super _SC_commonInit];
  SELF = [[SCViewP alloc] init];
}


/*
  Used to cache the current cursor so we can use it from -resetCursorRects
*/

- (void)_SC_cursorChanged:(NSNotification *)notification;
{
  SC21_LOG_METHOD;
  SELF->cursor = [NSCursor currentCursor];
}

@end
