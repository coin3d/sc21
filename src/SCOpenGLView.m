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

#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <Sc21/SCOpenGLView.h>
#import <Sc21/SCOpenGLPixelFormat.h>
#import "SCUtil.h"

#import "SCOpenGLViewP.h"

@implementation SCOpenGLViewP
@end

#define PRIVATE(p) ((p)->_sc_openglview)
#define SELF PRIVATE(self)

@implementation SCOpenGLView

/*" 
  SCOpenGLView is a replacement for NSOpenGLView.
  
  The main purpose of this class is to be able to use an
  SCOpenGLPixelFormat in order to be able to archive/unarchive this
  class. In all other respects, SCOpenGLView behaves like
  NSOpenGLView.
 "*/

#pragma mark --- static methods ---

/*"
Returns a default SCOpenGLPixelFormat.
 "*/
+ (SCOpenGLPixelFormat *)defaultPixelFormat
{
  SC21_DEBUG(@"SCOpenGLView.defaultPixelFormat");
  
  // FIXME: Loop through an internal prioritized list of pixel format
  // requirements and select the first valid pixelformat found?
  // (kintel 20040615)
  // Suggestion:
  // o First try to get the same pf as NSOpenGLView.defaultPixelFormat
  // o If failed, fall back to some lower pf
  // -> we need to acquire a real NSOpenGLPixelFormat here.
  
  SCOpenGLPixelFormat * pixelFormat = [[SCOpenGLPixelFormat alloc] init];
  [pixelFormat setAttribute:NSOpenGLPFADoubleBuffer];
  [pixelFormat setAttribute:NSOpenGLPFAAccelerated];
  [pixelFormat setAttribute:NSOpenGLPFAColorSize toValue:24];
  [pixelFormat setAttribute:NSOpenGLPFAAlphaSize toValue:8];
  [pixelFormat setAttribute:NSOpenGLPFADepthSize toValue:32];
  [pixelFormat autorelease];
  return pixelFormat;
}


#pragma mark --- initialization and cleanup ---

/*"  
  Designated initializer.
  
  Initializes a newly allocated NSOpenGLView with frameRect as its
  frame rectangle and format as its pixelformat.

  Passing nil as pixelFormat will result in the pixelformat being
  set to the result of !{+defaultPixelFormat} when the OpenGL context
  is initialized.
  "*/
- (id)initWithFrame:(NSRect)frameRect pixelFormat:(SCOpenGLPixelFormat *)format
{
  SC21_DEBUG(@"SCOpenGLView.initWithFrame:pixelFormat");
  
  self = [super initWithFrame:frameRect];
  if (self) {
    [self _SC_commonInit];
    SELF->pixelformat = [format retain];
  }
  return self;
}

/*"
  Equivalent to -initWithFrame:frameRect pixelFormat:nil.
  "*/
- (id)initWithFrame:(NSRect)frameRect
{  
  SC21_DEBUG(@"SCOpenGLView.initWithFrame:");
  
  return [self initWithFrame:frameRect pixelFormat:nil];
}

/*"
Used by subclassers to initialize OpenGL state. This function is called
 once after an OpenGL context is created and the drawable is attached.
 
 On Panther, NSOpenGLContext will automatically send this message to
 its view from its !{-makeCurrentContext} method.
 On Jaguar, this function is called explicitly from our
 !{-openGLContext} method, emulating Panther's behavior.
 "*/
- (void)prepareOpenGL
{
  SC21_DEBUG(@"SCOpenGLView.prepareOpenGL");
  glEnable(GL_DEPTH_TEST);
  glClearColor(0.0, 0.0, 0.0, 0.0);
  glClear(GL_COLOR_BUFFER_BIT);
}


- (void)dealloc
{
  SC21_DEBUG(@"SCOpenGLView.dealloc");
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [self clearGLContext];
  [self setPixelFormat:nil];
  [SELF release];
  [super dealloc];
}

#pragma mark --- pixelformat-related ---

/*"
  Sets the receiver's pixel format to pixelFormat
"*/
- (void)setPixelFormat:(SCOpenGLPixelFormat *)pixelFormat
{
  SC21_DEBUG(@"SCOpenGLView.setPixelFormat");
  
  //   FIXME: Should we force a recreation of our OpenGL context?
  //   NSOpenGLView doesn't seem to do this, but it needs to be
  //   better tested.
  //   (kintel 20040456)
  [pixelFormat retain];
  [SELF->pixelformat release];
  SELF->pixelformat = pixelFormat;
}

/*"
  Returns the pixel format associated with the receiver.
  "*/
- (SCOpenGLPixelFormat *)pixelFormat
{
  SC21_DEBUG(@"SCOpenGLView.pixelFormat");
  
  return SELF->pixelformat;
}


#pragma mark --- context-related ---

/*"
  Releases the NSOpenGLContext associated with the receiver. If
  necessary, this method calls clearDrawable on the context before
  releasing it.
  "*/
- (void)clearGLContext
{
  SC21_DEBUG(@"SCOpenGLView.clearGLContext");

  if (SELF->openGLContext) {
    if ([SELF->openGLContext view] == self) 
      [SELF->openGLContext clearDrawable];
    [SELF->openGLContext autorelease];
    SELF->openGLContext = nil;
  }
}

/*"
  Returns the NSOpenGLContext associated with the receiver. If the
  receiver has no associated context, a new NSOpenGLContext is created
  and returned. This new context is initialized with the pixelformat
  returned by sending !{pixelFormat} to the receiver, or (if this
  returns nil) a new pixelformat created by !{+defaultPixelFormat}.
"*/
- (NSOpenGLContext *)openGLContext
{
  if (!SELF->openGLContext) {
    SC21_DEBUG(@"SCOpenGLView.openGLContext: Creating new context");
    
    SCOpenGLPixelFormat * format = [self pixelFormat];
    if (!format) {
      format = [SCOpenGLView defaultPixelFormat];
      [self setPixelFormat:format];
    }
    SELF->openGLContext = 
      [[NSOpenGLContext alloc] initWithFormat:[format pixelFormat]
                               shareContext:nil];
    SELF->contextisprepared = NO;
  }
  return SELF->openGLContext;
}


/*"
  Sets the NSOpenGLContext used by the receiver to allow sharing the
  same context on a per view basis. Replaces the existing context if
  one was already created. You must send !{setView:} to the context to
  sync the context with the view.
"*/

- (void)setOpenGLContext:(NSOpenGLContext *)context
{
  SC21_DEBUG(@"SCOpenGLView.setOpenGLContext");

  [context retain];
  [self clearGLContext];
  SELF->openGLContext = context;
  SELF->contextisprepared = NO;
}

#pragma mark --- drawing and updating --- 

/*" 
  Called if the visible rectangle or bounds of the receiver change
  (for scrolling or resize). The default implementation does
  nothing. Override this method if you need to adjust the viewport and
  display frustum. 
"*/

  // FIXME: Using NSOpenGLView, reshape is called when a scrollview is
  // scrolled. This does not happen with SCOpenGLView. The reason
  // seems to be that for our view, NSView.translateOriginToPoint: is
  // not called.  Test this with "OpenGL scroller"/"NSOpenGL
  // scroller". (kintel 20040505)

- (void)reshape
{
}

/*"
  Called if the view's context needs to be updated because the window
  moves, or if the view moves or is resized. This method simply calls
  NSOpenGLContext's !{update}. Override this method if you need to add
  locks for multithreaded access to multiple contexts.
"*/
- (void)update
{
  if ([SELF->openGLContext view] == self) {
    [SELF->openGLContext update];
  }
}

// Overridden methods from parent

/*"
  Overridden from NSView: we are always drawing every pixel.
"*/
- (BOOL)isOpaque
{
  return YES;
}

/*"
  Overridden from NSView to ensure that we have a valid context
  bound to this view.
"*/
- (void)lockFocus
{
  // SC21_DEBUG(@"SCOpenGLView.lockFocus");

  NSOpenGLContext * context = [self openGLContext];
  [super lockFocus];
  
  if ([context view] != self) {
    [context setView:self];
  }
  [context makeCurrentContext];
  // Run this only on <= 10.2 since >=10.3 automatically calls
  // prepareOpenGL from NSOpenGLContext.
  //   FIXME:
  //   Is it OK to assume that prepareOpenGL will work when compiling
  //   on Jaguar and running on Panther? If not, we should
  //   probably not use prepareOpenGL at all, but a similar method
  //   that will work with both OS versions. (kintel 20040615)
  if (!SELF->contextisprepared &&
      floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_2) {
    [self prepareOpenGL];
    SELF->contextisprepared = YES;
  }
}

#pragma mark --- NSCoding conformance ---

- (void)encodeWithCoder:(NSCoder *)coder 
{
  SC21_DEBUG(@"SCOpenGLView.encodeWithCoder:");

  [super encodeWithCoder:coder];
  if ([coder allowsKeyedCoding]) {
    [coder encodeObject:SELF->pixelformat forKey:@"SC_pixelformat"];
  }
}

- (id)initWithCoder:(NSCoder *)coder 
{
  SC21_DEBUG(@"SCOpenGLView.initWithCoder:");

  if (self = [super initWithCoder:coder]) {
    [self _SC_commonInit];
    if ([coder allowsKeyedCoding]) {
      SELF->pixelformat = [[coder decodeObjectForKey:@"SC_pixelformat"] retain];
    }
  }
  return self;
}

@end

// ----------------------- InternalAPI -------------------------

@implementation SCOpenGLView(InternalAPI)

/* 
  Shared initialization code that is called both from 
  !{initWithFrame:pixelFormat} and !{initWithCoder:}.
  
  If you override this method, you must call !{[super
  _SC_commonInit]} as the first call in your
  implementation to make sure everything is set up properly.

  Do not call this method from your superclass' init or 
  initWithCoder.
  */
- (void)_SC_commonInit
{
  SELF = [[SCOpenGLViewP alloc] init];
  
  [[NSNotificationCenter defaultCenter] 
    addObserver:self 
    selector:@selector(_SC_updateNeeded:) 
    name:NSViewGlobalFrameDidChangeNotification 
    object:self];
  
  [[NSNotificationCenter defaultCenter] 
    addObserver:self 
    selector:@selector(_SC_reshapeNeeded:) 
    name:NSViewFrameDidChangeNotification 
    object:self];
}

- (void)_SC_updateNeeded:(NSNotification *)notification
{
  SC21_DEBUG(@"SCOpenGLView._SC_updateNeeded");
  [self update];
}

- (void)_SC_reshapeNeeded:(NSNotification *)notification
{
  SC21_DEBUG(@"SCOpenGLView._SC_reshapeNeeded:");
  //   FIXME: Should we make sure that we have a valid context before calling
  //   reshape (e.g. in _SC_reshapeNeeded:) ? (kintel 20040615)
  [self reshape];
}

@end
